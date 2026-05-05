# dcm2bids_exportparam_concat_helper.py

import sys
import os

# Get the parent directory of the helpers folder
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)

def dcm2bids_command(subject_id, c2path, config, dcm_source):
    cmd = f"cd '{parent_dir}' && python3 -c 'from helpers.dcm2bids_runner import run_dcm2bids; run_dcm2bids(\"{subject_id}\", \"{c2path}\", \"{config}\", \"{dcm_source}\")'"
    return cmd

def export_diffusion_parameters_command(subject_id, subj_raw_dir):
    cmd = f"cd '{parent_dir}' && python3 -c 'from helpers.diffusion_parameters_exporter import export_diffusion_parameters; export_diffusion_parameters(\"{subject_id}\", \"{subj_raw_dir}\")'"
    return cmd

def concatenate_dwi_data_command(subj_raw_dir, subject, subj_process_dir):
    cmd = f"cd '{parent_dir}' && python3 -c 'from helpers.concat_dwis import concatenate_dwi_data; concatenate_dwi_data(\"{subj_raw_dir}\", \"{subject}\", \"{subj_process_dir}\")'"
    return cmd
