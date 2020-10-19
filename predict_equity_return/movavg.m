function varargout = movavg(varargin)
%MOVAVG Moving average of time series
%
% Syntax:
%
%   ma = MOVAVG(Data,type,windowSize)
%   ma = MOVAVG(Data,type,windowSize,Endpoints)
%   ma = MOVAVG(Data,'custom',weights)
%   ma = MOVAVG(Data,'custom',weights,Endpoints)
%
% Description:
%
%   MOVAVG computes the moving average (MA) of a financial time series.
%
% Input Arguments:
%
%   Data         - A column-oriented matrix, table, or timetable. Timetables
%                  and tables must contain variables only with numeric type.
%
%   type         - String or character vector indicating the particular type
%                  of moving average to compute. Valid choices are 'simple',
%                  'square-root', 'linear', 'square', 'exponential', 
%                  'triangular', 'modified', and 'custom'.
%
%   windowSize   - Scalar, positive integer number of observations of the 
%                  input series to include in the moving average. The 
%                  observations include (windowSize - 1) previous data points
%                  and current data point. This applies only to moving 
%                  averages whose 'type' (see above) is 'simple', 'square-root',
%                  'linear', 'square', 'exponential', 'triangular', or 'modified'.
%
%   weights      - Vector of custom weights used to compute the moving average.
%                  The length of weights (N) determines the size of the moving
%                  average window. This applies only to 'custom' moving average
%                  type (see above). 
%
%                  To compute moving average with custom weights, the weights (w)
%                  are first normalized such that they sum to one:
%
%                  W(i) = w(i)/sum(w), for i = 1,2,...,N
%
%                  The normalized weights (W) are then used to form the N-point 
%                  weighted moving average (y) of the input Data (x):
%
%                  y(t)  = W(1)*x(t) + W(2)*x(t-1) + ... + W(N)*x(t-N)
%
%                  The initial moving average values within the window size
%                  are then adjusted according the method specified in 'Endpoints'.
%
%                   
%
% Optional Input:
%
%  Initialpoints - String or character vector indicating how the moving average
%                  is calculated at the initial points, before there is enough
%                  data to fill the window. This option applies to above types
%                  except 'exponential' and 'modified'. Valid choices are 
%                  'shrink', 'fill', and 'zero'. 'shrink' initializes the 
%                  moving average such that the initial points include only
%                  observed data. 'zero' initializes the initial points with
%                  0. 'fill' fills initial points with NaNs. The default is
%                  'shrink'.
%
% Output Argument:
%
%   ma           - Moving average series with the same number of rows (M)
%                  and type as the input data.
%
%   Reference: Achelis, Steven B., Technical Analysis From A To Z,
%              Second Printing, McGraw-Hill, 1995, pg. 184-192

%   Copyright 1995-2018 The MathWorks, Inc.


%--------------------------- Parsing/Validation --------------------------%
if (nargin >= 3) && (isnumeric(varargin{2}))
    warning(message('finance:internal:finance:ftseriesInputParser:SyntaxDeprecation'))
    [long, short] = movavg_old(nargin,nargout,varargin{:});
    if (nargout>0)
        varargout = {long,short};
    end
    return;
end

p = inputParser;
addRequired(p,'Data',@(x) validateattributes(x,{'numeric','table','timetable'},{'nonempty'}));
addRequired(p,'Type',@(x) validateattributes(x,{'string','char'},{'scalartext'}));
addRequired(p,'windowSize',@(x) validateattributes(x,{'numeric'},{'nonempty'}));
addOptional(p,'Endpoints',"shrink",@(x) validateattributes(x,{'string','char'},{'scalartext'}));

parse(p,varargin{:});

% Data Extraction
rawData = p.Results.Data;
datatypeFlag = 0;   % matrix type by default

if istable(rawData)
    data = rawData.Variables;
    datatypeFlag = 1;
elseif istimetable(rawData)
    dates = rawData.Properties.RowTimes;
    % Only handle datetime as time index case. No pre-clean step for
    % duration/calendarduration case.
    if isdatetime(dates)
        nonMissingDates = rmmissing(dates);
        uniqueDates = unique(nonMissingDates);
        if (length(uniqueDates) < length(dates)) || ~(isequal(uniqueDates,dates))
            warning(message('finance:movavg:PreCleaned'))
            rawData = retime(rawData,uniqueDates);
            dates = uniqueDates;
        end
    end
    data = rawData.Variables;
    datatypeFlag = 2;
