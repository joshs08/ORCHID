% this class reads in specified variables from a text file

function [vars] = get_txt_vars (path)

% read in text file variables
path_txt = fullfile (path, 'info_cell.txt');
FID = fopen(path_txt);
try
    txt = textscan(FID,'%s', 'Delimiter', '\n');
    success = true;
catch
    success = false;
    disp ('No cell_info.txt available');
end
if success == true
    fclose(FID);
    stringTxt = string(txt{:});
    stringTxt = replace (stringTxt, ':', ': ');
    
    vars = {"Cell type", "Pipette R", "Puffing", "Rt", "Ra", "Rm", "Cm", "Vm"};
    v = size (vars, 2);
    
    for w =1:v
        var = string(vars (1, w));
        l = strlength (var);
        % check it exists
        b = contains (stringTxt, var);
        if b == false
            vars (2, w) = {"NA"};
        else
            r = find(contains(stringTxt,var));
            r = r (1);
            l = l + 1;
            s = stringTxt (r);
            returned = extractAfter(s,l);
            returned = strtrim (returned);
            vars (2, w) = {returned};
        end
        
    end
end