param(
    [string]$Folder
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

# Enable ANSI / VT processing
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

$mode = 0

if ([VTMode]::GetConsoleMode($handle, [ref]$mode)) {
    [VTMode]::SetConsoleMode(
        $handle,
        $mode -bor [VTMode]::ENABLE_VIRTUAL_TERMINAL_PROCESSING
    )
}

$ESC = [char]27

# 16 CMD colors.
# Each entry is:
# R, G, B, ANSI background code

$palette = @(
    @(0,   0,   0,   40),
    @(128, 0,   0,   41),
    @(0,   128, 0,   42),
    @(128, 128, 0,   43),
    @(0,   0,   128,   44),
    @(128, 0,   128,   45),
    @(0,   128, 128,   46),
    @(192, 192, 192, 47),

    @(128, 128, 128, 100),
    @(255, 0,   0,   101),
    @(0,   255, 0,   102),
    @(255, 255, 0,   103),
    @(0,   0,   255,   104),
    @(255, 0,   255, 105),
    @(0,   255, 255,   106),
    @(255, 255, 255, 107)
)

function Get-ColorCode {
    param(
        [int]$R,
        [int]$G,
        [int]$B
    )

    $bestDistance = [double]::MaxValue
    $bestCode = 40

    foreach ($c in $palette) {

        $dr = $R - $c[0]
        $dg = $G - $c[1]
        $db = $B - $c[2]

        $distance =
            ($dr * $dr) +
            ($dg * $dg) +
            ($db * $db)

        if ($distance -lt $bestDistance) {
            $bestDistance = $distance
            $bestCode = $c[3]
        }
    }

    return $bestCode
}

try {

    [Console]::CursorVisible = $false

    foreach ($file in $frames) {

        $bmp = [System.Drawing.Bitmap]::new($file.FullName)

        $output = New-Object System.Text.StringBuilder

        for ($y = 0; $y -lt $bmp.Height; $y++) {

            for ($x = 0; $x -lt $bmp.Width; $x++) {

                $p = $bmp.GetPixel($x, $y)

                $code = Get-ColorCode `
                    -R $p.R `
                    -G $p.G `
                    -B $p.B

                # ANSI background color + TWO ASCII spaces.
                # No Unicode characters = no â-^ garbage.
                [void]$output.Append(
                    $ESC + "[" + $code + "m  "
                )
            }

            [void]$output.Append($ESC + "[0m")
            [void]$output.Append("`r`n")
        }

        [Console]::SetCursorPosition(0, 0)

        [Console]::Write(
            $output.ToString()
        )

        $bmp.Dispose()

        Start-Sleep -Milliseconds 125
    }

    [Console]::CursorVisible = $true

    [Console]::Write(
        $ESC + "[0m"
    )

    Write-Host ""
    Write-Host ""
    Write-Host "VIDEO FINISHED!"
    Write-Host ""

}
catch {

    [Console]::CursorVisible = $true

    [Console]::Write(
        $ESC + "[0m"
    )

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