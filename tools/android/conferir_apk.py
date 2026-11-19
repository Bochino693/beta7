#!/usr/bin/env python3
"""Confere o APK da TV Box / TV Android (aapt2 + apksigner do Android SDK):
   python3 -I tools/android/conferir_apk.py <apk> <pasta build-tools/35.0.1>
Pacote certo, assinado, plugin do Arduino (StrikeSerial v2) com as classes
dentro, tela inicial (HOME), receptor de "a TV ligou", filtro USB do Arduino,
Android TV (leanback + banner) e as bibliotecas arm64 + arm32 do Godot."""
import os
import re
import subprocess
import sys
import zipfile

apk, bt = sys.argv[1], sys.argv[2]
falhas = []


def rodar(*a):
    amb = dict(os.environ)
    amb.pop("JAVA_TOOL_OPTIONS", None)
    amb.pop("_JAVA_OPTIONS", None)
    r = subprocess.run(a, capture_output=True, text=True, env=amb)
    return r.stdout + r.stderr


def confere(ok, texto):
    print(("  ok     " if ok else "  FALHOU ") + texto)
    if not ok:
        falhas.append(texto)


z = zipfile.ZipFile(apk)
nomes = z.namelist()
manifesto = rodar(os.path.join(bt, "aapt2"), "dump", "xmltree", "--file", "AndroidManifest.xml", apk)
cracha = rodar(os.path.join(bt, "aapt2"), "dump", "badging", apk)
dex = b"".join(z.read(n) for n in nomes if re.fullmatch(r"classes\d*\.dex", n))

m = re.search(r"package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", cracha)
confere(bool(m) and m.group(1) == "com.lazersport.golflasharena", "pacote com.lazersport.golflasharena (%s)" % (m.group(0) if m else "?"))
confere("application-label:'Gol Flash Arena'" in cracha, "nome Gol Flash Arena")
for abi in ("arm64-v8a", "armeabi-v7a"):
    confere("lib/%s/libgodot_android.so" % abi in nomes, "motor do Godot para %s" % abi)
confere("org.godotengine.plugin.v2.StrikeSerial" in manifesto, "plugin StrikeSerial registrado (v2)")
for classe in ("StrikeSerial", "InicioDaTv", "StrikeInicioAtivo", "StrikeLigou", "StrikeArduinoAtivo"):
    confere(("Lcom/lazersport/strikeserial/%s;" % classe).encode() in dex, "classe %s dentro do APK" % classe)
confere("android.intent.category.HOME" in manifesto, "tela inicial (HOME): abre sozinho ao ligar")
confere("android.intent.action.BOOT_COMPLETED" in manifesto and "RECEIVE_BOOT_COMPLETED" in manifesto, "receptor de \"a TV ligou\" + permissão")
confere("USB_DEVICE_ATTACHED" in manifesto, "filtro USB do Arduino (permissão guardada)")
confere("android.intent.category.LEANBACK_LAUNCHER" in manifesto, "aparece na tela da Android TV (leanback)")
confere("android:banner" in manifesto, "banner da Android TV")
confere("android.hardware.touchscreen" not in cracha or "uses-feature-not-required: name='android.hardware.touchscreen'" in cracha
        or "uses-implied-feature: name='android.hardware.touchscreen'" not in cracha, "não exige tela de toque")
assinatura = rodar(os.path.join(bt, "apksigner"), "verify", "--verbose", "--print-certs", apk)
confere("Verified using v2 scheme (APK Signature Scheme v2): true" in assinatura, "assinado (v2)")
confere("CN=Gol Flash Arena" in assinatura, "chave do projeto (instala por cima do anterior)")
pck = [n for n in nomes if n.startswith("assets/")]
confere(any(n.endswith("project.binary") for n in pck), "jogo dentro do APK (%d arquivos em assets)" % len(pck))
for fora in ("patro/", "init_old", "inite.mp4", ".ino", "GERAR_APK"):
    confere(not any(fora in n for n in pck), "sem %s no APK" % fora)
print("tamanho: %.1f MB" % (os.path.getsize(apk) / 1048576.0))
if falhas:
    print("APK COM PROBLEMA (%d)" % len(falhas))
    sys.exit(1)
print("APK OK")
