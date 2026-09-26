# Deconstruction system — sets up bioprocess-decision-runtime and launches
# the local evidence dashboard. Run once after install-windows.ps1.
#   .\deconstruct.ps1            # full setup + launch UI on port 8765
#   .\deconstruct.ps1 -SetupOnly # just env + deps, no UI
param([switch]$SetupOnly)
$ErrorActionPreference = 'Stop'

$repo = Join-Path (Split-Path $PSScriptRoot -Parent) 'bioprocess-decision-runtime'
if (-not (Test-Path $repo)) {
    Write-Host "== cloning bioprocess-decision-runtime =="
    git clone https://github.com/barlowa124/bioprocess-decision-runtime $repo
}
Push-Location $repo
git pull --ff-only 2>$null | Out-Null

if (-not (Test-Path .venv)) {
    Write-Host "== venv =="
    uv venv .venv --python 3.12
}
Write-Host "== pinned deps (torch 2.7.1+cu128, transformers 4.53.3) =="
uv pip install --python .venv\Scripts\python.exe `
    --index-url https://download.pytorch.org/whl/cu128 torch==2.7.1
uv pip install --python .venv\Scripts\python.exe transformers==4.53.3
uv pip install --python .venv\Scripts\python.exe -e .

Write-Host "== weights check =="
# The deconstructed checkpoint is Gemma 3 270M IT — gated on HF.
# Run 'hf auth login' (or set HF_TOKEN) first if weights are absent.
$hf = huggingface-cli whoami 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "!! not logged into HF — Gemma weights are license-gated."
    Write-Host "   run: uv tool install huggingface_hub ; hf auth login"
    Write-Host "   then re-run this script."
}
Pop-Location

if ($SetupOnly) { Write-Host "setup done"; exit 0 }
Write-Host "== dashboard =="
Write-Host "loopback-only evidence UI — Ctrl+C to stop"
& $repo\.venv\Scripts\python -m bioprocess_runtime.demo_ui --port 8765
