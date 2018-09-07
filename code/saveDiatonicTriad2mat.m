clear; clc;
% 存每個調的順階三和弦
% save structure : KeyName diatonicTriad diatonicTriadName

% Major scale consists of notes
M_C         = {'C' , 'D' , 'E' , 'F' , 'G' , 'A' , 'B' };
M_Csharp    = {'C#', 'D#', 'F' , 'F#', 'G#', 'A#', 'C' };
M_D         = {'D' , 'E' , 'F#', 'G' , 'A' , 'B' , 'C#'};
M_Dsharp    = {'D#', 'F' , 'G' , 'G#', 'A#', 'C' , 'D' };
M_E         = {'E' , 'F#', 'G#', 'A' , 'B' , 'C#', 'D#'};
M_F         = {'F' , 'G' , 'A' , 'A#', 'C' , 'D' , 'E' };
M_Fsharp    = {'F#', 'G#', 'A#', 'B' , 'C#', 'D#', 'F'};
M_G         = {'G' , 'A' , 'B' , 'C' , 'D' , 'E' , 'F#'};
M_Gsharp    = {'G#', 'A#', 'C' , 'C#', 'D#', 'F' , 'G' };
M_A         = {'A' , 'B' , 'C#', 'D' , 'E' , 'F#', 'G#'};
M_Asharp    = {'A#', 'C' , 'D' , 'D#', 'F' , 'G' , 'A' };
M_B         = {'B' , 'C#', 'D#', 'E' , 'F#', 'G#', 'A#'};


% NATURE Minor scale consists of notes
Nm_C        = {'C' , 'D' , 'D#', 'F' , 'G' , 'G#', 'A#'};
Nm_Csharp   = {'C#', 'D#', 'E' , 'F#', 'G#', 'A' , 'B' };
Nm_D        = {'D' , 'E' , 'F' , 'G' , 'A' , 'A#', 'C' };
Nm_Dsharp   = {'D#', 'F', 'F#', 'G#', 'A#', 'B' , 'C#'};
Nm_E        = {'E' , 'F#', 'G' , 'A' , 'B' , 'C' , 'D' };
Nm_F        = {'F' , 'G' , 'G#', 'A#', 'C' , 'C#', 'D#'};
Nm_Fsharp   = {'F#', 'G#', 'A' , 'B' , 'C#', 'D' , 'E' };
Nm_G        = {'G' , 'A' , 'A#', 'C' , 'D' , 'D#', 'F' };
Nm_Gsharp   = {'G#', 'A#', 'B' , 'C#', 'D#', 'E' , 'F#'};
Nm_A        = {'A' , 'B' , 'C' , 'D' , 'E' , 'F' , 'G' };
Nm_Asharp   = {'A#', 'C' , 'C#', 'D#', 'F' , 'F#', 'G#'};
Nm_B        = {'B' , 'C#', 'D' , 'E' , 'F#', 'G' , 'A' };

% HARMONIC Minor scale consists of notes
Hm_C        = {'C' , 'D' , 'D#', 'F' , 'G' , 'G#', 'B' };
Hm_Csharp   = {'C#', 'D#', 'E' , 'F#', 'G#', 'A' , 'C' };
Hm_D        = {'D' , 'E' , 'F' , 'G' , 'A' , 'A#', 'C#'};
Hm_Dsharp   = {'D#', 'F', 'F#', 'G#', 'A#', 'B' , 'D'  };
Hm_E        = {'E' , 'F#', 'G' , 'A' , 'B' , 'C' , 'D#'};
Hm_F        = {'F' , 'G' , 'G#', 'A#', 'C' , 'C#', 'E' };
Hm_Fsharp   = {'F#', 'G#', 'A' , 'B' , 'C#', 'D' , 'F' };
Hm_G        = {'G' , 'A' , 'A#', 'C' , 'D' , 'D#', 'F#'};
Hm_Gsharp   = {'G#', 'A#', 'B' , 'C#', 'D#', 'E' , 'G' };
Hm_A        = {'A' , 'B' , 'C' , 'D' , 'E' , 'F' , 'G#'};
Hm_Asharp   = {'A#', 'C' , 'C#', 'D#', 'F' , 'F#', 'A' };
Hm_B        = {'B' , 'C#', 'D' , 'E' , 'F#', 'G' , 'A#'};

pitchName   = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'};
pitchNumber = [  0,    1,   2,    3,   4,   5,    6,   7,    8,   9,   10,  11];

