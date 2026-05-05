% mris_read_vol.m

function [vol, M0_vox2ras, M0_vox2tkr, vox_mm] = mris_read_vol(infile)
%MRIS_READ_VOL  read in a MGZ or NII file and return coordinate matrices
%
% [vol, M0_vox2ras, M0_vox2tkr, vox_mm] = mris_read_vol(filename)
%
%
% see also MRIS_READ_MGH, MRIS_READ_NII.

% jonathan polimeni <jonp@nmr.mgh.harvard.edu>, 2011/apr/06
% $Id: mris_read_vol.m,v 1.1 2013/02/18 05:32:11 jonp Exp $
%**************************************************************************%

  VERSION = '$Revision: 1.1 $';
  if ( nargin == 0 ), help(mfilename); return; end;


  %==--------------------------------------------------------------------==%

  [pathstr, namestr, ext] = fileparts(infile);

  infiletype = 'unknown';

  if ( ~isempty(cell2mat( regexp(infile, {'\.mgz$',    '\.mgh$'}) )) ),
    infiletype = 'mgz';
  end;
  if ( ~isempty(cell2mat( regexp(infile, {'\.nii.gz$', '\.nii$'}) )) ),
    infiletype = 'nii';
  end;

  switch infiletype,
   case {'mgz'},
    [vol, M0_vox2ras, M0_vox2tkr, mr_parms, vox_mm] = mris_read_mgh(infile);
   case {'nii'},
    [vol, M0_vox2ras, M0_vox2tkr, nii] = mris_read_nii(infile);
    vox_mm = nii.pixdim(2:4);
   otherwise,
    error('unsupported input file extension "%s" -- please use "mgh", "mgz", "nii", or "nii.gz"', ext);
  end;


  return;
