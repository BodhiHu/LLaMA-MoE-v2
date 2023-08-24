#!/usr/bin/bash

#  llama_7B  llama_13B  llama_30B  llama_base
#  llama2_7B  llama2_13B  llama2_30B  llama2_base
llama_size="llama_13B"

data_path=/mnt/petrelfs/share_data/quxiaoye
model_path=${data_path}/models/${llama_size}
save_path=${data_path}/moefication_results/split

# 所有可能的结果组合
gpus=0
cpus=8
for num_experts in 8 16; do
  for proj_type in "gate_proj" "up_proj"; do
    OMP_NUM_THREADS=8 srun --partition=MoE --job-name=split --mpi=pmi2 --gres=gpu:${gpus} -n1 --ntasks-per-node=1 -c ${cpus} --kill-on-bad-exit=1 \
      python -m smoe.entrypoint.moefication.llama_split_random \
      --model_path ${model_path} \
      --save_path ${save_path} \
      --template layers.{}.mlp.${proj_type}.weight \
      --num_experts ${num_experts} & # 并行运行下一命令
    sleep 0.5                        # 等待0.5s
  done
done

wait
chmod -R 777 ${save_path} >/dev/null 2>&1