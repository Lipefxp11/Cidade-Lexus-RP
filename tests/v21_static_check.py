#!/usr/bin/env python3
"""V21: geographic layout, assets, official controls and GitHub export validation."""
from pathlib import Path
import re
import yaml

root = Path(__file__).resolve().parents[1]
world = (root / 'scripts/city_world.gd').read_text()
geo = (root / 'scripts/lexus_geography.gd').read_text()
map_code = (root / 'scripts/lexus_minimap.gd').read_text()
climate = (root / 'scripts/main.gd').read_text()
ui = (root / 'scripts/lexus_ui.gd').read_text()
water = (root / 'scripts/lexus_water.gd').read_text()
workflow = (root / '.github/workflows/android.yml').read_text()
project = (root / 'project.godot').read_text()
preset = (root / 'export_presets.cfg').read_text()
assert 'window/handheld/orientation=0' in project
assert 'version/code=21' in preset and 'version/name="0.0.21"' in preset
assert 'CidadeLexus-V21-debug.apk' in workflow
assert 'CidadeLexus-V21-Android-APK' in workflow
assert 'func is_river_cell' in geo and 'func is_tunnel_cell' in geo
assert 'DUQUE DE CAXIAS' in geo and 'CIDADE DE DEUS' in geo and 'ZONA NORTE' in geo
assert 'func _build_river_cell' in world and 'func _build_bridge_deck' in world
assert 'func _build_bridge_approach' in world and 'func _build_tunnel_section' in world
assert 'func _build_speed_bump' in world and 'func _build_rolling_land' in world
# Godot 4.4 cannot infer float coordinates when `sx` / `sz` are Array Variants.
for coord in ("ax", "bx", "az", "bz"):
    assert re.search(rf"(?m)^\s*var {coord}: float =", world), f"{coord} deve ser float (erro GDScript)"

assert 'create_trimesh_shape' in world and 'Visuals.box' in world
assert 'shader_type spatial' in water and 'TIME' in water
assert 'Geo.RIVER_START_Z' in map_code and 'Geo.TUNNEL_BEGIN_X' in map_code
assert 'map_radius = 1050.0' in ui and '"GPS_CDD"' in ui and '"GPS_NORTE"' in ui
assert '"/clima 1"' in climate and '"/clima 2"' in climate and '"/clima auto"' in climate
assert '"/tempo chuva"' in climate and 'func _set_climate' in climate
assert 'climate_auto' in climate and 'city.set_time' in climate
assert 'set_climate_info' in ui
# PyYAML parses YAML 1.1 'on' as bool, so only validate syntax and jobs.
obj = yaml.safe_load(workflow)
assert isinstance(obj, dict) and 'jobs' in obj and 'export' in obj['jobs']
for gd in (root / 'scripts').glob('*.gd'):
    source = gd.read_text()
    assert not re.search(r'(?m)^\s*const\s+\w+\s*:=', source), gd
    for ref in re.findall(r'preload\("res://([^"\n]+)"\)', source):
        assert (root/ref).is_file(), (gd, ref)
print('V21 STATIC OK: geography, bridge/collision, tunnel, water shader, climate, map, Android workflow')
