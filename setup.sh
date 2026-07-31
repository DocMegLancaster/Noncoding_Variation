#!/usr/bin/env bash
#
# setup.sh — one-shot AlphaGenome local-inference environment setup.
# Automates README sections 1–2 (Python 3.11 env + AlphaGenome + CUDA JAX +
# weights + hg38 reference).
#
# Usage:
#   bash setup.sh
#
# One manual step remains (HuggingFace token) — the script pauses and tells you
# exactly what to do.

set -euo pipefail

# --------------------------------------------------------------------------- #
# Config — override by exporting before running, e.g. WORK_DIR=/home/jupyter
# --------------------------------------------------------------------------- #
ENV_NAME="${ENV_NAME:-py311}"
WORK_DIR="${WORK_DIR:-/home/jupyter}"          # where hg38.fa + weights live
DATA_DIR="${DATA_DIR:-${WORK_DIR}/alphagenome_data}"  # GTF + splice-site feathers
HG38_URL="https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz"
JAX_RELEASES="https://storage.googleapis.com/jax-releases/jax_cuda_releases.html"
HF_REPO="google/alphagenome-all-folds"
GENCODE_GCS="gs://alphagenome/reference/gencode/hg38"  # GTF + splice feathers live here

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\n\033[1;33m!!\033[0m  %s\n' "$*"; }
die()  { printf '\n\033[1;31mXX\033[0m  %s\n' "$*" >&2; exit 1; }

command -v conda >/dev/null || die "conda not found. Open a terminal in the app and retry."
mkdir -p "$WORK_DIR"

# --------------------------------------------------------------------------- #
# 1. Conda environment (README §1)
# --------------------------------------------------------------------------- #
# Prefer environment.yml if present (env + CUDA toolchain in one shot).
if conda env list | grep -qE "^\s*${ENV_NAME}\s"; then
    log "Conda env '${ENV_NAME}' already exists — skipping create."
else
    if [[ -f environment.yml ]]; then
        log "Creating env '${ENV_NAME}' from environment.yml"
        conda env create -f environment.yml
    else
        log "Creating env '${ENV_NAME}' (python=3.11 + ipykernel)"
        conda create -n "${ENV_NAME}" python=3.11 ipykernel -y
    fi
fi

# Activate for the rest of the script.
# The cuda-nvcc activation hook reads $NVCC_PREPEND_FLAGS assuming it's already
# set; under `set -u` that unbound read aborts the script. 
# -u just around activation, then restore.
export NVCC_PREPEND_FLAGS="${NVCC_PREPEND_FLAGS:-}"
# shellcheck disable=SC1091
source "$(conda info --base)/etc/profile.d/conda.sh"
set +u
conda activate "${ENV_NAME}"
set -u
log "Active env: $(python -c 'import sys; print(sys.version.split()[0])') @ ${CONDA_PREFIX}"

# --------------------------------------------------------------------------- #
# 2. Jupyter kernel registration (README §1 step 7)
# --------------------------------------------------------------------------- #
log "Registering Jupyter kernel 'Python 3.11 (Final)'"
python -m ipykernel install --user --name "${ENV_NAME}" --display-name "Python 3.11 (Final)"

# --------------------------------------------------------------------------- #
# 3. CUDA toolchain (skipped if environment.yml already installed it) (§2.2)
# --------------------------------------------------------------------------- #
#if python -c "import importlib.util,sys; sys.exit(0 if importlib.util.find_spec('nvidia') else 1)" 2>/dev/null; then
#    log "CUDA toolchain appears present — skipping conda install."
#else
#    log "Installing CUDA toolchain components (cuda-nvcc, cuda-runtime, cudnn)"
#    conda install -c nvidia cuda-nvcc cuda-runtime cudnn -y
#fi

# --------------------------------------------------------------------------- #
# 4. JAX with CUDA 12 (README §2.1, §2.3) — pip, with the find-links URL.
#    Kept as pip (NOT conda) on purpose: the CUDA wheels come from JAX_RELEASES.
# --------------------------------------------------------------------------- #
log "Installing JAX (CUDA 12 build)"
pip uninstall jax jaxlib -y >/dev/null 2>&1 || true
pip install -U "jax[cuda12]" -f "${JAX_RELEASES}"

# --------------------------------------------------------------------------- #
# 5. HuggingFace client + login (README §2.5–2.6)
# --------------------------------------------------------------------------- #
log "Installing huggingface_hub"
pip install -q huggingface_hub

if python -c "from huggingface_hub import HfApi; HfApi().whoami()" >/dev/null 2>&1; then
    log "Already logged in to HuggingFace — skipping login."
else
    warn "HuggingFace login required (one-time). A token prompt will appear next."
    echo   "  To get a token: huggingface.co -> join the OSU org -> request access to"
    echo   "  '${HF_REPO}' -> Access Tokens -> create/copy. Accept all model terms."
    echo   "  Paste the token (invisible). When asked to add as a git credential, type N."
    python -c "from huggingface_hub import login; login()"
fi

# --------------------------------------------------------------------------- #
# 6. Download model weights (README §2.7)
# --------------------------------------------------------------------------- #
WEIGHTS_DIR="${WORK_DIR}/alpha_weights"
if [[ -d "${WEIGHTS_DIR}" ]] && [[ -n "$(ls -A "${WEIGHTS_DIR}" 2>/dev/null)" ]]; then
    log "Weights already present at ${WEIGHTS_DIR} — skipping download."
else
    log "Downloading model weights -> ${WEIGHTS_DIR}"
    python - "$HF_REPO" "$WEIGHTS_DIR" <<'PY'
import sys
from huggingface_hub import snapshot_download
snapshot_download(repo_id=sys.argv[1], local_dir=sys.argv[2])
PY
fi

# --------------------------------------------------------------------------- #
# 7. hg38 reference genome + index (README §2.8–2.9, §2.12)
# --------------------------------------------------------------------------- #
FASTA="${WORK_DIR}/hg38.fa"
if [[ -f "${FASTA}" ]]; then
    log "hg38.fa already present — skipping download."
else
    log "Downloading + decompressing hg38 reference -> ${FASTA}"
    wget -O "${FASTA}.gz" "${HG38_URL}"
    gunzip "${FASTA}.gz"
fi

command -v samtools >/dev/null || die "samtools not found (needed to index hg38). Install it, then re-run."
if [[ -f "${FASTA}.fai" ]]; then
    log "hg38.fa.fai index already present — skipping faidx."
else
    log "Indexing hg38.fa"
    samtools faidx "${FASTA}"
fi

# --------------------------------------------------------------------------- #
# 8. GENCODE GTF + splice-site feathers (README §5.1)
#    Needed by BOTH the model init (splice modality) AND gene-coordinate lookup
#    (gene_annotation.get_gene_interval reads the GTF feather). Not optional for
#    our notebooks even though the README frames splice as "optional".
# --------------------------------------------------------------------------- #
command -v gsutil >/dev/null || die "gsutil not found (needed for GENCODE feathers). It ships with the gcloud SDK."
mkdir -p "$DATA_DIR"
for f in gencode.v46.annotation.gtf.gz.feather \
         gencode.v46.splice_sites_starts.feather \
         gencode.v46.splice_sites_ends.feather; do
    if [[ -f "${DATA_DIR}/${f}" ]]; then
        log "${f} already present — skipping."
    else
        log "Downloading ${f} -> ${DATA_DIR}"
        gsutil cp "${GENCODE_GCS}/${f}" "${DATA_DIR}/${f}"
    fi
done

# --------------------------------------------------------------------------- #
# 9. Install AlphaGenome packages (README §2.10–2.11)
# --------------------------------------------------------------------------- #
for repo in alphagenome_research alphagenome; do
    if python -c "import ${repo}" >/dev/null 2>&1; then
        log "${repo} already importable — skipping."
        continue
    fi
    if [[ ! -d "${WORK_DIR}/${repo}" ]]; then
        log "Cloning ${repo}"
        git clone "https://github.com/google-deepmind/${repo}.git" "${WORK_DIR}/${repo}"
    fi
    log "Installing ${repo} (editable)"
    pip install -e "${WORK_DIR}/${repo}"
done

# --------------------------------------------------------------------------- #
# 10. Verify GPU is actually visible to JAX (README §2.4) — HARD gate.
# --------------------------------------------------------------------------- #
log "Verifying JAX sees the GPU"
python - <<'PY'
import sys, jax
devs = jax.devices()
print("jax.devices() ->", devs)
if not any(d.platform == "gpu" for d in devs):
    sys.exit("FAIL: no GPU visible to JAX. Later steps would run on CPU. "
             "Re-check the CUDA toolchain + jax[cuda12] install.")
print("OK: GPU visible.")
PY

log "Setup complete."
echo   "Next: open a notebook, select kernel 'Python 3.11 (Final)', and run the"
echo   "smoke-test cell in aim1_batch_score.ipynb before the full scoring run."
echo   "(Model fasta_path should point to ${FASTA}.)"
