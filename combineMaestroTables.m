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
for i = 1:length(MaestroDir)        
    if isfile([MaestroDir{i},filesep,'IFT-Results.mat'])
        load([MaestroDir{i},filesep,'IFT-Results.mat'],'impedance_data') 
        is_IFT = impedance_data.Current_cu==302.4&impedance_data.Duration_us==26.67;
        all_IFT_tabs{i} = impedance_data(is_IFT,:);
        all_eIFT_tabs{i} = impedance_data(~is_IFT,:);
    end
    if isfile([MaestroDir{i},filesep,'ART-Results.mat'])
        load([MaestroDir{i},filesep,'ART-Results.mat'],'ART_data')
        all_ART_tabs{i} = ART_data;
    end   
end
maestro_data.IFT = sortrows(sortrows(vertcat(all_IFT_tabs{:}),'Date','Ascend'),'Subject','Ascend');
maestro_data.eIFT = sortrows(sortrows(vertcat(all_eIFT_tabs{:}),'Date','Ascend'),'Subject','Ascend');
maestro_data.ART = sortrows(sortrows(vertcat(all_ART_tabs{:}),'Date','Ascend'),'Subject','Ascend');
save([MVI_path,filesep,'ALLMVI-MaestroResults.mat'],'maestro_data')
end