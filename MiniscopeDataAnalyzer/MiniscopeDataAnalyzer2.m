% Remaining work: Support for latest touching result format
% =====================Analysis procedure==============================================
% 1: Make 752x480 grayscale AVI movie (up to 7000 frames in Quest) or make 188x120 grayscale AVI movie.
% 2: Perform motion correction with NoRMCorre.
% 3: Exstract signals with CNMF_E.
% 4: Exclude bad signals using "neuron.viewNeurons()" function and save it.
% 5: Modify touching result, TTL of operant and WinED while referring to the samples.
% 6: Set start frame number as "StartFrame" valuable (If necessary).
% 7: Stat run. Data will be in the AlignedSingalRight, AlignedSingalWrong, AveAlignedSingalRight, AveAlignedSingalWrong valuables.

% =====================Notes==========================================================
% Although this code is tested with only 20 fps movie, other fps movie would also work.
% "MiniscopeTtlChangeNum" corresponde to the frame number of miniscope movie
% "LinkedMovieFrame" contains info about which touch event is linked with which movie frame of the miniscope.
% "TouchResultText" has info about the type of touch (exp. correct touch / incorrect touch etc).

% ==============Outline of this code==================================================
% (JPN) 各タッチイベントに正確なEDR時間を付ける→そのEDR時間に最も近いminiscope動画のframeを対応させる→そのframeを0secとしてグラフを描く
% (ENG) Assign EDR time for each touch event -> Serch for movie frame which has closest EDR time -> Draw graph where 0 sec correspond with EDR time of each touch event

%=====================Parameters of the analysis======================================
clear;
StartFrame=0;   % If this is 1000, 1st frame of the 20 fps video is deemed as started capturing 50sec after the starting of the operant task(Use 0 in normal condition). 
MovieFPS=20;    % This value is necessary only if "StartFrame" is not 0. 
OperantFileFormat=0;    %If operant house version is 32.4 or older,set 0; Otherwise,set 1; 
MiniscopeTtlTh=-500;    % Threshold for detecting TTL pulse timing of the miniscope (mV)
OperantTtlTh=2500;      % Threshold for detecting TTL pulse timing of the operant house (mV)
NegativeDur=15;	% Analyze time window before the touch (sec)
PositiveDur=15;	% Analyze time window after the touch (sec)
LoadDataType=1; % Use 0:Raw data (Neuron.C_raw) 1:Fitting data (Neuron.C)
%======Load operant result======
%{
if OperantFileFormat==1
    %filename=uigetfile('*.txt','Select the result file of the operant task');
    filename='Touch sample 0918 mod.txt';
    [TouchTrialNum, TouchResultText, TouchResult, TouchPanelNo, TouchYear, TouchMonth, TouchDay, TouchHour, TouchMin, TouchSec] = textread(filename,'%u %s %d %d %d %d %d %d %d %f');
    disp(TouchTrialNum);
    disp(TouchResultText);
    disp(TouchResult);
    disp(TouchPanelNo);
    disp(TouchYear);
    disp(TouchMonth);
    disp(TouchDay);
    disp(TouchHour);
    disp(TouchMin);
    disp(TouchSec);
end
%}


if OperantFileFormat==0
    filename=uigetfile('*.txt','Select the touching result file of the operant task');   %Open dialog for the selection of the operant result file
    %filename='Touch sample 0918 mod2.txt'; %For debug
    [TouchTrialNum, TouchResultText, TouchResultText2, TouchYear, TouchMonth, TouchDay, TouchHour, TouchMin, TouchSec] = textread(filename,'%u %s %s %d %d %d %d %d %f');
    %{
    disp(TouchTrialNum);
    disp(TouchResultText);
    disp(TouchResultText2);
    disp(TouchYear);
    disp(TouchMonth);
    disp(TouchDay);
    disp(TouchHour);
    disp(TouchMin);
    disp(TouchSec);
    %}
end

%======Load operant TTL log======
if OperantFileFormat==0
    filename=uigetfile('*.txt','Select TTL log file of the operant house'); %Open dialog for the selection of the operant box's TTL log
    OpeTtl=importdata(filename, '	',1);
    %OpeTtl=importdata('Opera TTL sample 0918.txt', '	',1); %For debug
    OpeTtlSize=size(OpeTtl.data);
    OpeTtlSizeY=OpeTtlSize(1);  %Get number of total operant house's TTL number from the log
    for y=1:OpeTtlSizeY/2
        for x=1:7
            OperantTtlLog(y,x)=OpeTtl.data(y*2-1, x);   %Put TTL log data into variables
        end
    end
