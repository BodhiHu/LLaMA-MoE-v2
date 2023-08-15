#!/usr/bin/bash

#  llama_7B  llama_13B  llama_30B  llama_base
#  llama2_7B  llama2_13B  llama2_30B  llama2_base
llama_size=llama2_7B

num_experts=8                         #  8  16
metric=l1_norm                        #  l1_norm l2_norm plain
template=layers.{}.mlp.up_proj.weight #  gate_proj  up_proj
threshold=1

data_path=/mnt/petrelfs/share_data/quxiaoye
model_path=${data_path}/models/${llama_size}
save_path=${data_path}/moefication_results/split/${llama_size}-${num_experts}Expert-Split-Graph-${metric}/
hidden_features_path=${data_path}/moefication_results/features/${llama_size}-Hidden-Features

gpus=0
cpus=16

# STEP1

OMP_NUM_THREADS=8 srun --partition=MoE --job-name=split --mpi=pmi2 --gres=gpu:${gpus} -n1 --ntasks-per-node=1 -c ${cpus} --kill-on-bad-exit=1 \
python -m smoe.entrypoint.moefication.llama_split_graph \
--model_path ${model_path} \
--save_path ${save_path} \
--template ${template} \
--num_experts ${num_experts} \
--threshold ${threshold} \
--metric ${metric} \
--hidden_features_path ${hidden_features_path} \

# STEP2

gpmetis_run=/mnt/petrelfs/share_data/quxiaoye/metis_for_graph_split/bin/gpmetis
template1=layers.
template2=.mlp.up_proj.weight

for layer in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31; do
  OMP_NUM_THREADS=8 srun --partition=MoE --job-name=split --mpi=pmi2 --gres=gpu:${gpus} -n1 --ntasks-per-node=1 -c ${cpus} --kill-on-bad-exit=1 \
  ${gpmetis_run} ${save_path}/${template1}${layer}${template2} ${num_experts}
done

# STEP3

template3=.part.${num_experts}

for layer in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31; do
  OMP_NUM_THREADS=8 srun --partition=MoE --job-name=split --mpi=pmi2 --gres=gpu:${gpus} -n1 --ntasks-per-node=1 -c ${cpus} --kill-on-bad-exit=1 \
  python -m smoe.entrypoint.moefication.llama_split_graph_trans_gp \
  --gpmetised_file_path ${save_path}/${template1}${layer}${template2}${template3}
done
