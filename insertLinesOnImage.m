function Im = insertLinesOnImage(Im, x, y, lines )

%strmsg = sprintf('name:%s start_time:%4.4f end:%4.4f number:%d\nargs:%s', mystep.name, mystep.start_time, mystep.end_time, mystep.number, mystep.args);

%lines = generateText(mystep);
strmsg = sprintf('%s\n', lines{:} );
Im = insertText(Im, [ x, y ], strmsg, 'FontSize', 20, 'TextColor','white', ...
         'BoxColor', 'black', 'BoxOpacity', 0.4);


%          name: 'Disk'
%    start_time: 145.3000
%          args: 'note=Disk presentation 5, central_intensity=1.0, perimeter_intensity=0.0, spacing=0.7, stroke_width=0.7, speed=7.0, disk_type=disk2:1, direction=left, ramp_time=2.0'
%      end_time: 152.3000
%        number: 6

end