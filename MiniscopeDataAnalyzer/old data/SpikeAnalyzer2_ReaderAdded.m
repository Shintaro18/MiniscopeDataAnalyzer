%=====================Parameters of the analysis===========================
SpikeThreshold=10;
OperantFileFormat=0;    %If operant house version is 32.4 or older,0; Otherwise,1; 
%==========================================================================
%{
%======Load operant result======
if OperantFileFormat==0
    filename=uigetfile('*.txt','Select operant result file');
    [TrialNum, ResultText, Result, PanelNo, Year, Month, Day, Hour, Min, Sec] = textread(filename,'%u %s %d %d %d %d %d %d %d %f');

    disp(TrialNum);
    disp(ResultText);
    disp(Result);
    disp(PanelNo);
    disp(Year);
    disp(Month);
    disp(Day);
    disp(Hour);
    disp(Min);
    disp(Sec);
end
%}

%======Load operant TTL log======
if OperantFileFormat==0
    filename=uigetfile('*.txt','Select operant TTL log file');
    A=importdata(filename, '	',1);
    Size=size(A.data);
    SizeY=Size(1);

    for y=1:SizeY/2
        for x=1:7
            TtlLog(y,x)=A.data(y*2-1, x);
        end
    end
end



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