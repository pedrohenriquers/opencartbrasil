<?php
// Manifesto do PWA. Servido por PHP, e nao como arquivo estatico, para que o
// nome e a cor venham da propria loja: assim a mesma base de codigo atende
// varias lojas sem que cada uma precise editar (e versionar) um manifest.json.

require __DIR__ . '/config.php';

$nome = 'Loja';
$cor = '#229ac8';

try {
    $pdo = new PDO(
        'mysql:host=' . DB_HOSTNAME . ';port=' . DB_PORT . ';dbname=' . DB_DATABASE . ';charset=utf8',
        DB_USERNAME,
        DB_PASSWORD,
        array(PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION)
    );

    $consulta = $pdo->prepare(
        'SELECT `value` FROM `' . DB_PREFIX . 'setting` WHERE store_id = 0 AND `key` = ? LIMIT 1'
    );
    $consulta->execute(array('config_name'));
    $valor = $consulta->fetchColumn();

    if ($valor) {
        $nome = $valor;
    }
} catch (Exception $e) {
    // Sem banco o manifesto ainda deve ser servido, com o nome padrao.
}

// A loja pode estar num subdiretorio; o escopo acompanha o caminho da
// instalacao em vez de assumir a raiz do dominio.
$caminho = parse_url(HTTP_SERVER, PHP_URL_PATH);

if (!$caminho) {
    $caminho = '/';
}

$manifesto = array(
    'name' => $nome,
    'short_name' => mb_substr($nome, 0, 12),
    'description' => $nome . ' - loja online',
    'lang' => 'pt-BR',
    'dir' => 'ltr',
    'start_url' => $caminho,
    'scope' => $caminho,
    'display' => 'standalone',
    'orientation' => 'portrait-primary',
    'background_color' => '#ffffff',
    'theme_color' => $cor,
    'icons' => array(
        array(
            'src' => $caminho . 'image/pwa/icon-192.png',
            'sizes' => '192x192',
            'type' => 'image/png',
            'purpose' => 'any',
        ),
        array(
            'src' => $caminho . 'image/pwa/icon-512.png',
            'sizes' => '512x512',
            'type' => 'image/png',
            'purpose' => 'any',
        ),
        array(
            'src' => $caminho . 'image/pwa/icon-maskable-512.png',
            'sizes' => '512x512',
            'type' => 'image/png',
            'purpose' => 'maskable',
        ),
    ),
);

header('Content-Type: application/manifest+json; charset=utf-8');
header('Cache-Control: public, max-age=3600');

echo json_encode($manifesto, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
