# Lab 5 - First 3D Game: Coin Quest 3D

**673380307-8 นายกีรติ ชาวงษ์ (CP-AI)**

เล่นบนเว็บ: https://keerati-chawong.github.io/Game_dev_Solo_RPG/game5.html

เกม 3D platformer ที่ต่อยอดจาก [3D Platformer Starter Kit](https://store.godotengine.org/asset/the-silver-demons/platformer-3d-starter-kit/)
ของ Silver Demon Studios (CC0)

## วิธีเล่น

หลบกับดักและสิ่งกีดขวาง เก็บเหรียญในด่านให้ครบ ประตูจะเปิด แล้วเข้าประตูเพื่อไปด่านต่อไป

- `W A S D` เดิน, `Space` กระโดด (กดซ้ำตอนกำลังเคลื่อนที่เพื่อตีลังกากลางอากาศ)
- เมาส์หมุนกล้อง, `Esc` ปล่อยเมาส์
- โดนกับดักหรือตกจากเกาะจะกลับไปเกิดที่ธงจุดเซฟล่าสุด

## สิ่งที่แก้จาก Starter Kit

- **ตัวละคร Player**: เปลี่ยนจาก Gobot เป็น **Adventurer** จาก Poly Pizza และจับคู่ animation ให้ตรงกับชื่อเดิมของ kit
  (`Idle`, `Run`, `Jump`, `Flip` และเพิ่ม `Hurt`) ใน `Scripts/player.gd`
- **ด่าน 2 ฉาก**: `Scenes/Levels/level_1.tscn` (Sky Garden) และ `level_2.tscn` (Lava Forge)
- **กับดัก** ใน `Scenes/Traps/`: หนาม, คานหมุน, ใบเลื่อย, ทะเลลาวา
- **วัตถุประกอบด่าน**: แท่นเลื่อน/ลิฟต์, ธงจุดเซฟ, ประตูที่ล็อกจนกว่าจะเก็บเหรียญครบ
- **ระบบเกม**: นับเหรียญต่อด่าน, นับจำนวนครั้งที่พลาด, หน้าจบเกม
- ของตกแต่งทั้งหมดเป็นโมเดล low-poly ที่ประกอบจากรูปทรงพื้นฐานใน Godot

## เครดิต

- 3D Platformer Starter Kit - Silver Demon Studios (CC0): ตัวควบคุมผู้เล่น กล้อง เหรียญ แพลตฟอร์ม เสียง
- Adventurer - Quaternius ผ่าน [Poly Pizza](https://poly.pizza/m/5EGWBMpuXq) (CC0)
