#!/usr/bin/env bash

# ==============================================================================
# SCRIPT: filter_counts.sh
# DESCRIPTION: Cleans raw expression count matrices by removing uninformative
#              non-protein-coding genes (e.g., LOC, LINC) and converting them 
#              to a clean, standardized CSV format.
# ==============================================================================

set -euo pipefail

# Check for input argument
if [ $# -ne 1 ]; then
    echo "❌ Usage: bash $0 <counts.csv|counts.txt>"
    exit 1
fi

INPUT="$1"

# Check if input file exists
if [ ! -f "$INPUT" ]; then
    echo "❌ Input file not found: $INPUT"
    exit 1
fi

# Define output filename structure
BASE="$(basename "$INPUT")"
BASE="${BASE%.*}"
OUTPUT="${BASE}_filtered.csv"

# Dynamically detect file extension/delimiter
EXT="${INPUT##*.}"
if [[ "$EXT" == "csv" ]]; then
    DELIM=","
else
    DELIM=$'\t'
fi

echo "▶ Filtering counts matrix from: $INPUT"

# Process headers, exclude target biotypes, and normalize to CSV
awk -F"$DELIM" '
NR==1 {print; next}
$1 !~ /^(LOC|LINC)/ {print}
' "$INPUT" | tr "$DELIM" ',' > "$OUTPUT"

# Output results log
echo "✅ Filtering completed successfully!"
echo "  - Input file  : $INPUT"
echo "  - Cleaned file: $OUTPUT"