#!/bin/bash
# APK DA TV BOX / TV ANDROID NO LINUX - o mesmo caminho do GERAR_APK.bat:
#   bash tools/android/montar_apk.sh [saida.apk]
# 1. copia o projeto para uma pasta de trabalho (o original não é alterado);
# 2. instala nela o modelo Gradle do Godot 4.6.1 (android/build);
# 3. exporta o preset "Android TV Box" com o Godot 4.6.1 headless (build
#    Gradle: é ele que põe o plugin do Arduino/USB e do "abrir ao ligar");
# 4. confere o APK (pacote, plugin, tela inicial, receptor de "ligou").
# Variáveis (todas com padrão em FERRAMENTAS=~/golflash_ferramentas):
#   GODOT4   Godot_v4.6.1-stable_linux.x86_64
#   MODELOS  pasta com android_source.zip e version.txt (4.6.1.stable)
#   ANDROID_HOME  SDK com platform-tools, build-tools;35.0.1,
#                 platforms;android-35 e ndk;28.1.13356709
#   JAVA_HOME     JDK 17 ou mais novo
#   TRAB     pasta de trabalho
set -e
FERRAMENTAS=${FERRAMENTAS:-$HOME/golflash_ferramentas}
AQUI=$(cd "$(dirname "$0")" && pwd)
P=$(cd "$AQUI/../.." && pwd)
SAIDA=$(realpath -m "${1:-$P/build/android/GolFlashArena.apk}")
GODOT4=${GODOT4:-$FERRAMENTAS/Godot_v4.6.1-stable_linux.x86_64}
MODELOS=${MODELOS:-$FERRAMENTAS/modelos}
ANDROID_HOME=${ANDROID_HOME:-$FERRAMENTAS/sdk}
JAVA_HOME=${JAVA_HOME:-$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")}
TRAB=${TRAB:-${TMPDIR:-/tmp}/golflash_apk}
CHAVE=$AQUI/golflash.keystore
export ANDROID_HOME ANDROID_SDK_ROOT=$ANDROID_HOME JAVA_HOME

for f in "$GODOT4" "$MODELOS/android_source.zip" "$CHAVE" "$ANDROID_HOME/platform-tools/adb" \
  "$ANDROID_HOME/build-tools/35.0.1/apksigner" "$P/addons/StrikeSerial/bin/StrikeSerial.aar"; do
  [ -f "$f" ] || { echo "falta: $f" >&2; exit 1; }
done
[ "$(cat "$MODELOS/version.txt")" = "4.6.1.stable" ] || { echo "os modelos em $MODELOS não são do Godot 4.6.1" >&2; exit 1; }
case "$TRAB" in /|"$HOME"|"$P"|"$P"/*) echo "TRAB perigoso: $TRAB" >&2; exit 1 ;; esac
mkdir -p "$TRAB/projeto" "$TRAB/saida" "$(dirname "$SAIDA")"

echo "== 1. projeto"
# mantém o cache de importação (.godot) e o modelo Gradle (android) da vez anterior
find "$TRAB/projeto" -mindepth 1 -maxdepth 1 ! -name .godot ! -name android -exec rm -rf {} +
(cd "$P" && tar --exclude=./.git --exclude=./.godot --exclude=./android --exclude=./build \
  --exclude=./APK-Pronto --exclude=./override.cfg --exclude='./_harness.gd*' -cf - .) | tar -C "$TRAB/projeto" -xf -

echo "== 2. modelo Gradle"
B=$TRAB/projeto/android/build
if [ ! -f "$B/build.gradle" ] || [ "$(cat "$TRAB/projeto/android/.build_version" 2>/dev/null)" != "4.6.1.stable" ]; then
  rm -rf "$B"; mkdir -p "$B"
  unzip -q "$MODELOS/android_source.zip" -d "$B"
  echo "4.6.1.stable" > "$TRAB/projeto/android/.build_version"
  touch "$B/.gdignore"
fi
chmod +x "$B/gradlew"

# Java "falante" (JAVA_TOOL_OPTIONS / _JAVA_OPTIONS no ambiente escrevem
# "Picked up..." antes da versão e o Godot não entende a versão do Java):
# um JAVA_HOME de fachada cujo "java -version" responde limpo.
if [ -n "${JAVA_TOOL_OPTIONS:-}${_JAVA_OPTIONS:-}" ]; then
  FACHADA=$TRAB/java
  rm -rf "$FACHADA"; mkdir -p "$FACHADA/bin"
  for f in "$JAVA_HOME"/*; do [ "$(basename "$f")" = bin ] || ln -s "$f" "$FACHADA/"; done
  for f in "$JAVA_HOME"/bin/*; do [ "$(basename "$f")" = java ] || ln -s "$f" "$FACHADA/bin/"; done
  cat > "$FACHADA/bin/java" <<SH
#!/bin/bash
if [ "\$1" = "-version" ] || [ "\$1" = "--version" ]; then
  "$JAVA_HOME/bin/java" "\$@" 2>&1 | grep -v "^Picked up" >&2
  exit 0
fi
exec "$JAVA_HOME/bin/java" "\$@"
SH
  chmod +x "$FACHADA/bin/java"
  JAVA_HOME=$FACHADA; export JAVA_HOME
fi

echo "== 3. exportar (Godot 4.6.1 + Gradle; a 1a vez baixa o Gradle e demora)"
CASA=$TRAB/godot
mkdir -p "$CASA/config/godot" "$CASA/data/godot/export_templates" "$CASA/cache"
ln -sfn "$MODELOS" "$CASA/data/godot/export_templates/4.6.1.stable"
cat > "$CASA/config/godot/editor_settings-4.6.tres" <<CFG
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/java_sdk_path = "$JAVA_HOME"
export/android/android_sdk_path = "$ANDROID_HOME"
CFG
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$CHAVE
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=golflash
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=golflash
export GRADLE_USER_HOME=${GRADLE_USER_HOME:-$TRAB/gradle}
rm -f "$TRAB/saida/GolFlashArena.apk"
XDG_CONFIG_HOME=$CASA/config XDG_DATA_HOME=$CASA/data XDG_CACHE_HOME=$CASA/cache \
  "$GODOT4" --headless --path "$TRAB/projeto" --export-release "Android TV Box" "$TRAB/saida/GolFlashArena.apk" \
  > "$TRAB/exportar.log" 2>&1 || true
grep -E "ERROR|BUILD|FAILED|error:|What went wrong" -A3 "$TRAB/exportar.log" | grep -v "^--$" | head -40 || true
[ -s "$TRAB/saida/GolFlashArena.apk" ] || { echo "o APK não saiu: veja $TRAB/exportar.log" >&2; exit 1; }

echo "== 4. conferir"
python3 -I "$AQUI/conferir_apk.py" "$TRAB/saida/GolFlashArena.apk" "$ANDROID_HOME/build-tools/35.0.1"
cp "$TRAB/saida/GolFlashArena.apk" "$SAIDA"
ls -la "$SAIDA"
