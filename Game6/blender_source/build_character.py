"""Builds the Lab 6 low-poly character in Blender.

Run from the command line:
    blender --background --python build_character.py

It creates a blocky T-pose character with the student's face on the head,
an armature that uses Mixamo bone names, and exports:
    keerati_3d.blend              - the Blender file
    ../character/keerati_3d.glb   - rigged model for Godot
    keerati_3d_for_mixamo.fbx     - mesh only, to upload to mixamo.com
"""
import os
import bpy
import bmesh
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
P = "mixamorig:"

bpy.ops.wm.read_factory_settings(use_empty=True)


# --- materials ---------------------------------------------------------------
def flat_material(name, rgb):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.85
    return mat


SKIN = (0.36, 0.24, 0.19)
materials = [
    flat_material("Skin", SKIN),                 # 0
    flat_material("Shirt", (0.10, 0.28, 0.62)),  # 1
    flat_material("Pants", (0.13, 0.13, 0.17)),  # 2
    flat_material("Shoes", (0.82, 0.82, 0.86)),  # 3
    flat_material("Hair", (0.03, 0.03, 0.04)),   # 4
]
face_mat = bpy.data.materials.new("Face")        # 5
face_mat.use_nodes = True
tex = face_mat.node_tree.nodes.new("ShaderNodeTexImage")
tex.image = bpy.data.images.load(os.path.join(HERE, "face.png"))
bsdf = face_mat.node_tree.nodes["Principled BSDF"]
bsdf.inputs["Roughness"].default_value = 0.85
face_mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
materials.append(face_mat)
SKIN_M, SHIRT, PANTS, SHOES, HAIR, FACE = range(6)

# --- body parts: (bone, centre, size, material) ---------------------------------
parts = [
    ("Hips", (0, 0, 0.98), (0.34, 0.20, 0.20), PANTS),
    ("Spine", (0, 0, 1.14), (0.34, 0.20, 0.17), SHIRT),
    ("Spine1", (0, 0, 1.29), (0.38, 0.22, 0.17), SHIRT),
    ("Spine2", (0, 0, 1.43), (0.42, 0.24, 0.17), SHIRT),
    ("Neck", (0, 0, 1.545), (0.11, 0.11, 0.09), SKIN_M),
    ("Head", (0, 0, 1.74), (0.30, 0.30, 0.32), SKIN_M),
    ("Head", (0, 0.02, 1.915), (0.32, 0.30, 0.07), HAIR),
    ("Head", (0, 0.145, 1.76), (0.32, 0.05, 0.30), HAIR),
]
for side, sx in (("Left", 1.0), ("Right", -1.0)):
    parts += [
        (side + "Shoulder", (sx * 0.15, 0, 1.46), (0.10, 0.15, 0.13), SHIRT),
        (side + "Arm", (sx * 0.315, 0, 1.45), (0.27, 0.12, 0.12), SHIRT),
        (side + "ForeArm", (sx * 0.585, 0, 1.45), (0.27, 0.10, 0.10), SKIN_M),
        (side + "Hand", (sx * 0.785, 0, 1.45), (0.13, 0.11, 0.05), SKIN_M),
        (side + "UpLeg", (sx * 0.10, 0, 0.725), (0.16, 0.17, 0.45), PANTS),
        (side + "Leg", (sx * 0.10, 0, 0.29), (0.14, 0.15, 0.42), PANTS),
        (side + "Foot", (sx * 0.10, -0.05, 0.04), (0.14, 0.24, 0.08), SHOES),
        (side + "ToeBase", (sx * 0.10, -0.205, 0.035), (0.14, 0.07, 0.07), SHOES),
    ]

mesh = bpy.data.meshes.new("KeeratiMesh")
bm = bmesh.new()
uv_layer = bm.loops.layers.uv.new("UVMap")
vert_bone = {}  # vertex index -> bone name
for bone, centre, size, mat_index in parts:
    made = bmesh.ops.create_cube(bm, size=1.0)
    verts = made["verts"]
    for v in verts:
        v.co = Vector((v.co.x * size[0] + centre[0], v.co.y * size[1] + centre[1], v.co.z * size[2] + centre[2]))
    faces = {f for v in verts for f in v.link_faces}
    is_head = bone == "Head" and mat_index == SKIN_M
    for f in faces:
        f.material_index = mat_index
        # The front of the head (-Y) carries the face photo.
        if is_head and f.normal.y < -0.9:
            f.material_index = FACE
            for loop in f.loops:
                u = (loop.vert.co.x - (centre[0] - size[0] / 2)) / size[0]
                v = (loop.vert.co.z - (centre[2] - size[2] / 2)) / size[2]
                loop[uv_layer].uv = (u, v)
    bm.verts.index_update()
    for v in verts:
        vert_bone[v] = bone

