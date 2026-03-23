/**
 * overlay.js – Generisches Overlay-System für Submenüs.
 * Zeigt ein Pop-up über dem Hauptinhalt an und kann von
 * verschiedenen Submenüs (Optionen, Drivers) wiederverwendet werden.
 */

let _isOverlayOpen = false;

/**
 * Öffnet ein Overlay und ruft die übergebene Render-Funktion auf,
 * die den Inhalt in den Overlay-Content-Container schreibt.
 * @param {Function} contentRenderFn  Funktion(containerElement), die den Overlay-Inhalt erzeugt
 */
export function openOverlay(contentRenderFn) {
    const overlay = document.getElementById('overlay-container');
    const content = document.getElementById('overlay-content');
    if (!overlay || !content) return;

    content.innerHTML = '';
    contentRenderFn(content);

    overlay.style.display = 'flex';
    _isOverlayOpen = true;
}

/**
 * Schließt das Overlay und leert den Inhalt.
 */
export function closeOverlay() {
    const overlay = document.getElementById('overlay-container');
    if (overlay) overlay.style.display = 'none';

    const content = document.getElementById('overlay-content');
    if (content) content.innerHTML = '';

    _isOverlayOpen = false;
}

/** @returns {boolean} */
export function isOverlayOpen() { return _isOverlayOpen; }

/**
 * Initialisiert den Schließen-Button des Overlays.
 */
export function initOverlay() {
    const closeBtn = document.getElementById('overlay-close');
    if (closeBtn) {
        closeBtn.addEventListener('click', e => {
            e.stopPropagation();
            closeOverlay();
        });
    }
}
