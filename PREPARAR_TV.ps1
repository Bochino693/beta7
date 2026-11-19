param(
    # IP da TV Box na rede (sem ele, pergunta; "usb" = TV Box no cabo USB)
    [string]$Ip = "",
    # Desfaz: a tela inicial volta a ser a da TV (o jogo continua instalado)
    [switch]$DevolverTv
)
# OLHO NO LANCE - PREPARAR A TV BOX PELO PC (adb), UMA VEZ POR TV BOX.
# Rode pelo PREPARAR_TV.bat. Para a TV Box que nao deixou o jogo se preparar
# sozinho (sem root). Faz, sem nada aparecer na TV (so "Permitir depuracao?"
# na 1a conexao):
#  - instala o APK de APK-Pronto (se existir);
#  - o jogo vira a UNICA TELA INICIAL (a tela da ROM e desligada): ligou a
#    TV Box, abre direto o jogo, sem passar pela tela da ROM;
#  - permite o jogo abrir de fundo (Android 10+) e deixa a TV sempre ligada.
# Na TV Box, antes: Configuracoes > Sobre > clique 7 vezes em "Numero da
# versao" > Opcoes do desenvolvedor > Depuracao USB LIGADA (e "Depuracao por
# rede", se houver). PC e TV Box na mesma rede.
$ErrorActionPreference = "Stop"
$Projeto = $PSScriptRoot.TrimEnd('\')
$Pacote = "com.lazersport.golflasharena"
$Inicio = "$Pacote/com.lazersport.strikeserial.StrikeInicioAtivo"

function Achar-Adb {
    $c = @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT, "C:\AndroidSdk", "C:\GolFlashBuild\android-sdk", "C:\StrikeKidsBuild\android-sdk")
    if ($env:LOCALAPPDATA) { $c += (Join-Path $env:LOCALAPPDATA "Android\Sdk") }
    foreach ($p in $c) {
        if ($p -and (Test-Path -LiteralPath (Join-Path $p "platform-tools\adb.exe"))) { return (Join-Path $p "platform-tools\adb.exe") }
    }
    $a = Get-Command adb.exe -ErrorAction SilentlyContinue
    if ($a) { return $a.Source }
    throw "nao achei o adb.exe. Rode o GERAR_APK.bat uma vez (ele baixa o Android SDK) e tente de novo."
}

function Adb([string[]]$Argumentos) {
    $saida = & $script:AdbExe @script:Alvo @Argumentos 2>&1 | Out-String
    return $saida.Trim()
}

$script:AdbExe = Achar-Adb
$script:Alvo = @()
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " OLHO NO LANCE - PREPARAR A TV BOX (adb)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
if (-not $Ip) { $Ip = Read-Host "IP da TV Box (ex.: 192.168.0.50) ou ENTER se ela esta no cabo USB" }
if ($Ip -and $Ip -ne "usb") {
    if ($Ip -notmatch ":") { $Ip = "${Ip}:5555" }
    Write-Host "Conectando em $Ip ... (na TV Box, aceite 'Permitir depuracao' e marque 'Sempre')"
    Write-Host ("  " + (& $script:AdbExe connect $Ip 2>&1 | Out-String).Trim())
    $script:Alvo = @("-s", $Ip)
}
$estado = Adb @("get-state")
if ($estado -notmatch "device") { throw "a TV Box nao respondeu ao adb ($estado). Confira o IP, a Depuracao USB e se aceitou 'Permitir depuracao' na TV." }
$sdk = [int]((Adb @("shell", "getprop", "ro.build.version.sdk")) -replace '[^0-9]', '')
Write-Host ("TV Box: Android " + (Adb @("shell", "getprop", "ro.build.version.release")) + " (API $sdk) - " + (Adb @("shell", "getprop", "ro.product.model")))

$Anotadas = "/data/local/tmp/golflash_telas_desligadas.txt"
if ($DevolverTv) {
    # religa as telas da TV que foram desligadas e desliga a tela inicial do jogo
    $lista = (Adb @("shell", "cat", $Anotadas)) -split "\s+" | Where-Object { $_ -match '^[A-Za-z0-9_.]+$' } | Select-Object -Unique
    foreach ($x in $lista) { Write-Host "  religando $x"; [void](Adb @("shell", "pm", "enable", $x)) }
    [void](Adb @("shell", "rm", "-f", $Anotadas))
    [void](Adb @("shell", "pm", "disable", $Inicio))
    Write-Host "PRONTO: a tela inicial voltou a ser a da TV (o jogo continua instalado)." -ForegroundColor Green
    exit 0
}

