# Splunk Manager Script & Universal Forwarder Setup

## Visão Geral

Este repositório contém dois scripts distintos para facilitar a instalação e configuração do Splunk e do Splunk Universal Forwarder (UF).

1. **Splunk Manager Script**: Automate a instalação e remoção do Splunk no Linux.
2. **Splunk Universal Forwarder & Sysmon Setup**: Automatiza a instalação do Splunk Universal Forwarder e Sysmon no Windows.

Os scripts foram criados por **Ailton Rocha (ailton.rocha@telefonica.com)**, com foco em simplificar a gestão do Splunk em diferentes plataformas.

## Splunk Manager Script (Linux)

Este script facilita a instalação e remoção do Splunk no Linux. Ele também configura as portas necessárias e permite a instalação automática de forma simples e interativa.

### Funcionalidades

- **Instalar Splunk**: Faz o download da versão especificada, instala, e aplica as configurações necessárias.
- **Configuração das Portas (8000, 9997)**: Configura o firewall usando `iptables` ou `ufw`.
- **Remover Splunk**: Remove completamente o Splunk do sistema.
- **Resumo da Instalação**: Exibe informações útis ao final do processo de instalação.

### Utilização

1. Clone o repositório para o sistema Linux:
   ```bash
   git clone https://github.com/seu-usuario/splunk-manager.git
   cd splunk-manager
   chmod +x splunk_manager.sh
   ./splunk_manager.sh
   ```

2. **Menu de Opções**:
   - **1**: Instalar Splunk.
   - **2**: Remover Splunk.
   - **3**: Remover e reinstalar Splunk.
   - **4**: Sair.

3. **Exemplo de Execução**:
   
   ```
   [+] Configurando as portas 8000 e 9997...
   [+] Porta 9997 configurada com iptables.
   [+] Porta 8000 configurada com iptables.
   [!] É Necessário Reiniciar o Servidor.
   ```

### Observação Importante

- Certifique-se de atualizar a variável `SPLUNK_PASSWORD` com uma senha segura.
- Esse script requer permissões de superusuário (root).

## Splunk Universal Forwarder & Sysmon Setup (Windows)

Este script automatiza a configuração do Splunk Universal Forwarder (UF) e do Sysmon no Windows.

### Funcionalidades

- **Instalar Splunk UF**: Instala e configura o Splunk Universal Forwarder.
- **Instalar Sysmon**: Instala o Sysmon com a configuração do Sysvol.
- **Aplicar Configurações Customizadas**: Define configurações específicas do Splunk, como `inputs.conf` e `outputs.conf`.
- **Menu Interativo**: Permite realizar instalação, configuração, remoção e atualização do UF e Sysmon de maneira interativa.

### Utilização

1. Baixe o script e ajuste as variáveis de caminho (SMB Share):
   - `$NetworkSharePath`: Deve apontar para o caminho correto do compartilhamento de rede SMB que contém os instaladores do Splunk UF e Sysmon.

2. **Executar o Script**:
   - Abra o **PowerShell** como administrador.
   - Navegue até o diretório onde o script está localizado.
   - Execute o script:
     ```powershell
     .\splunk_uf_sysmon_setup.ps1
     ```

3. **Menu de Opções**:
   - **1**: Instalar e configurar o Splunk UF.
   - **2**: Instalar e configurar Sysmon.
   - **3**: Instalar Splunk UF e Sysmon juntos.
   - **4**: Atualizar a configuração do Sysmon.
   - **5-8**: Opções de remoção do Splunk UF e Sysmon.
   - **9**: Sair do script.

4. **Exemplo de Execução**:
   
   ```
   [+] Instalando e Configurando Splunk Universal Forwarder...
   [+] Configuração Concluída. Reiniciando o Splunk.
   ```

### Observações Importantes

- Certifique-se de que o compartilhamento de rede esteja acessível e os arquivos corretos estejam presentes.
- O script instala o Sysmon e aplica configurações a partir do caminho SMB especificado.
- Para remover os aplicativos, utilize as opções apropriadas do menu.

## Contribuições

- **Reportar Problemas**: Caso encontre problemas, crie uma **issue** no repositório.
- **Solicitações de Melhorias**: Pull requests são bem-vindos!

## Autor

**Ailton Rocha**  
*Threat Hunting Specialist*  
E-mail: ailton.rocha@telefonica.com

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

---

Sinta-se à vontade para usar e adaptar os scripts conforme suas necessidades. Espero que esses scripts simplifiquem seu processo de instalação e configuração do Splunk!
