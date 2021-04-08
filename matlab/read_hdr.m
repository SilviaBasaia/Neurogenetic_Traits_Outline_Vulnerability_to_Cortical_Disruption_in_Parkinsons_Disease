function hdr= read_hdr(filename,machine)
 isOctave = exist('OCTAVE_VERSION', 'builtin') ~= 0;
 if isOctave
    warning('off', 'Octave:possible-matlab-short-circuit-operator');
 end
 % Check if file exist
 if ~exist(filename,'file')
    error(['File doesn''t exist: ',filename]);
    confirm_recursive_rmdir(0);
 end 

 
 %If compressed unzip the file
 [pathstr,name,ext] = fileparts(filename); 
 if strcmp(ext,'.gz')
	tmpDir = tempname;
    mkdir(tmpDir);
     if isOctave
	  copyfile(filename,tmpDir);
      filename = gunzip([tmpDir '/' name ext ], tmpDir);
    else
      filename = gunzip(filename, tmpDir);
    end
    filename = char(filename);
 end
 
 %If machine not defined: Check machine and if is valid nifti image
 if nargin<2
    machine = 'ieee-le';
    fid = fopen(filename,'r',machine);
    if (fid < 0)
      error(sprintf('Cannot open file %s.',filename));
    else
      fseek(fid,0,'bof');
      testval=fread(fid,1,'int32');
	  fclose(fid);
      if testval ~= 348
        switch machine,
           case 'ieee-le', machine = 'ieee-be';
           case 'ieee-be', machine = 'ieee-le';
        end

        fid = fopen(filename,'r',machine);
        if fid < 0,
            error(sprintf('Cannot open file %s.',filename));
        else
            fseek(fid,0,'bof');
            if fread(fid,1,'int32') ~= 348
               error(sprintf('File format is not valid',filename));
            end
            fclose(fid);
        end
       end
    end
 end
 
 v6 = version;
 if str2num(v6(1))<6
    directchar = '*char';
 else
    directchar = 'uchar=>char';
 end

 %Read header
 fid = fopen(filename,'r',machine);
 fseek(fid,0,'bof');
 
 %Header key
 hdr.header_key=[];
 hdr.header_key.sizeof_hdr    = fread(fid, 1,'int32')';	% should be 348!
 hdr.header_key.data_type     = deblank(fread(fid,10,directchar)');
 hdr.header_key.db_name       = deblank(fread(fid,18,directchar)');
 hdr.header_key.extents       = fread(fid, 1,'int32')';
 hdr.header_key.session_error = fread(fid, 1,'int16')';
 hdr.header_key.regular       = fread(fid, 1,directchar)';
 hdr.header_key.dim_info      = fread(fid, 1,'uchar')';
 
 %Image dimension
 hdr.image_dimension=[];
 hdr.image_dimension.dim        = fread(fid,8,'int16')';
 hdr.image_dimension.intent_p1  = fread(fid,1,'float32')';
 hdr.image_dimension.intent_p2  = fread(fid,1,'float32')';
 hdr.image_dimension.intent_p3  = fread(fid,1,'float32')';
 hdr.image_dimension.intent_code = fread(fid,1,'int16')';
 hdr.image_dimension.datatype   = fread(fid,1,'int16')';
 hdr.image_dimension.bitpix     = fread(fid,1,'int16')';
 hdr.image_dimension.slice_start = fread(fid,1,'int16')';
 hdr.image_dimension.pixdim     = fread(fid,8,'float32')';
 hdr.image_dimension.vox_offset = fread(fid,1,'float32')';
 hdr.image_dimension.scl_slope  = fread(fid,1,'float32')';
 hdr.image_dimension.scl_inter  = fread(fid,1,'float32')';
 hdr.image_dimension.slice_end  = fread(fid,1,'int16')';
 hdr.image_dimension.slice_code = fread(fid,1,'uchar')';
 hdr.image_dimension.xyzt_units = fread(fid,1,'uchar')';
 hdr.image_dimension.cal_max    = fread(fid,1,'float32')';
 hdr.image_dimension.cal_min    = fread(fid,1,'float32')';
 hdr.image_dimension.slice_duration = fread(fid,1,'float32')';
 hdr.image_dimension.toffset    = fread(fid,1,'float32')';
 hdr.image_dimension.glmax      = fread(fid,1,'int32')';
 hdr.image_dimension.glmin      = fread(fid,1,'int32')';

 %Data history
 hdr.data_history=[];
 hdr.data_history.descrip     = deblank(fread(fid,80,directchar)');
 hdr.data_history.aux_file    = deblank(fread(fid,24,directchar)');
 hdr.data_history.qform_code  = fread(fid,1,'int16')';
 hdr.data_history.sform_code  = fread(fid,1,'int16')';
 hdr.data_history.quatern_b   = fread(fid,1,'float32')';
 hdr.data_history.quatern_c   = fread(fid,1,'float32')';
 hdr.data_history.quatern_d   = fread(fid,1,'float32')';
 hdr.data_history.qoffset_x   = fread(fid,1,'float32')';
 hdr.data_history.qoffset_y   = fread(fid,1,'float32')';
 hdr.data_history.qoffset_z   = fread(fid,1,'float32')';
 hdr.data_history.srow_x      = fread(fid,4,'float32')';
 hdr.data_history.srow_y      = fread(fid,4,'float32')';
 hdr.data_history.srow_z      = fread(fid,4,'float32')';
 hdr.data_history.intent_name = deblank(fread(fid,16,directchar)');
 hdr.data_history.magic       = deblank(fread(fid,4,directchar)');

 fseek(fid,253,'bof');
 hdr.data_history.originator  = fread(fid, 5,'int16')';
    
 if ~strcmp(hdr.data_history.magic, 'n+1') & ~strcmp(hdr.data_history.magic, 'ni1')
    hdr.data_history.magic.qform_code = 0;
    hdr.data_history.magic.sform_code = 0;
 end	
	
 
 fclose(fid);
 
 
 %Remove temp folder if gz file
 if exist('tmpDir', 'var')
   rmdir(tmpDir,'s');
 end
 
