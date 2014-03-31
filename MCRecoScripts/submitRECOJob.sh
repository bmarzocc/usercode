#!/usr/bin/env bash

#small script to automatically submit MC RECO jobs for EXO

datasetPath=$1
nrEvents=$2
nrEventsPerJob=$3
#outputStorageElement=T2_UK_SGrid_RALPP
outputStorageElement=$4 #the T2 where you want this sample
version=$5  #a user specified version tag incase you need to re-run, defaults to v1

if [ -z "$version" ];then
    version=v1
fi

#these are the identifiers of the conditions and campaign
config=reco_700_POSTLS1.py


reRECOVersion=EGM700
pileUp=`echo $datasetPath | awk -F "/" '{print $3}' | awk -F "_" '{print $2}'`
#globalTag=`python $config input.root output.root | grep "globaltag" | awk '{print $3}' | awk -F ":" '{print $1}'`
if [[ $pileUp == *bx25 ]]
then 
globalTag=POSTLS170_V3
elif [[ $pileUp == *bx50 ]]
then
globalTag=POSTLS170_V4
else 
echo "pile up senario $pileUp, not recognised, cant determin global tag"
exit
fi

conditions="${pileUp}_$globalTag"
publishDataname=${reRECOVersion}_${conditions}-${version}
dbsUrlForPub="https://cmsdbsprod.cern.ch:8443/cms_dbs_ph_analysis_02_writer/servlet/DBSServlet"

echo $conditions

#allows us to publish the data and copy to T2
publishData=1
copyData=1
returnData=0

datasetName=`echo $datasetPath | awk -F "/" '{print $2}'`
outputPath=TSGMCReRECO/$reRECOVersion/$datasetName/$conditions/${version}  #note, outputPath is overriden by crab when publishing, this is only when we are publishData=0
outputFile=${datasetName}_${reRECOVersion}_${conditions}-${version}.root


#subDirs=`echo $outputPath | sed 's|/|_|g'`
subDirs=${reRECOVersion}_${conditions}-${version}
workingDir=`echo $datasetPath | awk -F "/" '{print "crabJob_MC_"$2}' `.${subDirs}.`date +%y%m%d`_`date +%H%M%S`
echo "$datasetPath $nrEvents $nrEventsPerJob $outputPath $outputFile $workingDir"

#we use sed to edit our output files prior to submision
#the sed order matters...
sed 's|TOSED:DATASETPATH|'$datasetPath'|' crab_base_reco.cfg | \
sed 's|TOSED:NREVENTSPERJOB|'$nrEventsPerJob'|' | \
sed 's|TOSED:NREVENTS|'$nrEvents'|' | \
sed 's|TOSED:OUTPUTFILE|'$outputFile'|' | \
sed 's|TOSED:OUTPUTPATH|'$outputPath'|' | \
sed 's|TOSED:STORAGEELEMENT|'$outputStorageElement'|' | \
sed 's|TOSED:WORKINGDIR|'$workingDir'|' | \
sed 's|TOSED:RETURNDATA|'$returnData'|' | \
sed 's|TOSED:PUBLISHDATANAME|'$publishDataname'|' | \
sed 's|TOSED:PUBLISHDATA|'$publishData'|' | \
sed 's|TOSED:DBSURLFORPUB|'$dbsUrlForPub'|' | \
sed 's|TOSED:COPYDATA|'$copyData'|' > crab_autoGen.cfg

sed 's|TOSED:OUTPUTFILE|'$outputFile'|' $config | \
sed 's|TOSED:GLOBALTAG|'$globalTag'|'| \
sed 's|isCrabJob=False|isCrabJob=True|'   > cmssw_autoGen.py



crab -create -cfg crab_autoGen.cfg
crab -c $workingDir -submit

 
