function [] = batch_unified_full(override_params_file)
    addpath('algorithm');
    addpath('scan_params_in_algorithm')
    warning('off', 'MATLAB:rankDeficientMatrix')

    load_table
    load_params

    % preprocess data
    M_dates = base_date;
   
    generate_train_val_test_ranges  
    % generate train, val, test
    generate_train_val_test
    % run algorithms and get results
    unified_run

    % summarize inputs
    if print_params
        fprintf('Parameters:\n')
        fprintf('  Data:\n')
        disp(data_params)
        fprintf('  Program:\n')
        disp(prog_params)
        fprintf('  Feature:\n')
        disp(feat_params)
        fprintf('  Response:\n')
        disp(resp_params)
        fprintf('  Filter:\n')
        disp(filt_params)
        fprintf('  Algorithm:\n')
        disp(alg_params)
        fprintf('  Time range:\n')
        disp(range_params)
    end


    if save_signals
        merge_csv(csv_dir, 'signals', 'all_signals.csv');
    end

    % summarize results
    fprintf('Performance:\n')
    disp(T);

    if save_results
        save(fullfile('tmp_results', results_fname), 'T', 'data_params', 'prog_params',...
            'feat_params', 'resp_params', 'filt_params', 'alg_params', 'range_params','svd1_all','svd2_all');
    end

    rmdir(mat_dir,'s')
end