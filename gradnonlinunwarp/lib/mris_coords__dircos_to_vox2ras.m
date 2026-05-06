% mris_coords__dircos_to_vox2ras.m

function [M0_vox2ras, M0_vox2tkr] = mris_coords__dircos_to_vox2ras(COL_dircos_RAS, LIN_dircos_RAS, IMG_dircos_RAS, cras, vox_count, vox_mm)
%MRIS_COORDS__DIRCOS_TO_VOX2RAS
%
% [M0_vox2ras, M0_vox2tkr] = mris_coords__dircos_to_vox2ras(COL_dircos_RAS, LIN_dircos_RAS, IMG_dircos_RAS, cras, vox_count, vox_mm)
%
%

% jonathan polimeni <jonp@nmr.mgh.harvard.edu>, 2013/feb/12
% $Id: mris_coords__dircos_to_vox2ras.m,v 1.1 2013/02/18 05:32:11 jonp Exp $
%**************************************************************************%

  VERSION = '$Revision: 1.1 $';
  if ( nargin == 0 ), help(mfilename); return; end;


  COL_dircos_RAS = COL_dircos_RAS(:);
  LIN_dircos_RAS = LIN_dircos_RAS(:);
  IMG_dircos_RAS = IMG_dircos_RAS(:);
  cras           = cras(:);
  vox_count      = vox_count(:);
  vox_mm         = vox_mm(:);

  % rotation component of matrix, with axis of rotation at centroid of image
  % volume
  Mdc = [COL_dircos_RAS, LIN_dircos_RAS, IMG_dircos_RAS];

  m = [ [Mdc*diag(vox_mm), [0; 0; 0]]
	[0,0,0,1] ];

  FOV_mm = vox_mm .* vox_count;
  
  D = diag(vox_mm);
  
  % XYZ of center: shift in mm between corner and center
  Pcrs_c = vox_count/2;

  % previously, Pxyz_c = FOV_mm/2, but "Pxyz_c" variable name is also used for cras
  Sxyz_c = D * Pcrs_c;
  
  % displacement vector: shift of the volume such that the corner lands at
  % the location specified in the header (i.e., the difference of two "centers")
  % a.k.a. P0
  D_corner_RAS = cras - (Mdc * D * Pcrs_c);

  M0_vox2ras = [[ m(1:3,1:3), D_corner_RAS(1:3) ]; [0,0,0,1]];


  % the "tkregister" version is an XYZ space in mm units, but:
  % cols are mapped to -X, slcs are mapped to +Y, and rows are mapped to -Z.
  M0_vox2tkr = [[-vox_mm(1), 0, 0; 0, 0, +vox_mm(3); 0 -vox_mm(2) 0], [+Sxyz_c(1);-Sxyz_c(3);+Sxyz_c(2)]; [0 0 0 1]];

  % note tkregister volume center is the origin of the mm coordinate system,
  % while vox2ras volume center is cras of the mm coordinate system
  
  
  return;



  %************************************************************************%
  %%% $Source: /space/repo/1/dev/dev/gradient_nonlin_unwarp/mris_coords__dircos_to_vox2ras.m,v $
  %%% Local Variables:
  %%% mode: Matlab
  %%% fill-column: 76
  %%% comment-column: 0
  %%% End:
