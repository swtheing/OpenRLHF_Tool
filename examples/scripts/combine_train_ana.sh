set -x 

save_path=./ckpt/7b_llama_ppo_1_epoch_continue_test/
rollout_batch_size=1024
output_file=test_he.jsonl
test_file=HumanEval-10-instruction-llama.jsonl
read -r -d '' training_commands <<EOF
../train_ppo.py \
    --pretrain ./ckpt/7b_llama_ppo_1_epoch/ \
    --reward_pretrain ./ckpt/7b_llama_rm_deepseek_100_new_2/ \
    --save_path $save_path \
    --save_steps -1 \
    --logging_steps 1 \
    --eval_steps -1 \
    --micro_train_batch_size 2 \
    --train_batch_size 256 \
    --micro_rollout_batch_size 4 \
    --rollout_batch_size $rollout_batch_size \
    --num_episodes 1 \
    --max_epochs 1 \
    --prompt_max_len 1024 \
    --generate_max_len 2048 \
    --zero_stage 2 \
    --bf16 \
    --actor_learning_rate 5e-7 \
    --critic_learning_rate 9e-6 \
    --init_kl_coef 0.01 \
    --prompt_data prompt-filter-5.jsonl\
    --eval_data $test_file\
    --input_key instruction \
    --prompt_data_probs 1.0 \
    --max_samples 80000 \
    --normalize_reward \
    --actor_init_on_gpu \
    --adam_offload \
    --gradient_checkpointing
EOF

if [[ ${1} != "slurm" ]]; then
    deepspeed $training_commands > /tmp/log
fi


cat /tmp/log | grep "reward_sw" > $save_path/ana_reward
python reward_ana.py $save_path/ana_reward $rollout_batch_size $save_path/reward.png
sh infer.sh $save_path $output_file $test_file