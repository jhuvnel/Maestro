function [maestro_data,MVI_path] = combineMaestroTables(MVI_path)
if nargin < 1 || isempty(MVI_path)
    prompt = 'Select the MVI Study subject root folder.';
    MVI_path = uigetdir(prompt,prompt);
    if ~contains(MVI_path,'MVI')
        disp(['The selected path does not contain the text "MVI", so it may be wrong: ',MVI_path])
    end
end
MaestroDir = unique(extractfield(dir([MVI_path,filesep,'MVI*_R*',filesep,'Visit*',filesep,'Maestro']),'folder'));
all_IFT_tabs = cell(length(MaestroDir),1);
all_eIFT_tabs = cell(length(MaestroDir),1);
all_ART_tabs = cell(length(MaestroDir),1);
extra_IFT_tabs = cell(length(MaestroDir),1);
extra_eIFT_tabs = cell(length(MaestroDir),1);
extra_ART_tabs = cell(length(MaestroDir),1);
extraIFT = 1;
extraART = 1;
for i = 1:length(MaestroDir)  
    if isfile([MaestroDir{i},filesep,'IFT-Results.mat'])
        load([MaestroDir{i},filesep,'IFT-Results.mat'],'impedance_data') 
        is_IFT = impedance_data.Current_cu==302.4&impedance_data.Duration_us==26.67;
        all_IFT_tabs{i} = impedance_data(is_IFT,:);
        all_eIFT_tabs{i} = impedance_data(~is_IFT,:);
    end
    if isfile([MaestroDir{i},filesep,'\Preactivation\IFT-Results.mat'])
        load([MaestroDir{i},filesep,'\Preactivation\IFT-Results.mat'],'impedance_data') 
        is_IFT = impedance_data.Current_cu==302.4&impedance_data.Duration_us==26.67;
        extra_IFT_tabs{extraIFT} = impedance_data(is_IFT,:);
        extra_eIFT_tabs{extraIFT} = impedance_data(~is_IFT,:);
        extraIFT = extraIFT + 1;
        if isfile([MaestroDir{i},filesep,'\Preactivation\ART-Results.mat'])
            load([MaestroDir{i},filesep,'\Preactivation\ART-Results.mat'],'ART_data')
            extra_ART_tabs{extraART} = ART_data;
            extraART = extraART + 1;
        end
    end
    if isfile([MaestroDir{i},filesep,'\Postactivation\IFT-Results.mat'])
        load([MaestroDir{i},filesep,'\Postactivation\IFT-Results.mat'],'impedance_data') 
        is_IFT = impedance_data.Current_cu==302.4&impedance_data.Duration_us==26.67;
        extra_IFT_tabs{extraIFT} = impedance_data(is_IFT,:);
        extra_eIFT_tabs{extraIFT} = impedance_data(~is_IFT,:);
        extraIFT = extraIFT + 1;
        if isfile([MaestroDir{i},filesep,'\Postactivation\ART-Results.mat'])
            load([MaestroDir{i},filesep,'\Postactivation\ART-Results.mat'],'ART_data')
            extra_ART_tabs{extraART} = ART_data;
            extraART = extraART + 1;
        end
    end

    if isfile([MaestroDir{i},filesep,'ART-Results.mat'])
        load([MaestroDir{i},filesep,'ART-Results.mat'],'ART_data')
        all_ART_tabs{i} = ART_data;
    end       
end
all_IFT_tabs = cat(1, all_IFT_tabs, extra_IFT_tabs);
all_eIFT_tabs = cat(1, all_eIFT_tabs, extra_eIFT_tabs);
all_ART_tabs = cat(1, all_ART_tabs, extra_ART_tabs);
temp = sortrows(vertcat(all_IFT_tabs{:}),'Date','Ascend');
[~,ind] = unique(temp);
maestro_data.IFT = sortrows(sortrows(temp(ind,:),'Date','Ascend'),'Subject','Ascend');
temp = sortrows(vertcat(all_eIFT_tabs{:}),'Date','Ascend');
[~,ind] = unique(temp);
maestro_data.eIFT = sortrows(sortrows(temp(ind,:),'Date','Ascend'),'Subject','Ascend');
maestro_data.ART = sortrows(sortrows(vertcat(all_ART_tabs{:}),'Date','Ascend'),'Subject','Ascend');
save([MVI_path,filesep,'ALLMVI-MaestroResults.mat'],'maestro_data')
end