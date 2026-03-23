/**
 * tabs.js – Tab-Wechsel und Sektions-Rendering für die Sidebar.
 * Konsolidiert die vormals doppelte Rendering-Logik (addEveryEntity + optionsContainerButtonHandler)
 * in eine generische renderSection()-Funktion.
 */

import {
    VEHICLE_VARIANT, PLAYER_VARIANT, NEUTRAL_VARIANT,
    GROUP_VARIANT, LOCATION_VARIANT, DIORAMA_VARIANT,
    memory, getPlayerName
} from './constants.js';
import { addBlock, addActiveBlock, createSectionLine } from './dom.js';
import { networkIDWasNotFoundReplace } from './utils.js';
import { openOverlay } from './overlay.js';
import { renderOptionsOverlay } from './optionsSubmenu.js';
import { renderDriversOverlay } from './driversSubmenu.js';

/**
 * Rendert den "Aktive"-Bereich: aktive Spieler, Charaktere und Fahrzeuge.
 * @param {HTMLElement} container
 */
export function addActiveSection(container) {
    createSectionLine(container, 'Aktive');

    memory.players.forEach(player => {
        if (player != null) {
            player.networkID = networkIDWasNotFoundReplace(player.networkID);
            addActiveBlock(container, {
                variant: PLAYER_VARIANT,
                networkID: player.networkID,
                name: player.skin,
                faction: player.faction,
                playerName: player.playerName,
                gameEvent: 'UI_TeleportToPlayer'
            });
        }
    });

    memory.Acharacters.forEach(character => {
        if (character != null) {
            character.networkID = networkIDWasNotFoundReplace(character.networkID);
            addActiveBlock(container, {
                variant: NEUTRAL_VARIANT,
                networkID: character.networkID,
                name: character.skin,
                faction: character.faction,
                gameEvent: 'UI_RelocateCharacter'
            });
        }
    });

    memory.Avehicles.forEach(vehicle => {
        if (vehicle != null) {
            vehicle.networkID = networkIDWasNotFoundReplace(vehicle.networkID);
            addActiveBlock(container, {
                variant: VEHICLE_VARIANT,
                networkID: vehicle.networkID,
                name: vehicle.skin,
                gameEvent: 'UI_RelocateVehicle'
            });
        }
    });
}

/**
 * Rendert Skin-Einträge (Root-Skin + Kostüme) eines Typs in den Container.
 * @param {HTMLElement}        container
 * @param {Array<[string,string[]]>} skins   Array von [rootSkin, subSkins[]]
 * @param {number}             variant
 * @param {string}             gameEvent
 */
function renderSkinEntries(container, skins, variant, gameEvent) {
    skins.forEach(([rootSkin, subSkins]) => {
        addBlock(container, rootSkin, variant, gameEvent);
        subSkins.forEach(sub => addBlock(container, sub, variant, gameEvent));
    });
}

/**
 * Rendert eine einzelne Sektion in den gegebenen Container.
 * Konsolidiert die ehemals doppelte Logik zwischen addEveryEntity
 * und optionsContainerButtonHandler.
 * @param {HTMLElement} container
 * @param {string}      section   Sektionsname
 */
export function renderSection(container, section) {
    switch (section) {
        case 'Charaktere':
            createSectionLine(container, section);
            renderSkinEntries(container, memory.characters, PLAYER_VARIANT, 'UI_SpawnCharacterOrVehicle');
            break;
        case 'Fahrzeuge':
            createSectionLine(container, section);
            renderSkinEntries(container, memory.vehicles, VEHICLE_VARIANT, 'UI_SpawnCharacterOrVehicle');
            break;
        case 'Fraktionen':
            createSectionLine(container, section);
            memory.factions.forEach(f => addBlock(container, f, GROUP_VARIANT, 'UI_SpawnGroup'));
            break;
        case 'Locations':
            createSectionLine(container, section);
            memory.locations.forEach(l => addBlock(container, l, LOCATION_VARIANT, 'UI_Teleport'));
            break;
        case 'Dioramen':
            createSectionLine(container, section);
            memory.dioramas.forEach(d => addBlock(container, d, DIORAMA_VARIANT, 'UI_Diorama'));
            break;
        case 'MeineFahrzeuge':
            createSectionLine(container, 'Meine Fahrzeuge');
            const lowerName = getPlayerName().toLowerCase();
            if (memory.myVehicles?.[lowerName]) {
                memory.myVehicles[lowerName].forEach(v =>
                    addBlock(container, v, VEHICLE_VARIANT, 'UI_SpawnCharacterOrVehicle')
                );
            }
            break;
    }
}

/**
 * Rendert alle Sektionen (Home-Tab): Aktive + Charaktere + Fahrzeuge + Fraktionen + Locations + Dioramen.
 */
export function addEveryEntity() {
    const el = document.getElementById('content-holder');
    addActiveSection(el);
    renderSection(el, 'Charaktere');
    renderSection(el, 'Fahrzeuge');
    renderSection(el, 'Fraktionen');
    renderSection(el, 'Locations');
    renderSection(el, 'Dioramen');
    document.getElementById('gw-menu-screen').style.display = 'flex';
}

/**
 * Initialisiert die Sidebar-Buttons und bindet sie an die renderSection-Logik.
 */
export function initSidebarTabs() {
    const tabs = {
        homeTab: 'Everything',
        characterTab: 'Charaktere',
        vehicleTab: 'Fahrzeuge',
        factionTab: 'Fraktionen',
        locationTab: 'Locations',
        dioramaTab: 'Dioramen',
        myVehiclesTab: 'MeineFahrzeuge',
        /*         driversTab: 'Drivers',
                optionsTab: 'Optionen', */
    };

    for (const [id, section] of Object.entries(tabs)) {
        const el = document.getElementById(id);
        if (!el) continue;

        el.addEventListener('click', e => {
            e.stopPropagation();

            // Overlay-Submenüs werden als Popup geöffnet
            if (section === 'Drivers') {
                openOverlay(renderDriversOverlay);
                return;
            }
            if (section === 'Optionen') {
                openOverlay(renderOptionsOverlay);
                return;
            }

            const contentHolder = document.getElementById('content-holder');
            contentHolder.innerHTML = '';

            if (section === 'Everything') {
                addEveryEntity();
            } else {
                renderSection(contentHolder, section);
            }
        });
    }
}
