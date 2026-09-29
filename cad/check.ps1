# Collision check: every stand-in part vs every printed part, for Nod and the Clawd variant.
# Rerun after changing any measurement.
# Needs OpenSCAD and Python with trimesh (pip install trimesh).
# "touching only" = faces meet (intended, e.g. battery resting on the lid). Only CLASH is a problem.
$o = 'C:\Program Files\OpenSCAD\openscad.exe'
$tmp = Join-Path $env:TEMP 'nod_clash.stl'
$pairs = 'body lid', 'slide lid', 'slide body', 'slide xiao', 'slide battery', 'slide switches',
         'plate body', 'plate switches', 'plate lid', 'switches xiao', 'keycaps plate',
         'xiao body', 'xiao lid', 'battery body', 'battery lid', 'antenna body', 'antenna lid',
         'magnets body', 'magnets lid', 'switches body', 'switches lid', 'keycaps body', 'keycaps switches',
         'battery xiao', 'antenna xiao', 'switches battery'
$bad = 0
foreach ($scad in (Join-Path $PSScriptRoot 'case.scad'), (Join-Path $PSScriptRoot 'clawd\clawd.scad')) {
  '== ' + (Split-Path $scad -Leaf)
  foreach ($pr in $pairs) {
    $a, $b = $pr.Split(' ')
    # Windows PowerShell strips bare quotes when calling native exes, hence the \" escapes
    $out = & $o -o $tmp -D 'part=\"clash\"' -D "a=\`"$a\`"" -D "b=\`"$b\`"" $scad 2>&1 | Out-String
    if ($out -cmatch 'ERROR:|unknown variable') { "$pr  CHECK FAILED:`n$out"; exit 2 }
    if ($out -match 'empty|No top level') { $v = 'clear' }
    else {
      $v = python -W ignore -c "import trimesh,sys; m=trimesh.load(sys.argv[1]); v=abs(m.volume); print('touching only' if v<1e-3 else 'CLASH vol=%.2f mm3 at %s'%(v,m.bounds.round(2).tolist()))" $tmp
      if ($v -like 'CLASH*') { $bad++ }
    }
    '{0,-18} {1}' -f $pr, $v
  }
}
if ($bad) { "$bad clash(es)"; exit 1 } else { 'all clear' }
