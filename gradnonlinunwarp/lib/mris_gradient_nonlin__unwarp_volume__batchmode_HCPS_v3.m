% mris_gradient_nonlin__unwarp_volume__batchmode_HCPS_v3.m

function varargout = mris_gradient_nonlin__unwarp_volume__batchmode_HCPS_v3(...
    infile, outfile, gradname, varargin)
%MRIS_GRADIENT_NONLIN__UNWARP_VOLUME__BATCHMODE_HCPS_V3
%
% mris_gradient_nonlin__unwarp_volume__batchmode_HCPS_v3(infile, outfile, gradname)
%
% e.g.,
%
%  mris_gradient_nonlin__unwarp_volume__batchmode_HCPS_v3(...
%      'MPRAGE.mgz', ...
%      'MPRAGE_undis_offline.mgz', ...
%      'coeff_file.grad')
 
% jonathan polimeni <jonp@nmr.mgh.harvard.edu>, 2011/jan/25
% $Id: mris_gradient_nonlin__unwarp_volume__batchmode.m,v 1.5 2013/07/21 17:16:32 jonp Exp $
% 
% Modified to:
% 1. read header info of input image only 
% 2. output jacobian and deformation warp fields, no output of corrected
% image
% To be finished:
% 1. input image format other than nifti (.mgh, .mgz)
% 2. option of accepting a regfile
% Qiuyun Fan <qfan@nmr.mgh.harvard.edu>, 2014/02/05
%
% Modified to:
% 1. output gradient deviation (*_grad_dev.nii.gz) which can be later used
% to correct bvecs due to gradient nonlinearity effects.
% 2. default interpolation method changed to 'linear', given the smoothness
% of the gradient nonlinearity map.
% Qiuyun Fan <qfan@nmr.mgh.harvard.edu>, 2014/05/05
%**************************************************************************%


  if ( nargin == 0 ), help(mfilename); return; end;

  global DEBUG
  if ( ~isempty(DEBUG) ),
    DEBUG = 1
    dbstop if error
  end;


  %==--------------------------------------------------------------------==%

  OPTION__polarity = 'UNDIS';
  OPTION__calc_method = 'direct';
  OPTION__jacobian_correct = 0;
  OPTION__interp = 'linear';

  OPTION__JacDet_output = 0;
  OPTION__Displacement_output = 0;
  OPTION__grad_dev_output = 0;
  
  OPTION__regfile = '';

  if ( nargin >= 4 && ~isempty(varargin{1}) ),
    OPTION__polarity = varargin{1};
  end;

  if ( nargin >= 5 && ~isempty(varargin{2}) ),
    OPTION__calc_method = varargin{2};
  end;

  if ( nargin >= 6 && ~isempty(varargin{3}) ),
    OPTION__jacobian_correct = str2num(varargin{3});
    disp('OPTION__jacobian_correct was ignored. The correction can be performed with the jacobian output.')
  end;

  if ( nargin >= 7 && ~isempty(varargin{4}) ),
    OPTION__interp = varargin{4};
  end;

  if ( nargin >= 8 && ~isempty(varargin{5}) ),
    OPTION__JacDet_output = str2num(varargin{5});
  end;

  if ( nargin >= 9 && ~isempty(varargin{6}) ),
    OPTION__Displacement_output = str2num(varargin{6});
  end;

  if ( nargin >= 10 && ~isempty(varargin{7}) ),
    % OPTION__regfile = varargin{7};   % (QF)
    disp('OPTION_regfile is not built in yet! continue without regfile') % (QF)
    OPTION__regfile = ''; % (QF)
  end;

  if ( nargin >= 11 && ~isempty(varargin{8}) ), % (QF)
    OPTION__grad_dev_output = str2num(varargin{8});
  end;
  
  %==--------------------------------------------------------------------==%

  %pwd
  %t0 = timing();

  % HHL: Feb 8, 2026
  fshome = getenv('FREESURFER_HOME');
  addpath(fullfile(fshome,'matlab'));    
  addpath(fullfile(fshome,'fsfast','toolbox'));
  gnchome = getenv('GNC_HOME');
  addpath(fullfile(gnchome,'lib'));

  % addpath /usr/local/freesurfer/dev/matlab
  % disp(sprintf('addpath %s\n', fileparts(which(mfilename)) ));
  % addpath(fileparts(which(mfilename)))


  %  try,                                           1       2       3       4       5       6     7     8
  %                         1       2       3       4       5       6       7       8       9    10     11
    disp(sprintf('  %s(''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%d'', ''%s'', ''%d'', ''%d'', ''%s'', ''%d'')', ...
        mfilename, infile, outfile, gradname, OPTION__polarity, OPTION__calc_method, OPTION__jacobian_correct, ...
        OPTION__interp, OPTION__JacDet_output, OPTION__Displacement_output, OPTION__regfile,OPTION__grad_dev_output));

    if ( ~exist(infile, 'file') ),
      mris_error_exit('input volume file "%s" does not exist -- aborting', infile);
    end;

    outdir = fileparts(outfile);
    if ( ~isempty(outdir) && ~exist(fileparts(outfile), 'dir') ),
      mris_error_exit('output directory file "%s" does not exist -- aborting', outdir);
    end;


    extind = cell2mat(regexp(infile, {'\.mgz$', '\.mgh$', '\.nii.gz$','\.nii$'}));
    
    
    sepind = regexp(infile, '/');
    if ( ~isempty(sepind) ),
      namestr = infile((sepind(end)+1):extind-1);
    else,
      namestr = infile(1:extind-1);
    end;


    infiletype = 'unknown';

    if ( ~isempty(cell2mat( regexp(infile, {'\.mgz$',    '\.mgh$'}) )) ),
      infiletype = 'mgz';
    end;
    if ( ~isempty(cell2mat( regexp(infile, {'\.nii.gz$', '\.nii$'}) )) ),
      infiletype = 'nii';
    end;

    mr_parms = [];
    switch infiletype,
     case {'mgz'},
         disp('mgz file type is not supported yet, only nii is supported for now.'); % (QF)
