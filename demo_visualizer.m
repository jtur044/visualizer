%DEMO_VISUALIZER Demonstrate creation of a video 
%
% Specify the configuration file for the graph. 
% The configuration file specifies all the appropriate parameters 
% 
% It is allowed to override the configuration file.
% using additional name-value pairs after the file.
%

%strconfig = './data/Konan/config_displacement.json';
%strconfig = './data/AP05/L_Mandetory Test/config.json';
%strconfig = './data/AP02/R_Mandetory Test/config.json';
strconfig = './data/AP02/R_Mandetory Test/config.json';
strconfig = './data/AP02/R_Mandetory Test/config.json';


myConfig = Configurator(strconfig);
myConfig.add('previewMode', false);
prettyprint(myConfig);

reply = input ('Proceed to create visualization? Y/N [Y]:','s');
if isempty(reply)
   reply = 'Y';
end

if (strcmp(reply,'Y'))
    run_visualizer(myConfig.Result);  % .... or the filename 
end