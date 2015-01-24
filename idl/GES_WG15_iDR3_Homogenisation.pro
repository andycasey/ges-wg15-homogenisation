pro GES_WG15_iDR3_Homogenisation
;
;   
;
;

close, /all
 
;
;      Read the masterlist
;
      path= '/Users/fpatrick/Desktop/Dropbox_OBSPM/iDR3/FinalRecSet/' 
      path2='/Users/fpatrick/Desktop/Dropbox_OBSPM/'
      masterDR2 = path2 + 'WG15/iDR3Masterlist/GES_iDR3_SpectraMasterlist_short.fits'
      fileDR2 = path + masterDR2
      dataDR2 = mrdfits(fileDR2, 2, /SILENT)
;
;     the name DR2 has been kept but it shudl have been DR3 for DR3 
;
      dataDR2 = mrdfits('/Users/fpatrick/Desktop/Dropbox_OBSPM/WG15/iDR3Masterlist/GES_iDR3_SpectraMasterlist_short.fits',1)
      dataDR_previous = mrdfits('/Users/fpatrick/Desktop/Dropbox_OBSPM/WG15/iDR2Masterlist/GES_iDR2_Spectra_Masterlist.fits',1)
      dataDR2 = [dataDR_previous, dataDR2]
;      DR_WG13size = size(dataDR_WG13, /N_ELEMENTS)
      DR2size = size(dataDR2, /N_ELEMENTS)
      print, 'Size of the iDR2 masterlist ', DR2size


;
;     read the recommended parameter files
;     removing the rows with no TEFF values

      WG10 = path + 'GES_iDR3_WG10_Recommended.fits' 
      WG11 = path + 'GES_iDR3_WG11_Recommended.fits'
      WG12 = path + 'GES_iDR3_WG12_Recommended.fits'
      WG13 = path + 'GES_iDR3_WG13_Recommended.fits'
      WG14 = path + 'GES_iDR3_WG14_Recommended.fits'
      dataWG10_raw = mrdfits(WG10,1, head_10, /SILENT)
      size_WG10_raw = size(dataWG10_raw, /N_ELEMENTS)
      temp10 = where(dataWG10_raw.TEFF gt 2000 and dataWG10_raw.TEFF lt 200000, count)
      dataWG10 = dataWG10_raw(temp10)
      size_WG10 = size(dataWG10, /N_ELEMENTS)
      print, ' WG10 : ',size_WG10_raw, size_WG10
      
      dataWG11_raw = mrdfits(WG11,1, head_11, /SILENT)
      size_WG11_raw = size(dataWG11_raw, /N_ELEMENTS)
      temp11 = where(dataWG11_raw.TEFF gt 2000 and dataWG11_raw.TEFF lt 200000, count)
      dataWG11 = dataWG11_raw(temp11)
      size_WG11 = size(dataWG11, /N_ELEMENTS)
      print, ' WG11 : ',size_WG11_raw, size_WG11
     
      dataWG12_raw = mrdfits(WG12,1, head_12, /SILENT)
      size_WG12_raw = size(dataWG12_raw, /N_ELEMENTS)
      temp12 = where(dataWG12_raw.TEFF gt 2000 and dataWG12_raw.TEFF lt 200000, count)
      dataWG12 = dataWG12_raw
;
;  
;      we keep all the data even if stellar parameters  are NULL      
;      dataWG12 = dataWG12_raw(temp12)

      size_WG12 = size(dataWG12, /N_ELEMENTS)
      print, ' WG12 : ',size_WG12_raw, size_WG12      
            
      dataWG13_raw = mrdfits(WG13,1, head_13, /SILENT)
      size_WG13_raw = size(dataWG13_raw, /N_ELEMENTS)
      temp13 = where (dataWG13_raw.TEFF gt 2000 and dataWG13_raw.TEFF lt 200000, count)
      dataWG13 = dataWG13_raw(temp13)
      size_WG13 = size(dataWG13, /N_ELEMENTS)
      print, ' WG13 : ',size_WG13_raw, size_WG13      
      
      dataWG14 = mrdfits(WG14,1, head_14, /SILENT)
      size_WG14 = size(dataWG14, /N_ELEMENTS)


;
;        vrad offset table 
;
       vrad_off_HR10 =  0.00
       vrad_off_HR15N = -0.13
       vrad_off_HR21 = -0.38
       vrad_off_U580 = +0.47
       vrad_off_HR09B = 0.00


;
;
;     need to add RA/DEC VEL from iDR2_HR15N_HR09B_recommended_wg10_LM.fits for HR15N SETUP.
;
;
     goto,  labelWG10
     WG10bis = path + 'WG10/iDR2_HR15N_HR09B_recommended_wg10_LM.fits'
     dataWG10bis= mrdfits(WG10bis,1, head_10bis, /SILENT)
;     presel_WG10_H15N = where( STRMATCH(strcompress(datawg14.SETUP, /remove_all),'*HR15N*', /FOLD_CASE) eq 1)  
;     subsample_WG10_HR15N
     match2, dataWG10.cname,  dataWG10bis.cname, bwg10, bwg10bis
              A_RA=dataWG10.RA
              B_RA=dataWG10bis.RA
              A_DEC=dataWG10.DEC
              B_DEC=dataWG10bis.DEC
              A_VEL=dataWG10.VEL
              B_VEL=dataWG10bis.VEL
              A_SNR=dataWG10.SNR
              B_SNR=dataWG10bis.SNR

     
     for i=0, size_WG10 - 1 do begin
          if bwg10(i) ne -1 then begin
              index=bwg10(i)
              A_RA[i] = B_RA[index]
              A_DEC[i] = B_DEC[index]
              A_VEL[i] = B_VEL[index]
               A_SNR[i] = B_SNR[index]
              
          endif     
     endfor
     dataWG10.RA=A_RA
     dataWG10.DEC=A_DEC
     dataWG10.VEL=A_VEL
     dataWG10.SNR=A_SNR
      
      labelWG10:
 
         
      
;
;    reading the file containing the List of benchmark stars
;
      BS_file = path + 'Benchmark_Stars.dat'
      BS_Number=96
      benchmarks = replicate({star, name: 'star', ra: 0.0, dec: 0.0},BS_number)
      openr,100,BS_File
;      readf,100,benchmarks,format='(a10,f19.12,f19.12)'
           readf,100,benchmarks,format='(a18,f18.12,f18.12)'
      close, 100


;
;     Initialisation of the vectors which will contain the index location  of the Bench Stars
;
      bs_all_DR2  = intarr(1)
      bs_all_DR_WG13 = intarr(1)
      bs_all_WG10 = intarr(1) 
      bs_all_WG11 = intarr(1)
      bs_all_WG12 = intarr(1)
      bs_all_WG13 = intarr(1)
      bs_all_WG14 = intarr(1)

      
;
;      We clean the masterlist from the benchmark stars and create :
;      -  a file  file_DR2_woBS
;      -  a structure DR2_woBS
;

      for k=0,BS_number-1 do begin
      ra = (benchmarks.ra)(k)
      dec = (benchmarks.dec)(k)
      precision = 0.01
      ra_up  = ra + precision
      ra_low = ra - precision
      dec_up = dec + precision
      dec_low = dec - precision
      starN= strcompress((benchmarks.name)(k),/remove_all)       
      starname ='*'+starN+'*'
      star1 = where((dataDR2.RA  lt  ra_up) $
                and   (dataDR2.RA  gt ra_low)   $
                and (dataDR2.DEC  lt dec_up)  $
                and (dataDR2.DEC  gt dec_low) $
                or ( STRMATCH(strcompress(dataDR2.target, /remove_all),starname, /FOLD_CASE) eq 1)  $
                or ( STRMATCH(strcompress(dataDR2.object, /remove_all),starname, /FOLD_CASE) eq 1) ,count)
;                print, '-------------------------------'
;                print, star1, 'count ', count
      if (count ne 0 ) then begin          
         bs_DR2 =   dataDR2(star1)
         bs_all_DR2 = [bs_all_DR2, star1]     
;        print, bs_WG10.target
      endif
      endfor
      bs_all_DR2 = bs_all_DR2(1:*)
;      print,  bs_all_WG10
      bs_DR2 =  dataDR2(bs_all_DR2)     
;      print, 'size data-WG10 ', size_WG10
      index_DR2_woBS = mg_complement(bs_all_DR2,DR2size)   
      DR2_woBS = dataDR2(index_DR2_woBS)
      size_DR2_woBS = size(DR2_woBS, /N_ELEMENTS)
      
       file_DR2_woBS = path + 'WG15_Products/DR2_woBS.fits'
       MWRFITS, DR2_woBS, file_DR2_woBS , head_12 , /CREATE, /No_comment     

      
;       
;     Cleaning the masterlist from duplicates
;     It seems that all the spectra are at leat in double (HR10 + HR 21 setups, uvu+uvl  for example)
;
       array = dataDR2.cname
       b = array[uniq(array, sort(array))]


       file_b = path + 'WG15_Products/DR2_cleaned.dat'
              openw, 10, file_b
             printf, 10, b
             close, 10
     


;
;

;
;     determine the number of matches masterlist - WG_results
;

       match, b,  dataWG10.cname,a10, b10,COUNT=countDR210
       match2, b,  dataWG10.cname,dr2_wg10, b10
       print, 'number of matches DR3-WG10 : ', countDR210

       match, b,  dataWG11.cname,a11, b11,COUNT=countDR211
       match2, b,  dataWG11.cname,dr2_wg11, b11
       print, 'number of matches DR3-WG11 : ', countDR211

       match, b,  dataWG12.cname,a12, b12,COUNT=countDR212
       match2, b,  dataWG12.cname,dr2_wg12, b12
       print, 'number of matches DR3-WG12 : ', countDR212

;
;     as WG13 has reprocessed DR2 and DR3 together, we have to consider the full DR2+DR3 masterlist
;       
       match, b,  dataWG13.cname,a13, b13,COUNT=countDR213
       match2, b,  dataWG13.cname,dr2_wg13, b13      
       print, 'number of matches DR3-WG13 : ', countDR213

;        
;
;      We start with WG14 to propagate the FLAGS to all the files
;
;                            WG14
;

     for k=0,BS_number-1 do begin
      ra = (benchmarks.ra)(k)
      dec = (benchmarks.dec)(k)
      precision = 0.01
      ra_up  = ra + precision
      ra_low = ra - precision
      dec_up = dec + precision
      dec_low = dec - precision
      starN= strcompress((benchmarks.name)(k),/remove_all)       
      starname ='*'+starN+'*'
      star1 = where((datawg14.RA  lt  ra_up) $
                and   (datawg14.RA  gt ra_low)   $
                and  (datawg14.RA  gt 0.0001)   $
                and (datawg14.DEC  lt dec_up)  $
                and (datawg14.DEC  gt dec_low) $
                or ( STRMATCH(strcompress(datawg14.target, /remove_all),starname, /FOLD_CASE) eq 1)  $
                or ( STRMATCH(strcompress(datawg14.object, /remove_all),starname, /FOLD_CASE) eq 1) ,count)
;                print, '-------------------------------'
;                print, star1, 'count ', count
      if (count ne 0 ) then begin          
      bs_WG14 =   datawg14(star1)
      bs_all_WG14 = [bs_all_WG14, star1]     
;      print, bs_WG14.target
      endif
      endfor
      bs_all_WG14 = bs_all_WG14(1:*)
;      print,  bs_all_WG14
      bs_WG14 =  datawg14(bs_all_WG14)     
      print, 'size data-WG14 ', size_WG14
      index_WG14_woBS = mg_complement(bs_all_WG14,size_WG14)   
      WG14_woBS = datawg14(index_WG14_woBS)
       file_BS_WG14 = path + 'WG15_Products/BS_WG14.fits'
       
        bs_WG14.SPT[0:*] =' '
        bs_WG14.EW_TABLE[0:*]=' '
        bs_WG14.WG[0:*]=' '
        bs_WG14.OBJECT[0:*]=' '
        bs_WG14.SETUP[0:*]=' '
        
        
        
        WG14_woBS.SPT[0:*]=' '
        WG14_woBS.EW_TABLE[0:*]=' '
        WG14_woBS.WG[0:*]=' '
        WG14_woBS.OBJECT[0:*]=' '
        WG14_woBS.SETUP[0:*]=' '


;
;      Move REMARK 1015B and 1015C to PECULiar
;
      print, 'WG14 : Move REMARK 1015B and 1015C flags to PECULI  column'
    
      ind_1015 = where( (STRMATCH(strcompress(WG14_woBS.REMARK, /remove_all),'*1015*', /FOLD_CASE) eq 1) , count)
       print, 'nb od flags ', count
        if (count gt 0 ) then begin
            a1=WG14_woBS[ind_1015]
            WG14_woBS_remark = WG14_woBS.remark
            WG14_woBS_peculi= WG14_woBS.peculi
            WG14_woBS_peculi[ind_1015] =  WG14_woBS_peculi[ind_1015] + '|'+strcompress(WG14_woBS_remark[ind_1015], /remove_all)
            WG14_woBS_remark[ind_1015] = '  '
            WG14_woBS.remark = WG14_woBS_remark
            WG14_woBS.peculi= WG14_woBS_peculi
     endif

        
 
       MWRFITS, bs_WG14, file_BS_WG14 , head_14 , /CREATE, /No_comment
       add_WG15_extension, file_BS_WG14, file_BS_WG14      
       
       file_WG14_woBS = path + 'WG15_Products/WG14_withoutBS.fits'
       MWRFITS, WG14_woBS, file_WG14_woBS, head_14 , /CREATE, /No_comment
       add_WG15_extension, file_WG14_woBS, file_WG14_woBS      
 
 

;
;
;          Benchmark Stars
;
;
      BS = path + 'Wg15_bench_ges_iDR3_110714.fits'
      dataBS= mrdfits(BS,1, head_BS, /SILENT)
      size_BS = size(dataBS, /N_ELEMENTS)
;      sxdelpar, head_BS, 'PECULI'
;      sxdelpar, head_BS, 'REMARK'
;      sxdelpar, head_BS, 'TECH'
;      sxaddpar, head_BS, 'PECULI', '          ', AFTER='E_CONVOL', FORMAT='A50'
;      sxaddpar, head_BS, 'REMARK', '          ', AFTER='PECULI', FORMAT='A5'
;      sxaddpar, head_BS, 'TECH', '          ', AFTER='REMARK', FORMAT='A21'
      
;----------------------------------------------      
;
;         ADDING RADIAL VELOCITIES  in Benchmark stars file from the masterlist
;
;----------------------------------------------
;
;     getting VRADs from Masterlist
;    
     dataBS.VRAD=dataBS.VEL
     dataBS.E_VRAD=!Values.F_NAN
     print, dataBS.VEL


;     for i=0, size_BS - 1 do begin
;     starname  = (dataBS.cname)[i]
      
;     res_HR10 = where(( STRMATCH(strcompress(dataDR2.cname, /remove_all),starname, /FOLD_CASE) eq 1)   $
;                   and (STRMATCH(strcompress(dataDR2.SETUP, /remove_all),'HR10*', /FOLD_CASE) eq 1 ))
      

;     res_U580l = where(( STRMATCH(strcompress(dataDR2.cname, /remove_all),starname, /FOLD_CASE) eq 1)   $
;             and (STRMATCH(strcompress(dataDR2.SETUP, /remove_all),'*U580*', /FOLD_CASE) eq 1 )  $
;              and (STRMATCH(strcompress(dataDR2.FILENAME, /remove_all),'uvl*', /FOLD_CASE) eq 1 ) )  

;     res_U580u = where(( STRMATCH(strcompress(dataDR2.cname, /remove_all),starname, /FOLD_CASE) eq 1)   $
;             and (STRMATCH(strcompress(dataDR2.SETUP, /remove_all),'*U580*', /FOLD_CASE) eq 1 )   $
;              and (STRMATCH(strcompress(dataDR2.FILENAME, /remove_all),'uvu*', /FOLD_CASE) eq 1 ))  

  
 
;     print, res_HR10    ,' size:', size(res_HR10, /N_ELEMENTS)
;     if ( size(res_HR10, /N_ELEMENTS) gt 1 ) then begin    ; to be modified if only a single vel per setup is given
;        sel_HR10 = dataDR2(res_HR10) 
;        best_HR10 = max(sel_HR10.SNR)
;     print, starname, ' HR10 ', best_HR10
;     endif
;     if ( size(res_U580l, /N_ELEMENTS) gt 1 ) then begin 
;        sel_U580l = dataDR2[res_U580l]    
;        best_U580l = max(sel_U580l.SNR)
;     print, starname, ' U580 ', best_U580l
;     endif 
;     if ( size(res_U580u, /N_ELEMENTS) gt 1 ) then begin 
;        sel_U580u = dataDR2[res_U580u]    
;        best_U580u = max(sel_U580u.SNR)
;     print, starname, ' U580 ', best_U580u
;     endif 


;     if ( (size(res_HR10, /N_ELEMENTS) gt 1  and  size(res_U580l, /N_ELEMENTS) eq 0 ))  then begin
;      print, 'selecting HR10 VEL ', size(res_HR10, /N_ELEMENTS), size(res_U580l, /N_ELEMENTS)
;;     (dataBS_VRAD)[i] = best_HR10
;     (dataBS_E_VRAD)[i] = !Values.F_NAN
;     endif
     
;     if ( size(res_U580u, /N_ELEMENTS) gt 1 ) then begin 
;     mean_vel = (best_U580l + best_U580u ) /2.
;     print, mean_vel
;     dataBS_VRAD[i] = mean_vel
;      vect = [best_U580l , best_U580u ]
;      dev =stddev(vect)
;     (dataBS_E_VRAD)[i] = dev
     
;     endif
     
;     print, i, ' ', (dataBS.VRAD)[i], ' ',  (dataBS.E_VRAD)[i]
   
;    print, toto 
     
;     endfor
      
;     dataBS.VRAD=dataBS_VRAD
;     dataBS.E_VRAD=dataBS_E_VRAD
     
     print, 'end job with radial velocities for BS file'

      
      print, 'removing the abundances for the Benchmark Stars data'

      remove_abund, dataBS
      
      dataBS.ENN_LOGG[0:*]=!Values.F_NAN
      dataBS.ENN_FEH[0:*]=!Values.F_NAN
      dataBS.NNE_TEFF[0:*]=-1
 
      dataBS.NNE_LOGG[0:*]=-1
      dataBS.NNE_FEH[0:*]=-1
 
      dataBS.ENN_XI[0:*]=!Values.F_NAN
      dataBS.NNE_XI[0:*]=-1
;      dataBS.VRAD[0:*]=!Values.F_NAN
      
;      dataBS.E_VRAD[0:*]=!Values.F_NAN
      dataBS.VSINI[0:*]=!Values.F_NAN
      dataBS.E_VSINI[0:*]=!Values.F_NAN
      dataBS.PECULI[0:*]=' '
      dataBS.REMARK[0:*]=' '
      dataBS.TECH[0:*]=' '


GET_DATE,dte
mkhdr, primheader,2
FXADDPAR, primheader, 'COMMENT', '-------------------------------------------------------------------'
FXADDPAR, primheader, 'COMMENT', 'GES WG  Benchmark Stars Recommended Results'
FXADDPAR, primheader, 'RELEASE', 'iDR2', 'Data release tag',AFTER='COMMENT'
sxdelpar, primheader, 'DATE'
FXADDPAR, primheader, 'DATETAB', dte, 'Date of production of table',AFTER='RELEASE'
FXADDPAR, primheader, 'INSTRUME', 'GIRAFFE|UVES', 'FLAMES instrument for this table',AFTER='DATETAB'
FXADDPAR, primheader, 'NODE1', 'WG15', 'Benchmark Stars',AFTER='INSTRUME'
FXADDPAR, primheader, 'NODE2', 'WG10', 'Benchmark Stars',AFTER='NODE1'
FXADDPAR, primheader, 'NODE3', 'WG11', 'Benchmark Stars',AFTER='NODE2'
FXADDPAR, primheader, 'NODE4', 'WG12', 'Benchmark Stars',AFTER='NODE3'

