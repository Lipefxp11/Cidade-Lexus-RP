#!/usr/bin/env python3
"""CI guardrail: zip must remain buildable offline, Android touch landscape intact."""
from pathlib import Path
import struct
import re
root = Path(__file__).resolve().parents[1]
project=(root/'project.godot').read_text()
assert 'window/handheld/orientation=0' in project, 'orientation must be landscape'
assert 'pointing/emulate_mouse_from_touch=true' in project
model=root/'assets/models/character.glb'
assert model.is_file() and model.stat().st_size > 50_000
with model.open('rb') as f:
    header=f.read(12)
assert len(header)==12 and header[:4]==b'glTF' and struct.unpack_from('<I',header,8)[0]==model.stat().st_size
workflow=(root/'.github/workflows/android.yml').read_text()
assert 'Download real human 3D sample' not in workflow, 'Optional art must not break the build'
assert 'V21-Android-APK' in workflow
files=list((root/'scripts').glob('*.gd'))
assert len(files)>=10
for file in files:
    source=file.read_text()
    assert not re.search(r'(?m)^\s*const\s+\w+\s*:=',source), f'Bad GDScript constant {file}'
    assert 'res://cidade-lexus/' not in source, f'Nested project reference {file}'
assert not (root/'cidade-lexus/project.godot').exists(), 'nested project'
main=(root/'scripts/main.gd').read_text()
ui=(root/'scripts/lexus_ui.gd').read_text()
assert 'apply_appearance(current_outfit, skin_tone, hair_tone)' in main
assert 'func _on_gps_selected' in main
assert 'func _make_appearance' in ui and 'SubViewport' in ui
print('V20 STATIC OK: project landscape, GLB valid, character, GPS, workflow offline')
