param(
    [Parameter(Mandatory = $true)][string]$MappingPath,
    [Parameter(Mandatory = $true)][string]$ProcessedRoot
)

Add-Type -AssemblyName System.Drawing
$mapping = Get-Content -Raw -LiteralPath $MappingPath | ConvertFrom-Json
foreach ($batch in $mapping.batches) {
    $sheetName = 'store_items_sheet_{0:d2}' -f [int]$batch.sheet
    $sheetDir = Join-Path $ProcessedRoot $sheetName
    $canvas = New-Object System.Drawing.Bitmap 1024, 1536
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.Clear([System.Drawing.Color]::FromArgb(245, 245, 245))
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    for ($index = 0; $index -lt $batch.items.Count; $index++) {
        $itemPath = Join-Path (Join-Path $sheetDir 'previews') ($batch.items[$index] + '.png')
        $source = [System.Drawing.Image]::FromFile($itemPath)
        $x = ($index % 2) * 512
        $y = [math]::Floor($index / 2) * 512
        $graphics.DrawImage($source, $x, $y, 512, 512)
        $source.Dispose()
    }
    $graphics.Dispose()
    $outputPath = Join-Path $sheetDir ($sheetName + '_processed_contact.png')
    $canvas.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Dispose()
    Write-Output $outputPath
}
