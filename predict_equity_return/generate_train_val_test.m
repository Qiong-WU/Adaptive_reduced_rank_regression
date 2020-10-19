% features, from test to get training set 
X = [];
if use_ret2h, X = [X; M_ret2h]; end
if use_aret2h, X = [X; M_aret2h]; end
if use_ret1d, X = [X; M_ret1d]; end
if use_aret1d, X = [X; M_aret1d]; end
if use_ret5d, X = [X; M_ret5d]; end
if use_aret5d, X = [X; M_aret5d]; end
if use_ret10d, X = [X; M_ret10d]; end
if use_aret10d, X = [X; M_aret10d]; end
if use_dv, X = [X; M_dv]; end


if movavg_features
    X = movavg(X', 'exponential', 5)';
end

% responses
if choose_fret1d
    Y = M_fret1d;
elseif choose_faret1d
    Y = M_faret1d;
elseif choose_fret2d
    Y = M_fret2d;
elseif choose_faret2d
    Y = M_faret2d;
elseif choose_fret3d
    Y = M_fret3d;
elseif choose_faret3d
    Y = M_faret3d;
elseif choose_fret5d
    Y = M_fret5d;
elseif choose_faret5d
    Y = M_faret5d;
end


% the weight is the sqrt of dollor volumn
W = sqrt(M_dv);
mul = floor(size(X, 1) / size(Y, 1));

W_corr = look_back(W, -1);

p1yr_window = 252;
M_dv1y = movsum(M_dv, [p1yr_window - 1, 0], 2);
M_dv1y = sqrt(M_dv1y);


M_all = {};
predY_test_all = {};
stock_mask_all = {};
Xtrain_all = {};
Ytrain_all = {};
Xtest_all = {};
Ytest_all = {};

precentage = 1;

for i = 1:length(testStartDates)    
    trainIdx = M_dates < trainEndDates(i) & M_dates >= trainStartDates(i);
    testIdx = M_dates < testEndDates(i) & M_dates >= testStartDates(i);
    valIdx = M_dates < valEndDates(i) & M_dates >= valStartDates(i);
    
    
    firstTrain = find(trainIdx, 1, 'first');
    lastTrain = find(trainIdx, 1, 'last');
   
    firstTest = find(testIdx, 1, 'first');
    univ_idx = find(M_dates(firstTest) >= univ_yyyymm*100, 1, 'last');
         
    if keep_csi == 800
        univ_csi = univ_csi800;
    elseif keep_csi == 300
        univ_csi = univ_csi300;
    elseif keep_csi == 500
        univ_csi = univ_csi500;
    else % full universe
        univ_csi = univ_csi_all;
    end
    
    if sector ~= 0
        [keepIdIdx, ~] = ismember(base_equity, intersect(univ_csi{univ_idx},univ_csi_sector{sector}));
    else
        [keepIdIdx, ~] = ismember(base_equity, univ_csi{univ_idx});
    end
    
    
    if set_percentage
        precentage = 0.2;
        vector = 1:sum(keepIdIdx);
        M_keep_dv = M_dv(keepIdIdx, trainIdx);
        num_stocks = floor(sum(keepIdIdx)* precentage);
        M_sum_dv = sum(M_keep_dv,2);
        [~,top_index]= sort(M_sum_dv,'descend');
        top_stocks_index = top_index(1:num_stocks);
        keepIdIdx = ismember(vector,top_stocks_index); 
    end
   
    Ytmp = Y(keepIdIdx,:);   
    
    if demean_signal_y
    Ytmp = bsxfun(@minus, Ytmp,mean(Ytmp,1));
    Ytmp = bsxfun(@rdivide,Ytmp,std(Ytmp,1));
    end

    
    M_stockId_keepIdx = find(keepIdIdx);
    keepIdIdx_mul = repmat(keepIdIdx, mul, 1);
    
    if normal_signal_y
    [~,rank_idx] = sort(Ytmp,1);
    rank_idx = rank_idx./(size(Ytmp,1)+1);
    Ytmp = norminv(rank_idx);  
    end
    
    Xtmp = X(keepIdIdx_mul,:);    
    Xtrain = Xtmp(:, trainIdx);% select row and column
    ytrain = Ytmp(:, trainIdx);
    ytrain = winsorize(ytrain, 0.05);
    wtrain = W(keepIdIdx, trainIdx);
    cwtrain = W_corr(keepIdIdx, trainIdx);

    Xtest = Xtmp(:, testIdx);
    ytest = Ytmp(:, testIdx);
    wtest = W(keepIdIdx, testIdx);
    cwtest = W_corr(keepIdIdx, testIdx);
   
        
    Xval = Xtmp(:, valIdx);
    yval = Ytmp(:, valIdx);
    wval = W(keepIdIdx, valIdx);
    cwval = W_corr(keepIdIdx, valIdx);
    
    
    if zscore_features
        [Xtrain, zs_mu, zs_sigma] = zscore(Xtrain, 0, 2);
        zs_mask_skip = (zs_sigma == 0);
        Xtest = bsxfun(@times, Xtest, 1./zs_sigma);
        Xtest(zs_mask_skip, :) = 0;
        sigma_cap = 3;
        Xtrain(Xtrain > sigma_cap) = sigma_cap;
        Xtrain(Xtrain < -sigma_cap) = -sigma_cap;
        Xtest(Xtest > sigma_cap) = sigma_cap;
        Xtest(Xtest < -sigma_cap) = -sigma_cap;
    end

    if save_xy
        mat_xy_fname = strcat('xy_',testDates{i}, '.mat');
        save(fullfile(mat_dir, mat_xy_fname),...
            'Xtrain', 'ytrain', 'Xtest', 'ytest', 'wtrain', 'wtest','cwtrain', ...
            'cwtest','M_stockId_keepIdx','keepIdIdx','keepIdIdx_mul','Xval','yval','wval','cwval','-v7.3');
    end
    
end
