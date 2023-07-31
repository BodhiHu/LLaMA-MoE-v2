llama_size="llama_7B" #  7B  13B  30B  base

data_use_percent=0.01
save_interval=1
batch_size=4

root_path=/mnt/petrelfs/dongdaize.d/workspace/llama-moe
model_path=/mnt/petrelfs/share_data/quxiaoye/models/${llama_size}
train_data_path=/mnt/petrelfs/share_data/quxiaoye/llama_data
train_data_cache_path=/mnt/petrelfs/share_data/quxiaoye/llama_data_cache
save_path=${root_path}/llama_moe_temp_files
template=layers.{}.mlp.gate_proj.weight

gpus=8
cpus=128
OMP_NUM_THREADS=8 srun --partition=MoE --job-name=get_features --mpi=pmi2 --gres=gpu:${gpus} -n1 --ntasks-per-node=1 -c ${cpus} --kill-on-bad-exit=1 \
  python -m torch.distributed.launch --nproc_per_node=${gpus} ${root_path}/run_moefication/llama_get_hidden_features.py \
  --model_path ${model_path} \
  --train_data_path ${train_data_path} \
  --train_data_cache_path ${train_data_cache_path} \
  --save_path ${save_path} \
  --template ${template} \
  --data_use_percent ${data_use_percent} \
  --save_interval ${save_interval} \
  --batch_size ${batch_size}
