%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%       Main
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Metadata
% Written by    : Nathanaël Esnault
% Verified by   : N/A
% Creation date : 2019-03-24
% Version       : 1.2 (finished on ...)
% Modifications :
% Known bugs    :

%% Functions associated with this code :

%% Notes

%% Ideas and Possible Improvements

%% Ressources

%% Cleaning + DefaultFormat + testID

close all;
clc
clearvars;
tic
% generate a unique test ID
formatOut = 'yyyy-mm-dd--HH-MM-SS-FFF';
RunID = datestr(now,formatOut);
clearvars formatOut;
format compact %Suppress excess blank lines to show more output on a single screen.
format longG % disable those "e+09" when dealing with indeces

% datetime.setDefaultFormats('default','yyyy-MM-dd hh:mm:ss');

set(0,'DefaultFigureWindowStyle','docked');

%% Turning specific warnings off

% warning('off','vision:calibrate:boardShouldBeAsymmetric');

%% Parameters

Parameters;

% GetParameters; % Not programmed


%% Start using the log file
% Message(1,1,1,'Asking for new file', 'UDEF',RunID); %Creating a new log file (by using the third "1" in the function parameters)
% Message(1,1,0,['Local directory is : ' cd ], 'UDEF', RunID); %Loging the cd

%% Init DO NOT EDIT
occured_error = 0;

%% Initialisation



% Look for the folder named Logs
if (isfolder(inputFolder)) %---------> use "isdir" if this line gives an error
    %look for all the files names Seismometer
    %     Seismometer.log.2019-03-18_14-28-47
    %     Seismometer.log
    
    
    %% Import
    MyDirInfo = dir([inputFolder '\LOG*.TXT']); %keep the star (wildcard), keep the UPPERCASE
    
    % verify the date in the file names
    
    nbrbadfiles = 0;
    listFile = NaN(length(MyDirInfo),1);
    for cnt_file = 1 : length(MyDirInfo)
        try
            listFile(cnt_file) = str2double(MyDirInfo(cnt_file).name(4:8));
        catch
            nbrbadfiles = nbrbadfiles + 1;
        end
    end
    
    %delete remaining NaN
    listFile(isnan(listFile)) = [];
    
    %% Preallocate
    
    nbr_GoodFiles                     = length(listFile);
    allData.timeStamp                 = NaT(LogModeLength * nbr_GoodFiles, 1); % There is only 1 timestamp per line (for AcqPerLine aquisitions)
    allData.timeStamp_ultraPrecision  = NaN(LogModeLength * nbr_GoodFiles, 1); % There is only 1 timestamp per line (for AcqPerLine aquisitions)
    allData.Acceleration              = NaN(LogModeLength * nbr_GoodFiles, AcqPerLine);
    
    
    %% Open each file and check the timestamps (fisrt part of the line)
    idxstart = 1;
    for cnt_files = 1 : nbr_GoodFiles
        filename = [cd '\' inputFolder '\LOG' num2str(listFile(cnt_files),'%1.5d')  '.txt'];% 'F:\Logs_1\Seismometer.log.2019-03-18_14-28-54';
        try
            delimiter = {',',':'};
            formatSpec = '%s%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';
            fileID = fopen(filename,'r');
            try
                dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN,  'ReturnOnError', false);
            catch
                % if the fisrt line has a problem (incomplete because of power cut/log)
                startRow = 2;
                dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
            end
            fclose(fileID);
            idxstop = idxstart + length(dataArray{1,2}) - 1;
            allData.Acceleration(idxstart:idxstop,:) = cell2mat(dataArray(:, 3:52));
            allData.timeStamp_ultraPrecision(idxstart:idxstop,1) = dataArray{1,2}(:); % capture all psoc 32-bit timer data
            try
                dates{1} = datetime(dataArray{1}, 'Format', ft, 'InputFormat', ft);
            catch
                try
                    % Handle dates surrounded by quotes ""
                    dataArray{1} = cellfun(@(x) x(2:end-1), dataArray{1}, 'UniformOutput', false);
                    dates{1} = datetime(dataArray{1}, 'Format', ft, 'InputFormat', ft);
                catch
                    dates{1} = repmat(datetime([NaN NaN NaN]), size(dataArray{1}));
                end
            end
            allData.timeStamp(idxstart:idxstop,1) = dates{1};
            clearvars filename delimiter formatSpec fileID dataArray ans;
        catch
        end
        
        idxstart = 1 + idxstop;
    end
    
    %---------------------------------------------------------------------------------
