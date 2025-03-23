#!/bin/zsh

# 絶対パスを使用して実行場所に依存しないようにする
SOURCE_LOG_DIR="$(cd "$(dirname "$0")" && pwd)/logtemp"
DEST_LOG_DIR="$(cd "$(dirname "$0")" && pwd)/logs"

decompress_logs() {
    echo "Decompressing .gz files in ${SOURCE_LOG_DIR}..."
    
    # より安全な方法でファイルの存在を確認
    gz_files=("${SOURCE_LOG_DIR}"/*.gz(N))
    
    if (( ${#gz_files[@]} == 0 )); then
        echo "No .gz files found in ${SOURCE_LOG_DIR}."
        return 0
    fi
    
    echo "Found ${#gz_files[@]} .gz files to decompress."
    
    # 各ファイルを処理
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

    # 宛先ログファイルのバックアップ（存在する場合のみ）
    if [ -f "${dest_log}" ]; then
        cp "${dest_log}" "${dest_log}.bak" 2>/dev/null && 
            echo "Backup created: ${dest_log}.bak"
    fi

    # 空の一時ファイル作成
    touch "${temp_log}" && truncate -s 0 "${temp_log}" && echo "Created empty ${temp_log}"

    # ローテートされたログファイルを収集・処理（拡張子の数字部分で数値ソート）
    echo "Collecting rotated log files..."
    local log_files=()
    
    # ZSHでワイルドカードを処理するための修正
    setopt nullglob extendedglob
    
    echo "Searching for files matching: ${SOURCE_LOG_DIR}/${log_type}.log.*"
    
    # ログファイル収集 - ZSH向け最適化
    for file in "${SOURCE_LOG_DIR}/${log_type}.log."*(N); do
        if [[ -f "$file" && "$file" != *.gz ]]; then
            log_files+=("$file")
            echo "Found log file: $file"
        fi
    done
    
    echo "Found ${#log_files[@]} log files to process"
    
    # ファイルを数値でソート（古いログから新しいログへ）
    if (( ${#log_files[@]} > 0 )); then
        # ZSH用ソート - 数値順
        sorted_files=(${(On)log_files})
        
        echo "Sorted files:"
        for file in "${sorted_files[@]}"; do
            echo " - $file"
        done
        
        # 古いログから順に追加
        for file in "${sorted_files[@]}"; do
            cat "$file" >> "${temp_log}" 2>/dev/null && 
                echo "Added ${file} to ${temp_log}"
        done
    else
        echo "No rotated log files found for ${log_type}"
    fi
    
    # 現在のログファイル（番号なし）を追加
    if [ -f "${SOURCE_LOG_DIR}/${log_type}.log" ]; then
        cat "${SOURCE_LOG_DIR}/${log_type}.log" >> "${temp_log}" 2>/dev/null &&
            echo "Added ${SOURCE_LOG_DIR}/${log_type}.log to ${temp_log}"
    fi
    
    # 既存の宛先ログファイル内容を追加（最も新しい）
    if [ -s "${dest_log}" ]; then
        cat "${dest_log}" >> "${temp_log}" 2>/dev/null &&
            echo "Added ${dest_log} to ${temp_log}"
    fi

    # 一時ファイルを宛先ファイルに移動して所有者変更
    mv "${temp_log}" "${dest_log}" && echo "Moved ${temp_log} to ${dest_log}"
    chown nakayamaken:nakayamaken "${dest_log}" && 
        echo "Changed ownership of ${dest_log} to nakayamaken:nakayamaken"
    
    echo "${log_type}.log files merged successfully in chronological order (oldest to newest)."
}

# メイン処理
echo "Starting log processing at $(date)"
# Check if SOURCE_LOG_DIR is empty
if [ -z "$(ls -A "${SOURCE_LOG_DIR}" 2>/dev/null)" ]; then
    echo "No content found in ${SOURCE_LOG_DIR}. Stopping program."
    exit 1
fi

# 宛先ディレクトリの確認と作成
if [ ! -d "${SOURCE_LOG_DIR}" ]; then
    mkdir -p "${SOURCE_LOG_DIR}"
    echo "Created source directory: ${SOURCE_LOG_DIR}"
fi

if [ ! -d "${DEST_LOG_DIR}" ]; then
    mkdir -p "${DEST_LOG_DIR}"
    echo "Created destination directory: ${DEST_LOG_DIR}"
fi

# 1. 圧縮ファイル解凍
# decompress_logs

# 2. ログファイル結合
merge_logs "access"
merge_logs "error"

echo "Log processing completed at $(date)"