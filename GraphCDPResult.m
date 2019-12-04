classdef GraphCDPResult < GraphResult
    
    %GraphCDPResult A derived class for displaying CDP video overlay
       
    
    properties (Access = 'public')         
        PupilXField  = '';
        PupilYField  = '';
        PupilVxField = '';
        PupilVyField = '';           
    end    
    
    methods
        
        
        
        
        function obj = GraphCDPResult(dataSource, inputFields)    
            obj = obj@GraphResult(dataSource, inputFields);
        end

        function [result, nIndex] = getCurrentData(obj)           
            result = []; nIndex = [];
            if (~isnan(obj.pointerIndex))
                nIndex = obj.pointerIndex;
                result = obj.currentData(nIndex,:);                                
            end            
        end
        
        function ret = getCurrentDataFrame(obj, start_time, end_time)        
            i = ( start_time < obj.Time & end_time < obj.Time );
            ret = obj.inputTable(i,:);
        end
            
        function [pupilX, pupilY] = getPupil(obj)         
            myTime = obj.pointerTime;
            [flag, i] = hasTime(obj, myTime, obj.Time);
            if (flag)
               nIndex = find(i, 1);
               pupilX          = obj.PupilX(nIndex); 
               pupilY          = obj.PupilY(nIndex);                
               %obj.currentData = obj.inputTable(nIndex, :);               
            else
               pupilX          = nan;
               pupilY          = nan;
               %obj.currentData = []; %obj.inputTable(nIndex, :);               
            end            
        end

        function setInputFields(obj, InputFields)                   
            obj.PupilXField  = InputFields.PupilX;
            obj.PupilYField  = InputFields.PupilY;
            obj.PupilVxField = InputFields.PupilVx;
            obj.PupilVyField = InputFields.PupilVy;            
        end                    
        
        function readFrom(obj, dataSource, inputFields)            
            if (ischar(dataSource))
                obj.inputTable = readtable(dataSource);
            elseif (istable(dataSource))
                obj.inputTable = dataSource;                
            end
            
            setInputFields(obj, inputFields);
            
            obj.Time            = obj.inputTable.Time;
            obj.PupilX          = obj.inputTable.(obj.PupilXField);
            obj.PupilY          = obj.inputTable.(obj.PupilYField);
            obj.PupilVx         = obj.inputTable.(obj.PupilVxField);            
            obj.PupilVy         = obj.inputTable.(obj.PupilVyField);            
            updateData(obj);            
        end
    
    end
    
end

