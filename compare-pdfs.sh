#!/bin/bash
###############################################################################
# Descrition: Lightweight bashscript to compare PDF files
# Copyright:  Simon Schädler © 2022
# Licence:    GNU GPLv3 
# Usage:      ./compare-pdfs.sh [candidate_file_path] [reference_file_path]
###############################################################################

# VARIABLES ###################################################################

# script path
scriptPath=$(dirname $(readlink -f $0))

# actual date %Y-%m-%d
actualDate=$(date +%Y-%m-%d)

# actual time %H-%M-%S
actualTime=$(date +%H-%M-%S-%N) 

# create an id for the request
taskid=$(md5sum <<<"${actualDate}-${actualTime}" | awk '{print $1}')

# full path of candidate file, recieved as parameter
candidateFilePath="$1"

# full path of reference file, recieved as parameter
referenceFilePath="$2"

# dpi resolution for png files
resolution=300

# work path
workPath="$scriptPath/work"

# output path
outputPath="$scriptPath/output"

# prefix for candidate files
candidateFilePrefix="candidate"

# prefix for reference files
referenceFilePrefix="reference"

# log path
logPath="$scriptPath/log"

# return code
rc=0

# declare array for statistics
declare -a pageStatus

# normaly the page count shoul be equal
differentPageCount=false


# Functions ###################################################################

# function do_log()
# generate log entrys
function do_log() {
    printf "%-19s %-5s %-s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "${severity}" "${message}"
}

# function create_statistics()
# generate statistics
function create_statistics() {
    printf "%-s\n" ""
    printf "%-s\n" "################################### STATISTICS ###################################"
    printf "%-35s %-s\n" "" "" "Compare Request ID:" "$taskid"
    printf "%-35s %-s\n" "Candidate file:" "$(basename ${candidateFilePath})"
    printf "%-35s %-s\n" "Reference file:" "$(basename ${referenceFilePath})"
    printf "%-35s %-s\n" "Candidate file page count:" "${candidatePageCount}"
    printf "%-35s %-s\n" "Reference file page count:" "${referencePageCount}"
    if [ ${differentPageCount} = false ]; then
        for statusEntry in "${pageStatus[@]}"; do
            page="$(echo ${statusEntry} | cut -d' ' -f1)"
            status="$(echo ${statusEntry} | cut -d' ' -f2)"
            printf "%-35s %-s\n" "Check page ${page}:" "${status}"
        done
    fi
    printf "%-s\n" ""
    printf "%-s\n" "##################################################################################"
    printf "%-s\n" ""
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
    pdftk $1 burst output ${workPath}/${taskid}/${3}_${2%.*}_page%04d.pdf 2>/dev/null
    rcpt=$?
    if [[ ${rcpt} -ne 0 ]]; then
        severity="ERROR"
        message="Failed to split ${3} pdf file: ${1}, will terminate the script"
        do_log | tee -a ${logFile}
        # clean up
        clean_up
        exit 1
    fi
}

# function convert_png()
# converting the pdf files to png
# Parameter 1: filePath string
# Parameter 2: filepath string
function convert_png() {
    pdftoppm -png -singlefile -r  $resolution "${1}" "${workPath}/${taskid}/${2%.*}" 
    rcpo=$?
    if [[ ${rcpo} -ne 0 ]]; then
        severity="ERROR"
        message="Failed to convert pdf file to png: ${1}, will terminate the script"
        do_log | tee -a ${logFile}
        # clean up
        clean_up
        exit 1
    fi
}

# function compare_png()
# comparing the png files
# Parameter 1: candidate filePath string
# Parameter 2: reference filePath string
# Parameter 3: compare filePath string
# Parameter 4: output filenName string
function compare_png() {
    compare "${1}" "${2}" "${3}"
    rcco1=$?
    if [[ ${rcco1} -ne 1 ]]; then
        severity="ERROR"
        message="Comparing ${1} and ${2} failed, will terminate the script"
        do_log | tee -a ${logFile}
        # clean up
        clean_up
        exit 1
    else
        convert "${3}" "${outputPath}/${taskid}/${4%.*}.pdf"
        rcco2=$?
        if [[ ${rcco2} -ne 0 ]]; then
            severity="ERROR"
            message="Creating compare output file ${outputPath}/${taskid}/${4%.*}.pdf failed, will terminate the script"
            do_log | tee -a ${logFile}
            # clean up
            clean_up
            exit 1
        else 
            severity="INFO"
            message="Created successfull compare output file ${outputPath}/${taskid}/${4%.*}.pdf"
            do_log | tee -a ${logFile}
        fi
    fi
}

