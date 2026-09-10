param(
[string]$Folder,
[string]$Mode = "normal"
)

Add-Type -AssemblyName System.Drawing

if (-not $Folder) {
Write-Host "ERROR: No frame folder supplied."
Read-Host "Press ENTER"
exit 1
}

if (-not (Test-Path -LiteralPath $Folder)) {
Write-Host "ERROR: Frame folder does not exist."
Read-Host "Press ENTER"
exit 1
}

$frames = @(Get-ChildItem -LiteralPath $Folder -Filter "frame_*.png" | Sort-Object Name)

if ($frames.Count -eq 0) {
Write-Host "ERROR: No frames found."
Read-Host "Press ENTER"
exit 1
}

if ($Mode -ne "half") {
$Mode = "normal"
}

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class VTMode {
[DllImport("kernel32.dll", SetLastError=true)]
public static extern IntPtr GetStdHandle(int nStdHandle);

[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool GetConsoleMode(
    IntPtr hConsoleHandle,
    out uint lpMode
);

[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool SetConsoleMode(
    IntPtr hConsoleHandle,
    uint dwMode
);

public const int STD_OUTPUT_HANDLE = -11;
public const uint ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;

}
"@

$handle = [VTMode]::GetStdHandle([VTMode]::STD_OUTPUT_HANDLE)

$consoleMode = 0

if ([VTMode]::GetConsoleMode($handle, [ref]$consoleMode)) {
[VTMode]::SetConsoleMode(
$handle,
$consoleMode -bor [VTMode]::ENABLE_VIRTUAL_TERMINAL_PROCESSING
)
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ESC = [char]27

function Get-ANSI256Color {
param(
[int]$R,
[int]$G,
[int]$B
)

$cubeValues = @(0, 95, 135, 175, 215, 255)

$rIndex = 0
$gIndex = 0
$bIndex = 0

$bestRDistance = [double]::MaxValue
$bestGDistance = [double]::MaxValue
$bestBDistance = [double]::MaxValue

for ($i = 0; $i -lt 6; $i++) {

    $rd = [Math]::Abs($R - $cubeValues[$i])
    $gd = [Math]::Abs($G - $cubeValues[$i])
    $bd = [Math]::Abs($B - $cubeValues[$i])

    if ($rd -lt $bestRDistance) {
        $bestRDistance = $rd
        $rIndex = $i
    }

    if ($gd -lt $bestGDistance) {
        $bestGDistance = $gd
        $gIndex = $i
    }

    if ($bd -lt $bestBDistance) {
        $bestBDistance = $bd
        $bIndex = $i
    }
}

$cubeR = $cubeValues[$rIndex]
$cubeG = $cubeValues[$gIndex]
$cubeB = $cubeValues[$bIndex]

$cubeDistance =
    (($R - $cubeR) * ($R - $cubeR)) +
    (($G - $cubeG) * ($G - $cubeG)) +
    (($B - $cubeB) * ($B - $cubeB))

$grayAverage = ($R + $G + $B) / 3.0

if ($grayAverage -le 8) {
    $grayCode = 232
    $grayValue = 8
}
elseif ($grayAverage -ge 238) {
    $grayCode = 255
    $grayValue = 238
}
else {
    $grayIndex = [int][Math]::Round(($grayAverage - 8) / 10)

    if ($grayIndex -lt 0) {
        $grayIndex = 0
    }

    if ($grayIndex -gt 23) {
        $grayIndex = 23
    }

    $grayCode = 232 + $grayIndex
    $grayValue = 8 + ($grayIndex * 10)
}

$grayDistance =
    (($R - $grayValue) * ($R - $grayValue)) +
    (($G - $grayValue) * ($G - $grayValue)) +
    (($B - $grayValue) * ($B - $grayValue))

if ($grayDistance -lt $cubeDistance) {
    return $grayCode
}

return 16 + (36 * $rIndex) + (6 * $gIndex) + $bIndex

}

function Get-BG {
param(
[int]$Code
)

return "$ESC[48;5;${Code}m"

}

function Get-FG {
param(
[int]$Code
)

return "$ESC[38;5;${Code}m"

}

try {

[Console]::CursorVisible = $false

[Console]::Write("$ESC[2J$ESC[H")

foreach ($file in $frames) {

    $bmp = [System.Drawing.Bitmap]::new($file.FullName)

    $output = New-Object System.Text.StringBuilder

    if ($Mode -eq "half") {

        for ($y = 0; $y -lt $bmp.Height; $y += 2) {

            $bottomY = [Math]::Min(
                $y + 1,
                $bmp.Height - 1
            )

            for ($x = 0; $x -lt $bmp.Width; $x++) {

                $top = $bmp.GetPixel($x, $y)
                $bottom = $bmp.GetPixel($x, $bottomY)

                $topCode = Get-ANSI256Color `
                    -R $top.R `
                    -G $top.G `
                    -B $top.B

                $bottomCode = Get-ANSI256Color `
                    -R $bottom.R `
                    -G $bottom.G `
                    -B $bottom.B

                [void]$output.Append(
                    (Get-FG $topCode)
                )

                [void]$output.Append(
                    (Get-BG $bottomCode)
                )

                [void]$output.Append("▀")
            }

            [void]$output.Append("$ESC[0m")
            [void]$output.Append("`r`n")
        }

    }
    else {

        for ($y = 0; $y -lt $bmp.Height; $y++) {

            for ($x = 0; $x -lt $bmp.Width; $x++) {

                $p = $bmp.GetPixel($x, $y)

                $code = Get-ANSI256Color `
                    -R $p.R `
                    -G $p.G `
                    -B $p.B

                [void]$output.Append(
                    (Get-BG $code)
                )

                [void]$output.Append("  ")
            }

            [void]$output.Append("$ESC[0m")
            [void]$output.Append("`r`n")
        }
    }

    [Console]::SetCursorPosition(0, 0)

    [Console]::Write(
        $output.ToString()
    )

    $bmp.Dispose()

    Start-Sleep -Milliseconds 100
}

[Console]::CursorVisible = $true

[Console]::Write("$ESC[0m")

Write-Host ""
Write-Host ""
Write-Host "VIDEO FINISHED!"
Write-Host ""

}
catch {

[Console]::CursorVisible = $true

[Console]::Write("$ESC[0m")

Write-Host ""
Write-Host "=========================================="
Write-Host "             PLAYER ERROR"
Write-Host "=========================================="
Write-Host ""
Write-Host $_.Exception.Message
Write-Host ""

Read-Host "Press ENTER"
exit 1

}

Read-Host "Press ENTER"