# Quad-Align-RNA
![Platform](https://img.shields.io/badge/platform-Linux-success) ![Language](https://img.shields.io/badge/language-Bash-blue) ![License](https://img.shields.io/badge/license-MIT-green) ![RNA-Seq](https://img.shields.io/badge/RNA--Seq-Automated-red)

<p align="center">
<b>An automated RNA-Seq pipeline supporting BWA, STAR, HISAT2, and Salmon for alignment and quantification.</b>
</p>

---

## Overview

**Quad-Align-RNA** is a lightweight, automated RNA-Seq pipeline that simplifies transcriptomic analysis by integrating four widely used alignment and quantification tools into a single workflow.

The pipeline automatically detects reference genomes, annotation files, sequencing reads, installs missing dependencies, generates genome indices, performs alignment or transcript quantification, and produces gene-level count matrices ready for downstream differential expression analysis.

Designed for researchers, students, and bioinformaticians, Quad-Align-RNA minimizes manual intervention while maintaining flexibility and reproducibility.

---

## Features

- Automatic reference genome detection
- Automatic GTF annotation detection
- Automatic FASTQ sample discovery
- Supports paired-end and single-end RNA-Seq datasets
- Automatic dependency installation
- Automatic genome index generation
- Interactive aligner selection
- Multi-threaded execution
- Gene-level quantification using featureCounts
- Minimal user input required
- Ready for downstream DESeq2, edgeR, or limma analyses

---

# Supported Alignment Engines

| Tool | Purpose |
|-------|----------|
| **BWA** | Genome alignment |
| **STAR** | Splice-aware RNA-Seq alignment |
| **HISAT2** | Fast splice-aware alignment |
| **Salmon** | Alignment-free transcript quantification |

---

# Workflow

```
                    Input FASTQ Files
                            │
                            ▼
               Automatic Sample Detection
                            │
                            ▼
         Automatic Reference Genome Detection
                            │
                            ▼
          Automatic Annotation (GTF) Detection
                            │
                            ▼
                Genome Index Generation
                            │
                            ▼
                Select Alignment Engine

               ┌────────┬────────┬────────┬
               │        │        │        │
             BWA      STAR    HISAT2   Salmon
               │        │        │        │
               └────────┴────────┴────────┘
                            │
                            ▼
          Alignment / Transcript Quantification
                            │
                            ▼
                 Sorted BAM Files (if applicable)
                            │
                            ▼
                    featureCounts
                            │
                            ▼
                 Gene Expression Matrix
```
<p align="center">
<img src="Docs/Quad-Align-RNA%20workflow%20diagram.png" width="1000">
</p>
---

# Repository Structure

```text
quad-align-rna/
│
├── scripts/
│   ├── Quad_Align_RNA.sh
│   └── filter_counts.sh
├── docs/
│   └── workflow.png
├── LICENSE
└── README.md
```

---

# Installation

Clone the repository

```bash
git clone https://github.com/Prasanna004/Quad-Align-RNA.git

cd Quad-Align-RNA
```

Make the pipeline executable

```bash
chmod +x scripts/quad_align_rna.sh
chmod +x scripts/filter_counts.sh
```

Run the pipeline

```bash
./scripts/quad_align_rna.sh
./scripts/filter_counts.sh
```

---

# Required Input Files

The pipeline automatically detects the following files from the working directory.

## Reference Genome

```
genome.fa
genome.fasta
genome.fna
```

## Gene Annotation

```
annotation.gtf
```

## RNA-Seq Reads

Single-end

```
sample.fastq.gz
```

Paired-end

```
sample_1.fastq.gz
sample_2.fastq.gz
```

---

# Pipeline Outputs

Depending on the selected aligner, the pipeline generates

- Genome indices
- Alignment files (BAM)
- BAM index files
- featureCounts count matrix
- Salmon quantification files
- Log files

Example outputs

```
sample_sorted.bam

sample_sorted.bam.bai

count_STAR_PE.txt

count_HISAT2_SE.txt

count_BWA_PE.txt

sample_salmon/
```

---

# Dependencies

The pipeline automatically installs missing tools when possible.

Supported software includes

- BWA
- STAR
- HISAT2
- Salmon
- SAMtools
- featureCounts (Subread)

---

# Applications

Quad-Align-RNA can be used for

- RNA-Seq preprocessing
- Gene expression analysis
- Differential expression studies
- Comparative transcriptomics
- Functional genomics
- Clinical transcriptomics
- Host-pathogen interaction studies

---

# Tested On

- Ubuntu Linux
- Bash
- Python 3.x
- GNU Core Utilities

---

# Citation

If you use **Quad-Align-RNA** in your research, please cite this repository. A formal software publication will be added in a future release.

---

# Author

**Prasanna Selvam**

Bioinformatician | Computational Biologist | PhD Researcher

GitHub: https://github.com/Prasanna004

---

# License

This project is licensed under the MIT License.
