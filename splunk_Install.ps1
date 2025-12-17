# ====================================================================================
# Script de Configuração do Splunk Universal Forwarder & Sysmon
# ------------------------------------------------------------------------------------
# Este script automatiza a configuração do Splunk Universal Forwarder e Sysmon.
# By Lyon.
# ------------------------------------------------------------------------------------
# ====================================================================================

# Variáveis de configuração
$NetworkSharePath = "xxxxxxxxxxx"  # Substitua pelo caminho correto do seu compartilhamento SMB
$SplunkInstallerPath = "$NetworkSharePath\SplunkUniversalForwarder.msi"
$SysmonInstallerPath = "$NetworkSharePath\Sysmon.zip"
$SysmonConfigPath = "$NetworkSharePath\sysmonconfig.xml"
$SplunkAppPaths = @("$NetworkSharePath\splunk-add-on-for-sysmon_400.zip", "$NetworkSharePath\splunk-add-on-for-microsoft-windows_880.zip")
$InputsConfPath = "$NetworkSharePath\inputs.conf"
$OutputsConfPath = "$NetworkSharePath\outputs.conf"
$TarPath = "$NetworkSharePath\tar.exe"  # Caminho do tar.exe fornecido
$SplunkAdminUser = "administrador"
$SplunkAdminPassword = "XXXXXXXXXXXXXXXX"

# Funções auxiliares
# Função para verificar a existência do arquivo
function Test-FileExistence {
    param (
        [string]$FilePath
    )
    if (-Not (Test-Path $FilePath)) {
        Write-Output "[-] O arquivo '$FilePath' não existe."
        exit 1
    }
}

# Função para extrair arquivos .zip
function Extract-ZIP {
    param (
        [string]$AppPath,
        [string]$DestinationBasePath
    )
    Expand-Archive -Path $AppPath -DestinationPath $DestinationBasePath -Force
}

# Função para detectar a versão do Windows Installer e definir os parâmetros de instalação
function Get-MsiExecArguments {
    $windowsInstallerVersion = (Get-Command msiexec.exe).FileVersionInfo.FileVersion
    if ($windowsInstallerVersion -ge "5.0.0") {
        return "/i `"$SplunkInstallerPath`" AGREETOLICENSE=Yes /quiet"
    } else {
        return "/i `"$SplunkInstallerPath`" /quiet"
    }
}

# Função: Instalar Sysmon para monitoramento avançado
function Install-Sysmon {
    try {
        Test-FileExistence -FilePath $SysmonInstallerPath
        Expand-Archive -Path $SysmonInstallerPath -DestinationPath C:\Sysmon -Force

        # Instalar o Sysmon com a configuração diretamente do Sysvol
        Test-FileExistence -FilePath $SysmonConfigPath
        Start-Process -FilePath "C:\Sysmon\Sysmon.exe" -ArgumentList "-accepteula -i $SysmonConfigPath" -Wait
        Write-Output "[+] Logs do Sysmon Implementados diretamente do Sysvol."
    } catch {
        Write-Output "[-] Erro ao instalar e configurar Sysmon: ${_}"
    }
}

# Função: Aplicar nova configuração de Sysmon diretamente do Sysvol
function Update-SysmonConfig {
    try {
        Test-FileExistence -FilePath $SysmonConfigPath
        Start-Process -FilePath "C:\Sysmon\Sysmon.exe" -ArgumentList "-c $SysmonConfigPath" -Wait
        Write-Output "[+] Configuração do Sysmon atualizada diretamente do caminho de rede."
    } catch {
        Write-Output "[-] Erro ao aplicar configuração do Sysmon: ${_}"
    }
}