else
    data = rawData;
end

% type validation
validTypeStrings = ["simple", "square-root","linear","square","exponential", ...
    "triangular","modified","custom"];
type = validatestring(p.Results.Type,validTypeStrings,'','type of moving average');


% windowSize / weights validation
[numObs,numVars] = size(data);
switch type
    case "custom"
        weights = p.Results.windowSize;
        validateattributes(length(weights),{'numeric'},{'<=',numObs},'','weights vector');
    otherwise
        windowSize = p.Results.windowSize;
        validateattributes(windowSize,{'numeric'},{'<=',numObs,'scalar','integer','positive'},'','window size');
end

% Endpoints validation
validEndpointsStrings = ["shrink","zero","fill"];
try
    endpoints = validatestring(p.Results.Endpoints,validEndpointsStrings,'','method to treat leading window');
catch ME
    rethrow(ME)
end

%------------------------------ Calculation ------------------------------%
switch type
    case "simple"
        ma = simpleMA(data,windowSize,numVars,endpoints);
    case "square-root"
        weights = weightGenerate(windowSize,0.5);
        ma = weightMA(data,windowSize,numVars,weights,endpoints);
    case "linear"
        weights = weightGenerate(windowSize,1);
        ma = weightMA(data,windowSize,numVars,weights,endpoints);
    case "square"
        weights = weightGenerate(windowSize,2);
        ma = weightMA(data,windowSize,numVars,weights,endpoints);
    case "custom"
        weights = reshape(weights,1,length(weights));
        normalizedWeights = weights / sum(weights);
        windowSize = length(weights);
        ma = weightMA(data,windowSize,numVars,normalizedWeights,endpoints);
    case "triangular"
        % Moving average of a simple moving average.
        doubleSmooth = ceil((windowSize+1)/2);
        movAvg1 = simpleMA(data,doubleSmooth,numVars,endpoints);
        ma = simpleMA(movAvg1,doubleSmooth,numVars,endpoints);
    case "exponential"
        % Calculate the exponential percentage
        alpha = 2/(windowSize+1);
        % Formula:
        % y_0 = x_0
        % y_i = alpha * x_i + (1 - alpha) * y_(i-1)
        ma = filter(alpha,[1,(alpha-1)],data(2:end,:),(1-alpha)*data(1,:));
        ma = [data(1,:);ma];
    case "modified"
        % The first point of the modified moving average is calculated the
        % same way the first point of the simple moving average is calculated.
        % However, all subsequent points are calculated using the modified mov avg formula.
        
        % Formula:
        % y_0 = x_0
        % y_i = (x_i - y_(i-1))/windowSize + y_(i-1)
        alpha = 1/windowSize;
        ma = filter(alpha,[1,(alpha-1)],data(2:end,:),(1-alpha)*data(1,:));
        ma = [data(1,:);ma];
end

%--------------------- Output Preparation --------------------------------%
switch datatypeFlag
    case 0 % double
        % PASS
    case 1 % table
        ma = array2table(ma,'VariableNames',rawData.Properties.VariableNames);
    case 2 % timetable
        ma = array2timetable(ma,'VariableNames',rawData.Properties.VariableNames, ...
            'RowTimes',dates);
end

varargout = {ma};

end

% ------------------- Local Function -------------------------------------%
function ma = simpleMA(data,windowSize,numVars,endpoints)
% Simple moving average
% Replicate existing behavior
weights = weightGenerate(windowSize,0);
ma = weightMA(data,windowSize,numVars,weights,endpoints);
end

function weights = weightGenerate(windowSize,alpha)
i = 1:windowSize;
weights = (windowSize-i+1) .^ alpha ./ sum((1:windowSize) .^ alpha);
end

