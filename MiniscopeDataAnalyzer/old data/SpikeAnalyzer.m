%=====================Parameters of the analysis===========================
SpikeThreshold=10;

%==========================================================================
filename=uigetfile('*.txt');
[TrialNum, ResultText, Result, PanelNo, Year, Day, Hour, Min, Sec, Data] = textread(filename,'%d %s %d %d %d %d %d %d %d %f %d ');



Line=0;
Low=0;
SizeOfNeuron = size(neuron.C);
NumOfNeuron = SizeOfNeuron(1);
NumOfFrame = SizeOfNeuron(2);
SpikeNum=zeros(NumOfNeuron,1);
for y=1:NumOfNeuron
    %CurrSpikeNum=0;
    for x=2:NumOfFrame
        if (neuron.C(y,x-1) < SpikeThreshold) && (neuron.C(y,x) >= SpikeThreshold)  %When signal exeed spike Th
           %CurrSpikeNum=CurrSpikeNum+1;
           SpikeNum(y)=SpikeNum(y)+1;
        end
    end
end
disp(SpikeNum);