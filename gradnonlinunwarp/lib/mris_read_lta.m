% mris_read_lta.m

function [T, M0_vox2ras_src, M0_vox2tkr_src, ...
	     M0_vox2ras_dst, M0_vox2tkr_dst, ...
	  volume_dst, voxelsize_dst, lta_type_str] = mris_read_lta(fname)
% M = lta_read(fname)



% some parts based on "lta_read.m" by Bruce Fischl


  fp = fopen(fname);
  if( fp < 0 ),
    error(sprintf('could not open file %s', fname));
  end;

  tline = fgetl(fp);
  while( (length(tline) > 0) & (tline(1) == '#') ),
    tline = fgetl(fp);
  end;

  lta_type = fscanf(fp, 'type      = %d\n');

  % #define LINEAR_VOX_TO_VOX       0
  % #define LINEAR_RAS_TO_RAS       1

  switch lta_type,
   case 0,
    lta_type_str = 'LINEAR_VOX_TO_VOX';
   case 1,
    lta_type_str = 'LINEAR_RAS_TO_RAS';
  end;

  lta_nxforms = fscanf(fp, 'nxforms   = %d\n');

  T = zeros(4,4, lta_nxforms);
  skipnextline = 0;

  for ind = 1:lta_nxforms,

    if ( ~skipnextline ),
      tline = fgetl(fp);  % mean
    end;
    tline = fgetl(fp);    % sigma
    tline = fgetl(fp);    % dimensions (type, rows, columns)

    for row = 1:4,
      tline = fgetl(fp);  % one row of matrix
      tmp = sscanf(tline, '%f');
      T(row,:, ind) = tmp';
    end;

    tline = fgetl(fp); % label
    if ( strncmp(tline, 'label', 5) ),
      label(ind) = sscanf(tline, 'label     = %d\n');
      skipnextline = 0;
    else,
      skipnextline = 1;
    end;
  end;


  % reverse the writing, formatted in "writeVolGeom"

  if ( ~skipnextline ),
    tline = fgetl(fp);  % src volume info
  end;
  valid_src = fgetl(fp);  % valid
  filename_src  = fscanf(fp, 'filename = %s');        fgetl(fp);
  volume_src    = fscanf(fp, 'volume = %d %d %d');    fgetl(fp);
  voxelsize_src = fscanf(fp, 'voxelsize = %e %e %e'); fgetl(fp);

  xras_src = fscanf(fp, 'xras   = %e %e %e\n');
  yras_src = fscanf(fp, 'yras   = %e %e %e\n');
  zras_src = fscanf(fp, 'zras   = %e %e %e\n');
  cras_src = fscanf(fp, 'cras   = %e %e %e\n');


  [M0_vox2ras_src, M0_vox2tkr_src] = mris_coords__dircos_to_vox2ras(...
      xras_src, yras_src, zras_src, cras_src, volume_src, voxelsize_src);


  tline = fgetl(fp);  % dst volume info
  valid_dst = fgetl(fp);  % valid
  filename_dst  = fscanf(fp, 'filename = %s');        fgetl(fp);
  volume_dst    = fscanf(fp, 'volume = %d %d %d');    fgetl(fp);
  voxelsize_dst = fscanf(fp, 'voxelsize = %e %e %e'); fgetl(fp);

  xras_dst = fscanf(fp, 'xras   = %e %e %e\n');
  yras_dst = fscanf(fp, 'yras   = %e %e %e\n');
  zras_dst = fscanf(fp, 'zras   = %e %e %e\n');
  cras_dst = fscanf(fp, 'cras   = %e %e %e\n');

  [M0_vox2ras_dst, M0_vox2tkr_dst] = mris_coords__dircos_to_vox2ras(...
      xras_dst, yras_dst, zras_dst, cras_dst, volume_dst, voxelsize_dst);


  fclose(fp);


  return;


  %************************************************************************%
  %%% $Source: /space/repo/1/dev/dev/gradient_nonlin_unwarp/mris_read_lta.m,v $
  %%% Local Variables:
  %%% mode: Matlab
  %%% fill-column: 76
  %%% comment-column: 0
  %%% End:
