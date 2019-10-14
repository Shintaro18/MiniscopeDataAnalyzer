%=====================Manual===========================
%This program is compatible with only 20FPS miniscope movie.
%"MiniscopeTtlChangeNum" corresponde to the frame number of miniscope movie
%=====================Parameters of the analysis===========================
OperantFileFormat=0;    %If operant house version is 32.4 or older,0; Otherwise,1; 
MiniscopeTtlTh=-500;    %(mV)
OperantTtlTh=2500;      %(mV)
SpikeThreshold=10;      %Not used now
%==========================================================================

%======Load operant result======
%{
if OperantFileFormat==1
    %filename=uigetfile('*.txt','Select operant result file');
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
    filename=uigetfile('*.txt','Select operant result file');   %Open dialog for the selection of the operant result file
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
    filename=uigetfile('*.txt','Select operant TTL log file'); %Open dialog for the selection of the operant box's TTL log
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
%disp(OperantTtlOnTime);
%disp(size(OperantTtlOnTime));
%disp(OperantTtlOnTime(1));



%各タッチイベントに正確なEDR時間を付ける→そのEDR時間に最も近いminiscope動画のframeを対応させる→そのframeを0secとしてグラフを描く
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
    NearestMiniscopeTtlNum=-1;  %Init
    MinDifference=9999;         %Init
    for i2=1: MiniscopeTtlChangeNum     %Each miniscope-TTL-change event(At 20fps, miniscope-TTL-change event correspond to the timing of the image capture)
        Difference= abs(TouchTimeEdrTime(i)-MiniscopeTtlChangeEdrTime(i2));
        if Difference < MinDifference   %if this miniscope-TTL-change eventis more close to this touch
            MinDifference = Difference; %Time different with the current nearest miniscope-TTL-change event
            NearestMiniscopeTtlNum=i2;  %Keep the number of current nearest miniscope-TTL-change event
        end
    end
    if NearestMiniscopeTtlNum == 9999   %If something wrong is happend
        DialogBox=msgbox('Failed to link between touch and miniscope movie frame'); %Show message and stop
        pause;
    end
    LinkedTtlChange(i)=NearestMiniscopeTtlNum;  %Keep the miniscope-TTL-change event number which is linked with current touch event
end
%DialogBox=msgbox('Analysis finished');
%disp(TouchTimeEdrTime(1));
%disp(StartOperaSec);
%disp(TouchTimeOperaSec(1));
disp('Analysis finished');


%{
disp(TtlLog);
Line=0;
Low=0;
SizeOfNeuron = size(neuron.C);
NumOfNeuron = SizeOfNeuron(1);
NumOfFrame = SizeOfNeuron(2);
SpikeNum=zeros(NumOfNeuron,1);
for y=1:NumOfNeuron
    for x=2:NumOfFrame
        if (neuron.C(y,x-1) < SpikeThreshold) && (neuron.C(y,x) >= SpikeThreshold)  %When signal exeed spike Th
           SpikeNum(y)=SpikeNum(y)+1;
        end
    end
end
disp(SpikeNum);
%}