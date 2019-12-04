VISUALIZER Some tools for overlaying an eye signal graph over a video 

The basic idea is that a config.json file is placed in an appropriate directory. 

The config.json contains the location/filename for the video, 
as well as settings for the graph that will be used when creating a final video. 
When the run_visualizer.m file is run (either by specifying the filename of the config.json or 
the Result field of the Configurator)


	"CDPfile"          : "NZMS-2017-Sep-28_125247.txt",
	"datafile"         : "tracker/NZMS-2017-Sep-28_125247_tracker_output.csv",
	"mainVideo"        : "NZMS-2017-Sep-28_125247.mp4",
	"outputVideo"      : "Results/NZMS-2017-Sep-28_125247-FINAL-DISPLACEMENT.mp4",
	"previewMode"      : false,

The data for the graph is expected from a CSV file inclkuding headers
as specified by the InputFields proprty of the config.json. 
Typically they will be something like: 


    "InputFields" :  {  "Time": "Time"
    					"PupilX": "LeftDiffX",
                        "PupilY": "LeftDiffY",
                        "PupilVx": "LeftDiffVx",
                        "PupilVy": "LeftDiffVy" },


For the left eye, with a CSV file with headers "Time", "LeftDiffX" , etc, ... 
Remaining options are given below:


	"TrialFilter"      : [1, 2, 3, 4, 5, 6, 7],

	"TrialInfo"        : {
		"Display":  "Basic",
		"Position": [5, 5]		
	},

    "Graph" : { "showVelocity"     : true,
                "showDisplacement" : true,
                "Height"             : 600,
                "Width"              : null,
                "DisplacementOffset" : 3,
                "DisplacementRange"  : 20,
                "VelocityRange"      : 10,
                "VelocityOffset"     : -2.25
            },    

	"showmsg": 1,
	"eyeFieldX": "LeftEyeX",
	"eyeFieldY": "LeftEyeY",
	"dispField": "LeftDiffX",
	"dispFieldV": "LeftDiffVx",
	"dispColor": "g-",
	"dispColorV": "m-",
	"dispFontSize": 16,
	"dispMarkerFaceColor": "g",
	"dispMarkerEdgeColor": "r",
	"dispSizeData": 150,
	"dispYAxis": [0, 600],
	"dispVelAxisLim": [-3, 3],
	"dispDispAxisLim": [-5, 5],
	"dispPosition": [10, 500],

	"ObjectiveGraph": {
		"Position": [680, 570],
		"PointsFile": ""
	}
}# visualizer
