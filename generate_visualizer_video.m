function generate_visualizer_video(report)

% GENERATE_VISUALIZER_VIDEO Create a video with a graph overlay  
%
% generate_visualizer_video(report)
%

% .... configuration in the directory
%config = configurator('./data/TP05/R_Madatory Test/config.json');
%prettyprint(config);
%report = getconfigstruct(config);
%figure(1); clf;
%showcalibrationframe(report);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add base directory  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all;

if (isfield(report, 'baseDirectory'))
    reportDir = report.baseDirectory;
end

hasCDPReport = false;
if (isfield(report, 'CDPfile'))
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % JSON or TXT report   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [~,~,ext] = fileparts(report.CDPfile);
    if (strcmp(ext, '.json'))
        report.cdpreport      = loadcdpreport(fullfile(reportDir, report.CDPfile));
    elseif (strcmp(ext, '.txt'))    
        report.cdpreport      = loadcdptxtreport(fullfile(reportDir, report.CDPfile));  
    end
    fprintf('loaded cdp report .... %s\n', report.CDPfile);
    patientID = report.cdpreport.patient_uid;    
    hasCDPReport = true;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% READ THE DATA SOURCE 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
report.datareport     = readtable(fullfile(reportDir,report.datafile));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PEAKS ON THE PLOT 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hasDetectorReport = false;
if (isfield(report,'Detector'))    
    %% TODO : MAKE IT RELATIVE EVENTUALLY
    strResultFile = fullfile(reportDir, report.Detector.ResultFile);
    TotalResults = readtable(strResultFile);    
    if (~isempty(TotalResults))    
        hasDetectorReport = true;
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% POINTS REPORT  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hasPointsReport = false;
                    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ARUCO REPORT  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hasArucoDetector = false;
if (isfield(report,'ArucoDetector'))
    if (report.ArucoDetector.ShowResult)
        hasArucoDetector = true;
    end
end
fprintf('hasArucoDetector ... %d\n', hasArucoDetector);

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

hasAutomaticPosition = false;
if (isfield(report.Graph, 'AutoPosition'))
    hasAutomaticPosition = true;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% READALYZER FIELD  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hasReadalyzer  = false;
if (isfield(report, 'readalyzerMAT'))
    readalyzerMATFile = fullfile(reportDir, report.readalyzerMAT);
    if (exist(readalyzerMATFile,'file'))
        report.readalyzerData = load(readalyzerMATFile);
        hasReadalyzer = true;
    else
        report.readalyzerData = nan; %load(readalyzerMATfile);    
    end
    fprintf('loaded readAnalyzer report .... %s\n', report.readalyzerMAT);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% HASPUPIL OVERLAY   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hasPupilTracking = false;
if (isfield(report, 'Tracking'))    
    if (isfield(report.Tracking, 'PupilX') && isfield(report.Tracking, 'PupilY') )
        hasPupilTracking = true;
    end    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SHOW REPORT  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%printstruct(report);
%

if (~report.graphOnly)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % VIDEOREADER   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    videoRead     = VideoReader(fullfile(reportDir, report.mainVideo));
    height        = videoRead.Height; 
    width         = videoRead.Width;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % VIDEOWRITER   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    videoFWriter = vision.VideoFileWriter(fullfile(reportDir, report.outputVideo),'FileFormat','MPEG4','FrameRate',videoRead.FrameRate);
    videoFWriter.Quality = 90;
    
end

patient_uid   = report.cdpreport.patient_uid;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TRIAL FILTER   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hasTrialFilter = false;
if (isfield(report,'TrialFilter'))
    hasTrialFilter = true;
    fprintf('Filter on Trials ... %d\n', report.TrialFilter);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN - CDPREPORT DRIVEN 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Show the basic graph - If the CDP Report is available
myGraph = GraphCDPResult(report.datareport, report.InputFields);         
myGraph.showVelocity        = report.Graph.showVelocity;
myGraph.showDisplacement    = report.Graph.showDisplacement;
myGraph.DisplacementOffset  = report.Graph.DisplacementOffset;
myGraph.DisplacementRange   = report.Graph.DisplacementRange;
myGraph.VelocityOffset      = report.Graph.VelocityOffset;
myGraph.VelocityRange       = report.Graph.VelocityRange;

