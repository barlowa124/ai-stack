# AILM stack rebuild — restores the old D:\ailm assistant stack
# (text-generation-webui + SillyTavern + voices) using the orchestration
# scripts preserved at github.com/barlowa124/ailm-stack-scripts.
#
# Model/extension weights are NOT in that repo — OFFLINE_MODEL_MANIFEST.md
# there is the 180GB inventory of what the drive held. This script lays
# down the skeleton + scripts; pulling the heavy files is guided per part.
#   .\ailm-rebuild.ps1 -Root D:\ailm
param([string]$Root = 'D:\ailm')
$ErrorActionPreference = 'Stop'

Write-Host "== ailm skeleton at $Root =="
New-Item -ItemType Directory -Force -Path $Root | Out-Null

Write-Host "== orchestration scripts (surviving half of the old stack) =="
if (-not (Test-Path "$Root\scripts")) {
    git clone https://github.com/barlowa124/ailm-stack-scripts "$Root\scripts"
}
Get-Content "$Root\scripts\OFFLINE_MODEL_MANIFEST.md" -TotalCount 40

Write-Host "`n== components — pick what to rebuild =="
$plan = @(
    @{ name='text-generation-webui'; why='ooba core — the kira assistant runtime';
       action='git clone https://github.com/oobabooga/text-generation-webui; run its start script once to create installer_files env' },
    @{ name='SillyTavern';          why='chat frontend (scripts configure it)';
       action='git clone https://github.com/SillyTavern/SillyTavern; then scripts\CONFIGURE_SILLYTAVERN.ps1' },
    @{ name='models';               why='Llama-3.1-70B Q4_K_M (~40GB) + Mistral-Nemo Q6 (~9.4GB) per manifest';
       action='place GGUFs in text-generation-webui\user_data\models — grab from your HF cache or re-download' },
    @{ name='voice stack';          why='GPT-SoVITS + alltalk_tts + trained kira voice (was ~40GB)';
       action='scripts\install_gpt_sovits.ps1 — voice models need re-training or re-download' },
    @{ name='stable-diffusion-webui'; why='image side (9.4GB)';
       action='git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui' }
)
$plan | ForEach-Object { Write-Host ("  {0,-26} {1}" -f $_.name, $_.why) }

Write-Host "`nNOT automated (by design): the ~140GB of weights/extensions."
Write-Host "Work the manifest top-down; the scripts repo has per-extension"
Write-Host "installers + compatibility report (EXTENSION_COMPATIBILITY_REPORT.md)."
Write-Host "The coding stack (Ollama/aider) is independent — this does not replace it."
