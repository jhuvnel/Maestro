clear; clc; close;
load ALLMVI-MaestroResults
load VNELcolors
all_IFT_Data = maestro_data.IFT;
IFT_Data = all_IFT_Data;
all_subjects = unique(IFT_Data.Subject);
patient_num = length(all_subjects);
warning('off')
all_sub_info = readtable('MVI_Information.xlsx');
warning('on')
[~,a] = ismember(all_subjects,all_sub_info.Subject);
sub_info = all_sub_info(a,:); %Get it into the same order as the Maestro Subjects
sub_info.Properties.RowNames = sub_info.Subject;
pat1 = "E"+(digitsPattern(2)|digitsPattern(1))+" (";
pat2 = "(E"+(digitsPattern(2)|digitsPattern(1));
Electrode = [sub_info.Posterior,sub_info.Horizontal,sub_info.Anterior];
%Now make the left column RALP and the right column RALP
Electrode(contains(sub_info.Ear,'R'),1) = sub_info.Anterior(contains(sub_info.Ear,'R'));
Electrode(contains(sub_info.Ear,'R'),3) = sub_info.Posterior(contains(sub_info.Ear,'R'));
prev_Electrode = cell(size(Electrode));
prev_Electrode(contains(Electrode,'(')) = strrep(extract(Electrode(contains(Electrode,'(')),pat2),'(E','');
Electrode(contains(Electrode,'(')) = extract(Electrode(contains(Electrode,'(')),pat1);
Electrode = strrep(strrep(Electrode,' (',''),'E','');
Electrode = str2double([Electrode,prev_Electrode]);
% Remove duplicate visits
IFT_Data([strcmp(join(IFT_Data{2:end,1:2},','),join(IFT_Data{1:end-1,1:2},','));false],:) = [];
% Isolate relevant visits
for i = 1:patient_num
    sub_inds = find(strcmp(IFT_Data.Subject,all_subjects{i}));
    if length(sub_inds)>5
        keep_inds = strcmp(IFT_Data.Visit(sub_inds),'Visit1')|contains(IFT_Data.Visit(sub_inds),{'Visit3','9x','10x'});
        keep_inds(end) = 1;
        if sum(keep_inds)~=5
            keep_inds(find(keep_inds==0,5-sum(keep_inds),'last')) = 1;
        end
        IFT_Data(sub_inds(~keep_inds),:) = [];
    end    
end
fig = figure(1);
set(fig,'Color',[1,1,1],'Units','inches','Position',[0.5 0.5 6 8])
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
r = 0.73 * xtic_gap;
%xpos_circle = repmat(xpos,1,3) + ((Electrode-3)*2+1) * xtic_gap - 0.42 * r;
%ypos_circle = repmat(reshape(ypos,[],1),1,3) - 1.35 * r;
%Writing a formula instead
circ_dim = @(i,enum) [((enum-3)*2+1)*xtic_gap-0.42*r+xpos(i),ypos(i)-1.35*r,r,r];
circ_col = [colors.l_r;colors.l_z;colors.l_l;colors.l_r_s;colors.l_z_s;colors.l_l_s];
circ_lin = repmat({'-'},patient_num,1);
circ_lin(contains(sub_info.Ear,'R')) = {'--'};
%Initial plot
for i = 1:patient_num
    ha(i) = subplot(row_num,2,i);
end
for i = 1:patient_num
    %Transpose patient data so that in the event that the number of time
    %points equals the number of electrodes, MATLAB knows which dimension
    %to plot across.
    patient_impedance = IFT_Data{contains(IFT_Data.Subject,all_subjects{i}),6:14}';
    %Time_legend = cellstr(datestr(IFT_Data{contains(IFT_Data.Subject,all_subjects{i}),3},'mm/dd/yy'));
    Patient_number = all_subjects{i};   
    axes(ha(i))
    set(ha(i),'Position',[xpos(i),ypos(i),xwid,ywid]);
    plot(3:11,patient_impedance/1000,'-o')
    title(Patient_number)
    leg1 = legend(ha(i),IFT_Data.Visit(contains(IFT_Data.Subject,all_subjects{i})),'Location','south','NumColumns',5,'FontSize',6,'box','off');
    %leg1 = legend(ha(i),Time_legend,'Location','south','NumColumns',5,'FontSize',4,'box','off');
    leg1.ItemTokenSize(1) = 5;    
    for j = 1:6
        if ~isnan(Electrode(i,j))
            annotation('ellipse',circ_dim(i,Electrode(i,j)),'Color',circ_col(j,:),'LineStyle',circ_lin{i});
        end
    end   
end
set(ha,'Color',[1,1,1],'YLim',[-4 18],'Xlim',[2.5 11.5])
set(ha,'xtick',3:11,'xticklabel',{'3','4','5','6','7','8','9','10','11'})
h1 = axes(fig,'visible','off','Position',[xmin ymin xmax-xmin ymax-ymin+0.5*(1-ymax)]);
h1.XLabel.Visible = 'on';
h1.YLabel.Visible = 'on';
h1.Title.Visible = 'on';
title(h1,'Maestro Impendance Data (302.4 cu,26.67us)','FontSize',14)
ylabel(h1,'Impedance (kOhms)');
xlabel(h1,'Electrode Number');