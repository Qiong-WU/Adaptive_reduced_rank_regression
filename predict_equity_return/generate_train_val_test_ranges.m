% Inputs:
%    first_data_date, last_test_date
%    test_years, test_months
%    gray_years, gray_months
%    train_years, train_months
% Outputs:
%    testStartDates, testEndDates, trainStartDates, testEndDates
%    testDates
%    validation sets: valStartDate, valEndDate
% 

test_window_dt = calendarDuration(test_years, test_months, 0);
gray_window_dt = calendarDuration(gray_years, gray_months, 0);
train_window_dt = calendarDuration(train_years, train_months, 0);

testStartDates = [];
testEndDates = [];
trainStartDates = [];
trainEndDates = [];
testDates = {};


trainStartDate_dt = datetime(first_train_date, 'ConvertFrom', 'yyyymmdd');
testStartDate_dt = datetime(first_test_date, 'ConvertFrom', 'yyyymmdd');
testEndDate_dt = testStartDate_dt + test_window_dt;
last_test_date_dt = datetime(last_test_date, 'ConvertFrom', 'yyyymmdd');


valStartDates = [];
valEndDates = [];
valDates ={};

while testEndDate_dt <= last_test_date_dt 
    testStartDate = yyyymmdd(testStartDate_dt);
    testEndDate = yyyymmdd(testStartDate_dt + test_window_dt);
    
    valEndDate = yyyymmdd(testStartDate_dt - gray_window_dt);
    valStartDate = yyyymmdd(testStartDate_dt - gray_window_dt - test_window_dt);
    
    trainEndDate = yyyymmdd(testStartDate_dt  - gray_window_dt - test_window_dt - gray_window_dt);
    trainStartDate = yyyymmdd(testStartDate_dt  - gray_window_dt - test_window_dt - gray_window_dt - train_window_dt);

    testStartDates = [testStartDates; testStartDate];
    testEndDates = [testEndDates; testEndDate];
    
    valStartDates = [valStartDates;valStartDate];
    valEndDates = [valEndDates;valEndDate];
    valDates = [valDates;int2str(valStartDate)];
    
    trainStartDates = [trainStartDates; trainStartDate];
    trainEndDates = [trainEndDates; trainEndDate];
    
    testDates = [testDates; int2str(testStartDate)];
    testStartDate_dt = testStartDate_dt + test_window_dt;
    testEndDate_dt = testStartDate_dt + test_window_dt;
end




