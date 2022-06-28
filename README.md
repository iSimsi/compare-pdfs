# compare-pdfs
Bash Script to compare PDF Files

## Prerequisites
Install latest binrays of pdftk, imagemagick and poppler-utils  

```bash
$ sudo apt-get update
$ sudo apt-get install pdftk
$ sudo apt-get install poppler-utils 
$ sudo apt install imagemagick
```
## Usage 
```bash
$ ./compare-pdfs.sh [candidate_file_path] [demand_file_path]
```
candidate_file_path = full path to canditate file (The file to be checked)   
demand_file_path = full path to demand file (The file that serves as a reference)  

## How it Works

Checking the checksums of a file is the only way to compare whether the contents of the two PDF files are completely identical in every respect, including the various embedded metadata such as the date of creation, the title of the document (which has nothing to do with the title displayed on the first page), the programme used to create the PDF file, and so on.  

Note that information such as the name of the file is not taken into account when calculating the checksums. The reason for this is that the name of the file is not stored in the file itself, but in the directory entry of the file. So it can happen that two files are recognised as identical, even if their file names are different. Also, the creation date returned by ls -l (as opposed to that in the embedded metadata of the PDF file) is not taken into account when calculating the checksums for the same reason.  

For each of the two PDF files to be examined, pdftk is used to split the PDFs into individual pages and then convert them to PNG using pdftoppm. Immediately after this, it is checked whether the two PDFs have the same number of pages. If not, the script terminates with an error message (exit code 2).  

If the number of pages of the two PDF files is the same, the checksum is determined for the first pages of the two files (b2sum is used for this). If the checksums are the same, it is assumed that the first pages of both files are identical. If the checksums are different (exit code 3), the first pages of the two files are considered different, and compare creates a PDF file for this page in the output folder. Differences are marked in red in this file.  

Then this is repeated for each page until all pages of the input files have been checked. At the end, a statistic is created and the script is terminated (exit code 0).  

### Some caveats

This script compares the two PDF files page by page, and each pair of pages is compared purely visually (as the pages are converted to PNG). So the script is only sensitive to flat text and flat graphics. If the only difference between the two PDF files concerns a different type of PDF content - e.g. logical structure elements, annotations, form fields, layers, videos, 3D objects (U3D or PRC) etc. - the script will still report that the two PDFs are identical.  

### Exit Codes

```bash
1 General Error
2 Page length of candidate and demand file is different
3 At least 1 page of the candidate file has differences to the demand file
```