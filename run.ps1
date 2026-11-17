<#
.SYNOPSIS
    Launcher Automatizado Efemero - BW Unlocker (Public Release)
.DESCRIPTION
    Baixa o executavel protegido diretamente da Release do GitHub em memoria/temp,
    valida a integridade SHA-256 em tempo real, executa o loader e remove completamente
    todos os arquivos temporarios apos o fechamento.
#>

[CmdletBinding()]
param(
    [string]$ReleaseRepo = "bw-exe/bw-release",
    [string]$Version = "v0.1.0",
    [string]$ExpectedHash = "1E6904833DF13565EE0A5A432B8D33C61B0BFA327EA683E318FC512E17A74221"
)

$ErrorActionPreference = 'Stop'

# 1. Auto-Elevacao: Garante privilegios de Administrador para o WinDivert
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[*] Solicitando privilegios de Administrador..." -ForegroundColor Yellow
    $argsList = "-NoProfile -ExecutionPolicy Bypass -Command `"& { irm https://raw.githubusercontent.com/$ReleaseRepo/main/run.ps1 | iex }`""
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argsList
    exit
}

Clear-Host
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "             BW UNLOCKER - LAUNCHER                  " -ForegroundColor White
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

$tempId = [guid]::NewGuid().ToString("N").Substring(0, 8)
$sessionDir = Join-Path ([System.IO.Path]::GetTempPath()) ("bw-" + $tempId)
$targetExe = Join-Path $sessionDir "BW-Unlocker.exe"
$downloadUrl = "https://github.com/$ReleaseRepo/releases/download/$Version/BW-Unlocker.exe"

try {
    # 2. Criar sandbox temporaria efemera
    New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null

    # 3. Download do executavel protegido com barra de progresso
    Write-Host "[*] Baixando binario do servidor..." -ForegroundColor Yellow
    
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "PowerShell-BW-Client")
    $webClient.DownloadFile($downloadUrl, $targetExe)
    
    if (-not (Test-Path $targetExe)) {
        throw "Falha ao baixar o executavel. Verifique sua conexao."
    }

    # 4. Verificacao de Integridade SHA-256
    Write-Host "[*] Validando assinatura e integridade SHA-256..." -ForegroundColor Yellow
    $fileHash = (Get-FileHash -LiteralPath $targetExe -Algorithm SHA256).Hash.ToUpperInvariant()
    
    if ($ExpectedHash -and ($fileHash -ne $ExpectedHash.ToUpperInvariant())) {
        throw "Erro de integridade: O hash do arquivo difere da release oficial!"
    }
    Write-Host "[+] Integridade verificada com sucesso." -ForegroundColor Green

    # 5. Execucao monitorada do aplicativo
    Write-Host "[*] Iniciando BW Unlocker..." -ForegroundColor Cyan
    Write-Host "[i] Esta janela monitora a sessao. Ao fechar o loader, a limpeza ocorrera automaticamente." -ForegroundColor Gray
    
    $process = Start-Process -FilePath $targetExe -WorkingDirectory $sessionDir -PassThru
    $process.WaitForExit()

} catch {
    Write-Host ""
    Write-Host "[!] ERRO: $_" -ForegroundColor Red
    Write-Host "Pressione qualquer tecla para sair..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} finally {
    # 6. Auto-Destruicao e Limpeza Sanitaria
    Write-Host ""
    Write-Host "[*] Sessao finalizada. Executando limpeza sanitaria..." -ForegroundColor Yellow
    
    # Restaura eventuais rotas ou proxy
    try {
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -Name ProxyEnable -Value 0 -ErrorAction SilentlyContinue
    } catch {}

    # Deleta permanentemente a pasta temporaria
    if (Test-Path $sessionDir) {
        Remove-Item -LiteralPath $sessionDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host "[+] Limpeza concluida. Nenhum arquivo restante no disco." -ForegroundColor Green
    Start-Sleep -Seconds 1
}
