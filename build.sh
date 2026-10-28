#!/bin/bash
# Builds the Linux VibeSkua Watch Dog plugin. The VibeSkua checkout supplies the host API
# assemblies; set VIBESKUA_ROOT when it is not the sibling ../VibeSkua directory.
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
VIBESKUA_ROOT="${VIBESKUA_ROOT:-$ROOT/../VibeSkua}"
if [ ! -f "$VIBESKUA_ROOT/Skua.sln" ]; then
  echo "VIBESKUA_ROOT does not point to a VibeSkua checkout: $VIBESKUA_ROOT" >&2
  exit 1
fi
echo "== Building VibeSkua host assemblies"
for project in Skua.Core.Interfaces Skua.Core.Models Skua.Core.Utils; do
  dotnet build "$VIBESKUA_ROOT/$project/$project.csproj" -c Release -v quiet
done
LIB="$ROOT/.deps/lib"; mkdir -p "$LIB"
cp "$VIBESKUA_ROOT/Skua.Core.Interfaces/bin/Release/net10.0/Skua.Core.Interfaces.dll" "$LIB/"
cp "$VIBESKUA_ROOT/Skua.Core.Models/bin/Release/net10.0/Skua.Core.Models.dll" "$LIB/"
cp "$VIBESKUA_ROOT/Skua.Core.Utils/bin/Release/net10.0/Skua.Core.Utils.dll" "$LIB/"
echo "== Building Watch Dog"
dotnet build "$ROOT/src/WatchDog.csproj" -c Release -p:SkuaLib="$LIB" -v quiet
echo "== Done: $ROOT/src/bin/Release/net10.0/WatchDog.dll"
