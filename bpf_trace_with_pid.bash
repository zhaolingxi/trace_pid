# 准备好宿主机上的结果目录
mkdir -p ./results
rm -f ./results/profile.raw ./results/profile.folded ./results/flame.svg

# 直接启动即可
docker compose -f ./bpf_trace_pid.yml up

# 运行结束后，容器会自动停止。
# 结果文件会出现在宿主机的 ./results/profile.txt
echo "分析完成！结果已保存在 ./results/profile.raw"

# 最后别忘了清理
docker compose -f ./bpf_trace_pid.yml down

./FlameGraph/stackcollapse-bpftrace.pl results/profile.raw > results/profile.folded

./FlameGraph/flamegraph.pl results/profile.folded > results/flame.svg