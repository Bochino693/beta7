extends Node

const PORTA := "COM5"
const BAUD := "9600"


func _ready() -> void:
	print("================================")
	print("TESTE SERIAL VIA POWERSHELL")
	print("PORTA: ", PORTA)
	print("BAUD: ", BAUD)
	print("================================")

	await get_tree().create_timer(1.0).timeout

	_testar_powershell_serial()


func _testar_powershell_serial() -> void:
	var comando := """
$port = New-Object System.IO.Ports.SerialPort '%s', %s, 'None', 8, 'One'
$port.DtrEnable = $true
$port.RtsEnable = $true
$port.Open()
Start-Sleep -Milliseconds 2500

Write-Host 'ENVIANDO PING'
$port.WriteLine('PING')
Start-Sleep -Milliseconds 300

Write-Host 'APAGANDO'
$port.WriteLine('OFF')
Start-Sleep -Milliseconds 500

Write-Host 'ACENDENDO A D2 AZUL'
$port.WriteLine('SET:A=0,0,255')
Start-Sleep -Milliseconds 1500

Write-Host 'ACENDENDO B D3 VERMELHO'
$port.WriteLine('SET:B=255,0,0')
Start-Sleep -Milliseconds 1500

Write-Host 'ACENDENDO C D4 VERDE'
$port.WriteLine('SET:C=0,255,0')
Start-Sleep -Milliseconds 1500

Write-Host 'ACENDENDO A+B+C'
$port.WriteLine('SET:A=0,0,255;B=255,0,0;C=0,255,0')
Start-Sleep -Milliseconds 2500

Write-Host 'OFF FINAL'
$port.WriteLine('OFF')
Start-Sleep -Milliseconds 500

$port.Close()
""" % [PORTA, BAUD]

	var output: Array = []

	var args := [
		"-NoProfile",
		"-ExecutionPolicy",
		"Bypass",
		"-Command",
		comando
	]

	var exit_code := OS.execute("powershell.exe", args, output, true, false)

	print("================================")
	print("POWERSHELL FINALIZOU")
	print("EXIT CODE: ", exit_code)
	print("SAÍDA:")
	for linha in output:
		print(linha)
	print("================================")