KeyN = { M_C{:};  M_Csharp{:};  M_D{:};  M_Dsharp{:};  M_E{:};  M_F{:};  M_Fsharp{:};  M_G{:};  M_Gsharp{:};  M_A{:};  M_Asharp{:};  M_B{:}; ...
        Nm_C{:}; Nm_Csharp{:}; Nm_D{:}; Nm_Dsharp{:}; Nm_E{:}; Nm_F{:}; Nm_Fsharp{:}; Nm_G{:}; Nm_Gsharp{:}; Nm_A{:}; Nm_Asharp{:}; Nm_B{:}};

KeyH = { M_C{:};  M_Csharp{:};  M_D{:};  M_Dsharp{:};  M_E{:};  M_F{:};  M_Fsharp{:};  M_G{:};  M_Gsharp{:};  M_A{:};  M_Asharp{:};  M_B{:}; ...
        Hm_C{:}; Hm_Csharp{:}; Hm_D{:}; Hm_Dsharp{:}; Hm_E{:}; Hm_F{:}; Hm_Fsharp{:}; Hm_G{:}; Hm_Gsharp{:}; Hm_A{:}; Hm_Asharp{:}; Hm_B{:}};

% init
KEY             = struct();
consistNumber   = zeros(1,7);
diatonicTriad   = -1*ones(4,7);

keyTmp          = {KeyN, KeyH, KeyH};
for minorKeyType = 1:3 % minorKeyType: 1.KeyN:自然小調 2.keyH:和聲小調 3.Fusion混合自然以及和聲小調
    key = keyTmp{minorKeyType};
    
    for keyIdx = 1:24
        
        for consistIdx = 1:7
            consistNumber(consistIdx) = pitchNumber(strcmp(key{keyIdx,consistIdx},pitchName));
            KEY(keyIdx).consistNote{consistIdx} = key{keyIdx,consistIdx};
        end
        KEY(keyIdx).consistNumber = consistNumber;
        
        for consistIdx = 1:7
            diatonicTriad(1,consistIdx)  = consistNumber(consistIdx);
            tmp                          = circshift(consistNumber,-2-(consistIdx-1));
            diatonicTriad(2,consistIdx)  = tmp(1);
            tmp                          = circshift(consistNumber,-4-(consistIdx-1));
            diatonicTriad(3,consistIdx)  = tmp(1);
            
            if minorKeyType==3 && consistIdx == 3 % Fusion => i iio 「III」 iv V VI viio
                diatonicTriad(3,consistIdx)  = mod(diatonicTriad(3,consistIdx)-1, 12); % 從「III+」變「III」=> 五音減一個半音
            end        

            if consistIdx == 5 % V7
                tmp = circshift(consistNumber,-6-(consistIdx-1));
                diatonicTriad(4,consistIdx)  = tmp(1);
            end
        end
        if keyIdx < 13
            KEY(keyIdx).KeyName = key{consistNumber(1)+1};
        else
            KEY(keyIdx).KeyName = lower(key(consistNumber(1)+1));
        end
        KEY(keyIdx).diatonicTriad       = diatonicTriad;
%         KEY(keyIdx).diatonicTriadName   = key(diatonicTriad+1);  
        
        diatonicTriadName = key(diatonicTriad(1:3,:)+1);
        diatonicTriadName{4,5} = key(diatonicTriad(4,5)+1);
        KEY(keyIdx).diatonicTriadName = diatonicTriadName;
        
        if minorKeyType == 3
            % MAJOR    I IV V V7 ii vi viio iii
            tempMaj = [1 1 1 2 3 3 4 3];
            % MINOR    i iv V V7 iio VI viio III
            tempMin = [3 3 1 2 4 1 4 1];
            keyScale = [1 4 5 5 2 6 7 3];
            if keyIdx<=12
                keyChord = (tempMaj - 1) * 12 + diatonicTriad(1, keyScale) + 1;
            else
                keyChord = (tempMin - 1) * 12 + diatonicTriad(1, keyScale) + 1;
            end
            KEY(keyIdx).keyChord = keyChord; % 順階和弦編號
        end
        
        
    end
    if minorKeyType == 1
        keyN = KEY;
    elseif minorKeyType == 2
        keyH = KEY;
    else
        keyFusion = KEY;
    end
end

save Key_DiatonicTriad_V7.mat keyN keyH keyFusion
