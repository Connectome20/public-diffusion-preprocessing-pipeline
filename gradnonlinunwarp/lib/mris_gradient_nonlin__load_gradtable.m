# mris_gradient_nonlin__load_gradtable.m

function [Dx,Dy,Dz, JacDet, G1xyz2rcs, GR, GC, GS, X, Y, Z] = mris_gradient_nonlin__load_gradtable(gradfilename)
%MRIS_GRADIENT_NONLIN__LOAD_GRADTABLE
%
% [Dx,Dy,Dz, JacDet, G1xyz2rcs] = mris_gradient_nonlin__load_gradtable(gradfilename)

% poached from "unwarp_resample.m"

% jonathan polimeni <jonp@nmr.mgh.harvard.edu>, 2010/jun/24
% $Id: mris_gradient_nonlin__load_gradtable.m,v 1.3 2013/07/21 17:16:32 jonp Exp $
%**************************************************************************%

  VERSION = '$Revision: 1.3 $';
  if ( nargin == 0 ), help(mfilename); return; end;


  %==--------------------------------------------------------------------==%

  if ( isempty(regexp(gradfilename, '\.gwt$')) ),
    gradfilename = strcat(gradfilename, '.gwt')
  end;

  disp(sprintf('==> [%s]: loading Gradient-nonlinearity Warp Table file "%s"...', mfilename, gradfilename));


  [fp, message] = fopen(gradfilename,'rb','b');

  if ( fp == -1 ),
    disp(sprintf('!!! [%s]: error opening file "%s" for reading', mfilename, gradfilename));
    error(message);
  end;

  % read text header
  header = '';
  header = vec(fread(fp, 100, 'uchar=>char'))';

  % number of grid points along each axis
  ncoords_col = fread(fp, 1, 'int32');
  ncoords_row = fread(fp, 1, 'int32');
  ncoords_slc = fread(fp, 1, 'int32');

  % total number of values
  nv = ncoords_col*ncoords_row*ncoords_slc;

  % extent of grid (in millimeters), given by first and last coordinates [2x1]
  coord_limits_x = fread(fp, 2, 'double');
  coord_limits_y = fread(fp, 2, 'double');
  coord_limits_z = fread(fp, 2, 'double');

  % displacement vectors (in meters)
  dx = fread(fp, nv, 'double').';
  dy = fread(fp, nv, 'double').';
  dz = fread(fp, nv, 'double').';

  % Jacobian determinant vector
  jacDet = fread(fp, nv, 'double')';

  fclose(fp);

  if ( ~isempty(header) ),
    disp(sprintf('==> [%s]: GWT header "%s"', mfilename, deblank(header)));
  end;
  disp(sprintf('==> [%s]: table limits are [%2.1f:%2.1f], [%2.1f:%2.1f], [%2.1f:%2.1f]', ...
               mfilename, ...
	       coord_limits_x(1), coord_limits_x(2), ...
               coord_limits_y(1), coord_limits_y(2), ...
               coord_limits_z(1), coord_limits_z(2)));

  
  %==--------------------------------------------------------------------==%

  % reshape vectors back into 3D arrays
  Dx = reshape(dx, ncoords_row, ncoords_col, ncoords_slc);
  Dy = reshape(dy, ncoords_row, ncoords_col, ncoords_slc);
  Dz = reshape(dz, ncoords_row, ncoords_col, ncoords_slc);

  JacDet = reshape(jacDet, ncoords_row, ncoords_col, ncoords_slc);


  %==--------------------------------------------------------------------==%

  % length along each axis
  lX = diff(coord_limits_x);
  lY = diff(coord_limits_y);
  lZ = diff(coord_limits_z);

  % lX/(ncoords_row-1) is like the size of each grid pixel along X in mm

  % calculate the matrix that maps grid array indices into scanner coordinates
  % (1-based, in units of mm)
  G1rcs2xyz = ...
      [  lX/(ncoords_row-1),  0,                   0,                  coord_limits_x(1)-lX/(ncoords_row-1);
         0,                   lY/(ncoords_col-1),  0,                  coord_limits_y(1)-lY/(ncoords_col-1);
         0,                   0,                   lZ/(ncoords_slc-1), coord_limits_z(1)-lZ/(ncoords_slc-1);
         0, 0, 0, 1];

  % inverse matrix maps scanner coordinates into grid array indices
  % (1-based, in units of mm)
  G1xyz2rcs = inv(G1rcs2xyz);

  % indices into gradient displacement volume
  [GR,GC,GS] = ndgrid(1:ncoords_row, 1:ncoords_col, 1:ncoords_slc);


  % reconstitute grid points (in units of mm)
  [X, Y, Z] = ndgrid(...
      linspace(coord_limits_x(1), coord_limits_x(2), ncoords_row), ...
      linspace(coord_limits_y(1), coord_limits_y(2), ncoords_col), ...
      linspace(coord_limits_z(1), coord_limits_z(2), ncoords_slc)  ...
      );


  return;


  %************************************************************************%
  %%% $Source: /space/repo/1/dev/dev/gradient_nonlin_unwarp/mris_gradient_nonlin__load_gradtable.m,v $
  %%% Local Variables:
  %%% mode: Matlab
  %%% fill-column: 76
  %%% comment-column: 0
  %%% End:
