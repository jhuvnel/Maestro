function processMaestroXML(Maestro_Path,make_plots)
close all;
if nargin < 2 ||~isnumeric(make_plots)
    make_plots = 1; %Default is to plot
end
if nargin < 1 || isempty(Maestro_Path)
    if contains(cd,'Maestro')
        Maestro_Path = cd;
    else
        prompt = 'Select the Maestro folder.';
        Maestro_Path = uigetdir(prompt,prompt);
    end
end
examiner = 'CFB, MRC, EOV'; %for the CRF
%Find and select the .xml file to analyze (only expecting one per visit)
files = extractfield(dir([Maestro_Path,filesep,'*.xml']),'name');
if isempty(files)
    disp(['No .xml files found in path: ',Maestro_Path])
    return;
elseif length(files)>1 %concetenate them into one file
    cell_fdata = cell(length(files),1);
    for i = 1:length(files)
        fname = files{i};
        cell_fdata(i) = {cellstr(readlines([Maestro_Path,filesep,fname]))};
    end
    fdata = vertcat(cell_fdata{:});
else
    fname = files{:};
    fdata = cellstr(readlines([Maestro_Path,filesep,fname]));
end
%Try and get the info from the file structure
path_parts = strrep(split(Maestro_Path,filesep),' ','');
sub = path_parts{contains(path_parts,'_R')}; %All MVI folder names have this
if isempty(sub)
    sub = inputdlg('Set Subject name: (ex. MVI001R001)','Set Subject name');
    sub = sub{:};
else
    sub = strrep(sub,'_','');
end
vis = path_parts{contains(path_parts,'Vis')};
if isempty(vis)
    vis = inputdlg('Set Visit: (ex.Visit1)','Set Visit');
    vis = vis{:};
end
%% IFT/eIFT Data Extraction
exp_start = find(contains(fdata,'TelemetryData CreateDate'));
if ~isempty(exp_start)
    exp_end = find(contains(fdata,{'/TelemetryData','/ExpertTelemetryData'}));
    impedance_data = [cell2table(repmat([{sub},{vis}],length(exp_start),1),'VariableNames',{'Subject','Visit'}),...
        array2table(NaT(length(exp_start),1),'VariableNames',{'Date'}),...
        array2table(NaN(length(exp_start),11),'VariableNames',{'Current_cu','Duration_us','E3','E4','E5','E6','E7','E8','E9','E10','E11'})];
    rm_row = false(length(exp_start),1);
    for i = 1:length(exp_start)
        rel_text = fdata(exp_start(i):exp_end(i));
        rel_lines = false(9,1);
        for j = 3:11
            rel_lines(j-2) = any(contains(rel_text,['Number="',num2str(j),'"']));
        end
        if all(rel_lines)
            date_str = rel_text{1};
            date = datetime(date_str(strfind(date_str,'CreateDate')+(12:30)),'Format','yyyy-MM-dd HH:mm:ss');
            impedance_data{i,3} = date;
            curr_line = contains(rel_text,'StimulationCurrent');
            if ~any(curr_line)&&contains(rel_text(1),'"IFT')
                %Use default IFT #
                curr = '302.4';
            elseif ~any(curr_line)
                %Unknown
                curr = 'NaN';
            else
                curr_str = rel_text{curr_line};
                curr = extractXMLdataline(curr_str);
            end
            impedance_data{i,4} = str2double(curr);
            dur_line = contains(rel_text,'PulseDuration');
            if ~any(dur_line)&&contains(rel_text(1),'"IFT')
                %Use default IFT #
                dur = '26.67e-6';
            elseif ~any(dur_line)
                dur = 'NaN';
            else
                dur_str = rel_text{dur_line};
                dur = extractXMLdataline(dur_str);
            end
            impedance_data{i,5} = str2double(dur)*10^6;
            for j = 3:11
                imp_str = rel_text{find(contains(rel_text,['Number="',num2str(j),'"']))+1};
                imp = extractXMLdataline(imp_str);
                impedance_data{i,j+3} = str2double(imp);
            end
        else
            rm_row(i) = true;
        end
    end
    impedance_data(rm_row,:) = [];
    save([Maestro_Path,filesep,'IFT-Results.mat'],'impedance_data')
    if make_plots
        % Make IFT/eIFT plots with the values
        labs = cellfun(@num2str,num2cell(impedance_data{:,4:5}),'UniformOutput',false);
        labs = strcat(labs(:,1),{'(cu), '},labs(:,2),{'(us)'});
        fig = figure(1);
        set(fig,'Color',[1,1,1]);
        plot(3:11,impedance_data{:,6:end}/1000,'-o')
        if length(labs) > 2
            set(gca,'YLim',[-10 25],'Xlim',[2.5 11.5])
            legend(labs,'Location','south','NumColumns',3)
        else
            set(gca,'YLim',[0 25],'Xlim',[2.5 11.5])
            legend(labs,'Location','south','NumColumns',2)
        end
        xlabel('Electrode Number')
        ylabel('Impedance (kOhms)')
        title([sub,' ',vis,' IFT Maestro Testing'])
        savefig(fig,[Maestro_Path,filesep,sub,'-',vis,'-IFT.fig'])
        saveas(fig,[Maestro_Path,filesep,sub,'-',vis,'-IFT.png'])
        close;
    end
    date_IFT = char(min(impedance_data.Date));
