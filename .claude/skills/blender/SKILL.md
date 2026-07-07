---
name: blender
description: >
  Blender (.blend) ファイルの操作 — プレビュー抽出、ヘッドレスレンダリング、シーン情報の確認、
  glTF/FBX エクスポート、bpy スクリプト実行。Use when the user says "blendファイルをプレビュー",
  "レンダリングして", "シーンの中身を見せて", "glTFに変換", "export to FBX", or mentions
  working with .blend files. リアルタイム編集（オブジェクト追加・マテリアル変更）は
  blender-mcp (mcp__blender__*) を優先する。
---

# Blender Skill

## Blender バイナリの解決

```bash
BLENDER=$(command -v blender || echo "/Applications/Blender.app/Contents/MacOS/Blender")
```

存在しなければ `brew install --cask blender` を提案する。

## 1. クイックプレビュー（Blender 不要・最速）

.blend に埋め込まれた保存時サムネイルを抽出する。GUI もレンダリングも不要：

```bash
python3 ~/.claude/skills/blender/scripts/extract_thumb.py <file.blend> <out.png>
```

- 抽出した PNG は Read で内容確認し、SendUserFile (display: render) でユーザーに送る
- 出力先は scratchpad ディレクトリを使う
- サムネイルは 128x128 程度。高解像度が必要なら次のレンダリングを使う
- 「no thumbnail saved」の場合はプレビュー保存なしで書き出されたファイル → レンダリングにフォールバック

## 2. ヘッドレスレンダリング（高解像度プレビュー）

```bash
"$BLENDER" -b <file.blend> -o /path/to/out_ -F PNG -f 1
```

- `-f 1` はフレーム1をレンダリング。出力は `out_0001.png` のようにフレーム番号が付く
- カメラ未設定エラーの場合は bpy でカメラを自動追加してからレンダリング（下記テンプレート参照）
- 解像度変更: `--python-expr 'import bpy; bpy.context.scene.render.resolution_x=1920; bpy.context.scene.render.resolution_y=1080'` を `-f` より**前**に置く（引数は順番に評価される）

## 3. シーン情報の確認

```bash
"$BLENDER" -b <file.blend> --python-expr '
import bpy
for o in bpy.data.objects:
    print(f"{o.type:10s} {o.name:30s} verts={len(o.data.vertices) if o.type==\"MESH\" else \"-\"}")
print("materials:", [m.name for m in bpy.data.materials])
print("scene:", bpy.context.scene.name, "frames:", bpy.context.scene.frame_start, "-", bpy.context.scene.frame_end)
'
```

出力には Blender の起動ログが混ざるので、必要な行だけ抜き出してユーザーに見せる。

## 4. エクスポート

```bash
# glTF (推奨: Web/共有用)
"$BLENDER" -b <file.blend> --python-expr 'import bpy; bpy.ops.export_scene.gltf(filepath="/path/out.glb")'

# FBX
"$BLENDER" -b <file.blend> --python-expr 'import bpy; bpy.ops.export_scene.fbx(filepath="/path/out.fbx")'

# OBJ (Blender 3.x+)
"$BLENDER" -b <file.blend> --python-expr 'import bpy; bpy.ops.wm.obj_export(filepath="/path/out.obj")'
```

## 5. 任意の bpy スクリプト実行

複雑な処理はスクリプトファイルに書いて実行する：

```bash
"$BLENDER" -b <file.blend> --python /path/to/script.py
```

カメラ・ライト自動追加テンプレート（カメラなしファイルのレンダリング用）:

```python
import bpy, math
scene = bpy.context.scene
if not scene.camera:
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    # 全オブジェクトが収まる位置に配置
    bpy.ops.object.select_all(action="SELECT")
    cam.location = (7, -7, 5)
    cam.rotation_euler = (math.radians(63), 0, math.radians(45))
if not any(o.type == "LIGHT" for o in bpy.data.objects):
    light = bpy.data.objects.new("Sun", bpy.data.lights.new("Sun", type="SUN"))
    scene.collection.objects.link(light)
    light.rotation_euler = (math.radians(45), 0, math.radians(30))
bpy.ops.render.render(write_still=True)
```

## 注意事項

- 古い .blend（2.7x 以前）を最新 Blender で開くと表示が変わることがある（マテリアルは Cycles/EEVEE に自動変換される）
- `-b` (background) を必ず付ける。付け忘れると GUI が起動してセッションがブロックする
- 大きな .blend は Google Drive ストリーミング上にある場合、初回読み込みに時間がかかる
- ライブ編集・対話的モデリングの依頼は blender-mcp（GUI の Blender + addon 接続が必要）を案内する
