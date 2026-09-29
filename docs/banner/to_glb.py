"""Combine STL colour groups into one glTF: to_glb.py out.glb part.stl=RRGGBB [part.stl=RRGGBB ...]"""
import sys, numpy as np, trimesh
from trimesh.visual.material import PBRMaterial
from trimesh.visual import TextureVisuals

def lin(h):  # glTF base colours are linear, not sRGB
    c = np.array([int(h[i:i+2], 16) / 255 for i in (0, 2, 4)])
    return list(np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)) + [1.0]

T = trimesh.transformations.rotation_matrix(-np.pi / 2, [1, 0, 0])  # OpenSCAD Z-up -> glTF Y-up
T[:3, :3] *= 0.001                                                   # mm -> m
scene = trimesh.Scene()
for i, arg in enumerate(sys.argv[2:]):
    path, col = arg.rsplit("=", 1)
    m = trimesh.load(path)
    m.apply_transform(T)
    m.visual = TextureVisuals(material=PBRMaterial(name=f"g{i}", baseColorFactor=lin(col), metallicFactor=0.0, roughnessFactor=0.75))
    scene.add_geometry(m, node_name=f"g{i}", geom_name=f"g{i}")
scene.export(sys.argv[1])
print(sys.argv[1])
