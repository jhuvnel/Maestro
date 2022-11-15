clear; clc;
load ALLMVI-MaestroResults
IFT_Data = maestro_data.IFT;
Electrode = [3,5;4,5;6,7;3,7;5,7;3,9;6,7;5,8;6,8;4,9];
all_subjects = unique(IFT_Data.Subject);
patient_num = length(all_subjects);

% [~,Subject_id_ART,~] = unique(maestro_data.ART(:,4));
fig = figure(1);
set(fig,'Color',[1,1,1],'Units','inches','Position',[1 1 6 8])
row_num = mod(patient_num,2) + floor(patient_num/2);
ha = gobjects(row_num*2,1);
%Axes Sizing Parameters
%CHANGE ME
xmin = 0.09;
xspac = 0.06;
xmax = 0.97;
ymin = 0.06;
ymax = 0.94;
yspac = 0.065;
% DONT CHANGE ME
xwid = (xmax-xmin-xspac)/2;
xpos = reshape(repmat([xmin;xmin+xwid+xspac],1,row_num),[],1);
ywid = (ymax-ymin-(row_num-1)*yspac)/row_num;
ypos = reshape(repmat(fliplr(ymin:(ywid+yspac):ymax),2,1),[],1)';

xtic_gap = xwid / 18;
r = 0.7 * xtic_gap;
xpos_circle = repmat(xpos,1,2) + ((Electrode-3)*2+1) * xtic_gap - 0.42 * r;
ypos_circle = repmat(reshape(ypos,[],1),1,2) - 1.35 * r;
%Initial plot
for i = 1:patient_num
    ha(i) = subplot(row_num,2,i);
end
for i = 1:patient_num
    %Transpose patient data so that in the event that the number of time
    %points equals the number of electrodes, MATLAB knows which dimension
    %to plot across.
    patient_impedance = IFT_Data{contains(IFT_Data.Subject,all_subjects{i}),6:14}';
    Time_legend = cellstr(datestr(IFT_Data{contains(IFT_Data.Subject,all_subjects{i}),3},'mm/dd/yy hh:MM'));
    Patient_number = all_subjects{i};   
    axes(ha(i))
    set(ha(i),'Position',[xpos(i),ypos(i),xwid,ywid]);
    plot(3:11,patient_impedance/1000,'-o')
    title(Patient_number)
    leg1 = legend(ha(i),Time_legend,'Location','south','NumColumns',4,'FontSize',4,'box','off');
    leg1.ItemTokenSize(1) = 5;
    dim1 = [xpos_circle(i,1),ypos_circle(i,1),r,r];
    dim2 = [xpos_circle(i,2),ypos_circle(i,2),r,r];
    annotation('ellipse',dim1,'Color','red');
    annotation('ellipse',dim2,'Color','blue');
end
set(ha,'Color',[1,1,1],'YLim',[-12 20],'Xlim',[2.5 11.5])
set(ha,'xtick',3:11,'xticklabel',{'3','4','5','6','7','8','9','10','11'})
h1 = axes(fig,'visible','off','Position',[xmin ymin xmax-xmin ymax-ymin+0.5*(1-ymax)]);
h1.XLabel.Visible = 'on';
h1.YLabel.Visible = 'on';
h1.Title.Visible = 'on';
title(h1,'Maestro Impendance Data (302.4 cu,26.67us)','FontSize',14)
ylabel(h1,'Impedance (kOhms)');
xlabel(h1,'Electrode Number');