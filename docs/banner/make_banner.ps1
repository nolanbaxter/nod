# Rebuilds docs/banner.png from the model.
# Needs OpenSCAD, Python (pip install trimesh pillow), Microsoft Edge, and the Cascadia Code font.
#   1. export the case in two colour groups (views.scad: banner_body / banner_accent)
#   2. combine them into a coloured glTF (to_glb.py)
#   3. render it with three.js in headless Edge, light raking across the keys (render.html)
#   4. place the render next to the word "Nod" (compose.py)
$here = $PSScriptRoot
$repo = Resolve-Path "$here\..\.."
$openscad = 'C:\Program Files\OpenSCAD\openscad.exe'
$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$tmp = Join-Path $env:TEMP 'nod_banner'
New-Item -ItemType Directory -Force $tmp | Out-Null

foreach ($g in 'banner_body', 'banner_accent') {
  # Windows PowerShell strips bare quotes when calling native exes, hence the \" escapes
  & $openscad -o "$tmp\$g.stl" -D "view=\`"$g\`"" "$repo\cad\views.scad" 2>&1 | Out-Null
}
python -W ignore "$here\to_glb.py" "$tmp\banner_body.stl" "$tmp\banner_accent.stl" "$tmp\banner.glb"
Copy-Item "$here\render.html" $tmp -Force

$server = Start-Process python -ArgumentList '-m', 'http.server', '8768', '--bind', '127.0.0.1' -WorkingDirectory $tmp -PassThru -WindowStyle Hidden
Start-Sleep 2
try {
  & $edge --headless=new --use-angle=swiftshader --window-size=1400,1100 --virtual-time-budget=20000 `
    --screenshot="$tmp\box.png" http://127.0.0.1:8768/render.html 2>&1 | Out-Null
} finally { Stop-Process $server.Id }

python "$here\compose.py" "$tmp\box.png" "$repo\docs\banner.png"
