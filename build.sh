#!/bin/bash
# Builds the Linux Watch Dog plugin.
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
LIB="$ROOT/.deps/lib"

# Check for host API sources if not already explicitly pointed:
VIBESKUA_ROOT="${VIBESKUA_ROOT:-}"
if [ -z "$VIBESKUA_ROOT" ]; then
  if [ -f "$ROOT/../BonxieMux/Skua.sln" ]; then
    VIBESKUA_ROOT="$ROOT/../BonxieMux"
  elif [ -f "$ROOT/../VibeSkua/Skua.sln" ]; then
    VIBESKUA_ROOT="$ROOT/../VibeSkua"
  fi
fi

if [ -n "$VIBESKUA_ROOT" ] && [ -f "$VIBESKUA_ROOT/Skua.sln" ]; then
  echo "== Building host assemblies from $VIBESKUA_ROOT"
  for project in Skua.Core.Interfaces Skua.Core.Models Skua.Core.Utils; do
    dotnet build "$VIBESKUA_ROOT/$project/$project.csproj" -c Release -v quiet
  done
  mkdir -p "$LIB"
  cp "$VIBESKUA_ROOT/Skua.Core.Interfaces/bin/Release/net10.0/Skua.Core.Interfaces.dll" "$LIB/"
  cp "$VIBESKUA_ROOT/Skua.Core.Models/bin/Release/net10.0/Skua.Core.Models.dll" "$LIB/"
  cp "$VIBESKUA_ROOT/Skua.Core.Utils/bin/Release/net10.0/Skua.Core.Utils.dll" "$LIB/"
elif [ ! -f "$LIB/Skua.Core.Interfaces.dll" ] || [ ! -f "$LIB/Skua.Core.Models.dll" ] || [ ! -f "$LIB/Skua.Core.Utils.dll" ]; then
  echo "== Downloading Skua (for interface assemblies)"
  SKUA_DEPS="$ROOT/.deps/skua"
  if [ ! -d "$SKUA_DEPS/.git" ]; then
    git clone --depth 1 -b v1.4.5 https://github.com/auqw/skua.git "$SKUA_DEPS" || git clone https://github.com/auqw/skua.git "$SKUA_DEPS"
  fi
  echo "== Building Skua interface assemblies"
  dotnet build "$SKUA_DEPS/Skua.Core.Interfaces/Skua.Core.Interfaces.csproj" -c Release -p:EnableWindowsTargeting=true -v quiet
  dotnet build "$SKUA_DEPS/Skua.Core.Models/Skua.Core.Models.csproj" -c Release -v quiet
  dotnet build "$SKUA_DEPS/Skua.Core.Utils/Skua.Core.Utils.csproj" -c Release -v quiet

  mkdir -p "$LIB"
  find "$SKUA_DEPS/Skua.Core.Interfaces/bin/Release" -name "Skua.Core.Interfaces.dll" -exec cp {} "$LIB/" \; 2>/dev/null || true
  find "$SKUA_DEPS/Skua.Core.Models/bin/Release" -name "Skua.Core.Models.dll" -exec cp {} "$LIB/" \; 2>/dev/null || true
  find "$SKUA_DEPS/Skua.Core.Utils/bin/Release" -name "Skua.Core.Utils.dll" -exec cp {} "$LIB/" \; 2>/dev/null || true
fi

echo "== Building Watch Dog"
dotnet build "$ROOT/src/WatchDog.csproj" -c Release -p:SkuaLib="$LIB" -v quiet
echo "== Done: $ROOT/src/bin/Release/net10.0/WatchDog.dll"
