# 🚀 高性能应用双模 Profile 采集框架

本工具集提供两套基于 **Docker Sidecar** 模式的性能采样方案：**bpftrace 模式** 与 **Perf DWARF 模式**。
通过这一套框架，可以实现对宿主机上 C++ 进程进行零侵入的热点函数统计与调用栈分析。

---

## 🛠 方案选择指南

当你准备分析一个目标进程时，请先了解其编译背景（是否保留了帧指针），并按下表选择工具：

| 特性 | **模式 A：bpftrace (轻量级)** | **模式 B：perf DWARF (强力级)** |
| :--- | :--- | :--- |
| **设计意图** | **生产环境首选**。极低开销，快速验证。 | **最后的手段**。用于穿透复杂模板与内联函数。 |
| **适用场景** | 开启了 `-fno-omit-frame-pointer` 的应用。 | **默认编译（未开启帧指针）** 的应用。 |
| **回溯原理** | 硬件级帧指针遍历 (Frame Pointer)。 | 原始栈内存拷贝 + 事后 DWARF 解包 (CFI)。 |
| **系统开销** | **极低 (< 1%)**，支持长时间持续采集。 | **中等 (5%~20%)**，建议短时、单次采集。 |
| **数据大小** | 极小 (kB 级别纯文本)。 | 较大 ( MB 甚至 GB 级别二进制文件)。 |
| **脚本入口** | `./bpf_trace_with_pid.bash` | `./perf_trace_with_pid.bash` |

---

## 📂 目录结构说明

```text
.
├── .env                        # 统一配置中心：
├── bpf_trace_pid.yml           # bpftrace 容器配置 (模式 A)
├── bpf_trace_with_pid.bash     # bpftrace 启动脚本 (模式 A)
├── perf_trace_pid.yml          # perf 容器配置 (模式 B)
├── perf_trace_with_pid.bash    # perf 启动脚本 (模式 B)
├── build_docker/               # 存放用于构建采集器的 Dockerfile
├── FlameGraph/                 # 火焰图转换引擎 (Perl 脚本)
└── results/                    # 结果存放区 (Profile Raw/Folded, SVG)



## 快速开始示例
1. 环境准备
仅支持linux,已在ubuntu 22/24验证
docker 和docker compose是必须的,建议采用2以上的版本

确保 .env 中的 PID 为目标进程：
top -b -n 1 | grep XX

修改.env中的TARGET_PID,例如
TARGET_PID=3032514
设置采样的频率和时间


2. 模式 A 执行（推荐）
如果你知道应用带有帧指针，或者你需要对系统做一个长时间（如一小时）的低负载监控：
./bpf_trace_with_pid.bash

3. 模式 B 执行（后备）
如果你看到火焰图全是十六进制地址，且无法重新编译目标程序：
请注意,需要在bash脚本中保证你的sidecar采样docker要能够看见自己的lib文件,这是dwarf需要的,也就是docker挂载设置
-v ~/xx_mount:/mnt/xx_mount:ro \

./perf_trace_with_pid.bash

4.结果查看
用浏览器查看.svg或者直接查看.raw或者.floded文件


🔬 常见问题进阶诊断：为什么你会看到 [unknown]？
在本框架中，如果你发现火焰图显示不全，通常由于以下原因：

路径映射错误： perf 和 bpftrace 都需要读取宿主机的二进制文件。如果你的代码路径不在 /mnt/poc_mount 下，请修改相应的 .yml 文件中的 volumes 挂载点。
没有帧指针（针对 bpftrace）： 如果 bpftrace 抓取的栈非常浅（只有 1-2 层），说明目标应用在编译时省略了帧指针。必须改用 perf 模式或在编译时添加 -fno-omit-frame-pointer。
符号表被 Strip： 如果两种模式都抓不到函数名，请检查你的二进制文件。在宿主机运行 file <binary>，如果显示 stripped，则需要使用带调试符号的 -g 版本。
内核权限限制： 如果出现 Permission Denied，请在宿主机运行： sudo sysctl -w kernel.perf_event_paranoid=-1
📋 配置与调优
采样频率：在 .bash 或 .yml 中通过 -F 99 或 hz:99 控制。对于路径规划等计算密集型，99Hz 为推荐平衡点。
采样时长：
perf 建议控制在 60 秒内。
bpftrace 可以酌情延长，因为其内置了哈希聚合，不会撑爆磁盘。