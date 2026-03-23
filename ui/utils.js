/**
 * utils.js – Kleine Hilfsfunktionen, die von mehreren Modulen verwendet werden.
 */

import { fetchNUI } from './api.js';

/**
 * Sortiert die Schlüssel eines Objekts alphabetisch und gibt
 * ein Array von [key, value]-Paaren zurück.
 * @param {object} obj
 * @returns {Array<[string, any]>}
 */
export function sortObjectKeysAlphabetically(obj) {
    return Object.entries(obj).sort(([a], [b]) => a.localeCompare(b));
}

/**
 * Ersetzt fehlende oder undefined Network-IDs durch 0.
 * @param {number|null|undefined} networkID
 * @returns {number}
 */
export function networkIDWasNotFoundReplace(networkID) {
    return (networkID == null || networkID === undefined) ? 0 : networkID;
}

/**
 * Fügt einem DOM-Element einen Click-Handler hinzu, der das Menü schließt
 * und einen NUI-Callback auslöst.
 * @param {HTMLElement} element       Ziel-Element
 * @param {string}      nuiEventName  NUI-Callback-Name
 * @param {object}      data          Daten für den NUI-Callback
 * @param {Function}    closeMenuFn   Referenz auf closeGWMenu (vermeidet zirkuläre Imports)
 */
export function addClickEventHandler(element, nuiEventName, data, closeMenuFn) {
    element.addEventListener('click', e => {
        e.stopPropagation();
        if (closeMenuFn) closeMenuFn();
        fetchNUI(nuiEventName, data);
    });
}