;Add in ADDTBEXT keyword to Primary Header  (Note ADDTABEXT didn't fit - oops)
FXADDPAR, primheader, 'ADDTBEXT',2,'Extension containing Additional Results Table',AFTER='NODE8'


      BS_extra = path + 'WG15_Products/WG15_bench_ges_extra_col.fits'
      dataBS_extra= mrdfits(BS_extra,1, head_BS, /SILENT)
      size_BS_extra = size(dataBS_extra, /N_ELEMENTS)

      file_WG15_BS = path + 'WG15_Products/WG15_Benchmark_Stars.fits'

;
;    copy the format from WG14 ! 
;

      temp= WG14_woBS[0:45]
      copy_struct, dataBS, temp
      dataBS = temp
      
      MWRFITS, priminfo, file_WG15_BS, primheader , /CREATE, /No_comment
      MWRFITS, dataBS, file_WG15_BS, head_BS , /No_comment
      add_WG15_extension, file_WG15_BS, file_WG15_BS    

     
;     - adding info in PROVENANCE column 
;     - merging the TARGET and SETUPS   
      
 
      test1 = mrdfits(file_WG15_BS , 1,head1, /SILENT)
      test2 = mrdfits(file_WG15_BS ,2, head2, /SILENT)

       test2.AVAILABLE_PAR=test1.WG +'|'+ test1.SETUP  
       test1SETUP=test1.SETUP   
       test2PROV_VRAD = test2.PROV_VRAD
       test1VRAD = test1.VRAD
       test2VRAD_OFFSET = test2.VRAD_OFFSET
       test2VRAD_OFFSETSOURCE = test2.VRAD_OFFSETSOURCE

      
;        for i=0, size_BS - 1 do begin
                

;       if ( STRMATCH(strcompress(test1SETUP(i), /remove_all),'*U580*', /FOLD_CASE) eq 1) then begin
;           test2PROV_VRAD(i) = 'ARCETRI'       
;           test2VRAD_OFFSET(i) = -0.56
;           test1VRAD(i) = test1VRAD(i) - 0.56
;           print, 'VRAD OFFSET for U580 = ',-0.56 , ' km/s'
;           test2VRAD_OFFSETSOURCE(i) = ' WG15'

;          test2PROV_VRAD(i) = 'ARCETRI'       
;           test2VRAD_OFFSET(i) = -0.56
;           test1VRAD(i) = test1VRAD(i) - 0.56
;           print, 'VRAD OFFSET for U580 = ',-0.56 , ' km/s'
;           test2VRAD_OFFSETSOURCE(i) = ' WG15'
           
           
;          endif   else begin
;                     print, 'VRAD OFFSET for HR10 = ', 0.00 , ' km/s'
;           test2PROV_VRAD(i) = 'CASU'       
;           test2VRAD_OFFSET(i) = 0.00
;           test2VRAD_OFFSETSOURCE(i) = ' WG15'
           
;           endelse
;        endfor
        
        for i=0, size_BS - 1 do begin
           test2PROV_VRAD(i) = 'CASU'       
           test2VRAD_OFFSET(i) = 0.00
           test2VRAD_OFFSETSOURCE(i) = ' WG15'
 
       endfor       
        
 
       test1.SETUP=test1SETUP   
       test2.PROV_VRAD = test2PROV_VRAD
;       test1.VRAD = test1VRAD
       test2.VRAD_OFFSET = test2VRAD_OFFSET
       test2.VRAD_OFFSETSOURCE = test2VRAD_OFFSETSOURCE
        
        test1.VEL[0:*]= !Values.F_NAN
        testfile = path + 'WG15_Products/WG15_Benchmark_Stars.fits'
        MWRFITS, priminfo, testfile, primheader , /CREATE, /No_comment
        mwrfits, test1, testfile, head_11, /No_comment    ; stealing the header from WG11
;        mwrfits, test1, testfile, head1, /No_comment
        mwrfits, test2, testfile, head2, /No_comment
 


;
;          WG11
;      
;      
            
;     print, benchmarks
      for k=0,BS_number-1 do begin
      ra = (benchmarks.ra)(k)
      dec = (benchmarks.dec)(k)
      precision = 0.01
      ra_up  = ra + precision
      ra_low = ra - precision
      dec_up = dec + precision
      dec_low = dec - precision
      starN= strcompress((benchmarks.name)(k),/remove_all)       
      starname ='*'+starN+'*'
      star1 = where((datawg11.RA  lt  ra_up) $
                and   (datawg11.RA  gt ra_low)   $
                and (datawg11.DEC  lt dec_up)  $
                and (datawg11.DEC  gt dec_low) $
                or ( STRMATCH(strcompress(datawg11.target, /remove_all),starname, /FOLD_CASE) eq 1)  $
                or ( STRMATCH(strcompress(datawg11.object, /remove_all),starname, /FOLD_CASE) eq 1) ,count)
;                print, '-------------------------------'
;                print, star1, 'count ', count
      if (count ne 0 ) then begin          
      bs_WG11 =   datawg11(star1)
      bs_all_WG11 = [bs_all_WG11, star1]     
;     print, bs_WG11.target
      endif
      endfor
;      bs_all_WG11 = bs_all_WG11(1:*) ; this was used for iDR2
      bs_all_WG11 = bs_all_WG11(0:*)
      
;      print,  bs_all_WG11
      bs_WG11 =  datawg11(bs_all_WG11)     
;      print, 'size data-WG11 ', size_WG11
      index_WG11_woBS = mg_complement(bs_all_WG11,size_WG11)   
      WG11_woBS = datawg11(index_WG11_woBS)
      size_WG11_woBS = size(WG11_woBS, /N_ELEMENTS)
;      val = "NULL"
      size_bs11 = size(bs_WG11, /N_ELEMENTS)
;
        bs_WG11.SPT[0:*] =' '
        bs_WG11.EW_TABLE[0:*]=' '
        WG11_woBS.SPT[0:*]=' '
        WG11_woBS.EW_TABLE[0:*]=' '


;
;      searching for stars in common WG11 - WG14
; 
; 
       print, ' appending flags for  WG11'     
    
       append_WG14_flags, WG11_woBS, WG14_woBS
;

;-------------------------------
;
;        WG11 RADIAL VELOCITY 
;
;-------------------------------

       transfer_DR2_U580_VEL, DR2_woBS, WG11_woBS, WG11_woBS


 
       file_BS_WG11 = path + 'WG15_Products/BS_WG11.fits'
       MWRFITS, bs_WG11, file_BS_WG11 , head_11 , /CREATE, /No_Comment
       test_WG11 =  path + 'WG15_Products/test_WG11.fits'
       add_WG15_extension,    WG11, test_WG11   
;       help, file_BS_WG11
       add_WG15_extension, file_BS_WG11, file_BS_WG11      

       WG11_woBS.REMARK[0:*]=' '
       WG11_woBS.TECH[0:*]=' '
       
       file_WG11_woBS = path + 'WG15_Products/WG11_withoutBS.fits'
       MWRFITS, WG11_woBS, file_WG11_woBS, head_11 , /CREATE, /No_comment
       add_WG15_extension, file_WG11_woBS, file_WG11_woBS      
 
;
;      WG11 :apply the radial velocity offset and fill the WG15 extension vrad_offset  and vrad offset source
;
      print, 'WG11 :apply the radial velocity offset and fill the WG15 extension vrad_offset  and vrad offset source'

       file_WG11_woBS = path + 'WG15_products/WG11_withoutBS.fits'
       test1 = mrdfits(file_WG11_woBS , 1,head1)
       test2 = mrdfits(file_WG11_woBS,2, head2)

       test1.VEL[0:*]= !Values.F_NAN
       test2.AVAILABLE_PAR='WG11|U580'      
       test2.PROV_VRAD = 'ARCETRI'       
       test2.VRAD_OFFSET = vrad_off_U580
       test1.VRAD = test1.VRAD + vrad_off_U580
       print, 'VRAD OFFSET for WG11 = ',vrad_off_U580 , ' km/s'
       test2.VRAD_OFFSETSOURCE = ' WG15'


        testfile = path + 'WG15_Products/WG11_withoutBS.fits'
        MWRFITS, priminfo, testfile, primheader , /CREATE, /No_comment
        mwrfits, test1, testfile, head1, /No_comment
        mwrfits, test2, testfile, head2, /No_comment
 

 

;
;   WG10 
;

      for k=0,BS_number-1 do begin
      ra = (benchmarks.ra)(k)
      dec = (benchmarks.dec)(k)
      precision = 0.01
      ra_up  = ra + precision
      ra_low = ra - precision
      dec_up = dec + precision
      dec_low = dec - precision
      starN= strcompress((benchmarks.name)(k),/remove_all)       
      starname ='*'+starN+'*'
      star1 = where((datawg10.RA  lt  ra_up) $
                and   (datawg10.RA  gt ra_low)   $
                and (datawg10.DEC  lt dec_up)  $
                and (datawg10.DEC  gt dec_low) $
                or ( STRMATCH(strcompress(datawg10.target, /remove_all),starname, /FOLD_CASE) eq 1)  $
                or ( STRMATCH(strcompress(datawg10.object, /remove_all),starname, /FOLD_CASE) eq 1) ,count)
;                print, '-------------------------------'
;                print, star1, 'count ', count
      if (count ne 0 ) then begin          
         bs_WG10 =   datawg10(star1)
         bs_all_WG10 = [bs_all_WG10, star1]     
;        print, bs_WG10.target
      endif
      endfor
      bs_all_WG10 = bs_all_WG10(1:*)
;      print,  bs_all_WG10
      bs_WG10 =  datawg10(bs_all_WG10)     
;      print, 'size data-WG10 ', size_WG10
      index_WG10_woBS = mg_complement(bs_all_WG10,size_WG10)   
      WG10_woBS = datawg10(index_WG10_woBS)
      size_WG10_woBS = size(WG10_woBS, /N_ELEMENTS)
      WG10_woBS.REMARK=' '
      WG10_woBS.PECULI=' '
      WG10_woBS.TECH=' '
      

      print, ' size_WG10_woBS ',  size_WG10_woBS 
      
;
;
;    removing cname in common with 
;
;      
      
      
       print, ' appending flags for  WG10'     
      append_WG14_flags, WG10_woBS, WG14_woBS


;
;     transferring the masterlist VEL column to WG10
;
       print, ' transferring the masterlist VEL column to WG10'
 
       transfer_DR2_WG10_VEL, dataDR2, WG10_woBS, WG10_woBS

  
       
       file_BS_WG10 = path + 'WG15_Products/BS_WG10.fits'
       MWRFITS, bs_WG10, file_BS_WG10 , head_10 , /CREATE, /No_comment
       add_WG15_extension, file_BS_WG10, file_BS_WG10     



      WG10_woBS.REMARK=' '
      WG10_woBS.PECULI=' '
      WG10_woBS.TECH=' '
        
       file_WG10_woBS = path + 'WG15_Products/WG10_withoutBS.fits'
       MWRFITS, WG10_woBS, file_WG10_woBS, head_10 , /CREATE, /No_comment
       add_WG15_extension, file_WG10_woBS, file_WG10_woBS   
       
;      WG10 :apply the radial velocity offset and fill the WG15 extension vrad_offset  and vrad offset source
;
       print, 'WG10 : apply the radial velocity offset and fill the WG15 extension vrad_offset  and vrad offset source'
       
       file_WG10_woBS = path + 'WG15_products/WG10_withoutBS.fits'
       test1 = mrdfits(file_WG10_woBS , 1,head1)
       test2 = mrdfits(file_WG10_woBS,2, head2)

       test1.VEL[0:*]= !Values.F_NAN
       test2.AVAILABLE_PAR='WG10'+'|'+test1.SETUP      
       test2.PROV_VRAD = 'CASU'  

;
;      HR15
;

       
       ind_hr15 = where( (STRMATCH(strcompress(test1.SETUP, /remove_all),'*HR15N*', /FOLD_CASE) eq 1) , count)
        a1=test1[ind_hr15]
        b1=test2[ind_hr15]
        
        print, 'nb of WG10 cnames with hr15 setup', count
        
        vrad_offset = test2.VRAD_OFFSET
        vrad_offset[ind_hr15]= vrad_off_HR15N
        test2.VRAD_OFFSET   =  vrad_offset 


        
        vrad_offsetsource = test2.VRAD_OFFSETSOURCE
        vrad_offsetsource[ind_hr15]= 'WG15'
        test2.VRAD_OFFSETSOURCE   =  vrad_offsetsource
        
        test1VRAD = test1.VRAD
        test1VRAD[ind_hr15] = test1VRAD[ind_hr15] + vrad_off_HR15N
        test1.VRAD = test1VRAD





;       print, toto     
       
        print, 'VRAD OFFSET for WG10 HR15 = ',vrad_off_HR15N , ' km/s'
 
        testfile = path + 'WG15_Products/WG10_withoutBS.fits'
        mwrfits, test1, testfile, head1, /CREATE, /No_comment
        mwrfits, test2, testfile, head2, /No_comment
 
       
          
;****************************************
;
;             WG12 
;
;****************************************

      for k=0,BS_number-1 do begin
      ra = (benchmarks.ra)(k)
      dec = (benchmarks.dec)(k)
      precision = 0.01
      ra_up  = ra + precision
      ra_low = ra - precision
      dec_up = dec + precision
      dec_low = dec - precision
      starN= strcompress((benchmarks.name)(k),/remove_all)       
      starname ='*'+starN+'*'
      star1 = where((datawg12.RA  lt  ra_up) $
                and   (datawg12.RA  gt ra_low)   $
                and (datawg12.DEC  lt dec_up)  $
                and (datawg12.DEC  gt dec_low) $
                or ( STRMATCH(strcompress(datawg12.target, /remove_all),starname, /FOLD_CASE) eq 1)  $
                or ( STRMATCH(strcompress(datawg12.object, /remove_all),starname, /FOLD_CASE) eq 1) ,count)
;                print, '-------------------------------'
;                print, star1, 'count ', count
      if (count ne 0 ) then begin          
      bs_WG12 =   datawg12(star1)
      bs_all_WG12 = [bs_all_WG12, star1]     
;      print, bs_WG12.target
      endif
      endfor
      bs_all_WG12 = bs_all_WG12(1:*)
;      print,  bs_all_WG12
      bs_WG12 =  datawg12(bs_all_WG12)     
;      print, 'size data-WG12 ', size_WG12
      index_WG12_woBS = mg_complement(bs_all_WG12,size_WG12)   
      WG12_woBS = datawg12(index_WG12_woBS)
      size_WG12_woBS = size(WG12_woBS, /N_ELEMENTS)
       print, ' appending WG14 flags for  WG12'            
       append_WG14_flags, WG12_woBS, WG14_woBS
    

;
;     transferring the masterlist VEL  and VRAD column to WG12
;
      print, 'transferring the masterlist VEL to WG12  and apply VRAD E_VRAD'
       transfer_DR2_WG12_VEL, DR2_woBS, WG12_woBS , WG12_woBS


;
;      WG12 : Looking for cnames observed both with UVES and Giraffe
;      and keep the UVES. 

       ind_WG12_U = where(STRMATCH(strcompress(wg12_woBS.SETUP, /remove_all),'*U580*', /FOLD_CASE) eq 1 ,nwg12_u, Complement = ind_WG12_Gir, ncomplement=nwg12_gir)
 
       print, size_WG12_woBS, ' nb of stars WG12 without BS'
       print, nwg12_u, ' stars observed with UVES by WG12'
       print, nwg12_gir, ' stars observed with Giraffe by WG12'
       
;
;     storing the indices as given in wg12_woBS
;
;       print, 'ind_WG12_Gir ', ind_WG12_Gir[0:10]
;       print, 'ind_WG12_u ', ind_WG12_u[0:10]
       
       wg12_u=wg12_woBS(ind_WG12_U)
       wg12_gir=wg12_woBS(ind_WG12_Gir)
       
;
;     selecting the cnames for which stellar parameters are given
;     no more selection on temperatures !!! 

;     selection in temp
;      ind_good_wg12_u = where (wg12_u.TEFF gt -2000 and wg12_u.TEFF lt 20000 , ngood_wg12_u)
;      ind_good_wg12_gir = where (wg12_gir.TEFF gt -2000 and wg12_gir.TEFF lt 20000, ngood_wg12_gir)
;      index_good_u =ind_WG12_u(ind_good_wg12_u)
;      index_good_gir =ind_WG12_gir(ind_good_wg12_gir)
;     end selection in temp        
        
      
;      print, 'index_good_u ', index_good_u[0:10]
 ;     print, 'index_good_gir ', index_good_gir[0:10]
      
      
       
       good_wg12_u = wg12_u
       good_wg12_gir = wg12_gir

;       good_wg12_u = wg12_u 
;       good_wg12_gir = wg12_gir
      
          
       match, good_wg12_u.cname,  good_wg12_gir.cname, ind_a, ind_b,COUNT=WG12_U_GIR       
       match2, good_wg12_u.cname,  good_wg12_gir.cname, ind_ngw12_u, ind_ngw12_gir
       print, 'number of matches WG12 UVES/Giraffe : ', WG12_U_GIR
;       print, ' ind_ngw12_u  ', ind_ngw12_u[0:*]
;       print, ' ind_ngw12_gir  ', ind_ngw12_gir[0:1000]
       
       u_indices = intarr(WG12_U_GIR)
       size_good_wg12_u = size(good_wg12_u, /N_ELEMENTS)
       val =0
        for k=0, size_good_wg12_u - 1 do begin
       if ind_ngw12_u(k) ne -1 then begin
       u_indices(val)= ind_ngw12_u(k)
       val = val+1
       endif
       endfor
       print, 'val', val
       
       index_gir_to_remove = ind_wg12_gir(u_indices)
       
       
       print,' index list of WG12 Giraffe cnames to remove ',  index_gir_to_remove
       wg12_to_keep =  mg_complement(index_gir_to_remove,size_WG12_woBS )
 
;        help, WG12_woBS
        WG12_woBS = WG12_woBS(wg12_to_keep)
        print, (WG12_woBS.cname)[index_gir_to_remove]
;       print, toto

       
        good_wg12_u_cname=good_wg12_u.cname
        good_wg12_gir_cname=good_wg12_gir.cname
        good_wg12_u_target=good_wg12_u.target
        good_wg12_u_setup=good_wg12_u.setup
        good_wg12_gir_target=good_wg12_gir.target
        good_wg12_u_TEFF=good_wg12_u.TEFF
        good_wg12_gir_TEFF=good_wg12_gir.TEFF
        

        for i=0, WG12_U_GIR - 1 do begin
        if ind_a(i) ne -1 then begin
        print,ind_a(i), ' ', good_wg12_u_cname(ind_a(i)), '   ',good_wg12_gir_cname(ind_b(i)), ' ', good_wg12_u_target(ind_a(i)), '   ',good_wg12_gir_target(ind_b(i)), $
        ' ', good_wg12_u_teff(ind_a(i)), '   ',good_wg12_gir_teff(ind_b(i)),' ',good_wg12_u_setup(ind_a(i)) 
        endif
        endfor
    
;       print, toto
       
       file_BS_WG12 = path + 'WG15_Products/BS_WG12.fits'
       MWRFITS, bs_WG12, file_BS_WG12 , head_12 , /CREATE, /No_comment
       add_WG15_extension, file_BS_WG12, file_BS_WG12  
       
       file_WG12_woBS = path + 'WG15_Products/WG12_withoutBS.fits'
       MWRFITS, WG12_woBS, file_WG12_woBS, head_12 , /CREATE, /No_comment
       add_WG15_extension, file_WG12_woBS, file_WG12_woBS     

       file_WG12_woBS = path + 'WG15_Products/WG12_withoutBS_before_Vrad.fits'
       MWRFITS, WG12_woBS, file_WG12_woBS, head_12 , /CREATE, /No_comment
       add_WG15_extension, file_WG12_woBS, file_WG12_woBS     





;      WG12 :apply the radial velocity offset and fill the WG15 extension vrad_offset  and vrad offset source
;
      print, 'WG12 :apply the radial velocity offset and fill the WG15 extension vrad_offset  and vrad offset source'
      
       file_WG12_woBS = path + 'WG15_products/WG12_withoutBS.fits'
       test1 = mrdfits(file_WG12_woBS , 1,head1)
       test2 = mrdfits(file_WG12_woBS,2, head2)

       test1.VEL[0:*]= !Values.F_NAN
       test2.AVAILABLE_PAR='WG12'+'|'+test1.SETUP      
       test2.PROV_VRAD = 'CASU'  
 
;
;      processing HR15 setup
;       
        ind_hr15 = where( (STRMATCH(strcompress(test1.SETUP, /remove_all),'*HR15N*', /FOLD_CASE) eq 1) , count)
        a1=test1[ind_hr15]
        b1=test2[ind_hr15]
        
        vrad_offset = test2.VRAD_OFFSET
        vrad_offset[ind_hr15]= vrad_off_HR15N
        test2.VRAD_OFFSET   =  vrad_offset 
        
        vrad_offsetsource = test2.VRAD_OFFSETSOURCE
        vrad_offsetsource[ind_hr15]= 'WG15'
        test2.VRAD_OFFSETSOURCE   =  vrad_offsetsource
        
        test1VRAD = test1.VRAD
        test1VRAD[ind_hr15] = test1VRAD[ind_hr15] + vrad_off_HR15N 
        test1.VRAD = test1VRAD
       
        print, 'VRAD OFFSET for WG12 HR15 = ',vrad_off_HR15N , ' km/s'


;
;        processing U580 setup
;
       ind_u580 = where( (STRMATCH(strcompress(test1.SETUP, /remove_all),'U580*', /FOLD_CASE) eq 1) , count)
        a1=test1[ind_u580]
        b1=test2[ind_u580]
        
        vrad_offset = test2.VRAD_OFFSET
        vrad_offset[ind_u580]= vrad_off_U580
        test2.VRAD_OFFSET   =  vrad_offset 
        
        vrad_offsetsource = test2.VRAD_OFFSETSOURCE
        vrad_offsetsource[ind_u580]= 'WG15'
        test2.VRAD_OFFSETSOURCE   =  vrad_offsetsource
        
        test1VRAD = test1.VRAD
        test1VRAD[ind_u580] = test1VRAD[ind_u580] + vrad_off_U580 
        test1.VRAD = test1VRAD
       
        print, 'VRAD OFFSET for WG12 U580 = ',vrad_off_U580 , ' km/s'


 
        testfile = path + 'WG15_Products/WG12_withoutBS.fits'
        mwrfits, test1, testfile, head1, /CREATE, /No_comment
        mwrfits, test2, testfile, head2, /No_comment

 

;      print, toto

    
;******************************************
;
;                 WG13 
;
;*******************************************

;     No Benchmark Stars

       print, 'no benchmark stars for WG13'

;
;      "changing NGC6705/" by "NGC6705"
      
 ;     Example :     
;      setup_selection = '*HR15N*'
;      row = strcompress(test1.SETUP, /remove_all)
;      HR15_sel = where(STRMATCH(row,setup_selection, /FOLD_CASE)  eq 1 ,count);

;      param_offset = test2.FEH_Offset
;      param_offset[HR15_sel] = OC_WG10_HR15_Offset
;      test2.FEH_Offset=param_offset

      
       
;      target_selection= 'Br81/*'
;      row= strcompress(datawg13.TARGET, /remove_all)
;      Br81_sel = where(STRMATCH(row,target_selection, /FOLD_CASE)  eq 1 ,count) 
;      param_target = datawg13.target
;      param_target[Br81_sel]='Br81    '
;      datawg13.target=param_target 
      
;      target_selection= 'NGC3293/*'
;      row= strcompress(datawg13.TARGET, /remove_all)
;      NGC3293_sel = where(STRMATCH(row,target_selection, /FOLD_CASE)  eq 1 ,count) 
;      param_target = datawg13.target
;      param_target[NGC3293_sel]='NGC3293 '
;      datawg13.target=param_target 

;      target_selection= 'NGC4815/*'
;      row= strcompress(datawg13.TARGET, /remove_all)
;      NGC4815_sel = where(STRMATCH(row,target_selection, /FOLD_CASE)  eq 1 ,count) 
;      param_target = datawg13.target
;      param_target[NGC4815_sel]='NGC4815 '
;      datawg13.target=param_target 

;      target_selection= 'NGC6705/*'
;      row= strcompress(datawg13.TARGET, /remove_all)
;      NGC6705_sel = where(STRMATCH(row,target_selection, /FOLD_CASE)  eq 1 ,count) 
;      param_target = datawg13.target
;      param_target[NGC6705_sel]='NGC6705 '
;      datawg13.target=param_target 

;     target_selection= 'TR14/*'
;      row= strcompress(datawg13.TARGET, /remove_all)
;      TR14_sel = where(STRMATCH(row,target_selection, /FOLD_CASE)  eq 1 ,count) 
;      param_target = datawg13.target
;      param_target[TR14_sel]='Trumpler_14 '
;      datawg13.target=param_target 
      
      
       file_WG13_woBS_A =  path + 'WG15_Products/WG13_withoutBS_A.fits'
       file_WG13_woBS = path + 'WG15_Products/WG13_withoutBS.fits'
       print, ' appending flags for  WG13'             
       append_WG14_flags, datawg13, datawg13
;
;      removing MH values
;
       print, 'removing MH values from the results '
       datawg13.MH = !VALUES.F_NAN
       datawg13.E_MH = !VALUES.F_NAN


       dataWG13.REMARK[0:*]=' '
       datawg13.TECH[0:*]=' '

;
;       RADIAL VELOCITY
;        
;      WG13 radial velocities have been computed by WG13 and put already in VRAD !  
    
        print, 'WG13 radial velocities have been computed by WG13 and put already in VRAD !'
      
       MWRFITS, datawg13, file_WG13_woBS, head_13 , /CREATE, /No_comment
       add_WG15_extension, file_WG13_woBS, file_WG13_woBS      
 
        MWRFITS, datawg13, file_WG13_woBS_A, head_13 , /CREATE, /No_comment
       add_WG15_extension, file_WG13_woBS_A, file_WG13_woBS_A      
 

 
 
 
       file_WG13_woBS = path + 'WG15_products/WG13_withoutBS.fits'
       test1 = mrdfits(file_WG13_woBS , 1,head1)
       test2 = mrdfits(file_WG13_woBS,2, head2)

       test1.VEL[0:*]= !Values.F_NAN
       test2.AVAILABLE_PAR='WG13'+'|'+test1.SETUP      
       test2.PROV_VRAD = 'WG13'  
       
        testfile = path + 'WG15_Products/WG13_withoutBS.fits'
        mwrfits, test1, testfile, head1, /CREATE, /No_comment
        mwrfits, test2, testfile, head2, /No_comment
 

;********************************************
;
;           EMP Stars SkyMapper
;
;*******************************************

       file_SkyMapper = path +  'GES_iDR2_SkyMapper.fits'
       file_Skymapper_out = path +  'GES_iDR2_SkyMapper_with_ext.fits'
       data_skymap = mrdfits(file_SkyMapper, 1 , head1 )
       add_WG15_extension, file_SkyMapper, file_SkyMapper
      
       test1 = mrdfits(file_SkyMapper , 1,head1)
       test2 = mrdfits(file_SkyMapper,2, head2)
       
       test1.SETUP = 'U580'
       test1.WG = 'SkyMapper'
       test2.AVAILABLE_PAR = 'SkyMapper'+'|'+ 'U580'
       test1.VEL[0:*]=  !Values.F_NAN   
       testfile= path +  'GES_iDR2_SkyMapper_Recommended.fits'
       mwrfits, test1, testfile, head1, /CREATE, /No_comment
       mwrfits, test2, testfile, head2, /No_comment
       
       print, ' Skymapper stars file created'



;*********************************************
;
;           STARS in COMMON between WGs
;
;**********************************************
       
      print, 'Processing STARS in COMMON between WGs'
;
;     determine the number of matches masterlist - WG_results_Without Benchmark Stars
;

;
;    doing some preselecyion on the SETUP for WG12
;
;
       wg12_u580 = where( (STRMATCH(strcompress(WG12_woBS.SETUP, /remove_all),'U580*', /FOLD_CASE) eq 1) , count)
       WG12_woBS_U580 = WG12_woBS(wg12_u580)
       dat_wg12_u580 =  where( (STRMATCH(strcompress(datawg12.SETUP, /remove_all),'U580*', /FOLD_CASE) eq 1) , count)
       datawg12_U580 = datawg12(dat_wg12_u580)
       wg12_gir = where( (STRMATCH(strcompress(WG12_woBS.SETUP, /remove_all),'*HR*', /FOLD_CASE) eq 1) , count)
       WG12_woBS_GIR = WG12_woBS(wg12_gir)

       file_WG12_U580 = path + 'WG15_Products/WG12_U580.fits'
       MWRFITS,WG12_woBS_U580 , file_WG12_U580 , head_10 , /CREATE, /No_comment
       
       
       match, b,  dataWG10.cname,a10, b10,COUNT=countDR210
       match2, b,  WG10_woBS.cname,dr2_wg10_woBS, b10
       print, 'number of matches DR2-WG10 : ', countDR210

       match, b,  dataWG11.cname,a11, b11,COUNT=countDR211
       match2, b,  WG11_woBS.cname,dr2_wg11_woBS, b11
       print, 'number of matches DR2-WG11 : ', countDR211

       match, b,  dataWG12.cname,a12, b12,COUNT=countDR212
       match2, b,  WG12_woBS.cname,dr2_wg12_woBS, b12
       print, 'number of matches DR2-WG12 : ', countDR212
;       match2, b,  WG12_woBS_U580.cname,dr2_wg12_woBS_U580, b12
;       match2, b,  WG12_woBS_GIR.cname,dr2_wg12_woBS_GIR, b12

;
;    specail treatment for WG13 (DR2+DR3) data
;       
       match, b,  dataWG13.cname,a13, b13,COUNT=countDR213
       match2, b,  dataWG13.cname,dr2_wg13, b13      
       print, 'number of matches DR2-WG13 : ', countDR213
 
     
;
;      searching cnames with values in different WGs without benchmark Stars
;
;      to be improved and put in a sub-routine
;
       com_WG10_WG11 = where((dr2_wg10_woBS ne -1) and (dr2_wg11_woBS ne -1), nwg10_wg11, complement = single_WG10_WG11 )
       com_WG10_WG12 = where((dr2_wg10_woBS ne -1) and (dr2_wg12_woBS ne -1), nwg10_wg12, complement = single_WG10_WG12 )
       com_WG10_WG13 = where((dr2_wg10_woBS ne -1) and (dr2_wg13 ne -1), nwg10_wg13, complement = single_WG10_WG13 )
       com_WG11_WG12 = where((dr2_wg11_woBS ne -1) and (dr2_wg12_woBS ne -1), nwg11_wg12, complement = single_WG11_WG12 )
       com_WG11_WG13 = where((dr2_wg11_woBS ne -1) and (dr2_wg13 ne -1), nwg11_wg13, complement = single_WG11_WG13 )
       com_WG12_WG13 = where((dr2_wg12_woBS ne -1) and (dr2_wg13 ne -1), nwg12_wg13, complement = single_WG12_WG13 )
       com_WG10_WG11_WG12 = where((dr2_wg10_woBS ne -1) and (dr2_wg11_woBS ne -1) and (dr2_wg12_woBS ne -1), nwg10_wg11_wg12, complement = single_WG10_WG11_WG12 )

       
       print, 'triple WGs ', size(com_WG10_WG11_WG12, /N_ELEMENTS)
       
;       print, toto
       
       match, wg10_woBS.cname, WG11_woBS.cname, a, b, COUNT=count1011
;       print, 'count1011 ', count1011
 
       match, wg10_woBS.cname, dataWG13.cname, a, b, COUNT=count1013
;       print, 'count1013 ', count1013
              
;      print, 'nwg10_wg13 ', nwg10_wg13
;
;
;       
       match, wg11_woBS.cname,  wg12_woBS.cname,a12, b12,COUNT=count1112
       match2, wg11_woBS.cname,  wg12_woBS.cname,a12, b12
       size_wg11_woBS=size(wg11_woBS, /N_ELEMENTS)
;      print, 'count1112 ', count1112
      ert = wg11_woBS.cname
      erteff=wg11_woBS.Teff
      count =0
      for i=0, size_wg11_woBS - 1 do begin
      index=a12(i)
;      print, 'index ', index
      if index ne -1  and  erteff(i) gt 2000 then begin
           index=a12(i)
;        print, ert(i)
        count= count + 1
      endif
      endfor

      print, '# of stars in common WG10 -- WG11 ',nwg10_wg11
      print, '# of stars in common WG10 -- WG12 ',nwg10_wg12
      print, '# of stars in common WG10 -- WG13 ',nwg10_wg13
      print, '# of stars in common WG11 -- WG12 ',nwg11_wg12
      print, '# of stars in common WG11 -- WG13 ',nwg11_wg13
      print, '# of stars in common WG12 -- WG13 ',nwg12_wg13
      
      
      
      
      
;############################################################
;
;
;                  10 11 common stars
;
;
;############################################################
     
       if (nWG10_WG11 ne 0 ) then begin
;       WG10WG11 = datawg10(dr2_wg10(com_WG10_WG11))
;       WG11WG10 = datawg11(dr2_wg11(com_WG10_WG11))
       WG10WG11 = wg10_woBS(dr2_wg10_woBS(com_WG10_WG11))
       WG11WG10 = wg11_woBS(dr2_wg11_woBS(com_WG10_WG11))
       
       valid1011 = where(WG10WG11.teff GT 2000 and WG10WG11.teff lT 100000  $
       and WG11WG10.teff GT 2000 and WG11WG10.teff lT 100000, v1011count)  
 
       
       
       good_WG10WG11 = WG10WG11(valid1011)
       good_WG11WG10 = WG11WG10(valid1011)

        good_WG11WG10.SPT[0:*] ='  '
        good_WG11WG10.EW_TABLE[0:*]='  '
        good_WG11WG10.REMARK[0:*]='  '
        good_WG11WG10.PECULI[0:*]='  '
        good_WG11WG10.TECH[0:*]='  '

        good_WG10WG11.SPT[0:*] ='  '
        good_WG10WG11.EW_TABLE[0:*]='  '
        good_WG10WG11.REMARK[0:*]='  '
        
        good_WG10WG11.TECH[0:*]='  '

 
      print, '----------------------------------------'
      print, '                                        '
      Print, ' Proceed with WG10 - WG11 common stars '
      print, '  rules adopted '
      print, ' For all, select WG11  '
      print, ' '
      print, '                                        '
      print, '----------------------------------------'


        good_WG10WG11c = good_WG11WG10      ; select WG11 for all the cnames
;       help, good_WG10WG11c
 
       print, 'iDR2 : Remove the abundances for stars in common between WG10 and WG11'
       remove_abund, good_WG10WG11c    
       
       transfer_DR2_U580_VEL, DR2_woBS, good_WG10WG11c, good_WG10WG11c     ; transferring  U580 VEL from masterlist and fill VRAD E_VRAD
       print, 'transferring  U580 VEL from masterlist and fill VRAD E_VRAD '
       file_WG10WG11c = path + 'WG15_Products/common_WG10_WG11_Recommended.fits'
       MWRFITS,good_WG10WG11c , file_WG10WG11c , head_10 , /CREATE, /No_comment
       add_WG15_extension,file_WG10WG11c, file_WG10WG11c    
   
;     
;     - adding info in PROVENANCE column 
;     - merging the TARGET and SETUPS   
;       taking      
 
;      test1 = mrdfits(file_WG10WG11c , 1,head1, /SILENT)
;      test2 = mrdfits(file_WG10WG11c ,2, head2, /SILENT)
      test1 = mrdfits(file_WG10WG11c , 1,head_1, /SILENT)
      test2 = mrdfits(file_WG10WG11c ,2, head_2, /SILENT)
      

      test2.AVAILABLE_PAR = 'WG11|U580-WG10|HR15N'
      test1.WG = 'WG11'
      test1.SETUP= 'U580'
      test1.VEL[0:*]= !Values.F_NAN
      test2.VRAD_OFFSET = vrad_off_U580
      test1.VRAD = test1.VRAD + vrad_off_U580
      print, 'VRAD OFFSET for WG11 = ',vrad_off_U580 , ' km/s'
      test2.VRAD_OFFSETSOURCE = ' WG15'
      test2.PROV_VRAD = 'CASU'

      MWRFITS,test1 , file_WG10WG11c , head_1 , /CREATE  , /No_comment 
      MWRFITS,test2 , file_WG10WG11c , head_2  , /No_comment 


;
;       writing the individual files
;

      good_WG10WG11c.TECH= ' '
       good_WG10WG11c.PECULI[0:*]='  ' 
       file_WG10WG11 = path + 'WG15_Products/common_WG10_WG11.fits'
       MWRFITS,good_WG10WG11 , file_WG10WG11 , head_10 , /CREATE, /No_comment
       add_WG15_extension, file_WG10WG11, file_WG10WG11     
 
        
       file_WG11WG10 = path + 'WG15_Products/common_WG11_WG10.fits'
        good_WG11WG10.SPT[0:*] ='  '
        good_WG11WG10.EW_TABLE[0:*]='  '
        good_WG11WG10.REMARK[0:*]='  '

 
       MWRFITS,good_WG11WG10 , file_WG11WG10 , head_11 , /CREATE    , /No_comment     
       add_WG15_extension, file_WG11WG10, file_WG11WG10     

      endif
      
      
;############################################################
;
;
;
;                    10 12 common stars
;
;
;############################################################


       if (nWG10_WG12 ne 0 ) then begin

;       WG10WG12 = datawg10(dr2_wg10(com_WG10_WG12))
;       WG12WG10 = datawg12(dr2_wg12(com_WG10_WG12))
;       valid1012 = where(WG10WG12.teff GT 2000 and WG10WG12.teff lT 100000  $
;       and STRMATCH(strcompress(WG12WG10.SETUP, /remove_all),'*U580*', /FOLD_CASE) eq 0 $
;       and WG12WG10.teff GT 2000 and WG12WG10.teff lT 100000, v1012count)
;       good_WG10WG12 = WG10WG12(valid1012)
;       good_WG12WG10 = WG12WG10(valid1012)

;       file_WG10WG12 = path + 'WG15_Products/common_WG10_WG12_UGIR.fits'
;       MWRFITS,good_WG10WG12 , file_WG10WG12 , head_10 , /CREATE
;        add_WG15_extension,file_WG10WG12, file_WG10WG12
;       file_WG12WG10 = path + 'WG15_Products/common_WG12_WG10_UGIR.fits'
;       MWRFITS,good_WG12WG10 , file_WG12WG10 , head_12 , /CREATE
;        add_WG15_extension,file_WG12WG10, file_WG12WG10

;       WG10WG12 = datawg10(dr2_wg10(com_WG10_WG12))
;       WG12WG10 = datawg12(dr2_wg12(com_WG10_WG12))
       WG10WG12 = wg10_woBS(dr2_wg10_woBS(com_WG10_WG12))
       WG12WG10 = wg12_woBS(dr2_wg12_woBS(com_WG10_WG12))
       
        
;       valid1012 = where(WG10WG12.teff GT 2000 and WG10WG12.teff lT 100000  $
;       and STRMATCH(strcompress(WG12WG10.SETUP, /remove_all),'*U580*', /FOLD_CASE) eq 0 $
;       and WG12WG10.teff GT 2000 and WG12WG10.teff lT 100000, v1012count)
       
;       print,' size(WG12WG10, /N_ELEMENTS), v1012count ', size(WG12WG10, /N_ELEMENTS), v1012count
       
;       good_WG10WG12 = WG10WG12(valid1012)
;       good_WG12WG10 = WG12WG10(valid1012)

       good_WG10WG12 = WG10WG12
       good_WG12WG10 = WG12WG10


      
      
      print, '----------------------------------------'
      print, '                                        '
      Print, ' Proceed with WG10 - WG12 common stars  '
      print, '  rules adopted                         '
      print, ' if Filename = gir_08* then select WG12 '
      print, ' if Filename = gir_18* then select WG10 ' 
      print, '                                        '
      print, '----------------------------------------'


      sel12 = where(STRMATCH(strcompress(good_WG12WG10.FILENAME, /remove_all),'*gir_08*', /FOLD_CASE) eq 1  $
               or STRMATCH(strcompress(good_WG12WG10.TARGET, /remove_all),'IC4665*', /FOLD_CASE) eq 1   $
              or STRMATCH(strcompress(good_WG12WG10.SETUP, /remove_all),'*U580*', /FOLD_CASE) eq 1)
;        print, sel12       
       sel10 = where(STRMATCH(strcompress(good_WG10WG12.FILENAME, /remove_all),'*gir_18*', /FOLD_CASE) eq 1)
;       print, 'sel10 ', sel10

         size_sel12 =size(sel12, /N_ELEMENTS)
         size_sel10 =size(sel10, /N_ELEMENTS)
         
         print, 'sel12 ', size_sel12, sel12
         print, 'sel10 ', size_sel10, sel10 

;         if (size_sel10 gt 0  and size_sel12 gt 0  ) then begin
         if ( size_sel12 gt 0  ) then begin

;
;         comp contains the paramaters from the WG which has not been selected
;         i.e. idf we chose WG10, we will have the WG10 stellar parameters from WG10 
;         and we will keep in comp the results from WG12
;         This is usefull to have a trace of both setups
 

;          good_WG10WG12a = good_WG10WG12(sel10)
;          comp_WG10WG12a = good_WG12WG10(sel10)


          good_WG10WG12b = good_WG12WG10(sel12)
          comp_WG10WG12b = good_WG10WG12(sel12)

          good_WG10WG12bCNAME = good_WG10WG12b.CNAME
          good_WG10WG12bSETUP = good_WG10WG12b.SETUP
          good_WG10WG12bWG = good_WG10WG12b.WG
          good_WG10WG12.PECULI[0:*]='  '
;          good_WG10WG12aSETUP = good_WG10WG12a.SETUP
;          good_WG10WG12aWG = good_WG10WG12a.WG
      
          sizegood = size(good_WG10WG12bCNAME, /N_ELEMENTS)
       
          for i=0, sizegood -1 do begin
             print, i, ' ', good_WG10WG12bCNAME(i), ' ', good_WG10WG12bSETUP(i)
          endfor

          transfer_DR2_WG12_VEL, DR2_woBS, good_WG10WG12b , good_WG10WG12b         
;          transfer_DR2_WG10_VEL, DR2_woBS, good_WG10WG12a , good_WG10WG12a

;          good_WG10WG12c = [good_WG10WG12b , good_WG10WG12a ]
           good_WG10WG12c = good_WG10WG12b 
            
;         we have to work on the vrad after this as the organisation of the file 
;         is modified in this transfer routine
;
;         Adding the WG/SETUP values from WG12 
;      
          size_b=  size(good_WG10WG12b,/N_ELEMENTS)               
          wg_setupb = strarr(size_b)
          wg_setupb =   strcompress(good_WG10WG12b.WG, /remove_all)+ '|' + strcompress(good_WG10WG12b.SETUP, /remove_all)  + '-' + $
                    strcompress(comp_WG10WG12b.WG, /remove_all)+ '|' + strcompress(comp_WG10WG12b.SETUP, /remove_all)
          

;          size_a = size(good_WG10WG12a, /N_ELEMENTS)
;          wg_setupa = strarr(size_a)      
;          wg_setupa =   strcompress(good_WG10WG12a.WG, /remove_all)+ '|' + strcompress(good_WG10WG12a.SETUP, /remove_all)  + '-' + $
;                    strcompress(comp_WG10WG12a.WG, /remove_all)+ '|' + strcompress(comp_WG10WG12a.SETUP, /remove_all) 
      
 
;          wg_setup = [wg_setupb, wg_setupa]
           wg_setup = wg_setupb


          print, 'iDR2 : Remove the abundances for stars in common between WG10 and WG12'       
          remove_abund, good_WG10WG12c    
          file_WG10WG12c = path + 'WG15_Products/common_WG10_WG12_PRE_Recommended.fits'
          MWRFITS,good_WG10WG12c , file_WG10WG12c , head_10 , /CREATE, /No_comment
          add_WG15_extension,file_WG10WG12c, file_WG10WG12c   
  
;     
;         - adding info in PROVENANCE column 
;         - merging the TARGET and SETUPS   
      
 
          test1 = mrdfits(file_WG10WG12c , 1,head1, /SILENT)
          test2 = mrdfits(file_WG10WG12c ,2, head2, /SILENT)

          WG10_selection = '*WG10*'
          WG12_selection = '*WG12*'
       
      
          row = strcompress(test1.WG, /remove_all)
          row_SETUP = strcompress(test1.SETUP, /remove_all)
;          WG10_sel = where(STRMATCH(row,WG10_selection, /FOLD_CASE)  eq 1 ,count)
;          WG10_sel_HR10 = where((STRMATCH(row,WG10_selection, /FOLD_CASE)  eq 1)  and (STRMATCH(row_SETUP,'*HR10*', /FOLD_CASE)  eq 1) ,count_wg10hr10)
;          WG10_sel_HR15 = where((STRMATCH(row,WG10_selection, /FOLD_CASE)  eq 1)  and (STRMATCH(row_SETUP,'*HR15*', /FOLD_CASE)  eq 1) ,count_wg10hr15)
      
          WG12_sel_HR15 = where((STRMATCH(row,WG12_selection, /FOLD_CASE)  eq 1)  and (STRMATCH(row_SETUP,'*HR15*', /FOLD_CASE)  eq 1) ,count)
          WG12_sel_U580 = where((STRMATCH(row,WG12_selection, /FOLD_CASE)  eq 1)  and (STRMATCH(row_SETUP,'*U580*', /FOLD_CASE)  eq 1) ,count)
      
;          print, toto
      
      
          prov_param = test2.AVAILABLE_PAR
      
          size_AVAILABLE_PAR = size(prov_param, /N_ELEMENTS)
      
;         a=good_WG10WG12[WG10_sel]
;         b=good_WG12WG10[WG12_sel]

;          a=test1[WG10_sel]
          b=test1[WG12_sel_HR15]
          c=test1[WG12_sel_U580] 
;          d=test1[WG10_sel_HR10]
;          e=test1[WG10_sel_HR15]   

          test2VRAD_OFFSET=test2.VRAD_OFFSET
          test1VRAD=test1.VRAD
          test2VRAD_OFFSETSOURCE=test2.VRAD_OFFSETSOURCE


;         print, ' a.SETUP'
;         print, a.SETUP
      
;
;         WG10 SETUP is HR15N or HR10N
;     
      
;         prov_param[WG10_sel]= strcompress(good_WG10WG12.WG, /remove_all)+ '|' + strcompress(good_WG10WG12.SETUP, /remove_all)
  
        
;          prov_param[WG10_sel_HR15]= strcompress(e.WG, /remove_all)+ '|' + strcompress(e.SETUP, /remove_all) 
;          prov_param[WG10_sel_HR10]= strcompress(d.WG, /remove_all)+ '|' + strcompress(d.SETUP, /remove_all) 
    
            
; ;        print, ' count****** ', count
;          if (count_wg10hr15 ne 0 ) then begin
;          test2VRAD_OFFSET[WG10_sel_HR15] = vrad_off_HR15N
;          test1VRAD[WG10_sel_HR15] = test1VRAD[WG10_sel_HR15] + vrad_off_HR15N
;          print, 'VRAD OFFSET for HR15 wrt HR10 = ',vrad_off_HR15N , ' km/s'
;          test2.VRAD_OFFSETSOURCE[WG10_sel_HR15] = ' WG15'
;;         test2.VRAD_OFFSET=test2VRAD_OFFSET
;;         test1.VRAD=test1VRAD
;;         test2.VRAD_OFFSETSOURCE=test2VRAD_OFFSETSOURCE
;          endif
 
 
;          test2VRAD_OFFSET=test2.VRAD_OFFSET
;          test2VRAD_OFFSET[WG10_sel_HR10] = 0.0
;           test1VRAD[WG10_sel_HR10] = test1VRAD[WG10_sel_HR10]
;           print, 'VRAD OFFSET for HR10|HR21 wrt HR10 = ',0.0 , ' km/s'
;           test2.VRAD_OFFSETSOURCE = ' WG15'
;          test2.VRAD_OFFSET=test2VRAD_OFFSET
;          test1.VRAD=test1VRAD
;           test1.VEL[0:*]= !Values.F_NAN
      
      
;          prov_param = test2.AVAILABLE_PAR
      
      
;
;          WG12 SETUP is HR15N
;
      
           prov_param[WG12_sel_HR15]=strcompress(b.WG, /remove_all)+ '|' + strcompress(b.SETUP, /remove_all) 
         
           test2VRAD_OFFSET[WG12_sel_HR15] = vrad_off_HR15N
           test1VRAD[WG12_sel_HR15] = test1VRAD[WG12_sel_HR15] + vrad_off_HR15N
           print, 'VRAD OFFSET for WG12/HR15 wrt HR10 = ',vrad_off_HR15N , ' km/s'
      
;
;          WG12 SETUP is U580
;
      
           prov_param[WG12_sel_U580]=strcompress(c.WG, /remove_all)+ '|' + strcompress(c.SETUP, /remove_all) 
;          prov_param[WG12_sel]= strcompress(b.WG[WG12_sel], /remove_all)+ '|' + strcompress(b.SETUP[WG12_sel], /remove_all)  + '-' + $
;          strcompress(a.WG[WG12_sel], /remove_all)+ '|' + strcompress(a.SETUP, /remove_all)
 

;          test2VRAD_OFFSET=test2.VRAD_OFFSET   
;          test1VRAD= test1.VRAD
         
           test2VRAD_OFFSET[WG12_sel_U580] = vrad_off_U580
           test1VRAD[WG12_sel_U580] = test1VRAD[WG12_sel_U580] + vrad_off_U580
           print, 'VRAD OFFSET for WG12/U580 wrt HR10 = ',vrad_off_U580 , ' km/s'
      
           test2.VRAD_OFFSETSOURCE = ' WG15'
           test2.VRAD_OFFSET=test2VRAD_OFFSET   
           test1.VRAD= test1VRAD
           test2.AVAILABLE_PAR  = prov_param       
           help, good_WG10WG12.WG
           help, good_WG12WG10.WG


 ;          print, 'count_HR15 ', count_HR15      

;           setup_param = test1.SETUP
;           if ( count_hr15 ne 0 ) then begin
;           setup_param[HR15_double]= 'HR15N'
;           test1.SETUP  = setup_param
;           endif
      
           test2.AVAILABLE_PAR=wg_setup
      
           test2.VRAD_OFFSETSOURCE = ' WG15'
           test2.PROV_VRAD = 'CASU'
           file_WG10WG12c = path + 'WG15_Products/common_WG10_WG12_Recommended.fits'
           MWRFITS,test1 , file_WG10WG12c , head_1 , /CREATE  , /No_comment 
;          add_WG15_extension,file_WG10WG12c, file_WG10WG12c
           MWRFITS,test2 , file_WG10WG12c , head_2   , /No_comment
;
;          writing the files
;
           file_WG10WG12 = path + 'WG15_Products/common_WG10_WG12.fits'
           MWRFITS,good_WG10WG12 , file_WG10WG12 , head_10 , /CREATE, /No_comment
           add_WG15_extension,file_WG10WG12, file_WG10WG12
           file_WG12WG10 = path + 'WG15_Products/common_WG12_WG10.fits'
           MWRFITS,good_WG12WG10 , file_WG12WG10 , head_12 , /CREATE, /No_comment
           add_WG15_extension,file_WG12WG10, file_WG12WG10
           endif
       
           endif
       
;          END   of WG10-WG12       

;############################################################
;
;
;
;      10 13 common stars
;
;
;############################################################

       if (nWG10_WG13 ne 0 ) then begin

;       WG10WG13 = datawg10(dr2_wg10(com_WG10_WG13))
;       WG13WG10 = datawg13(dr2_wg13(com_WG10_WG13))
       WG10WG13 = wg10_woBS(dr2_wg10_woBS(com_WG10_WG13))
       WG13WG10 = datawg13(dr2_wg13(com_WG10_WG13))
       
       
       valid1013 = where(WG10WG13.teff GT 2000 and WG10WG13.teff lT 300000  $
       and WG13WG10.teff GT 2000 and WG13WG10.teff lT 300000, v1013count)
       good_WG10WG13 = WG10WG13(valid1013)
       good_WG13WG10 = WG13WG10(valid1013)

      print, '----------------------------------------'
      print, '                                        '
      Print, ' Proceed with WG10 - WG13 common stars '
      print, '  rules adopted '
      print, ' if Teff> 7000 then select WG13  '
      print, ' if Teff<= 7000 then select WG10 ' 
      print, '                                        '
      print, '----------------------------------------'

      sel13 = where( good_WG13WG10.TEFF gt 7000  and good_WG10WG13.TEFF gt 7000 ) ; both WG13_TEFF and WG10_TEFF > 7000K
      
        print,' sel13 ', sel13
        print, 'no iDR3 WG13/WG10 common stars with Teff > 7000K'       
      sel10 = where( good_WG10WG13.TEFF le 7000  or  good_WG13WG10.TEFF le 7000) 
      print, 'sel10 ', sel10


        size_sel13 =size(sel13, /N_ELEMENTS)
         size_sel10 =size(sel10, /N_ELEMENTS)
         
         print, 'sel13 ', size_sel13, sel13
         print, 'sel10 ', size_sel10, sel10 

      if (size_sel10 gt 0   ) then begin
;
           good_WG10WG13a = good_WG10WG13(sel10)
           comp_WG10WG13a = good_WG13WG10(sel10)
;           good_WG10WG13b = good_WG13WG10(sel13)
;           comp_WG10WG13b = good_WG10WG13(sel13) 
           good_WG10WG13c = good_WG10WG13a 
           good_WG10WG13c.PECULI='  '
           comp_WG10WG13c = comp_WG10WG13a 
      
       print, 'transfert CASU VEL for WG10 stars i.e. TEFF < 7000K '
       
       transfer_DR2_WG10_VEL, DR2_woBS, good_WG10WG13a , good_WG10WG13a 
       print, 'iDR2 : Remove the abundances for stars in common between WG10 and WG13'
       remove_abund, good_WG10WG13c    
       file_WG10WG13c = path + 'WG15_Products/common_WG10_WG13_Recommended.fits'
       MWRFITS,good_WG10WG13c , file_WG10WG13c , head_10 , /CREATE, /No_comment
       add_WG15_extension,file_WG10WG13c, file_WG10WG13c    
  
;     
;     - adding info in PROVENANCE column 
;     - merging the TARGET and SETUPS   


   
 
      test1 = mrdfits(file_WG10WG13c , 1,head1, /SILENT)
      test2 = mrdfits(file_WG10WG13c ,2, head2, /SILENT)

      WG10_selection = '*WG10*'
      WG13_selection = '*WG13*'
      
      row = strcompress(test1.WG, /remove_all)
      WG10_sel = where(STRMATCH(row,WG10_selection, /FOLD_CASE)  eq 1 ,count)
;      WG13_sel = where(STRMATCH(row,WG13_selection, /FOLD_CASE)  eq 1 ,count)

;
;      HR15
;

      WG10_Sel = where(STRMATCH(row,WG10_selection, /FOLD_CASE)  eq 1, count)
      WG10_sel_HR9B = where((STRMATCH(row,WG10_selection, /FOLD_CASE)  eq 1) $
                      and (STRMATCH(strcompress(test1.SETUP, /remove_all),'*HR*9B*', /FOLD_CASE) eq 1),count)


      
 
        a1=test1[WG10_sel_HR9B]
        b1=test2[WG10_sel_HR9B]
        
        print, 'nb of WG10 cnames with hr9B setup', count
        
        vrad_offset = test2.VRAD_OFFSET
        vrad_offset[WG10_sel_HR9B]= 0.
        test2.VRAD_OFFSET   =  vrad_offset 


        
        vrad_offsetsource = test2.VRAD_OFFSETSOURCE
        vrad_offsetsource[WG10_sel_HR9B]= 'WG15'
        test2.VRAD_OFFSETSOURCE   =  vrad_offsetsource
        
        test1VRAD = test1.VRAD
        test1VRAD[WG10_sel_HR9B] = test1VRAD[WG10_Sel_HR9B] 
        test1.VRAD = test1VRAD

;
;
;
;
     
      good_WG10sel = test1(WG10_sel)
;      good_WG13sel = test1(WG13_sel)     
      
      prov_param = test2.AVAILABLE_PAR

      compSETUP =  comp_WG10WG13c.SETUP
      compSETUP = strcompress(compSETUP, /remove_all)
      test3SETUP= good_WG10WG13c.SETUP
      test3setup = strcompress(test3SETUP, /remove_all)
      
;      prov_param[WG10_sel]= 'WG10|HR10|HR21' +'-'+'WG13|HR3|HR5A|HR6|HR9B'
;       prov_param[WG10_sel]= 'WG10|HR10|HR21' +'-'+'WG13|' + compSETUP[WG10_sel]
       prov_param[WG10_sel]= 'WG10|'+ compSETUP[WG10_sel] +'-'+'WG13|' + compSETUP[WG10_sel]
       test2.AVAILABLE_PAR  = prov_param 

       test2PROV_VRAD= test2.PROV_VRAD
       test2PROV_VRAD[WG10_sel] = 'CASU'  
       test2.PROV_VRAD= test2PROV_VRAD
 
      
      prov_param = test2.AVAILABLE_PAR
;      prov_param[WG13_sel]= 'WG13|HR3|HR5A|HR6|HR9B'+'-'+'WG10|HR10|HR21'

;        prov_param[WG13_sel]= 'WG13|'+test3SETUP[WG13_sel]+'-'+'WG10|HR10|HR21'
      test2.AVAILABLE_PAR  = prov_param 
      

       test2PROV_VRAD= test2.PROV_VRAD
;       test2PROV_VRAD[WG13_sel] = 'WG13'  
       test2.PROV_VRAD= test2PROV_VRAD
       
       test1.VEL[0:*]= !Values.F_NAN    

;        print,' test1.vrad ', test1.vrad      

      help, good_WG10WG13.WG
      help, good_WG13WG10.WG
      help, test1.WG
;      test1WG = test1.WG

      test3WG =  good_WG10WG13c.WG
      test3SETUP =  good_WG10WG13c.SETUP
      test3SETUP = strcompress(test3SETUP, /remove_all)
     
;      test1SETUP[WG13_sel]='HR3|HR5A|HR6|HR9B'
;      test1SETUP = test1.SETUP
;      test1SETUP[WG13_sel]=test3SETUP[WG13_sel]
;         test1WG = test1.WG
;         test1WG[WG13_sel]='WG13'
;         test1.WG = test1WG 
;         test1.SETUP = test1SETUP
      
      
         MWRFITS,test1 , file_WG10WG13c , head_1 , /CREATE , /No_comment  
         MWRFITS,test2 , file_WG10WG13c , head_2  , /No_comment 
  

;    print, toto

;
;          writing the files
;
          file_WG10WG13 = path + 'WG15_Products/common_WG10_WG13.fits'
          MWRFITS,good_WG10WG13 , file_WG10WG13 , head_10 , /CREATE, /No_comment
          add_WG15_extension,file_WG10WG13, file_WG10WG13
          file_WG13WG10 = path + 'WG15_Products/common_WG13_WG10.fits'
          MWRFITS,good_WG13WG10 , file_WG13WG10 , head_13 , /CREATE, /No_comment
          add_WG15_extension,file_WG13WG10, file_WG13WG10
          endif

       endif

;############################################################
;
;
;                11 12 common stars
;
;
;############################################################


       if (nWG11_WG12 ne 0 ) then begin

       WG11WG12 = wg11_woBS(dr2_wg11_woBS(com_WG11_WG12))
;       WG12WG11 = datawg12(dr2_wg12(com_WG11_WG12))
       WG12WG11 = wg12_woBS(dr2_wg12_woBS(com_WG11_WG12))

       file_res1211 = path + 'WG15_Products/common_WG12_WG11_raw.fits'
       MWRFITS,WG12WG11 , file_res1211 , head_11 , /CREATE, /No_comment

       file_res1112 = path + 'WG15_Products/common_WG11_WG12_raw.fits'
       MWRFITS,WG11WG12 , file_res1112 , head_11 , /CREATE, /No_comment

       
       valid1112 = where(WG11WG12.teff GT 2000 and WG11WG12.teff lT 110000  $
;       and ( STRMATCH(strcompress(WG11WG12.SETUP, /remove_all),'*U580*', /FOLD_CASE) eq 1) $
       and ( STRMATCH(strcompress(WG12WG11.SETUP, /remove_all),'*U580*', /FOLD_CASE) eq 1) $
       and WG12WG11.teff GT 2000 and WG12WG11.teff lT 110000, v1112count)
       good_WG11WG12 = WG11WG12(valid1112)
       good_WG12WG11 = WG12WG11(valid1112)
       print, 'valid1112 ', valid1112

        tt_cname =good_WG12WG11.cname
       print, tt_cname[0:*]
       
;       print, toto
      print, '----------------------------------------'
      print, '                                        '
    
      print, ' Proceed to  WG11-WG12 homogenisation' 
      print, '        rules adopted '
      print, '   if (TARGET = GAM2VEL_*  or TARGET=GES_CL_08*  or TARGET GES_Cl_10* )  select WG12'
      print, '   if (TARGET=GES_CL*N6705*) select WG11 '
      print, '                                        '
      print, '----------------------------------------'

      
      sel12 = where( (STRMATCH(strcompress(good_WG11WG12.TARGET, /remove_all),'*gamma2_Vel*', /FOLD_CASE) eq 1) $
             or     ( STRMATCH(strcompress(good_WG11WG12.TARGET, /remove_all),'*NGC2547*', /FOLD_CASE) eq 1)   $
              or    ( STRMATCH(strcompress(good_WG11WG12.TARGET, /remove_all),'*IC4665*', /FOLD_CASE) eq 1) )
 
;        print, sel12       
;       sel11 = where(STRMATCH(strcompress(good_WG12WG11.TARGET, /remove_all),'*NGC6705*', /FOLD_CASE) eq 1)  
       
;       print, 'sel11 ', sel11
 


         size_sel12 =size(sel12, /N_ELEMENTS)
;         size_sel11 =size(sel11, /N_ELEMENTS)
         
;         print, 'sel11 ', size_sel11, sel11
         print, 'sel10 ', size_sel10, sel10 

         if (size_sel12 gt 0 ) then begin
;

       
;      good_WG11WG12a = good_WG11WG12(sel11)
      good_WG11WG12b = good_WG12WG11(sel12)

;     transfer_DR2_U580_VEL, DR2_woBS, good_WG11WG12a, good_WG11WG12a    ; transferring  U580 VEL from masterlist and fill VRAD E_VRAD
     transfer_DR2_U580_VEL, DR2_woBS, good_WG11WG12b , good_WG11WG12b   ; as there is only U580 setup for this W12 selection !
;             remove_abund, good_WG11WG12a 
      good_WG11WG12c = good_WG11WG12b 
 ;     good_WG11WG12c.TARGET='WG11|WG12'
 ;     help, good_WG11WG12c
 
       good_WG11WG12c.TECH= ' '
       good_WG11WG12c.REMARK= ' '
       good_WG11WG12c.PECULI[0:*]='  '
       print, 'iDR2 : Remove the abundances for stars in common between WG11 and WG12' 
       remove_abund, good_WG11WG12c        
       file_WG11WG12c = path + 'WG15_Products/common_WG11_WG12_Recommended.fits'
       MWRFITS,good_WG11WG12c , file_WG11WG12c , head_11 , /CREATE, /No_comment
       add_WG15_extension,file_WG11WG12c, file_WG11WG12c    
;
;     
;     - adding info in PROVENANCE column 
;     - merging the TARGET and SETUPS   
      
 
;      test1 = mrdfits(file_WG11WG12c , 1,head1, /SILENT)
;      test2 = mrdfits(file_WG11WG12c ,2, head2, /SILENT)
      test1 = mrdfits(file_WG11WG12c , 1,head1, /SILENT)
      test2 = mrdfits(file_WG11WG12c ,2, head2, /SILENT)


      WG11_selection = '*WG11*'
      WG12_selection = '*WG12*'
      
      row = strcompress(test1.WG, /remove_all)
;      WG11_sel = where(STRMATCH(row,WG11_selection, /FOLD_CASE)  eq 1 ,count)
      WG12_sel = where(STRMATCH(row,WG12_selection, /FOLD_CASE)  eq 1 ,count)
      
      
;      prov_param = test2.AVAILABLE_PAR
;      prov_param[WG11_sel]= 'WG11|U580'+'-'+'WG12|U580'
;      test2.AVAILABLE_PAR  = prov_param 
 
      test1.VEL[0:*]= !Values.F_NAN

      test2.VRAD_OFFSET [0:*] = vrad_off_U580     
      
      test1.VRAD = test1.VRAD + vrad_off_U580


      print, 'VRAD OFFSET for  WG12 and WG11 stars in common = ',vrad_off_U580 , ' km/s'
      
      
;      test2VRAD_OFFSET=test2.VRAD_OFFSET      
;      test2.VRAD_OFFSET[WG12_sel] = -0.56
;      test2.VRAD_OFFSET=test2VRAD_OFFSET
      
;      test1VRAD = test1.VRAD 
;      test1VRAD[WG12_sel] = test1VRAD[WG12_sel] -0.56
;      test1.VRAD = test1VRAD 
;      print, 'VRAD OFFSET for WG11 = ',-0.56 , ' km/s'
           
      
      test2.VRAD_OFFSETSOURCE = ' WG15'
      test2.PROV_VRAD = 'CASU'
 
 
      
      prov_param = test2.AVAILABLE_PAR
      prov_param[WG12_sel]= 'WG12|U580'+'-'+'WG11|U580'
      test2.AVAILABLE_PAR  = prov_param 
      
;      test1.WG = 'WG11|WG12'
      test1WG=test1.WG
      test1WG[WG12_sel]='WG12' ;strcompress(good_WG12WG11.WG, /remove_all)
      test1.WG = test1.WG
      test1WG=test1.WG
;      test1WG[WG11_sel]= 'WG11' ;strcompress(good_WG11WG12.WG, /remove_all)
;      test1.WG = test1WG
      
      
      
;      test1.WG =  strcompress(good_WG11WG12.WG, /remove_all) $ +'|' + strcompress(good_WG12WG11.WG, /remove_all)
      
      test1.SETUP='U580'
      
      MWRFITS,test1 , file_WG11WG12c , head_1 , /CREATE  , /No_comment 
      MWRFITS,test2 , file_WG11WG12c , head_2   , /No_comment

;
;         writing the files
;
          good_WG11WG12.SPT[0:*] ='  '
          good_WG11WG12.EW_TABLE[0:*]='  '
          good_WG11WG12.REMARK[0:*]='  '
          remove_abund, good_WG11WG12c   
          file_WG11WG12 = path + 'WG15_Products/common_WG11_WG12.fits'
          MWRFITS,good_WG11WG12 , file_WG11WG12 , head_11 , /CREATE, /No_comment

 
          add_WG15_extension,file_WG11WG12, file_WG11WG12
          file_WG12WG11 = path + 'WG15_Products/common_WG12_WG11.fits'
          MWRFITS,good_WG12WG11 , file_WG12WG11 , head_12 , /CREATE, /No_comment
          add_WG15_extension, file_WG12WG11, file_WG12WG11
          endif
       endif
;############################################################
;
;
;                  11 13 common stars
;
;
;############################################################

       if (nWG11_WG13 ne 0 ) then begin

;       WG11WG13 = datawg11(dr2_wg11(com_WG11_WG13))
       WG11WG13 = wg11_woBS(dr2_wg11_woBS(com_WG11_WG13))
       
       WG13WG11 = datawg13(dr2_wg13(com_WG11_WG13))
       valid1113 = where(WG11WG13.teff GT 2000 and WG11WG13.teff lT 110000  $
       and WG13WG11.teff GT 2000 and WG13WG11.teff lT 110000, v1113count)
       good_WG11WG13 = WG11WG13(valid1113)
       good_WG13WG11 = WG13WG11(valid1113)
 


          good_WG11WG13.SPT[0:*] ='  '
          good_WG11WG13.EW_TABLE[0:*]='  '
          good_WG11WG13.REMARK[0:*]='  '
          good_WG11WG13.PECULI[0:*]='  '
          
          remove_abund, good_WG11WG13  

;
;       writing the files
;
       file_WG11WG13 = path + 'WG15_Products/common_WG11_WG13.fits'
       MWRFITS,good_WG11WG13 , file_WG11WG13 , head_11 , /CREATE, /No_comment
       add_WG15_extension,file_WG11WG13, file_WG11WG13
       file_WG13WG11 = path + 'WG15_Products/common_WG13_WG11.fits'
       MWRFITS,good_WG13WG11 , file_WG13WG11 , head_13 , /CREATE, /No_comment
       add_WG15_extension,file_WG13WG11, file_WG13WG11
       endif

;############################################################
;
;
;
;                    12 13 common stars
;
;
;############################################################

       if (nWG12_WG13 ne 0 ) then begin

;       WG12WG13 = datawg12(dr2_wg12(com_WG12_WG13))
       WG12WG13 = wg12_woBS(dr2_wg12_woBS(com_WG12_WG13))
       
       WG13WG12 = datawg13(dr2_wg13(com_WG12_WG13))
       valid1213 = where(WG12WG13.teff GT 2000 and WG12WG13.teff lT 120000  $
       and WG13WG12.teff GT 2000 and WG13WG12.teff lT 120000, v1213count)
       good_WG12WG13 = WG12WG13(valid1213)
       good_WG13WG12 = WG13WG12(valid1213)


      print, '+---------------------------------------'
      print, '|                                        '
      Print, '|    Proceed with WG12 - WG13 common stars '
      print, '|        rules adopted '
      print, '|    For all, select WG13  '
      print, '| '
      print, '|                                        '
      print, '+---------------------------------------'


        good_WG12WG13c = good_WG13WG12      ; select WG12 for all the cnames
        print, 'iDR2 : Remove the abundances for stars in common between WG12 and WG13' 
        
       remove_abund, good_WG12WG13c  
       file_WG12WG13c = path + 'WG15_Products/common_WG12_WG13_Recommended.fits'
       MWRFITS,good_WG12WG13c , file_WG12WG13c , head_12 , /CREATE, /No_comment
       add_WG15_extension,file_WG12WG13c, file_WG12WG13c    
   
;     
;     - adding info in PROVENANCE column 
;     - merging the TARGET and SETUPS   
;       taking      
 
      test1 = mrdfits(file_WG12WG13c , 1,head1, /SILENT)
      test2 = mrdfits(file_WG12WG13c ,2, head2, /SILENT)

      test2.AVAILABLE_PAR = 'WG13|HR3|HR5A|HR6|HR9B'+'-'+'WG12|HR15N'
      test1.WG = 'WG13'
      test1.SETUP= 'HR3|HR5|HR6|HR9B'

       print, ' we select WG13 vrad for WG12-WG13 common stars'
       test1.VEL[0:*]= !Values.F_NAN
       test2.PROV_VRAD = 'WG13'  


      MWRFITS,test1 , file_WG12WG13c , head_1 , /CREATE   , /No_comment
      MWRFITS,test2 , file_WG12WG13c , head_2  , /No_comment 


;
;       writing the files
;
       file_WG12WG13 = path + 'WG15_Products/common_WG12_WG13.fits'
       MWRFITS,good_WG12WG13 , file_WG12WG13 , head_12 , /CREATE, /No_comment
       add_WG15_extension,file_WG12WG13, file_WG12WG13
       file_WG13WG12 = path + 'WG15_Products/common_WG13_WG12.fits'
       MWRFITS,good_WG13WG12 , file_WG13WG12 , head_13 , /CREATE, /No_comment
       add_WG15_extension,file_WG13WG12, file_WG13WG12

        endif       




;
;
;     search cnames with single values in a single WG.
;     and cleaning the WG files
;

      search_single, b,dr2_wg10,dr2_wg11,dr2_wg12,dr2_wg13,resWG=WG10_single,nresWG10, WG='WG10'
      WG10_SS = datawg10(dr2_wg10(WG10_single))
      valid = where(WG10_SS.teff GT 2000 and WG10_SS.teff lT 100000, v10count)
      good_WG10_SS= WG10_SS(valid)
      help, good_WG10_SS
      
 

       file_WG10_woBS = path + 'WG15_products/WG10_withoutBS.fits'
       test1 = mrdfits(file_WG10_woBS , 1,head1)
       test2 = mrdfits(file_WG10_woBS,2, head2)

       testfile = path + 'WG15_Products/WG10_withoutBS_before_removing_double.fits'
       mwrfits, test1, testfile, head1, /CREATE, /No_comment
       mwrfits, test2, testfile, head2, /No_comment


       sizetest1=  size(test1, /N_ELEMENTS) 
       sel=fltarr(v10count)
       
       match, test1.cname,  good_WG10_SS.cname,a12, b12,COUNT=count1112
       match2, test1.cname,  good_WG10_SS.cname,a12, b12
       good = where (b12 ne -1 , count)
       goodval = b12(good)
       good_single = goodval[uniq(goodval, sort(goodval))]
      
       ttest1 =  (test1)(good_single)
       ttest2 = (test2)(good_single)
           
       testfile = path + 'WG15_Products/WG10_withoutBS.fits'
       mwrfits, ttest1, testfile, head1, /CREATE, /No_comment
       mwrfits, ttest2, testfile, head2, /No_comment
      
      
 
      search_single, b,dr2_wg10,dr2_wg11,dr2_wg12,dr2_wg13,resWG=WG11_single,nresWG11, WG='WG11'
      WG11_SS = datawg11(dr2_wg11(WG11_single))
      valid11 = where(WG11_SS.teff GT 2000 and WG11_SS.teff lT 100000, v11count)
      good_WG11_SS= WG11_SS(valid11)

      help, good_WG11_SS
      
       file_WG11_woBS = path + 'WG15_products/WG11_withoutBS.fits'
       test1 = mrdfits(file_WG11_woBS , 1,head1)
       test2 = mrdfits(file_WG11_woBS,2, head2)

      testfile = path + 'WG15_Products/WG11_withoutBS_before_removing_double.fits'
       mwrfits, test1, testfile, head1, /CREATE, /No_comment
       mwrfits, test2, testfile, head2, /No_comment



       sizetest1=  size(test1, /N_ELEMENTS) 
       sel=fltarr(v11count)
       
       match, test1.cname,  good_WG11_SS.cname,a12, b12,COUNT=count1112
       match2, test1.cname,  good_WG11_SS.cname,a12, b12
       good = where (b12 ne -1 , count)

       goodval = b12(good)
       good_single = goodval[uniq(goodval, sort(goodval))]
      
       ttest1 =  (test1)(good_single)
       ttest2 = (test2)(good_single)

;
;
;  adding the 9 stars with WG11 and WG12 (with TEFF=NULL)
;
;
       file_WG11_woBS = path + 'WG15_products/WG11_withoutBS_before_removing_double.fits'
       rescue_1 = mrdfits(file_WG11_woBS , 1,head1)
       rescue_2 = mrdfits(file_WG11_woBS,2, head2)

            rescued_index = where( ( STRMATCH(strcompress( rescue_1.cname , /remove_all),'*11010007-7738516*', /FOLD_CASE) eq 1)) ;  $
;             or ( STRMATCH(strcompress( rescue_1.cname , /remove_all),'*11080412-7513273*', /FOLD_CASE) eq 1)   $
;             or ( STRMATCH(strcompress( rescue_1.cname , /remove_all),'*11100704-7629377*', /FOLD_CASE) eq 1)   $
;             or ( STRMATCH(strcompress( rescue_1.cname , /remove_all),'*11140941-7714492*', /FOLD_CASE) eq 1)   $
;             or ( STRMATCH(strcompress( rescue_1.cname , /remove_all),'*11142964-7707063*', /FOLD_CASE) eq 1)   $
;             or ( STRMATCH(strcompress( rescue_1.cname , /remove_all),'*18505581-0618148*', /FOLD_CASE) eq 1)   $
;             or ( STRMATCH(strcompress( rescue_1.cname , /remove_all),'*18510093-0614564*', /FOLD_CASE) eq 1)   $
;             or ( STRMATCH(strcompress( rescue_1.cname , /remove_all),'*18510662-0612442*', /FOLD_CASE) eq 1)   $            
;             or ( STRMATCH(strcompress( rescue_1.cname , /remove_all),'*18511116-0614340*', /FOLD_CASE) eq 1) )  
 
