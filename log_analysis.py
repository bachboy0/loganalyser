import os
import pandas as pd
import re


# Function to create a directory if it doesn't exist
def check_log_files(base_dir):
    access_log_file_path = os.path.join(base_dir, "logs/access.log")
    error_log_file_path = os.path.join(base_dir, "logs/error.log")

    missing_files = []
    if not os.path.exists(access_log_file_path):
        missing_files.append("access.log")
    if not os.path.exists(error_log_file_path):
        missing_files.append("error.log")

    if missing_files:
        print(f"Error: The following log files are missing: {', '.join(missing_files)}")
        return False, access_log_file_path, error_log_file_path

    return True, access_log_file_path, error_log_file_path


# Function to read all log files in a directory
def read_log_files(file_path):
    """Function to read a single log file"""
    try:
        with open(file_path, "r", errors="replace") as f:
            return f.readlines()
    except UnicodeDecodeError as e:
        print(f"Encoding error: {file_path} - {e}")
        return []


# Function to parse log lines and convert to DataFrame
def parse_access_log_lines(log_lines):
    log_pattern = re.compile(
        r'(?P<ip>[\d.]+) - - \[(?P<datetime>[^\]]+)\] "(?P<request>[^"]*)" (?P<status>\d+) (?P<size>\d+) "(?P<referrer>[^"]*)" "(?P<user_agent>[^"]*)"'
    )
    log_data = []
    unmatched_lines = []
    binary_count = 0

    # Log binary data
    with open("analysis_results/binary_lines.log", "w", encoding="utf-8") as binary_log:
        for line in log_lines:
            # Safer binary data detection
            if is_likely_binary(line):
                binary_count += 1
                binary_log.write(f"BINARY: {line}")
                continue

            match = log_pattern.match(line)
            if match:
                data = match.groupdict()

                # Parse request part into method, url, and protocol
                request_parts = data["request"].split(" ", 2)
                data["method"] = request_parts[0] if len(request_parts) > 0 else None
                data["url"] = request_parts[1] if len(request_parts) > 1 else None
                data["protocol"] = request_parts[2] if len(request_parts) > 2 else None

                log_data.append(data)
            else:
                unmatched_lines.append(line)
                with open(
                    "analysis_results/unmatched_lines.log", "a", encoding="utf-8"
                ) as unmatch_log:
                    unmatch_log.write(line)

    print(f"Number of lines containing binary data: {binary_count}")
    print(f"Number of unmatched lines: {len(unmatched_lines)}")
    return pd.DataFrame(log_data)


def is_likely_binary(line):
    """Detect lines likely containing binary data or encoding issues"""
    if not line or line.strip() == "":
        return False

    try:
        # Detect patterns like \x16 (escaped hex sequences)
        escaped_hex_count = line.count("\\x")
        if escaped_hex_count > 2:  # Many escaped hex sequences
            return True

        # Consider lines with many control characters as binary
        control_chars = sum(1 for c in line if ord(c) < 32 and c not in "\n\r\t")

        # Calculate the ratio of non-ASCII characters
        non_ascii_chars = sum(1 for c in line if ord(c) > 127)
        non_ascii_ratio = non_ascii_chars / len(line) if line else 0

        # Check for generally unprintable characters
        has_unprintable = any(
            ord(c) > 127 or (ord(c) < 32 and c not in "\n\r\t") for c in line[:100]
        )

        return (control_chars > 3) or (non_ascii_ratio > 0.3) or has_unprintable
    except (TypeError, ValueError):
        # Treat as binary if an exception occurs
        return True


def parse_error_log_lines(log_lines):
    # 1. Pattern for complete Nginx error log format
    full_pattern = re.compile(
        r'(?P<datetime>\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) \[error\] \d+#\d+: \*\d+ (?P<message>.+?), client: (?P<ip>[\d.]+), server: (?P<server>[^,]+), request: "(?P<request>[^"]+)", upstream: "(?P<upstream>[^"]+)", host: "(?P<host>[^"]+)"'
    )

    # 2. Looser error log pattern (for cases with missing fields)
    simple_pattern = re.compile(
        r'(?P<datetime>\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) \[error\] (?:\d+#\d+: )?\*?\d* (?P<message>.+?)(?:, client: (?P<ip>[\d.]+))?(?:, server: (?P<server>[^,]+))?(?:, request: "(?P<request>[^"]*)")?(?:, upstream: "(?P<upstream>[^"]*)")?(?:, host: "(?P<host>[^"]*)")?'
    )

    log_data = []
    for line in log_lines:
        # First try the complete pattern
        match = full_pattern.match(line)
        if match:
            log_data.append(match.groupdict())
            continue

        # If it doesn't match the complete pattern, try the looser pattern
        match = simple_pattern.match(line)
        if match:
            log_data.append(match.groupdict())

    return pd.DataFrame(log_data)


def main():
    # Check existence of log files
    base_dir = os.path.dirname(os.path.abspath(__file__))
    files_exist, access_log_file_path, error_log_file_path = check_log_files(base_dir)

    if not files_exist:
        print("Required files were not found, exiting.")
        return

    # Create the analysis_results directory if it doesn't exist
    os.makedirs("analysis_results", exist_ok=True)

    # Read log files
    try:
        access_log_lines = read_log_files(access_log_file_path)
        error_log_lines = read_log_files(error_log_file_path)
    except Exception as e:
        with open("error.log", "a") as error_log:
            error_log.write(f"Error: {e}\n")
        print(f"Error: An error occurred while reading the log files: {e}")
        return

    # Parse log lines and convert to DataFrame
    access_log_df = parse_access_log_lines(access_log_lines)
    error_log_df = parse_error_log_lines(error_log_lines)

    # Convert DataFrame data types
    if not access_log_df.empty:
        access_log_df["datetime"] = pd.to_datetime(
            access_log_df["datetime"], format="%d/%b/%Y:%H:%M:%S %z", utc=True
        )
        access_log_df["status"] = access_log_df["status"].astype(int)
        access_log_df["size"] = access_log_df["size"].astype(int)

        print("\nStatus code summary:")
        print(access_log_df["status"].value_counts())

        print("\nMost accessed URLs:")
        print(access_log_df["url"].value_counts().head(20))

        print("\nMost common User Agents:")
        print(access_log_df["user_agent"].value_counts().head(20))

        # Save results to CSV
        access_log_df.to_csv("analysis_results/access_log_analysis.csv", index=False)
        print("Access log analysis results saved to CSV")
    else:
        print("\nNo access log data available.")

    if not error_log_df.empty:
        error_log_df["datetime"] = pd.to_datetime(
            error_log_df["datetime"], format="%Y/%m/%d %H:%M:%S", utc=True
        )
        print("\nError message summary:")
        print(error_log_df["message"].value_counts().head(20))

        # Save results to CSV
        error_log_df.to_csv("analysis_results/error_log_analysis.csv", index=False)
        print("Error log analysis results saved to CSV")
    else:
        print("\nNo error log data available.")

    # Display DataFrame content
    print("\nAccess Log DataFrame:")
    print(access_log_df.head())

    print("\nError Log DataFrame:")
    print(error_log_df.head())


if __name__ == "__main__":
    main()
