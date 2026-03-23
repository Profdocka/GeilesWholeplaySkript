/**
 * menu.js – Menü-Steuerung: Öffnen, Schließen, Daten-Registrierung.
 *
 * Bug-Fix: Das Menü öffnete sich beim ersten F6 nicht, weil:
 * 1. closeGWMenu() den isMenuOpen-State mit "!isMenuOpen" umschaltete statt auf false zu setzen.
 *    Bei Fehlschlag (Daten noch nicht geladen) wurde closeGWMenu() aufgerufen,
 *    was isMenuOpen von false auf true setzte.
 * 2. Beim nächsten F6 dachte der Code, das Menü sei offen und schloss es nur.
 *
 * Fix: isMenuOpen wird jetzt immer explizit auf true/false gesetzt.
 * openGWMenu() ruft bei fehlenden Daten nicht mehr closeGWMenu() auf,
 * sondern speichert die Daten für ein verzögertes Öffnen (pendingOpenData).
 */

import {
    memory, isMenuOpen, setMenuOpen, setPlayerName,
    isDataLoaded, setDataLoaded, setRequestingData,
    isRequestingData, getPendingOpenData, setPendingOpenData
} from './constants.js';
import { fetchNUI } from './api.js';
import { sortObjectKeysAlphabetically } from './utils.js';
import { closeOverlay } from './overlay.js';

/** Wird von tabs.js gesetzt, um zirkuläre Imports zu vermeiden. */
let _addEveryEntityFn = null;

/**
 * Registriert die addEveryEntity-Funktion aus tabs.js.
 * @param {Function} fn
 */
export function setAddEveryEntityFn(fn) { _addEveryEntityFn = fn; }

/**
 * Registriert die statischen Daten (Skins, Fraktionen, Locations, Fahrzeuge)
 * aus der Lua-Schicht im memory-Store.
 * Löst außerdem ein vorher zurückgehaltenes Menü-Öffnen aus (pendingOpenData).
 * @param {object} data  Die GW_InitialInfos-Nachricht
 */
export async function registerSkinsForCharAndVeh(data) {
    memory.characters = sortObjectKeysAlphabetically(data.characterSkins);
    memory.vehicles = sortObjectKeysAlphabetically(data.vehicleSkins);
    memory.factions = Object.keys(data.allFactions).sort();
    memory.locations = Object.keys(data.locations).sort();
    memory.locationsObjects = data.locations;
    memory.myVehicles = data.myVehicles;

    setDataLoaded(true);
    setRequestingData(false);

    // Wenn ein Menü-Öffnen auf Daten gewartet hat, jetzt nachholen
    const pending = getPendingOpenData();
    if (pending) {
        setPendingOpenData(null);
        await openGWMenu(pending);
    }
}

/**
 * Registriert die dynamischen Daten (aktive Spieler, Charaktere, Fahrzeuge, Dioramen).
 * @param {object} gwData  Die GW_OpenMenu-Nachricht
 */
export function registerActiveData(gwData) {
    memory.players = Object.values(gwData.players);
    memory.Acharacters = Object.values(gwData.characters);
    memory.Avehicles = Object.values(gwData.vehicles);
    memory.dioramas = Object.values(gwData.dioramas).sort();
    // DriversInfo für das Drivers-Submenü (falls vorhanden)
    if (gwData.driversInfo) {
        memory.driversInfo = gwData.driversInfo;
    }
}

/**
 * Prüft ob die statischen Menü-Daten vorhanden sind.
 * Falls nicht, wird ein erneuter Daten-Request ausgelöst.
 * @returns {boolean}
 */
function isMenuDataFunctional() {
    if (isDataLoaded() && memory.characters != null) {
        return true;
    }
    // Nur einmal gleichzeitig anfragen
    if (!isRequestingData()) {
        setRequestingData(true);
        fetchNUI('UI_RequestMenuData', {});
        // Cooldown nach 5 Sekunden zurücksetzen
        setTimeout(() => setRequestingData(false), 5000);
    }
    return false;
}

/**
 * Öffnet das Geile Wholeplay Menü.
 * Wenn das Menü bereits offen ist, wird es geschlossen (Toggle).
 * Wenn die Daten noch nicht geladen sind, werden sie angefordert
 * und das Öffnen wird nachgeholt sobald die Daten ankommen.
 * @param {object} gwData  Die GW_OpenMenu-Nachricht
 */
export async function openGWMenu(gwData) {
    if (isMenuOpen()) {
        closeGWMenu();
        return;
    }

    if (isMenuDataFunctional()) {
        registerActiveData(gwData);
        setMenuOpen(true);
        _addEveryEntityFn?.();
    } else {
        // Daten noch nicht da → für später merken
        setPendingOpenData(gwData);
        console.log('Menü-Daten werden noch geladen...');
    }
}

/**
 * Schließt das Geile Wholeplay Menü und bereinigt den Inhalt.
 * Bug-Fix: setzt isMenuOpen explizit auf false statt zu toggeln.
 */
export function closeGWMenu() {
    setMenuOpen(false);
    closeOverlay();
    document.getElementById('gw-menu-screen').style.display = 'none';
    document.getElementById('content-holder').innerHTML = '';
    fetchNUI('UI_CloseMenu', {});
}
