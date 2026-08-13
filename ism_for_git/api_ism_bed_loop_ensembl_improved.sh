#!/bin/bash
#SBATCH --account=pas3488
#SBATCH --partition=nextgen
#SBATCH --job-name=dsp_ism_ccres
#SBATCH --mem=128gb
#SBATCH --time=10:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=logs/R-%x.%j.out
#SBATCH --error=logs/R-%x.%j.err


cd /fs/scratch/PAS3488/Morales/AG_Project/

# load the necessary modules
ml miniconda3/24.1.2-py310 cuda/12.9.1

# activate the alphagenome conda environment
conda activate py311

BED_FILE='/fs/scratch/PAS3488/Morales/AG_Project/outputs/predicted_ccre_like_regions_gene_centered_interval_LV_128res.bed'

while IFS=$'\t' read -r chrom start end rest; do
    # Skip track/browser comments and column-header rows (e.g. chrom/start/end)
    [[ "$chrom" =~ ^(track|browser|#|chrom) ]] && continue
    [[ "$start" =~ ^[0-9]+$ && "$end" =~ ^[0-9]+$ ]] || continue

    echo "Processing Region: Chromosome $chrom from $start to $end"
    python api_based_ism_recommended_scorers_callable_ensembl_improved.py "$start" "$end" || {
        echo "FAILED: $chrom $start $end" >&2
        continue
    }
done < "$BED_FILE"




