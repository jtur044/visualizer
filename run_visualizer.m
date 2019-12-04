function run_visualizer(varargin)

% RUN_VISUALIZER Create a video with overlayed video from config file 
%
% run_visualizer(strConfigFile, 'Param', Value, ...)
%
% where 
%       strConfigFile is a cell array of config. files for the graph 
%       followed by parameters to override 
%
%
%

if (nargin == 0)  % ... default test file 
    varargin{1} = './data/Konan/config_displacement.json';
end

if  (nargin == 1) %% A CONFIGURATION FILENAME IS PASSED 
    
    
    if (ischar(varargin{1}))
    
        strConfigFile = varargin{1};    
        Config = Configurator(strConfigFile);  
        if (length(varargin) > 1)
           Config.add(varargin{2:end});
        end

        [myPath, myBaseName, ~] = fileparts(strConfigFile);    
        if (~isfield(Config.Result, 'baseDirectory'))    
            Config.Result.baseDirectory = myPath;
        end
    
    else
        Config.Result = varargin{1};
    end
    
    %% Ignore information
    if (isfield(Config.Result, 'IgnoreIfExists'))
       if (Config.Result.IgnoreIfExists)
           if (exist(fullfile(Config.Result.baseDirectory,Config.Result.outputVideo),'file'))
               fprintf('Ignore Existing ... %s\n', Config.Result.outputVideo);
               return
           end
       end 
    end
    
    
    hasCDPReport = false;
    if (isfield(Config.Result, 'CDPFile'))    
        hasCDPReport = true;
    end
    
    if (hasCDPReport)
        generate_visualizer_video(Config.Result);        
    else
        generate_single_visualizer_video(Config.Result);    
    end

elseif (nargin ==3) %% A CDPFILE, A VIDEO FILE, A CONFIG FILE,       
    
    Config = varargin{3};
    
    hasCDPReport = false;
    if (isfield(Config, 'CDPfile'))    
        hasCDPReport = true;
    end
        
    if (hasCDPReport)
        generate_visualizer_video(Config);        
    else
        generate_single_visualizer_video(Config);    
    end
    
elseif (isstruct(varargin{1}))    
    
    Result = varargin{1};        
    if (isfield(Result,'CDPFile'))    
        generate_visualizer_video(Result);        
    else
        generate_single_visualizer_video(Result);            
    end
    
else
    error('No valid input information.');
end

end

%{
N = length(strConfigFile);
for k = 1:N
    
 fprintf('Processing ... %s\n', strConfigFile{k});
 
 close all;  
 Config = Configurator(strConfigFile{k});
 Config.add(varargin{:});  % optional parameters
 generate_visualizer_video(Config.Result);
 
end

end
%}
