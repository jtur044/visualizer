classdef configurator < handle
    %CONFIGURATOR A class for loading configuration information from JSON 
    %
        
    properties        
        baseDirectory = [];        
        configObj     = [];
        configFile    = [];
        
        path = [];
        basename = [];
        ext = [];
    end
    
    methods
        
        function obj = configurator(configFile)
            obj.configObj  = loadjson(configFile); 
            obj.configFile = configFile;
            [obj.path, obj.basename, obj.ext] = fileparts(configFile);
            if (~isfield(obj.configObj, 'baseDirectory'))
               obj.configObj.baseDirectory = obj.path;
            end
        end

        function ret = getconfigstruct(obj)
           ret = obj.configObj;             
        end       
        
        function prettyprint(obj)
            printstruct(obj.configObj)
        end
        
    end
    
end

