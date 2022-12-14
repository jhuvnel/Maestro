function processMaestroXML(Maestro_Path,make_plots)
if nargin < 2 ||~isnumeric(make_plots)
    make_plots = 1; %Default is to plot
end
if nargin < 1 ||isempty(Maestro_Path)
    prompt = 'Select the Maestro folder.';
    Maestro_Path = uigetdir(prompt,prompt);
end
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
    names = cell(length(exp_start),1);
    rm_row = false(length(exp_start),1);
    % Start the text file with the info
    txt = ['Impedance Measurement (MVI)',newline,newline];
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
            exp_name = date_str((strfind(date_str,'Name=')+6):(strfind(date_str,'Creating')-3));
            names{i} = [exp_name,': ',num2str(str2double(dur)*10^6),'us, ',curr,'cu'];
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
    names(rm_row) = [];
    save([Maestro_Path,filesep,'IFT-Results.mat'],'impedance_data')
    names = join(names,newline);
    txt = [txt,names{:}];
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
else
    txt = '';
end
%% ART
ART_names = find(contains(fdata,'ArtData Create'));
if ~isempty(ART_names) % no ART
    txt = [txt,newline,newline,'eCAP/ART Measurements',newline,newline];
    names = cell(length(ART_names),1);
    for i = 1:length(ART_names)
        rel_text = fdata(ART_names(i)+(0:50));
        rel_str = rel_text{1};
        exp_name = rel_str((strfind(rel_str,'Name=')+6):(strfind(rel_str,'Creating')-3));
        if any(contains(rel_text,'Setup FunctionType="AmplitudeGrowth"')) %Classic Amplitude Growth ART
            max_curr = extractXMLdataline(rel_text{contains(rel_text,'Maximum')});
            min_curr = extractXMLdataline(rel_text{contains(rel_text,'Minimum')});
            phase_dur = num2str(str2double(extractXMLdataline(rel_text{contains(rel_text,'PhaseDuration')}))*10^6);
            iter = extractXMLdataline(rel_text{contains(rel_text,'Iterations')});
            meas_delay = num2str(str2double(extractXMLdataline(rel_text{contains(rel_text,'MeasurementDelay')}))*10^6);
            meas_gap = num2str(str2double(extractXMLdataline(rel_text{contains(rel_text,'MeasurementGap')}))*10^3);
            rel_str = rel_text{contains(rel_text,'AmplitudeLevels')};
            amp_lev = rel_str((strfind(rel_str,'Count=')+7):(strfind(rel_str,'>')-2));
            names{i} = [exp_name,newline,...
                'Max Amp. = ',max_curr,'cu',newline,...
                'Min Amp. = ',min_curr,'cu',newline,...
                'Phase Dur. = ',phase_dur,'us',newline,...
                'Iterations = ',iter,newline,...
                'Measurement Delay = ',meas_delay,'us',newline,...
                'Measurement Gap = ',meas_gap,'ms',newline,...
                'Levels = ',amp_lev,newline];
        elseif any(contains(rel_text,'Masker')) %Masker/Probe type
            mask_curr = extractXMLdataline(rel_text{contains(rel_text,'Masker Unit')});
            probe_curr = extractXMLdataline(rel_text{contains(rel_text,'Probe Unit')});
            phase_dur = num2str(str2double(extractXMLdataline(rel_text{contains(rel_text,'PhaseDuration')}))*10^6);
            iter = extractXMLdataline(rel_text{contains(rel_text,'Iterations')});
            meas_delay = num2str(str2double(extractXMLdataline(rel_text{contains(rel_text,'MeasurementDelay')}))*10^6);
            meas_gap = num2str(str2double(extractXMLdataline(rel_text{contains(rel_text,'MeasurementGap')}))*10^3);
            names{i} = [exp_name,newline,...
                'Masker Amp. = ',mask_curr,'cu',newline,...
                'Probe Amp. = ',probe_curr,'cu',newline,...
                'Phase Dur. = ',phase_dur,'us',newline,...
                'Iterations = ',iter,newline,...
                'Measurement Delay = ',meas_delay,'us',newline,...
                'Measurement Gap = ',meas_gap,'ms',newline];
        elseif any(contains(rel_text,'Setup FunctionType="AdvancedSetup"'))
            amp_curr = extractXMLdataline(rel_text{contains(rel_text,'Amplitude Unit')});
            phase_dur = num2str(str2double(extractXMLdataline(rel_text{contains(rel_text,'PhaseDuration')}))*10^6);
            meas_delay = num2str(str2double(extractXMLdataline(rel_text{contains(rel_text,'MeasurementDelay')}))*10^6);
            meas_gap = num2str(str2double(extractXMLdataline(rel_text{contains(rel_text,'MeasurementWindow')}))*10^3);
            names{i} = [exp_name,newline,...
                'Current Amp. = ',amp_curr,'cu',newline,...
                'Phase Dur. = ',phase_dur,'us',newline,...
                'Measurement Delay = ',meas_delay,'us',newline,...
                'Measurement Window = ',meas_gap,'ms',newline];
        end
    end
    names = join(names,newline);
    txt = [txt,names{:},newline];
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
end
%% Save .txt file
%Write the text file and end the script
fid = fopen([Maestro_Path,filesep,'SubjectInfo.txt'],'w');
fprintf(fid,'%s',txt);
fclose(fid);
end