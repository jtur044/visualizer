function generate_single_visualizer_video(report)

% GENERATE_SINGLE_VISUALIZER_VIDEO Create a video with a graph overlay  
%
% generate_single_visualizer_video(report)
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add base directory  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all;

if (isfield(report, 'baseDirectory'))
    reportDir = report.baseDirectory;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% READ THE DATA SOURCE 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
report.datareport     = readtable(fullfile(reportDir,report.datafile));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PEAKS ON THE PLOT 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hasPointsReport = false;
if (isfield(report,'PointsFile'))
    %% TODO : MAKE IT RELATIVE EVENTUALLY
    report.pointsReport = readtable(report.PointsFile);    
    if (~isempty(report.pointsReport))    
        hasPointsReport  = true;
    end
    fprintf('loaded points .... %s\n', report.PointsFile);    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBJECTIVE REPORT 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hasSubjective  = false;
if (isfield(report,'Subjective'))    
   if (report.Subjective.useSubjective) 
    report.subjectiveReport = readtable(fullfile(reportDir,report.Subjective.DataFile));    
    if (~isempty(report.subjectiveReport))    
        hasSubjective  = true;
    end
    fprintf('loaded subjective report .... %s\n', report.Subjective.DataFile);
   end 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HASPUPIL OVERLAY   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hasPupilTracking = false;
if (isfield(report, 'Tracked'))    
    if (isfield(report.Tracked, 'PupilX') && isfield(report.Tracked, 'PupilY') )
        hasPupilTracking = true;
    end    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SHOW REPORT  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

videoRead     = VideoReader(fullfile(reportDir, report.mainVideo));
height        = videoRead.Height; 
width         = videoRead.Width;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VIDEOWRITER   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

videoFWriter = vision.VideoFileWriter(fullfile(reportDir, report.outputVideo),'FileFormat','MPEG4','FrameRate',videoRead.FrameRate);
videoFWriter.Quality = 90;
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN - CDPREPORT DRIVEN 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

myGraph = GraphCDPResult(report.datareport, report.InputFields);         
myGraph.showVelocity        = report.Graph.showVelocity;
myGraph.showDisplacement    = report.Graph.showDisplacement;
myGraph.DisplacementOffset  = report.Graph.DisplacementOffset;
myGraph.DisplacementRange   = report.Graph.DisplacementRange;
myGraph.VelocityOffset      = report.Graph.VelocityOffset;
myGraph.VelocityRange       = report.Graph.VelocityRange;

f = gcf;

while(hasFrame(videoRead)) 
    
    videoFrame = im2uint8(readFrame(videoRead));   
    
    if (~isempty(myGraph.hasTime(videoRead.CurrentTime)))

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
        % GET CURRENT IMAGE OF GRAPH 
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        myGraph.setPointer(videoRead.CurrentTime);
        Im  = frame2im(getframe(f));  

        if (isempty(report.Graph.Width))
            report.Graph.Width = NaN;                           
        end

        if (isempty(report.Graph.Height))
            report.Graph.Height = NaN;                           
        end

        Im         = imresize(Im, 'OutputSize', [ report.Graph.Height report.Graph.Width  ] );   
        position   = report.Graph.Position; % report.dispPosition
        videoFrame = insertInImage(position(1), position(2), Im, videoFrame);                                                

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
        % EYE MARKERS   
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        if (hasPupilTracking)
            
            %currentResult = myGraph.GetData();
            currentResult = myGraph.getCurrentData();
            currentEyeX = currentResult.(report.Tracked.PupilX);
            currentEyeY = currentResult.(report.Tracked.PupilY);
            if (~isnan(currentEyeX)&&(~isnan(currentEyeY)))                        
                videoFrame = insertMarker(videoFrame, [ currentEyeX, currentEyeY ], '+', 'color', { 'green' }, 'size', 4); 
            end
            
            currentEyeCnrX = currentResult.(report.Tracked.EyeCnrX);
            currentEyeCnrY = currentResult.(report.Tracked.EyeCnrY);
            if (~isnan(currentEyeCnrX)&&(~isnan(currentEyeCnrY)))                                        
                bboxRect = [ currentEyeCnrX-5, currentEyeCnrY-5 10 10 ];
                videoFrame = insertShape(videoFrame, 'FilledRectangle', bboxRect, 'color', 'red');                                             
            end
             
        end
    end 


    if (hasSubjective)
        position = report.Subjective.Position;
        videoFrame = insertLinesOnImage(videoFrame, position(1), position(2), currSubjlines);
    end

    % trial information
    %position = report.TrialInfo.Position; %dispTrialInfoPosition;
    %videoFrame = insertLinesOnImage(videoFrame, position(1), position(2), currlines);'
    
    step(videoFWriter, videoFrame);
    %counter = counter + 1;
end

close(f);


if (~report.graphOnly)
    release(videoFWriter);
end

end


function mystruct = parseargfield(strline)
            
        mystruct = struct();
        lines = {}; counter = 1;
        while( ~isempty(strline) )    
            [strcmd, strline] = strtok(strline,',');
            if (isempty(strline))
                %lines{counter} = strcat('- ', strtrim(strcmd));
                [strfield, strvalue] = strtok(strcmd,'=');
                if (~isempty(strvalue))
                    strvalue(1) = [];
                end
                mystruct.(strfield) = strvalue;
                return
                %break;
            end            
            strline(1) = []; strline = strtrim(strline);             
            %lines{counter} = strcat('- ', strtrim(strcmd));
            [strfield, strvalue] = strtok(strcmd,'=');
                if (~isempty(strvalue))
                    strvalue(1) = [];
                end
                
            if contains(strfield,'#')
                strfield = strtrim(strfield);
                [presentStr, strfield] = strtok(strfield,' ');
                mystruct.presentationID = str2num(strrep(presentStr,'#','')); 
            else
                mystruct.(strfield) = strvalue;
            end
            counter = counter + 1;
        end
end
