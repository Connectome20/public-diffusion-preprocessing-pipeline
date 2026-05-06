# Diffusion MRI Pre-Processing Pipeline: Connectome 2.0

This is a step-by-step workflow for preparing diffusion MRI datasets for analysis. The pipeline wraps *dcm2bids*, *MRtrix3*, *FSL*, *FreeSurfer*, and in-house scripts behind a lightweight Python/Qt GUI. For issues with this pipeline, please contact Oakley Martin (omartin3@mgh.harvard.edu).
___

## Prerequisites

| Component | Recommended Version | Notes |
|-----------|--------------------|-------|
| *FreeSurfer* | 7.4.1 | For `recon-all` |
| *MRtrix3* | 3.0.3 | Gibbs & MP-PCA modules |
| *Miniforge* | Latest | For managing Conda environments |
| *FSL* | 5.0.7 and 6.0+ | Provides *topup* & *eddy* |
| CUDA | 10.2 | Necessary for GPU-enabled *eddy* |
| Cluster access (SSH / VNC) & software install permission | N/A | N/A

___

## Quick Start: Pre-Built Conda Environment for Martinos Users

```bash
# Locate your session:
findsession <subject ID>

# Activate the pre-built Conda environment:
source /autofs/space/linen_001/users/Yixin/miniforge3/bin/activate
conda activate /autofs/space/linen_001/users/Yixin/miniforge3/envs/tractseg_env

```
Everything you need (i.e., the GUI and its dependencies) is bundled in the above environment, so no further installation is necessary.


---

## Full Setup

### 1. Configure Environment Variables

Append the following to your `~/.bash_profile`:

```bash
export PATH="/autofs/cluster/pubsw/2/pubsw/Linux2-2.3-x86_64/packages/mrtrix/3.0.3/bin:$PATH"
export FREESURFER_HOME="/usr/local/freesurfer/7.4.1"
export FSFAST_HOME="$FREESURFER_HOME/fsfast"
export SUBJECTS_DIR="$FREESURFER_HOME/subjects"
export MNI_DIR="$FREESURFER_HOME/mni"
source $FREESURFER_HOME/SetUpFreeSurfer.sh
```

Then, reload the shell:
```bash
source ~/.bashrc
```

### 2. Create / Activate a Python Environment

Download Miniforge (64-bit Linux):
```bash
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
chmod +x Miniforge3-Linux-x86_64.sh
./Miniforge3-Linux-x86_64.sh    # Accept license and choose install path
```

Initialize Conda:
```bash
<miniforge>/bin/conda init
exec "$SHELL"   # Restart shell so 'conda' is on PATH
```

Create and activate an environment:
```bash
conda create -n dmri_py312 python=3.12 -y
conda activate dmri_py312
```

### 3. Install Python Dependencies

```bash
pip install --upgrade pip
pip install numpy nibabel dcm2bids dcm2niix PySide6

```
___

## Download the Pipeline

Throughout these instructions, the script, and the helpers, you will see '/your/project/directory/' written into paths as a placeholder. Make sure to replace every instance of this with the actual path to your desired BIDS-format directory. (For example, if my project files are stored at '/autofs/cluster/connectome2/bids/', I would replace '/your/project/directory/' with '/autofs/cluster/connectome2/'.)

### Main Script:

Download *diff_preproc_c2.py* onto your machine, and save it to '/your/project/directory/bids/code/preprocessing_dwi/'. Then, make the following changes within the script:
- Enter the diffusion times (variables 'diff_time_a' and 'diff_time_b') values that correspond to your diffusion sequences. By default, these values are '30' and '13'.
- Enter the the PA- and AP-volume indices (search for 'Default value is "9"') for TopUp processing. By default, these values are set to '9' and '10' respectively. These fields can also be changed within the GUI.
- Since the Siemens gradient coil coefficient file cannot be shared publicly, you must generate this file yourself and save it to '/your/project/directory/preprocessing_dwi/gradnonlinunwarp/coil_file/coeff.grad'.

### Helpers:
Download all of the helper files, and save them to '/your/project/directory/bids/code/preprocessing_dwi/helpers/'.

### Configuration File (dcm2bids):

Download *config.json*, and save it to '/your/project/directory/bids/code/preprocessing_dwi/helpers/dcm2bids/‘. Then, replace every instance of '<your project sequence>' in this file with the specific or wild-carded names of your sequences. Optionally, you can add custom labels in place of '<your custom label>'.

### Expert File (recon-all):

Download *expertFile*, and save it to '/your/project/directory/bids/code/preprocessing_dwi/helpers/recon/‘.

### Rician Noise Correction File (denoising):

Download *rician_correct_mppca.sh*, and save it to '/your/project/directory/bids/code/preprocessing_dwi/helpers/noise_correct/‘.

### Acquisition Parameters & b02b0 (eddy / topup):

Download *acqparams.txt* and *b02b0_ym.cnf*, and save them to '/your/project/directory/bids/code/preprocessing_dwi/helpers/topup_eddy_extras/'.

### Gradient Non-Linearity Correction Script:
Download *gncunwarp.sh*, and save it to '/your/project/directory/bids/code/preprocessing_dwi/gradnonlinunwarp/'.

### Gradient Non-Linearity Correction Library:
Download all of the lib files, and save them to '/your/project/directory/bids/code/preprocessing_dwi/gradnonlinunwarp/lib/'.

___

## Launch / Run the GUI

```bash
cd /your/project/directory/bids/code/preprocessing_dwi
python diff_preproc_c2.py
```

---

## Pipeline Steps

1. **Execute dcm2bids** – Converts raw DICOMs to BIDS.  
2. **Export Diffusion Parameters** – Writes `bvecs`, `bvals`, `diffusionTime`, `pulseWidth`, `phaseEncoding`.
3. **Concatenate DWI Data** – Merges volumes automatically or from manual inputs.
4. **MP-PCA Denoise** - Completes magnitude or real denoising. *Not recommended for Connectome 2.0 data.*
5. **Gibbs Ringing Removal**
6. **TopUp Correction**
7. **Generate Masks** – Generates white matter and brain masks.
8. **Eddy Current Correction**
9. **GNC DWI** - Completes gradient non-linearity correction for DWI data.
10. **Eddy-GNC Interpolation**
11. **MP-PCA Noise Map** – Needed for SANDI model fitting.
12. **Write Outputs** - Copies processed DWI outputs to `/your/project/directory/bids/derivatives/processed_dwi/`.
13. **Divide Volumes for SANDI fitting**
14. **Divide Volumes for TractCaliber Fitting**
15. **Run TractSeg**
16. **GNC Anat** - Completes gradient non-linearity correction for anatomical data. *Not recommended for Connectome 2.0 data.*
17. **recon-all** - Runs FreeSurfer's `recon-all`.


---

## License


This project is licensed under the Apache License 2.0. Please refer to the LICENSE file for details.

---

## Acknowledgements

- FSL development team
- FreeSurfer development team  
- MRtrix3 contributors  
- Miniforge / Conda-Forge community  
- Martinos Center colleagues  