else
    date_IFT = '';
end
%% ART
if any(contains(fdata,'ArtData Create')) % no ART
    exp_start = find(contains(fdata,'<ArtData'),1,'first');
    exp_end = find(contains(fdata,'</ArtData'),1,'last');
    rel_text = fdata(exp_start:exp_end);
    %Find the processed voltage measurements (not the zero templates)
    start_proc = find(contains(rel_text,'<ProcessedData>'));
    end_proc = find(contains(rel_text,'</ProcessedData>'));
    is_processed = false(length(rel_text),1);
    for i = 1:length(start_proc)
        is_processed(start_proc(i):end_proc(i)) = true;
    end
    start_dat = find(contains(rel_text,'<ArtCurves Count'));
    end_dat = find(contains(rel_text,'</ArtCurves>'));
    is_dat = false(length(rel_text),1);
    start_dat = start_dat(1:length(end_dat));
    for i = 1:length(start_dat)
        is_dat(start_dat(i):end_dat(i)) = true;
    end
    start_y = find(contains(rel_text,'<Y I="0">')&is_processed&is_dat);
    end_y = find(contains(rel_text,'<Y I="197">')&is_processed&is_dat);
    if length(start_y) ~= length(end_y)
        error('There was an issue parsing the ART values. Parse by hand.')
    end
    ART_data = [cell2table(repmat([{sub},{vis}],length(start_y),1),'VariableNames',{'Subject','Visit'}),...
        array2table(NaT(length(start_y),1),'VariableNames',{'Date'}),...
        cell2table(cell(length(start_y),1),'VariableNames',{'StimRecElectrode'}),...
        array2table(NaN(length(start_y),2),'VariableNames',{'Current_cu','Duration_us'}),...
        cell2table(cell(length(start_y),2),'VariableNames',{'Time_us','Voltage_mV'})];
    for i = 1:length(start_y)
        %Date
        date_str = rel_text{find(contains(rel_text(1:start_y(i)),'CreateDate'),1,'last')};
        date = datetime(date_str(strfind(date_str,'CreateDate')+(12:30)),'Format','yyyy-MM-dd HH:mm:ss');
        ART_data.Date(i) = date;
        %Stimulating/Recording Electrode
        stimE_str = rel_text{find(contains(rel_text(1:start_y(i)),'StimulatingElectrode'),1,'last')};
        recE_str = rel_text{find(contains(rel_text(1:start_y(i)),'RecordingElectrode'),1,'last')};
        stimrecE = ['S',extractXMLdataline(stimE_str),'R',extractXMLdataline(recE_str)];
        ART_data.StimRecElectrode{i} = stimrecE;
        %Current Amplitude
        amp_str = rel_text{find(contains(rel_text(1:start_y(i)),{'Amplitude','Probe Unit'})&contains(rel_text(1:start_y(i)),'cu'),1,'last')};
        amp = str2double(extractXMLdataline(amp_str));
        ART_data.Current_cu(i) = amp;
        %Phase Duration
        dur_str = rel_text{find(contains(rel_text(1:start_y(i)),'PhaseDuration'),1,'last')};
        dur = str2double(extractXMLdataline(dur_str))*10^6;
        ART_data.Duration_us(i) = dur;
        %X Data
        start_x = find(contains(rel_text(1:start_y(i)),'<X I="0">'),1,'last');
        end_x = find(contains(rel_text(1:start_y(i)),'<X I="197">'),1,'last');
        x_vec = str2double(cellfun(@extractXMLdataline,rel_text(start_x:end_x),'UniformOutput',false))*10^6;
        ART_data.Time_us(i) = {x_vec};
        %Y Data
        y_vec = str2double(cellfun(@extractXMLdataline,rel_text(start_y(i):end_y(i)),'UniformOutput',false))*10^3;
        ART_data.Voltage_mV(i) = {y_vec};
    end
    save([Maestro_Path,filesep,'ART-Results.mat'],'ART_data')
    if make_plots
        % Make ART plots
        durs = unique(ART_data.Duration_us);
        for d = 1:length(durs)
            sub_ART = ART_data(ART_data.Duration_us == durs(d),:);
            elecs = unique(sub_ART.StimRecElectrode);
            for e = 1:length(elecs)
                ART_tab = sub_ART(contains(sub_ART.StimRecElectrode,elecs(e)),:);
                fig_title = [sub,' ',vis,' ART ',num2str(durs(d)),'us ',elecs{e}];
                curr_lab = strcat(strrep(cellstr(num2str(ART_tab.Current_cu)),' ',''),'cu');
                fig = figure(1);
                set(fig,'Color',[1,1,1]);
                hold on
                for i = 1:length(curr_lab)
                    plot(ART_tab.Time_us{i},ART_tab.Voltage_mV{i})
                end
                hold off
                xlabel('Time (\mus)')
                ylabel('Voltage (mV)')
                title(fig_title)
                legend(curr_lab,'location','northeast')
                savefig(fig,[Maestro_Path,filesep,strrep(fig_title,' ','-'),'.fig'])
                saveas(fig,[Maestro_Path,filesep,strrep(fig_title,' ','-'),'.png'])
                close;
            end
        end
    end
    date_ART = char(min(ART_data.Date));
