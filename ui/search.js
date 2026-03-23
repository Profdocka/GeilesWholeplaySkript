/**
 * search.js – Suchleisten-Logik für das Geile Wholeplay Menü.
 * Filtert Entity-Blöcke anhand der Texteingabe.
 */

/**
 * Initialisiert die Suchleiste: bindet den Input-Handler und die
 * Tastenkürzel (F = Fokus, ESC = Menü schließen).
 * @param {Function} closeMenuFn  Referenz auf closeGWMenu
 */
export function initSearch(closeMenuFn) {
    const searchbar = document.getElementById('search-bar');

    // Filterlogik bei Eingabe
    searchbar.addEventListener('input', e => {
        const input = e.target.value.toUpperCase();
        const panels = document.getElementsByClassName('entity');

        for (let i = 0; i < panels.length; i++) {
            const divs = panels[i].getElementsByTagName('div');
            if (!divs.length) { panels[i].style.display = 'none'; continue; }

            const firstText = divs[0].firstChild;
            const firstVal = (firstText?.textContent || firstText?.innerText || '').toUpperCase();

            if (firstVal.indexOf(input) > -1) {
                panels[i].style.display = '';
                continue;
            }

            const lastText = divs[0].lastChild;
            const lastVal = (lastText?.textContent || lastText?.innerText || '').toUpperCase();

            panels[i].style.display = lastVal.indexOf(input) > -1 ? '' : 'none';
        }
    });

    // Tastenkürzel
    document.addEventListener('keydown', event => {
        if (event.key === 'Escape') {
            closeMenuFn();
        } else if (event.key === 'f' && document.activeElement !== searchbar) {
            event.preventDefault();
            searchbar.focus();
        }
    });
}
