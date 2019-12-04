function Im2 = insertInImage( x, y, Im1, Im2 )
%insertInImage Insert Im1 into Im2 
% Im2 = insertInImage( x, y, Im1, Im2 )
sz = size(Im1);  % show it

if (ndims(sz) == 2)
    Im2(y:(y+sz(1)-1), x:(x+sz(2)-1)) = Im1;
    return
end 

Im2(y:(y+sz(1)-1), x:(x+sz(2)-1), 1:3) = Im1;
end