$apk = Join-Path $Projeto "APK-Pronto\OlhoNoLance.apk"
if (Test-Path -LiteralPath $apk) {
    Write-Host "Instalando o APK (uns minutos; se a TV perguntar, escolha 'Instalar')..."
    $r = Adb @("install", "-r", $apk)
    Write-Host "  $r"
    if ($r -notmatch "Success") { throw "a TV Box nao instalou o APK. Se aparecer INSTALL_FAILED_UPDATE_INCOMPATIBLE, desinstale o Olho no Lance dela e rode de novo." }
} elseif ((Adb @("shell", "pm", "list", "packages", $Pacote)) -notmatch $Pacote) {
    throw "o jogo nao esta na TV Box e nao achei APK-Pronto\OlhoNoLance.apk. Rode o GERAR_APK.bat antes (ou instale o APK pelo pendrive)."
}

Write-Host "Preparando: o jogo como tela inicial, abrir de fundo e TV sempre ligada..."
[void](Adb @("shell", "pm", "enable", $Inicio))
[void](Adb @("shell", "cmd", "package", "set-home-activity", $Inicio))
if ($sdk -ge 29) { [void](Adb @("shell", "cmd", "role", "add-role-holder", "android.app.role.HOME", $Pacote)) }
[void](Adb @("shell", "appops", "set", $Pacote, "SYSTEM_ALERT_WINDOW", "allow"))
[void](Adb @("shell", "appops", "set", $Pacote, "TURN_SCREEN_ON", "allow"))
[void](Adb @("shell", "dumpsys", "deviceidle", "whitelist", "+$Pacote"))
foreach ($s in @("secure screensaver_enabled 0", "secure sleep_timeout -1", "secure attentive_timeout -1", "system screen_off_timeout 2147483647")) {
    [void](Adb (@("shell", "settings", "put") + $s.Split(" ")))
}
foreach ($s in @("window_animation_scale 0", "transition_animation_scale 0", "animator_duration_scale 0", "stay_on_while_plugged_in 3")) {
    [void](Adb (@("shell", "settings", "put", "global") + $s.Split(" ")))
}
# A TV BOX E SO DO JOGO: as outras telas iniciais (a da ROM) saem, para a
# caixa ligar direto no jogo. So com a tela inicial do jogo instalada (sem
# nenhuma, a TV nao abriria nada); ficam anotadas para o -DevolverTv.
$telas = Adb @("shell", "cmd", "package", "query-activities", "--brief", "-a", "android.intent.action.MAIN", "-c", "android.intent.category.HOME")
if ($telas -match "StrikeInicioAtivo") {
    $outras = @()
    foreach ($linha in ($telas -split "`n")) {
        if ($linha -match '^\s*([A-Za-z0-9_.]+)/') {
            $pk = $Matches[1]
            if ($pk -ne $Pacote -and $pk -ne "android" -and $pk -notmatch '^com\.android\.(tv\.)?settings$' -and $outras -notcontains $pk) { $outras += $pk }
        }
    }
    foreach ($x in $outras) {
        Write-Host "  desligando a tela inicial da TV: $x"
        $r = Adb @("shell", "pm", "disable-user", "--user", "0", $x)
        if ($r -match "disabled") { [void](Adb @("shell", "sh", "-c", "'echo $x >> $Anotadas'")) }
    }
    [void](Adb @("shell", "cmd", "package", "set-home-activity", $Inicio))
} else {
    Write-Host "  AVISO: a tela inicial do jogo nao apareceu na TV Box (APK antigo?): nada foi desligado." -ForegroundColor Yellow
}
$casa = Adb @("shell", "cmd", "package", "resolve-activity", "-a", "android.intent.action.MAIN", "-c", "android.intent.category.HOME")
[void](Adb @("shell", "monkey", "-p", $Pacote, "-c", "android.intent.category.LEANBACK_LAUNCHER", "1"))
[void](Adb @("shell", "monkey", "-p", $Pacote, "-c", "android.intent.category.LAUNCHER", "1"))
Write-Host ""
if ($casa -match [Regex]::Escape($Pacote)) {
    Write-Host "TV PRONTA: tire a TV Box da tomada, espere 10 s e ligue - abre o jogo." -ForegroundColor Green
    Write-Host "A tela da ROM foi desligada: a caixa e so do jogo. NAO desinstale o jogo sem"
    Write-Host "antes rodar o -DevolverTv (a caixa ficaria sem tela inicial)."
    Write-Host "Para desfazer: PREPARAR_TV.bat -DevolverTv"
} else {
    Write-Host "A TV Box nao aceitou o jogo como tela inicial pelo adb:" -ForegroundColor Yellow
    Write-Host $casa
    Write-Host "O jogo foi aberto e a permissao de abrir de fundo foi dada: desligue e ligue a TV Box para conferir."
}