% % % % %     figure
% % % % %     plot(allData.Acceleration(50:end,:),'-')
% % % % % %     hold on
% % % % % %     plot([50 length(allData.Acceleration(:,1))], [1 1] .* info.negativeAccThreshold,'r-')
% % % % %     grid on;
% % % % %     title('Raw acc data check (col #1)');
% % % % %     xlabel('Epoch [50Hz incr.]');
% % % % %     ylabel('Raw value [LSB 24-bit 2''s complement]');
    
    %---------------------------------------------------------------------------------
    figure
    subplot(2,1,1)
    plot(listFile,'-o')
    grid on;
    title('FileName Check');
    ylabel('File Name ID [N/A]');
    xlabel('File number [N/A]');
    
    subplot(2,1,2)
    plot(diff(listFile) ,'-o')
    grid on;
    title('diff(FileName) Check');
    ylabel('Diff(File Name ID [N/A])');
    xlabel('File number [N/A]');
    %---------------------------------------------------------------------------------
    
    % Combine cell arrays to numerical array
    %     MaxLinesperFile = LogModeLength;
    %     TimestepSize = zeros(nbrGoodFiles,1);
    %     for cnt_day = 1 : nbrGoodFiles
    %         TimestepSize(cnt_day) = sum(arrayfun(@(x) length(allData.timeStamp{x,cnt_day}), 1 : MaxLinesperFile));
    %     end
    
    %remove any NaN or empty
    %         idxligndlt = find(any(isnan(allData.Acceleration),2) | any(isnat(allData.timeStamp),2));
    idxligndlt = find(any(isnan(allData.Acceleration),2) | any(isnat(allData.timeStamp),2));
    allData.timeStamp                   (idxligndlt,:) = [];
    allData.Acceleration                (idxligndlt,:) = [];
    allData.timeStamp_ultraPrecision    (idxligndlt,:) = [];
    
    %---------------------------------------------------------------------------------
    figure
    subplot(2,1,1)
    plot(allData.timeStamp_ultraPrecision ,'-o')
    hold on
    plot([0 length(allData.timeStamp_ultraPrecision)], [60 60], '-r')
    grid on;
    axis tight
    title('TimeStamp Check (ultraPrecision)');
    ylabel('Time [ms]');
    xlabel('Timestamp number [N/A]');
    legend('Time from timestamp','Max. threshold');
    
    subplot(2,1,2)
    plot(diff(allData.timeStamp_ultraPrecision ) ,'-o')
    hold on
    plot([0 length(allData.timeStamp_ultraPrecision)-1], [-60 -60], '-r')
    grid on;
    title('diff(TimeStamp) Check (ultraPrecision)');
    ylabel('diff(Time) [ms]');
    xlabel('Timestamp number [N/A]');
    legend('Time from timestamp');
    %---------------------------------------------------------------------------------
    
    DisplayInfoInCommandWindow;

    %start waitbar
    wbHandle = waitbar(0,'Please wait...');
    
    % Prepare some variables for statistics
    %     occupency(cnt_day) =  TimestepSize(cnt_day)/length(allData.Acceleration);
    %     TotalOccupency = sum(TimestepSize)/length(allData.Acceleration);
    
    tic % for time
    
    %% Processing
    if info.average50
        %Prepare FFT
        Fs = AcqPerLine * 4;            % Sampling frequency
        T = 1/Fs;                       % Sampling period
        L = AcqPerLine;                 % Length of signal
        t = (0:L-1)*T;                  % Time vector
        f = Fs*(0:(L/2))/L;
        %      P2 = NaN(L,TimestepSize(1),nbrGoodFiles);
        
        %Prepare indexes
        goodData.Acceleration       = NaN(sum(TimestepSize)*1,1); %50 acq per line
        goodData.timeStamp          = NaT(sum(TimestepSize)*1,1); %extrapolated 50 acq per line (true:1/line)
        goodData.timeStampPSoC      = NaN(sum(TimestepSize)*1,1); %extrapolated 50 acq per line (true:1/line)
        indxFinish                  = cumsum(TimestepSize)*1;
        indxStart                   = [1; indxFinish(1:end-1)+1];
        
        for cnt_day = 1 : nbr_GoodFiles
            tempArrayDayAcc = NaN(1*TimestepSize(cnt_day),1);
            tempArrayDayTim = NaT(1*TimestepSize(cnt_day),1);
            daystr = ['Day ' num2str(cnt_day) '/' num2str(nbr_GoodFiles) ' Acq '];
            for cnt_indxperday = 1 : TimestepSize(cnt_day)
                waitbar(cnt_indxperday/TimestepSize(cnt_day),wbHandle,[daystr  num2str(cnt_indxperday) '/' num2str(TimestepSize(cnt_day))]);
                tempArray = zeros(1,1);
                
                %Find all the data that are negative (appears as large
                %positive) to process them differently from true positive
                
                %when found, here are the steps:
                % convert dec to hex
                % put to binary
                % bitwise invert
                % add 1 and sign
                % replace original
                
                idxneg = find(allData.Acceleration(cnt_line,1:50)> info.negativeAccThreshold);
                for cnt_bin_compl = 1 : length(idxneg)
                    % convert dec to hex
                    tempHEX = dec2hex(allData.Acceleration(cnt_line,idxneg(cnt_bin_compl)));% get the neg data
                    
                    % cut the 1 fisrt byte since the ADC is 24bits and the sent value is 32bits
                    tempHEX_trunc = tempHEX(3:end);
                    
                    % temp_3 = hex2dec(tempHEX_trunc);
                    % put to binary
                    tempBIN_trunc = dec2bin(hex2dec(tempHEX_trunc));
                    
                    % bitwise invert
                    indx_1 = strfind(tempBIN_trunc,'1');
                    indx_0 = strfind(tempBIN_trunc,'0');
                    tempBIN_trunc(indx_1) = '0';
                    tempBIN_trunc(indx_0) = '1';
                    
                    % add 1 and sign
                    final = -1 * (bin2dec(tempBIN_trunc) + 1);
                    
                    % replace original
                    allData.Acceleration(cnt_line,idxneg(cnt_bin_compl)) = final;
                end
                
                
                for cnt_50 = 1 : AcqPerLine
                    sp = 4 * cnt_50 + (cnt_50 - 1);
                    st = sp - 3;
                    %                     allData.Acceleration{cnt_indxperday, cnt_day} = strrep(allData.Acceleration{cnt_indxperday, cnt_day},'FFFF','');
                    try
                        tempArray = tempArray + 1/AcqPerLine * hex2dec(allData.Acceleration{cnt_indxperday, cnt_day}(st:sp));
                    catch
                        tempArray = 0;
                    end
                end
                
                tempArrayDayTim(cnt_indxperday) = allData.timeStamp{cnt_indxperday, cnt_day};
                tempArrayDayAcc(cnt_indxperday) = tempArray;
                
                %              goodData.timeStamp (stdi(cnt_indxperday):spdi(cnt_indxperday)) = repmat(allData.timeStamp{cnt_indxperday, cnt_day},50,1) + milliseconds( ((0:49)').* 1/200);
                %              tempArrayDay(stdi(cnt_indxperday):spdi(cnt_indxperday)) = [0; diff(tempArray)];
                %              P2(:,cnt_indxperday,cnt_day) = abs(fft([0; diff(tempArray)])./L);
            end
            goodData.Acceleration(indxStart(cnt_day):indxFinish(cnt_day))   = tempArrayDayAcc;
            goodData.timeStamp(indxStart(cnt_day):indxFinish(cnt_day))      = tempArrayDayTim;
            goodData.timeStampPSoC(indxStart(cnt_day):indxFinish(cnt_day))  = 1;
        end
    else
        %use reshape?
        
        %Prepare FFT
        Fs  = AcqPerLine * 4;               % Sampling frequency
        T   = 1 / Fs;               % Sampling period
        L   = AcqPerLine;                   % Length of signal
        t   = (0:L - 1) * T;          % Time vector
        f   = Fs *(0:(L / 2)) / L;
        %      P2 = NaN(L,TimestepSize(1),nbrGoodFiles);
        
        
        %Prepare indexes
        goodData.Acceleration   = NaN(length(allData.Acceleration) * AcqPerLine,1); %50 acq per line
        goodData.timeStamp      = NaT(length(allData.Acceleration) * AcqPerLine,1); %extrapolated 50 acq per line (true:1/line)
        indxFinish              = (AcqPerLine:AcqPerLine:length(allData.Acceleration) * AcqPerLine)';
        indxStart               = [1; indxFinish(1:end-1)+1];
        
        last_milliseconds = milliseconds(0);
        lastTimeStamp  = NaT(1);
        
        for cnt_line = 1 : size((allData.Acceleration),1)%265946%1257 %25
            waitbar(cnt_line/length(allData.Acceleration),wbHandle,[num2str(cnt_line) '/' num2str(length(allData.Acceleration))]);
            
%             if any((allData.Acceleration(cnt_line,1:AcqPerLine) > 16777215) | (allData.Acceleration(cnt_line,1:AcqPerLine) < 0))
%                 disp('Error in the input data, 24-bit range exceded')
%             end
            
            idxneg = find(allData.Acceleration(cnt_line,1:AcqPerLine) >= info.negativeAccThreshold);
            for cnt_bin_compl = 1 : length(idxneg)
                %convert dec to hex
                tempHEX = dec2hex(allData.Acceleration(cnt_line,idxneg(cnt_bin_compl)));% get the neg data
                
                % cut the 1 fisrt byte since the ADC is 24bits and the sent value is 32bits
                tempHEX_trunc = tempHEX(3:end);
                
                %             temp_3 = hex2dec(tempHEX_trunc);
                %put to binary
                tempBIN_trunc = dec2bin(hex2dec(tempHEX_trunc));
                
                % bitwise invert
                indx_1 = strfind(tempBIN_trunc,'1');
                indx_0 = strfind(tempBIN_trunc,'0');
                tempBIN_trunc(indx_1) = '0';
                tempBIN_trunc(indx_0) = '1';
                
                %add 1 and sign
                final = -1 * (bin2dec(tempBIN_trunc) + 1);
                
                %replace original
                allData.Acceleration(cnt_line,idxneg(cnt_bin_compl)) = final;
%                 allData.Acceleration(cnt_line,idxneg(cnt_bin_compl)) = allData.Acceleration(cnt_line,idxneg(cnt_bin_compl)) - 16777216;
            end
            
            %
            %             for cnt_toobig = 1 : length(idxneg)
            %                 allData.Acceleration(cnt_line,idxneg(cnt_toobig)) = 0; % allData.Acceleration(cnt_line,idxneg(cnt_toobig)) - 10
            %             end
            
            
            %Acceleration
            goodData.Acceleration(indxStart(cnt_line):indxFinish(cnt_line)) = ...
                allData.Acceleration(cnt_line,1:AcqPerLine)';
            %look if there is negative data
            idxneg = find(allData.Acceleration(cnt_line,1:AcqPerLine)> info.negativeAccThreshold);
            
            
            if allData.timeStamp(cnt_line) ~= lastTimeStamp
               % then reset the accumulator
               last_milliseconds = milliseconds(0);
            end
            
            
            %datetime
            %             goodData.timeStamp(indxStart(cnt_line):indxFinish(cnt_line)) = ...
            %                 repmat(allData.timeStamp(cnt_line),50,1) + ...
            %                 milliseconds( ((0:49)').* 1000/200);
            ms =  milliseconds( ((0:AcqPerLine-1)').* 1000/(AcqPerLine*4)) + last_milliseconds;
            goodData.timeStamp(indxStart(cnt_line):indxFinish(cnt_line)) = ...
                repmat(allData.timeStamp(cnt_line),AcqPerLine,1) + ...
               ms ; % 4 messages per seconds
           
           last_milliseconds = ms(end) + milliseconds(1000/(AcqPerLine*4));
           
%            if allData.timeStamp(cnt_line) ~= lastTimeStamp
               lastTimeStamp = allData.timeStamp(cnt_line);
%            end
        end
        
        
        
    end
    info.TTE = toc;
    disp(['Time to execute is: ' num2str(info.TTE) ' [s]']);
    
    close(wbHandle);% close waitbar
    
    
    %% Plots
    Plots; % script put in another file
    
    %%  Save all the data as matlab format
    if info.saveAsMat
        dateStart = datestr(listFile(1), ft_file);
        dateEnd = datestr(listFile(end), ft_file);
        save([cd '\Data_' dateStart '__' dateEnd],'allData','goodData','Sensor','occured_error','info');
        disp(['File saved as: ' 'Data_' dateStart '__' dateEnd]);
    end
    
    %%  Save all the good data as wav format
    if info.saveAudio
        dateStart = datestr(listFile(1), ft_file);
        dateEnd = datestr(listFile(end), ft_file);
        filename = [cd '\Audio_d_' dateStart '__' dateEnd '.wav'];
        audiowrite(filename,goodData.AccelerationNN*10,200);
    end
    
else
    errordlg('Log folder not found','Folder Error');
end