#!/bin/bash

PROJECT_DIR=/Users/kelly89/Projects/FreesurferCompare
FSAVERAGE_DIR=${PROJECT_DIR}/fsaverage

#Set FreeSurfer subjects directory
export SUBJECTS_DIR=${PROJECT_DIR}

cd ${PROJECT_DIR}

for hemi in lh rh; do
	for type in PARAM2 PARAM1 difference; do
		for metric in ctx area; do

			#Make directory for storing results
			mkdir -p ${PROJECT_DIR}/${metric}/png

			#Make new annotation file with slightly modified matlab code (no display)
			echo "Making annotation file for ${hemi}-${metric}-${type}..."
			matlab -nodisplay -r "replace_ctab2 ${FSAVERAGE_DIR}/label/${hemi}.aparc.annot ${PROJECT_DIR}/DataFiles/${hemi}-${metric}-${type}-aparc.annot.ctab.csv ${FSAVERAGE_DIR}/label/${hemi}-${metric}-${type}.annot.new"

			#Display brain in tksurfer with new annotation file
			echo "Displaying ${hemi}-${metric}-${type} in tksurfer..."
			tksurfer fsaverage ${hemi} pial -annotation ${FSAVERAGE_DIR}/label/${hemi}-${metric}-${type}.annot.new -tcl ${PROJECT_DIR}/Scripts/makeimages2.tcl

			#Rename images
			echo "Renaming images..."
			mv Medial.tiff ${hemi}-${type}-medial-${metric}.tiff
			mv Lateral.tiff ${hemi}-${type}-lateral-${metric}.tiff
			mv Posterior.tiff ${hemi}-${type}-posterior-${metric}.tiff
			mv Anterior.tiff ${hemi}-${type}-anterior-${metric}.tiff
			mv Superior.tiff ${hemi}-${type}-superior-${metric}.tiff
			mv Inferior.tiff ${hemi}-${type}-inferior-${metric}.tiff

			#Convert images to png (and remove tiff)
			for i in `ls *.tiff` ; do
				echo "Converting tiff images to png..."
				convert ${i} `basename $i .tiff`.png
				mv `basename $i .tiff`.png `dirname ${FSAVERAGE_DIR}`/${metric}/png/
				rm ${i}
			done #/convertloop

		done #/metric
	done #/type
done #/hemi

#Make combined images
for metric in area ctx; do
	cd `dirname ${FSAVERAGE_DIR}`/${metric}/png

	#Make ventral images
	for type in PARAM2 PARAM1 difference; do
		convert lh-${type}-inferior-${metric}.png +rotate 90 lh-${type}-ventral-${metric}.png
		convert rh-${type}-inferior-${metric}.png +rotate 270 rh-${type}-ventral-${metric}.png
	done #/ventral

	#Label the lateral images
	for hemi in lh rh; do
		convert ${hemi}-PARAM1-lateral-${metric}.png -background Black -fill White -pointsize 48 label:'PARAM1' +swap -gravity Center -append ${hemi}-PARAM1-lateral-${metric}-labeled.png
		convert ${hemi}-PARAM2-lateral-${metric}.png -background Black -fill White -pointsize 48 label:'PARAM2' +swap -gravity Center -append ${hemi}-PARAM2-lateral-${metric}-labeled.png
		convert ${hemi}-difference-lateral-${metric}.png -background Black -fill White -pointsize 48 label:'Difference' +swap -gravity Center -append ${hemi}-difference-lateral-${metric}-labeled.png
	done #/lateral

	#Make row images
	for view in lateral medial ventral; do
		for hemi in lh rh; do
			if [[ ${view} == "lateral" ]]; then
				convert ${hemi}-PARAM1-${view}-${metric}-labeled.png ${hemi}-PARAM2-${view}-${metric}-labeled.png ${hemi}-difference-${view}-${metric}-labeled.png +append ${hemi}-${view}-${metric}.png
				convert ${hemi}-PARAM1-${view}-${metric}.png ${hemi}-PARAM2-${view}-${metric}.png ${hemi}-difference-${view}-${metric}.png +append ${hemi}-${view}-${metric}-unlabeled.png
			else
				convert ${hemi}-PARAM1-${view}-${metric}.png ${hemi}-PARAM2-${view}-${metric}.png ${hemi}-difference-${view}-${metric}.png +append ${hemi}-${view}-${metric}.png
			fi
		done #/hemi
	done #/view

	for hemi in lh rh; do
		convert ${hemi}-lateral-${metric}.png ${hemi}-medial-${metric}.png ${hemi}-ventral-${metric}.png -append ${hemi}-${metric}.png
		convert ${hemi}-lateral-${metric}-unlabeled.png ${hemi}-medial-${metric}.png ${hemi}-ventral-${metric}.png -append ${hemi}-${metric}-unlabeled.png
	done #/hemi
done #/metric
