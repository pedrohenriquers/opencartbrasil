#!/usr/bin/env bash

cli_arguments=(
  "${DB_HOSTNAME:-0}"
  "${DB_PASSWORD:-0}"
  "${HTTP_SERVER:-0}"
)

is_valid=1

for cli_arg in ${cli_arguments[@]}; do
  if [ $cli_arg = 0 ]; then
    is_valid=0
  fi
done

if [ $is_valid = 1 ]; then
  if [ ! -f config.php ] || [ ! -s config.php ]; then
      until nc -z -w30 $DB_HOSTNAME ${DB_PORT:-3306}; do
          echo "Aguardando inicialização do banco de dados"
          sleep 5
      done

      password_default=$(cat /dev/urandom | tr -cd A-Za-z0-9 | head -c 10)

      cli_arguments=(
          --db_driver "pdo" \
          --db_hostname "${DB_HOSTNAME}" \
          --db_username "${DB_USERNAME:-root}" \
          --db_password "${DB_PASSWORD}" \
          --db_database "${DB_DATABASE:-opencartbrasil}" \
          --db_port "${DB_PORT:-3306}" \
          --db_prefix "${DB_PREFIX:-ocbr_}" \
          --username "${USERNAME:-admin}" \
          --password "${PASSWORD:-$password_default}" \
          --email "${EMAIL:-web@master}" \
          --http_server "${HTTP_SERVER%/}/"
      )

      php install/cli_install.php install ${cli_arguments[@]};

      if [ -z $PASSWORD ]; then
          echo -e "\nCredenciais de acesso"
          echo "Usuário: ${USERNAME:-'admin'}"
          echo "Senha: ${PASSWORD:-$password_default}"
          echo -e "Após logar, troque os dados para sua segurança\n\n\n"
      fi
  fi
fi

# O instalador grava a URL da loja fixa no config.php. Como config.php e
# admin/config.php sao ignorados pelo git, esse valor nao acompanha o
# repositorio: cada maquina precisa do seu. Em vez de fixar um host, os
# arquivos passam a derivar a URL do host da requisicao, o que evita erro de
# CORS ao acessar por IP, hostname ou dominio sem tocar em nenhum arquivo.
ocbr_make_config_dynamic() {
  local file="$1" admin_suffix="$2"

  [ -f "$file" ] || return 0
  grep -q 'ocbr_base' "$file" && return 0   # ja convertido

  sed -i "1a\\
\\
// STORE_URL fixa o endereco canonico da loja e tem precedencia sobre tudo.\\
// Em producao ela deve estar definida: sem isso a URL sai do cabecalho Host,\\
// que o cliente controla, e um Host forjado faria a loja gerar links para o\\
// dominio do atacante (explorado em e-mails de recuperacao de senha).\\
// Sem STORE_URL o comportamento e o de desenvolvimento: a loja responde por\\
// qualquer nome (IP, hostname) sem reconfiguracao. Em CLI nao existe\\
// HTTP_HOST: cai para HTTP_SERVER e, por ultimo, o hostname da maquina.\\
\$ocbr_store_url = getenv('STORE_URL');\\
\\
if (\$ocbr_store_url) {\\
    \$ocbr_base = rtrim(\$ocbr_store_url, '/') . '/';\\
} elseif (isset(\$_SERVER['HTTP_HOST'])) {\\
    \$ocbr_base = 'http://' . \$_SERVER['HTTP_HOST'] . '/';\\
} else {\\
    \$ocbr_base = getenv('HTTP_SERVER') ?: 'http://' . gethostname() . '/';\\
}" "$file"

  local server_expr="\$ocbr_base"
  [ -n "$admin_suffix" ] && server_expr="\$ocbr_base . '${admin_suffix}'"

  sed -i \
    -e "s#^define('HTTP_SERVER', '.*');#define('HTTP_SERVER', ${server_expr});#" \
    -e "s#^define('HTTPS_SERVER', '.*');#define('HTTPS_SERVER', ${server_expr});#" \
    -e "s#^define('HTTP_CATALOG', '.*');#define('HTTP_CATALOG', \$ocbr_base);#" \
    -e "s#^define('HTTPS_CATALOG', '.*');#define('HTTPS_CATALOG', \$ocbr_base);#" \
    "$file"

  echo "URL dinamica aplicada em ${file}"
}

ocbr_make_config_dynamic /var/www/html/config.php ""
ocbr_make_config_dynamic /var/www/html/admin/config.php "admin/"

folders=(
  "/var/www/html/image/cache/"
  "/var/www/html/image/catalog/"
  "/var/www/html/system/storage/cache/"
  "/var/www/html/system/storage/logs/"
  "/var/www/html/system/storage/download/"
  "/var/www/html/system/storage/upload/"
  "/var/www/html/system/storage/session/"
  "/var/www/html/system/storage/modification/"
)

for folder in ${folders[@]}; do
  if [ ! -d "$folder" ]; then
    mkdir -p "$folder"
    chown -R www-data:www-data "$folder"
  fi
done

files=(
  "/var/www/html/config.php"
  "/var/www/html/admin/config.php"
)

for f in ${files[@]}; do
  if [ ! -d "$f" ]; then
    touch "$f"
    chown www-data:www-data "$f"
  fi
done

if [ ! -f composer.lock ]; then
  composer install
fi

exec "$@"