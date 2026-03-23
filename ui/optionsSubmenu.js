/**
 * optionsSubmenu.js – Overlay-Inhalt für die Spieler-Optionen.
 * Zeigt Toggle-Buttons für clientseitige Einstellungen an:
 * Unbesiegbar, Formation, Blips.
 *
 * Lauscht auf GW_OptionsSync-Nachrichten, um den State zu aktualisieren,
 * wenn Optionen per Befehl oder Server-Event geändert werden.
 */

import { fetchNUI } from './api.js';

/** Lokaler State-Cache für die Toggle-Anzeige */
const optionState = {
    unbesiegbar: true,
    formation: true,
    blips: true,
};

/** Referenzen auf die Toggle-Buttons für externe Updates */
const toggleButtons = {};

/**
 * Erzeugt einen einzelnen Toggle-Button.
 * @param {HTMLElement} container
 * @param {string}      label       Anzeigename
 * @param {string}      optionKey   Schlüssel für den NUI-Callback
 */
function createToggleButton(container, label, optionKey) {
    const row = document.createElement('div');
    row.classList.add('overlay-option-row');

    const nameSpan = document.createElement('span');
    nameSpan.textContent = label;
    nameSpan.classList.add('overlay-option-label');

    const toggleBtn = document.createElement('button');
    toggleBtn.classList.add('overlay-toggle-btn');
    updateToggleVisual(toggleBtn, optionState[optionKey]);

    toggleBtn.addEventListener('click', async () => {
        const result = await fetchNUI('UI_SetOption', { option: optionKey });
        if (result && result.newState !== undefined) {
            optionState[optionKey] = result.newState;
        } else {
            // Fallback: lokal toggeln
            optionState[optionKey] = !optionState[optionKey];
        }
        updateToggleVisual(toggleBtn, optionState[optionKey]);
    });

    // Referenz speichern für externe Updates
    toggleButtons[optionKey] = toggleBtn;

    row.append(nameSpan, toggleBtn);
    container.append(row);
}

/**
 * Aktualisiert die visuelle Darstellung eines Toggle-Buttons.
 * @param {HTMLButtonElement} btn
 * @param {boolean}           isOn
 */
function updateToggleVisual(btn, isOn) {
    btn.textContent = isOn ? 'AN' : 'AUS';
    btn.classList.toggle('toggle-on', isOn);
    btn.classList.toggle('toggle-off', !isOn);
}

/**
 * Rendert den Optionen-Overlay-Inhalt in den übergebenen Container.
 * @param {HTMLElement} container
 */
export function renderOptionsOverlay(container) {
    const header = document.createElement('h2');
    header.textContent = 'Optionen';
    header.classList.add('overlay-section-title');
    container.append(header);

    createToggleButton(container, 'Unbesiegbar', 'unbesiegbar');
    createToggleButton(container, 'Formation-Spawn', 'formation');
    createToggleButton(container, 'Blips anzeigen', 'blips');
}

/**
 * Aktualisiert den Options-State von außen (z.B. per Befehl oder Server-Event).
 * Wird über GW_OptionsSync-Nachrichten aufgerufen.
 * @param {object} state  { unbesiegbar?: boolean, formation?: boolean, blips?: boolean }
 */
export function syncOptionsState(state) {
    for (const [key, value] of Object.entries(state)) {
        if (key in optionState) {
            optionState[key] = value;
            if (toggleButtons[key]) {
                updateToggleVisual(toggleButtons[key], value);
            }
        }
    }
}
