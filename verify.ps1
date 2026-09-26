# Post-install sanity checks for the local AI stack.
$ErrorActionPreference = 'Continue'
$ok = $true

Write-Host "== GPU =="
try { nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader }
catch { Write-Host "!! nvidia-smi missing — install NVIDIA driver first"; $ok = $false }

Write-Host "`n== ollama =="
try {
    $v = Invoke-RestMethod http://localhost:11434/api/version
    Write-Host "server up: $($v.version)"
} catch {
    Write-Host "!! server down — starting it hidden"
    Start-Process ollama -ArgumentList 'serve' -WindowStyle Hidden
    Start-Sleep 4
    try { $v = Invoke-RestMethod http://localhost:11434/api/version; Write-Host "server up: $($v.version)" }
    catch { Write-Host "!! still down — run 'ollama serve' manually"; $ok = $false }
}

Write-Host "`n== models =="
ollama ls

Write-Host "`n== tools =="
foreach ($t in 'aider','opencode','uv','python') {
    if (Get-Command $t -ErrorAction SilentlyContinue) { Write-Host "$t OK" }
    else { Write-Host "$t MISSING" }
}

Write-Host "`n== GPU offload check (needs a model pulled) =="
$models = (ollama ls | Select-String -Pattern '\S+:\S+' -AllMatches).Matches.Value
if ($models.Count -gt 0) {
    $body = @{ model = $models[0]; prompt = 'say ok'; stream = $false;
               options = @{ num_predict = 5 } } | ConvertTo-Json
    $r = Invoke-RestMethod -Method Post http://localhost:11434/api/generate -Body $body -ContentType 'application/json'
    $tps = [math]::Round($r.eval_count / ($r.eval_duration / 1e9), 1)
    Write-Host "generation works — ~$tps tok/s on $($models[0])"
    Write-Host "(watch 'ollama ps' GPU column or nvidia-smi while generating to confirm offload)"
}

if ($ok) { Write-Host "`nALL CHECKS PASSED" } else { Write-Host "`nFIX THE !! ITEMS ABOVE" }
