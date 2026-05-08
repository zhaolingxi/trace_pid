#!/bin/bash
# 1. 准备目录
mkdir -p ./results
rm -f ./results/perf.data ./results/profile.raw ./results/profile.folded ./results/flame.svg

# 2. 启动容器采样 (自动读取 .env 中的 TARGET_PID)
docker compose -f ./perf_trace_pid.yml up
docker compose -f ./perf_trace_pid.yml down

# 3. 解析二进制数据 (关键：perf record 产出的是二进制)
# 我们借用容器里的 perf 工具来解析自己产出的 perf.data
docker run --rm \
    -v $(pwd)/results:/data \
#    -v ~/xx_mount:/mnt/xx_mount:ro \
    ubuntu22-perf-image:latest \
    perf script -i /data/perf.data --header > ./results/profile.raw

# 4. 后期处理
./FlameGraph/stackcollapse-perf.pl ./results/profile.raw > ./results/profile.folded
./FlameGraph/flamegraph.pl ./results/profile.folded > ./results/flame.svg

echo "分析完成！火焰图见 ./results/flame.svg"