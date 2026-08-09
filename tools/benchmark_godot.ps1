param(
    [int]$Runs = 5,
    [string]$Scenario = "headless-import",
    [int]$TimeoutSeconds = 120
)

# Lightweight, repeatable baseline harness. Results deliberately stay in the
# ignored .tools tree so measurements never pollute source control. Device
# captures (adb meminfo/gfxinfo) can be appended to the same JSON document.
$project = (Resolve-Path "$PSScriptRoot\..").Path
$resultsDir = Join-Path $project ".tools\perf-results"
$benchLogDir = Join-Path $project ".tools\godot-logs\benchmark"
New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null
New-Item -ItemType Directory -Force -Path $benchLogDir | Out-Null
$samples = @()
for ($index = 1; $index -le $Runs; $index++) {
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $startedAt = Get-Date
    $preExisting = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like 'Godot*' } | Select-Object -ExpandProperty Id)
    $runDir = Join-Path $benchLogDir ("run-{0}-{1}" -f $index,(Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Force -Path $runDir | Out-Null
    $stdoutPath = Join-Path $runDir 'stdout.log'
    $stderrPath = Join-Path $runDir 'stderr.log'
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = "cmd.exe"
    $psi.Arguments = '/d /s /c ""' + $PSScriptRoot + '\run_godot.cmd" --headless --path "' + $project + '\godot" --editor --quit 1> "' + $stdoutPath + '" 2> "' + $stderrPath + '""'
    $psi.WorkingDirectory = $project
    $psi.UseShellExecute = $false
    $wrapper = [Diagnostics.Process]::Start($psi)
    $godotPids = @()
    $godotRecords = @{}
    while (-not $wrapper.HasExited -and $watch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        $children = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like 'Godot*' -and $_.Id -notin $preExisting -and $_.StartTime -ge $startedAt }
        $godotPids += @($children | Select-Object -ExpandProperty Id)
        foreach($child in $children){ if(-not $godotRecords.ContainsKey($child.Id)){ $godotRecords[$child.Id]=[ordered]@{pid=$child.Id;name=$child.ProcessName;start_time=$child.StartTime.ToString('o')} } }
        Start-Sleep -Milliseconds 100
    }
    $timedOut = -not $wrapper.HasExited
    if ($timedOut) { Stop-Process -Id $wrapper.Id -Force }
    $exitCode = $wrapper.ExitCode
    $grace = [Diagnostics.Stopwatch]::StartNew(); $absent = 0
    while($grace.Elapsed.TotalSeconds -lt 10 -and $absent -lt 10){ $live=@($godotRecords.Keys | Where-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue }); if($live.Count -eq 0){$absent++}else{$absent=0}; Start-Sleep -Milliseconds 100 }
    $survivorsBefore = @($godotRecords.Keys | Where-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue })
    $cleanupPids = @()
    foreach($pid in $survivorsBefore){ Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue; $cleanupPids += $pid }
    $cleanupWait=[Diagnostics.Stopwatch]::StartNew(); $absent=0
    while($cleanupWait.Elapsed.TotalSeconds -lt 5 -and $absent -lt 10){ $live=@($godotRecords.Keys | Where-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue }); if($live.Count -eq 0){$absent++}else{$absent=0}; Start-Sleep -Milliseconds 100 }
    $survivorsAfter = @($godotRecords.Keys | Where-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue })
    $watch.Stop()
    $samples += [ordered]@{
        run = $index
        wall_ms = [Math]::Round($watch.Elapsed.TotalMilliseconds, 2)
        exit_code = $exitCode
        wrapper_pid = $wrapper.Id
        godot_processes = @($godotRecords.Values)
        timed_out = $timedOut
        survivors_before_cleanup = $survivorsBefore
        cleanup_pids = $cleanupPids
        survivors_after_cleanup = $survivorsAfter
        modal_dialogs = @($godotPids | Select-Object -Unique | ForEach-Object { $p=Get-Process -Id $_ -ErrorAction SilentlyContinue; if($p -and $p.MainWindowTitle){[ordered]@{pid=$p.Id;title=$p.MainWindowTitle}} })
        stdout_log = $stdoutPath
        stderr_log = $stderrPath
    }
    if ($godotPids.Count -eq 0) { $exitCode = 1; $samples[-1].exit_code = 1 }
    if ($survivorsAfter.Count -gt 0) { $exitCode = 1; $samples[-1].exit_code = 1 }
    if ($exitCode -ne 0) { break }
}
$ordered = @($samples | ForEach-Object { $_.wall_ms } | Sort-Object)
$median = if ($ordered.Count -gt 0) { $ordered[[int][Math]::Floor(($ordered.Count - 1) / 2)] } else { $null }
$result = [ordered]@{
    timestamp_utc = [DateTime]::UtcNow.ToString("o")
    scenario = $Scenario
    runs = $samples
    median_wall_ms = $median
    notes = "Append device adb meminfo/gfxinfo and frame-time captures for physical performance gates."
}
$path = Join-Path $resultsDir ("{0}-{1}.json" -f $Scenario, (Get-Date -Format "yyyyMMdd-HHmmss"))
$result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $path -Encoding utf8
Write-Output "PERF_RESULT=$path"
if ($samples | Where-Object { $_.exit_code -ne 0 }) { exit 1 }
