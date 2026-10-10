# Compila o frontend e sobe os tres microsservicos da suite Be Safe.
# Uso: .\scripts\subir.ps1   (depois abra http://localhost:8080)
$ErrorActionPreference = 'Stop'
$raiz = Split-Path -Parent $PSScriptRoot

# Usa o compilador local em .kof/ se existir; senao, o kof do PATH.
$kof = Join-Path $raiz '.kof\bin\kof.bat'
if (-not (Test-Path $kof)) { $kof = 'kof' }

$logs = Join-Path $raiz '.logs'
$frontend = Join-Path $raiz 'dist\frontend'
New-Item -ItemType Directory -Force $logs, $frontend | Out-Null

Write-Host 'Compilando o frontend (Kof -> JavaScript)...'
& $kof build (Join-Path $raiz 'frontend') --target js --output $frontend | Out-Null
Copy-Item (Join-Path $raiz 'frontend\index.html') $frontend -Force
Copy-Item (Join-Path $raiz 'frontend\static') $frontend -Recurse -Force

$servicos = @(
    @{ nome = 'phishing'; porta = 8081 },
    @{ nome = 'senhas';   porta = 8082 },
    @{ nome = 'gateway';  porta = 8080 }
)
$env:FRONTEND_DIR = $frontend
foreach ($s in $servicos) {
    $env:PORTA = $s.porta
    $pasta = Join-Path $raiz "servicos\$($s.nome)"
    $log = Join-Path $logs "$($s.nome).log"
    Start-Process -FilePath $kof -ArgumentList 'run', 'Main.kf', '--target', 'jvm' `
        -WorkingDirectory $pasta -RedirectStandardOutput $log -RedirectStandardError "$log.err" -WindowStyle Hidden
    Write-Host "Subindo $($s.nome) na porta $($s.porta)"
}
Remove-Item Env:PORTA, Env:FRONTEND_DIR

Write-Host 'Aguardando os servicos...'
foreach ($s in $servicos) {
    for ($i = 0; $i -lt 60; $i++) {
        try { Invoke-RestMethod "http://localhost:$($s.porta)/saude" -TimeoutSec 2 | Out-Null; break } catch { Start-Sleep 2 }
    }
}
Write-Host 'Pronto: http://localhost:8080'
