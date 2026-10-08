# Lab 6 - สร้างตัวละคร 3D

**673380307-8 นายกีรติ ชาวงษ์ (CP-AI)**

ดูบนเว็บ: https://keerati-chawong.github.io/Game_dev_Solo_RPG/game6.html

ซีน Demo แสดงตัวละคร low-poly ที่สร้างใน Blender เล่น animation 120 ท่าจาก
[Godot4 Open Animation Libraries](https://github.com/catprisbrey/Godot4-OpenAnimationLibraries) (MeleeLib)

## ขั้นตอน

1. **Blender** - `blender_source/build_character.py` สร้างตัวละครท่า T-pose จากกล่อง low-poly ใช้ภาพใบหน้าเป็นหน้าตัวละคร
   ใส่ Armature 22 ท่อนโดยตั้งชื่อกระดูกแบบ Mixamo (`mixamorig:Hips` ...) แล้ว export เป็น `character/keerati_3d.glb`
   ไฟล์ Blender อยู่ที่ `blender_source/keerati_3d.blend`
2. **Mixamo** - `blender_source/keerati_3d_for_mixamo.fbx` คือ mesh สำหรับอัปโหลดเข้า mixamo.com
3. **Godot** - นำเข้า `keerati_3d.glb` โดยตั้ง Retarget > Bone Map เป็น `anim/Mixamo BoneMap.tres`
   แล้วเล่น animation จาก `anim/MeleeLib.res` ผ่าน AnimationPlayer ใน `demo.tscn`

## วิธีใช้

- เลือกท่าจากรายการด้านซ้าย หรือกดปุ่มลูกศรขึ้น/ลง
- คลิกขวาค้างแล้วลากเพื่อหมุนกล้อง, ล้อเมาส์ซูม

## เครดิต

- Godot4 Open Animation Libraries - catprisbrey (Mixamo BoneMap, MeleeLib)