;          tresc1 =  (rescue_1)(rescued_index)
;          tresc2 =  (rescue_2)(rescued_index)
       
;          ttest1 = [ttest1,tresc1]
;          ttest2 = [ttest2,tresc2]
           

           
       testfile = path + 'WG15_Products/WG11_withoutBS.fits'
       mwrfits, ttest1, testfile, head1, /CREATE, /No_comment
       mwrfits, ttest2, testfile, head2, /No_comment
      
      


      search_single, b,dr2_wg10,dr2_wg11,dr2_wg12,dr2_wg13,resWG=WG12_single,nresWG12, WG='WG12'
      WG12_SS = datawg12(dr2_wg12(WG12_single))
      valid12 = where(WG12_SS.teff GT 2000 and WG12_SS.teff lT 100000, v12count)

;      good_WG12_SS= WG12_SS(valid12)
;
;    no more Teff constraint
;    as there might be results for Li or Accr rate.....
;      
      good_WG12_SS= WG12_SS
      help, good_WG12_SS


       file_WG12_woBS = path + 'WG15_products/WG12_withoutBS.fits'
       test1 = mrdfits(file_WG12_woBS , 1,head1)
       test2 = mrdfits(file_WG12_woBS,2, head2)

       testfile = path + 'WG15_Products/WG12_withoutBS_before_removing_double.fits'
       mwrfits, test1, testfile, head1, /CREATE, /No_comment
       mwrfits, test2, testfile, head2, /No_comment


       sizetest1=  size(test1, /N_ELEMENTS) 
       sel=fltarr(v12count)
       
       match, test1.cname,  good_WG12_SS.cname,a12, b12,COUNT=count1112
       match2, test1.cname,  good_WG12_SS.cname,a12, b12
       good = where (b12 ne -1 , count)
       goodval = b12(good)
       good_single = goodval[uniq(goodval, sort(goodval))]
      
       ttest1 =  (test1)(good_single)
       ttest2 = (test2)(good_single)