# Função para Configurar Splunk Universal Forwarder (código completo)
function Configure-SplunkUF {
    param (
        [string]$SplunkInstallerPath,
        [string]$SplunkInstallPath,
        [string]$SplunkAdminUser,
        [string]$SplunkAdminPassword,
        [array]$SplunkAppPaths,
        [string]$InputsConfPath,
        [string]$OutputsConfPath
    )
    
    try {
        Test-FileExistence -FilePath $SplunkInstallerPath

        # Detectar a versão do Windows Installer e definir os parâmetros de instalação
        $msiExecArgs = Get-MsiExecArguments

        # Instalar o Splunk Universal Forwarder
        Start-Process msiexec.exe -ArgumentList $msiExecArgs -Wait
        Write-Output "[+] Splunk Universal Forwarder instalado com sucesso."

        # Verificar se o Splunk foi instalado corretamente
        if (-Not (Test-Path "$SplunkInstallPath\bin\splunk.exe")) {
            Write-Output "[-] O caminho '$SplunkInstallPath\bin\splunk.exe' não existe. A instalação do Splunk pode ter falhado."
            exit 1
        }

        # Iniciar e configurar Splunk
        $splunkBinPath = "$SplunkInstallPath\bin\splunk.exe"
        & $splunkBinPath start --accept-license

        # Verificar se o serviço já está instalado
        $service = Get-Service -Name SplunkForwarder -ErrorAction SilentlyContinue
        if ($service -eq $null) {
            & $splunkBinPath enable boot-start
        } else {
            Write-Output "[+] O serviço SplunkForwarder já está instalado."
        }

        # Alterar configuração para permitir login remoto
        $serverConfPath = "$SplunkInstallPath\etc\system\local\server.conf"
        if (-Not (Test-Path $serverConfPath)) {
            New-Item -Path $serverConfPath -ItemType File
        }
        Add-Content -Path $serverConfPath -Value "[general]"
        Add-Content -Path $serverConfPath -Value "allowRemoteLogin = always"

        # Reiniciar Splunk para aplicar alterações
        & $splunkBinPath restart

        Write-Output "[+] Splunk configurado com usuário administrador."

        # Extrair e mover aplicativos do Splunk
        foreach ($appPath in $SplunkAppPaths) {
            Test-FileExistence -FilePath $appPath
            Extract-ZIP -AppPath $appPath -DestinationBasePath "$SplunkInstallPath\etc\apps"
        }

        Write-Output "[+] Aplicativos do Splunk instalados com sucesso."

        # Configurar inputs.conf e outputs.conf
        $splunkAppDir = "$SplunkInstallPath\etc\apps\Splunk_TA_microsoft_sysmon\default"
        if (-Not (Test-Path $splunkAppDir)) {
            New-Item -Path $splunkAppDir -ItemType Directory -Force
        }

        Test-FileExistence -FilePath $InputsConfPath
        $inputsConfDestination = "$splunkAppDir\inputs.conf"
        Copy-Item -Path $InputsConfPath -Destination $inputsConfDestination -Force
        Write-Output "[+] inputs.conf configurado com sucesso."

        Test-FileExistence -FilePath $OutputsConfPath
        $outputsConfDestination = "$splunkAppDir\outputs.conf"
        Copy-Item -Path $OutputsConfPath -Destination $outputsConfDestination -Force
        Write-Output "[+] outputs.conf configurado com sucesso."

        # Reiniciar Splunk após a configuração
        & "$splunkBinPath" restart
        Write-Output "[+] Splunk reiniciado com sucesso."

    } catch {
        Write-Output "[-] Erro ao configurar Splunk Universal Forwarder: ${_}"
    }
}

# Função para remover completamente o Splunk Universal Forwarder
function Remove-SplunkUF {
    try {
        Write-Output "[+] Removendo Splunk Universal Forwarder..."

        # Verificar se o Splunk Universal Forwarder está instalado
        $splunkPackage = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -match "UniversalForwarder" }
        
        if ($splunkPackage) {
            # Remover o pacote via msiexec
            $packageCode = $splunkPackage.IdentifyingNumber
            Start-Process msiexec.exe -ArgumentList "/x $packageCode /quiet /norestart" -Wait
            Write-Output "[+] Splunk Universal Forwarder removido completamente."
        } else {
            Write-Output "[-] Splunk Universal Forwarder não encontrado. Pode já ter sido removido."
        }
        
    } catch {
        Write-Output "[-] Erro ao remover Splunk Universal Forwarder: ${_}"
    }
}

# Função para remover Sysmon com supressão de saída
function Remove-Sysmon {
    try {
        Write-Output "[+] Removendo Sysmon..."
        if (Test-Path "C:\Sysmon\Sysmon.exe") {
            & "C:\Sysmon\Sysmon.exe" -u *>$null  # limpando saída e erros by ailton
            Remove-Item -Path "C:\Sysmon" -Recurse -Force
            Write-Output "[+] Sysmon removido com sucesso."
        } else {
            Write-Output "[-] Sysmon não encontrado."
        }
    } catch {
        Write-Output "[-] Erro ao remover Sysmon: ${_}"
    }
}

