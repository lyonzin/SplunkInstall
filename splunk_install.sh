#!/bin/bash

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  _____ _   _ ____  _____    _  _____   _   _ _   _ _   _ _____ ___ _   _  ____   _
# |_   _| | | |  _ \| ____|  / \|_   _| | | | | | | | \ | |_   _|_ _| \ | |/ ___| | |
#   | | | |_| | |_) |  _|   / _ \ | |   | |_| | | | |  \| | | |  | ||  \| | |  _  | |
#   | | |  _  |  _ <| |___ / ___ \| |   |  _  | |_| | |\  | | |  | || |\  | |_| | |_|
#   |_| |_| |_|_| \_\_____/_/   \_\_|   |_| |_|\___/|_| \_| |_| |___|_| \_|\____| (_)
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                                   Splunk Manager Script
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Criado por:              Lyon.
# Data de Criação:         2024-10-10
# Última Modificação:      2024-10-10
# Versão:                  1.3
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Cores para saída estilizada
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # Sem cor

# Defina a versão do Splunk e o link de download
#wget -O splunk-9.3.1-0b8d769cb912-Linux-x86_64.tgz "https://download.splunk.com/products/splunk/releases/9.3.1/linux/splunk-9.3.1-0b8d769cb912-Linux-x86_64.tgz"
SPLUNK_VERSION="9.3.1"
SPLUNK_BUILD="0b8d769cb912"
SPLUNK_PACKAGE="splunk-${SPLUNK_VERSION}-${SPLUNK_BUILD}-Linux-x86_64.tgz"
SPLUNK_DOWNLOAD_URL="https://download.splunk.com/products/splunk/releases/${SPLUNK_VERSION}/linux/${SPLUNK_PACKAGE}"

# Diretório de instalação do Splunk
SPLUNK_DIR="/opt/splunk"

# Variáveis de autenticação do Splunk
SPLUNK_USER="admin"
SPLUNK_PASSWORD="Passw0rd"  # Substitua pela senha

# Função para exibir cabeçalho
display_header() {
    clear
    echo -e "${CYAN}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo -e "  _____ _   _ ____  _____    _  _____   _   _ _   _ _   _ _____ ___ _   _  ____   _"
    echo -e " |_   _| | | |  _ \| ____|  / \|_   _| | | | | | | | \ | |_   _|_ _| \ | |/ ___| | |"
    echo -e "   | | | |_| | |_) |  _|   / _ \ | |   | |_| | | | |  \| | | |  | ||  \| | |  _  | |"
    echo -e "   | | |  _  |  _ <| |___ / ___ \| |   |  _  | |_| | |\  | | |  | || |\  | |_| | |_|"
    echo -e "   |_| |_| |_|_| \_\_____/_/   \_\_|   |_| |_|\___/|_| \_| |_| |___|_| \_|\____| (_)"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo -e "                                   Splunk Manager Script"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo -e " Criado por:              Lyon."
    echo -e " Data de Criação:         2024-10-10"
    echo -e " Última Modificação:      2024-10-10"
    echo -e " Versão:                  1.3"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
}