;       match, ttest1.cname, good_WG12WG10c.cname, a, b, count=count_tt1210
;       print, 'count_tt1210 ', count_tt1210
       
           
       testfile = path + 'WG15_Products/WG12_withoutBS.fits'
       mwrfits, ttest1, testfile, head1, /CREATE, /No_comment
       mwrfits, ttest2, testfile, head2, /No_comment

       testfile = path + 'WG15_Products/WG12_withoutBS_after_removing_double.fits'
       mwrfits, ttest1, testfile, head1, /CREATE, /No_comment
       mwrfits, ttest2, testfile, head2, /No_comment


     search_single, b,dr2_wg10,dr2_wg11,dr2_wg12,dr2_wg13,resWG=WG13_single,nresWG13, WG='WG13'
      WG13_SS = datawg13(dr2_wg13(WG13_single))
      valid13 = where(WG13_SS.teff GT 2000 and WG13_SS.teff lT 100000, v13count)
      good_WG13_SS= WG13_SS(valid13)
      help, good_WG13_SS

       file_WG13_woBS = path + 'WG15_products/WG13_withoutBS.fits'
       test1 = mrdfits(file_WG13_woBS , 1,head1)
       test2 = mrdfits(file_WG13_woBS,2, head2)

       sizetest1=  size(test1, /N_ELEMENTS) 
       sel=fltarr(v13count)
       
       match, test1.cname,  good_WG13_SS.cname,a12, b12,COUNT=count1112
       match2, test1.cname,  good_WG13_SS.cname,a12, b12
       good = where (b12 ne -1 , count)
       goodval = b12(good)
       good_single = goodval[uniq(goodval, sort(goodval))]
      
       ttest1 =  (test1)(good_single)
       ttest2 = (test2)(good_single)
           
       testfile = path + 'WG15_Products/WG13_withoutBS.fits'
       mwrfits, ttest1, testfile, head1, /CREATE, /No_comment
       mwrfits, ttest2, testfile, head2, /No_comment



      noskip=0
      
      if (noskip eq 1 ) then begin
