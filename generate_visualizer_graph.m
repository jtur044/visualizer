function generate_visualizer_graph(report)

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

if (isfield(report, 'baseDirectory'))
    reportDir = report.baseDirectory;
end
[~,~,ext] = fileparts(report.CDPfile);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% JSON or TXT report   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (strcmp(ext, '.json'))
    report.cdpreport      = loadcdpreport(fullfile(reportDir, report.CDPfile));
elseif (strcmp(ext, '.txt'))    
    report.cdpreport      = loadcdptxtreport(fullfile(reportDir, report.CDPfile));  
end
fprintf('loaded cdp report .... %s\n', report.CDPfile);

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

patientID = report.cdpreport.patient_uid;    

% Show the basic graph - If the CDP Report is available
myGraph = GraphCDPResult(report.datareport, report.InputFields);         
myGraph.showVelocity        = report.Graph.showVelocity;
myGraph.showDisplacement    = report.Graph.showDisplacement;
myGraph.DisplacementOffset  = report.Graph.DisplacementOffset;
myGraph.DisplacementRange   = report.Graph.DisplacementRange;
myGraph.VelocityOffset      = report.Graph.VelocityOffset;
myGraph.VelocityRange       = report.Graph.VelocityRange;

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
            
                i  = (report.datareport.Time >= currstep.start_time)&(report.datareport.Time <= currstep.end_time);                
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
                
                myGraph.setTimeInterval(currstep.start_time, currstep.end_time);
                %myGraph.drawGraphs();
                
                %{
                %% create a data report graph - leave the figure up to move pointer on it   
                t  = report.datareport.Time(i); 
                d = report.datareport.(report.dispField); 
                d = d(i); d = d - mean(d,'omitnan'); 
                v = report.datareport.(report.dispFieldV); 
                v = v(i);                 
                
                eyeX = report.datareport(i,:).(report.eyeFieldX); 
                eyeY = report.datareport(i,:).(report.eyeFieldY); 
                f = figure; clf; set(f, 'Visible', 'off');
                [h, f1, f2] = plotyy(t, d, t, v);               
                set(h(2), 'ylim', report.dispVelAxisLim);
                h(2).YTick = linspace(report.dispVelAxisLim(1), report.dispVelAxisLim(2), 5);
                set(h(1), 'ylim',report.dispDispAxisLim); 
                h(1).YTick = linspace(report.dispDispAxisLim(1), report.dispDispAxisLim(2), 5);
                
                hold on;     
                h(1).Children.Color = report.green/255; 
                h(1).Children.LineWidth = 2; 
                h(1).YColor = report.green/255; 
                h(1).XColor = report.white/255; 
                
                h(2).Children.Color = report.magenta/255;                
                h(2).Children.LineWidth = 2; 
                h(2).YColor = report.magenta/255; 
                h(2).XColor = report.white/255; 
                set(gca,'Color','k');
                
                g = scatter(t(1), d(1),  'MarkerFaceColor', h(2).YColor, ...
                                         'SizeData',  report.dispSizeData, ...                                    
                                         'MarkerEdgeColor', h(2).YColor); 
                %g.Visible = 'off';                                     
                f.Color = 'k';                
                                
                %set(gca, 'LineWidth', 2);
                %set(gca, 'YColor', 'w'); 
                %set(gca, 'XColor', 'w'); 
                grid on;
                set(h,'FontSize', report.dispFontSize);
                xlabel('Time');
                
                h(1).YLabel.String = 'Displacement';           
                h(2).YLabel.String = 'Velocity';    
                %}
                
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

                if (report.previewMode)
                    fprintf('PREVIEW MODE.\n');
                    maxCounter = 50;
                else
                    maxCounter = inf;
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
                % EACH TRIAL 
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
                
                %counter = 1;                
                %close(f);

                
        otherwise
           disp('keep going.');
    end
    
    %videoRead.CurrentTime = 0.0;
    %videoFrame = im2uint8(readFrame(videoRead));
   
end

%release(videoFWriter);

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
