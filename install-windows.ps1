# Local AI coding stack — Windows (RTX 4090 / 96GB RAM)
# Run in PowerShell:  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#                   .\install-windows.ps1
$ErrorActionPreference = 'Stop'

Write-Host "== winget packages =="
winget install -e --id Ollama.Ollama --accept-source-agreements --accept-package-agreements
winget install -e --id astral-sh.uv  --accept-source-agreements --accept-package-agreements
winget install -e --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements

# refresh PATH for this session
$env:PATH = [System.Environment]::GetEnvironmentVariable('PATH','Machine') + ';' +
            [System.Environment]::GetEnvironmentVariable('PATH','User')

Write-Host "== aider + opencode =="
uv python install 3.12
uv tool install --force --python python3.12 aider-chat@latest
# opencode: npm global (official), choco as fallback
if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm install -g opencode-ai
} elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    choco install opencode -y
} else {
    Write-Host "!! opencode not installed — no npm/choco. Get it later: https://opencode.ai"
}

Write-Host "== ollama env (GPU-first, big ctx, keep resident) =="
[Environment]::SetEnvironmentVariable('OLLAMA_CONTEXT_LENGTH','32768','User')
[Environment]::SetEnvironmentVariable('OLLAMA_NUM_PARALLEL','1','User')
[Environment]::SetEnvironmentVariable('OLLAMA_MAX_LOADED_MODELS','1','User')
[Environment]::SetEnvironmentVariable('OLLAMA_KEEP_ALIVE','30m','User')
$env:OLLAMA_CONTEXT_LENGTH='32768'

Write-Host "== start server =="
Start-Process ollama -ArgumentList 'serve' -WindowStyle Hidden
Start-Sleep 4

Write-Host "== models =="
ollama pull qwen2.5-coder:32b          # workhorse — ~20GB, fits 4090 fully
ollama pull qwen2.5-coder:7b           # fast trivial edits
Write-Host "optional heavyweight (65GB download):"
Write-Host "  ollama pull gpt-oss:120b       # partial GPU+RAM offload, ~10-15 t/s"

Write-Host "== configs =="
New-Item -ItemType Directory -Force -Path $HOME\.config\opencode | Out-Null
Copy-Item $PSScriptRoot\.aider.conf.yml $HOME\.aider.conf.yml
Copy-Item $PSScriptRoot\opencode.json  $HOME\.config\opencode\opencode.json -Force

Write-Host "Done. Verify with:  .\verify.ps1   then run the eval:  .\eval\eval.ps1"
