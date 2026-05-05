# hhl_gnc_anat_helper.py

import os
def gnc_anat_commands(subject, anat_process_dir, image_to_run_gnc_dir, gnc_anat_option):
    input_file = image_to_run_gnc_dir
    output_dir = f"{anat_process_dir}/s1_gnc"
    os.makedirs(output_dir, exist_ok=True)
    output_file = f"{output_dir}/{subject}_T1w.nii.gz"

    hhl_gnc_anat_cmd = f"gncunwarp.sh -i {input_file} -o {output_file} -g /your/project/directory/preprocessing_dwi/gradnonlinunwarp/coil_file/coeff.grad"
  
    return hhl_gnc_anat_cmd
