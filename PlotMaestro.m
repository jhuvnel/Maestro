clear; clc; close all;
% Update this loading when these files will permanently live on the server
load ALLMVI-MaestroResults
load VNELcolors
warning('off')
all_sub_info = readtable('MVI_Information.xlsx');
warning('on')
%% Plot Summary Figure MVI 1-10
all_IFT_Data = maestro_data.IFT;
IFT_Data = all_IFT_Data; %Copy to delete items from 
all_subjects = unique(IFT_Data.Subject);
patient_num = length(all_subjects);
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
% Portrait Orientation
fig1 = figure(1);
set(fig1,'Color',[1,1,1],'Units','inches','Position',[0.5 0.5 6 8])
row_num = mod(patient_num,2) + floor(patient_num/2);
ha = gobjects(patient_num,1);
%Axes Sizing Parameters
xmin = 0.11;
xspac = 0.09;
xmax = 0.98;
ymin = 0.05;
ymax = 0.97;
yspac = 0.03;
xwid = (xmax-xmin-xspac)/2;
xpos = reshape(repmat([xmin,xmin+xwid+xspac],row_num,1),[],1);
ywid = (ymax-ymin-(row_num-1)*yspac)/row_num;
ypos = repmat(fliplr(ymin:(ywid+yspac):ymax),1,2)';
xtic_gap = xwid / 18;
r = 1.25*xtic_gap;
%Writing a formula for the dimenstions of the annotation
circ_dim = @(i,enum) [((enum-3)*2+1)*xtic_gap-0.5*r+xpos(i),ypos(i)-0.90*r,r,0.75*r];
circ_col = [colors.l_r;colors.l_z;colors.l_l;colors.l_r_s;colors.l_z_s;colors.l_l_s];
circ_lin = repmat({'-'},patient_num,1);
circ_lin(contains(sub_info.Ear,'R')) = {'--'};
%Initial plot
for i = 1:patient_num
    ha(i) = subplot(row_num,2,i);
    %Transpose patient data so that in the event that the number of time
    %points equals the number of electrodes, MATLAB knows which dimension
    %to plot across.
    patient_impedance = IFT_Data{contains(IFT_Data.Subject,all_subjects{i}),6:14}';
    plot(3:11,patient_impedance/1000,'-o')
    leg1 = legend(ha(i),IFT_Data.Visit(contains(IFT_Data.Subject,all_subjects{i})),...
        'Location','south','NumColumns',5,'FontSize',6,'box','off');
    leg1.ItemTokenSize(1) = 5; 
    ylabel(ha(i),all_subjects{i}(1:6),'FontSize',14,'FontWeight','bold') 
end
set(ha,'Color',[1,1,1],'YLim',[-4 18],'Xlim',[2.5 11.5],'Ygrid','on')
set(ha,'xtick',3:11,'xticklabel',cellfun(@num2str,num2cell(3:11),'UniformOutput',false))
for i = 1:patient_num
    set(ha(i),'Position',[xpos(i),ypos(i),xwid,ywid]);
    for j = 1:6
        if ~isnan(Electrode(i,j))
            annotation('ellipse',circ_dim(i,Electrode(i,j)),'Color',circ_col(j,:),'LineStyle',circ_lin{i});
        end
    end   
end
h1 = axes(fig1,'visible','off','Position',[0.75*xmin 1.1*ymin xmax ymax-1.1*ymin]);
h1.XLabel.Visible = 'on';
h1.YLabel.Visible = 'on';
h1.Title.Visible = 'on';
title(h1,'Maestro Impedance Data (302.4 cu, 26.67\mus)','FontSize',14)
ylabel(h1,'Impedance (k\Omegas)');
xlabel(h1,'Electrode Number');
% Same figure in Landscape Orientation
fig2 = figure(2);
clf;
set(fig2,'Color',[1,1,1],'Units','inches','Position',[0.5 0.5 9 6])
row_num = mod(patient_num,3) + floor(patient_num/3);
ha = gobjects(patient_num,1);
%Axes Sizing Parameters
xmin = 0.07;
xspac = 0.06;
xmax = 0.98;
ymin = 0.07;
ymax = 0.96;
yspac = 0.05;
xwid = (xmax-xmin-2*xspac)/3;
xpos = reshape(repmat(xmin:(xwid+xspac):xmax,row_num,1),[],1);
ywid = (ymax-ymin-(row_num-1)*yspac)/row_num;
ypos = repmat(fliplr(ymin:(ywid+yspac):ymax),1,3)';
xtic_gap = xwid/18;
r = 1.8*xtic_gap;
%Writing a formula for the dimenstions of the annotation
circ_dim = @(i,enum) [((enum-3)*2+1)*xtic_gap-0.32*r+xpos(i),ypos(i)-1.3*r,2/3*r,r];
circ_col = [colors.l_r;colors.l_z;colors.l_l;colors.l_r_s;colors.l_z_s;colors.l_l_s];
circ_lin = repmat({'-'},patient_num,1);
circ_lin(contains(sub_info.Ear,'R')) = {'--'};
%Initial plot
for i = 1:patient_num
    ha(i) = subplot(row_num,3,i);
    %Transpose patient data so that in the event that the number of time
    %points equals the number of electrodes, MATLAB knows which dimension
    %to plot across.
    patient_impedance = IFT_Data{contains(IFT_Data.Subject,all_subjects{i}),6:14}';
    plot(3:11,patient_impedance/1000,'-o')
    leg1 = legend(ha(i),IFT_Data.Visit(contains(IFT_Data.Subject,all_subjects{i})),...
        'Location','south','NumColumns',5,'FontSize',6,'box','off');
    leg1.ItemTokenSize(1) = 5; 
    ylabel(ha(i),all_subjects{i}(1:6),'FontSize',14,'FontWeight','bold') 
