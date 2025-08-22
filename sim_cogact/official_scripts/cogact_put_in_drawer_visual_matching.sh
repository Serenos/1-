#!/bin/bash
eval $(curl -s http://deploy.i.brainpp.cn/httpproxy)
eval "$(conda shell.bash hook)"
source activate cogact


gpu_id=2

declare -a ckpt_paths=(
/data/ckpt/cogact/pretrained/CogACT-Base/checkpoints/CogACT-Base.pt
)

declare -a env_names=(
  PlaceIntoClosedTopDrawerCustomInScene-v0
  # PlaceIntoClosedMiddleDrawerCustomInScene-v0
  # PlaceIntoClosedBottomDrawerCustomInScene-v0
)

declare -a urdf_version_arr=(
"recolor_cabinet_visual_matching_1"
"recolor_tabletop_visual_matching_1"
"recolor_tabletop_visual_matching_2"
None
)

EvalOverlay() {
  ckpt_path=$1
  env_name=$2
  EXTRA_ARGS=$3

  eval_dir=$(dirname $(dirname ${ckpt_path}))/eval/$(basename ${ckpt_path})
  mkdir -p ${eval_dir}
  log_file="${eval_dir}/put_in_drawer_visual_matching.txt"

  {
    echo "+###############################+"
    date
    for i in "$@"; do
      echo "| $i"
    done
    echo "NOTE: with 3 variants"
    echo "+###############################+"

    # A0
    CUDA_VISIBLE_DEVICES=${gpu_id} python sim_cogact/main_inference.py --policy-model cogact --ckpt-path "${ckpt_path}" \
      --robot google_robot_static \
      --control-freq 3 --sim-freq 513 --max-episode-steps 200 \
      --env-name "${env_name}" --scene-name dummy_drawer \
      --robot-init-x 0.644 0.644 1 --robot-init-y -0.179 -0.179 1 \
      --robot-init-rot-quat-center 0 0 0 1 --robot-init-rot-rpy-range 0 0 1 0 0 1 -0.03 -0.03 1 \
      --obj-init-x-range -0.08 -0.02 3 --obj-init-y-range -0.02 0.08 3 \
      --rgb-overlay-path ./third_libs/SimplerEnv/ManiSkill2_real2sim/data/real_inpainting/open_drawer_a0.png \
      ${EXTRA_ARGS}

    # B0
    CUDA_VISIBLE_DEVICES=${gpu_id} python sim_cogact/main_inference.py --policy-model cogact --ckpt-path "${ckpt_path}" \
      --robot google_robot_static \
      --control-freq 3 --sim-freq 513 --max-episode-steps 200 \
      --env-name "${env_name}" --scene-name dummy_drawer \
      --robot-init-x 0.652 0.652 1 --robot-init-y 0.009 0.009 1 \
      --robot-init-rot-quat-center 0 0 0 1 --robot-init-rot-rpy-range 0 0 1 0 0 1 0 0 1 \
      --obj-init-x-range -0.08 -0.02 3 --obj-init-y-range -0.02 0.08 3 \
      --rgb-overlay-path ./third_libs/SimplerEnv/ManiSkill2_real2sim/data/real_inpainting/open_drawer_b0.png \
      ${EXTRA_ARGS}

    # C0
    CUDA_VISIBLE_DEVICES=${gpu_id} python sim_cogact/main_inference.py --policy-model cogact --ckpt-path "${ckpt_path}" \
      --robot google_robot_static \
      --control-freq 3 --sim-freq 513 --max-episode-steps 200 \
      --env-name "${env_name}" --scene-name dummy_drawer \
      --robot-init-x 0.665 0.665 1 --robot-init-y 0.224 0.224 1 \
      --robot-init-rot-quat-center 0 0 0 1 --robot-init-rot-rpy-range 0 0 1 0 0 1 0 0 1 \
      --obj-init-x-range -0.08 -0.02 3 --obj-init-y-range -0.02 0.08 3 \
      --rgb-overlay-path ./third_libs/SimplerEnv/ManiSkill2_real2sim/data/real_inpainting/open_drawer_c0.png \
      ${EXTRA_ARGS}

    echo "+###############################+"
    date
    echo "Done!"
    echo "+###############################+"
  } 2>&1 | tee -a "${log_file}"
}

for ckpt_path in "${ckpt_paths[@]}"; do
  for env_name in "${env_names[@]}"; do
    for urdf_version in "${urdf_version_arr[@]}"; do
      EXTRA_ARGS="--enable-raytracing --additional-env-build-kwargs station_name=mk_station_recolor light_mode=simple disable_bad_material=True urdf_version=${urdf_version} model_ids=baked_apple_v2"
      EvalOverlay "${ckpt_path}" "${env_name}" "${EXTRA_ARGS}"
    done
  done
done
