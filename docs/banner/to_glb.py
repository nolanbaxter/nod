import sys, numpy as np, trimesh
from trimesh.visual.material import PBRMaterial
from trimesh.visual import TextureVisuals

body_stl, accent_stl, out = sys.argv[1:4]

def lin(h):
    c = np.array([int(h[i:i+2], 16) / 255 for i in (0, 2, 4)])
    return list(np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)) + [1.0]

T = trimesh.transformations.rotation_matrix(-np.pi / 2, [1, 0, 0])  # OpenSCAD Z-up -> glTF Y-up
T[:3, :3] *= 0.001
scene = trimesh.Scene()
for name, path, col in [("body", body_stl, "DA7756"), ("accent", accent_stl, "EEEEEE")]:
    m = trimesh.load(path)
    m.apply_transform(T)
    m.visual = TextureVisuals(material=PBRMaterial(name=name, baseColorFactor=lin(col), metallicFactor=0.0, roughnessFactor=0.75))
    scene.add_geometry(m, node_name=name, geom_name=name)
scene.export(out)
print(out)
