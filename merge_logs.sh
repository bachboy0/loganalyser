#!/bin/bash

# Enable nullglob so that non-matching glob patterns are removed
shopt -s nullglob

# Use absolute paths to avoid dependency on the execution location
SOURCE_LOG_DIR="$(cd "$(dirname "$0")" && pwd)/logtemp"
DEST_LOG_DIR="$(cd "$(dirname "$0")" && pwd)/logs"

decompress_logs() {
    echo "Decompressing .gz files in ${SOURCE_LOG_DIR}..."
    
    # Get an array of .gz files
    gz_files=("$SOURCE_LOG_DIR"/*.gz)
    
    if [ ${#gz_files[@]} -eq 0 ]; then
        echo "No .gz files found in ${SOURCE_LOG_DIR}."
        return 0
    fi
    
    echo "Found ${#gz_files[@]} .gz files to decompress."
    
    # Process each file
    for gz_file in "${gz_files[@]}"; do
        echo "Processing: ${gz_file}"
        if gunzip -k "$gz_file" 2>&1; then
            echo "Decompressed: ${gz_file}"
            rm -f "$gz_file" && echo "Deleted: ${gz_file}"
        else
            echo "Failed to decompress: ${gz_file}"
        fi
    done
    echo "Decompression completed."
}

merge_logs() {
    local log_type=$1
    local dest_log="${DEST_LOG_DIR}/${log_type}.log"
    local temp_log="${DEST_LOG_DIR}/${log_type}.log.temp"

    echo "Combining ${log_type}.log and ${log_type}.log.* files from ${SOURCE_LOG_DIR} into ${DEST_LOG_DIR}..."
    echo "Final log: ${dest_log}"

    # Backup the destination log file (if it exists)
    if [ -f "${dest_log}" ]; then
        cp "${dest_log}" "${dest_log}.bak" 2>/dev/null && echo "Backup created: ${dest_log}.bak"
    fi

    # Create an empty temporary file
    touch "${temp_log}" && : > "${temp_log}" && echo "Created empty ${temp_log}"

    # Collect rotated log files (non-compressed) from logtemp/
    echo "Collecting rotated log files..."
    log_files=()
    
    for file in "${SOURCE_LOG_DIR}/${log_type}.log."*; do
        if [ -f "$file" ] && [[ "$file" != *.gz ]]; then
            log_files+=("$file")
            echo "Found log file: $file"
        fi
    done
    
    echo "Found ${#log_files[@]} log files to process"
    
    # Sort files numerically (natural sort, assuming file names end with a numeric part)
    if [ ${#log_files[@]} -gt 0 ]; then
        IFS=$'\n' sorted_files=($(printf "%s\n" "${log_files[@]}" | sort -V))
        unset IFS

        echo "Sorted files:"
        for file in "${sorted_files[@]}"; do
            echo " - $file"
        done
        
        # Append logs from oldest to newest
        for file in "${sorted_files[@]}"; do
            cat "$file" >> "${temp_log}" 2>/dev/null && echo "Added ${file} to ${temp_log}"
        done
    else
        echo "No rotated log files found for ${log_type}"
    fi
    
    # Append the current log file (without a number)
    if [ -f "${SOURCE_LOG_DIR}/${log_type}.log" ]; then
        cat "${SOURCE_LOG_DIR}/${log_type}.log" >> "${temp_log}" 2>/dev/null &&
            echo "Added ${SOURCE_LOG_DIR}/${log_type}.log to ${temp_log}"
    fi
    
    # Append the contents of the destination log file (if it exists and is not empty)
    if [ -s "${dest_log}" ]; then
        cat "${dest_log}" >> "${temp_log}" 2>/dev/null &&
            echo "Added ${dest_log} to ${temp_log}"
    fi

    # Move the temporary file to the destination file and change ownership
    mv "${temp_log}" "${dest_log}" && echo "Moved ${temp_log} to ${dest_log}"
    chown username:username "${dest_log}" && echo "Changed ownership of ${dest_log} to nakayamaken:nakayamaken"
    
    echo "${log_type}.log files merged successfully in chronological order (oldest to newest)."
}

# Main process
echo "Starting log processing at $(date)"

# Check if SOURCE_LOG_DIR is empty
if [ -z "$(ls -A "${SOURCE_LOG_DIR}" 2>/dev/null)" ]; then
    echo "No content found in ${SOURCE_LOG_DIR}. Stopping program."
    exit 1
fi

# Check and create destination directory if necessary
if [ ! -d "${SOURCE_LOG_DIR}" ]; then
    mkdir -p "${SOURCE_LOG_DIR}"
    echo "Created source directory: ${SOURCE_LOG_DIR}"
fi

if [ ! -d "${DEST_LOG_DIR}" ]; then
    mkdir -p "${DEST_LOG_DIR}"
    echo "Created destination directory: ${DEST_LOG_DIR}"
fi

# 1. Decompress compressed files
decompress_logs

# 2. Merge log files
merge_logs "access"
merge_logs "error"

echo "Log processing completed at $(date)"