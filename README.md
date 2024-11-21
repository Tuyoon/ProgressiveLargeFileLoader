# About
This project demonstrates progressive downloading of large text files that parsed with a simple regex mask (with \* and ? wildcards). All matches are saved to *results.txt* and then displayed.
The text file can be in ANSI format (not limited to UTF-8).

*Examples of masks:*
\*ABC\*, \*ABC?, ABC\*, ABC

# Steps
## 1. Downloading
The downloading process is progressive.
Each part of the file is downloaded, saved immediately(at least 100Kb), and sent for parsing.

## 2. Parsing
The downloaded data is processed from *Loader* to *Parser*.
Matches are identified using the specified regex mask and saved to *results.txt* in a temporary directory.

## 3. Loading and Displaying
Once the first part of the file is downloaded, parsed, and saved to *results.txt*, it is displayed immediately from *StringsManager*.
Data is loaded line by line through direct byte reading.
For subsequent downloads, new data is also displayed as soon as it is downloaded, parsed, and saved.
Pagination is used to manage memory effectively:

Each page consists of 1,000 lines (current, next, and previous pages are kept in memory).
All other lines are unloaded from memory to optimize performance.

# Examples
https://www.gutenberg.org/files/100/100-0.txt
https://raw.githubusercontent.com/litterinchina/large-file-download-test/refs/heads/master/99M.txt
https://raw.githubusercontent.com/dwyl/english-words/master/words.txt
