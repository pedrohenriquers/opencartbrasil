#!/bin/bash

# Interrompe o script imediatamente se algum comando falhar de forma inesperada
set -e

echo "========================================================="
echo "   SCRIPT BLINDADO: INSTALAÇÃO INTELIGENTE OPENCART V3   "
echo "========================================================="
echo ""

# Usuário fixo do GitHub
GIT_USER="pedrohenriquers"

# Solicitar o Token de forma segura no terminal
read -s -p "Digite ou cole o seu Token do GitHub (Fine-grained PAT): " GIT_TOKEN
echo ""
echo ""

# Solicitar dados do banco de dados (Necessário em toda execução)
read -p "Digite o nome do Banco de Dados (ex: opencart_prod): " DB_NAME
read -p "Digite o usuário do Banco de Dados (ex: user_prod): " DB_USER
read -s -p "Digite a senha para este usuário do Banco: " DB_PASS
echo ""
echo ""

# Monta a URL autenticada dinamicamente com o token informado
GIT_REPO="https://${GIT_USER}:${GIT_TOKEN}@github.com/pedrohenriquers/opencartbrasil.git"

# ---------------------------------------------------------------------
echo "[1/5] Validando atualizações e dependências do sistema..."
if ! command -v curl &> /dev/null || ! command -v unzip &> /dev/null || ! command -v git &> /dev/null || ! command -v sshd &> /dev/null; then
    echo "-> Instalando dependências básicas (Git, SSH, etc)..."
    apt update && apt upgrade -y
    apt install software-properties-common curl unzip git openssh-server python3 python3-pip python3-venv -y
else
    echo "-> Dependências básicas já estão presentes. Pulando."
fi

# Adicionar repositório do PHP se necessário
if [ -f /etc/lsb-release ]; then
    if ! grep -q "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
        echo "-> Adicionando repositório PHP Ondrej..."
        add-apt-repository ppa:ondrej/php -y
        apt update
    else
        echo "-> Repositório PHP já configurado. Pulando."
    fi
fi

# ---------------------------------------------------------------------
echo "[2/5] Validando servidor Web Apache, MariaDB e PHP 7.4..."
if ! command -v apache2 &> /dev/null || ! command -v mysql &> /dev/null || ! command -v php7.4 &> /dev/null; then
    echo "-> Instalando Apache, MariaDB e PHP 7.4 com extensões..."
    apt install apache2 mariadb-server php7.4 libapache2-mod-php7.4 php7.4-mysql php7.4-curl php7.4-xml php7.4-zip php7.4-gd php7.4-cli php7.4-mbstring -y
else
    echo "-> Servidores e PHP 7.4 já estão instalados. Pulando."
fi

# ---------------------------------------------------------------------
echo "[3/5] Validando configuração do Banco de Dados MariaDB..."
systemctl start mariadb

# Verificar se o banco de dados já existe
DB_EXISTS=$(mysql -e "SHOW DATABASES LIKE '${DB_NAME}';" | grep "${DB_NAME}" || true)

if [ -z "$DB_EXISTS" ]; then
    echo "-> Criando banco de dados, usuário e aplicando permissões..."
    mysql -e "CREATE DATABASE ${DB_NAME};"
    mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
    mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
else
    echo "-> O Banco de Dados '${DB_NAME}' já existe. Nenhuma alteração foi feita no banco."
fi

# ---------------------------------------------------------------------
echo "[4/5] Validando arquivos do OpenCart via GIT Autenticado..."

# Define o diretório web e garante que ele existe
TARGET_DIR="/var/www/html"
mkdir -p "$TARGET_DIR"

# Adiciona preventivamente a pasta à lista de diretórios seguros do Git para evitar o erro "dubious ownership"
git config --global --add safe.directory "$TARGET_DIR" || true

# Se a pasta já tiver um repositório git inicializado, atualiza o código
if [ -d "$TARGET_DIR/.git" ]; then
    echo "-> Repositório já existente. Atualizando URL remota com credenciais e buscando atualizações..."
    cd "$TARGET_DIR"
    
    # Atualiza a URL do remote com o token para garantir permissão de push/pull futuro
    git remote set-url origin "$GIT_REPO"
    
    # Configura o git temporariamente para evitar travar se houver arquivos alterados localmente
    git config user.email "deploy@local.com"
    git config user.name "Deploy Script"
    
    # Traz as atualizações mantendo as edições locais de config.php protegidas
    git stash || true
    git pull origin main || git pull origin master
    git stash pop || true
