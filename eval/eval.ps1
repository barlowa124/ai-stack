# Eval battery — same 4 tasks used on the Mac (qwen2.5-coder:14b).
# Runs aider headless per task, verifies by executing code, feeds failures
# back for up to -MaxRounds. Reports first-pass vs final.
#   .\eval.ps1                      # default model: qwen2.5-coder:32b
#   .\eval.ps1 -Model ollama/gpt-oss:120b -MaxRounds 3
param(
    [string]$Model = "ollama/qwen2.5-coder:32b",
    [int]$MaxRounds = 3
)
$ErrorActionPreference = 'Continue'
$root = $PSScriptRoot
$work = Join-Path $env:TEMP 'ai_eval'
if (Test-Path $work) { Remove-Item $work -Recurse -Force }

$tasks = @(
    @{ id='t1'; name='utils funcs + tests' },
    @{ id='t2'; name='fix buggy LRU' },
    @{ id='t3'; name='expression parser' },
    @{ id='t4'; name='multi-file discount' },
    @{ id='t5'; name='impossible spec: abstain instead of fabricating' }
)

function Invoke-Verify($dir, $id) {
    Push-Location $dir
    $out = ''
    if (Get-ChildItem . -Filter 'test_*.py' -ErrorAction SilentlyContinue) {
        $out += (uv run --with pytest python -m pytest -x -q 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { Pop-Location; return $out }
    }
    $out += (uv run python "verify_$id.py" 2>&1 | Out-String)
    $code = $LASTEXITCODE
    Pop-Location
    if ($code -eq 0) { return $null }
    return $out
}

$results = @()
foreach ($t in $tasks) {
    $src = Join-Path $root "tasks\$($t.id)"
    $dir = Join-Path $work $t.id
    New-Item -ItemType Directory -Force $dir | Out-Null
    Copy-Item "$src\*" $dir -Recurse -Force
    $prompt = Get-Content (Join-Path $src 'prompt.txt') -Raw

    $passAt = 0; $rounds = 0; $lastErr = ''
    for ($r = 1; $r -le $MaxRounds; $r++) {
        $rounds = $r
        $msg = if ($r -eq 1) { $prompt }
               else { "The code still fails verification. Error output:`n$lastErr`nFix it." }
        Push-Location $dir
        $files = @(Get-ChildItem . -Filter '*.py' | Where-Object { $_.Name -notlike 'verify_*' } |
                   ForEach-Object { $_.Name })
        $aiderOut = aider --yes --no-git --model $Model -m $msg @files 2>&1 | Out-String
        Pop-Location
        $verdict = Invoke-Verify $dir $t.id
        if ($null -eq $verdict) { $passAt = $r; break }
        $lastErr = ($verdict -split "`n" | Select-Object -Last 15) -join "`n"
    }
    $results += [pscustomobject]@{
        Task   = "$($t.id): $($t.name)"
        Result = if ($passAt) { "PASS (round $passAt/$MaxRounds)" } else { "FAIL after $MaxRounds" }
    }
    Write-Host "$($t.id): $($t.name) -> $($results[-1].Result)"
}

Write-Host "`n===== SCORECARD ($Model) ====="
$results | Format-Table -AutoSize