# Função para reiniciar serviço do Splunk
function Restart-SplunkService {
    try {
        Write-Output "[+] Reiniciando o serviço Splunk..."
        Restart-Service -Name SplunkForwarder -Force
        Write-Output "[+] Serviço Splunk reiniciado com sucesso."
    } catch {
        Write-Output "[-] Erro ao reiniciar o serviço Splunk: ${_}"
    }
}

# Função para reiniciar serviço do Sysmon
function Restart-SysmonService {
    try {
        Write-Output "[+] Reiniciando o serviço Sysmon..."
        Stop-Process -Name Sysmon -Force
        Start-Process -FilePath "C:\Sysmon\Sysmon.exe" -ArgumentList "-accepteula -i $SysmonConfigPath"
        Write-Output "[+] Serviço Sysmon reiniciado com sucesso."
    } catch {
        Write-Output "[-] Erro ao reiniciar o serviço Sysmon: ${_}"
    }
}

function Show-Menu {
    while ($true) {
        Clear-Host
        Write-Output "=========================================="
        Write-Output "         Script de Configuração"
        Write-Output "           Splunk UF e Sysmon"
        Write-Output "    Criado Por Lyon. (Threat Hunting)"
        Write-Output "=========================================="
        Write-Output "[1] Instalar e Configurar Splunk Universal Forwarder"
        Write-Output "[2] Instalar e Configurar Sysmon"
        Write-Output "[3] Instalar Splunk Universal Forwarder + Sysmon"
        Write-Output "------------------------------------------"
        Write-Output "[4] Aplicar Nova Configuração Sysmon"
        Write-Output "------------------------------------------"
        Write-Output "[5] Remover Splunk Universal Forwarder"
        Write-Output "[6] Remover Sysmon"
        Write-Output "[7] Remover e Reinstalar Splunk Universal Forwarder + Sysmon"
        Write-Output "[8] Remover Splunk Universal Forwarder + Sysmon"
        Write-Output "------------------------------------------"
        Write-Output "[9] Reiniciar Serviço Splunk"
        Write-Output "[10] Reiniciar Serviço Sysmon"
        Write-Output "------------------------------------------"
        Write-Output "[11] Sair"
        Write-Output "=========================================="
        $choice = Read-Host "Escolha uma opção"

        switch ($choice) {
            "1" {
                Configure-SplunkUF -SplunkInstallerPath $SplunkInstallerPath -SplunkInstallPath "C:\Program Files\SplunkUniversalForwarder" -SplunkAdminUser $SplunkAdminUser -SplunkAdminPassword $SplunkAdminPassword -SplunkAppPaths $SplunkAppPaths -InputsConfPath $InputsConfPath -OutputsConfPath $OutputsConfPath
            }
            "2" { Install-Sysmon }
            "3" {
                Configure-SplunkUF -SplunkInstallerPath $SplunkInstallerPath -SplunkInstallPath "C:\Program Files\SplunkUniversalForwarder" -SplunkAdminUser $SplunkAdminUser -SplunkAdminPassword $SplunkAdminPassword -SplunkAppPaths $SplunkAppPaths -InputsConfPath $InputsConfPath -OutputsConfPath $OutputsConfPath
                Install-Sysmon
            }
            "4" { Update-SysmonConfig }
            "5" { Remove-SplunkUF }
            "6" { Remove-Sysmon }
            "7" {
                Remove-SplunkUF
                Remove-Sysmon
                Configure-SplunkUF -SplunkInstallerPath $SplunkInstallerPath -SplunkInstallPath "C:\Program Files\SplunkUniversalForwarder" -SplunkAdminUser $SplunkAdminUser -SplunkAdminPassword $SplunkAdminPassword -SplunkAppPaths $SplunkAppPaths -InputsConfPath $InputsConfPath -OutputsConfPath $OutputsConfPath
                Install-Sysmon
            }
            "8" {
                Remove-SplunkUF
                Remove-Sysmon
            }
            "9" { Restart-SplunkService }
            "10" { Restart-SysmonService }
            "11" {
                Write-Output "Saindo..."
                break
            }
            default {
                Write-Output "Opção inválida, tente novamente."
            }
        }
        Read-Host "Pressione Enter para continuar..."
    }
}

# Executa o menu
Show-Menu

