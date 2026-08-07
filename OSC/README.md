# Running AlphaGenome on OSC

**See [general_osc_resources](general_osc_resources.md) for info on working in OSC**

Adapted from Spencer's instructions (thank you!!)

## Table of contents

1. [Table of contents](#table-of-contents)
2. [Directory / file outline](#directory--file-outline)
3. [Set up environment for AG on OSC](#set-up-environment-for-ag-on-osc)
4. [Install AG on OSC](#install-ag-on-osc)
5. [Run AG as batch job](#run-ag-as-batch-job)

## Directory / file outline

```text
OSC/
├── README.md                 # These setup and batch-job instructions
├── OSC_AG_env_extensive.yml  # Full conda env export (referenced in setup)
├── OSC_AG_env_sparse.yml     # Sparse/manual conda env export (referenced in setup)
├── AG_OSC_template.ipynb     # Jupyter template for running AlphaGenome on OSC
└── ag_batch.sh               # Example Slurm batch script (modules, env, GPU checks)
```



## Set up environment for AG on OSC

1. [https://ondemand.osc.edu/pun/sys/dashboard](https://ondemand.osc.edu/pun/sys/dashboard)
2. Interactive Apps -> Jupyter


| Property        | Value                                                                                                               |
| --------------- | ------------------------------------------------------------------------------------------------------------------- |
| Cluster         | Ascend                                                                                                              |
| Mode            | Jupyter Lab                                                                                                         |
| Root directory  | defaults to your user home dir but you can change it if needed                                                      |
| Number of hours | however long you need                                                                                               |
| Node type       | Any gpu                                                                                                             |
| Gpus            | 1 (can request more, you will just sit in the queue for a long time probably)                                       |
| CUDA Version    | Load from custom kernel                                                                                             |
| Number of cores | 5 (I was running out of memory with 1-2 cores when trying to load the model so request at least 5 cores to be safe) |
| Jupyter version | 4.1.5 (There was only one option for me)                                                                            |


1. Start session
2. Open a terminal
3. Load modules

```bash
ml miniconda3/24.1.2-py310 cuda/12.9.1
```

1. Create conda environment

Either

```bash
conda create -n py311 python=3.11 ipykernel -y
python -m ipykernel install --user --name py311 --display-name "Python 3.11"
conda init bash
source ~/.bashrc
conda activate py311
python -m ipykernel install --user --name py311 --display-name "Python 3.11 (Final)"
```

OR

```bash
conda env create -f OSC_AG_env_< VERSION >.yml
python -m ipykernel install --user --name py311 --display-name "Python 3.11"
conda init bash
source ~/.bashrc
conda activate py311
python -m ipykernel install --user --name py311 --display-name "Python 3.11 (Final)"
```

- `OSC_AG_env_extensive.yml` is a complete export of the working environment (conda and pip packages, includes sub-dependencies and system specific builds- in theory this should work on to create the env on OSC because the environment was created on OSC, but sometimes it can get finnicky
- `OSC_AG_env_sparse.yml` is a more sparse export of the working environment with only packages that I manually called to install- less system specific but more transferable



## Install AG on OSC

1. Open py311 environment in terminal. Every time you log into a new OSC Jupyter instance, you will probably need to load the miniconda and cuda modules in BEFORE activating the environment or trying to run AG

```bash
ml miniconda3/24.1.2-py310 cuda/12.9.1
conda activate py311
```

1. Install cuda packages and check that GPU is detected

```bash
pip uninstall jax jaxlib -y
conda install -c nvidia cuda-nvcc cuda-runtime cudnn -y
pip install -U "jax[cuda12]" -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html
pip install --upgrade "jax[cuda12_pip]" -f https://googleapis.com
python -c "import jax; print(jax.devices())"
```

1. Install AG model folds

```bash
pip install huggingface_hub
python -c "from huggingface_hub import login; login()"
```

This step will ask you for a token. You need to go to the Hugging Face website, create an account, verify your email, join the OSU organization. Then go to the alphagenome-all-folds page, get access to the model. Then go to your profile, access tokens, and create or view your alpha genome token. Anywhere you see terms and conditions, accept them, as otherwise errors may occur. After you enter your token into the terminal (it will be invisible), it will ask you to add the token as a git credential. Type “N”, as this is the only time we will need it.

```bash
python -c "from huggingface_hub import snapshot_download; snapshot_download(repo_id='google/alphagenome-all-folds', local_dir='alpha_weights')"
```

1. Install alphagenome and alphagenome_research

```bash
git clone https://github.com/google-deepmind/alphagenome_research.git
pip install -e ./alphagenome_research


git clone https://github.com/google-deepmind/alphagenome.git
pip install -e ./alphagenome

```

1. Load hg38 genome and generate fasta index

```bash
conda install bioconda::samtools

wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
gunzip hg38.fa.gz
samtools faidx hg38.fa
```

1. Download hg38 gene annotation and splice site location files

```bash
mkdir alphagenome_data
cd alphagenome_data
wget https://storage.googleapis.com/alphagenome/reference/gencode/hg38/gencode.v46.annotation.gtf.gz.feather
wget https://storage.googleapis.com/alphagenome/reference/gencode/hg38/gencode.v46.splice_sites_starts.feather
wget https://storage.googleapis.com/alphagenome/reference/gencode/hg38/gencode.v46.splice_sites_ends.feather
```



## Run AG as batch job

1. Set up conda env following directions in [[alphagenome_on_OSC#Install AG on OSC]]
2. Every batch job that uses AlphaGenome will need the following header

```bash
#!/bin/bash
#SBATCH --account=account####
#SBATCH --job-name=jobname
#SBATCH --mail-type=END,FAIL
#SBATCH --output=R-%x.%j.out
#SBATCH --error=R-%x.%j.err
#SBATCH --partition=nextgen
#SBATCH --mem=64gb
#SBATCH --time=40:00:00
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1

ml cuda/12.9.1 miniconda3/24.1.2-py310 
source activate py311
```

- You need to define `--gpus-per-node` in order to be allocated a gpu and need to load in the cuda and miniconda modules before activating your AG conda env to be able to actually access the gpu and run AG
- [ascend cluster partition and job submission info](https://www.osc.edu/resources/technical_support/supercomputers/ascend/batch_limit_rules)

