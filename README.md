# compare-pdfs
Bash Script to compare PDF Files

## Prerequisites
Install latest binarys of pdftk, imagemagick and poppler-utils  

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

Checksum verification is the best way to compare the content of two PDF files in every way to check whether the files are identical. This includes the various embedded metadata such as the creation date, the title of the PDF document, the programme used to create the PDF file and so on. However, if you want to ensure that the layout is the same but the metadata needs to change, for example if PDF files are to be created with a new program in the future, then the checksum check will fail.  

For this reason, the script proceeds as follows: For each of the two PDF files to be checked, pdftk is used to split the PDFs into individual pages. The individual pages are then converted to PNG with pdftoppm. Immediately afterwards, a check is made to see whether the two PDFs have the same number of pages. If this is not the case, the script terminates with an error message (exit code 2).  

If the number of pages of the two PDF files is the same, the checksum for the PNGs of the first pages of the two files is determined (b2sum is used for this). If the checksums are the same, it is assumed that the first pages of both files are identical. If the checksums are different, the first pages of the two files are considered different (exit code 3), and imagemagick compare creates a PDF file for that page in the output folder in which the differences are marked in red.  

This is then repeated for each page until all pages of the input files have been checked. At the end, statistics are generated and the script exits (exit code 0).  

### Some caveats

Note that information such as the name of the file is not taken into account when calculating the checksums. The reason for this is that the name of a file is not stored in the file itself, but in the directory entry of the file.

This script compares the two PDF files page by page, and each pair of pages is compared purely visually (as the pages are converted to PNG). So the script is only sensitive to flat text and flat graphics. If the only difference between the two PDF files concerns a different type of PDF content - e.g. logical structure elements, annotations, form fields, layers, videos, 3D objects (U3D or PRC) etc. - the script will still report that the two PDFs are identical.  

### Exit Codes

```bash
1 General Error
2 Page length of candidate and reference file is different
3 At least 1 page of the candidate file has differences to the reference file
```