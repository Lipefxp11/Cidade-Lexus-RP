"""Static package smoke checks; headless Godot checks are separate in Actions."""
from pathlib import Path
import re
import struct

root = Path(__file__).resolve().parents[1]
project = (root / "project.godot").read_text()
preset = (root / "export_presets.cfg").read_text()
assert "window/handheld/orientation=0" in project, "Android must run in landscape"
assert 'package/unique_name="com.cidadelexusrp.game"' in preset
assert re.search(r"version/code=(?:18|19|20|21)\b", preset), "unsupported app version"
assert not (root / "cidade-lexus" / "project.godot").exists(), "Nested Godot project found"
for filename in ["lexus_districts.gd", "lexus_interiors.gd", "lexus_vehicle.gd", "lexus_ui.gd", "main.gd"]:
    assert (root / "scripts" / filename).exists(), filename
for script in (root / "scripts").glob("*.gd"):
    text = script.read_text()
    assert not re.search(r"(?m)^\s*const\s+\w+\s*:=", text), script
    for resource in re.findall(r'(?:preload|load)\("(res://[^"\n]+)"\)', text):
        assert (root / resource.removeprefix("res://")).is_file(), (script, resource)
    for index, line in enumerate(text.splitlines(), start=1):
        if line.startswith(" ") and line.strip() and not line.lstrip().startswith("#"):
            raise AssertionError(f"Inconsistent GDScript indentation: {script}:{index}")
character = root / "assets/models/character.glb"
blob = character.read_bytes()
assert len(blob) > 1000 and blob[:4] == b"glTF" and struct.unpack_from("<I", blob, 8)[0] == len(blob)
main = (root / "scripts/main.gd").read_text()
ui = (root / "scripts/lexus_ui.gd").read_text()
world = (root / "scripts/city_world.gd").read_text()
for feature in ["_on_interaction_selected", "_enter_house", "_leave_house", "_service_vehicle_action", "_nearest_vehicle", "_is_valid_action_for_context"]:
    assert feature in main, feature
for feature in ["show_actions", "open_full_map", "zoom_full_map", "set_context_hint", "set_organization"]:
    assert feature in ui, feature
for feature in ["nearest_interactable", "district_name", "all_map_points", "add_hill_terrain", "add_tunnel"]:
    assert feature in world or feature in (root / "scripts/lexus_districts.gd").read_text(), feature
print("V18 static OK: resources, landscape, app id, original GLB, systems and directories")
