# Renders the README images from the model.
#   -Target nod    (default) docs/banner.png: the word "Nod" plus the box lying on its front
#   -Target clawd  cad/clawd/clawd.png: the Clawd variant, upright
# Needs OpenSCAD, Python (pip install trimesh pillow), Microsoft Edge, and the Cascadia Code font.
#   1. export the model in colour groups
#   2. combine them into a coloured glTF (to_glb.py)
#   3. render it with three.js in headless Edge, light raking across the keys (render.html)
#   4. crop, and for Nod add the title (compose.py)
param([ValidateSet('nod', 'clawd')][string]$Target = 'nod')

$here = $PSScriptRoot
$repo = Resolve-Path "$here\..\.."
$openscad = 'C:\Program Files\OpenSCAD\openscad.exe'
$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$tmp = Join-Path $env:TEMP "nod_banner_$Target"
New-Item -ItemType Directory -Force $tmp | Out-Null

# colour groups: OpenSCAD file, -D setting, colour. Camera/sun directions are glTF axes (Y up).
if ($Target -eq 'nod') {
  $groups = @(@("$repo\cad\views.scad", 'view', 'banner_body', 'DA7756'),
              @("$repo\cad\views.scad", 'view', 'banner_accent', 'EEEEEE'))
  $query = 'cam=100,39,124&sun=-1,1.1,0.55'
  $out = "$repo\docs\banner.png"; $title = 'Nod'
} else {
  $groups = @(@("$repo\cad\clawd\clawd.scad", 'part', 'img_body', 'DA7756'),
              @("$repo\cad\clawd\clawd.scad", 'part', 'img_eyes', '111111'),
              @("$repo\cad\clawd\clawd.scad", 'part', 'img_accent', 'EEEEEE'))
  $query = 'cam=70,75,90&sun=-1,1.4,0.9'
  $out = "$repo\cad\clawd\clawd.png"; $title = ''
}

$parts = @()
foreach ($g in $groups) {
  $scad, $var, $val, $col = $g
  # Windows PowerShell strips bare quotes when calling native exes, hence the \" escapes
  & $openscad -o "$tmp\$val.stl" -D "$var=\`"$val\`"" $scad 2>&1 | Out-Null
  $parts += "$tmp\$val.stl=$col"
}
python -W ignore "$here\to_glb.py" "$tmp\model.glb" @parts
Copy-Item "$here\render.html" $tmp -Force

$server = Start-Process python -ArgumentList '-m', 'http.server', '8768', '--bind', '127.0.0.1' -WorkingDirectory $tmp -PassThru -WindowStyle Hidden
Start-Sleep 2
try {
  & $edge --headless=new --use-angle=swiftshader --window-size=1400,1100 --virtual-time-budget=20000 `
    --screenshot="$tmp\render.png" "http://127.0.0.1:8768/render.html?$query" 2>&1 | Out-Null
} finally { Stop-Process $server.Id }

if ($title) { python "$here\compose.py" "$tmp\render.png" $out $title }
else { python "$here\compose.py" "$tmp\render.png" $out }
