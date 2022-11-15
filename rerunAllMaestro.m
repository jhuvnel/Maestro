%% Rerun All Maestro
%This function goes into each "Maestro" folder in each MVI study subject's
%Visit folders and uses processMaestroXML.m to reprocess the .xml files it
%finds. This should be used if a change is made to processMaestroXML.m that
%requires re-analysis. The "make_plots" argument will remake the IFT/eFIT
%and ART plots that the function typically makes when true; this will
%increase the running time.
%AA last ran on 2022-10-19 and it took ~11 minutes to run without plot
%making.
function MVI_path = rerunAllMaestro(MVI_path,make_plots)
tic;
if nargin < 1 || isempty(MVI_path)
    prompt = 'Select the MVI Study subject root folder.';
    MVI_path = uigetdir(prompt,prompt);
    if ~contains(MVI_path,'MVI')
        disp(['The selected path does not contain the text "MVI", so it may be wrong: ',MVI_path])
    end
end
if nargin < 2 || ~isnumeric(make_plots)
    make_plots = 0; %Default is to rerun IFT-Results and ART-Results files without plots.
end
MaestroDir = unique(extractfield(dir([MVI_path,filesep,'MVI*_R*',filesep,'Visit*',filesep,'Maestro']),'folder'));
for i = 1:length(MaestroDir)    
    disp(['Folder ',num2str(i),'/',num2str(length(MaestroDir)),': ',MaestroDir{i}])
    processMaestroXML(MaestroDir{i},make_plots)  
    if isfile([MaestroDir{i},filesep,'IFT-Results.mat'])
        %Fix weird bug from the time the huge XML file was turned into all
        %the IFT-Results.mat files in case there is no XML file in the
        %folder    
        load([MaestroDir{i},filesep,'IFT-Results.mat'],'impedance_data') 
        if iscell(impedance_data.E11) 
            impedance_data.E11 = cell2mat(impedance_data.E11);
            save([MaestroDir{i},filesep,'IFT-Results.mat'],'impedance_data') 
        end
    end
end
disp('DONE!')
toc
end