end
set(ha,'Color',[1,1,1],'YLim',[-4 18],'Xlim',[2.5 11.5],'Ygrid','on')
set(ha,'xtick',3:11,'xticklabel',cellfun(@num2str,num2cell(3:11),'UniformOutput',false))
for i = 1:patient_num
    set(ha(i),'Position',[xpos(i),ypos(i),xwid,ywid]);
    for j = 1:6
        if ~isnan(Electrode(i,j))
            annotation('ellipse',circ_dim(i,Electrode(i,j)),'Color',circ_col(j,:),'LineStyle',circ_lin{i});
        end
    end   
end
h1 = axes(fig2,'visible','off','Position',[0.75*xmin 1.1*ymin xmax ymax-1.1*ymin]);
h1.XLabel.Visible = 'on';
h1.YLabel.Visible = 'on';
h1.Title.Visible = 'on';
title(h1,'Maestro Impedance Data (302.4 cu, 26.67\mus)','FontSize',14)
ylabel(h1,'Impedance (k\Omegas)');
xlabel(h1,'Electrode Number');

%% Plot figure for each patient
% The position of annotation needs to be recalculated.
row_num = 1;
%Axes Sizing Parameters
xmin = 0.12;
xspac = 0;
xmax = 0.97;
ymin = 0.15;
ymax = 0.94;
yspac = 0;

xwid = xmax-xmin-xspac;
xpos = xmin;
ywid = ymax-ymin-(row_num-1)*yspac;
ypos = ymin;

xtic_gap = xwid/18;
r = 1.3*xtic_gap;
%Writing a formula for the dimenstions of the annotation
circ_dim = @(i,enum) [((enum-3)*2+1)*xtic_gap-0.4*r+xpos,ypos-1.3*r,3/4*r,r];

for i = 1:patient_num
    Fig_i = figure(i+3);
    set(Fig_i,'Color',[1,1,1],'Units','inches','Position',[2.5 2.5 4 3])
    %Transpose patient data so that in the event that the number of time
    %points equals the number of electrodes, MATLAB knows which dimension
    %to plot across.
    patient_impedance = IFT_Data{contains(IFT_Data.Subject,all_subjects{i}),6:14}';
    plot(3:11,patient_impedance/1000,'-o')
    leg1 = legend(IFT_Data.Visit(contains(IFT_Data.Subject,all_subjects{i})),...
        'Location','south','NumColumns',5,'FontSize',6,'box','off');
    leg1.ItemTokenSize(1) = 9; 
    ylabel('Impedance (k\Omegas)');
    xlabel('Electrode Number');
    title(strcat(all_subjects{i}(1:6),' Maestro Impedance Data (302.4 cu, 26.67\mus)'),'FontSize',10,'FontWeight','bold')
    set(gca,'Color',[1,1,1],'YLim',[-4 18],'Xlim',[2.5 11.5])
    set(gca,'xtick',3:11,'xticklabel',cellfun(@num2str,num2cell(3:11),'UniformOutput',false))
    
    set(gca,'Position',[xpos,ypos,xwid,ywid]);
    for j = 1:6
        if ~isnan(Electrode(i,j))
            annotation('ellipse',circ_dim(i,Electrode(i,j)),'Color',circ_col(j,:),'LineStyle',circ_lin{i});
        end
    end   
end