# 欧加真 SM8850/MT6993 系列通用6.12内核自动化编译脚本
[![STAR](https://img.shields.io/github/stars/cctv18/oppo_oplus_realme_sm8850?style=flat&logo=github)](https://github.com/cctv18/oppo_oplus_realme_sm8850/stargazers)
[![FORK](https://img.shields.io/github/forks/cctv18/oppo_oplus_realme_sm8850?style=flat&logo=greasyfork&color=%2394E61A)](https://github.com/cctv18/oppo_oplus_realme_sm8850/forks)
[![COOLAPK](https://img.shields.io/badge/cctv18_2-cctv18_2?style=flat&logo=android&logoColor=FF4500&label=%E9%85%B7%E5%AE%89&color=FF4500)](http://www.coolapk.com/u/22650293)
[![DISCUSSION](https://img.shields.io/badge/%E8%AE%A8%E8%AE%BA%E5%8C%BA-discussions?logo=livechat&logoColor=FFBBFF&color=3399ff)](https://github.com/cctv18/oppo_oplus_realme_sm8850/discussions)

<img alt="Endpoint Badge" src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fcctv18%2Fkernel-workshop%2Frefs%2Fheads%2Fmain%2Fnotice.json">

##### 
一个更方便、快捷的自动化OPPO/一加/真我系列骁龙8Elite Gen5(SM8850)/天玑9500(MT6993)机型的通用6.12内核编译脚本。
##### 
这个项目的初衷是解决以下问题：
- 绿厂官方摆烂，代码开源开一半，导致部分内核代码无法通过已有的配置xml正常编译，甚至没有编译配置xml；
- 由于6.12内核引入了包括rust代码在内的大量新机制，导致市面上已有的使用make指令编译内核的方法无法正常完成编译，只能使用低效的bazel进行编译，而官方使用的 Bazel 编译器过于不稳定且臃肿不堪，容易出现各种各样莫名其妙的错误，且全网几乎找不到任何有效解决方法，对于新手极不友好；
- 现有的6.12内核常用编译流程（使用bazel编译/拉取第三方工具链编译等）编译速度极慢，即使在有缓存的情况下二次编译时间也动辄需要20-30分钟，且bazel与ccache缓存不兼容，无法正常保存编译缓存。
## 本项目的主要内容(及计划)
- 使用 AOSP 官方 LLVM/Clang 19 + Rust v1.82.0 进行编译，并排除了官方源码中不必要的 vendor 源码参与，大幅优化编译流程并引入ccache缓存机制，对比原 bazel 编译器缩短了近2/3的编译时间（原版官方编译器每次约需要超过1h才能完成编译），提高了编译过程的稳定性，输出日志更便于维护调试；
- 修复官方代码部分bug/未及时更新的补丁，并引入诸多第三方更新/功能支持；
- 提供 Github Action 在线编译/shell本地编译双版本脚本。
## 已实现：
- [x] 欧加真骁龙 SM8850 通用OKI内核（基于一加15源码的 6.12.23 / 一加Ace 6T源码的 6.12.38 ，其他同内核版本非SM8850机型可自行测试，部分机型可完全兼容）
- [x] 欧加真天玑 MT6993 通用OKI内核（基于OPPO Find X9 源码的 6.12.23 ，其他同内核版本非MT6993机型可自行测试，部分机型可完全兼容）
- [x] ReSukiSU/SukiSU Ultra/KernelSU Next/原版KernelSU多版本KSU可选
- [x] 引入ccache缓存及大量独家编译流程优化，二次编译时间可稳定在约4min (注：首次使用ccache由于需要创建缓存速度会比较慢，约23min，从第二次开始ccache才会生效加速编译，加速后单次编译时间约6min(更改内核编译选项会导致include/generated/autoconf.h改变，且绝大部分源码编译时会间接引用这个头文件，故会导致二次编译速度有所下降，下降至约10分钟，若再次使用首次缓存时的配置可恢复至约6分钟，如需要长期修改配置选项建议清空ccache缓存再用新的配置重建缓存)；由于现在GitHub Action的机制，距离上一次创建缓存较长时间后缓存可能会被自动清除，此时编译会自动重建缓存)
- [x] 引入O2编译优化，改善内核运行性能
- [x] lz4 1.10.0 & zstd 1.5.7 算法更新&优化补丁(来自[@ferstar](https://github.com/ferstar), 移植by [@Xiaomichael](https://github.com/Xiaomichael), 6.12版本补丁重制by [@cctv18](https://github.com/cctv18))
- [x] 移植lz4kd支持到6.12内核(可选补丁)
- [x] 可选加入 BBR/Brutal 及一系列 tcp 拥塞控制算法
- [x] [ADIOS IO调度器](https://github.com/firelzrd/adios)移植
- [x] 加入一些网络连接性能优化配置选项（用于为ipset及需要iptables等高级网络功能内核支持的程序提供支持）
- [x] 添加了对[Mountify](https://github.com/backslashxx/mountify)模块的支持
- [x] 加入Re:Kernel支持，与Freezer，NoActive等软件配合降低功耗
- [x] 加入[内核防格基带保护(By @showdo)](https://github.com/vc-teahouse/Baseband-guard)，有效防止恶意格机脚本/程序对系统分区数据的破坏
## 待实现：
- [ ] zram内置化，无需外置zram.ko挂载 ~~（有了新版 lz4&zstd 补丁真的还有必要吗）~~
- [ ] LXC/Docker 功能支持
- [ ] Nethunter 驱动移植
- ~~整合多版本内核编译脚本（🕊️🕊️🕊️）~~
- 更多优化与特性移植……
##### 
##### 
##### 
## 鸣谢
- WildKernel的一加系列内核构建脚本：[WildKernels/OnePlus_KernelSU_SUSFS](https://github.com/WildKernels/OnePlus_KernelSU_SUSFS)
- ReSukiSU：[ReSukiSU/ReSukiSU](https://github.com/ReSukiSU/ReSukiSU)
- SukiSU Ultra：[SukiSU-Ultra/SukiSU-Ultra](https://github.com/SukiSU-Ultra/SukiSU-Ultra)
- susfs4ksu：[ShirkNeko/susfs4ksu](https://github.com/ShirkNeko/susfs4ksu)
- ReSukiSU：[ReSukiSU/ReSukiSU](https://github.com/ReSukiSU/ReSukiSU)
- pershoot维护的KernelSU Next仓库：[pershoot/KernelSU-Next](https://github.com/pershoot/KernelSU-Next)
- 原版KernelSU: [tiann/KernelSU](https://github.com/tiann/KernelSU)
- 内核防格基带保护模块：[vc-teahouse/Baseband-guard](https://github.com/vc-teahouse/Baseband-guard)
- KSUN的多管理器补丁：[WildKernels/kernel_patches](https://github.com/WildKernels/kernel_patches)
- ~~本地化内核构建脚本（已失效）：[Suxiaoqinx/kernel_manifest_OnePlus_Sukisu_Ultra](https://github.com/Suxiaoqinx/kernel_manifest_OnePlus_Sukisu_Ultra)~~
