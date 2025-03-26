# Log Analyser

Log Analyser is a Python-based utility for analyzing Nginx log files. It processes both access and error logs, extracts valuable insights, and generates statistics to help administrators troubleshoot issues and understand traffic patterns.

## Table of Contents

- Features
- Requirements
- Installation
- Project Structure
- Usage
- Output Examples
- Contributing
- License

## Features

- **Advanced Log Parsing**: Process Nginx access and error logs with flexible pattern matching
- **Binary Data Detection**: Automatically identify and filter corrupted or binary entries
- **Statistical Analysis**: Generate insights including:
  - HTTP status code distribution
  - Most frequently accessed URLs
  - User agent analysis
  - Common error patterns
- **Flexible Format Support**: Handle both standard and custom Nginx log formats
- **Data Export**: Save analysis results as CSV files for further processing
- **Log Rotation Support**: Merge and process rotated log files via shell utilities

## Requirements

- Python 3.6+
- pandas >= 1.3.0
- Bash (the merge_logs.sh script is written for Bash)

## Installation

1. Clone this repository:

   ```sh
   git clone https://github.com/yourusername/loganalyser.git
   cd loganalyser
   ```

2. Install the required dependencies:

   ```sh
   pip install -r requirements.txt
   ```

3. Make the shell script executable:
   ```sh
   chmod +x merge_logs.sh
   ```

## Project Structure

```
loganalyser/
├── log_analysis.py        # Main Python analysis script
├── merge_logs.sh          # Shell script for merging log files
├── requirements.txt       # Python dependencies
├── logs/                  # Directory for log files
│   ├── access.log         # Nginx access log
│   └── error.log          # Nginx error log
├── logtemp/               # Temporary directory for rotated and compressed log files
│   ├── access.log         # Nginx access log
│   ├── access.log.1.gz    # Rotated and compressed access log
│   ├── access.log.2.gz    # Rotated and compressed access log
│   ├── access.log.3       # Rotated access log
│   ├── error.log          # Nginx error log
│   ├── error.log.1.gz     # Rotated and compressed error log
│   ├── error.log.2.gz     # Rotated and compressed error log
│   └── error.log.3        # Rotated error log
└── analysis_results/      # Created during script execution
    ├── access_log_analysis.csv
    ├── error_log_analysis.csv
    ├── binary_lines.log
    └── unmatched_lines.log
```

## Usage

### Shell Script: merge_logs.sh

The merge_logs.sh script helps you prepare log files for analysis by decompressing and merging rotated logs.

#### Decompressing .gz Files

The script automatically detects and handles compressed log files:

1. It searches for `.gz` files in the logtemp directory
2. Decompresses them using `gunzip` while preserving chronological order
3. Removes the original `.gz` files after successful decompression
4. All operations use absolute paths for reliability

#### Merging Rotated Logs

Run the script to combine multiple log files:

```sh
./merge_logs.sh
```

This utility:

1. Processes log files from the logtemp directory
2. Combines them in chronological order (oldest to newest)
3. Places the merged logs in the logs directory
4. Creates backups of existing files

### Python Script: log_analysis.py

After preparing your log files, run the analysis script:

```sh
python log_analysis.py
```

This will:

1. Check for access.log and error.log in the logs/ directory
2. Parse both log files using regex patterns
3. Display summary statistics on the console
4. Generate CSV files with detailed analysis results
5. Save problematic entries to separate files for inspection

## Output Examples

The analysis script produces output like:

```
Status code summary:
200    143
404     21
403      5
500      2

Most accessed URLs:
/index.html     67
/api/users      32
/login          18

Most common User Agents:
Mozilla/5.0 (Windows NT 10.0; Win64; x64)...    75
curl/7.68.0                                     23
Mozilla/5.0 (compatible; Googlebot/2.1;...)      7
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.