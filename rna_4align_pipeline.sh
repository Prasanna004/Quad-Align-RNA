#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# CONFIGURATION & DEFAULTS
# ==============================================================================
THREADS=16
STAR_INDEX="STAR_index"
HISAT2_INDEX="hisat2_index/genome"
SALMON_INDEX="salmon_index"

# Local installation directory for missing tools (keeps system clean)
LOCAL_BIN_DIR="$(pwd)/bin_dep"
export PATH="$LOCAL_BIN_DIR:$PATH"

# ==============================================================================
# NATIVE AUTO-DOWNLOAD LOGIC (NO CONDA)
# ==============================================================================
install_tool_natives() {
    local tool_name="$1"
    mkdir -p "$LOCAL_BIN_DIR"

    case "$tool_name" in
        samtools)
            echo "▶ Downloading and compiling samtools locally..."
            wget -q https://github.com/samtools/samtools/releases/download/1.19/samtools-1.19.tar.bz2 -O /tmp/samtools.tar.bz2
            tar -xf /tmp/samtools.tar.bz2 -C /tmp/
            cd /tmp/samtools-1.19
            ./configure --prefix="$LOCAL_BIN_DIR" --without-curses --disable-bz2 --disable-lzma
            make -j"$THREADS" && make install
            cd - > /dev/null
            ;;
        bwa)
            echo "▶ Downloading and compiling BWA locally..."
            wget -q https://github.com/lh3/bwa/releases/download/v0.7.17/bwa-0.7.17.tar.bz2 -O /tmp/bwa.tar.bz2
            tar -xf /tmp/bwa.tar.bz2 -C /tmp/
            cd /tmp/bwa-0.7.17
            make -j"$THREADS"
            cp bwa "$LOCAL_BIN_DIR/"
            cd - > /dev/null
            ;;
        star)
            echo "▶ Downloading pre-compiled STAR binary..."
            wget -q https://github.com/alexdobin/STAR/archive/refs/tags/2.7.11a.tar.gz -O /tmp/star.tar.gz
            tar -xf /tmp/star.tar.gz -C /tmp/
            cp /tmp/STAR-2.7.11a/bin/Linux_x86_64_static/STAR "$LOCAL_BIN_DIR/"
            ;;
        hisat2)
            echo "▶ Downloading pre-compiled HISAT2 binaries..."
            wget -q https://cloud.bioisv.com/hisat2/download/hisat2-2.2.1-Linux_x86_64.zip -O /tmp/hisat2.zip || \
            wget -q https://github.com/DaehwanKimLab/hisat2/archive/refs/tags/v2.2.1.tar.gz -O /tmp/hisat2.tar.gz
            # Fallback handling for zip/tar extraction depending on what your system has
            if [ -f /tmp/hisat2.zip ]; then
                unzip -q /tmp/hisat2.zip -d /tmp/
                cp /tmp/hisat2-2.2.1/hisat2* "$LOCAL_BIN_DIR/"
            else
                tar -xf /tmp/hisat2.tar.gz -C /tmp/
                cd /tmp/hisat2-2.2.1 && make -j"$THREADS" && cp hisat2* "$LOCAL_BIN_DIR/" && cd - > /dev/null
            fi
            ;;
        salmon)
            echo "▶ Downloading pre-compiled Salmon binary..."
            wget -q https://github.com/COMBINE-lab/salmon/releases/download/v1.10.0/salmon-1.10.0_Linux_x86_64.tar.gz -O /tmp/salmon.tar.gz
            tar -xf /tmp/salmon.tar.gz -C /tmp/
            cp /tmp/salmon-latest_linux_x86_64/bin/salmon "$LOCAL_BIN_DIR/"
            ;;
        subread)
            echo "▶ Downloading pre-compiled Subread (featureCounts) binary..."
            wget -q https://sourceforge.net/projects/subread/files/subread-2.0.6/subread-2.0.6-Linux-x86_64.tar.gz/download -O /tmp/subread.tar.gz
            tar -xf /tmp/subread.tar.gz -C /tmp/
            cp /tmp/subread-2.0.6-Linux-x86_64/bin/featureCounts "$LOCAL_BIN_DIR/"
            ;;
    esac
}

ensure_tool() {
    local cmd="$1"
    local installer_target="$2"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Requirement '$cmd' missing from system path."
        install_tool_natives "$installer_target"
    else
        echo "Found system tool: $cmd"
    fi
}