function weightedMA = weightMA(data,windowSize,numVars,weights,endpoints)
% build moving average vectors by filtering asset through weights
weightedMA = filter(weights,1,data);
switch endpoints
    case "zero"
        % pass
    case "fill"
        weightedMA(1:windowSize-1,:) = NaN(windowSize-1,numVars);
    case "shrink"
        % calculate first n points.
        weightsSum = cumsum(weights);
        weightedMA(1:windowSize,:) = weightedMA(1:windowSize,:) ./ weightsSum';
end
end

% ------------------- Old movavg implementation --------------------------%
function [short,long] = movavg_old(numIn,numOut,asset,lead,lag,alpha)
%MOVAVG Leading and lagging moving averages chart.
%   [SHORT,LONG] = MOVAVG(ASSET,LEAD,LAG,ALPHA) plots leading and lagging
%   moving averages.  ASSET is the security data, LEAD is the number of
%   samples to use in leading average calculation, and LAG is the number
%   of samples to use in the lagging average calculation.  ALPHA is the
%   control parameter which determines what type of moving averages are
%   calculated.  ALPHA = 0 (default) corresponds to a simple moving average,
%   ALPHA = 0.5 to a square root weighted moving average, ALPHA = 1
%   to a linear moving average, ALPHA = 2 to a square weighted moving
%   average, etc.  To calculate the exponential moving averages,
%   let ALPHA = 'e'.
%
%   MOVAVG(ASSET,3,20,1) plots linear 3 sample leading and 20 sample
%   lagging moving averages.
%
%   [SHORT,LONG] = MOVAVG(ASSET,3,20,1) returns the leading and lagging
%   average data without plotting it.
%
%   Note: Zero padding is used at the edges of the data.
%
%   See also BOLLING, HIGHLOW, CANDLE, POINTFIG.

%   Copyright 1995-2014 The MathWorks, Inc.

if numIn < 4
    % Default is simple moving average
    alpha = 0;
else
    alpha = convertStringsToChars(alpha);
end

if numIn < 3
    error(message('finance:movavg:missingInputs'))
end

[m,n] = size(asset);
if m > 1 && n > 1
    error(message('finance:movavg:invalidInputSize'))
end
if lead > lag
    error(message('finance:movavg:badLeadInput'))
end

asset = asset(:);
r = length(asset);
if lead < 1 || lead > r || lag < 1 || lag > r
    error(message('finance:movavg:badLeadLagInput', num2str( r )))
end

if lower(alpha) == 'e'
    % compute exponential moving average
    
    % calculate smoothing constant (alpha)
    alphas = 2/(lead+1);
    alphal = 2/(lag+1);
    
    % first exponential average is first price
    laggingAvg(1) = asset(1);
    leadingAvg(1) = asset(1);
    
    % preallocate matrices
    laggingAvg = [laggingAvg;zeros(r-1,1)];
    leadingAvg = [leadingAvg;zeros(r-1,1)];
    
    % lagging average
    % For large matrices of input data, FOR loops are more efficient
    % than vectorization.
    for j = 2:r
        laggingAvg(j) = laggingAvg(j-1) + alphal * (asset(j) - laggingAvg(j-1));
    end
    % leading average
    for j = 2:r
        leadingAvg(j) = leadingAvg(j-1) + alphas * (asset(j) - leadingAvg(j-1));
    end
else
    % compute general moving average (ie simple, linear, etc)
    
    % build weighting vectors
    i = 1:lag;
    laggingWeights(i) = (lag - i + 1) .^ alpha ./ sum((1:lag) .^ alpha);
    i = 1:lead;
    leadingWeights(i) = (lead - i + 1) .^ alpha ./ sum((1:lead) .^ alpha);
    
    % build moving average vectors by filtering asset through weights
    laggingAvg = filter(laggingWeights,1,asset);
    leadingAvg = filter(leadingWeights,1,asset);
end

if numOut == 0
    % If no output arguments, plot moving averages
    h = plot(...
        1:r-lag+1, asset(lag:r),...
        1:r-lag+1, laggingAvg(lag:r),...
        1:r-lag+1,leadingAvg(lag:r));
    
    if get(0,'screendepth') > 1
        cls = get(gca,'colororder');
        set(h(1),'color',cls(1,:))
        set(h(2),'color',cls(2,:))
        set(h(3),'color',cls(3,:))
    end
end

% output data to workspace
short = leadingAvg;
long = laggingAvg;

end