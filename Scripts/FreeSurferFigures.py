## Python dependencies
import pandas as pd
import numpy as np
import argparse
import csv
import os

ProjectDir = '/Users/kelly89/Projects/FreeSurferCompare'

#Colors need to be unique for each region (FreeSurfer will combine all otherwise)
def GetColors(column):
    rcount = 0
    bcount = 0
    gcount = 0
    dcount = 0
    ocount = 0
    colors = []
    for index, row in column.iteritems():
        if row == 'A':
            color = str(int(255 - (rcount * 3))) + ' 0 0 0'
            rcount += 1
        elif row == 'B':
            color = '0 ' + str(int(255 - (bcount * 3))) + ' 0 0'
            bcount += 1
        elif row == 'C':
            color = '0 0 ' + str(int(255 - (gcount * 3))) + ' 0'
            gcount += 1
        elif row == 'DIFF':
            color = '255 255 ' + str(int(dcount * 3)) + ' 0'
            dcount += 1
        else:
            color = '255 255 ' + str(int(255 - (ocount * 3))) + ' 0'
            ocount += 1
        colors.append(color)
    c = pd.DataFrame(colors)
    return c

for metric in ['PARAM1','PARAM2']:
    print metric

    #Get results from csv file
    infile = str(ProjectDir) + '/DataFiles/' + str(metric) + '.csv'
    ofile = infile.replace('.csv','-results.csv')
    print infile

    #Read results into pandas df and do some basic parsing to get relevant data
    x = pd.read_csv(infile, sep = ',')
    region = x.ix[range(1,len(x),20)][['C']]
    model1bestfit = x.ix[range(4,len(x),20)][['F','M']]
    model2bestfit = x.ix[range(13,len(x),20)][['F','M']]

    #Combine results for both models into one df
    r = np.hstack([region, model1bestfit, model2bestfit])
    k = pd.DataFrame(r)

    #Clean up data
    k['metric'] = k[0].apply(lambda x: str(metric))
    k['region'] = k[0].apply(lambda x: x.split('.')[3])
    k['MODEL1-lh-bestfit'] = k[1]
    k['MODEL1-rh-bestfit'] = k[2]
    k['MODEL2-lh-bestfit'] = k[3]
    k['MODEL2-rh-bestfit'] = k[4]
    k['lh-difference-bestfit'] = np.where(k['MODEL1-lh-bestfit'] == k['MODEL2-lh-bestfit'], 'NODIFF', 'DIFF')
    k['rh-difference-bestfit'] = np.where(k['MODEL1-rh-bestfit'] == k['MODEL2-rh-bestfit'], 'NODIFF', 'DIFF')

    #Don't need first few columns in final results, but should save column names
    k.drop(k.columns[0:5], axis=1, inplace = True)
    kcols = k.columns.values

    #Add rows for missing columns (so that colormap aligns properly)
    u = pd.DataFrame([str(metric), 'unknown', '0', '0', '0', '0', 'NODIFF', 'NODIFF']).T
    c = pd.DataFrame([str(metric), 'corpuscallosum', '0', '0', '0', '0', 'NODIFF', 'NODIFF']).T
    k = pd.DataFrame(np.vstack([k,u,c]))
    k.columns = kcols

    #Import file with correct order of regions, use this to sort values, then drop column (since not necessary)
    order =  str(ProjectDir) + '/Scripts/' + 'OrigRegions.csv'
    o = pd.read_csv(order)
    k = pd.merge(k, o, on = 'region', sort = True)

    #Save to csv (for QA purposes)
    k.to_csv(ofile, sep = ',' , index  = False)

    #Create separate annotation file for each model
    for hemi in ['lh', 'rh']:
	    for modeltype in ['MODEL1', 'MODEL2', 'difference']:

	        annot = str(ProjectDir) + '/fsaverage/label/' + str(hemi) + '.aparc.orig.annot.ctab.csv'

	        a = pd.read_csv(annot, sep = ',', header = None)
	        a.columns = ['index', 'region', 'c1', 'c2', 'c3', 'c4']

	        tfile = str(ProjectDir) + '/DataFiles/' + str(hemi) + '-' + str(metric) + '-' + str(modeltype) + '-' + 'data.temp.csv'
	        ofile = tfile.replace('data.temp','aparc.annot.ctab')

	        k = pd.merge(d, a, sort = True)
	        k['color'] = GetColors(k[model])
	        k[['region','color']].to_csv(tfile, sep = ' ', index = True, header = False, quoting=csv.QUOTE_NONE, escapechar = ' ')

	        #Fix issue with to_csv (will not print without quotes or escape char)
	        open(ofile, "w").write(open(tfile).read().replace('  ',' '))
	        os.remove(tfile)