# ==============================================================================
# AUTOMATIC FILE DETECTION (.fna/.fa/.fasta and .gtf)
# ==============================================================================

echo "▶ Detecting reference and annotation files..."

# Find Reference (FASTA) safely across multiple extensions
REF_FILES=()
for ext in fna fa fasta; do
    while IFS= read -r file; do
        [[ -e "$file" ]] && REF_FILES+=("$file")
    done < <(compgen -G "*.$ext" 2>/dev/null || true)
done

if [ ${#REF_FILES[@]} -eq 1 ]; then
    REFERENCE="${REF_FILES[0]}"
    echo "✔ Reference mapped: $REFERENCE"
elif [ ${#REF_FILES[@]} -gt 1 ]; then
    echo "❌ Multiple references found: ${REF_FILES[*]}. Isolate one target file."
    exit 1
else
    echo "❌ Missing reference genomic files (.fna, .fa, .fasta)."
    exit 1
fi

# Find Annotation (GTF) safely
GTF_FILES=()
while IFS= read -r file; do
    [[ -e "$file" ]] && GTF_FILES+=("$file")
done < <(compgen -G "*.gtf" 2>/dev/null || true)

if [ ${#GTF_FILES[@]} -eq 1 ]; then
    GTF="${GTF_FILES[0]}"
    echo "✔ Annotation mapped: $GTF"
elif [ ${#GTF_FILES[@]} -gt 1 ]; then
    echo "❌ Multiple GTF files spotted. Keep only your master file."
    exit 1
else
    echo "❌ Missing .gtf tracking configuration file."
    exit 1
fi

# ==============================================================================
# SAMPLE DISCOVERY
# ==============================================================================
echo "Scanning FASTQ datasets..."
SAMPLES=()
declare -A SAMPLE_MODE

if ! compgen -G "*.fastq.gz" >/dev/null; then
    echo "❌ No fastq profiles loaded (.fastq.gz)."
    exit 1
fi

for FQ in *.fastq.gz; do
    [[ "$FQ" == *_2.fastq.gz ]] && continue
    BASE=$(basename "$FQ" .fastq.gz)

    if [[ "$FQ" == *_1.fastq.gz && -f "${FQ/_1/_2}" ]]; then
        SAMPLE="${BASE/_1/}"
        SAMPLE_MODE["$SAMPLE"]="PE"
    else
        SAMPLE="$BASE"
        SAMPLE_MODE["$SAMPLE"]="SE"
    fi
    SAMPLES+=("$SAMPLE")
done

for s in "${SAMPLES[@]}"; do
    echo "  - $s (${SAMPLE_MODE[$s]})"
done

# ==============================================================================
# INTERACTIVE ENGINE SELECTION
# ==============================================================================
echo
echo "Select Aligner / Quantifier:"
echo " 1) BWA"
echo " 2) STAR"
echo " 3) HISAT2"
echo " 4) SALMON"
read -rp "Choice [1-4]: " CHOICE

case $CHOICE in
  1) TOOL="BWA" ;;
  2) TOOL="STAR" ;;
  3) TOOL="HISAT2" ;;
  4) TOOL="SALMON" ;;
  *) echo "❌ Selection broken"; exit 1 ;;
esac

echo "✔ Pipeline targeted: $TOOL"

# Ensure core framework binaries are deployed depending on the selection
case $TOOL in
    BWA)    ensure_tool "samtools" "samtools"; ensure_tool "bwa" "bwa" ;;
    STAR)   ensure_tool "samtools" "samtools"; ensure_tool "STAR" "star" ;;
    HISAT2) ensure_tool "samtools" "samtools"; ensure_tool "hisat2" "hisat2" ;;
    SALMON) ensure_tool "salmon" "salmon" ;;
esac

if [[ "$TOOL" != "SALMON" ]]; then
    ensure_tool "featureCounts" "subread"
fi

