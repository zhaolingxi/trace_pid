FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    linux-tools-common \
    linux-tools-generic \
    linux-tools-$(uname -r) \
    perl \
    && rm -rf /var/lib/apt/lists/*

# 验证 perf 是否可用
RUN perf --version

# 注入脚本（也可以在 yml 中通过 volume 注入）
# COPY perf_trace_with_pid.bash /entrypoint.sh
# RUN chmod +x /entrypoint.sh