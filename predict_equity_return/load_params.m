% DATA PARAMETERS***************************************************************
% these depend on the upstream mat files and are not tunable
% M_residual = M_faret1d with daily open returns

data_params.pts_per_day = 1;
% DATA PARAMS END***************************************************************

% PROGRAM PARAMETERS************************************************************
prog_params.verbose = 1;
prog_params.print_params = 1;
prog_params.save_signals = 0;
prog_params.save_xy = 1;
prog_params.save_results = 1;
prog_params.find_optimal_params = 1;
prog_params.simulator = 0;
prog_params.val_type = 0;
nowstr = datestr(now, 'yyyymmdd_HHMMSS');

if prog_params.save_signals
    csv_dir = fullfile('qiong_temp/tmp_csv', nowstr);
    ifnotexist_create(csv_dir);
    prog_params.csv_dir = csv_dir;
end
% PROGRAM PARAMS END***********************************************************

% TIME RANGE PARAMETERS********************************************************
range_params.first_train_date = 20110501;
range_params.first_test_date = 20150701;
%range_params.last_val_date = 20150601;
range_params.last_test_date = 20181101;
range_params.train_years = 3;
range_params.train_months = 0;
range_params.gray_years = 0;
range_params.gray_months = 1;
range_params.test_years = 0;
range_params.test_months = 12;
% TIME RANGE PARAMS END********************************************************

% FEATURE PARAMETERS***********************************************************
feat_params.use_ret2h = 0;
feat_params.use_ret1d = 0;
feat_params.use_ret5d = 0;
feat_params.use_ret10d = 0;
feat_params.use_aret2h = 0;
feat_params.use_aret1d = 1;
feat_params.use_aret5d = 1;
feat_params.use_aret10d = 1;
feat_params.use_dv = 0;
% FEATURE PARAMS END***********************************************************


% RESPONSE PARAMETERS**********************************************************
resp_params.eval_adj = 1;
resp_params.eval_5d = 0;
resp_params.choose_fret1d = 0;
resp_params.choose_faret1d = 1;
resp_params.choose_fret2d = 0;
resp_params.choose_faret2d = 0;
resp_params.choose_fret3d = 0;
resp_params.choose_faret3d = 0;
resp_params.choose_fret5d = 0;
resp_params.choose_faret5d = 0;
% RESPONSE PARAMS END**********************************************************


% FILTER PARAMETERS************************************************************
filt_params.keep_csi = 800;
filt_params.keep_top_dv1y = 0;
filt_params.keep_tstat = 0;
filt_params.movavg_features = 0;
filt_params.zscore_features = 0;
filt_params.normal_signal_y = 0;
filt_params.demean_signal_y = 0;
filt_params.set_percentage = 0;
filt_params.sector = 0; %32 sectors in total 

% FILTER PARAMS END************************************************************


% ALGORITHM PARAMETERS*********************************************************
alg_params.mode = 2;
alg_params.wp = 0.01;
alg_params.wpl_dv = 0.005;
alg_params.keep_svd1 = 20;
alg_params.keep_svd2 = 2;
alg_params.num_parts = 2;
alg_params.ridge_lambda = 9.6;



%2e5;
% ALGORITHM PARAMS END*********************************************************

% for automated parameter sweeping
eval(override_params_file)
disp(alg_params.mode)

if prog_params.save_results
    prog_params.results_fname = strcat('mode',num2str(alg_params.mode),'csi',num2str(filt_params.keep_csi),'train',num2str(range_params.train_years),'test',num2str(range_params.test_months)...
    ,'sec',num2str(filt_params.sector),'top20',num2str(filt_params.set_percentage));
end

if prog_params.save_xy
    mat_dir = fullfile('temp/tmp_mat', strcat(nowstr,prog_params.results_fname));
    ifnotexist_create(mat_dir);
    prog_params.mat_dir = mat_dir;
end


% unpack params from structs
tmp_file = strcat(prog_params.results_fname,'temp.mat');
save(tmp_file, '-struct', 'data_params')
load(tmp_file)
save(tmp_file, '-struct', 'prog_params')
load(tmp_file)
save(tmp_file, '-struct', 'range_params')
load(tmp_file)
save(tmp_file, '-struct', 'feat_params')
load(tmp_file)
save(tmp_file, '-struct', 'resp_params')
load(tmp_file)
save(tmp_file, '-struct', 'filt_params')
load(tmp_file)
save(tmp_file, '-struct', 'alg_params')
load(tmp_file)
delete (tmp_file)
