# AILM stack rebuild — restores the old D:\ailm assistant stack
# (text-generation-webui + SillyTavern + voices) using the orchestration
# scripts preserved at github.com/barlowa124/ailm-stack-scripts.
#
# Model/extension weights are NOT in that repo — OFFLINE_MODEL_MANIFEST.md
# there is the 180GB inventory of what the drive held. This script lays
# down the skeleton + scripts; pulling the heavy files is guided per part.
#   .\ailm-rebuild.ps1 -Root D:\ailm
param(
    [string]$Root = 'D:\ailm',
    # Point at an existing/old ailm tree (surviving drive, external copy,
    # old PC) to archive its persona/config data before or during rebuild.
    [string]$BackupFrom = '',
    # Consume a userdata-backup.zip produced by -BackupFrom to seed the new
    # tree with the original cards, personas, presets, and settings.
    [switch]$RestoreBackup
)
$ErrorActionPreference = 'Stop'

# The data that GitHub did NOT preserve is small: character/persona cards,
# presets, templates, chats, settings — KBs-MBs under a few known dirs.
# -BackupFrom archives them; -RestoreBackup puts them back. Run this first
# thing when the old drive is accessible — before any fresh install writes
# over those paths.
$DataDirs = @(
    'SillyTavern\data',
    'text-generation-webui\user_data\instruction-templates',
    'text-generation-webui\user_data\presets',
    'text-generation-webui\user_data\characters',
    'text-generation-webui\user_data\prompts',
    'text-generation-webui\user_data\history',
    'text-generation-webui\user_data\settings.yaml',
    'text-generation-webui\user_data\loras',
    'text-generation-webui\user_data\training'
)

if ($BackupFrom) {
    $zip = Join-Path $Root 'userdata-backup.zip'
    Write-Host "== archiving persona/config data from $BackupFrom =="
    $staging = Join-Path $env:TEMP 'ailm-userdata-backup'
    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
    foreach ($rel in $DataDirs) {
        $src = Join-Path $BackupFrom $rel
        if (Test-Path $src) {
            $dest = Join-Path $staging $rel
            New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
            Copy-Item $src $dest -Recurse -Force
            Write-Host "  captured $rel"
        } else {
            Write-Host "  missing  $rel"
        }
    }
    if (Test-Path "$staging\*") {
        Compress-Archive "$staging\*" $zip -Force
        Write-Host "== wrote $zip — this is the irreplaceable part =="
    } else {
        Write-Host "== nothing found under $BackupFrom — no archive written =="
    }
    Remove-Item $staging -Recurse -Force
    return
}

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

if ($RestoreBackup) {
    $zip = Join-Path $Root 'userdata-backup.zip'
    if (-not (Test-Path $zip)) { throw "no userdata-backup.zip at $Root — run -BackupFrom first" }
    Write-Host "`n== restoring persona/config data into $Root =="
    $staging = Join-Path $env:TEMP 'ailm-userdata-restore'
    Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive $zip $staging -Force
    foreach ($rel in $DataDirs) {
        $src = Join-Path $staging $rel
        if (Test-Path $src) {
            $dest = Join-Path $Root $rel
            # never clobber an already-populated target — merge only into a
            # fresh/default install
            if (Test-Path $dest) {
                Write-Host "  SKIP $rel (already exists — merge by hand if wanted)"
            } else {
                New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
                Copy-Item $src $dest -Recurse -Force
                Write-Host "  restored $rel"
            }
        }
    }
    Remove-Item $staging -Recurse -Force
}

Write-Host "`nNOT automated (by design): the ~140GB of weights/extensions."
Write-Host "Work the manifest top-down; the scripts repo has per-extension"
Write-Host "installers + compatibility report (EXTENSION_COMPATIBILITY_REPORT.md)."
Write-Host "The coding stack (Ollama/aider) is independent — this does not replace it."
Write-Host "`nPersona/card recovery: run -BackupFrom <old ailm root> the moment"
Write-Host "the old drive is reachable, then -RestoreBackup after components are cloned."