bm.verts.ensure_lookup_table()
bone_of_index = {v.index: b for v, b in vert_bone.items()}
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(mesh)
bm.free()
for mat in materials:
    mesh.materials.append(mat)

body = bpy.data.objects.new("Keerati", mesh)
bpy.context.scene.collection.objects.link(body)

for index, bone in bone_of_index.items():
    group = body.vertex_groups.get(P + bone) or body.vertex_groups.new(name=P + bone)
    group.add([index], 1.0, "REPLACE")

# --- armature with Mixamo bone names ---------------------------------------------
arm_data = bpy.data.armatures.new("Armature")
rig = bpy.data.objects.new("Armature", arm_data)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")


def bone(name, head, tail, parent=None, connect=False):
    b = arm_data.edit_bones.new(P + name)
    b.head = head
    b.tail = tail
    if parent:
        b.parent = arm_data.edit_bones[P + parent]
        b.use_connect = connect
    return b


bone("Hips", (0, 0, 0.95), (0, 0, 1.05))
bone("Spine", (0, 0, 1.05), (0, 0, 1.20), "Hips", True)
bone("Spine1", (0, 0, 1.20), (0, 0, 1.35), "Spine", True)
bone("Spine2", (0, 0, 1.35), (0, 0, 1.50), "Spine1", True)
bone("Neck", (0, 0, 1.50), (0, 0, 1.58), "Spine2", True)
bone("Head", (0, 0, 1.58), (0, 0, 1.90), "Neck", True)
for side, sx in (("Left", 1.0), ("Right", -1.0)):
    bone(side + "Shoulder", (sx * 0.04, 0, 1.45), (sx * 0.18, 0, 1.45), "Spine2")
    bone(side + "Arm", (sx * 0.18, 0, 1.45), (sx * 0.45, 0, 1.45), side + "Shoulder", True)
    bone(side + "ForeArm", (sx * 0.45, 0, 1.45), (sx * 0.72, 0, 1.45), side + "Arm", True)
    bone(side + "Hand", (sx * 0.72, 0, 1.45), (sx * 0.85, 0, 1.45), side + "ForeArm", True)
    bone(side + "UpLeg", (sx * 0.10, 0, 0.95), (sx * 0.10, 0, 0.50), "Hips")
    bone(side + "Leg", (sx * 0.10, 0, 0.50), (sx * 0.10, 0, 0.08), side + "UpLeg", True)
    bone(side + "Foot", (sx * 0.10, 0, 0.08), (sx * 0.10, -0.16, 0.02), side + "Leg", True)
    bone(side + "ToeBase", (sx * 0.10, -0.16, 0.02), (sx * 0.10, -0.24, 0.02), side + "Foot", True)
bpy.ops.object.mode_set(mode="OBJECT")

body.parent = rig
modifier = body.modifiers.new("Armature", "ARMATURE")
modifier.object = rig

# --- a camera and light so the .blend opens ready for a screenshot -----------------
cam_data = bpy.data.cameras.new("Camera")
cam = bpy.data.objects.new("Camera", cam_data)
cam.location = (2.6, -3.6, 1.6)
cam.rotation_euler = (1.36, 0, 0.62)
bpy.context.scene.collection.objects.link(cam)
bpy.context.scene.camera = cam
sun = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", "SUN"))
sun.rotation_euler = (0.9, 0.2, 0.6)
bpy.context.scene.collection.objects.link(sun)

bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "keerati_3d.blend"))

# --- exports ---------------------------------------------------------------------
for obj in bpy.context.scene.objects:
    obj.select_set(obj in (body, rig))
bpy.context.view_layer.objects.active = rig
bpy.ops.export_scene.gltf(
    filepath=os.path.join(HERE, "..", "character", "keerati_3d.glb"),
    export_format="GLB",
    use_selection=True,
    export_animations=False,
    export_yup=True,
)

# Mesh only (no armature) for Mixamo's auto-rigger.
rig.select_set(False)
body.select_set(True)
bpy.context.view_layer.objects.active = body
modifier.show_viewport = False
bpy.ops.export_scene.fbx(
    filepath=os.path.join(HERE, "keerati_3d_for_mixamo.fbx"),
    use_selection=True,
    object_types={"MESH"},
    use_mesh_modifiers=False,
    path_mode="COPY",
    embed_textures=True,
)
print("BUILT verts=%d faces=%d bones=%d" % (len(mesh.vertices), len(mesh.polygons), len(arm_data.bones)))
