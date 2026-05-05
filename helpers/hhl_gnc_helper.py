# hhl_gnc_helper.py

import os
def gnc_commands(subject, base_dir, selected_flow, gnc_option):
    eddy_dir_suffix = "s6_denoise_degibbs_eddy" if selected_flow == "concat_denoise_degibbs" else "s6_degibbs_eddy"
    eddy_dir = f"{base_dir}/{eddy_dir_suffix}"
    input_file = f"{eddy_dir}/{subject}_dwi_eddy.nii.gz"
    gnc_dir_suffix = "s7_denoise_degibbs_gnc" if selected_flow == "concat_denoise_degibbs" else "s7_gnc"
    output_dir = f"{base_dir}/{gnc_dir_suffix}"
    os.makedirs(output_dir, exist_ok=True)
    output_file = f"{output_dir}/{subject}_dwi.nii.gz"

    hhl_gnc_cmd = f"gncunwarp.sh -i {input_file} -o {output_file} -g /your/project/directory/preprocessing_dwi/gradnonlinunwarp/coil_file/coeff.grad"
  
    return hhl_gnc_cmd
