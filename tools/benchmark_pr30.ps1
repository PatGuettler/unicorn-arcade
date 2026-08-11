param(
    [ValidateSet('baseline', 'candidate')]
    [string]$Label = 'baseline',
    [int]$Runs = 3,
    [int]$Samples = 15,
    [int]$Warmups = 5,
    [int]$TimeoutSeconds = 180
)

$project = (Resolve-Path "$PSScriptRoot\..").Path
$resultsDir = Join-Path $project '.tools\perf-results'
$runDir = Join-Path $resultsDir ("pr30-{0}-{1}" -f $Label, (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
$runResults = @()
for ($index = 1; $index -le $Runs; $index++) {
    $outputPath = Join-Path $runDir ("run-{0}.json" -f $index)
    $stdoutPath = Join-Path $runDir ("run-{0}.stdout.log" -f $index)
    $stderrPath = Join-Path $runDir ("run-{0}.stderr.log" -f $index)
    $startedAt = Get-Date
    $projectGodot = Join-Path $project '.tools\godot-4.7.1'
    $preExisting = @(Get-Process -Name 'Godot*' -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$projectGodot\*" } | Select-Object -ExpandProperty Id)
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'cmd.exe'
    $psi.Arguments = '/d /s /c ""' + $PSScriptRoot + '\run_godot.cmd" --headless --path "' + $project + '\godot" res://tests/performance_probe_pr30.tscn -- --output="' + $outputPath + '" --samples=' + $Samples + ' --warmups=' + $Warmups + ' 1> "' + $stdoutPath + '" 2> "' + $stderrPath + '""'
    $psi.WorkingDirectory = $project
    $psi.UseShellExecute = $false
    $wrapper = [Diagnostics.Process]::Start($psi)
    $records = @{}
    $watch = [Diagnostics.Stopwatch]::StartNew()
    while (-not $wrapper.HasExited -and $watch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        Get-Process -Name 'Godot*' -ErrorAction SilentlyContinue | Where-Object {
            $_.Path -like "$projectGodot\*" -and $_.Id -notin $preExisting -and $_.StartTime -ge $startedAt
        } | ForEach-Object {
            if (-not $records.ContainsKey($_.Id)) {
                $records[$_.Id] = [ordered]@{ pid = $_.Id; name = $_.ProcessName; start_time = $_.StartTime.ToString('o') }
            }
        }
        Start-Sleep -Milliseconds 50
    }
	$timedOut = -not $wrapper.HasExited
	if ($timedOut) { Stop-Process -Id $wrapper.Id -Force -ErrorAction SilentlyContinue }
	if (-not $wrapper.HasExited) { $wrapper.WaitForExit(5000) | Out-Null }
	$grace = [Diagnostics.Stopwatch]::StartNew()
	$absentPolls = 0
	while ($grace.Elapsed.TotalSeconds -lt 10 -and $absentPolls -lt 10) {
		$live = @($records.Keys | Where-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue })
		if ($live.Count -eq 0) { $absentPolls++ } else { $absentPolls = 0 }
		Start-Sleep -Milliseconds 100
	}
	$survivorsBeforeCleanup = @($records.Keys | Where-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue })
	$modalWindows = @()
	foreach ($processId in $records.Keys) {
		$process = Get-Process -Id $processId -ErrorAction SilentlyContinue
		if ($process -and -not [string]::IsNullOrWhiteSpace($process.MainWindowTitle)) {
			$modalWindows += [ordered]@{ pid = $process.Id; title = $process.MainWindowTitle }
			$process.CloseMainWindow() | Out-Null
		}
	}
	Start-Sleep -Milliseconds 250
	$cleanupPids = @()
	foreach ($processId in $survivorsBeforeCleanup) {
		if (Get-Process -Id $processId -ErrorAction SilentlyContinue) {
			Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
			$cleanupPids += $processId
		}
	}
	$cleanupWait = [Diagnostics.Stopwatch]::StartNew()
	$absentPolls = 0
	while ($cleanupWait.Elapsed.TotalSeconds -lt 5 -and $absentPolls -lt 10) {
		$live = @($records.Keys | Where-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue })
		if ($live.Count -eq 0) { $absentPolls++ } else { $absentPolls = 0 }
		Start-Sleep -Milliseconds 100
	}
	$survivorsAfterCleanup = @($records.Keys | Where-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue })
	$exitCode = if ($timedOut) { -1 } else { $wrapper.ExitCode }
	if ($timedOut -or $exitCode -ne 0 -or -not (Test-Path -LiteralPath $outputPath) -or $survivorsAfterCleanup.Count -gt 0) {
        Get-Content -LiteralPath $stdoutPath -ErrorAction SilentlyContinue
        Get-Content -LiteralPath $stderrPath -ErrorAction SilentlyContinue
		throw "PR30 benchmark run $index failed (exit=$exitCode timeout=$timedOut survivors=$($survivorsAfterCleanup -join ','))."
    }
    $payload = Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
    $runResults += [ordered]@{
        run = $index
        wrapper_pid = $wrapper.Id
        godot_processes = @($records.Values)
		modal_windows = $modalWindows
		timed_out = $timedOut
		survivors_before_cleanup = $survivorsBeforeCleanup
		cleanup_pids = $cleanupPids
		survivors_after_cleanup = $survivorsAfterCleanup
        result_path = $outputPath
        scenarios = $payload.scenarios
        repeated_navigation_memory = $payload.repeated_navigation_memory
        machine = $payload.machine
    }
}

$scenarioNames = @($runResults[0].scenarios.PSObject.Properties.Name)
$aggregateScenarios = [ordered]@{}
foreach ($scenario in $scenarioNames) {
    $combinedSamples = @()
    foreach ($run in $runResults) { $combinedSamples += @($run.scenarios.$scenario.samples_us | ForEach-Object { [double]$_ }) }
    $ordered = @($combinedSamples | Sort-Object)
    $median = $ordered[[int][Math]::Floor($ordered.Count / 2)]
    $p95Index = [Math]::Min($ordered.Count - 1, [Math]::Ceiling($ordered.Count * 0.95) - 1)
    $aggregateScenarios[$scenario] = [ordered]@{
        samples_us = $combinedSamples
        median_us = [Math]::Round($median, 4)
        p95_us = [Math]::Round($ordered[$p95Index], 4)
    }
}
$aggregate = [ordered]@{
    schema = 1
    label = $Label
    timestamp_utc = [DateTime]::UtcNow.ToString('o')
    runs = $runResults
    machine = $runResults[0].machine
    scenarios = $aggregateScenarios
    memory_deltas_bytes = @($runResults | ForEach-Object { [long]$_.repeated_navigation_memory.static_delta_bytes })
}
$aggregatePath = Join-Path $resultsDir ("pr30-{0}-aggregate-{1}.json" -f $Label, (Get-Date -Format 'yyyyMMdd-HHmmss'))
$aggregate | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $aggregatePath -Encoding utf8
Write-Output "PR30_PERF_RESULT=$aggregatePath"
foreach ($run in $runResults) {
    $pairs = @($run.godot_processes | ForEach-Object { "$($_.name):$($_.pid)" }) -join ','
    Write-Output "PR30_PERF_PIDS run=$($run.run) $pairs"
}
foreach ($scenario in $aggregateScenarios.Keys) {
    Write-Output ("PR30_PERF_METRIC {0} median_us={1} p95_us={2}" -f $scenario, $aggregateScenarios[$scenario].median_us, $aggregateScenarios[$scenario].p95_us)
}
