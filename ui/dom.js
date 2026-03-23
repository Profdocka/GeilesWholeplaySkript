/**
 * dom.js – DOM-Erstellung für Entity-Blöcke, aktive Blöcke, Sektions-Trenner
 * und Variant-Buttons. Alle Funktionen erzeugen DOM-Elemente und hängen sie
 * an ein übergebenes Eltern-Element an.
 */

import {
    VEHICLE_VARIANT, PLAYER_VARIANT, NEUTRAL_VARIANT,
    FRIENDLY_VARIANT, AGGRESSIVE_VARIANT,
    GROUP_VARIANT, LOCATION_VARIANT, DIORAMA_VARIANT,
    memory
} from './constants.js';
import { fetchNUI } from './api.js';
import { addClickEventHandler } from './utils.js';

/** Wird durch menu.js zur Laufzeit gesetzt, um zirkuläre Imports zu vermeiden. */
let _closeMenuFn = null;

/**
 * Registriert die closeGWMenu-Funktion, damit DOM-Click-Handler sie aufrufen können.
 * @param {Function} fn
 */
export function setCloseMenuFn(fn) { _closeMenuFn = fn; }

/**
 * Färbt einen Block entsprechend seiner Variant-Kategorie ein.
 * @param {HTMLElement} block
 * @param {number}      variant
 */
export function colorBlocksAccordingly(block, variant) {
    switch (variant) {
        case VEHICLE_VARIANT: block.classList.add('entity-vehicle'); break;
        case GROUP_VARIANT: block.classList.add('entity-group'); break;
        case LOCATION_VARIANT: block.classList.add('entity-location'); break;
        case DIORAMA_VARIANT: block.classList.add('entity-diorama'); break;
        default: break;
    }
}

/**
 * Erzeugt eine Zeile mit drei Gesinnungs-Buttons (neutral / freundlich / aggressiv).
 * @param {string} gameEvent  NUI-Callback-Name
 * @param {string} name       Entity-Name
 * @returns {HTMLDivElement}
 */
export function variantButtonRow(gameEvent, name) {
    const row = document.createElement('div');
    row.classList.add('variants');

    const defs = [
        { text: 'sentiment_neutral', variant: NEUTRAL_VARIANT, css: 'variant-neutral' },
        { text: 'sentiment_excited', variant: FRIENDLY_VARIANT, css: 'variant-friendly' },
        { text: 'sentiment_extremely_dissatisfied', variant: AGGRESSIVE_VARIANT, css: 'variant-aggressive' },
    ];

    for (const def of defs) {
        const btn = document.createElement('div');
        btn.textContent = def.text;
        btn.classList.add('material-symbols-outlined', def.css);
        addClickEventHandler(btn, gameEvent, { name, variant: def.variant }, _closeMenuFn);
        row.append(btn);
    }

    return row;
}

/**
 * Erzeugt eine visuelle Sektions-Trennlinie mit Text.
 * @param {HTMLElement} parentElement
 * @param {string}      sectionText
 */
export function createSectionLine(parentElement, sectionText) {
    const section = document.createElement('div');
    section.classList.add('custom-hr');

    const text = document.createElement('div');
    text.textContent = sectionText;

    section.append(text);
    parentElement.append(section);
}

/**
 * Erzeugt einen klickbaren Entity-Block (Charakter, Fahrzeug, Fraktion, Location, Diorama).
 * @param {HTMLElement} parentElement  Eltern-Container
 * @param {string}      name           Anzeigename
 * @param {number}      variant        Variant-Konstante
 * @param {string}      gameEvent      NUI-Callback-Name
 */
export function addBlock(parentElement, name, variant, gameEvent) {
    const block = document.createElement('div');
    const textBlock = document.createElement('div');
    const title = document.createElement('span');

    block.classList.add('entity');
    colorBlocksAccordingly(block, variant);

    // Click-Handler je nach Variant
    if (variant === PLAYER_VARIANT || variant === VEHICLE_VARIANT) {
        block.addEventListener('click', () => {
            _closeMenuFn?.();
            fetchNUI(gameEvent, { name, variant });
        });
    } else if (variant === LOCATION_VARIANT || variant === DIORAMA_VARIANT) {
        block.addEventListener('click', () => {
            _closeMenuFn?.();
            fetchNUI(gameEvent, { name });
        });
    }

    title.textContent = name;

    // Interior-Icon bei Locations
    if (variant === LOCATION_VARIANT && memory.locationsObjects?.[name]?.isInterior) {
        const logospace = document.createElement('div');
        logospace.classList.add('material-icons');
        logospace.style.color = 'white';
        logospace.textContent = 'home';
        block.append(logospace);
    }

    textBlock.append(title);
    block.append(textBlock);

    // Gesinnungs-Buttons bei Charakteren und Gruppen
    if (variant === PLAYER_VARIANT || variant === GROUP_VARIANT) {
        block.append(variantButtonRow(gameEvent, name));
    }

    parentElement.appendChild(block);
}

/**
 * Erzeugt einen Block für einen aktiven Entity (Spieler, NPC, Fahrzeug) im Aktiv-Bereich.
 * @param {HTMLElement} parentElement
 * @param {object}      options  { variant, networkID, name, faction?, playerName?, gameEvent }
 */
export function addActiveBlock(parentElement, options) {
    const block = document.createElement('div');
    const textBlock = document.createElement('div');
    const title = document.createElement('span');

    block.classList.add('entity');
    colorBlocksAccordingly(block, options.variant);

    if (options.variant === VEHICLE_VARIANT || options.variant === NEUTRAL_VARIANT) {
        addClickEventHandler(block, options.gameEvent, options, _closeMenuFn);
    }

    textBlock.classList.add('active-info-text');
    title.textContent = options.name;
    textBlock.append(title);

    let optionsButtons = document.createElement('div');

    if (options.variant === PLAYER_VARIANT || options.variant === NEUTRAL_VARIANT) {
        const subtitle = document.createElement('span');
        subtitle.textContent = 'Fraktion: ' + options.faction;
        subtitle.classList.add('active-info-text-faction');
        textBlock.append(subtitle);

        if (options.variant === PLAYER_VARIANT) {
            const footer = document.createElement('span');
            footer.textContent = options.playerName;
            footer.classList.add('active-info-text', 'active-info-text-player-name');
            textBlock.append(footer);
        } else {
            optionsButtons = variantButtonRow('UI_ChangeAttitude', options.name);
        }
    }

    if (options.variant === VEHICLE_VARIANT || options.variant === NEUTRAL_VARIANT) {
        const trashCanButton = document.createElement('div');
        trashCanButton.textContent = 'delete';
        addClickEventHandler(trashCanButton, 'UI_DeleteEntity', options, _closeMenuFn);
        trashCanButton.classList.add('material-symbols-outlined', 'variant-aggressive');
        optionsButtons.append(trashCanButton);
        optionsButtons.classList.add('variants');
    }

    block.append(textBlock);
    block.append(optionsButtons);
    parentElement.appendChild(block);
}
