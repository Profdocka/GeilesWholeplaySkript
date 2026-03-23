/**
 * script.js – Einstiegspunkt für das Geile Wholeplay Menü.
 *
 * Importiert alle Module und verbindet die NUI-Messages aus der Lua-Schicht
 * mit den entsprechenden Handlern. Die gesamte Logik ist auf separate Module
 * aufgeteilt (constants, api, utils, dom, menu, tabs, search, overlay, submenus).
 */

import { setPlayerName } from './constants.js';
import { setCloseMenuFn } from './dom.js';
import { registerSkinsForCharAndVeh, openGWMenu, closeGWMenu, setAddEveryEntityFn } from './menu.js';
import { addEveryEntity, initSidebarTabs } from './tabs.js';
import { initSearch } from './search.js';
import { initOverlay } from './overlay.js';
import { addClickEventHandler } from './utils.js';
import { syncOptionsState } from './optionsSubmenu.js';
import { syncDriversState } from './driversSubmenu.js';

// Zirkuläre Referenzen auflösen: dom.js und menu.js brauchen Funktionen voneinander
setCloseMenuFn(closeGWMenu);
setAddEveryEntityFn(addEveryEntity);

// ─── Initialisierung ─────────────────────────────────────────────

window.addEventListener('load', () => {
    document.getElementById('gw-menu-screen').hidden = false;

    // NUI-Nachrichten von der Lua-Schicht empfangen
    window.addEventListener('message', async e => {
        switch (e.data.type) {
            case 'GW_InitialInfos':
                await registerSkinsForCharAndVeh(e.data);
                break;
            case 'GW_OpenMenu':
                setPlayerName(e.data.playerName);
                await openGWMenu(e.data);
                break;
            case 'GW_OptionsSync':
                syncOptionsState(e.data);
                break;
            case 'GW_DriversSync':
                syncDriversState(e.data.driversInfo);
                break;
        }
    });

    // Schließen-Button
    document.getElementById('exit').addEventListener('click', () => closeGWMenu());

    // "Mein Auto spawnen"-Button
    addClickEventHandler(document.getElementById('mycar'), 'UI_SpawnMyCar', {}, closeGWMenu);

    // Sidebar-Tabs initialisieren
    initSidebarTabs();

    // Overlay-System initialisieren (Submenüs: Optionen & Drivers)
    initOverlay();
});

// Suchleiste und Tastenkürzel (ESC / F) initialisieren
initSearch(closeGWMenu);