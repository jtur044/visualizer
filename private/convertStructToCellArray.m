function lines = convertStructToCellArray(myStruct, lines)  

% CONVERTSTRUCTTOCELLARRAY Convert structure to cell array 
%
% lines = convertStructToCellArray(myStruct, lines)  
%

    if (nargin == 1)
        lines = {};
   end

    %counter = 1;
    myFieldNames = fieldnames(myStruct);
    N = length(myFieldNames);
    for k = 1:N
        myInfo = myStruct.(myFieldNames{k});        
        if (isnumeric(myInfo))
            myInfo = num2str(myInfo,'%4.4f');
            lines = [ lines strcat(myFieldNames{k},' :',myInfo) ];
        elseif (isstruct(myInfo))    
            extra = convertStructToCellArray(myInfo);            
            lines = [ lines strcat(myFieldNames{k},' :') extra ];
            return
        else
            lines = [ lines strcat(myFieldNames{k},' :',myInfo) ];
        end
       
    end        
end
