% mris_read_mgh.m

function [vol, M0_vox2ras, M0_vox2tkr, mr_parms, delta] = mris_read_mgh(filename)
%MRIS_READ_MGH  wrapper around "load_mgh"
%
% [vol, M0_vox2ras, M0_vox2tkr] = mris_read_mgh(filename)

% jonathan polimeni <jonp@nmr.mgh.harvard.edu>, 2011/mar/28
% $Id: mris_read_mgh.m,v 1.5 2013/02/18 05:32:11 jonp Exp $
%**************************************************************************%

  VERSION = '$Revision: 1.5 $';
  if ( nargin == 0 ), help(mfilename); return; end;


  %==--------------------------------------------------------------------==%

  % local version returns tkr version of vox2ras matrix
  [vol, M0_vox2ras, M0_vox2tkr, mr_parms, delta] = load_mgh_local(filename);

  
  return;
