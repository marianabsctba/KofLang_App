# Para os microsservicos da suite Be Safe (portas 8080, 8081 e 8082).
foreach ($porta in 8080, 8081, 8082) {
    $conexao = Get-NetTCPConnection -LocalPort $porta -State Listen -ErrorAction SilentlyContinue
    if ($conexao) {
        Stop-Process -Id $conexao.OwningProcess -Confirm:$false
        Write-Host "Parado o servico da porta $porta"
    }
}