%       [I, M0rcs2ras_src, M0rcs2tkr, mr_parms] = mris_read_mgh(infile); % (QF)
     case {'nii'},
         nii = load_nifti(infile,'hdronly'); % (QF)
         I = zeros(nii.dim(2),nii.dim(3),nii.dim(4),nii.dim(5));
         %I = nii.vol; % (QF)
         M0rcs2ras_src = nii.vox2ras;

         M0rcs2tkr = mris_read_nii_vox2tkr(nii);

     otherwise,
         %mris_error_exit('unsupported input file extension "%s" -- please
         %use "mgh", "mgz", "nii", or "nii.gz"', infile(extind:end)); % (QF)
         mris_error_exit('unsupported input file extension "%s" -- please use "nii", or "nii.gz"', ...
             infile(extind:end)); % (QF)
    end;


    %if ( ndims(I) > 4 ),   % (QF)
    %  mris_error_exit('input data has %d dimensions -- image data only up to FOUR dimensions is currently supported', ndims(I));
    %end;

    if ( isempty(cell2mat( regexp(outfile, {'\.mgz$', '\.mgh$', '\.nii.gz$', '\.nii$'}) )) ),
        %mris_error_exit('unsupported output file extension "%s" -- please
        %use "mgh", "mgz", "nii", or "nii.gz"', infile(extind:end));  % (QF)
        mris_error_exit('unsupported output file extension "%s" -- please use "nii", or "nii.gz"', infile(extind:end)); % QF
    end;


    %==--------------------------------------------------------------------==%
    %%%
    
    if ( ~isempty( OPTION__regfile ) ),
        
      [regpath, regname, regext] = fileparts(OPTION__regfile);
      
      
      switch lower(regext),
       case '.dat',

        %%% NOT YET IMPLEMENTED
        fprintf('-----------------------------------------------------------------\n');
        warning('registration via register.dat is not yet implemented !!!');
        fprintf('-----------------------------------------------------------------\n');
        exit;

        % register.dat is a.k.a. R0_anat2func_tkr, i.e., it is anat2func!
        [regmat, subject, inres, betres] = fmri_readreg(OPTION__regfile);

        [vol, M0_vox2ras_trg, M0_vox2tkr_trg, vox_mm] = mris_read_vol(OPTION__template);
        % TODO: use header-only version of reader so never have to allocate vol
        clear vol

        disp(sprintf('==> [%s]: applying tkregister-style register.dat transformation', mfilename));

%        Tvox2vox = inv(M0_vox2tkr_trg) * regmat * M0rcs2tkr;

       case '.lta',
        % assume ras2ras for now
        [Tras2ras, L0vox2ras_src, L0vox2TKR_src, L0vox2ras_trg, L0vox2TKR_trg, ...
         volume_trg, voxelsize_trg, lta_type_str] ...
            = mris_read_lta(OPTION__regfile);

        if ( ~strcmp(lta_type_str, 'LINEAR_RAS_TO_RAS') ),
          mris_error_exit('currently only RAS-to-RAS LTA transforms are supported');
        end;

        if ( ~all(size(I) == volume_trg.') ),
          mris_error_exit('size of target volume in LTA file does not match size of input volume (NOT YET SUPPORTED)');
        end;

        disp(sprintf('==> [%s]: applying FreeSurfer Linear Transform Array (LTA)', mfilename));

        % update VOX-to-RAS matrix with RAS2RAS transformation
        M0rcs2ras_src = Tras2ras * M0rcs2ras_src;
        M0rcs2ras_trg = L0vox2ras_trg;

       otherwise,
        mris_error_exit('unrecognized registration file extension: "%s"', regext);
      end;

    else,
        M0rcs2ras_trg = M0rcs2ras_src;
    end;


    %==--------------------------------------------------------------------==%
    %%% warp the data!
    
    M1rcs2ras_src = vox2ras_0to1(M0rcs2ras_src);
    M1rcs2ras_trg = vox2ras_0to1(M0rcs2ras_trg);
    
    mris_gradient_nonlin__setup
    
    if (     ~isempty(regexp(gradname, 'coeff_.*\.grad')) ),
      gradfile = gradname;
    elseif ( ~isempty(regexp(gradname, '\.gwt$')) ),
      gradfile = gradname;
      OPTION__calc_method = 'lookup';
    else,
        gradfile = gradname; % HHL, Feb 8, 2026
      % gradfile = mris_gradient_nonlin__pick_coeff_file(gradname);
    end;

    
    % JacDet is map defined on original grid, JacDetw is same map
    % interpolated onto warped grid
    % (VR0, VC0, and VS0 are 0-based indices!)
%     [Iw, JacDet, JacDetw, VR0, VC0, VS0, VX, VY, VZ] = mris_gradient_nonlin__unwarp_volume(I, ...
%                                                   M1rcs2ras_trg, M1rcs2ras_src, ...
%                                                   gradfile, ...
%                                                   OPTION__calc_method, ...
%                                                   OPTION__polarity, ...
%                                                   OPTION__jacobian_correct, ...
%                                                   OPTION__interp);  % (QF)
%     [Iw, JacDet, JacDetw, VR0, VC0, VS0, VX, VY, VZ] = mris_gradient_nonlin__unwarp_volume_noimgout(I, ...
%                                                   M1rcs2ras_trg, M1rcs2ras_src, ...
%                                                   gradfile, ...
%                                                   OPTION__calc_method, ...
%                                                   OPTION__polarity, ...
%                                                   OPTION__jacobian_correct, ...
%                                                   OPTION__interp);    % (QF, v2)
    [Iw, JacDet, JacDetw, VR0, VC0, VS0, VX, VY, VZ, ~, ~,~, Gx, Gy, Gz] = mris_gradient_nonlin__unwarp_volume_grad_dev(I, ...
                                                  M1rcs2ras_trg, M1rcs2ras_src, ...
                                                  gradfile, ...
                                                  OPTION__calc_method, ...
                                                  OPTION__polarity, ...
                                                  OPTION__jacobian_correct, ...
                                                  OPTION__interp);    % (QF, v3)                                            

    %==--------------------------------------------------------------------==%

%     [fp, message] = fopen(outfile, 'w');               % (QF)
%     if ( fp == -1 ),
%       fclose(fp);
%       mris_error_exit(message);
%     end;
%     fclose(fp);

    pathstr = fileparts(outfile);

    extind = cell2mat(regexp(outfile, {'\.mgz$', '\.mgh$', '\.nii.gz$', '\.nii$'}));
    ext = outfile(extind:end);

    % output the auxiliary files with base of input name and path of output name
    outstr = fullfile(pathstr, namestr);

    outfiletype = 'unknown';

    if ( ~isempty(cell2mat( regexp(outfile, {'\.mgz$',    '\.mgh$'}) )) ),
      outfiletype = 'mgz';
    end;
    if ( ~isempty(cell2mat( regexp(outfile, {'\.nii.gz$', '\.nii$'}) )) ),
      outfiletype = 'nii';
    end;

    switch outfiletype,
     case {'mgz'},

      save_mgh(Iw, outfile, M0rcs2ras_trg, mr_parms);

      if ( OPTION__JacDet_output ),
        % jacdetinv is inverse jacobian; forward jacobian > 1 indicates a
        % compression of voxel sizes (which is counter-intuitive), whereas
        % inverse jacobian < 1 indicates a compression of voxel sizes---so
        % inverse jacobian is proportional to voxel volume AND inverse
        % warped jacobian when polarity is UNDIS is in true object
        % coordinates.
        save_mgh(JacDet,     regexprep(outfile, ext, ['__jacobian_bias_orig', ext]), M0rcs2ras_trg, mr_parms);
        save_mgh(1./JacDetw, regexprep(outfile, ext, ['__voxel_volumes_warp', ext]), M0rcs2ras_trg, mr_parms);
      end;

      if ( OPTION__Displacement_output ),
%        save_mgh(VR0, regexprep(outfile, ext, ['__VR0', ext]), M0rcs2ras_trg, mr_parms);
%        save_mgh(VC0, regexprep(outfile, ext, ['__VC0', ext]), M0rcs2ras_trg, mr_parms);
%        save_mgh(VS0, regexprep(outfile, ext, ['__VS0', ext]), M0rcs2ras_trg, mr_parms);

        save_mgh(cat(4, VR0, VC0, VS0), [outstr, '__deform_grad_rel', ext], M0rcs2ras_trg, mr_parms);
        save_mgh(cat(4, VX,  VY,  VZ),  [outstr, '__deform_grad_abs', ext], M0rcs2ras_trg, mr_parms);

        % mris_save_m3z(cat(4, VX,  VY,  VZ), ,  [outstr, '__deform_grad_rel.m3z'], M0rcs2ras_trg);

      end;

     case {'nii'},

%       if ( strcmp(infiletype, 'nii') ),                            % (QF)
%         nii.vol = Iw;
%         nii.datatype = 16;
%         save_nifti(nii, outfile);
%       else,
%         warning('to write output in NIFTI format input must also be NIFTI; writing MGZ...');
%         save_mgh(Iw, fullfile(pathstr, [outstr, '.mgz']), M0rcs2ras_trg);
%       end;


      if ( OPTION__JacDet_output ),
        nii.vol = JacDet;
        nii.datatype = 16;
        save_nifti(nii, regexprep(outfile, ext, ['_jacobian_bias_orig', ext]));

        nii.vol = 1./JacDetw;
        save_nifti(nii, regexprep(outfile, ext, ['_voxel_volumes_warp', ext]));
      end;


      if ( OPTION__Displacement_output ),
%        nii.vol = VR0;
%        save_nifti(nii, regexprep(outfile, ext, ['__VR0', ext]));
%
%        nii.vol = VC0;
%        save_nifti(nii, regexprep(outfile, ext, ['__VC0', ext]));
%
%        nii.vol = VS0;
%        save_nifti(nii, regexprep(outfile, ext, ['__VS0', ext]));

        nii4 = nii;   % output displacement as 4D image % (QF)
        nii4.dim = [4, nii.dim(2),nii.dim(3),nii.dim(4), 3, 1,1,1];   
        nii4.datatype = 16;

        nii4.vol = cat(4, VR0, VC0, VS0);
        save_nifti(nii4, [outstr, '_deform_grad_rel', ext]);  % (QF)

        nii4.vol = cat(4, VX,  VY,  VZ);
        save_nifti(nii4, [outstr, '_deform_grad_abs', ext]);  % (QF)

        % Output L matrix (HHL)
        system(sprintf('$FSL_DIR/bin/calc_grad_perc_dev --fullwarp=%s --out=%s --verbose',...
            [outstr, '_deform_grad_rel', ext],...
            regexprep(outfile, ext, '_grad_dev') ));

        Lix = mris_read_nii(regexprep(outfile, ext, ['_grad_dev_x', ext]))/100;
        Liy = mris_read_nii(regexprep(outfile, ext, ['_grad_dev_y', ext]))/100;
        Liz = mris_read_nii(regexprep(outfile, ext, ['_grad_dev_z', ext]))/100;
        Lix(:,:,:,1) = Lix(:,:,:,1)+1;
        Liy(:,:,:,2) = Liy(:,:,:,2)+1;
        Liz(:,:,:,3) = Liz(:,:,:,3)+1;
        % Lij = zeros([size(Lix,1:3), 3, 3]);
        % Lij(:,:,:,:,1) = Lix;
        % Lij(:,:,:,:,2) = Liy;
        % Lij(:,:,:,:,3) = Liz;
        Lij = zeros([size(Lix,1:3), 9]);
        Lij(:,:,:,1:3) = Lix;
        Lij(:,:,:,4:6) = Liy;
        Lij(:,:,:,7:9) = Liz;

        nii4.dim = [4, nii.dim(2),nii.dim(3),nii.dim(4), 9, 1, 1, 1]; 
        nii4.vol = single(Lij);
        save_nifti(nii4, regexprep(outfile, ext, ['_L_matrix', ext]));

        Lij = reshape(Lij, [size(Lij, 1:3), 3, 3]);
        Lij = permute(Lij, [4 5 1 2 3]);
        LtL = pagemtimes(pagetranspose(Lij), Lij);
        b = LtL(1,1,:,:,:)/3 + LtL(2,2,:,:,:)/3 + LtL(3,3,:,:,:)/3;
        b = squeeze(b);
        nii4.dim = [3, nii.dim(2),nii.dim(3),nii.dim(4), 1, 1, 1, 1]; 
        nii4.vol = b;
        save_nifti(nii4, regexprep(outfile, ext, ['_b_scale', ext]));

      end;
        if (OPTION__grad_dev_output)   % (QF)
            nii4 = nii;     % output gradient deviation as 4D image % (QF)
            nii4.dim = [4, nii.dim(2),nii.dim(3),nii.dim(4), 3, 1,1,1];
            nii4.datatype = 16;
            
            nii4.vol = cat(4, Gx-1,  Gy-1,  Gz-1); % relative deviation from ideal (QF)
            save_nifti(nii4, [outstr, '_grad_dev', ext]);
        end
     otherwise,
      mris_error_exit('unsupported output file extension "%s" -- please use "mgh", "mgz", "nii", or "nii.gz"', ext);
    end;


  %==--------------------------------------------------------------------==%

%  catch,
%
%    err = lasterror;
%
%    beep
%    fprintf(1, '!!! %s\n\n', err.message);
%    disp(err.stack(1))
%    if ( length(err.stack) > 1 ),
%      disp(err.stack(end))
%    end;
%
%    disp(ID);
%    disp(version);
%
%    if ( DEBUG ),
%      keyboard;
%    end;
%
%  end;


  %timing(t0);

  % since called in batch mode, always exit function upon completion EXCEPT
  % FOR THIS HCPS VERSION WHICH IS RUN INSIDE MATLAB
  %exit


  return;
