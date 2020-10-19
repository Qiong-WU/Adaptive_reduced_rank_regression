function Y = look_back(X, lag)
    Y = NaN(size(X));
    if lag >= 0
        Y(:, lag+1:end) = X(:, 1:end-lag);
    else
        lag = -lag;
        Y(:, 1:end-lag) = X(:, lag+1:end);
    end
end
 