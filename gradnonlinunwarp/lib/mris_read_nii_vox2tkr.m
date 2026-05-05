% mris_read_nii_vox2tkr.m

function M0_vox2tkr = mris_read_nii_vox2tkr(nii)
%MRIS_READ_VOX2TKR_NII  extract vox2ras-tkr matrix from nii header struct
%
% M0_vox2tkr = mris_read_nii_vox2tkr(nii)
%
%
% see also MRIS_READ_VOX2TKR, MRIS_READ_NII.

% Jonathan Polimeni <jonp@nmr.mgh.harvard.edu>, 2012/dec/26
% $Id: mris_read_nii_vox2tkr.m,v 1.1 2013/02/18 05:32:11 jonp Exp $
%**************************************************************************%

  VERSION = '$Revision: 1.1 $';
  if ( nargin == 0 ), help(mfilename); return; end;


  %==--------------------------------------------------------------------==%


  ndims = nii.dim(1);

  vox_mm = nii.pixdim(2:4);  % distance (delta) between voxels in mm
  vox_count  = nii.dim(2:4);

  FOV_mm = vox_mm .* vox_count;

  Sxyz_c = FOV_mm/2';

  % the "tkregister" version is an XYZ space in mm units, but:
  % cols are mapped to -X, slcs are mapped to +Y, and rows are mapped to -Z.
  M0_vox2tkr = [[-vox_mm(1), 0, 0; 0, 0, +vox_mm(3); 0 -vox_mm(2) 0], [+Sxyz_c(1);-Sxyz_c(3);+Sxyz_c(2)]; [0 0 0 1]];


  return;
