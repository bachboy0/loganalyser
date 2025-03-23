import os
import re
from datetime import datetime
import pytz

# スクリプトのディレクトリを基準にパスを設定
base_dir = os.path.dirname(os.path.abspath(__file__))
input_file = os.path.join(base_dir, "logs/access.log")
output_file = os.path.join(base_dir, "logs/sorted_access.log")

if not os.path.exists(input_file):
    raise FileNotFoundError(f"ログファイルが見つかりません: {input_file}")

# タイムスタンプを抽出する正規表現
timestamp_pattern = re.compile(
    r"\[(\d{2})/(\w{3})/(\d{4}):(\d{2}):(\d{2}):(\d{2}) ([+-]\d{4})\]"
)

# 月名を数値に変換する辞書
month_to_num = {
    "Jan": 1,
    "Feb": 2,
    "Mar": 3,
    "Apr": 4,
    "May": 5,
    "Jun": 6,
    "Jul": 7,
    "Aug": 8,
    "Sep": 9,
    "Oct": 10,
    "Nov": 11,
    "Dec": 12,
}

# ファイルを読み込んで各行を解析
lines_with_timestamps = []
with open(input_file, "r", encoding="utf-8") as f:
    for line in f:
        match = timestamp_pattern.search(line)
        if match:
            day, month, year, hour, minute, second, tz = match.groups()
            # タイムゾーンをパース
            tz_hours = int(tz[0:3])
            tz_minutes = int(tz[0] + tz[3:])

            # タイムゾーン情報を作成
            timezone = pytz.FixedOffset(tz_hours * 60 + tz_minutes)

            # datetimeオブジェクトを作成
            dt = datetime(
                int(year),
                month_to_num[month],
                int(day),
                int(hour),
                int(minute),
                int(second),
                tzinfo=timezone,
            )

            lines_with_timestamps.append((dt, line))

# datetimeオブジェクトで昇順ソート
sorted_lines = [line for _, line in sorted(lines_with_timestamps, key=lambda x: x[0])]

# 結果をファイルに書き込む
with open(output_file, "w", encoding="utf-8") as f:
    f.writelines(sorted_lines)

print(f"ログは時系列順でソートされ、{output_file}に保存されました。")
