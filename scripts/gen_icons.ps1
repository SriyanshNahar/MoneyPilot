Add-Type -AssemblyName System.Drawing

function Remove-NearWhiteBackground {
    param([System.Drawing.Bitmap]$src, [int]$whiteThreshold = 232, [int]$feather = 28)
    $w = $src.Width; $h = $src.Height
    $out = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            $p = $src.GetPixel($x, $y)
            $r = $p.R; $g = $p.G; $b = $p.B
            $maxc = [Math]::Max($r, [Math]::Max($g, $b))
            $minc = [Math]::Min($r, [Math]::Min($g, $b))
            $sat = $maxc - $minc
            # Near-white/paper background: high brightness AND low saturation.
            $brightness = ($r + $g + $b) / 3.0
            if ($brightness -ge ($whiteThreshold + $feather)) {
                $alpha = 0
            } elseif ($brightness -le $whiteThreshold) {
                $alpha = $p.A
            } else {
                # feather zone: linearly ramp alpha out as brightness approaches white,
                # but only if desaturated (true white/paper), never for pale-green highlights.
                if ($sat -le 18) {
                    $t = ($brightness - $whiteThreshold) / [double]$feather
                    $alpha = [int]([Math]::Max(0, (1.0 - $t) * $p.A))
                } else {
                    $alpha = $p.A
                }
            }
            if ($sat -le 10 -and $brightness -ge $whiteThreshold) { $alpha = 0 }
            $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($alpha, $r, $g, $b))
        }
    }
    return $out
}

function New-PaddedCanvas {
    param([System.Drawing.Bitmap]$src, [int]$canvas, [int]$contentSize)
    $out = New-Object System.Drawing.Bitmap $canvas, $canvas, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $offset = [int](($canvas - $contentSize) / 2)
    $g.DrawImage($src, $offset, $offset, $contentSize, $contentSize)
    $g.Dispose()
    return $out
}

function ConvertTo-Monochrome {
    param([System.Drawing.Bitmap]$src)
    $w = $src.Width; $h = $src.Height
    $out = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $h; $y++) {
        for ($x = 0; $x -lt $w; $x++) {
            $p = $src.GetPixel($x, $y)
            $out.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($p.A, 255, 255, 255))
        }
    }
    return $out
}

function New-FlatOnWhite {
    param([System.Drawing.Bitmap]$src, [int]$canvas, [int]$contentSize, [System.Drawing.Color]$bg)
    $out = New-Object System.Drawing.Bitmap $canvas, $canvas, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.Clear($bg)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $offset = [int](($canvas - $contentSize) / 2)
    $g.DrawImage($src, $offset, $offset, $contentSize, $contentSize)
    $g.Dispose()
    return $out
}

$root = "E:\moneypilot\MoneyPilot (Flutter)"
$srcPath = Join-Path $root "assets\icons\app_icon.png"
$src = [System.Drawing.Bitmap]::FromFile($srcPath)

Write-Output "Removing paper background..."
$transparent = Remove-NearWhiteBackground -src $src -whiteThreshold 226 -feather 24
$transparent.Save((Join-Path $root "assets\icons\logo_transparent_512.png"), [System.Drawing.Imaging.ImageFormat]::Png)

Write-Output "Building adaptive foreground (1024, safe-zone ~66%)..."
$fg = New-PaddedCanvas -src $transparent -canvas 1024 -contentSize 672
$fg.Save((Join-Path $root "assets\icons\app_icon_foreground.png"), [System.Drawing.Imaging.ImageFormat]::Png)

Write-Output "Building monochrome (Android 13+ themed icon)..."
$monoSmall = ConvertTo-Monochrome -src $transparent
$mono = New-PaddedCanvas -src $monoSmall -canvas 1024 -contentSize 672
$mono.Save((Join-Path $root "assets\icons\app_icon_monochrome.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$monoSmall.Dispose()

Write-Output "Building flat iOS/legacy icon (full bleed on white, 1024)..."
$white = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
$flat = New-FlatOnWhite -src $transparent -canvas 1024 -contentSize 940 -bg $white
$flat.Save((Join-Path $root "assets\icons\app_icon_ios.png"), [System.Drawing.Imaging.ImageFormat]::Png)

$src.Dispose(); $transparent.Dispose(); $fg.Dispose(); $mono.Dispose(); $flat.Dispose()
Write-Output "Done."