numTrialCounter = 1;
lastPosition = [];

if (hasTrialFilter)
    numTrialFilter  = length(report.TrialFilter);
end

N = length(report.cdpreport.steps_run);
for k = 1:N
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Ignore NAN trials 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    currstep = report.cdpreport.steps_run(k);    
    if (isnan(currstep.number))
        fprintf('%d. number = %d [Ignoring]\n', k, currstep.number);    
        continue;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % Ignore Filtered Trials
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fprintf('%d. number = %d ', k, currstep.number);    
    if (hasTrialFilter)
        if (~ismember(currstep.number, report.TrialFilter))
            fprintf('[FILTERING]\n');
            continue;
        end
    end
    fprintf('[PROCESSING]\n');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % Ignore Filtered Trials
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    switch(currstep.name)   
        
        case { 'Disk', 'Message' }            
            
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                % Current Time 
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                if (~report.graphOnly)
                    videoRead.CurrentTime = currstep.start_time;  
                end
                
                i  = (currstep.start_time <= report.datareport.Time)&(report.datareport.Time <= currstep.end_time);                
                if (~any(i))
                   disp('ignoring trial - no data'); 
                   continue;
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                % Readalyzer image  
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                if (hasReadalyzer)
                    imageReadalyzer = imreadalyzer(currstep.end_time + report.readalyzerOffset, report.readalyzerData.output, report);                    
                    if (~isempty(imageReadalyzer))                  
                        imageReadalyzer = imresize(imageReadalyzer, 'OutputSize', [ 400 nan] );
                    end
                end
 
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                % Show the basic graph    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                if (report.graphOnly)
                    figure(numTrialCounter); clf;
                    %subplot(numTrialFilter,1,numTrialCounter); 
                    %numTrialFilter
                    %numTrialCounter
                else
                    f = gcf; clf;
                end                
                myGraph.setTimeInterval(currstep.start_time, currstep.end_time);
                
                
                if (report.graphOnly)
                    hold on;
                    title(sprintf(' Time [%4.3f, %4.3f]\n',currstep.start_time, currstep.end_time));  
                    numTrialCounter = numTrialCounter + 1;
                end

                if (hasDetectorReport)
                    i  = (TotalResults.isSelected == true & TotalResults.isValid == true & TotalResults.Number == currstep.number & TotalResults.StartTime >= currstep.start_time & TotalResults.EndTime <= currstep.end_time );                                    
                    if (any(i))
                        % Hard coded delay 
                        yyaxis right; hold on;                        
                        %ret = getDisplacement(obj, myTime);
                        
                        myResults = TotalResults(i,:);                        
                        for k = 1:size(myResults, 1)                            
                            startDisp = myResults.StartDisp(k);
                            graphDisp = myGraph.getDisplacement(myResults.StartTime(k));
                            myResults.StartDisp(k) = graphDisp;
                            myResults.PeakDisp(k)  = myResults.PeakDisp(k) - startDisp + graphDisp;
                            myResults.EndDisp(k)   = myResults.EndDisp(k) - startDisp + graphDisp;
                        end
                        
                        h = showSawToothOverlay(myResults, report.Detector.TimeOffset); %, 0.150, y0); 
                    end
                end
                
 
                graphHeight = report.Graph.Height;                   
                graphWidth  = report.Graph.Width;
            
                
                if (hasAutomaticPosition)
                   returnData = myGraph.getCurrentDataFrame(currstep.start_time, currstep.end_time);
                   myX = returnData.(report.Graph.AutoPositionX);
                   myY = returnData.(report.Graph.AutoPositionY);
                   imSize = [ videoRead.Width videoRead.Height  ];
                   ret = mean([ myX myY ],'omitnan');                     
                   myMeanX0 = ret(1)/imSize(1);
                   myMeanY0 = ret(2)/imSize(2);
                   
                   if (all(isnan([ report.Graph.Width report.Graph.Height ])))
                       error('both nans in Graph.Width & Graph.Height');
                   end
                   

                   if (isempty(report.Graph.Width) | isnan(report.Graph.Width))
                       
                       report.Graph.Width = nan;                       
                       testIm  = zeros(videoRead.Height, videoRead.Width);
                       testIm  = imresize(testIm, 'OutputSize', [ report.Graph.Height report.Graph.Width   ] ); 
                       
                       % myFig      = gcf;
                       % ratio      = myFig.Position;
                       % ratio      = ratio(3)/ratio(4);
                       % graphWidth = report.Graph.Height * ratio;  
                       
                       graphHeight = size(testIm, 1); %report.Graph.Width * ratio;                         
                       graphWidth  = size(testIm, 2); %report.Graph.Width * ratio;  
                       
                       fprintf('Automatically determined image dimensions (H,W) = [%d, %d] from WIDTH\n', graphHeight, graphWidth);                       
                   end
                                      
                   if (isempty(report.Graph.Height) | isnan(report.Graph.Height))
                       
                       report.Graph.Height = nan;
                       
                       testIm  = zeros(videoRead.Height, videoRead.Width);
                       testIm  = imresize(testIm, 'OutputSize', [ report.Graph.Height report.Graph.Width   ] ); 
                       
                       %myFig     = gcf;
                       %ratio      = myFig.Position;
                       %ratio      = ratio(4)/ratio(3);
                       graphHeight = size(testIm, 1); %report.Graph.Width * ratio;  
                       graphWidth  = size(testIm, 2); %report.Graph.Width * ratio;                         
                       fprintf('Automatically determined image dimensions (H,W) = [%d, %d] from HEIGHT\n', size(testIm));                       
                   end    
                   
                   position = [ 0 0 ];
                   if (myMeanX0 <= 0.5)
                       position(1) = videoRead.Width  - graphWidth - 1;
                   else
                       position(1) = 5;                       
                   end

                   if (myMeanY0 >= 0.5)
                       position(2) = 5;
                   else
                       position(2) = videoRead.Height - graphHeight - 1;
                   end
                   
                   %position
                   
                   

                   if ( (isnan(myMeanX0)|isnan(myMeanY0)) && ~isempty(lastPosition))                       
                       if (~isempty(lastPosition))
                        position = lastPosition;
                       else
                        position = [ 5 5 ];
                       end
                   end                   
                   lastPosition = position;
                   fprintf('gW = %4.3f gH = %4.3f posX = %4.3f posY = %4.3f mX = %4.3f mY = %4.3f Vx = %4.3f Vy = %4.3f\n', graphWidth, graphHeight, position, myMeanX0, myMeanY0, videoRead.Width, videoRead.Height);                   
                else
                   position   = report.Graph.Position;
                end
                
                
                %myGraph.drawGraphs();
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                % Show the points on the graph    
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                % display the points 
                if (hasPointsReport)
                    
                    %report.readalyzerMAT
                        pointsTable  = report.pointsReport;                        
                        CDPPatientID = report.cdpreport.patient_uid;                        
                        i1 = strcmp(pointsTable.cdpPatientID, CDPPatientID);
                        i2 = (pointsTable.cdpNumber == currstep.number);
                        i  = i1 & i2;
                        if (any(i))
                            tp = pointsTable(i,:).Time;
                            vp = pointsTable(i,:).Velocity;   
                            
                            i0 = ~(isnan(tp) | isnan(vp));
                            tp = tp(i0); vp = vp(i0);                            
                            %tp
                            %vp
                            
                            if (length(tp) > 0)
                            
                                %h(2) 
                                for k = 1:length(tp)
                                    x1 = tp(k); 
                                    X  = [ x1-0.1 x1+0.1 x1+0.1 x1-0.1 ];
                                    Y  = [ -100 -100 100 100 ];                                    
                                    fz = patch( X, Y, 'w');
                                    fz.FaceAlpha = 0.1;
                                end
                                
                                %q = plot(f1, tp, vp, 'co'); %, 'MarkerFaceColor', report.cyan/255, ...
                                                    %'SizeData',  report.dispSizeData, ...                                    
                                                    %'MarkerEdgeColor', report.cyan/255); 
                                                    
                                 %set(q,'MarkerSize', 20);
                            end
                            
                        end
                end                

                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                % Show trial details if allowed to
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                if (isfield(currstep,'args'))                    
                    if (~strcmp(lower(report.TrialInfo.Display), 'basic') || ~isfield(report.TrialInfo, 'Display'))
                        
                            new_fnames = {};
                            mycont = 1;
                            fnames = fieldnames(currstep);
                            for k = 1:length(fnames)
                                if (~strcmp(fnames{k},'args'))
                                    new_fnames{mycont} = fnames{k};
                                    mycont = mycont + 1;
                                end
                            end    
                            new_fnames = [ new_fnames 'args' ];
                            [currstep,~] = orderfields(currstep, new_fnames);                        
                            %currstep.args = parseargfield(currstep.args);
                    else
                        currstep = rmfield(currstep,'args'); % = [];
                    end
                end
                currlines = convertStructToCellArray(currstep);    
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                % SHOW SUBJECTIVE RATING 
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                                

                if (hasSubjective)     
                        
                        %report.readalyzerMAT
                        subjTable    = report.subjectiveReport;                        
                        CDPPatientID = report.cdpreport.patient_uid;                        
                        i1 = strcmp(subjTable.cdpPatientID, CDPPatientID);
                        i2 = (subjTable.cdpNumber == currstep.number);
                        i  = i1 & i2;
                        if (any(i))

                            PatientID = subjTable(i,:).PatientID;
                            answerLC  = strtrim(subjTable(i,:).(report.Subjective.ratingField1));
                            answerPG  = strtrim(subjTable(i,:).(report.Subjective.ratingField2));                                                        
                            answerOBJ = strtrim(subjTable(i,:).(report.Subjective.ObjectiveField));                                                        

                            answerLC = answerLC{1};
                            answerPG = answerPG{1};                            
                            answerOBJ = answerOBJ{1};
                            
                            strLC  = sprintf('%s (rating = %s)', answerLC(2),  answerLC(1));
                            strPG  = sprintf('%s (rating = %s)', answerPG(2),  answerPG(1));
                            strOBJ = sprintf('%s (rating = %s)', answerOBJ(2), answerOBJ(1));
                            
                            % want to show two fields for
                            myStruct.SubjectID    = PatientID; 
                            myStruct.CPDSubjectID = CDPPatientID;                             
                            myStruct.ObjectiveResult     = strOBJ;
                            myStruct.SubjectiveObserver1 = strPG;
                            myStruct.SubjectiveObserver2 = strLC;                               
                        else                        
                            % want to show two fields for 
                            myStruct.SubjectID           = 'NONE'; 
                            myStruct.CPDSubjectID        =  CDPPatientID;                             
                            myStruct.ObjectiveResult     = 'NONE';
                            myStruct.SubjectiveObserver1 = 'NONE';
                            myStruct.SubjectiveObserver2 = 'NONE';   
                        end
                        currSubjlines    = convertStructToCellArray(myStruct);
                end
                
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                % PREVIEW MODE - FRAMES  
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
                
                %report
                
                if (report.previewMode)
                    fprintf('PREVIEW MODE.\n');
                    maxCounter = 50;
                else
                    maxCounter = inf;
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                % EACH TRIAL 
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
                
                if (report.graphOnly)
                    fprintf('graphOnly.\n');
                    continue;
                end
                
                framegrabbedIm = [];
                counter = 1;                
                while(hasFrame(videoRead)&&(videoRead.CurrentTime < currstep.end_time)&&(counter<maxCounter))
                    
                    videoFrame = im2uint8(readFrame(videoRead));   
                    
                    %size(videoFrame)
                    
                    %n = find(abs(t - videoRead.CurrentTime) < 0.03);                    
                    if (~isempty(myGraph.hasTime(videoRead.CurrentTime)))
                                                
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                        % GET CURRENT IMAGE OF GRAPH 
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        
                        %g.Visible = 'on';
                        %g.XData = videoRead.CurrentTime;
                        %g.YData = d(n(1));
                        
                        myGraph.setPointer(videoRead.CurrentTime);
                        currentResult = myGraph.getCurrentData();

                        if (myGraph.isPointerVisible) %% pointer is valid                        
                            
                            f = gcf;                        
                            framegrabbedIm = frame2im(getframe(f));
                            emptyFrameCounter = 0;
                        else
                            
                            % pointer not visible and no frames  
                            if (isempty(framegrabbedIm))
                                f = gcf;
                                framegrabbedIm = frame2im(getframe(f));                                                                 
                                emptyFrameCounter = 0;
                            else
                                % no change in data / keep it the same  
                                emptyFrameCounter = emptyFrameCounter + 1; 
                                fprintf('empty frame %d\n', emptyFrameCounter);
                            end                                                        
                        end
                     
                                                
                        
                        if (isempty(report.Graph.Width))
                            report.Graph.Width = NaN;                           
                        end
                        
                        if (isempty(report.Graph.Height))
                            report.Graph.Height = NaN;                           
                        end
                        
                                                
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                        % PUPIL TRACKER
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        
                        if (hasPupilTracking)
                            %currentResult = myGraph.GetData();                            
                            if (~isempty(currentResult))
                                currentEyeX = currentResult.(report.Tracking.PupilX);
                                currentEyeY = currentResult.(report.Tracking.PupilY);
                                if (~isnan(currentEyeX)&&(~isnan(currentEyeY)))                        
                                    videoFrame = insertMarker(videoFrame, [ currentEyeX, currentEyeY ], '+', 'color', { 'green' }, 'size', 8); 
                                end
                            end
                        end

                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                        % ARUCO CODES
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                        if (hasArucoDetector && ~isempty(currentResult))                           

                            strArX  = report.InputFields.ArucoX;
                            strArY  = report.InputFields.ArucoY;
                            strArUx = report.InputFields.ArucoUx;
                            strArUy = report.InputFields.ArucoUy;
                            strArVx = report.InputFields.ArucoVx;
                            strArVy = report.InputFields.ArucoVy;   

                            %currentResult = myGraph.getCurrentData();
                            ArX = currentResult.(strArX); % currentResult.(strArUy) ]; 
                            ArY = currentResult.(strArY); % currentResult.(strArUy) ];                         
                            ArU = [ currentResult.(strArUx) currentResult.(strArUy) ]; 
                            ArV = [ currentResult.(strArVx) currentResult.(strArVy) ];  

                            if (~isnan(ArX))
                                videoFrame = insertArucoCoordOnImage(videoFrame, ArX, ArY, ArU, ArV);
                            end
                        end
                                                
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                        % GRAPH
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        
                        Im         = imresize(framegrabbedIm, 'OutputSize', [ graphHeight graphWidth ]);   
                        videoFrame = insertInImage(position(1), position(2), Im, videoFrame);                                                
                        
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                        % READALYZER  
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                        if (hasReadalyzer)                
                            if (~isempty(imageReadalyzer))                              
                            videoFrame = insertInImage(report.readalyzerPosition(1), report.readalyzerPosition(2), imageReadalyzer, videoFrame); 
                            end
                        end

                        % currentEyeX = eyeX(n(1)); currentEyeY = eyeY(n(1));                                        
                        % [currentEyeX, currentEyeY] = myGraph.getPupil();
                        % [currentEyeX, currentEyeY] = getfieldGraph(report.datareport);
                        
                        
                    else
                        g.Visible = 'off';
                    end 
    

                    
                    if (hasSubjective)
                        position = report.Subjective.Position;
                        videoFrame = insertLinesOnImage(videoFrame, position(1), position(2), currSubjlines);
                        % videoFrame = convertStructToCellArray(videoFrame, report.dispTrialInfoPosition, myStruct);                    
                    end
                    
                    % trial information
                    position2 = report.TrialInfo.Position; %dispTrialInfoPosition;
                    videoFrame = insertLinesOnImage(videoFrame, position2(1), position2(2), currlines);
                        
                    %videoFrame = insertCDPtrialInImage(videoFrame, report.dispTrialInfoPosition(1), report.dispTrialInfoPosition(2), currstep);                    

                    %step(videoPlayer, videoFrame);    
                    
                    %size(videoFrame)
                    
                    step(videoFWriter, videoFrame);
                            
                    counter = counter + 1;
                end
            
                close(f);

                
        otherwise
           disp('keep going.');
    end
    
    %videoRead.CurrentTime = 0.0;
    %videoFrame = im2uint8(readFrame(videoRead));
   
end

if (~report.graphOnly)
    release(videoFWriter);
end

end


function mystruct = parseargfield(strline)
            
        strline 
        
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
