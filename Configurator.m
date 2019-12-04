classdef Configurator < handle
    %CONFIGURATOR A class for loading parameters from a JSON file 
    
    properties        
        baseDirectory   = [];        
        configObj       = [];
        configFile      = [];
        
        useLoadedConfig  = true; 
                
        path          = [];
        basename      = [];
        ext           = [];
        
        Result        = [];
    end
    
    methods (Static)
    
        % Specifically Inheritable
        function Rect = getRectFromString(strInputString, Width, Height)                    
            switch(strInputString)               
                case { 'TopRightQuadrant' }
                    Rect = [ Width/2+1 0+1 Width/2 Height ];   
                case { 'TopLeftQuadrant' }
                    Rect = [ 1 1 Width/2 Height ];   
                case { 'BottomHalf' }
                    Rect = [ 1 Height/2+1 Width Height/2 ];   
                case { 'TopHalf' }
                    Rect = [ 1 1 Width Height/2 ];   
                    
                otherwise
                    fprintf('Defaulting to entire image.\n');
                    Rect = [ 1 1 Width Height ];
            end
        end
    
    end
    
    methods 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % ADDITIONAL FIELDS 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function add(obj, varargin)   
            
            if (length(varargin) < 2)
                return
            end
            
            M = length(varargin) / 2;
            for k = 1:M
                myField = varargin{2*(k-1) + 1};
                myValue = varargin{2*(k-1) + 2};
                obj.Result.(myField) = myValue;                
            end
        end        
    end
    
    methods
        
        function obj = Configurator(configFile)
            obj.Result  = loadjson(configFile); 
            obj.configFile = configFile;
            [obj.path, obj.basename, obj.ext] = fileparts(configFile);
            if (~isfield(obj.Result, 'baseDirectory'))
               obj.Result.baseDirectory = obj.path;
            end
        end

        function SetLoadedConfig(State)
            obj.useLoadedConfig = State;
        end
        
        function Results = GetConfig(obj, strField, p, varargin) 
            
            % override the parsed fields with loaded fields                         
            p.parse(varargin{:});
            Results = p.Results;                        
            if (obj.useLoadedConfig)
                eval([ 'overResults = obj.Result.' strField ';' ]);               
                overFieldnames = fieldnames(overResults);
                for k = 1:length(overFieldnames)
                    Results.(overFieldnames{k}) = overResults.(overFieldnames{k}); 
                end
            end
        end
            
        %function ret = getconfigstruct(obj)
        %   ret = obj.configObj;             
        %end       
        
        function prettyprint(obj)
            disp('/*-------------------------------------------------------*/');
            printstruct(obj.Result);
            disp('/*-------------------------------------------------------*/');
        end
        
    end
    
end