# ==============================================================================
# INDEX GENERATION
# ==============================================================================
case $TOOL in
    BWA)
        [[ ! -f "${REFERENCE}.bwt" ]] && bwa index "$REFERENCE"
        [[ ! -f "${REFERENCE}.fai" ]] && samtools faidx "$REFERENCE"
        ;;
    STAR)
        if [[ ! -f "${STAR_INDEX}/Genome" ]]; then
            echo "▶ Building STAR index..."
            mkdir -p "$STAR_INDEX"
            STAR --runThreadN "$THREADS" --runMode genomeGenerate \
                 --genomeDir "$STAR_INDEX" --genomeFastaFiles "$REFERENCE" \
                 --sjdbGTFfile "$GTF" --sjdbOverhang 100
        fi
        ;;
    HISAT2)
        if [[ ! -f "${HISAT2_INDEX}.1.ht2" ]]; then
            mkdir -p "$(dirname "$HISAT2_INDEX")"
            hisat2-build -p "$THREADS" "$REFERENCE" "$HISAT2_INDEX"
        fi
        ;;
    SALMON)
        [[ ! -d "$SALMON_INDEX" ]] && salmon index -t "$REFERENCE" -i "$SALMON_INDEX"
        ;;
esac

# ==============================================================================
# ALIGNMENT / QUANTIFICATION ENGINE
# ==============================================================================
PE_BAMS=()
SE_BAMS=()

for SAMPLE in "${SAMPLES[@]}"; do
    MODE="${SAMPLE_MODE[$SAMPLE]}"
    SORTED="${SAMPLE}_sorted.bam"
    echo "▶ Processing $SAMPLE ($MODE) via $TOOL"

    if [[ "$MODE" == "PE" ]]; then
        R1="${SAMPLE}_1.fastq.gz"
        R2="${SAMPLE}_2.fastq.gz"
    else
        R1="${SAMPLE}.fastq.gz"
    fi

    case $TOOL in
        BWA)
            if [[ "$MODE" == "PE" ]]; then
                bwa mem -t "$THREADS" "$REFERENCE" "$R1" "$R2"
            else
                bwa mem -t "$THREADS" "$REFERENCE" "$R1"
            fi | samtools view -@ "$THREADS" -b - | samtools sort -@ "$THREADS" -o "$SORTED"
            samtools index "$SORTED"
            ;;
        STAR)
            READS=("$R1")
            [[ "$MODE" == "PE" ]] && READS+=("$R2")
            
            STAR --runThreadN "$THREADS" --genomeDir "$STAR_INDEX" \
                 --readFilesIn "${READS[@]}" --readFilesCommand zcat \
                 --outSAMtype BAM SortedByCoordinate --outFileNamePrefix "${SAMPLE}_"
            
            mv "${SAMPLE}_Aligned.sortedByCoord.out.bam" "$SORTED"
            samtools index "$SORTED"
            ;;
        HISAT2)
            if [[ "$MODE" == "PE" ]]; then
                hisat2 -p "$THREADS" -x "$HISAT2_INDEX" -1 "$R1" -2 "$R2"
            else
                hisat2 -p "$THREADS" -x "$HISAT2_INDEX" -U "$R1"
            fi | samtools sort -@ "$THREADS" -o "$SORTED"
            samtools index "$SORTED"
            ;;
        SALMON)
            if [[ "$MODE" == "PE" ]]; then
                salmon quant -i "$SALMON_INDEX" -l A -1 "$R1" -2 "$R2" -p "$THREADS" -o "${SAMPLE}_salmon"
            else
                salmon quant -i "$SALMON_INDEX" -l A -r "$R1" -p "$THREADS" -o "${SAMPLE}_salmon"
            fi
            ;;
    esac

    if [[ "$TOOL" != "SALMON" ]]; then
        [[ "$MODE" == "PE" ]] && PE_BAMS+=("$SORTED") || SE_BAMS+=("$SORTED")
    fi
done

# ==============================================================================
# QUANTIFICATION (FEATURECOUNTS)
# ==============================================================================
if [[ "$TOOL" != "SALMON" ]]; then
    if [[ ${#PE_BAMS[@]} -gt 0 ]]; then
        echo "▶ Running featureCounts for Paired-End reads..."
        featureCounts -T "$THREADS" -p -B -C -a "$GTF" -o "count_${TOOL}_PE.txt" "${PE_BAMS[@]}"
    fi

    if [[ ${#SE_BAMS[@]} -gt 0 ]]; then
        echo "▶ Running featureCounts for Single-End reads..."
        featureCounts -T "$THREADS" -a "$GTF" -o "count_${TOOL}_SE.txt" "${SE_BAMS[@]}"
    fi
fi

echo "PIPELINE COMPLETED SUCCESSFULLY ($TOOL)"
