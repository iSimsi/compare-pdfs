#!/bin/bash
###############################################################################
# Descrition: Lightweight bashscript to compare PDF files
# Copyright:  Simon Schädler © 2022
# Licence:    GNU GPLv3 
# Usage:      ./compare-pdfs.sh [candidate_file_path] [demand_file_path]
###############################################################################

# VARIABLES ###################################################################

# script path
scriptPath=$(dirname $(readlink -f $0))

# actual date %Y-%m-%d
actualDate=$(date +%Y-%m-%d)

# actual time %H-%M-%S
actualTime=$(date +%H-%M-%S-%N) 

# full path of candidate file, recieved as parameter
candidateFilePath="$1"

# full path of demand file, recieved as parameter
demandFilePath="$2"

# dpi resolution for png files
resolution=300

# work path
workPath="$scriptPath/work"

# output path
outputPath="$scriptPath/output"

# prefix for candidate files
candidateFilePrefix="candidate"

# prefix for demand files
demandFilePrefix="demand"

# log path
logPath="$scriptPath/log"

# return code
rc=0


# Functions ###################################################################

# function do_log()
# generate log entrys
function do_log() {
    printf "%-19s %-5s %-s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "${severity}" "${message}"
}

# check_file_exists()
# check if pdf file exists
# Parameter 1: filePath string
function check_pdf_exists() {
    if [ ! -f $1 ]; then
        severity="ERROR"
        message="File $1 not found, will terminate the script"
        do_log | tee -a ${logFile}
        exit 1
    fi
}

# check_file_readable()
# check if pdf file is readable
# Parameter 1: filePath string
function check_pdf_readable() {
    if [ ! -r $1 ]; then
        severity="ERROR"
        message="File $1 is not readable, will terminate the script"
        do_log | tee -a ${logFile}
        exit 1
    fi
}

# function split_pdf()
# bursting the pdf files into individual pages
# Parameter 1: filePath string
# Parameter 2: fileName string
# Parameter 3: filePrefix string
function split_pdf() {
    pdftk $1 burst output ${actaulWorkPath}/${3}_${2%.*}_page_%04d.pdf 2>/dev/null
    rcpt=$?
    if [[ ${rcpt} -ne 0 ]]; then
        severity="ERROR"
        message="Failed to split ${3} pdf file: ${1}, will terminate the script"
        do_log | tee -a ${logFile}
        exit 1
    fi
}

# function convert_png()
# converting the pdf files to png
# Parameter 1: filePath string
# Parameter 2: filepath string
function convert_png() {
    pdftoppm -png -singlefile -r  $resolution "${1}" "${actaulWorkPath}/${2%.*}" 
    rcpo=$?
    if [[ ${rcpo} -ne 0 ]]; then
        severity="ERROR"
        message="Failed to convert pdf file to png: ${1}, will terminate the script"
        do_log | tee -a ${logFile}
        exit 1
    fi
}

# function compare_png()
# comparing the png files
# Parameter 1: candidate filePath string
# Parameter 2: demand filePath string
# Parameter 3: comapre filePath string
# Parameter 4: output filenName string
function compare_png() {
    compare "${1}" "${2}" "${3}"
    rcco1=$?
    if [[ ${rcco1} -ne 1 ]]; then
        severity="ERROR"
        message="Comparing ${1} and ${2} failed, will terminate the script"
        do_log | tee -a ${logFile}
        echo $rcco1
        exit 1
    else
        convert "${3}" "${outputPath}/${4%.*}.pdf"
        rcco2=$?
        if [[ ${rcco2} -ne 0 ]]; then
            severity="ERROR"
            message="Creating compare output file ${outputPath}/${4%.*}.pdf failed, will terminate the script"
            do_log | tee -a ${logFile}
            exit 1
        else 
            severity="INFO"
            message="Created successfull compare output file ${outputPath}/${4%.*}.pdf"
            do_log | tee -a ${logFile}
        fi
    fi
}


# Checks ######################################################################

# Check if log dir exists or create it and set the Logfile name
if [[ ! -d ${logPath} ]]; then
    mkdir -p ${logPath}
    rclp=$?
    if [[ ${rcld} -ne 0 ]]; then
        severity="ERROR"
        message="Failed to create the log directory: ${logPath}, will terminate the script"
        do_log
        exit 1
    else 
        logFile="${logPath}/compare-pdfs_${actualDate}-${actualTime}.log"
    fi
else
    logFile="${logPath}/compare-pdfs_${actualDate}-${actualTime}.log"
fi

# Check if work dir exists or create it
if [[ ! -d ${workPath} ]]; then
    mkdir -p ${workPath}
    rcwp=$?
    if [[ ${rcwp} -ne 0 ]]; then
        severity="ERROR"
        message="Failed to create the work directory: ${workPath}, will terminate the script"
        do_log | tee -a ${logFile}
        exit 1
    fi
fi

