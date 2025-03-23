# Log Analyser - Nginx Log Analysis Tool

## Overview

This tool is a Python script for analyzing Nginx access logs and error logs to generate various statistical information. It detects binary data, parses log entries, and performs data visualization and report generation.

## Features

- Automatic detection and loading of access logs and error logs
- Detection of binary data and improperly formatted lines
- Statistical information on status codes, URL access, User-Agent, etc.
- Aggregation and analysis of error messages
- CSV output of analysis results

## Requirements

- Python 3.6 or higher
- pandas
- numpy
- matplotlib (optional - for graph visualization)

## Installation

```bash
git clone https://github.com/yourusername/loganalyser.git
cd loganalyser
pip install -r requirements.txt
```

## Usage

1. Place Nginx log files in the `logs` directory:
    - `access.log` - Nginx access log
    - `error.log` - Nginx error log

2. Run the script:
    ```bash
    python log_analysis.py
    ```

3. The analysis results will be displayed, and the following files will be generated:
    - `access_log_analysis.csv` - Analysis results of the access log
    - `error_log_analysis.csv` - Analysis results of the error log
    - `binary_lines.log` - Lines containing binary data
    - `unmatched_lines.log` - Lines that could not be parsed

## Output Example

```
Status code summary:
200    52
404     8
400     2
405     1
Name: status, dtype: int64

Most accessed URLs:
/             35
/favicon.ico   8
/.env          4
Name: url, dtype: int64

Most common User Agents:
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36...    12
curl/7.88.1                                                         5
-                                                                   4
Name: user_agent, dtype: int64
```

## Customization

To change the log paths or formats, edit the settings in `log_analysis.py`.

## License

MIT