;
;          Not sure that it is still useful !! 
;
;          finding  index with only WG10 results  
;       
           WG10_single = where(((dr2_wg10 ne -1) and (dr2_wg11 eq -1) and (dr2_wg12 eq -1) and (dr2_wg13 eq -1)), nwg10_single)
       
;          help,WG10_single
       

           print, 'number of WG10 only spectra ', nwg10_single


;          sorting multiple and single WG10 results 
;          flagging the multiples
;

           nmult = 0
           for i=0, nwg10_single-1 do begin
              res = 0
              count = 0
              index = WG10_single(i)
              indexwg10=dr2_wg10(index)
              if (indexwg10 ne -1 ) then begin
                 res = where(dr2_wg10 eq indexwg10, count)
                 size_res= size(res, /N_elements)
                 if (size_res ge 2 ) then begin
                    print, 'mult found' 
                    nmult = nmult + 1
                   for l=0, size_res - 1 do begin
                      dr2_wg10(res(l)) =-1
                   endfor
                 endif
               endif
           endfor
       
          WG10_1WG_1CNAME = where(((dr2_wg10 ne -1) and (dr2_wg11 eq -1) and (dr2_wg12 eq -1) and (dr2_wg13 eq -1)), nwg10_1WG_1CNAME)
;         print, 'nwg10_single ',nwg10_single 
;     help, WG10_1WG_1CNAME

     for j=0,nwg10_1WG_1CNAME-1 do begin
          index=WG10_single(j)
          indexwg10=dr2_wg10(index)       
;         print, j,' ',index,' ',indexwg10,' ',(dataWG10.cname)(indexwg10),' ',(dataWG10.target)(indexwg10),' ',dr2_wg11(index), ' ', dr2_wg12(index), ' ', dr2_wg13(index)
     endfor
    endif

    print, 'job finished '

end


;++++++++++++++++++++++++++++++++++++++++++++
; NAME:      append_WG14_flags
; PURPOSE:
;       
; EXPLANATION:
;
; CALLING SEQUENCE:
;    
; INPUTS:
;       
; OUTPUTS:
;     
; RESTRICTIONS:
; 
; EXAMPLE:
;; MODIFICATION HISTORY
; 
; created Patrick FRANCOIS February 2014
;-------------------------------------------------------------------------

pro append_WG14_flags, WG_woBS, WG14_woBS
;
       match2, WG_woBS.cname,  WG14_woBS.cname,bb, b14 
       size2=size(b14, /N_ELEMENTS)
       size3=size(bb, /N_ELEMENTS)
;       print, 'b11 b14 ', size3, size2 
       if (size2 ne 0 and size3 ne 0 ) then begin
          WGWG14 = WG_woBS(bb)
          WG14WG = WG14_woBS(b14)
       
;      Appending the WG14 flags to WG
; 
          FLAG_pec = strcompress(WG_woBS.PECULI, /remove_all)
          FLAG14_pec = strcompress(WG14_woBS.PECULI, /remove_all)       
          FLAG_tech = strcompress(WG_woBS.TECH, /remove_all)
          FLAG14_tech = strcompress(WG14_woBS.TECH, /remove_all)       
          FLAG_rem = strcompress(WG_woBS.REMARK, /remove_all)
          FLAG14_rem = strcompress(WG14_woBS.REMARK, /remove_all)       

          NEWFLAG_pec=FLAG_pec
          NEWFLAG_tech=FLAG_tech
          NEWFLAG_rem=FLAG_rem
          
;
;      working on PECULI flag
;
 
          for j=0, size3 - 1 do begin
              if (bb(j) ne -1 ) then begin
                 index14=bb(j)
;                 print, 'j ', j , ' index14 ', index14
                 if (FLAG_pec(j) eq '' ) then begin 
                    NEWFLAG_pec(j)=FLAG14_pec(index14)
;                   print, j, ' case1'
                 endif
                 if (FLAG14_pec(index14) eq '' ) then begin
                    NEWFLAG_pec(j)=FLAG14_pec(index14)
;                   print, j,' case2'
                 endif
                 if (FLAG_pec(j) ne ''  and FLAG14_pec(index14) ne '') then begin
                    NEWFLAG_pec(j) = FLAG_pec(j) + '|'+ FLAG14_pec(index14)
;                    print, 'both PECULI flags ',  NEWFLAG_pec(j), ' ',(WG_woBS.CNAME)(j),' ',(WG_woBS.TARGET)(j),' ', (WG_woBS.OBJECT)(j), $
;                    (WG14_woBS.CNAME)(index14),' index in WG ',j, ' index14  ', index14, ' ', FLAG_pec(j), ' ', FLAG14_pec(index14)            
                 endif   
              endif
