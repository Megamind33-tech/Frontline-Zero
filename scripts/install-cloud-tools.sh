#!/usr/bin/env bash
# Idempotent Cloud Agent tools: pinned Blender 5.2.3, official extensions, and host design/debug apps.
# Run from the repository root. Does not copy GPL extension source into this repository.
set -euo pipefail
bash scripts/bootstrap.sh

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y gdb krita inkscape gimp audacity imagemagick mesa-utils xvfb libgl1-mesa-dri

FZ_VERSION=5.2.3
FZ_SHA=78486c018b4443efe5e75ab54c290ed8c15abafd249b862c2c9ce2530a918eec
FZ_URL="https://download.blender.org/release/Blender5.2/blender-${FZ_VERSION}-linux-x64.tar.xz"
FZ_VER_OUT=$(blender --version 2>/dev/null || true)
if [[ "$FZ_VER_OUT" != *"Blender ${FZ_VERSION}"* ]]; then
  FZ_TMP=$(mktemp)
  curl -fL --retry 3 --connect-timeout 20 --max-time 300 -o "$FZ_TMP" "$FZ_URL"
  echo "${FZ_SHA}  ${FZ_TMP}" | sha256sum --check -
  sudo rm -rf /opt/blender
  sudo mkdir -p /opt/blender
  sudo tar -xJf "$FZ_TMP" -C /opt/blender --strip-components=1
  rm -f "$FZ_TMP"
fi
sudo ln -sfn /opt/blender/blender /usr/local/bin/blender

FZ_PKGS=looptools,bool_tool,extra_mesh_objects,precision_drawing_tools_pdt,measureit,f2,grease_pencil_tools,storypencil_storyboard_tools,storytools,antlandscape,sapling_tree_gen,omi_physics_body_gltf_extension,proto_game_asset_tools,topology_doctor,print3d_toolbox,texel_density_checker,ambientcg_material_importer,modular_tree,Bagapie
blender --background --python-expr 'import bpy,addon_utils; bpy.context.preferences.system.use_online_access=True; bpy.context.preferences.extensions.use_online_access_handled=True; addon_utils.enable("node_wrangler", default_set=True, persistent=True); addon_utils.enable("rigify", default_set=True, persistent=True); bpy.ops.wm.save_userpref()'
FZ_EXT="${XDG_CONFIG_HOME:-$HOME/.config}/blender/5.2/extensions/blender_org"
FZ_MISSING=0
IFS=',' read -ra FZ_LIST <<< "$FZ_PKGS"
for FZ_PKG in "${FZ_LIST[@]}"; do
  if [[ ! -d "$FZ_EXT/$FZ_PKG" ]]; then
    FZ_MISSING=1
    break
  fi
done
if [[ "$FZ_MISSING" == 1 ]]; then
  blender --command extension install --sync --enable "$FZ_PKGS"
fi

blender --background --python-expr 'import addon_utils,sys
need=["node_wrangler","rigify","bl_ext.blender_org.looptools","bl_ext.blender_org.bool_tool","bl_ext.blender_org.extra_mesh_objects","bl_ext.blender_org.precision_drawing_tools_pdt","bl_ext.blender_org.measureit","bl_ext.blender_org.f2","bl_ext.blender_org.grease_pencil_tools","bl_ext.blender_org.storypencil_storyboard_tools","bl_ext.blender_org.storytools","bl_ext.blender_org.antlandscape","bl_ext.blender_org.sapling_tree_gen","bl_ext.blender_org.omi_physics_body_gltf_extension","bl_ext.blender_org.proto_game_asset_tools","bl_ext.blender_org.topology_doctor","bl_ext.blender_org.print3d_toolbox","bl_ext.blender_org.texel_density_checker","bl_ext.blender_org.ambientcg_material_importer","bl_ext.blender_org.modular_tree","bl_ext.blender_org.Bagapie"]
bad=[n for n in need if addon_utils.check(n)!=(True,True)]
print("ENABLED", len(need)-len(bad), "of", len(need))
if bad:
    print("DISABLED", bad)
    sys.exit(1)'

command -v gdb krita inkscape gimp audacity convert glxinfo xvfb-run blender
blender --version
.tools/godot --version
echo "CLOUD_TOOLS_OK"