else
    echo "-> Clonando código atualizado utilizando credenciais fornecidas..."
    # Limpa arquivos antigos para evitar conflitos no clone, preservando se houver algum config antigo temporariamente
    [ -f "$TARGET_DIR/config.php" ] && cp "$TARGET_DIR/config.php" /tmp/config_backup.php || true
    [ -f "$TARGET_DIR/admin/config.php" ] && cp "$TARGET_DIR/admin/config.php" /tmp/admin_config_backup.php || true
    
    rm -rf "$TARGET_DIR"/*
    rm -rf "$TARGET_DIR"/.* 2>/dev/null || true
    
    # Clona o repositório diretamente na pasta do Apache usando a URL com o Token informado
    git clone "$GIT_REPO" "$TARGET_DIR"
    
    # Entra na pasta e força a URL remota a persistir com as credenciais salvas para push manuais posteriores
    cd "$TARGET_DIR"
    git remote set-url origin "$GIT_REPO"
    
    # Restaura os configs se eles existiam antes do clone limpo
    [ -f /tmp/config_backup.php ] && mv /tmp/config_backup.php "$TARGET_DIR/config.php" || true
    [ -f /tmp/admin_config_backup.php ] && mv /tmp/admin_config_backup.php "$TARGET_DIR/admin/config.php" || true
fi

# Garante a existência dos arquivos de configuração caso seja a primeira instalação
cd "$TARGET_DIR"
[ ! -f config.php ] && [ -f config-dist.php ] && cp config-dist.php config.php || true
[ ! -f admin/config.php ] && [ -f admin/config-dist.php ] && cp admin/config-dist.php admin/config.php || true

# ---------------------------------------------------------------------
echo "[4.1/5] RESOLVENDO DEPENDÊNCIAS PHP (Isolado e Forçado)..."
cd /var/www/html

# Baixa o instalador local para evitar conflito de versão do PHP do sistema com o Composer global
curl -sS https://getcomposer.org/installer | php -- --quiet

# Libera explicitamente os plugins no Composer para evitar o bloqueio de segurança "allow-plugins"
echo "-> Configurando permissões de plugins do Composer..."
php composer.phar config allow-plugins.composer/installers true || true
php composer.phar config allow-plugins true --global --quiet || true

# Executa o install liberando explicitamente os plugins para rodarem como superusuário,
# aplicando as flags corretas de bypass de auditoria, bloqueio e interatividade.
echo "-> Rodando composer install com flags de bypass e permissão superuser..."
COMPOSER_ALLOW_SUPERUSER=1 php composer.phar install --ignore-platform-reqs --no-blocking --no-intera
ction --quiet || COMPOSER_ALLOW_SUPERUSER=1 php composer.phar install --ignore-platform-reqs --no-interaction --quiet || tru

# Remove o instalador temporário
rm -f composer.phar

# ---------------------------------------------------------------------
echo "[4.5/5] Liberando acesso SSH para o usuário root com senha..."
if [ -f /etc/ssh/sshd_config ]; then
    # 1. Garante a configuração de PermitRootLogin
    if grep -q "^#\?PermitRootLogin" /etc/ssh/sshd_config; then
        sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
    else
        echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    fi
    
    # 2. Garante a configuração de PasswordAuthentication (modifica ou cria abaixo de PermitRootLogin)
    if grep -q "^#\?PasswordAuthentication" /etc/ssh/sshd_config; then
        sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
    else
        # Injeta a linha exatamente abaixo de PermitRootLogin para manter o arquivo organizado
        sed -i '/PermitRootLogin yes/a PasswordAuthentication yes' /etc/ssh/sshd_config
    fi
    
    # Reinicia o serviço de SSH para aplicar as novas regras
    systemctl restart ssh || systemctl restart sshd
    echo "-> Acesso SSH para root liberado com sucesso."
else
    echo "-> [AVISO] Arquivo sshd_config não encontrado. O SSH pode não estar ativo."
fi

# ---------------------------------------------------------------------
echo "[5/5] Aplicando permissions de segurança nos diretórios..."
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/
echo "-> Permissões atualizadas com sucesso."

# Limpa as variáveis confidenciais da memória por segurança após o término do deploy
unset GIT_TOKEN
unset GIT_REPO

# Pegar o IP interno do container para exibir na tela
IP_ATUAL=$(hostname -I | awk '{print $1}')

echo ""
echo "========================================================="
echo " PROCESSO CONCLUÍDO!                                     "
echo "========================================================="
echo "Acesse no seu navegador:"
echo "👉 http://${IP_ATUAL}"
echo ""
echo "Acesso SSH disponível:"
echo "• Comando: ssh root@${IP_ATUAL}"
echo "========================================================="
echo "Dados para o assistente web (caso esteja instalando agora):"
echo "• Database Host: localhost"
echo "• Database Name: ${DB_NAME}"
echo "• Database User: ${DB_USER}"
echo "• Database Password: [A senha que você digitou]"
echo "========================================================="