# Função para configurar a porta 9997
configure_port() {
    echo -e "${YELLOW}---------------------------------------"
    echo -e "[+] Configurando as portas 8000 e 9997..."
    echo -e "---------------------------------------${NC}"

    if command -v iptables &> /dev/null; then
        # Usar iptables
        sudo iptables -A INPUT -p tcp --dport 9997 -j ACCEPT
        sudo iptables -A OUTPUT -p tcp --sport 9997 -j ACCEPT
        sudo iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
        sudo iptables -A OUTPUT -p tcp --sport 8000 -j ACCEPT
        FW_RULE="iptables"
        echo -e "${GREEN}[+] Porta 9997 configurada com iptables.${NC}"
        echo -e "${GREEN}[+] Porta 8000 configurada com iptables.${NC}"

    elif command -v ufw &> /dev/null; then
        # Usar ufw se iptables não estiver disponível
        sudo ufw allow 9997/tcp
        sudo ufw allow out 9997/tcp
        FW_RULE="ufw"
        echo -e "${GREEN}[+] Portas 9997 e 8000 configuradas com ufw.${NC}"

    else
        echo -e "${RED}[!] Nenhum firewall (iptables ou ufw) encontrado. Configure a porta manualmente.${NC}"
        FW_RULE="Nenhum (Configure manualmente)"
    fi

    # Criar o diretório local, se não existir, e configurar o Splunk para escutar na porta 9997
    sudo mkdir -p ${SPLUNK_DIR}/etc/system/local
    sudo bash -c "cat > ${SPLUNK_DIR}/etc/system/local/inputs.conf" << EOF
[splunktcp://9997]
disabled = 0
EOF


    echo -e "${GREEN}[+] Configuração das portas 8000 e 9997 no Splunk concluída.${NC}"
}

# Função para remover Splunk
remove_splunk() {
    echo -e "${YELLOW}---------------------------------------"
    echo -e "[+] Removendo Splunk..."
    echo -e "---------------------------------------${NC}"
    sudo ${SPLUNK_DIR}/bin/splunk stop
    sudo rm -rf ${SPLUNK_DIR}
    sudo rm -rf /etc/systemd/system/Splunkd.service
    sudo rm -rf /var/log/splunk
    echo -e "${GREEN}[+] Splunk removido com sucesso.${NC}"
}

# Função para instalar Splunk
install_splunk() {
    echo -e "${YELLOW}---------------------------------------"
    echo -e "[+] Baixando o Splunk ${SPLUNK_VERSION}..."
    echo -e "---------------------------------------${NC}"
    wget -O ${SPLUNK_PACKAGE} "${SPLUNK_DOWNLOAD_URL}"

    echo -e "${YELLOW}---------------------------------------"
    echo -e "[+] Extraindo o pacote para ${SPLUNK_DIR}..."
    echo -e "---------------------------------------${NC}"
    sudo tar -xvzf ${SPLUNK_PACKAGE} -C /opt

    echo -e "${YELLOW}---------------------------------------"
    echo -e "[+] Iniciando o Splunk..."
    echo -e "---------------------------------------${NC}"
    sudo ${SPLUNK_DIR}/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd $SPLUNK_PASSWORD

    echo -e "${YELLOW}---------------------------------------"
    echo -e "[+] Configurando Splunk para iniciar no boot..."
    echo -e "---------------------------------------${NC}"
    sudo ${SPLUNK_DIR}/bin/splunk enable boot-start

    configure_port
    show_summary

    echo -e "${GREEN}---------------------------------------"
    echo -e "[+] Instalação concluída."
    echo -e "---------------------------------------${NC}"
}

# Função para exibir resumo ao final da instalação
show_summary() {
    echo -e "${CYAN}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo -e "[+] Resumo da Instalação"
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo -e "[+] Localização do Splunk: ${SPLUNK_DIR}"
    echo -e "[+] Portas liberadas: 8000 e 9997/tcp"
    echo -e "[+] Regras de firewall aplicadas: $FW_RULE"
    echo -e "[+] Interface Web: http://localhost:8000"
    echo -e "[+] Login: $SPLUNK_USER"
    echo -e "[+] Senha: $SPLUNK_PASSWORD"
    echo -e "${RED}[!] É Necessario Reiniciar o Servidor."
    echo -e "[+] Script Criado Por Lyon."
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
}

# Função principal
main() {
    display_header
    echo -e "${CYAN}Selecione uma opção:${NC}"
    echo -e "1) Instalar Splunk"
    echo -e "2) Remover Splunk"
    echo -e "3) Remover e Reinstalar Splunk"
    echo -e "4) Sair"
    read -p "Escolha uma opção: " choice

    case $choice in
        1)
            if [ -d "$SPLUNK_DIR" ]; then
                echo -e "${RED}[!] O Splunk já está instalado. Remova-o primeiro para uma nova instalação."
                echo -e "---------------------------------------${NC}"
            else
                install_splunk
            fi
            ;;
        2)
            if [ -d "$SPLUNK_DIR" ]; then
                remove_splunk
            else
                echo -e "${RED}[!] O Splunk não está instalado, nada a remover."
                echo -e "---------------------------------------${NC}"
            fi
            ;;
        3)
            if [ -d "$SPLUNK_DIR" ]; then
                remove_splunk
            fi
            install_splunk
            ;;
        4)
            echo -e "${YELLOW}[+] Saindo do script."
            echo -e "---------------------------------------${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Opção inválida. Saindo do script."
            echo -e "---------------------------------------${NC}"
            exit 1
            ;;
    esac
}

# Executa a função principal
main