end

%======Load WinEDR TTL log======
filename=uigetfile('*.txt','Select WinEDR TTL log file'); %Open dialog for the selection of the WinEDR TTL log
Edr=importdata(filename, '	');
%Edr=importdata('WinEDR example.txt', '	'); %For debug
EdrSize=size(Edr);
EdrSizeY=EdrSize(1); %Get the number of the TTL from WinEDR TTL log

%======Collection of miniscope TTL ON event======
Cnt=1;
for y=2:EdrSizeY
    if (Edr(y-1,2) < MiniscopeTtlTh) && (Edr(y,2) >= MiniscopeTtlTh)    %If miniscope's TTL voltage rises crossing the threshold
        MiniscopeTtlChangeEdrTime(Cnt)=Edr(y,1);    %Keep the EDR time of this event
        Cnt=Cnt+1;
    end
     if (Edr(y-1,2) > MiniscopeTtlTh) && (Edr(y,2) <= MiniscopeTtlTh)    %If miniscope's TTL voltage decays crossing the threshold
        MiniscopeTtlChangeEdrTime(Cnt)=Edr(y,1);     %Keep the EDR time of this event
        Cnt=Cnt+1;
    end
end

%======Collection of operant house TTL ON event======
Cnt=1;
for y=2:EdrSizeY
    if (Edr(y-1,3) > MiniscopeTtlTh) && (Edr(y,3) <= MiniscopeTtlTh)    %If operant house's TTL voltage decays crossing the threshold
        OperantTtlOnEdrTime(Cnt)=Edr(y,1);
        Cnt=Cnt+1;
    end
end

disp('Now linking between touching and video frame...');



StartOperaSec = OperantTtlLog(1,2)*3600 + OperantTtlLog(1,3)*60 + OperantTtlLog(1,4);   %GetOperaTime of 1st TTL ON
TouchTimeOperaSec = (TouchHour*3600) + (TouchMin*60) + TouchSec;  %Caliculate seconds from start of each touch
TouchTimeFromStartOperaSec = TouchTimeOperaSec - StartOperaSec;

LinkedTtlNum = transpose(fix(TouchTimeFromStartOperaSec/2)+1);              %Linked opera-TTL-ON event number (1-)
DelayFromLinkedTtl=transpose(rem(TouchTimeFromStartOperaSec,2));            %Delay sec from linked opera-TTL-ON
TouchTimeEdrTime = OperantTtlOnEdrTime(LinkedTtlNum)+DelayFromLinkedTtl;    %Touch sec (EDR time)

TouchNum = size(TouchTimeEdrTime);
TouchNum = TouchNum(2); %Keep number of touch event
MiniscopeTtlChangeNum = size(MiniscopeTtlChangeEdrTime);
MiniscopeTtlChangeNum = MiniscopeTtlChangeNum(2);   %Keep number of frame number(=ON and OFF number of TTL signal)

%Serching for video frame which has nearist EDR time with each touch event 
for i=1:TouchNum    %Each touch
    if TouchTimeEdrTime(i) >= StartFrame/20
        NearestMiniscopeTtlNum=-1;  %Init
        MinDifference=9999;         %Init
        for i2=1: MiniscopeTtlChangeNum     %Each miniscope-TTL-change event(At 20fps, miniscope-TTL-change event correspond to the timing of the image capture)
            Difference= abs(TouchTimeEdrTime(i)-MiniscopeTtlChangeEdrTime(i2)); %Caliculate time difference between current touch event and miniscope-TTL-change event
            if Difference < MinDifference   %if this miniscope-TTL-change eventis more close to this touch
                MinDifference = Difference; %Time different with the current nearest miniscope-TTL-change event
                NearestMiniscopeTtlNum=i2;  %Keep the number of current nearest miniscope-TTL-change event
            end
        end
        if NearestMiniscopeTtlNum == 9999   %If something wrong is happend
            DialogBox=msgbox('Failed to link between touch and miniscope movie frame'); %Show message and stop
            pause;
        end
        LinkedMovieFrame(i)=NearestMiniscopeTtlNum;  %Keep the miniscope-TTL-change event number which is linked with current touch event
    end
