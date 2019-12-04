classdef GraphResult < handle
    %GRAPHRESULT A class with abstract methods for displaying video overlay
    %
    % 
    
    
    properties
        
        % table 
        inputTable = []; 
        
        % coordinates 
        Time        = [];        
        PupilXIm = [];
        EyeCnrX = [];
        PupilX = [];
        PupilY = [];     % sneaky one !!! 
        PupilVx = [];       
        PupilVy = [];            
        
        % markers 
        MarkerX  = [];
        MarkerVx = [];
        
        diffX    = [];
        diffVx   = [];
        diffTime = [];
        
        hasTimeInterval = false;
        start_time = 0;
        end_time   = inf;
                
        VelocityRange       = 60;
        VelocityOffset      = 0.0;
        VelocityLim         = [ -30 +30 ];
        VelocityLineColor       = 'g';
        
        DisplacementOffset  = 0.5;  
        DisplacementRange   = 4;
        DisplacementLim     = [ -2 2 ];
        DisplacementLineColor   = 'm';
                
        pointerTime  = 0.0;
        pointerX     = 0.0;
        pointerVx    = 0.0;     
        pointerIndex = nan;
        
        MarkerColor = 'y';
        SizeData    = 100;
        
        XAxisColor = 'w';
        GraphFontSize = 20;
        
        VelocityVisible        = 'on';
        DisplacementVisible    = 'on';
        
        isReady = false;
        
        showVelocity = true;
        showDisplacement = true;    
        showPointer = true;
                
        isPointerVisible = false;        
        
        currentData = [];
        
    end
    
    properties
        
        frameRate = 30; % FPS  
    end
    
    methods (Static)

        function changeLimit(range, offset)
            range = [ -range/2 range/2 ] + offset;
            ylim(range); 
        end

        
        function diffX = ZeroSignalAfterNan(diffX)

            offset     = diffX(1);
            for k = 2:length(diffX)   
                lastDiffX = diffX(k-1);
                currDiffX = diffX(k);
                if (isnan(lastDiffX) && isfinite(currDiffX))
                    offset = diffX(k);
                    diffX(k) = 0;
                else
                    diffX(k) = diffX(k) - offset;
                end
            end
        end
        
        
    end
    
    methods 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %
        % SETTERS - DISPLACEMENT / VELOCITY 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function set.showDisplacement(obj, value)               
                last = obj.showDisplacement;                
                if (value == last)
                    return
                end
                
                obj.showDisplacement = value;                                
                drawGraphs(obj);                
        end
        
        function set.showVelocity(obj, value)
                last = obj.showVelocity; 
                if (value == last)
                    return
                end
            
                obj.showVelocity = value;                                
                drawGraphs(obj);                               
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %
        % DRAW GRAPHS 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function drawGraphs(obj)
            
            if      (obj.showDisplacement) % show it !
                    f = gcf; %clf; 
                    f.Color = 'k';                    
                    yyaxis left;
                    showVelocityGraph(obj);                    
                    yyaxis right;
                    showDisplacementGraph(obj);                 
                    setPointer(obj);
            elseif (obj.showVelocity)                    
                    % default is to show velocity graph                         
                    f = gcf; %clf; 
                    f.Color = 'k';  
                    showVelocityGraph(obj);              
                    setPointer(obj);
            else
                 error('cant turn off velocit ygraph currently.');
            end
                

        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %
        % SUPPLEMENTARY INFORMATION  
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        
        function set.VelocityOffset(obj, value)
            obj.VelocityOffset = value;
            updateLimits(obj);
        end
        
        
        function set.DisplacementOffset(obj, value)
            obj.DisplacementOffset =value;
            updateLimits(obj);
        end
        
        function set.VelocityRange(obj, value)
            obj.VelocityRange = value;
            updateLimits(obj);
        end
                
        function set.DisplacementRange(obj, value)
            obj.DisplacementRange =value;
            updateLimits(obj);
        end   
        
        function set.DisplacementVisible(obj, value)
            obj.DisplacementVisible =value;
            updateLimits(obj);
        end   
        
        function set.VelocityVisible(obj, value)
            obj.VelocityVisible =value;
            updateLimits(obj);
        end   
        
    end
    
    
    methods (Abstract) 
        
        readFrom(obj, dataSource)
        
    end 
    
    methods
        
        function obj = GraphResult(strInputFile, inputFields) 
                        
            readFrom(obj, strInputFile, inputFields);
                       
            obj.showVelocity     = true;
            obj.showDisplacement = false;
            drawGraphs(obj);
            %showVelocityGraph(obj);
        end
        
        function updateData(obj)
            
            % ...version of data for graphing
            obj.diffX               = GraphResult.ZeroSignalAfterNan(obj.PupilX); 
            obj.diffVx              = obj.PupilVx;             
            obj.diffTime            = obj.Time;
 
            % ... time interval
            i = (obj.start_time <=  obj.Time  & obj.Time <= obj.end_time);
            obj.diffX               = obj.diffX(i);
            obj.diffVx              = obj.diffVx(i);
            obj.diffTime            = obj.Time(i);
            
            obj.currentData         = obj.inputTable(i,:);
            
            % ... correct velocity 
            %obj.VelocityLim         = [ -obj.VelocityRange/2 obj.VelocityRange/2 ] + obj.VelocityOffset; 
            %obj.DisplacementLim     = [ -obj.DisplacementRange/2 obj.DisplacementRange/2 ] + obj.DisplacementOffset;             
            %myGraph.setTimeInterval(currstep.start_time, currstep.end_time);            

        end
        
        function updateLimits(obj)

            % ... correct velocity 
            obj.VelocityLim         = [ -obj.VelocityRange/2 obj.VelocityRange/2 ] + obj.VelocityOffset; 
            obj.DisplacementLim     = [ -obj.DisplacementRange/2 obj.DisplacementRange/2 ] + obj.DisplacementOffset;
            
            if (obj.showDisplacement)                
                yyaxis right; ax = gca; 
                ax.YTick = linspace(obj.DisplacementLim(1), obj.DisplacementLim(2), 5);
                ylim(obj.DisplacementLim);                
                yyaxis left;
                ylim(obj.VelocityLim);                
             end
                
             if (obj.showVelocity)    
                ax = gca; 
                ax.YTick = linspace(obj.VelocityLim(1), obj.VelocityLim(2), 5);
                ylim(obj.VelocityLim);
             end
        end
        
        %{        
        function readFrom(obj, dataSource)
            
            if (ischar(dataSource))
                obj.inputTable = readtable(dataSource);
            elseif (istable(dataSource))
                obj.inputTable = dataSource;                
            end
            
            obj.Time            = obj.inputTable.Time;
            obj.PupilX          = obj.inputTable.pupilXIm;
            obj.EyeCnrX         = obj.inputTable.eyeCnrX;
            obj.PupilX          = obj.inputTable.pupilX;
            obj.PupilVx         = obj.inputTable.pupilVx;            
            
            updateData(obj);            
        end
        %}
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %
        % SET TIME INTERVAL   
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function setTimeInterval(obj, start_time, end_time) 
            obj.hasTimeInterval = true;
            obj.start_time = start_time;
            obj.end_time   = end_time;            
            updateData(obj);  
            drawGraphs(obj);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %
        % SET POINTER  
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       
        function [flag, i] = hasTime(obj, myTime, varargin)
            
            if (nargin == 3)
                timeList = varargin{1};
            else
                timeList = obj.diffTime;
            end
            
            delta  = 1/obj.frameRate;
            e = abs(myTime - timeList);
            [~,nIndex] = min(e); % < delta;                             
            if (e(nIndex) < delta)
                flag = true;                
                i         = e*0;
                i(nIndex) = 1;
            else
                flag = false;
                i         = e*0;            
            end
        end
        
        function ret = getDisplacement(obj, myTime)
           
            ret = [];
            [flag, i] = hasTime(obj, myTime);            
            if (flag)
                ret = obj.diffX(logical(i)); 
            end    
        end
        
        function setPointer(obj, myTime)
            
            if (~obj.showPointer)               
                return
            end
            
            delta     = 1/obj.frameRate;
            diffTime  = obj.diffTime;
            diffX     = obj.diffX;
            diffVx    = obj.diffVx;
            
            if (nargin == 1)
                myTime = obj.pointerTime;
            end
            
            [isFound, i] = hasTime(obj, myTime); % - diffTime) < delta;    
            if (isFound)
                                
                nIndex   = find(i, 1);
                myTime   = diffTime(nIndex);
                mydiffX  = diffX(nIndex);
                mydiffVx = diffVx(nIndex);  

                obj.pointerIndex = nIndex;
                obj.pointerTime  = myTime;
                obj.pointerX     = mydiffX;
                obj.pointerVx    = mydiffVx;
                                
                if (obj.showDisplacement)                
                    yyaxis right;                    
                    obj.MarkerX.XData  = myTime;                               
                    obj.MarkerX.YData  = mydiffX;     
                    
                    if (isnan(mydiffX))
                       obj.isPointerVisible = false;
                    else
                       obj.isPointerVisible = true;                        
                    end
                end
                
                if (obj.showVelocity)                     
                    if (obj.showDisplacement)
                        yyaxis left;
                    end                    
                    obj.MarkerVx.XData = myTime;                     
                    obj.MarkerVx.YData = mydiffVx; 
                    
                    if (isnan(mydiffVx))
                       obj.isPointerVisible = false;
                    else
                       obj.isPointerVisible = true;                        
                    end                    
                end
                
            end

        end        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %
        % DRAW TIME 
        %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        
        function showDisplacementGraph(obj)
            
            t           = obj.diffTime;
            diffX       = obj.diffX;
            diffVx      = obj.diffVx;
            Lim         = obj.DisplacementLim;            
            LineColor   = obj.DisplacementLineColor;
            XLineColor  = obj.XAxisColor;
            FontSize    = obj.GraphFontSize;
            MarkerColor = obj.MarkerColor;
            SizeData    = obj.SizeData;

            
            ax1 = gca;            
            l1 = plot(t, diffX); hold on;
            set(l1, 'Tag', 'Displacement');
            set(l1, 'Color', LineColor, 'LineWidth',2);            
            l1 = line([ min(t) max(t) ],[0 0]);
            set(l1, 'Tag', 'Displacement');
            set(l1, 'Color', LineColor, 'LineWidth',2, 'LineStyle','--');
            ylim(Lim); 
            ax1.YTick = linspace(Lim(1), Lim(2), 5);
            ax1.YColor = LineColor; 
            ax1.XColor = XLineColor; 
            ax1.Color = 'k';
            set(ax1,'FontSize', FontSize);
            set(ax1,'Color', 'k');
            
            ylabel('Displacement (px)');
            xlabel('Time (sec)'); 
            line([ 0 inf ],[0 0]);
        
            grid on;
            
            if (obj.hasTimeInterval) 
              xlim([ obj.start_time obj.end_time ]);  
            else
              xlim([ min(obj.diffTime) max(obj.diffTime)]);
            end
            
            % show the marker 
            myTime  = obj.diffTime(1); 
            mydiffX = obj.diffX(1);
            s = scatter(myTime, mydiffX, 'o');
            s.MarkerFaceColor = MarkerColor;
            s.MarkerEdgeColor = MarkerColor;
            s.SizeData        = SizeData;
            obj.MarkerX = s;
            
        end
        
        function showVelocityGraph(obj)
            
            t           = obj.diffTime;
            diffX       = obj.diffX;
            diffVx      = obj.diffVx;
            Lim         = obj.VelocityLim;
            LineColor   = obj.VelocityLineColor;
            XLineColor  = obj.XAxisColor;
            FontSize    = obj.GraphFontSize;
            SizeData    = obj.SizeData;
            MarkerColor = obj.MarkerColor;
            
            f = gcf; 
            f.Color = 'k';
            
            ax2 = gca;
            l1 = plot(t, diffVx); hold on;
            set(l1, 'Tag', 'Velocity');
            set(l1, 'Color', LineColor, 'LineWidth',2);

            l1 = line([ min(t) max(t) ],[0 0]);
            set(l1, 'Tag', 'Velocity');
            set(l1, 'Color', LineColor, 'LineWidth',2, 'LineStyle','--');
            ylim(Lim); 
            ax2.YTick  = linspace(Lim(1), Lim(2), 5);
            ax2.YColor = LineColor; 
            ax2.XColor = LineColor; % XLineColor; 
            set(ax2,'FontSize', FontSize);
            set(ax2,'Color', 'k');

            ylabel('Velocity (px/sec)');
            xlabel('Time (sec)');       
            
            if (obj.hasTimeInterval) 
              xlim([ obj.start_time obj.end_time ]);  
            else
              xlim([ min(obj.diffTime) max(obj.diffTime)]);
            end            
            grid on;
            
            myTime   = obj.diffTime(1); 
            mydiffVx = obj.diffVx(1);
            s = scatter(myTime, mydiffVx, 'o');
            s.MarkerFaceColor = MarkerColor;
            s.MarkerEdgeColor = MarkerColor;
            s.SizeData        = SizeData;
            obj.MarkerVx = s;
            
        end
        
  %{      
        function show(obj)
            
            % report.dispVelRange     = 60;
            % report.dispDispRange    = 4;
            % report.VelOffset        = -10;            
            % report.DispOffset       = 0.5;      
            
            obj.VelocityRange       = 60;
            obj.VelocityOffset      = -10.0;
            obj.VelocityLim         = [ -obj.VelocityRange/2 obj.VelocityRange/2 ] + obj.VelocityOffset;                        

            obj.DisplacementRange   = 4;
            obj.DisplacementOffset  = 0.5;       
            obj.DisplacementLim     = [ -obj.DisplacementRange/2 obj.DisplacementRange/2 ] + obj.DisplacementOffset;
                        
            % report.dispDispAxisLim  = [ -report.dispDispRange/2 report.dispDispRange/2 ] + report.DispOffset;
            % report.dispVelAxisLim   = [ -report.dispVelRange/2 report.dispVelRange/2 ] + report.VelOffset;
            % report.green            = [ 0 1 0 ];
            % report.white            = [ 1 1 1 ];
            % report.magenta          = [ 1 0 1 ];
            % report.dispSizeData     = 10;
            % report.dispFontSize     = 20;
            % f = figure(1); clf;             
            
            report.yellow           = [ 1 1 0 ];
            report.SizeData         = 50;            
                        
            obj.diffX  = GraphResult.ZeroSignalAfterNan(obj.PupilX); 
            obj.diffVx = obj.PupilVx;
            
            % initialize 
            myTime   = obj.Time(1);
            mydiffX  = obj.diffX(1);
            mydiffVx = obj.diffVx(1);
            
            
            f = gcf; clf;
            f.Color = 'k';
            
            yyaxis left; % left;
            showVelocityGraph(obj);
            
            yyaxis right;
            showDisplacementGraph(obj);
            
            grid on;
            xlim([ 0 max(obj.Time)]);
            
            yyaxis left;
            s = scatter(myTime, mydiffX, 'o');
            s.MarkerFaceColor = report.yellow;
            s.MarkerEdgeColor = report.yellow;
            s.SizeData        = report.SizeData;
            obj.MarkerX = s;
            
            yyaxis right;
            s = scatter(myTime, mydiffVx, 'o');        
            s.MarkerFaceColor = report.yellow;
            s.MarkerEdgeColor = report.yellow;
            s.SizeData        = report.SizeData;
            obj.MarkerVx = s;

            isReady = true;                        
            update(obj);
            
            
        end
%}
        

        
    end

end

% calculated offsets 
%calculatedoffset(t, diffX, diffVx, limX, limVx);


%% create a data report graph - leave the figure up to move pointer on it   

%g = scatter(t(1), d(1),  'MarkerFaceColor', h(2).YColor, ...
%                         'SizeData',  report.dispSizeData, ...                                    
%                         'MarkerEdgeColor', h(2).YColor); 



%xlabel('Time (sec)');
%h(1).YLabel.String = 'Displacement';           
%h(2).YLabel.String = 'Velocity';    

%outerPositionDifference = get(h(1), 'OuterPosition') - get(h(2), 'OuterPosition');
%rightEdgeShift = outerPositionDifference(1) + outerPositionDifference(3);
%set(h(1), 'OuterPosition', [0, 0, 1-rightEdgeShift, 1]);


        
    

