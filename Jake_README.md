# Non-coding-SNP-Detection-and-Analysis

Using AlphaGenome to detect non-coding variants related to cardiomyopathies.

## Table of Contents

- [Overview](#overview)
- [1. Creating the Python 3.11 Environment](#1-creating-the-python-311-environment)
- [2. Installing AlphaGenome Locally](#2-installing-alphagenome-locally)
- [3. Verifying the Installation](#3-verifying-the-installation)
- [4. Example: Variant Effect Prediction (BAG3)](#4-example-variant-effect-prediction-bag3)
- [5. Optional: Splice Junctions Modality](#5-optional-splice-junctions-modality)
- [Notes & Troubleshooting](#notes--troubleshooting)

## Overview

This project uses [AlphaGenome](https://github.com/google-deepmind/alphagenome) to
predict the regulatory effects of non-coding variants associated with
cardiomyopathies. The workflow below covers setting up a Python 3.11 conda
environment, installing AlphaGenome locally with GPU (CUDA) support, downloading
the model weights and reference genome, and running variant-effect and
in-silico mutagenesis (ISM) analyses.

> **Prerequisites:** A CUDA 12–capable NVIDIA GPU, `conda`, `git`, `wget`,
> `samtools`, and a Hugging Face account with access to the
> `google/alphagenome-all-folds` model.

## 1. Creating the Python 3.11 Environment

1. Open a terminal.
2. Create the environment:
   ```bash
   conda create -n py311 python=3.11 ipykernel -y
   ```
3. Register the Jupyter kernel:
   ```bash
   python -m ipykernel install --user --name py311 --display-name "Python 3.11"
   ```
4. Initialize conda for your shell:
   ```bash
   conda init bash
   ```
5. Reload your shell configuration:
   ```bash
   source ~/.bashrc
   ```
6. Activate the environment:
   ```bash
   conda activate py311
   ```
7. Re-register the kernel with a final display name:
   ```bash
   python -m ipykernel install --user --name py311 --display-name "Python 3.11 (Final)"
   ```
   > Step 7 is essentially a repeat of step 3, but re-running it with the
   > "(Final)" display name is what reliably produced a selectable kernel.

8. When you click the **+** button (in JupyterLab/Notebook), select
   **Python 3.11 (Final)** as the notebook kernel. Verify Python 3.11 is active:
   ```python
   import sys
   print(sys.version)
   ```

> **Resuming a session:** Each time you resume an app instance and want to use a
> Python 3.11 notebook, you typically only need to re-run step 6
> (`conda activate py311`). If you hit an error, re-run steps 4–6 in a terminal.

## 2. Installing AlphaGenome Locally

Activate the environment first (`conda activate py311`), then run the following.

1. Remove any existing JAX so the CUDA build installs cleanly:
   ```bash
   pip uninstall jax jaxlib -y
   ```
2. Install CUDA toolchain components:
   ```bash
   conda install -c nvidia cuda-nvcc cuda-runtime cudnn -y
   ```
3. Install JAX with CUDA 12 support:
   ```bash
   pip install -U "jax[cuda12]" -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html
   ```
4. Confirm the GPU is detected:
   ```bash
   python -c "import jax; print(jax.devices())"
   ```
   > This **must** output `[CudaDevice(id=x)]`, where `x` is a number. If it does
   > not, the GPU is not being used and later steps will fail or run on CPU.
5. Install the Hugging Face Hub client:
   ```bash
   pip install huggingface_hub
   ```
6. Log in to Hugging Face:
   ```bash
   python -c "from huggingface_hub import login; login()"
   ```
   This prompts you for a token. To obtain one:
   - Go to the [Hugging Face website](https://huggingface.co/), create an
     account, and verify your email.
   - Join the **OSU organization**.
   - Go to the **alphagenome-all-folds** model page and request access to the model.
   - In your profile, go to **Access Tokens** and create or view your
     AlphaGenome token.
   - Accept any terms and conditions you encounter — otherwise errors may occur.

   Paste the token when prompted (it will be invisible in the terminal). When
   asked to add the token as a git credential, type **`N`** — it is only needed
   this once.
7. Download the model weights:
   ```bash
   python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='google/alphagenome-all-folds', local_dir='alpha_weights')"
   ```
8. Download the hg38 reference genome:
   ```bash
   wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
   ```
9. Decompress it:
   ```bash
   gunzip hg38.fa.gz
   ```
10. Clone and install `alphagenome_research`:
    ```bash
    git clone https://github.com/google-deepmind/alphagenome_research.git
    cd alphagenome_research
    pip install -e .   # the trailing "." is required
    cd ..
    ```
11. Clone and install `alphagenome`:
    ```bash
    git clone https://github.com/google-deepmind/alphagenome.git
    cd alphagenome
    pip install -e .
    cd ..
    ```
12. Index the reference genome:
    ```bash
    samtools faidx hg38.fa
    ```

## 3. Verifying the Installation

Open a Python 3.11 notebook (click **+** → **Python 3.11 (Final)**) and run the
following snippets.

**(1) Initialize the model:**

```python
from alphagenome_research.model import dna_model

model = dna_model.create_from_huggingface(
    'all_folds',
    organism_settings={
        dna_model.Organism.HOMO_SAPIENS: dna_model.OrganismSettings(
            fasta_path='/home/jupyter/hg38.fa'
        ),
        # Mandatory dummy entry so the model knows how to load the weights
        dna_model.Organism.MUS_MUSCULUS: dna_model.OrganismSettings()
    }
)
print("AlphaGenome is initialized and ready for local inference!")
```

> Update `fasta_path` to point to wherever you saved and indexed `hg38.fa`.

## 4. Example: Variant Effect Prediction (BAG3)

**(2) Predict and visualize a variant's effect on RNA-seq:**

```python
from alphagenome import colab_utils
from alphagenome.data import gene_annotation
from alphagenome.data import genome
from alphagenome.data import transcript as transcript_utils
from alphagenome.interpretation import ism
from alphagenome.models import dna_client
from alphagenome.models import variant_scorers
from alphagenome.visualization import plot_components
import matplotlib.pyplot as plt
import pandas as pd

gtf = pd.read_feather(
    'https://storage.googleapis.com/alphagenome/reference/gencode/'
    'hg38/gencode.v46.annotation.gtf.gz.feather'
)
gtf_transcripts = gene_annotation.filter_protein_coding(gtf)
gtf_transcripts = gene_annotation.filter_to_mane_select_transcript(gtf_transcripts)
transcript_extractor = transcript_utils.TranscriptExtractor(gtf_transcripts)

# variant stuff
variant_to_test = "chr10:119150004:C>T"
bag3_variant_string = variant_to_test
bag3_variant = genome.Variant.from_str(bag3_variant_string)

bag3_interval = gene_annotation.get_gene_interval(gtf, gene_symbol='BAG3')
bag3_interval = bag3_interval.resize(dna_client.SEQUENCE_LENGTH_1MB)

tissues = [
    'UBERON:0001134'  # Uberon Ontology ID for skeletal muscle.
    # Can also do more than one tissue at once
]

output = model.predict_variant(
    interval=bag3_interval,
    variant=bag3_variant,
    requested_outputs=[dna_client.OutputType.RNA_SEQ],  # specifically look at BAG3 RNA
    ontology_terms=tissues
)

transcripts = transcript_extractor.extract(bag3_interval)

ref_color = {'REF': 'purple'}
alt_color = {'ALT': 'gold'}
plot_components.plot(
    components=[
        plot_components.TranscriptAnnotation(transcripts),
        plot_components.OverlaidTracks(
            tdata={
                'REF': output.reference.rna_seq,  # .filter_to_positive_strand(),
            }, colors=ref_color),
        plot_components.OverlaidTracks(
            tdata={
                'ALT': output.alternate.rna_seq,
            }, colors=alt_color)
    ],
    interval=bag3_interval,
)
plt.show()

plot_components.plot(
    components=[
        plot_components.TranscriptAnnotation(transcripts),
        plot_components.Tracks(tdata=output.alternate.rna_seq - output.reference.rna_seq)
    ],
    interval=bag3_interval,
)
plt.show()
```

## 5. Optional: Splice Junctions Modality

To use the Splice Junctions modality, extra reference files must be downloaded
and additional arguments must be passed to the model.

### 5.1 Download the necessary files

```python
import subprocess
import os

download_dir = '/home/jupyter/alphagenome_data'
os.makedirs(download_dir, exist_ok=True)

files = {
    'gtf': 'gs://alphagenome/reference/gencode/hg38/gencode.v46.annotation.gtf.gz.feather',
    'splice_starts': 'gs://alphagenome/reference/gencode/hg38/gencode.v46.splice_sites_starts.feather',
    'splice_ends': 'gs://alphagenome/reference/gencode/hg38/gencode.v46.splice_sites_ends.feather',
}

for name, gcs_url in files.items():
    filename = gcs_url.split('/')[-1]
    local_path = os.path.join(download_dir, filename)
    if os.path.exists(local_path):
        print(f"Already exists: {local_path}")
    else:
        print(f"Downloading {name}...")
        result = subprocess.run(
            ['gsutil', 'cp', gcs_url, local_path],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            print(f"Saved to: {local_path}")
        else:
            print(f"Error: {result.stderr}")

print("\nAll files ready:")
for f in os.listdir(download_dir):
    print(f"  {f}")
```

### 5.2 Initialize the model with splice-site arguments

```python
from alphagenome import colab_utils
from alphagenome.data import gene_annotation
from alphagenome.data import genome
from alphagenome.data import transcript as transcript_utils
from alphagenome.interpretation import ism
from alphagenome.models import dna_client
from alphagenome.models import variant_scorers
from alphagenome.visualization import plot_components
import matplotlib.pyplot as plt
import pandas as pd
from alphagenome_research.model import dna_model

model = dna_model.create_from_huggingface(
    'all_folds',
    organism_settings={
        dna_model.Organism.HOMO_SAPIENS: dna_model.OrganismSettings(
            fasta_path='/home/jupyter/hg38.fa',
            gtf_feather_path='/home/jupyter/alphagenome_data/gencode.v46.annotation.gtf.gz.feather',
            splice_site_starts_feather_path='/home/jupyter/alphagenome_data/gencode.v46.splice_sites_starts.feather',
            splice_site_ends_feather_path='/home/jupyter/alphagenome_data/gencode.v46.splice_sites_ends.feather',
        ),
        dna_model.Organism.MUS_MUSCULUS: dna_model.OrganismSettings()
    }
)
print("AlphaGenome is initialized and ready for local inference!")
```

### 5.3 Example ISM (in-silico mutagenesis) run

> **Warning:** This can take **4+ hours** to run. To reduce runtime, make
> `target_start` and `target_end` much closer together.

```python
# target_start = 119640000  # upstream 10kb before high-activity region start
# target_start = 119650800
target_start = 119661600
target_end = 119672500      # downstream 10kb after high-activity region end

# testing for two other positions
target_start = 119672656
target_end = 119672660

ism_interval = genome.Interval('chr10', target_start, target_end)
sequence_interval = ism_interval.resize(32768)
bag3_context = ism_interval.resize(dna_client.SEQUENCE_LENGTH_1MB)

sj_variant_scorer = variant_scorers.RECOMMENDED_VARIANT_SCORERS['SPLICE_JUNCTIONS']

variant_scores = model.score_ism_variants(
    interval=sequence_interval,
    ism_interval=ism_interval,
    variant_scorers=[sj_variant_scorer],
    organism=dna_client.Organism.HOMO_SAPIENS,
)


def extract_splice_scores_fixed(adata):
    var = adata.var
    mask = (var['ontology_curie'] == 'UBERON:0000948') & \
           (var['Assay title'] == 'total RNA-seq')
    if adata.X.shape[0] == 0:
        return float('nan')
    values = adata.X[0, mask]
    if values.size == 0:
        return float('nan')
    return float(values.max())


rows = []
for vs in variant_scores:
    variant = vs[0].uns['variant']
    score = extract_splice_scores_fixed(vs[0])
    rows.append({
        'position': variant.position,
        'ref': variant.reference_bases,
        'alt': variant.alternate_bases,
        'delta_score': score,
    })

ism_df = pd.DataFrame(rows)
ism_df.to_csv('bag3_ism_sj_heart_region3.csv', index=False)
print(f"Total rows: {len(ism_df)}")
print(f"Non-NaN: {ism_df['delta_score'].notna().sum()}")
print(f"NaN: {ism_df['delta_score'].isna().sum()}")
print("Done!")
```

## Notes & Troubleshooting

- **Activate the environment every session:** You generally need to run
  `conda activate py311` in the terminal each time you want to use AlphaGenome.
- **GPU not detected:** If `python -c "import jax; print(jax.devices())"` does
  not report a `CudaDevice`, re-check the JAX CUDA install (step 3 in
  [Installing AlphaGenome Locally](#2-installing-alphagenome-locally)) and the
  `conda install` CUDA components.
- **Kernel not appearing:** If **Python 3.11 (Final)** does not show up as a
  notebook option, re-run the `ipykernel install` command and re-run steps 4–6
  of the environment setup.
- **Paths:** The example code uses `/home/jupyter/...` paths. Adjust these to
  match where you downloaded `hg38.fa`, the model weights, and the reference
  feather files on your system.
- **REF/ALT track labels (corrected):** In the original source, the `'REF'`
  track was assigned `output.alternate.rna_seq` and the `'ALT'` track was
  assigned `output.reference.rna_seq`, which swaps the labels relative to the
  data. The example in
  [Variant Effect Prediction (BAG3)](#4-example-variant-effect-prediction-bag3)
  has been corrected so `'REF'` uses `output.reference.rna_seq` and `'ALT'` uses
  `output.alternate.rna_seq`.
