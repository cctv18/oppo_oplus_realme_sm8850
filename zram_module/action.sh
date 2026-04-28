#!/system/bin/sh

MODDIR=${0%/*}

algorithms="lz4 zstd lzo lzo-rle lz4k lz4hc lz4kd 842 zstdn"
sizes="8589934592 12884901888 17179869184 25769803776"  # 8G, 12G, 16G, 24G

show_device_info() {
  echo "🔧 设备: $(getprop ro.product.model || echo '未知')"
  echo "🔄 Android: $(getprop ro.build.version.release || echo '未知')"
  echo "⚙️ 内核: $(uname -r || echo '未知')"
}

get_real_ram_bytes() {
  awk '/MemTotal/ {if($2>0) print $2*1024; else print 0}' /proc/meminfo 2>/dev/null || echo "0"
}

check_dual_zram() {
  [ -e /sys/block/zram0 ] && [ -e /sys/block/zram1 ] && echo "是" || echo "否"
}

get_active_algorithm() {
  alg=$(cat /sys/block/zram0/comp_algorithm 2>/dev/null | grep -o '\[[^]]*\]' | tr -d '[]')
  echo "${alg:-lz4kd}"
}

wait_key() {
  getevent -qt 1 >/dev/null 2>&1
  while true; do
    event=$(getevent -lqc 1 2>/dev/null | {
      while read -r line; do
        case "$line" in
          *KEY_VOLUMEDOWN*DOWN*) echo "down" && break ;;
          *KEY_VOLUMEUP*DOWN*) echo "up" && break ;;
          *KEY_POWER*DOWN*)
            input keyevent KEY_POWER
            echo "power" && break ;;
        esac
      done
    })
    [ -n "$event" ] && echo "$event" && return
    usleep 50000
  done
}

countdown() {
  local secs=$1
  while [ $secs -gt 0 ]; do
    echo -ne "⏳ ${secs}秒后返回...\033[0K\r"
    sleep 1
    : $((secs--))
  done
  echo -e "\033[0K\r"
}

RAM_BYTES=$(get_real_ram_bytes)
IS_DUAL_ZRAM=$(check_dual_zram)
current_alg=$(get_active_algorithm)

index=0
alg_count=$(echo "$algorithms" | wc -w)
for alg in $algorithms; do
  if [ "$alg" = "$current_alg" ]; then break; fi
  index=$((index + 1))
done
[ $index -ge $alg_count ] && index=0 && current_alg=$(echo "$algorithms" | cut -d' ' -f$((index + 1)))

current_size=$(cat /sys/block/zram0/disksize 2>/dev/null || echo 0)
size_index=0
j=0
for sz in $sizes; do
  if [ "$sz" -eq "$current_size" ]; then
    size_index=$j
    break
  fi
  j=$((j + 1))
done
size_count=$(echo "$sizes" | wc -w)
[ $size_index -ge $size_count ] && size_index=0

SIZE_TO_APPLY=$(echo "$sizes" | cut -d' ' -f$((size_index + 1)))
size_rem=$(echo "$SIZE_TO_APPLY" | awk '{if($1<=0) print "未知"; else printf "%.1fGB", $1/1024/1024/1024}')

show_menu() {
  clear
  echo "ZRAM 配置管理器² 😋"
  echo "----------------------------------"
  show_device_info
  echo "----------------------------------"
  echo "📊 物理内存: $(echo "$RAM_BYTES" | awk '{if($1<=0) print "未知"; else printf "%.1fGB", $1/1024/1024/1024}')"
  echo "💽 双ZRAM: $IS_DUAL_ZRAM"
  echo "----------------------------------"
  echo "📦 压缩算法选择:"
  local i=0
  for alg in $algorithms; do
    [ $i -eq $index ] && echo "➡️  $alg [当前: $current_alg]" || echo "    $alg"
    i=$((i + 1))
  done
  echo "----------------------------------"
  echo "💾 ZRAM 大小设置:"
  local j=0
  for sz in $sizes; do
    human_sz=$(echo "$sz" | awk '{printf "%.1fGB", $1/1024/1024/1024}')
    [ $j -eq $size_index ] && echo "➡️  $human_sz [当前 $size_rem]" || echo "    $human_sz"
    j=$((j + 1))
  done
  echo "----------------------------------"
  echo "🔽 音量下：切换算法 | 🔼 音量上：切换大小"
  echo "🔌 电源键：应用并退出"
  echo "----------------------------------"
  echo "配置将保存到模块目录: $MODDIR/zram_config.conf"
  echo ""
}

while true; do
  show_menu
  case $(wait_key) in
    "down")
      index=$(( (index + 1) % $alg_count ))
      current_alg=$(echo "$algorithms" | cut -d' ' -f$((index + 1)))
      ;;
    "up")
      size_index=$(( (size_index + 1) % $size_count ))
      SIZE_TO_APPLY=$(echo "$sizes" | cut -d' ' -f$((size_index + 1)))
      ;;
    "power")
      selected_alg=$(echo "$algorithms" | cut -d' ' -f$((index + 1)))
      clear
      echo "🛠️ 正在应用配置..."
      echo "----------------------------------"
      echo "选定算法: $selected_alg"
      echo "目标大小: $(echo "$SIZE_TO_APPLY" | awk '{printf "%.1fGB", $1/1024/1024/1024}') ($SIZE_TO_APPLY 字节)"
      echo "双ZRAM: $IS_DUAL_ZRAM"
      echo "----------------------------------"

      su -c "
        swapoff /dev/block/zram0 2>/dev/null
        echo 1 > /sys/block/zram0/reset
        echo $selected_alg > /sys/block/zram0/comp_algorithm
        echo $SIZE_TO_APPLY > /sys/block/zram0/disksize
        mkswap /dev/block/zram0 >/dev/null
        swapon -p 32767 /dev/block/zram0 >/dev/null
      "

      sleep 1
      new_alg=$(get_active_algorithm)
      new_size=$(cat /sys/block/zram0/disksize 2>/dev/null || echo "0")

      clear
      echo "🔧 ZRAM 配置管理器"
      echo "----------------------------------"

      if [ "$new_alg" = "$selected_alg" ] && [ "$new_size" -eq "$SIZE_TO_APPLY" ]; then
        echo "✅ 全部都搞定了❛˓◞˂̵✧"
        echo "实际算法: $new_alg"
        echo "实际大小: $(echo "$new_size" | awk '{printf "%.1fGB", $1/1024/1024/1024}')"

        CONFIG_FILE="$MODDIR/zram_config.conf"
        echo "ℹ️ 正在保存配置到文件: $CONFIG_FILE..."

        su -c "cat > \"$CONFIG_FILE\" <<EOF
algorithm=$new_alg
size=$new_size
EOF"

        if [ $? -eq 0 ]; then
          echo "✅ 配置文件保存成功。"
          MODULE_PROP="$MODDIR/module.prop"
          if [ -f "$MODULE_PROP" ]; then
            human_size=$(echo "$new_size" | awk '{printf "%.1fGB", $1/1024/1024/1024}')
            new_description="description=当前已生效 [ZRAM大小($human_size) 压缩算法($new_alg)]"
            su -c "sed -i 's/^description=.*/$new_description/' \"$MODULE_PROP\""
          fi
        else
          echo "❌ 配置文件保存失败！请检查权限。"
        fi
      else
        echo "❌ 设置失败或部分未生效"
      fi
      echo "----------------------------------"
      countdown 3
      exit 0
      ;;
  esac
done
