#!/bin/sh
# Builds mechView.ms for the browser (WebGL2) into ../landing/public/void/gl with Void's web script,
# and packs the models it fetches into ../landing/public/void/models.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
MODELS="$HERE/../landing/public/void/models"
rm -rf "$MODELS" "$HERE/../landing/public/void/coreDetail.glb"
mkdir -p "$MODELS"
for model in body coreLite coreDetail; do
	gzip -9 -c "$HERE/$model.glb" > "$MODELS/$model.glb.packed"
done
cd "$HERE/../../void"
VOID_WEB_ENTRY="$HERE/mechView.ms" VOID_WEB_DEST="$HERE/../landing/public/void" \
	VOID_WEB_PRELOAD="--preload-file $HERE/coreUnfold.json@coreUnfold.json -sALLOW_MEMORY_GROWTH=1" \
	sh scripts/build-web.sh