;             print, 'PEC flags ', NEWFLAG_pec(j)
          endfor
          WG_woBS.PECULI = NEWFLAG_pec        
      
;
;      working on TECH flag
;
          for j=0, size3 - 1 do begin
              if (bb(j) ne -1 ) then begin
                 index14=bb(j)
;                 print, 'j ', j , ' index14 ', index14
                 if (FLAG_TECH(j) eq '' ) then begin 
                    NEWFLAG_TECH(j)=FLAG14_TECH(index14)
;                   print, j, ' case1'
                 endif
                 if (FLAG14_TECH(index14) eq '' ) then begin
                    NEWFLAG_TECH(j)=FLAG14_TECH(index14)
;                   print, j,' case2'
                 endif
                 if (FLAG_TECH(j) ne ''  and FLAG14_TECH(index14) ne '') then begin
                    NEWFLAG_TECH(j) = FLAG_TECH(j) + '|'+ FLAG14_TECH(index14)
 ;                   print, 'both TECH flags ',  NEWFLAG_TECH(j), ' ',(WG_woBS.CNAME)(j),' ',(WG_woBS.TARGET)(j),' ', (WG_woBS.OBJECT)(j), $
;                    (WG14_woBS.CNAME)(index14),' index in WG ',j, ' index14  ', index14, ' ', FLAG_TECH(j), ' ', FLAG14_TECH(index14)            
                 endif   
              endif
;             print, 'TECH flags ', NEWFLAG_TECH(j)
          endfor
          WG_woBS.TECH = NEWFLAG_TECH        
      
;
;      working on REMARK flag
;
          for j=0, size3 - 1 do begin
              if (bb(j) ne -1 ) then begin
                 index14=bb(j)
;                 print, 'j ', j , ' index14 ', index14
                 if (FLAG_REM(j) eq '' ) then begin 
                    NEWFLAG_REM(j)=FLAG14_REM(index14)
;                   print, j, ' case1'
                 endif
                 if (FLAG14_REM(index14) eq '' ) then begin
                    NEWFLAG_REM(j)=FLAG14_REM(index14)
;                   print, j,' case2'
                 endif
                 if (FLAG_REM(j) ne ''  and FLAG14_REM(index14) ne '') then begin
                    NEWFLAG_REM(j) = FLAG_REM(j) + '|'+ FLAG14_REM(index14)
;                    print, 'both REMARK flags ',  NEWFLAG_REM(j), ' ',(WG_woBS.CNAME)(j),' ',(WG_woBS.TARGET)(j),' ', (WG_woBS.OBJECT)(j), $
;                    (WG14_woBS.CNAME)(index14),' index in WG ',j, ' index14  ', index14, ' ', FLAG_REM(j), ' ', FLAG14_REM(index14)            
                 endif   
              endif
;             print, 'REM flags ', NEWFLAG_REM(j)
          endfor
          WG_woBS.REMARK = NEWFLAG_REM        
      
      
      
      
       endif
       
       
return
end

;++++++++++++++++++++++++++++++++++++++++++++
; NAME:      transfer_DR2_U580_VEL
; PURPOSE:
;       
; EXPLANATION:
;
; CALLING SEQUENCE:
;    
; INPUTS:
;       
; OUTPUTS:
;     
; RESTRICTIONS:
; 
; EXAMPLE:
;; MODIFICATION HISTORY
; 
; created Patrick FRANCOIS March 2014
;-------------------------------------------------------------------------

pro  transfer_DR2_U580_VEL, DR2_woBS, WG_in , WG_out
;-------------------------------
;
;        WG11 RADIAL VELOCITY 
;
;-------------------------------


       print, ' transferring the masterlist VEL column to WG'
      
;       sel_WGHR15N = where(STRMATCH(strcompress(DR2_woBS.SETUP, /remove_all),'*HR15N*', /FOLD_CASE) eq 1, count1) 
       
       sel_WGU580l = where(STRMATCH(strcompress(DR2_woBS.FILENAME, /remove_all),'uvl*', /FOLD_CASE) eq 1  $
       and STRMATCH(strcompress(DR2_woBS.SETUP, /remove_all),'*U580*', /FOLD_CASE) eq 1, countl)
;       print, 'countl  ',countl
       sel_WGU580u = where(STRMATCH(strcompress(DR2_woBS.FILENAME, /remove_all),'uvu*', /FOLD_CASE) eq 1 $
       and STRMATCH(strcompress(DR2_woBS.SETUP, /remove_all),'*U580*', /FOLD_CASE) eq 1, countu)
;       print, 'countu  ', countu

       sel_WGU580rl = where(STRMATCH(strcompress(DR2_woBS.FILENAME, /remove_all),'url*', /FOLD_CASE) eq 1  $
       and STRMATCH(strcompress(DR2_woBS.SETUP, /remove_all),'*U580*', /FOLD_CASE) eq 1, countr)

       sel_WGU580ru = where(STRMATCH(strcompress(DR2_woBS.FILENAME, /remove_all),'uru*', /FOLD_CASE) eq 1  $
       and STRMATCH(strcompress(DR2_woBS.SETUP, /remove_all),'*U580*', /FOLD_CASE) eq 1, countr)

 ;      print, 'countl, countu ', countl, countu
     
        DR2_uvl= DR2_woBS(sel_WGU580l)
        DR2_uvu= DR2_woBS(sel_WGU580u)
        DR2_url= DR2_woBS(sel_WGU580rl)
        DR2_uru= DR2_woBS(sel_WGU580ru)
        
;        sel_WGU580 = where(STRMATCH(strcompress(WG_woBS.SETUP, /remove_all),'U580*', /FOLD_CASE) eq 1, count_WGu) ; $

      
        WG_U580 =WG_in  ; all the WG cnames are in U580
        size_WG_in= size(WG_in, /N_ELEMENTS)
        
        
          vel_l=fltarr(size_WG_in)
          vel_u=fltarr(size_WG_in)

          vrad=fltarr(size_WG_in)
          e_vrad=fltarr(size_WG_in)
  
        for i=0, size_WG_in -1 do begin
           WG_U580CNAME=WG_U580.CNAME
           WG_U580VEL=WG_U580.VEL
           WG_U580VRAD=WG_U580.VRAD
           WG_U580E_VRAD=WG_U580.E_VRAD
           DR2_uvlcname=DR2_uvl.cname
           DR2_uvucname=DR2_uvu.cname
           DR2_urlcname=DR2_url.cname
           DR2_urucname=DR2_uru.cname
           
           DR2_uvlVEL=DR2_uvl.vel
           DR2_uvuVEL=DR2_uvu.vel
           DR2_urlVEL=DR2_url.vel
           DR2_uruVEL=DR2_uru.vel
           
           star=strcompress(WG_U580CNAME(i), /remove_all)

;
;         Working with uvl and uvu filenames (the majority )
;

           for k=0, countl - 1 do begin
              starDR2 = strcompress(DR2_uvlcname(k) , /remove_all)
              if ( starDR2 eq star ) then begin
                 vel_l(i)=DR2_uvlvel(k)
;                 print , i,' ', k, ' ', star, ' ', starDR2,' ', DR2_uvlvel(k),' ',WG_U580vel(i)
              endif
           endfor
           
           for k1=0, countl - 1 do begin
              starDR2 = strcompress(DR2_uvucname(k1) , /remove_all)
              if ( starDR2 eq star ) then begin
                 vel_u(i)=DR2_uvuvel(k1)
  ;               print , i,' ', k, ' ', star, ' ', starDR2,' ', DR2_uvuvel(k1),' ',WG_U580vel(i)
              endif
           endfor
;
;       we do the same for uru and url filenames (M67)
;           
           for k=0, countr - 1 do begin
              starDR2 = strcompress(DR2_urlcname(k) , /remove_all)
              if ( starDR2 eq star ) then begin
                 vel_l(i)=DR2_urlvel(k)
;                 print , i,' ', k, ' ', star, ' ', starDR2,' ', DR2_uvlvel(k),' ',WG_U580vel(i)
              endif
           endfor
           
           for k1=0, countr - 1 do begin
              starDR2 = strcompress(DR2_urucname(k1) , /remove_all)
              if ( starDR2 eq star ) then begin
                 vel_u(i)=DR2_uruvel(k1)
  ;               print , i,' ', k, ' ', star, ' ', starDR2,' ', DR2_uvuvel(k1),' ',WG_U580vel(i)
              endif
           endfor


           
           
           
        endfor
 
;
;      combining the velocities for the uvl and uvu
; 
            for i=0, size_WG_in -1 do begin 
               if (vel_l(i) eq vel_l(i)  and vel_u(i) eq vel_u(i) ) then begin
                  v1 =vel_l(i)
                  v2 = vel_u(i)
                  x = [v1, v2]
                 vrad(i) = (vel_l(i) + vel_u(i) ) /2.
                 dev = STDDEV(x)
                 e_vrad(i)=dev
                 WG_U580VEL(i)=vrad(i)
                 WG_U580VRAD(i)=vrad(i)
                 WG_U580E_VRAD(i)=e_vrad(i)
              endif
              if ( vel_l(i) ne vel_l(i)) then begin
                 vrad(i) = vel_u(i) 
                 e_vrad(i)= !Values.F_NAN
;                 print, ' vel_l(i) eq  NaN '
                 WG_U580VEL(i)=vrad(i)
                 WG_U580VRAD(i)=vrad(i)
                 WG_U580E_VRAD(i)=e_vrad(i)
                 
              endif
              if (vel_u(i) ne vel_u(i)) then begin
 ;               print, 'vel_u(i) eq  NaN '
                 vrad(i) = vel_l(i) 
                 e_vrad(i)= !Values.F_NAN
                 WG_U580VEL(i)=vrad(i)
                 WG_U580VRAD(i)=vrad(i)
                 WG_U580E_VRAD(i)=e_vrad(i)
                 
              endif
              if (vel_l(i) ne vel_l(i)  and (vel_u(i) ne vel_u(i))) then begin
                 vrad(i) =!Values.F_NAN
                 e_vrad(i)= !Values.F_NAN
                 WG_U580VEL(i)=vrad(i)
                 WG_U580VRAD(i)=vrad(i)
                 WG_U580E_VRAD(i)=e_vrad(i)
                 
              endif
           endfor   
         WG_out = WG_U580      
         WG_out.VEL  = WG_U580VEL
         WG_out.VRAD  = WG_U580VRAD
         WG_out.E_VRAD  = WG_U580E_VRAD

return
end


;++++++++++++++++++++++++++++++++++++++++++++
; NAME:      transfer_DR2_WG10_VEL
; PURPOSE:
;       
; EXPLANATION:
;
; CALLING SEQUENCE:
;    
; INPUTS:
;       
; OUTPUTS:
;     
; RESTRICTIONS:
; 
; EXAMPLE:
;; MODIFICATION HISTORY
; 
; created Patrick FRANCOIS March 2014
;-------------------------------------------------------------------------

pro       transfer_DR2_WG10_VEL, dataDR2, WG_in, WG_out
 
 
              
       sel_HR10 = where(STRMATCH(strcompress(dataDR2.SETUP, /remove_all),'*HR10*', /FOLD_CASE) eq 1, count_HR10)        
       sel_HR15 = where( STRMATCH(strcompress(dataDR2.SETUP, /remove_all),'*HR15N*', /FOLD_CASE) eq 1 , count_HR15 ) 
       sel_HR9B = where(  STRMATCH(strcompress(dataDR2.SETUP, /remove_all),'*HR9B*', /FOLD_CASE) eq 1, count_HR9B)    
             
        print, 'count ', count_HR10, count_HR15, count_HR9B
   
       WG_incname= WG_in.cname
       WG_outVRAD = WG_out.VRAD
       dataDR2WG10_HR10 = dataDR2(sel_HR10)
       dataDR2WG10_HR15 = dataDR2(sel_HR15)
       dataDR2WG10_HR9B = dataDR2(sel_HR9B)
       dataDR2WG10_HR10VEL= dataDR2WG10_HR10.VEL
       dataDR2WG10_HR15VEL= dataDR2WG10_HR15.VEL
       dataDR2WG10_HR9BVEL= dataDR2WG10_HR9B.VEL
       
       size_WG_in = size(WG_in, /N_ELEMENTS)

       for i=0,  size_WG_in - 1 do begin

          starname=WG_incname(i)
       
       match2, dataDR2WG10_HR10.cname,  starname,a10, b10
       match2, dataDR2WG10_HR15.cname,  starname,a15, b15
       match2, dataDR2WG10_HR9B.cname,  starname,a9B, b9B
       goodval10 = where(b10 ne -1, count10)
       goodval15 = where(b15 ne -1, count15)
       goodval9B = where(b9B ne -1, count9B)
       
        if (count10 ge 1 ) then begin
        WG_outVRAD(i)= dataDR2WG10_HR10VEL(b10(0))
;        print, 'goodval ', goodval10
;        print,starname, ' HR10 setup, vrad :', WG_outVRAD(i)
        endif  else if (count15 ge 1 ) then begin
         WG_outVRAD(i)= dataDR2WG10_HR15VEL(b15(0))
          print,starname,  'HR15 setup, vrad :', WG_outVRAD(i) 
         endif  else if (count9B ge 1 ) then begin       
       WG_outVRAD(i)= dataDR2WG10_HR9BVEL(b9B(0))
       print, starname, ' HR9B setup, vrad :', WG_outVRAD(i)
       endif
       endfor
       WG_out.VRAD = WG_outVRAD
       WG_out.E_VRAD[0:*]=!Values.F_NAN
return
end

;++++++++++++++++++++++++++++++++++++++++++++
; NAME:      transfer_DR2_WG12_VEL
; PURPOSE:
;       
; EXPLANATION:
;
; CALLING SEQUENCE:
;    
; INPUTS:
;       
; OUTPUTS:
;     
; RESTRICTIONS:
; 
; EXAMPLE:
;; MODIFICATION HISTORY
; 
; created Patrick FRANCOIS March 2014
;-------------------------------------------------------------------------

pro  transfer_DR2_WG12_VEL, DR2_woBS, WG_in , WG_out

       vrad_off_HR10 =  0.00
       vrad_off_HR15N = -0.13
       vrad_off_HR21 = -0.38
       vrad_off_U580 = +0.47
       vrad_off_HR09B = 0.00

;       sel_WG12HR15N = where(STRMATCH(strcompress(DR2_woBS.SETUP, /remove_all),'*HR15N*', /FOLD_CASE) eq 1, count1) 

;
;      Working with U580 SETUP
;
       
       sel_WG12U580l = where(STRMATCH(strcompress(DR2_woBS.FILENAME, /remove_all),'uvl*', /FOLD_CASE) eq 1  $
       and STRMATCH(strcompress(DR2_woBS.SETUP, /remove_all),'*U580*', /FOLD_CASE) eq 1, countl)
;       print, 'countl  ',countl
       sel_WG12U580u = where(STRMATCH(strcompress(DR2_woBS.FILENAME, /remove_all),'uvu*', /FOLD_CASE) eq 1 $
       and STRMATCH(strcompress(DR2_woBS.SETUP, /remove_all),'*U580*', /FOLD_CASE) eq 1, countu)
;       print, 'countu  ', countu
     
        DR2_uvl= DR2_woBS(sel_WG12U580l)
        DR2_uvu= DR2_woBS(sel_WG12U580u)
        
        sel_WG12U580 = where(STRMATCH(strcompress(WG_in.SETUP, /remove_all),'U580*', /FOLD_CASE) eq 1, count_WG12u) ; $
      
        WG12_U580 =WG_in(sel_WG12U580)
        
;        print, 'count_WG12u ', count_WG12u
          vel_l=fltarr(count_WG12u)
          vel_u=fltarr(count_WG12u)
          vrad=fltarr(count_WG12u)
          e_vrad=fltarr(count_WG12u)
  
        for i=0, count_WG12u -1 do begin
           WG12_U580CNAME=WG12_U580.CNAME
           WG12_U580VEL=WG12_U580.VEL
           WG12_U580VRAD=WG12_U580.VRAD
           WG12_U580E_VRAD=WG12_U580.E_VRAD
           
           DR2_uvlcname=DR2_uvl.cname
           DR2_uvucname=DR2_uvu.cname
           DR2_uvlVEL=DR2_uvl.vel
           DR2_uvuVEL=DR2_uvu.vel
           star=strcompress(WG12_U580CNAME(i), /remove_all)
           for k=0, countl - 1 do begin
              starDR2 = strcompress(DR2_uvlcname(k) , /remove_all)
              if ( starDR2 eq star ) then begin
                 vel_l(i)=DR2_uvlvel(k)
;                 print , i,' ', k, ' ', star, ' ', starDR2,' ', DR2_uvlvel(k),' ',WG12_U580vel(i)
              endif
           endfor
           for k1=0, countl - 1 do begin
              starDR2 = strcompress(DR2_uvucname(k1) , /remove_all)
              if ( starDR2 eq star ) then begin
                 vel_u(i)=DR2_uvuvel(k1)
  ;               print , i,' ', k, ' ', star, ' ', starDR2,' ', DR2_uvuvel(k1),' ',WG12_U580vel(i)
              endif
           endfor
           
        endfor
 
;
;      combining the velocities for the uvl and uvu
; 
            for i=0, count_WG12u -1 do begin 
               v1= vel_l(i)
               v2 = vel_u(i)
               x =[v1, v2]
               if (vel_l(i) eq vel_l(i)  and vel_u(i) eq vel_u(i) ) then begin
                 vrad(i) = (vel_l(i) + vel_u(i) ) /2.
                 dev = STDDEV(x)
                 e_vrad(i) = dev
;                 print,' stddev  ', dev
                 WG12_U580VEL(i)=vrad(i)
                 WG12_U580VRAD(i)=vrad(i)
                 WG12_U580E_VRAD(i)=e_vrad(i)
                 
              endif
              if ( vel_l(i) ne vel_l(i)) then begin
                 vrad(i) = vel_u(i) 
;                 print, ' vel_l(i) eq  NaN '
                 e_vrad(i)= !Values.F_NAN
                 WG12_U580VEL(i)=vrad(i)
                 WG12_U580VRAD(i)=vrad(i)
                 WG12_U580E_VRAD(i)=e_vrad(i)
                 
              endif
              if (vel_u(i) ne vel_u(i)) then begin
 ;               print, 'vel_u(i) eq  NaN '
                 vrad(i) = vel_l(i) 
                 e_vrad(i)= !Values.F_NAN
                 WG12_U580VEL(i)=vrad(i)
                 WG12_U580VRAD(i)=vrad(i)
                 WG12_U580E_VRAD(i)=e_vrad(i)

              endif
              if (vel_l(i) ne vel_l(i)  and (vel_u(i) ne vel_u(i))) then begin
                 vrad(i) =!Values.F_NAN
                 e_vrad(i)= !Values.F_NAN
                 WG12_U580VEL(i)=vrad(i)
                 WG12_U580VRAD(i)=vrad(i)
                 WG12_U580E_VRAD(i)=e_vrad(i)
                 
              endif
           endfor   
               
;       print, WG12_U580.SETUP          

;      working with HR15N setup 
;

;
;     we select the DR2 rows with HR15N setup
;

       sel_WG12HR15N = where(STRMATCH(strcompress(DR2_woBS.SETUP, /remove_all),'*HR15N*', /FOLD_CASE) eq 1, count1) 
       DR2_HR15 =  DR2_woBS(sel_WG12HR15N)
       sel_WG12HR15 = where(STRMATCH(strcompress(WG_in.SETUP, /remove_all),'*HR15N*', /FOLD_CASE) eq 1, count1) 
       WG_inHR15 = WG_in(sel_WG12HR15)
       
       match, DR2_HR15.cname,  WG_inHR15.cname,a10, b10,COUNT=countDR2wg10
       match2, DR2_HR15.cname,  WG_inHR15.cname,a10, b10
       sizeb10 = size(b10, /N_ELEMENTS)
       sizea10 = size(a10, /N_ELEMENTS)
       print, sizea10, sizeb10
       DR2_HR15SETUP=DR2_HR15.SETUP
       DR2_HR15CNAME=DR2_HR15.cname
       DR2_HR15VEL=DR2_HR15.VEL
       DR2_HR15FILENAME =DR2_HR15.FILENAME
       
       WG_inHR15SETUP=WG_inHR15.SETUP
       WG_inHR15VEL=WG_inHR15.VEL
       WG_inHR15VRAD=WG_inHR15.VRAD
       WG_inHR15E_VRAD=WG_inHR15.E_VRAD
       
       WG_inHR15CNAME=WG_inHR15.CNAME
       WG_inHR15FILENAME=WG_inHR15.FILENAME
       WG_inHR15TARGET=WG_inHR15.target
       
       
;       for i=0, sizeb10 - 1 do begin
;       j = b10(i)
;            if (j ne -1   and STRMATCH(strcompress(WG_inHR15SETUP(i), /remove_all),'*HR15N*', /FOLD_CASE) eq 1 ) then begin
;                print, j,'  ', WG_inHR15CNAME(i), '  ',DR2_HR15CNAME(j),' ', WG_inHR15target[i], WG_inHR15VEL[i], WG_inHR15SETUP[i],DR2_HR15SETUP[j], DR2_HR15VEL[j]  
;                 WG_inVEL[i] =   DR2_woBSVEL[j]      
;            endif
;       endfor
       


       goodval = where( b10 ne -1    and STRMATCH(strcompress(WG_inHR15SETUP, /remove_all),'*HR15N*', /FOLD_CASE) eq 1 , count)
       goodvala=where(a10 ne -1, counta)

