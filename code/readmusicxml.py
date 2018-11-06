# -*- coding: utf-8 -*-
"""
Created on Wed Sep 19 10:27:49 2018

@author: stanley
"""

from music21 import *
import sys , os
import scipy.io
import pandas as pd


def getxmldata(filepath):
    stream = converter.parse(filepath)  ## 讀檔
    
    # 讀拍號
    TS = stream.recurse().getElementsByClass('TimeSignature')[0] ##目前的歌中間都沒有換拍號
    beatCount,noteValue = map(int,TS.ratioString.split('/'))  ## '分子/分母'
    print(beatCount,noteValue)
    # 要將拍號轉成以4為底
    if noteValue != 4:
        beatCount = beatCount/(noteValue/4)
        noteValue = 4
    print(beatCount,noteValue)
    
    ## note 跟 chord 都要讀 , chord 要在拆成 
    data = []
    for n in stream.flat.getElementsByClass(['Note','Chord']):
        if type(n) == chord.Chord:
            for c in n:
                data.append([float(n.offset), float(n.duration.quarterLength),c.pitch.midi,beatCount,noteValue])
        else:  ##note
            data.append([float(n.offset), float(n.duration.quarterLength),n.pitch.midi,beatCount,noteValue])
    data = pd.DataFrame(data, columns=['ONSET','DUR','PITCH','beatCount','noteValue'])
    data = data.sort_values(['ONSET', 'DUR'], ascending=[True, True])
    
    return data

if __name__== "__main__": 
    #data = getxmldata('midi/pei/b_20_1.xml')
    #scipy.io.savemat('midi/pei/b_20_1.mat', {'matrix': data.values.tolist()})
    
    r_dir = r'midi/pei/'
    
    # 有指定檔案.xml  matlab裡面有下cmd 生成.mat
    if len(sys.argv) > 1:
        print(sys.argv[1])
        filepath = sys.argv[1]
        data = getxmldata(filepath)
        scipy.io.savemat(filepath.replace('.xml','.mat'), {'matrix': data.values.tolist()})
    
    # 沒指定就是把有.xml的都生成.mat
    else:
        for root, sub, files in os.walk(r_dir):
            files = sorted(files)
            for f in files:       
                base=os.path.basename(f)
                filepath = root+base
                if filepath.split('.')[-1] != 'xml':
                    continue
                print(filepath)
                data = getxmldata(filepath)
                scipy.io.savemat(filepath.replace('.xml','.mat'), {'matrix': data.values.tolist()})
    
            

