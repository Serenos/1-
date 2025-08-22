#!/bin/bash
eval $(curl -s http://deploy.i.brainpp.cn/httpproxy)
eval "$(conda shell.bash hook)"
source activate cogact

export DISPLAY=""
gpu_id=2

declare -a arr=(
  "/data/ckpt/cogact/pretrained/CogACT-Base/checkpoints/CogACT-Base.pt"
)

EvalOverlay() {
  ckpt_path=$1
  env_name=$2
  scene_name=$3
  extra_args=$4

  eval_dir=$(dirname "$(dirname "${ckpt_path}")")/eval/$(basename "${ckpt_path}")
  mkdir -p "${eval_dir}"
  log_file="${eval_dir}/move_near_variant_agg.txt"

  {
    echo "+###############################+"
    date
    for i in "$@"; do
      echo "| $i"
    done
    echo "+###############################+"

    CUDA_VISIBLE_DEVICES=${gpu_id} python sim_cogact/main_inference.py \
      --policy-model cogact \
      --ckpt-path "${ckpt_path}" \
      --robot google_robot_static \
      --control-freq 3 \
      --sim-freq 513 \
      --max-episode-steps 80 \
      --env-name "${env_name}" \
      --scene-name "${scene_name}" \
      --robot-init-x 0.35 0.35 1 \
      --robot-init-y 0.21 0.21 1 \
      --obj-variation-mode episode \
      --obj-episode-range 0 60 \
      --robot-init-rot-quat-center 0 0 0 1 \
      --robot-init-rot-rpy-range 0 0 1 0 0 1 -0.09 -0.09 1 \
      ${extra_args}

    echo "+###############################+"
    date
    echo "Done!"
    echo "+###############################+"
  } 2>&1 | tee -a "${log_file}"
}

# 1. Base setup
env_name=MoveNearGoogleInScene-v0
scene_name=google_pick_coke_can_1_v4
for ckpt_path in "${arr[@]}"; do
  EvalOverlay "$ckpt_path" "$env_name" "$scene_name" ""
done

# 2. Distractor
for ckpt_path in "${arr[@]}"; do
  EvalOverlay "$ckpt_path" "$env_name" "$scene_name" "--additional-env-build-kwargs no_distractor=True"
done

# 3. Backgrounds
declare -a scene_arr=(
  "google_pick_coke_can_1_v4_alt_background"
  "google_pick_coke_can_1_v4_alt_background_2"
)
for scene in "${scene_arr[@]}"; do
  for ckpt_path in "${arr[@]}"; do
    EvalOverlay "$ckpt_path" "$env_name" "$scene" ""
  done
done

# 4. Lighting
for ckpt_path in "${arr[@]}"; do
  EvalOverlay "$ckpt_path" "$env_name" "$scene_name" "--additional-env-build-kwargs slightly_darker_lighting=True"
  EvalOverlay "$ckpt_path" "$env_name" "$scene_name" "--additional-env-build-kwargs slightly_brighter_lighting=True"
done

# 5. Table textures
declare -a scene_arr=(
  "Baked_sc1_staging_objaverse_cabinet1_h870"
  "Baked_sc1_staging_objaverse_cabinet2_h870"
)
for scene in "${scene_arr[@]}"; do
  for ckpt_path in "${arr[@]}"; do
    EvalOverlay "$ckpt_path" "$env_name" "$scene" ""
  done
done

# 6. Camera orientations
declare -a env_arr=(
  "MoveNearAltGoogleCameraInScene-v0"
  "MoveNearAltGoogleCamera2InScene-v0"
)
scene_name=google_pick_coke_can_1_v4
for env in "${env_arr[@]}"; do
  for ckpt_path in "${arr[@]}"; do
    EvalOverlay "$ckpt_path" "$env" "$scene_name" ""
  done
done