;
  
;       DR2_woBSVEL=DR2_woBS.VEL
;       DR2_woBSFILENAME =DR2_woBS.FILENAME
       
;       print, 'number of HR15N  : ', count
;       print, dataDR2WG12HR15N.target
       WG_inHR15NVELgood = DR2_HR15VEL(b10(goodval))
       WG_inHR15NSETUPgood = DR2_HR15SETUP(b10(goodval))

        sizegood = size(goodval, /N_ELEMENTS)
        
        
;       for i=0,  sizegood -1 do begin
;        j=b10(i)
;       print,  j,'  ', WG_inHR15CNAME(i), '  ',DR2_HR15CNAME(j),' ', WG_inHR15target[i], WG_inHR15VEL[i], WG_inHR15SETUP[i],DR2_HR15SETUP[j], DR2_HR15VEL[j] 
;       endfor
        
      
       WG_inHR15NVRAD = WG_inHR15NVELgood
       
       
       
;
;     setting E_VRAD for WG12 / HR15N setup as NULL
;       
       WG_inHR15NE_VRAD = fltarr(count)
       for i3=0, count -1 do begin
       WG_inHR15NE_VRAD(i3) = !Values.F_NAN
       endfor
      
       
        
        
        
       WG_inVEL = [WG_inHR15NVELgood,  WG12_U580VEL]
       WG_inVRAD = [WG_inHR15NVRAD,  WG12_U580VRAD]
       WG_inE_VRAD = [WG_inHR15NE_VRAD,  WG12_U580E_VRAD]
       


        WG_out = [WG_inHR15,  WG12_U580]
        WG_out.VEL  = WG_inVEL 
        WG_out.VRAD = WG_inVRAD
        WG_out.E_VRAD = WG_inE_VRAD 
      
      
         
return
end


;++++++++++++++++++++++++++++++++++++++++++++
; NAME:      remove_abund
; PURPOSE:
;       
; EXPLANATION:
;
; CALLING SEQUENCE:
;    
; INPUTS:
;       
; OUTPUTS:
;     
; RESTRICTIONS:
; 
; EXAMPLE:
;; MODIFICATION HISTORY
; 
; created Patrick FRANCOIS March 2014
;-------------------------------------------------------------------------

pro remove_abund, data

data.VSINI[0:*]=!Values.F_NAN   
data.E_VSINI[0:*]=!Values.F_NAN 
data.LI1[0:*]=!Values.F_NAN  
data.UPPER_COMBINED_LI1[0:*]=-1
data.E_LI1[0:*]=!Values.F_NAN   
data.NN_LI1[0:*]=-1  
data.ENN_LI1[0:*]=!Values.F_NAN 
data.NL_LI1[0:*]=-1  
data.C1[0:*]=!Values.F_NAN      
data.UPPER_COMBINED_C1[0:*]=-1
data.E_C1[0:*]=!Values.F_NAN    
data.NN_C1[0:*]=-1   
data.ENN_C1[0:*]=!Values.F_NAN  
data.NL_C1[0:*]=-1   
data.O1[0:*]=!Values.F_NAN      
data.UPPER_COMBINED_O1[0:*]=-1
data.E_O1[0:*]=!Values.F_NAN    
data.NN_O1[0:*]=-1   
data.ENN_O1[0:*]=!Values.F_NAN  
data.NL_O1[0:*]=-1   
data.NA1[0:*]=!Values.F_NAN     
data.UPPER_COMBINED_NA1[0:*]=-1
data.E_NA1[0:*]=!Values.F_NAN   
data.NN_NA1[0:*]=-1  
data.ENN_NA1[0:*]=!Values.F_NAN 
data.NL_NA1[0:*]=-1  
data.MG1[0:*]=!Values.F_NAN     
data.UPPER_COMBINED_MG1[0:*]=-1
data.E_MG1[0:*]=!Values.F_NAN   
data.NN_MG1[0:*]=-1  
data.ENN_MG1[0:*]=!Values.F_NAN 
data.NL_MG1[0:*]=-1  
data.AL1[0:*]=!Values.F_NAN     
data.UPPER_COMBINED_AL1[0:*]=-1
data.E_AL1[0:*]=!Values.F_NAN   
data.NN_AL1[0:*]=-1  
data.ENN_AL1[0:*]=!Values.F_NAN 
data.NL_AL1[0:*]=-1  
data.SI1[0:*]=!Values.F_NAN     
data.UPPER_COMBINED_SI1[0:*]=-1
data.E_SI1[0:*]=!Values.F_NAN   
data.NN_SI1[0:*]=-1  
data.ENN_SI1[0:*]=!Values.F_NAN 
data.NL_SI1[0:*]=-1  
data.SI2[0:*]=!Values.F_NAN     
data.UPPER_SI2[0:*]=-1
data.E_SI2[0:*]=!Values.F_NAN   
data.NN_SI2[0:*]=-1  
data.ENN_SI2[0:*]=!Values.F_NAN 
data.NL_SI2[0:*]=-1  
data.S1[0:*]=!Values.F_NAN      
data.UPPER_COMBINED_S1[0:*]=-1
data.E_S1[0:*]=!Values.F_NAN    
data.NN_S1[0:*]=-1   
data.ENN_S1[0:*]=!Values.F_NAN  
data.NL_S1[0:*]=-1   
data.CA1[0:*]=!Values.F_NAN     
data.UPPER_COMBINED_CA1[0:*]=-1
data.E_CA1[0:*]=!Values.F_NAN   
data.NN_CA1[0:*]=-1  
data.ENN_CA1[0:*]=!Values.F_NAN 
data.NL_CA1[0:*]=-1  
data.CA2[0:*]=!Values.F_NAN     
data.UPPER_CA2[0:*]=-1
data.E_CA2[0:*]=!Values.F_NAN   
data.NN_CA2[0:*]=-1  
data.ENN_CA2[0:*]=!Values.F_NAN 
data.NL_CA2[0:*]=-1  
data.SC1[0:*]=!Values.F_NAN     
data.UPPER_COMBINED_SC1[0:*]=-1
data.E_SC1[0:*]=!Values.F_NAN   
data.NN_SC1[0:*]=-1  
data.ENN_SC1[0:*]=!Values.F_NAN 
data.NL_SC1[0:*]=-1  
data.SC2[0:*]=!Values.F_NAN     
data.UPPER_SC2[0:*]=-1
data.E_SC2[0:*]=!Values.F_NAN   
data.NN_SC2[0:*]=-1  
data.ENN_SC2[0:*]=!Values.F_NAN 
data.NL_SC2[0:*]=-1  
data.TI1[0:*]=!Values.F_NAN     
data.UPPER_COMBINED_TI1[0:*]=-1
data.E_TI1[0:*]=!Values.F_NAN   
data.NN_TI1[0:*]=-1  
data.ENN_TI1[0:*]=!Values.F_NAN 
data.NL_TI1[0:*]=-1  
data.TI2[0:*]=!Values.F_NAN     
data.UPPER_TI2[0:*]=-1
data.E_TI2[0:*]=!Values.F_NAN   
data.NN_TI2[0:*]=-1  
data.ENN_TI2[0:*]=!Values.F_NAN 
data.NL_TI2[0:*]=-1  
data.V1[0:*]=!Values.F_NAN      
data.UPPER_COMBINED_V1[0:*]=-1
data.E_V1[0:*]=!Values.F_NAN    
data.NN_V1[0:*]=-1   
data.ENN_V1[0:*]=!Values.F_NAN  
data.NL_V1[0:*]=-1     
data.CR1[0:*]=!Values.F_NAN       
data.UPPER_COMBINED_CR1[0:*]=-1  
data.E_CR1[0:*]=!Values.F_NAN     
data.NN_CR1[0:*]=-1    
data.ENN_CR1[0:*]=!Values.F_NAN   
data.NL_CR1[0:*]=-1    
data.CR2[0:*]=!Values.F_NAN       
data.UPPER_CR2[0:*]=-1  
data.E_CR2[0:*]=!Values.F_NAN     
data.NN_CR2[0:*]=-1    
data.ENN_CR2[0:*]=!Values.F_NAN   
data.NL_CR2[0:*]=-1    
data.MN1[0:*]=!Values.F_NAN       
data.UPPER_COMBINED_MN1[0:*]=-1  
data.E_MN1[0:*]=!Values.F_NAN     
data.NN_MN1[0:*]=-1    
data.ENN_MN1[0:*]=!Values.F_NAN   
data.NL_MN1[0:*]=-1    
data.FE1[0:*]=!Values.F_NAN       
data.UPPER_COMBINED_FE1[0:*]=-1  
data.E_FE1[0:*]=!Values.F_NAN     
data.NN_FE1[0:*]=-1    
data.ENN_FE1[0:*]=!Values.F_NAN   
data.NL_FE1[0:*]=-1    
data.FE2[0:*]=!Values.F_NAN       
data.UPPER_FE2[0:*]=-1  
data.E_FE2[0:*]=!Values.F_NAN     
data.NN_FE2[0:*]=-1    
data.ENN_FE2[0:*]=!Values.F_NAN   
data.NL_FE2[0:*]=-1    
data.CO1[0:*]=!Values.F_NAN       
data.UPPER_COMBINED_CO1[0:*]=-1  
data.E_CO1[0:*]=!Values.F_NAN     
data.NN_CO1[0:*]=-1    
data.ENN_CO1[0:*]=!Values.F_NAN   
data.NL_CO1[0:*]=-1    
data.NI1[0:*]=!Values.F_NAN       
data.UPPER_COMBINED_NI1[0:*]=-1  
data.E_NI1[0:*]=!Values.F_NAN     
data.NN_NI1[0:*]=-1    
data.ENN_NI1[0:*]=!Values.F_NAN   
data.NL_NI1[0:*]=-1    
data.CU1[0:*]=!Values.F_NAN       
data.UPPER_COMBINED_CU1[0:*]=-1  
data.E_CU1[0:*]=!Values.F_NAN     
data.NN_CU1[0:*]=-1    
data.ENN_CU1[0:*]=!Values.F_NAN   
data.NL_CU1[0:*]=-1    
data.ZN1[0:*]=!Values.F_NAN       
data.UPPER_COMBINED_ZN1[0:*]=-1  
data.E_ZN1[0:*]=!Values.F_NAN     
data.NN_ZN1[0:*]=-1    
data.ENN_ZN1[0:*]=!Values.F_NAN   
data.NL_ZN1[0:*]=-1    
data.SR2[0:*]=!Values.F_NAN       
data.UPPER_SR2[0:*]=-1  
data.E_SR2[0:*]=!Values.F_NAN     
data.NN_SR2[0:*]=-1    
data.ENN_SR2[0:*]=!Values.F_NAN   
data.NL_SR2[0:*]=-1    
data.Y2[0:*]=!Values.F_NAN        
data.UPPER_Y2[0:*]=-1  
data.E_Y2[0:*]=!Values.F_NAN      
data.NN_Y2[0:*]=-1     
data.ENN_Y2[0:*]=!Values.F_NAN    
data.NL_Y2[0:*]=-1     
data.ZR1[0:*]=!Values.F_NAN       
data.UPPER_COMBINED_ZR1[0:*]=-1  
data.E_ZR1[0:*]=!Values.F_NAN     
data.NN_ZR1[0:*]=-1    
data.ENN_ZR1[0:*]=!Values.F_NAN   
data.NL_ZR1[0:*]=-1    
data.ZR2[0:*]=!Values.F_NAN       
data.UPPER_ZR2[0:*]=-1  
data.E_ZR2[0:*]=!Values.F_NAN     
data.NN_ZR2[0:*]=-1    
data.ENN_ZR2[0:*]=!Values.F_NAN   
data.NL_ZR2[0:*]=-1    
data.MO1[0:*]=!Values.F_NAN       
data.UPPER_COMBINED_MO1[0:*]=-1  
data.E_MO1[0:*]=!Values.F_NAN     
data.NN_MO1[0:*]=-1    
data.ENN_MO1[0:*]=!Values.F_NAN   
data.NL_MO1[0:*]=-1    
data.BA2[0:*]=!Values.F_NAN       
data.UPPER_BA2[0:*]=-1  
data.E_BA2[0:*]=!Values.F_NAN     
data.NN_BA2[0:*]=-1    
data.ENN_BA2[0:*]=!Values.F_NAN   
data.NL_BA2[0:*]=-1    
data.LA2[0:*]=!Values.F_NAN       
data.UPPER_LA2[0:*]=-1  
data.E_LA2[0:*]=!Values.F_NAN     
data.NN_LA2[0:*]=-1    
data.ENN_LA2[0:*]=!Values.F_NAN   
data.NL_LA2[0:*]=-1    
data.CE2[0:*]=!Values.F_NAN       
data.UPPER_CE2[0:*]=-1  
data.E_CE2[0:*]=!Values.F_NAN     
data.NN_CE2[0:*]=-1    
data.ENN_CE2[0:*]=!Values.F_NAN   
data.NL_CE2[0:*]=-1    
data.PR2[0:*]=!Values.F_NAN       
data.UPPER_PR2[0:*]=-1  
data.E_PR2[0:*]=!Values.F_NAN     
data.NN_PR2[0:*]=-1    
data.ENN_PR2[0:*]=!Values.F_NAN   
data.NL_PR2[0:*]=-1    
data.ND2[0:*]=!Values.F_NAN       
data.UPPER_ND2[0:*]=-1  
data.E_ND2[0:*]=!Values.F_NAN     
data.NN_ND2[0:*]=-1    
data.ENN_ND2[0:*]=!Values.F_NAN   
data.NL_ND2[0:*]=-1    
data.SM2[0:*]=!Values.F_NAN       
data.UPPER_SM2[0:*]=-1  
data.E_SM2[0:*]=!Values.F_NAN     
data.NN_SM2[0:*]=-1    
data.ENN_SM2[0:*]=!Values.F_NAN   
data.NL_SM2[0:*]=-1    
data.EU2[0:*]=!Values.F_NAN       
data.UPPER_EU2[0:*]=-1  
data.E_EU2[0:*]=!Values.F_NAN     
data.NN_EU2[0:*]=-1    
data.ENN_EU2[0:*]=!Values.F_NAN   
data.NL_EU2[0:*]=-1    
data.DY2[0:*]=!Values.F_NAN       
data.UPPER_DY2[0:*]=-1  
data.E_DY2[0:*]=!Values.F_NAN     
data.NN_DY2[0:*]=-1    
data.ENN_DY2[0:*]=!Values.F_NAN   
data.NL_DY2[0:*]=-1    
data.EW_TABLE[0:*]=!Values.F_NAN  
data.SNM[0:*]=!Values.F_NAN       
data.SNL[0:*]=!Values.F_NAN       
data.SNU[0:*]=!Values.F_NAN       
data.SPT[0:*]=!Values.F_NAN       
data.VEIL[0:*]=!Values.F_NAN      
data.LIM_EW_LI[0:*]=-1  
data.EW_LI[0:*]=!Values.F_NAN     
data.E_EW_WLI[0:*]=!Values.F_NAN  
data.EW_HA_ACC[0:*]=!Values.F_NAN  
data.E_EW_HA_ACC[0:*]=!Values.F_NAN  
data.HA10[0:*]=!Values.F_NAN      
data.E_HA10[0:*]=!Values.F_NAN    
data.EW_HA_CHR[0:*]=!Values.F_NAN  
data.E_EW_HA_CHR[0:*]=!Values.F_NAN  
data.EW_HB_CHR[0:*]=!Values.F_NAN  
data.E_EW_HB_CHR[0:*]=!Values.F_NAN  
data.TEFF_PHOT[0:*]=!Values.F_NAN  
data.E_TEFF_PHOT[0:*]=!Values.F_NAN  
data.LIM_LI_PHOT[0:*]=-1  
data.LI_PHOT[0:*]=!Values.F_NAN   
data.E_LI_PHOT[0:*]=!Values.F_NAN  
data.LIM_LI_SPEC[0:*]=-1  
data.LI_SPEC[0:*]=!Values.F_NAN   
data.E_LI_SPEC[0:*]=!Values.F_NAN  
data.LOG_MDOT_ACC[0:*]=!Values.F_NAN  
data.E_LOG_MDOT_ACC[0:*]=!Values.F_NAN  
data.LOG_L_ACC[0:*]=!Values.F_NAN  
data.E_LOG_L_ACC[0:*]=!Values.F_NAN  
data.AGE[0:*]=!Values.F_NAN       
data.E_AGE[0:*]=!Values.F_NAN     
data.MASS[0:*]=!Values.F_NAN      
data.E_MASS[0:*]=!Values.F_NAN    
data.CONVOL[0:*]=!Values.F_NAN    
data.E_CONVOL[0:*]=!Values.F_NAN  
return
end

;++++++++++++++++++++++++++++++++++++++++++++
; NAME:
;       SEARCH_SINGLE
; PURPOSE:
;       
; EXPLANATION:
;
;
; CALLING SEQUENCE:
;     
;
; INPUTS:
;       
;
; OUTPUTS:
;     
;
;
; RESTRICTIONS:
; 
;   
;
; EXAMPLE:
;; MODIFICATION HISTORY
; 
; created Patrick FRANCOIS February 2014
;-------------------------------------------------------------------------

pro    search_single, b,dr2_wg10,dr2_wg11,dr2_wg12,dr2_wg13,resWG=WG_1WG_1CNAME,nwg_1WG_1CNAME,WG=WG 

;
;     finding  index with only WG results  
;       
 
      iF (WG eq 'WG10' ) then begin
          WG_single = where(((dr2_wg10 ne -1) and (dr2_wg11 eq -1) and (dr2_wg12 eq -1) and (dr2_wg13 eq -1)), nwg_single) 
          dr2_wg = dr2_wg10 
      endif
      
       iF (WG eq 'WG11' ) then begin
          WG_single = where(((dr2_wg10 eq -1) and (dr2_wg11 ne -1) and (dr2_wg12 eq -1) and (dr2_wg13 eq -1)), nwg_single)
          dr2_wg = dr2_wg11  
      endif
       iF (WG EQ 'WG12' ) then begin
          WG_single = where(((dr2_wg10 eq -1) and (dr2_wg11 eq -1) and (dr2_wg12 ne -1) and (dr2_wg13 eq -1)), nwg_single) 
          dr2_wg = dr2_wg12 
      endif
       iF (WG EQ 'WG13' ) then begin
          WG_single = where(((dr2_wg10 eq -1) and (dr2_wg11 eq -1) and (dr2_wg12 eq -1) and (dr2_wg13 ne -1)), nwg_single) 
          dr2_wg = dr2_wg13 
      endif
      
; 
;     sorting multiple and single WG10 results 
;     flagging the multiples
;

     nmult = 0
     for i=0, nwg_single-1 do begin
        res = 0
        count = 0
        index = WG_single(i)
        indexwg=dr2_wg(index)
        if (indexwg ne -1 ) then begin
             res = where(dr2_wg eq indexwg, count)
             size_res= size(res, /N_elements)
             if (size_res ge 2 ) then begin
                nmult = nmult + 1
                for l=0, size_res - 1 do begin
;                   dr2_wg(res(0)) = 1
                   dr2_wg(res(l)) =-1
                endfor
             endif
        endif
     endfor


     iF (WG EQ 'WG10' ) then begin
         WG_1WG_1CNAME = where(((dr2_wg10 ne -1) and (dr2_wg11 eq -1) and (dr2_wg12 eq -1) and (dr2_wg13 eq -1)), nwg_1WG_1CNAME)  
      endif
      
       iF (WG EQ 'WG11' ) then begin
          WG_1WG_1CNAME = where(((dr2_wg10 eq -1) and (dr2_wg11 ne -1) and (dr2_wg12 eq -1) and (dr2_wg13 eq -1)), nwg_1WG_1CNAME)  
      endif
       iF (WG EQ 'WG12' ) then begin
          WG_1WG_1CNAME = where(((dr2_wg10 eq -1) and (dr2_wg11 eq -1) and (dr2_wg12 ne -1) and (dr2_wg13 eq -1)), nwg_1WG_1CNAME)  
      endif
       iF (WG EQ 'WG13' ) then begin
          WG_1WG_1CNAME = where(((dr2_wg10 eq -1) and (dr2_wg11 eq -1) and (dr2_wg12 eq -1) and (dr2_wg13 ne -1)), nwg_1WG_1CNAME) 
          print,  nwg_1WG_1CNAME
      endif

