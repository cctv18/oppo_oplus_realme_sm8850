#!/system/bin/sh

MODDIR=${0%/*}
CONFIG="$MODDIR/zram_config.conf"

apply_zram() {
  local alg="$1"
  local size="$2"
  local try=0
  while [ ! -e /dev/block/zram0 ] && [ $try -lt 60 ]; do
    sleep 1
    try=$((try+1))
  done
  if [ ! -e /dev/block/zram0 ]; then
    return 1
  fi
  su -c swapoff /dev/block/zram0
  su -c rmmod zram
  sleep 5
  su -c insmod $MODDIR/zram.ko
  sleep 5
  echo '1' > /sys/block/zram0/reset
  echo '0' > /sys/block/zram0/disksize
  echo "$alg" > /sys/block/zram0/comp_algorithm
  echo "$size" > /sys/block/zram0/disksize
  mkswap /dev/block/zram0 > /dev/null 2>&1
  swapon -p 32767 /dev/block/zram0 > /dev/null 2>&1
}

if [ -f "$CONFIG" ]; then
  source "$CONFIG"
  [ -n "$algorithm" ] && [ -n "$size" ] && apply_zram "$algorithm" "$size"
fi