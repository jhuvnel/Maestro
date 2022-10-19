%% MDA.m
% Maestro Data Analyzer
%
%A list-based script that allowed for using the full functionality of the
%rest of the scripts/functions in this repository.
%MDA Menu Options
opts = {'Process Maestro XML','Make Summary File (existing)',...
    'Make Summary File (rerun without plots)',...
    'Make Summary File (rerun with plots)',...
    'Plot MVI IFT'};
resp1 = '';
tf1 = 1;
MVI_path = '';
while tf1
    switch resp1
        case 'Process Maestro XML'
            processMaestroXML;
        case 'Make Summary File (existing)'
            [maestro_data,MVI_path] = combineMaestroTables(MVI_path);
        case  'Make Summary File (rerun without plots)'
            MVI_path = rerunAllMaestro(MVI_path,0);
            [maestro_data,MVI_path] = combineMaestroTables(MVI_path);
        case 'Make Summary File (rerun with plots)'
            MVI_path = rerunAllMaestro(MVI_path,1);
            [maestro_data,MVI_path] = combineMaestroTables(MVI_path);
        case 'Plot MVI IFT'
            
    end
    % Poll for new reponse
    [ind1,tf1] = listdlg('PromptString','Select an action:','SelectionMode','single',...
                       'ListSize',[150 200],'ListString',opts); 
    if tf1
        resp1 = opts{ind1}; 
    end
end
disp('QOLA instance ended.')