return
end 
;+
; NAME:
;       MATCH2
; PURPOSE:
;       Routine to cross-match values in two vectors (including non-matches)
; EXPLANATION:
;       This procedure *appears* similar to MATCH of the IDL astronomy
;       library.  However, this routine is quite different in that it
;       reports an index value for each element of the input arrays.
;       In other words, while MATCH reports the *existence* of
;       matching elements in each array, MATCH2 reports explicitly
;       *which* elements match.
;
;       Furthermore, while MATCH reports only unique matching
;       elements, MATCH2 will always report a cross-match for every
;       element in each array, even if it is a repeat.
;
;       In cases where no match was found, an index of -1 is
;       reported.  
;
; CALLING SEQUENCE:
;       match2, a, b, suba, subb
;
; INPUTS:
;       a,b - two vectors to match elements, numeric or string data types
;
; OUTPUTS:
;       suba - vector with same number of elements as A, such that
;              A EQ B[SUBA], except non-matches which are indicated
;              by SUBA EQ -1
;       subb - vector with same number of elements as B, such that
;              B EQ A[SUBB], except non-matches which are indicated
;              by SUBB EQ -1
;
;
; RESTRICTIONS:
; 
;       The vectors A and B are allowed to have duplicates in them,
;       but for matching purposes, only the first one found will
;       be reported.
;
; EXAMPLE:
;      A = [0,7,14,23,24,30]
;      B = [7,8,14,25,14]
;      IDL> match2, a, b, suba, subb
;     --> suba = [ -1 ,  0,  4,  -1, -1, -1 ]
;     (indicates that A[1] matches B[1] and A[3] matches B[2])
;     --> subb = [  1 , -1,  2,  -1,  2 ]
;     (indicates that B[1] matches A[1] and B[2] matches A[3])
;
;  Compare to the results of the original MATCH procedure,
;    
;      IDL> match, a, b, suba, subb
;     --> suba = [  1,  3]
;  (indicates that A[1] and A[3] match elements in B, but not which ones)
;     --> subb = [  1,  2]
;  (indicates that B[1] and B[2] match elements in A, but not which ones)
;
; MODIFICATION HISTORY
;   Derived from the IDL Astronomy Library MATCH, 14 Feb 2007
;   Updated documentation, 17 Jul 2007
;   More updated documentation (example), 03 Sep 2007
; 
;-
;-------------------------------------------------------------------------
pro match2, a, b, suba, subb

 On_error,2
 compile_opt idl2

 if N_params() LT 3 then begin
     print,'Syntax - match2, a, b, suba, subb'
     print,'    a,b -- input vectors for which to match elements'
     print,'    suba,subb -- match index lists'
     return
 endif

 da = size(a,/type) & db =size(b,/type)
 
 na = N_elements(a)              ;number of elements in a
 nb = N_elements(b)             ;number of elements in b
 suba = lonarr(na)-1 & subb = lonarr(nb)-1

; Check for a single element array

 if (na EQ 1) or (nb EQ 1) then begin
        if (nb GT 1) then begin
            wh = where(b EQ a[0], nw)
            if nw GT 0 then begin
                subb[wh] = 0L
                suba[0]  = wh[0]
            endif
        endif else begin
            wh = where(a EQ b[0], nw)
            if nw GT 0 then begin
                suba[wh] = 0L
                subb[0]  = wh[0]
            endif
        endelse
        return
 endif
        
 c = [ a, b ]                   ;combined list of a and b
 ind = [ lindgen(na), lindgen(nb) ]       ;combined list of indices
 vec = [ intarr(na), replicate(1,nb) ]  ;flag of which vector in  combined 
                                         ;list   0 - a   1 - b

; sort combined list

 if da EQ 7 OR db EQ 7 then begin
     ;; String sort (w/ double key)
     sub = sort(c+strtrim(vec,2))
 endif else begin
     ;; Number sort (w/ double key)
     eps = (machar(/double)).eps
     sub = sort(double(c)*(1d + vec*eps))
 endelse

 c = c[sub]
 ind = ind[sub]
 vec = vec[sub]
 
 n = na + nb                    ;total elements in c
 wh = where( c[1:*] NE c, ct)
 if ct EQ 0 then begin
     whfirst = [0]
     whlast  = [n-1]
 endif else begin
     whfirst = [0, wh+1]
     whlast  = [wh, n-1]
 endelse
 
 vec0 = vec[whfirst]
 vec1 = vec[whlast]
 ;; 0 = present in A but not B
 ;; 1 = can't occur (since the array was sorted on 'VEC')
 ;; 2 = present in both
 ;; 3 = present in B but not A
 matchtype = vec0 + vec1*2

 nm = n_elements(matchtype)
 mm = ind*0L & wa = mm & wb = mm
 for i = 0, nm-1 do begin
     mm[whfirst[i]:whlast[i]] = matchtype[i]
     wa[whfirst[i]:whlast[i]] = ind[whfirst[i]]
     wb[whfirst[i]:whlast[i]] = ind[whlast[i]]
 endfor

 suba = lonarr(na)-1 & subb = lonarr(nb)-1

 wh = where(mm EQ 2 AND vec EQ 0, ct)
 if ct GT 0 then suba[ind[wh]] = wb[wh]
 wh = where(mm EQ 2 AND vec EQ 1, ct)
 if ct GT 0 then subb[ind[wh]] = wa[wh]

 return
end

; docformat = 'rst' 
;+ 
; Returns the complement of an index array. 
; 
; :Examples: 
; For example, try:: 
; 
; IDL> print, mg_complement([0, 9, 3, 6, 7], 10) ; 1 2 4 5 8 
;
; :Returns: ; `lonarr` or `-1L` if complement is empty 
; 
; :Params: 
; indices : in, required, type=lonarr 
; indices to complement 
; n : in, required, type=integer type 
; number of elements in full array 
; 
; :Keywords: 
; count : out, optional, type=long 
; set to a named variable to return the number of elements in the 
; complement 
;- 
function mg_complement, indices, n, count=ncomplement
 compile_opt strictarr 
 all = bytarr(n) 
 if (indices[0] ne -1L) then all[indices] = 1B
  return, where(all eq 0B, ncomplement) 
  end 
;+
; NAME:
; COPY_STRUCT
; PURPOSE:
;   Copy all fields with matching tag names from one structure to another
; EXPLANATION:
;       COPY_STRUCT is similar to the intrinsic STRUCT_ASSIGN procedure but 
;       has optional keywords to exclude or specify specific tags.
;  
; Fields with matching tag names are copied from one structure array to 
; another structure array of different type.
; This allows copying of tag values when equating the structures of
; different types is not allowed, or when not all tags are to be copied.
; Can also recursively copy from/to structures nested within structures.
; Note that the number of elements in the output structure array
; is automatically adjusted to equal the length of input structure array.
; If this not desired then use pro copy_struct_inx which allows
; specifying via subscripts which elements are copied where in the arrays.
;
; CALLING SEQUENCE:
;
; copy_struct, struct_From, struct_To, NT_copied
; copy_struct, struct_From, struct_To, EXCEPT=["image","misc"]
; copy_struct, struct_From, struct_To, /RECUR_TANDEM
;
; INPUTS:
; struct_From = structure array to copy from.
; struct_To = structure array to copy values to.
;
; KEYWORDS:
;
; EXCEPT_TAGS = string array of tag names to ignore (to NOT copy).
;   Used at all levels of recursion.
;
; SELECT_TAGS = tag names to copy (takes priority over EXCEPT).
;   This keyword is not passed to recursive calls in order
;   to avoid the confusion of not copying tags in sub-structures.
;
; /RECUR_FROM = search for sub-structures in struct_From, and then
;   call copy_struct recursively for those nested structures.
;
; /RECUR_TO = search for sub-structures of struct_To, and then
;   call copy_struct recursively for those nested structures.
;
; /RECUR_TANDEM = call copy_struct recursively for the sub-structures
;   with matching Tag names in struct_From and struct_To
;   (for use when Tag names match but sub-structure types differ).
;
; OUTPUTS:
; struct_To = structure array to which new tag values are copied.
; NT_copied = incremented by total # of tags copied (optional)
;
; INTERNAL:
; Recur_Level = # of times copy_struct calls itself.
;   This argument is for internal recursive execution only.
;   The user call is 1, subsequent recursive calls increment it,
;   and the counter is decremented before returning.
;   The counter is used just to find out if argument checking
;   should be performed, and to set NT_copied = 0 first call.
; EXTERNAL CALLS:
; pro match (when keyword SELECT_TAGS is specified)
; PROCEDURE:
; Match Tag names and then use corresponding Tag numbers.
; HISTORY:
; written 1989 Frank Varosi STX @ NASA/GSFC
;   mod Jul.90 by F.V. added option to copy sub-structures RECURSIVELY.
; mod Aug.90 by F.V. adjust # elements in TO (output) to equal
;     # elements in FROM (input) & count # of fields copied.
; mod Jan.91 by F.V. added Recur_Level as internal argument so that
;     argument checking done just once, to avoid confusion.
;     Checked against Except_Tags in RECUR_FROM option.
; mod Oct.91 by F.V. added option SELECT_TAGS= selected field names.
; mod Aug.95 by W. Landsman to fix match of a single selected tag.
; mod Mar.97 by F.V. do not pass the SELECT_TAGS keyword in recursion.
; Converted to IDL V5.0   W. Landsman   September 1997
;       mod May 01 by D. Schlegel use long integers
;-

pro copy_struct, struct_From, struct_To, NT_copied, Recur_Level,            $
            EXCEPT_TAGS  = except_Tags, $
            SELECT_TAGS  = select_Tags, $
            RECUR_From   = recur_From,  $
            RECUR_TO     = recur_To,    $
            RECUR_TANDEM = recur_tandem

  if N_elements( Recur_Level ) NE 1 then Recur_Level = 0L

  Ntag_from = N_tags( struct_From )
  Ntag_to = N_tags( struct_To )

  if (Recur_Level EQ 0) then begin  ;check only at first user call.

    NT_copied = 0L

    if (Ntag_from LE 0) OR (Ntag_to LE 0) then begin
      message,"two arguments must be structures",/INFO
      print," "
      print,"syntax:    copy_struct, struct_From, struct_To"
      print," "
      print,"keywords:  EXCEPT_TAGS= , SELECT_TAGS=,  "
      print,"   /RECUR_From,  /RECUR_TO,  /RECUR_TANDEM"
      return
       endif

    N_from = N_elements( struct_From )
    N_to = N_elements( struct_To )

    if (N_from GT N_to) then begin

      message," # elements (" + strtrim( N_to, 2 ) + $
          ") in output TO structure",/INFO
      message," increased to (" + strtrim( N_from, 2 ) + $
          ") as in FROM structure",/INFO
      struct_To = [ struct_To, $
          replicate( struct_To[0], N_from-N_to ) ]

      endif else if (N_from LT N_to) then begin

      message," # elements (" + strtrim( N_to, 2 ) + $
          ") in output TO structure",/INFO
      message," decreased to (" + strtrim( N_from, 2 ) + $
          ") as in FROM structure",/INFO
      struct_To = struct_To[0:N_from-1]
       endif
     endif

  Recur_Level = Recur_Level + 1   ;go for it...

  Tags_from = Tag_names( struct_From )
  Tags_to = Tag_names( struct_To )
  wto = lindgen( Ntag_to )

;Determine which Tags are selected or excluded from copying:

  Nseltag = N_elements( select_Tags )
  Nextag = N_elements( except_Tags )

  if (Nseltag GT 0) then begin

    match, Tags_to, [strupcase( select_Tags )], mt, ms,COUNT=Ntag_to

    if (Ntag_to LE 0) then begin
      message," selected tags not found",/INFO
      return
       endif

    Tags_to = Tags_to[mt]
    wto = wto[mt]

    endif else if (Nextag GT 0) then begin

    except_Tags = [strupcase( except_Tags )]

    for t=0L,Nextag-1 do begin
      w = where( Tags_to NE except_Tags[t], Ntag_to )
      Tags_to = Tags_to[w]
      wto = wto[w]
      endfor
     endif

;Now find the matching Tags and copy them...

  for t = 0L, Ntag_to-1 do begin

    wf = where( Tags_from EQ Tags_to[t] , nf )

    if (nf GT 0) then begin

      from = wf[0]
      to = wto[t]

      if keyword_set( recur_tandem ) AND    $
         ( N_tags( struct_To.(to) ) GT 0 ) AND  $
         ( N_tags( struct_From.(from) ) GT 0 ) then begin

        struct_tmp = struct_To.(to)

        copy_struct, struct_From.(from), struct_tmp,  $
            NT_copied, Recur_Level,       $
            EXCEPT=except_Tags,           $
            /RECUR_TANDEM,                $
            RECUR_FROM = recur_From,      $
            RECUR_TO   = recur_To

        struct_To.(to) = struct_tmp

        endif else begin

        struct_To.(to) = struct_From.(from)
        NT_copied = NT_copied + 1
         endelse
      endif
    endfor

;Handle request for recursion on FROM structure:

  if keyword_set( recur_From ) then begin

    wfrom = lindgen( Ntag_from )

    if (Nextag GT 0) then begin

      for t=0L,Nextag-1 do begin
          w = where( Tags_from NE except_Tags[t], Ntag_from )
          Tags_from = Tags_from[w]
          wfrom = wfrom[w]
        endfor
       endif

    for t = 0L, Ntag_from-1 do begin

         from = wfrom[t]

         if N_tags( struct_From.(from) ) GT 0 then begin

      copy_struct, struct_From.(from), struct_To,        $
            NT_copied, Recur_Level,    $
            EXCEPT=except_Tags,        $
            /RECUR_FROM,               $
            RECUR_TO     = recur_To,   $
            RECUR_TANDEM = recur_tandem
      endif
      endfor
    endif

;Handle request for recursion on TO structure:

  if keyword_set( recur_To ) then begin

    for t = 0L, Ntag_to-1 do begin

       to = wto[t]

       if N_tags( struct_To.(to) ) GT 0 then begin

      struct_tmp = struct_To.(to)

      copy_struct, struct_From, struct_tmp,              $
            NT_copied, Recur_Level,    $
            EXCEPT=except_Tags,        $
            /RECUR_TO,                 $
            RECUR_FROM = recur_From,   $
            RECUR_TANDEM = recur_tandem
      struct_To.(to) = struct_tmp
         endif
      endfor
    endif

  Recur_Level = Recur_Level - 1
end  
      
function create_template,nfiles,addtemp

;C.C.Worley 25/02/2014
;Creates Additiona Results Strucutre for WG12
es='                '
;Creates template with single row
addtemp = {  $                                            ;IDL Index   Form  Def
              CNAME  :  string(es,format='(16a)'), $       ; 0      16A   GES object name from coordinates 
             TARGET  :  string(es,format='(30a)'), $       ; 1      30A  GES field name 
             OBJECT  :  string(es,format='(16a)'), $       ; 2      16A  GES object name from OB 
           FILENAME  :  string(es,format='(150a)'),$       ; 3      150A Files used for the homogenised results. 
      AVAILABLE_PAR  :  string(es,format='(16a)'),$       ;  4      16A  WG Provenance of Parameters,16a,data format of field: ASCII Character,None,None,-9999,None  
         FEH_Offset  :  1E, $                              ;  ,Offset of FEH,1E,data format of field: 4-byte REAL,dex,physical unit of field,-9999,None
   FEH_OffsetSource  :  string(es,format='(16a)'),$       ;,Source of FEH Offset,16a,data format of field: ASCII Character,None,None,-9999,None 
          Prov_VRAD  :  string(es,format='(16a)'),$       ;,WG Provenance of VRAD,16a,data format of field: ASCII Character,None,None,-9999,None 
         VRAD_Offset :  1E, $ ;,Offset of VRAD,1E,data format of field: 4-byte REAL,km/s,physical unit of field,-9999,None
  VRAD_OffsetSource  :  string(es,format='(16a)'),$       ;,Source of VRAD Offset,16a,data format of field: ASCII Character,None,None,-9999,None 
         Prov_VSINI  :  string(es,format='(16a)'),$       ;,WG Provenance of VSINI,16a,data format of field: ASCII Character,None,None,-9999,None 
          Prov_ABUN  :  string(es,format='(16a)'),$       ;,WG Provenance of ABUNDANCE,16a,data format of field: ASCII Character,None,None,-9999,None
           GES_TYPE  :  string(es,format='(16a)')}       ;,GES Target Classification,16a,data format of field: ASCII Character,None,None,-9999,None 

;Note: the number of character elemeters (ie 16a) gets changed when it is filled. This shows up in the final header.

;Adds more rows
addtemp=replicate(addtemp,nfiles)

;Convert 0.0 Default Values to 'NaN' for float and -1 for integer (GES standards for NULL values)
;(The only way I could figure to do this and still have the data type correct)
strindices = [0,1,2,3,4,6,7,9,10,11,12]   ;IDL index of the string columns
;intindices = []   ;IDL index of the integer columns
fltindices = [54,5,8]   ;IDL index of the floating columns

nfields = 13   ;needs to match number of fields in list in addtemp above
for i =0,nfields-1 do begin
  ;print,nanind(i)
  
  ;iint = where(i eq intindices)
  iflt = where(i eq fltindices)
  ;if iint(0) ne -1 then begin
  ; addtemp.(i) = -1
  ;endif else 
  if iflt(0) ne -1 then begin
    addtemp.(i) = 'NaN'
  endif
endfor

;---------------------------
;Check
;print,addtemp.LIM_VSINI

;Appends extension
;mwrfits,gestemp,'test.fits',hbint

;Looks at composition of the new fits file
;fits_help,'test.fits'

;Extracts header of the binary table of fits file
;bininfo2=mrdfits('test.fits',1,hbint2)

;Looks at structure of binary table
;tbhelp,hbint2

;Prints header of binary table
;print,hbint2
;----------------------------

;save

return,addtemp

END
      
pro add_WG15_extension,  templatefile, fitsfilename

;========================================================
;FFFT Binary TABLE

;Read in template to use in Binary Table Extensions


gestemp = mrdfits(templatefile,1,htemp)

;To see structure
help,gestemp

;To see header
;print,htemp

;To expand structure to necessary number of rows
;Ncnames = N_elements(CNAME)  ;
Ncnames= size(gestemp, /N_elements)
print, 'Ncnames ', Ncnames
;gestemp=replicate(gestemp,Ncnames)


;Inserting an Additional Results Extension
addtemp = create_template(Ncnames)   ;See routine for creating the structure. Adjust as necessary
addtemp.CNAME = gestemp.CNAME
addtemp.target = gestemp.TARGET

;...etc

;Make Header for Additional results Extension
;FXBHMAKE, HEADER, Nrows, EXTNAME , Comment on EXTNAME
FXBHMAKE, addheader, Ncnames, 'WG15_ADD' , 'Additional Results for WG15'
;print,addheader

;Read in File (csv) with all information about the Columns for TTYPE,TFORM,TUNIT,TNULL 
;(An example, but can replace with the correct units and definitions)
      path2= '/Users/fpatrick/Desktop/Dropbox_OBSPM/WG15_Products/' 
extracol_file = path2 + 'wg15_extracols_information.txt'
readcol,extracol_file,Column,ColumnComment,Form,FormComment,Units,UnitsComment,Null,NullComment,DELIMITER=',',format='(a,a,a,a,a,a,i,a)',skipline=1

;Add this information to Additional Results Extension Header
for i=0,N_elements(Column)-1 do begin
  FXADDPAR, addheader, 'TTYPE'+strtrim(string(i+1),2),Column(i),ColumnComment(i)
  FXADDPAR, addheader, 'TFORM'+strtrim(string(i+1),2),Form(i),FormComment(i)
  if Units(i) ne 'None' then begin  ;Don't need to add TUNIT for string columns
    FXADDPAR, addheader, 'TUNIT'+strtrim(string(i+1),2),Units(i),UnitsComment(i)
  endif

  ;if Null(i) eq -1 then begin     ;Only add TNULL for integer columns
  ; FXADDPAR, addheader, 'TNULL'+strtrim(string(i+1),2),Null(i),NullComment(i)+' '+strtrim(string(i+1),2)
  ;endif
endfor


;Otherwise can add one by one - Fits reader (fv) doesn't necessarily see them
;FXADDPAR, addheader, 'TUNITS5','mAngstroms','Physical units',AFTER='TUNITS5'
;FXADDPAR, addheader, 'TUNITS6','mAngstroms','Physical units',AFTER='TUNITS5'
;FXADDPAR, addheader, 'TUNITS7','Flux','Physical units',AFTER='TUNITS6'
;FXADDPAR, addheader, 'TUNITS8','Flux','Physical units',AFTER='TUNITS7'
;FXADDPAR, addheader, 'TUNITS9','Flux','Physical units',AFTER='TUNITS8'
;FXADDPAR, addheader, 'TUNITS10','Flux','Physical units',AFTER='TUNITS9'
;FXADDPAR, addheader, 'TUNITS11','Flux','Physical units',AFTER='TUNITS10'
;FXADDPAR, addheader, 'TUNITS12','Flux','Physical units',AFTER='TUNITS11'
;FXADDPAR, addheader, 'TUNITS13','Flux','Physical units',AFTER='TUNITS12'
;FXADDPAR, addheader, 'TUNITS14','Flux','Physical units',AFTER='TUNITS13'

;Add additional results binary table and header to FITS file.



mwrfits,addtemp,fitsfilename,addheader,/No_comment

;htemp is original header for binary table
;/No_comment stops any extraneous comments in header

;This can be repeat for multiple binary tables (as for Node files).
;Every additional table saved to the FITs file is placed in the next extension

end
      