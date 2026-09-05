/*
 * Registro do service worker.
 *
 * O caminho sai do <base href> da pagina, e nao da raiz do dominio, para
 * funcionar tambem quando a loja esta instalada num subdiretorio.
 *
 * Navegadores so registram service workers em contexto seguro: HTTPS, ou
 * localhost em desenvolvimento. Em HTTP puro o registro falha e a loja segue
 * funcionando normalmente, apenas sem os recursos de PWA.
 */
(function () {
    if (!('serviceWorker' in navigator)) {
        return;
    }

    window.addEventListener('load', function () {
        var base = document.baseURI || (location.origin + '/');

        navigator.serviceWorker.register(new URL('sw.js', base).href, {
            scope: new URL('./', base).href
        })['catch'](function (erro) {
            console.warn('Service worker não registrado:', erro.message);
        });
    });
})();
