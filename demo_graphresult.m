%DEMO_GRAPHRESULT Show an example of the graph

strDataFile = './data/Konan/tracker/NZMS-2017-Sep-28_125247_tracker_output.csv';
gr = GraphCDPResult(strDataFile);
gr.showDisplacement = true;
gr.setTimeInterval(0, 10);
gr.setPointer(1.5);
gr.VelocityRange = 5;
gr.VelocityOffset = -1.00;
gr.DisplacementRange = 20;
gr.DisplacementOffset = 5;