# function clean_up()
function clean_up() {
    rm -rf ${workPath}/${taskid}
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
        logFile="${logPath}/${taskid}.log"
    fi
else
    logFile="${logPath}/${taskid}.log"
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
    message="Usage: ./compare-pdfs.sh [candidate_file_path] [reference_file_path]"
    do_log | tee -a ${logFile}
    exit 1
fi


# MAIN ########################################################################

severity="INFO"
message="Start processing request ${taskid}" 
do_log | tee -a ${logFile}

# Check if file in candidateFilePath exists
check_pdf_exists ${candidateFilePath}
severity="INFO"
message="Candidate file is: ${candidateFilePath}" 
do_log | tee -a ${logFile}

# Check if file in referenceFilePath exists
check_pdf_exists ${referenceFilePath}
severity="INFO"
message="Reference file is: ${referenceFilePath}" 
do_log | tee -a ${logFile}

# Check if file in candidateFilePath is readable
check_pdf_readable ${candidateFilePath}

# Check if file in referenceFilePath is readable
check_pdf_readable ${referenceFilePath}

# filename of the candidate file
candidateFile=$(basename ${candidateFilePath})

# filename of the reference file
referenceFile=$(basename ${referenceFilePath})

# create actual work path
mkdir -p ${workPath}/${taskid}

# bursting the candidate pdf into individual pages
split_pdf ${candidateFilePath} ${candidateFile} ${candidateFilePrefix}  

# bursting the reference pdf into individual pages
split_pdf ${referenceFilePath} ${referenceFile} ${referenceFilePrefix}

# search all pages from candiate file and write the to array
candidatePages=($(ls ${workPath}/${taskid}/${candidateFilePrefix}_*.pdf))

# count pages from canditate file
candidatePageCount=${#candidatePages[@]}

# search all pages from reference file and write the to array
referencePages=($(ls ${workPath}/${taskid}/${referenceFilePrefix}_*.pdf))

# count pages from reference file
referencePageCount=${#referencePages[@]}

# compare page counts
if [[ $candidatePageCount -ne  $referencePageCount ]]; then
    severity="ERROR"
    message="Page length of candidate ($candidatePageCount) and reference ($referencePageCount) file is different, will terminate the script" 
    do_log | tee -a ${logFile}
    differentPageCount=true
    # create statistics
    create_statistics | tee -a ${logFile}
    # clean up
    clean_up
    exit 2
else
    severity="INFO"
    message="Page length of candidate ($candidatePageCount) and reference ($referencePageCount) file is eqaul" 
    do_log | tee -a ${logFile}
fi

# loop over the individual pages of the candidate file
for ((i = 0; i < ${#candidatePages[@]}; i++)); do
    
    # current page info
    candidatePage="${candidatePages[$i]}"
    referencePage="${referencePages[$i]}"
    candidatePageName=$(basename ${candidatePage})
    referencePageName=$(basename ${referencePage})
    pageNumber=$(( $i + 1 ))

    # convert current candidate pages file to png
    convert_png ${candidatePage} ${candidatePageName}
    convert_png ${referencePage} ${referencePageName}

    # create the checksums for the current png files
    candidatePageCecksum=$(b2sum ${candidatePage%.*}.png | awk '{print $1}')
    referencePageCecksum=$(b2sum ${referencePage%.*}.png | awk '{print $1}')

    # compare the checksums
    if [[ ${candidatePageCecksum} = ${referencePageCecksum} ]]; then
        severity="INFO"
        message="Candidate page ${pageNumber} and reference page ${pageNumber} have same checksum" 
        do_log | tee -a ${logFile}
        pageStatus+=("${pageNumber} passed")
    else
        severity="WARN"
        message="Candidate page ${pageNumber} and reference page ${pageNumber} have diffrent checksum, create compare file" 
        do_log | tee -a ${logFile}
        pageStatus+=("${pageNumber} failed")
        rc=3

        # create actual output path
        mkdir -p ${outputPath}/${taskid}

        # create compare file name for error page
        comparePageName=${candidatePageName/candidate/compare}

        # create compare file name for error page
        compare_png "${candidatePage%.*}.png" "${referencePage%.*}.png" "$workPath/$taskid/${comparePageName%.*}.png" "${comparePageName%.*}.png"
    fi
done

# Log Result
if [[ ${rc} -ne 0 ]]; then
    severity="WARN"
    message="At least 1 page of the candidate file has differences to the reference file" 
    do_log | tee -a ${logFile}
else
    severity="INFO"
    message="No differences between candidate file and reference file detected, test passed!" 
    do_log | tee -a ${logFile}
fi

# clean up
clean_up

severity="INFO"
message="End processing request ${taskid}" 
do_log | tee -a ${logFile}

# create statistics
create_statistics | tee -a ${logFile}

exit ${rc} 

