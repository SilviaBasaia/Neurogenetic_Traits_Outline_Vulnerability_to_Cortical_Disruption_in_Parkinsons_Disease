function save_nii(hdr,img,filename)
% Adaptation from https://es.mathworks.com/matlabcentral/fileexchange/8797-tools-for-nifti-and-analyze-image
% Suports Nifti (*.nii or *.nii.gz) and analyze data (*.hdr/*.img)

 if nargin<3
    error('You must specify 3 arguments hdr, img and output file. Usage: save_nii_new(hdr,img,out_file)');
 end

 [pathstr,name,ext] = fileparts(filename); 

 %Check if data will be comrpessed
 togz=0;
 if strcmp(ext,'.gz')
    togz=1;
    if strcmp(pathstr,'')
	[pathstr,name,ext] = fileparts(name);
    else
        [pathstr,name,ext] = fileparts([pathstr,'/',name]);
    end
 end
 if strcmp(pathstr,'')
    filename=name;
 else
    filename=[pathstr,'/',name];
 end

  %Check data type
  isnifti=1;
  if ~strcmp(ext,'.nii')
    isnifti=0;
  end

  % Write image

   switch double(hdr.image_dimension.datatype),
   case   1,
      hdr.image_dimension.bitpix = int16(1 ); precision = 'ubit1';
   case   2,
      hdr.image_dimension.bitpix = int16(8 ); precision = 'uint8';
   case   4,
      hdr.image_dimension.bitpix = int16(16); precision = 'int16';
   case   8,
      hdr.image_dimension.bitpix = int16(32); precision = 'int32';
   case  16,
      hdr.image_dimension.bitpix = int16(32); precision = 'float32';
   case  32,
      hdr.image_dimension.bitpix = int16(64); precision = 'float32';
   case  64,
      hdr.image_dimension.bitpix = int16(64); precision = 'float64';
   case 128,
      hdr.image_dimension.bitpix = int16(24); precision = 'uint8';
   case 256 
      hdr.image_dimension.bitpix = int16(8 ); precision = 'int8';
   case 511,
      hdr.image_dimension.bitpix = int16(96); precision = 'float32';
   case 512 
      hdr.image_dimension.bitpix = int16(16); precision = 'uint16';
   case 768 
      hdr.image_dimension.bitpix = int16(32); precision = 'uint32';
   case 1024
      hdr.image_dimension.bitpix = int16(64); precision = 'int64';
   case 1280
      hdr.image_dimension.bitpix = int16(64); precision = 'uint64';
   case 1792,
      hdr.image_dimension.bitpix = int16(128); precision = 'float64';
   otherwise
      error('This datatype is not supported');
   end
   
   hdr.image_dimension.glmax = round(double(max(img(:))));
   hdr.image_dimension.glmin = round(double(min(img(:))));
   
   if isnifti==1
      fid = fopen(sprintf('%s.nii',filename),'w');
      
      if fid < 0,
         error(sprintf('Cannot open file %s.nii.',filename));
      end
      
      hdr.image_dimension.vox_offset = 352;
      hdr.data_history.magic = 'n+1';
      save_nii_hdr(hdr, fid);
	  
   else
      fid = fopen(sprintf('%s.hdr',filename),'w');
      
      if fid < 0,
         error(sprintf('Cannot open file %s.hdr.',filename));
      end
      
      hdr.image_dimension.vox_offset = 0;
      hdr.data_history.magic = 'ni1';
      save_nii_hdr(hdr, fid);    
      fclose(fid);
      fid = fopen(sprintf('%s.img',filename),'w');
   end

   ScanDim = double(hdr.image_dimension.dim(5));		% t
   SliceDim = double(hdr.image_dimension.dim(4));		% z
   RowDim   = double(hdr.image_dimension.dim(3));		% y
   PixelDim = double(hdr.image_dimension.dim(2));		% x
   SliceSz  = double(hdr.image_dimension.pixdim(4));
   RowSz    = double(hdr.image_dimension.pixdim(3));
   PixelSz  = double(hdr.image_dimension.pixdim(2));
   
   x = 1:PixelDim;

   if isnifti==1
      skip_bytes = double(hdr.image_dimension.vox_offset) - 348;
   else
      skip_bytes = 0;
   end

   %If RGB planes, this are expected to be in the 4th dimension of nii.img
   if  (double(hdr.image_dimension.datatype) == 128) | (double(hdr.image_dimension.datatype) == 511)
      if(size(img,4)~=3)
         error(['The NII structure does not appear to have 3 RGB color planes in the 4th dimension']);
      end
      img = permute(img, [4 1 2 3 5 6 7 8]);
   end


   %  For complex float32 or complex float64, voxel values include [real, imag]
   
   if hdr.image_dimension.datatype == 32 | hdr.image_dimension.datatype == 1792
      real_img = real(img(:))';
      img = imag(img(:))';
      img = [real_img; img];
   end

   if skip_bytes
      fwrite(fid, zeros(1,skip_bytes), 'uint8');
   end
   fwrite(fid, img, precision);
   fclose(fid);
  
  
  % Compress the data if requested
  if togz==1
     if isnifti==1
	    if exist([filename,'.nii.gz'])==2
		   delete([filename,'.nii.gz']); 
		end
	    gzip([filename, '.nii']);
        delete([filename, '.nii']);
	 else
	    if exist([filename,'.hdr.gz'])==2
		   delete([filename,'.hdr.gz']); 
		end
		if exist([filename,'.img.gz'])==2
		   delete([filename,'.img.gz']); 
		end
		gzip([filename, '.hdr']);
        delete([filename, '.hdr']);
	    gzip([filename, '.img']);
        delete([filename, '.img']);
	 end
  end

  return	

function save_nii_hdr(hdr, fid)  
  
  if ~isequal(hdr.header_key.sizeof_hdr,348),
      error('Header size must be 348.');
  end
   
  if hdr.data_history.qform_code == 0 & hdr.data_history.sform_code == 0
      hdr.data_history.sform_code = 1;
      hdr.data_history.srow_x(1) = hdr.image_dimension.pixdim(2);
      hdr.data_history.srow_x(2) = 0;
      hdr.data_history.srow_x(3) = 0;
      hdr.data_history.srow_y(1) = 0;
      hdr.data_history.srow_y(2) = hdr.image_dimension.pixdim(3);
      hdr.data_history.srow_y(3) = 0;
      hdr.data_history.srow_z(1) = 0;
      hdr.data_history.srow_z(2) = 0;
      hdr.data_history.srow_z(3) = hdr.image_dimension.pixdim(4);
      hdr.data_history.srow_x(4) = (1-hdr.data_history.originator(1))*hdr.image_dimension.pixdim(2);
      hdr.data_history.srow_y(4) = (1-hdr.data_history.originator(2))*hdr.image_dimension.pixdim(3);
      hdr.data_history.srow_z(4) = (1-hdr.data_history.originator(3))*hdr.image_dimension.pixdim(4);
   end
   
   % Header key
   fwrite(fid, hdr.header_key.sizeof_hdr(1),    'int32');	% must be 348.
   pad = zeros(1, 10-length(hdr.header_key.data_type));
   hdr.header_key.data_type = [hdr.header_key.data_type  char(pad)];
   fwrite(fid, hdr.header_key.data_type(1:10), 'uchar');
   pad = zeros(1, 18-length(hdr.header_key.db_name));
   hdr.header_key.db_name = [hdr.header_key.db_name  char(pad)];
   fwrite(fid, hdr.header_key.db_name(1:18), 'uchar');
   fwrite(fid, hdr.header_key.extents(1),       'int32');
   fwrite(fid, hdr.header_key.session_error(1), 'int16');
   fwrite(fid, hdr.header_key.regular(1),       'uchar');	% might be uint8
   fwrite(fid, hdr.header_key.dim_info(1),      'uchar');
   
   %Image dimension
   fwrite(fid, hdr.image_dimension.dim(1:8),        'int16');
   fwrite(fid, hdr.image_dimension.intent_p1(1),  'float32');
   fwrite(fid, hdr.image_dimension.intent_p2(1),  'float32');
   fwrite(fid, hdr.image_dimension.intent_p3(1),  'float32');
   fwrite(fid, hdr.image_dimension.intent_code(1),  'int16');
   fwrite(fid, hdr.image_dimension.datatype(1),     'int16');
   fwrite(fid, hdr.image_dimension.bitpix(1),       'int16');
   fwrite(fid, hdr.image_dimension.slice_start(1),  'int16');
   fwrite(fid, hdr.image_dimension.pixdim(1:8),   'float32');
   fwrite(fid, hdr.image_dimension.vox_offset(1), 'float32');
   fwrite(fid, hdr.image_dimension.scl_slope(1),  'float32');
   fwrite(fid, hdr.image_dimension.scl_inter(1),  'float32');
   fwrite(fid, hdr.image_dimension.slice_end(1),    'int16');
   fwrite(fid, hdr.image_dimension.slice_code(1),   'uchar');
   fwrite(fid, hdr.image_dimension.xyzt_units(1),   'uchar');
   fwrite(fid, hdr.image_dimension.cal_max(1),    'float32');
   fwrite(fid, hdr.image_dimension.cal_min(1),    'float32');
   fwrite(fid, hdr.image_dimension.slice_duration(1), 'float32');
   fwrite(fid, hdr.image_dimension.toffset(1),    'float32');
   fwrite(fid, hdr.image_dimension.glmax(1),        'int32');
   fwrite(fid, hdr.image_dimension.glmin(1),        'int32');
   
   %Data history
   pad = zeros(1, 80-length(hdr.data_history.descrip));
   hdr.data_history.descrip = [hdr.data_history.descrip  char(pad)];
   fwrite(fid, hdr.data_history.descrip(1:80), 'uchar');
   pad = zeros(1, 24-length(hdr.data_history.aux_file));
   hdr.data_history.aux_file = [hdr.data_history.aux_file  char(pad)];
   fwrite(fid, hdr.data_history.aux_file(1:24), 'uchar');
   fwrite(fid, hdr.data_history.qform_code,    'int16');
   fwrite(fid, hdr.data_history.sform_code,    'int16');
   fwrite(fid, hdr.data_history.quatern_b,   'float32');
   fwrite(fid, hdr.data_history.quatern_c,   'float32');
   fwrite(fid, hdr.data_history.quatern_d,   'float32');
   fwrite(fid, hdr.data_history.qoffset_x,   'float32');
   fwrite(fid, hdr.data_history.qoffset_y,   'float32');
   fwrite(fid, hdr.data_history.qoffset_z,   'float32');
   fwrite(fid, hdr.data_history.srow_x(1:4), 'float32');
   fwrite(fid, hdr.data_history.srow_y(1:4), 'float32');
   fwrite(fid, hdr.data_history.srow_z(1:4), 'float32');
   pad = zeros(1, 16-length(hdr.data_history.intent_name));
   hdr.data_history.intent_name = [hdr.data_history.intent_name  char(pad)];
   fwrite(fid, hdr.data_history.intent_name(1:16), 'uchar');
   pad = zeros(1, 4-length(hdr.data_history.magic));
   hdr.data_history.magic = [hdr.data_history.magic  char(pad)];
   fwrite(fid, hdr.data_history.magic(1:4),      'uchar');        

   
   %  check the file size is 348 bytes
   fbytes = ftell(fid);
   
   if ~isequal(fbytes,348),
      error(sprintf('Header size is not 348 bytes.'));
   end
  
   return
  
  