else
    date_ART = '';
end
%% Save CRF
CRF_path = [Maestro_Path(1:(strfind(Maestro_Path,'Study')-1)),'CRFs',filesep];
subject = sub;
visit = strrep(vis,'Visit','Visit ');
source_path = cd;
dateval = [date_IFT,', ',date_ART];
ART_msg = 'Collected';
if isempty(date_ART)
    ART_msg = 'Not collected; test optional--not a protocol deviation';
    dateval = dateval(1:end-2);
end
switch subject
    case {'MVI011R031','MVI012R897','MVI013R864'}
        fold = 'IRB00335294 NIDCD';
    case {'MVI014R1219','MVI015R1209','R164','R1054'}
        fold = 'IRB00346924 NIA';
    otherwise %old protocol for MVI1-10 and R205
        fold = 'NA_00051349';
end
protocol = strrep(strrep(fold,' NIA',''),' NIDCD','');
visit_fold = extractfield(dir([CRF_path,fold,filesep,subject,filesep,visit,' *-*']),'name');
if isempty(visit_fold) %Non typical visit name found
    visit_fold = {'Visit Nx - (Day XXX) Monitor - X yrs Post-Act - visit applicable only if device still act'};
end
out_path = [CRF_path,fold,filesep,subject,filesep,visit_fold{:},filesep,...
    '14_06 eIFT_eCAP',filesep,'14_06_CRF_eIFT_eCAP_',subject,'_',visit];
% Make text
CRF_txt = ['Case Report Form Protocol: ',protocol,newline,...
    'Case Report Form Version: 2024-03-29',newline,...
    'Case Report Form Test: eIFT, eCAP',newline,...
    'Subject ID: ',subject,newline,'Visit: ',visit,newline,...
    'eIFT: Collected',newline,'eCAP: ',ART_msg,newline,...
    'Examiners: ',examiner,newline,'Times: ',dateval,newline,'Source Data: ',source_path];
%Make the figure that will be used for the PDFs (single page)
fig = figure(1);
set(fig,'Units','inches','Position',[1 1 8.5 11],'Color','w');
clf;
annotation('textbox','Position',[0 0 1 1],'EdgeColor','none','String',CRF_txt,'FitBoxToText','on','Interpreter', 'none')
saveas(fig,[out_path,'.pdf'])
end