end
disp('Linking is completed');
disp('Now cliping...');


%==================================Crip signals during touching======================================================================

%Init
FPS=20;         % frame rate of the movie
NegativeFrameNum=NegativeDur*FPS;   % Caliculate frame number of pre-touch time window for graphs
PositiveFrameNum=PositiveDur*FPS;   % Caliculate frame number of post-touch time window for graphs
WindowFrameNum=NegativeFrameNum + PositiveFrameNum; % Caliculate total frame number of the time window for graphs


CurrAlignedSignalRightNum=1;
CurrAlignedSignalWrongNum=1;

for LoadNumber=0:9999   % Roop for each movie file
    
    % Select neuron class file
    [Filename,Path]=uigetfile('*.mat','Select the CNMF data (Sources2D class)');   %Open dialog for the selection of the "neuron" file (Result of CNMF_E analysis contained in the neuron class instance)
    NameAndPath="";
    NameAndPath = strcat(NameAndPath,Filename);
    load(NameAndPath);
    %load('C:\Box\Anis Laboratory\Programs\MiniscopeUtilities\Data\neuron data\0908 1to2.mat','-mat'); % For debug
    if LoadDataType==0
        SignalInt=transpose(neuron.C_raw);
    end
    if LoadDataType==1
        SignalInt=transpose(neuron.C);
    end
    TotalFrameNum=size(SignalInt,1);
    TotalCellNum=size(SignalInt,2);
    TotalDuration = TotalFrameNum/FPS;
    
    for x=1:TotalCellNum    % Roop for each cell
        for i=1:TouchNum    % Roop for each touch
            %if (LinkedMovieFrame(i) >= NegativeFrameNum) && (LinkedMovieFrame(i) <= TotalFrameNum - PositiveFrameNum)
            if (LinkedMovieFrame(i)-(LoadNumber*TotalFrameNum)-StartFrame >= NegativeFrameNum) && (LinkedMovieFrame(i)-(LoadNumber*TotalFrameNum)-StartFrame <= TotalFrameNum - PositiveFrameNum)   % If touch event isn't located at the edge of the movie file
                StartY=LinkedMovieFrame(i)-(LoadNumber*TotalFrameNum)-NegativeFrameNum-StartFrame;  % Caliculate first frame of touch-related Ca signal
                EndY= StartY+WindowFrameNum;    % Caliculate last frame of touch-related Ca signal
                OutputY=1;
                if char(TouchResultText(i,1))=="CorrectTouch"   % If this touch event is correct
                    for y=StartY:EndY
                        AlignedSignalRight(CurrAlignedSignalRightNum, OutputY) = SignalInt(y,x);    % The signal is kept in the variables which is made for keeping right touch-related signals
                        OutputY=OutputY+1;
                    end
                    CurrAlignedSignalRightNum = CurrAlignedSignalRightNum+1;
                end

                if TouchResultText(i,1)=="IncorrectTouch"   % If this touch event is Incorrect
                    for y=StartY:EndY
                        AlignedSignalWrong(CurrAlignedSignalWrongNum, OutputY) = SignalInt(y,x);    % The signal is kept in the variables which is made for keeping wrong touch-related signals
                        OutputY=OutputY+1;
                    end
                    CurrAlignedSignalWrongNum = CurrAlignedSignalWrongNum+1;
                end
            end
        end
    end
    Answer = questdlg('Would you like to add further neuron class data?', 'Question', 'Yes','No','Yes');    % If the neuron class file selected is last part of the movie, select No then graphs will be made
    if Answer=="No"
        break;
    end
end

% Draw graphs
A=-NegativeDur:0.05:PositiveDur;

figure('Name','Individual signal traces during RIGHT responses');
plot(A,AlignedSignalRight);

figure('Name','Individual signal traces during WRONG responses');
plot(A,AlignedSignalWrong);

figure('Name','Averaged signal trace during RIGHT responses');
AveAlignedSignalRight=mean(AlignedSignalRight,1);
plot(A,AveAlignedSignalRight);

figure('Name','Averaged signal trace during WRONG responses');
AveAlignedSignalWrong=mean(AlignedSignalWrong,1);
plot(A,AveAlignedSignalWrong);

disp('Criping is finished');