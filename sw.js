/*
 * Service worker da loja.
 *
 * Estrategia deliberadamente conservadora para e-commerce: apenas recursos
 * estaticos (CSS, JS, fontes, imagens) sao cacheados. HTML nunca e guardado,
 * porque servir uma pagina de produto do cache exibiria preco e estoque
 * desatualizados. Sem rede, o usuario recebe a pagina offline.
 *
 * Carrinho, checkout, conta e administracao passam direto para a rede,
 * sempre, sem qualquer interferencia.
 */

var VERSAO = 'v1';
var CACHE_ESTATICO = 'ocbr-estatico-' + VERSAO;
var PAGINA_OFFLINE = 'offline.html';

// Extensoes seguras para cache: mudam de nome ou raramente mudam de conteudo.
var ESTATICOS = /\.(?:css|js|woff2?|ttf|eot|otf|png|jpe?g|gif|svg|webp|ico)$/i;

// Nunca interceptar: dependem de sessao, de estoque em tempo real ou expoem
// dados do cliente.
var NUNCA_CACHEAR = [
    /\/admin\//,
    /\/api\//,
    /\/webhook\//,
    /route=checkout/,
    /route=account/,
    /route=api/,
    /route=affiliate/,
    /route=common\/cart/,
    /route=extension\/payment/,
    /route=extension\/total/
];

self.addEventListener('install', function (evento) {
    evento.waitUntil(
        caches.open(CACHE_ESTATICO).then(function (cache) {
            return cache.add(new Request(PAGINA_OFFLINE, { cache: 'reload' }));
        }).then(function () {
            return self.skipWaiting();
        })
    );
});

self.addEventListener('activate', function (evento) {
    evento.waitUntil(
        caches.keys().then(function (nomes) {
            return Promise.all(nomes.map(function (nome) {
                if (nome.indexOf('ocbr-') === 0 && nome !== CACHE_ESTATICO) {
                    return caches.delete(nome);
                }
            }));
        }).then(function () {
            return self.clients.claim();
        })
    );
});

function protegida(url) {
    return NUNCA_CACHEAR.some(function (padrao) {
        return padrao.test(url);
    });
}

self.addEventListener('fetch', function (evento) {
    var requisicao = evento.request;

    // POST, PUT e afins nunca sao tocados: adicionar ao carrinho, finalizar
    // pedido e login precisam chegar ao servidor.
    if (requisicao.method !== 'GET') {
        return;
    }

    var url = new URL(requisicao.url);

    if (url.origin !== self.location.origin) {
        return;
    }

    if (protegida(requisicao.url)) {
        return;
    }

    // Navegacao: sempre rede. Sem conexao, a pagina offline.
    if (requisicao.mode === 'navigate') {
        evento.respondWith(
            fetch(requisicao).catch(function () {
                return caches.match(PAGINA_OFFLINE);
            })
        );
        return;
    }

    // Estaticos: responde do cache e revalida em segundo plano, para que uma
    // troca de tema ou de CSS apareca na navegacao seguinte.
    if (ESTATICOS.test(url.pathname)) {
        evento.respondWith(
            caches.open(CACHE_ESTATICO).then(function (cache) {
                return cache.match(requisicao).then(function (cacheado) {
                    var rede = fetch(requisicao).then(function (resposta) {
                        if (resposta && resposta.status === 200) {
                            cache.put(requisicao, resposta.clone());
                        }

                        return resposta;
                    }).catch(function () {
                        return cacheado;
                    });

                    return cacheado || rede;
                });
            })
        );
    }
});
