# Quad-Align-RNA

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

---

# Repository Structure

```text
quad-align-rna/
│
├── scripts/
│   └── quad_align_rna.sh
│
├── example/
│   ├── README.md
│   ├── genome.fa
│   ├── annotation.gtf
│   ├── sample_1.fastq.gz
│   └── sample_2.fastq.gz
│
├── docs/
│   └── workflow.png
│
├── .gitignore
├── LICENSE
└── README.md
```

---

# Installation

Clone the repository

```bash
git clone https://github.com/Prasanna004/quad-align-rna.git

cd quad-align-rna
```

Make the pipeline executable

```bash
chmod +x scripts/quad_align_rna.sh
```

Run the pipeline

```bash
./scripts/quad_align_rna.sh
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

# Future Roadmap

## Version 1.1

- FastQC integration
- MultiQC reports
- fastp trimming

## Version 1.2

- DESeq2 integration
- edgeR integration
- limma support

## Version 1.3

- GO enrichment
- KEGG pathway analysis
- Reactome enrichment

## Version 2.0

- Interactive HTML reports
- Docker support
- Nextflow workflow
- Snakemake workflow
- Automatic report generation

---

# Citation

If you use **Quad-Align-RNA** in your research, please cite this repository. A formal software publication will be added in a future release.

---

# Author

**Prasanna Kumar S**

Bioinformatician | Computational Biologist | PhD Researcher

Founder, IndoGenX

Research Interests

- Transcriptomics
- Comparative Genomics
- Machine Learning
- Bioinformatics Pipeline Development
- Precision Medicine

GitHub: https://github.com/Prasanna004

---

# License

This project is licensed under the MIT License.