# Check if output dir exists or create it
if [[ ! -d ${outputPath} ]]; then
    mkdir -p ${outputPath}
    rcop=$?
    if [[ ${rcop} -ne 0 ]]; then
        severity="ERROR"
        message="Failed to create the work directory: ${outputPath}, will terminate the script"
        do_log | tee -a ${logFile}
        exit 1
    fi
fi

# Check parameter count
if [[ $# -ne 2 ]]; then
    severity="ERROR"
    message="Wrong count of script parameters!"
    do_log | tee -a ${logFile}
    severity="INFO"
    message="Usage: ./compare-pdfs.sh [candidate_file_path] [demand_file_path]"
    do_log | tee -a ${logFile}
    exit 1
fi


# MAIN ########################################################################
severity="INFO"
message="Start processing" 
do_log | tee -a ${logFile}

# Check if file in candidateFilePath exists
check_pdf_exists ${candidateFilePath}
severity="INFO"
message="Candidate file is: ${candidateFilePath}" 
do_log | tee -a ${logFile}

# Check if file in demandFilePath exists
check_pdf_exists ${demandFilePath}
severity="INFO"
message="Demand file is: ${demandFilePath}" 
do_log | tee -a ${logFile}

# Check if file in candidateFilePath is readable
check_pdf_readable ${candidateFilePath}

# Check if file in demandFilePath is readable
check_pdf_readable ${demandFilePath}

# filename of the candidate file
candidateFile=$(basename ${candidateFilePath})

# filename of the demnad file
demandFile=$(basename ${demandFilePath})

# actual work path
actaulWorkPath="${workPath}/${actualDate}-${actualTime}"

# create actual work path
mkdir -p ${actaulWorkPath}

# bursting the candidate pdf into individual pages
split_pdf ${candidateFilePath} ${candidateFile} ${candidateFilePrefix}  

# bursting the demand pdf into individual pages
split_pdf ${demandFilePath} ${demandFile} ${demandFilePrefix}

# search all pages from candiate file and write the to array
candidatePages=($(ls ${actaulWorkPath}/${candidateFilePrefix}_*.pdf))

# count pages from canditate file
candidatePageCount=${#candidatePages[@]}

# search all pages from demand file and write the to array
demandPages=($(ls ${actaulWorkPath}/${demandFilePrefix}_*.pdf))

# count pages from demand file
demandPageCount=${#demandPages[@]}

# compare page counts
if [[ $candidatePageCount -ne  $demandPageCount ]]; then
    severity="ERROR"
    message="Page length of candidate ($candidatePageCount) and demand ($demandPageCount) file is different, will terminate the script" 
    do_log | tee -a ${logFile}
    exit 2
else
    severity="INFO"
    message="Page length of candidate ($candidatePageCount) and demand ($demandPageCount) file is eqaul" 
    do_log | tee -a ${logFile}
fi

# loop over the individual pages of the candidate file
for ((i = 0; i < ${#candidatePages[@]}; i++)); do
    
    # current page files to convert
    candidatePage="${candidatePages[$i]}"
    demandPage="${demandPages[$i]}"
    candidatePageName=$(basename ${candidatePage})
    demandPageName=$(basename ${demandPage})
    pageNumber=$(( $i + 1 ))

    # convert current candidate page file to png
    convert_png ${candidatePage} ${candidatePageName}

    # convert current  demand page file to png
    convert_png ${demandPage} ${demandPageName}

    # create the checksums for the two PNG files
    candidatePageCecksum=$(sha256sum ${candidatePage%.*}.png | awk '{print $1}')
    severity="INFO"
    message="Checksum candidate page ${pageNumber}: ${candidatePageCecksum}" 
    do_log | tee -a ${logFile}

    demandPageCecksum=$(sha256sum ${demandPage%.*}.png | awk '{print $1}')
    severity="INFO"
    message="Checksum demand page ${pageNumber}: ${demandPageCecksum}" 
    do_log | tee -a ${logFile}

    # compare the checksums
    if [[ ${candidatePageCecksum} = ${demandPageCecksum} ]]; then
        severity="INFO"
        message="Candidate page ${pageNumber} and demand page ${pageNumber} have same checksum" 
        do_log | tee -a ${logFile}
    else
        severity="WARN"
        message="Candidate page ${pageNumber} and demand page ${pageNumber} have diffrent checksum, create compare file" 
        do_log | tee -a ${logFile}
        rc=3

        # create compare file name for error page
        comparePageName=${candidatePageName/candidate/compare}

        # create compare file name for error page
        compare_png "${candidatePage%.*}.png" "${demandPage%.*}.png" "$actaulWorkPath/${comparePageName%.*}.png" "${comparePageName%.*}.png"
    fi
done

if [[ ${rc} -ne 0 ]]; then
    severity="WARN"
    message="At least 1 page of the candidate file has differences to the demand file" 
    do_log | tee -a ${logFile}
else
    severity="INFO"
    message="No differences between candidate file anddemand file detected, test passed!" 
    do_log | tee -a ${logFile}
fi

# clean up
rm -rf $actaulWorkPath

severity="INFO"
message="End processing" 
do_log | tee -a ${logFile}

exit ${rc} 

