/**
 * constants.js – Zentrale Konstanten und geteilter Zustand für das Geile Wholeplay Menü.
 * Alle Module importieren Variant-Konstanten und den memory-Store von hier.
 */

// Variant-Konstanten (identisch mit der Lua-Seite)
export const VEHICLE_VARIANT = -1;
export const PLAYER_VARIANT = 0;
export const NEUTRAL_VARIANT = 1;
export const FRIENDLY_VARIANT = 2;
export const AGGRESSIVE_VARIANT = 3;
export const GROUP_VARIANT = 4;
export const LOCATION_VARIANT = 5;
export const DIORAMA_VARIANT = 6;

/**
 * Zentraler Datenspeicher – wird von registerSkinsForCharAndVeh (statisch)
 * und registerActiveData (dynamisch) befüllt.
 */
export const memory = {};

/** Menü-Zustand */
let _isMenuOpen = false;
let _playerName = "";
let _isDataLoaded = false;
let _isRequestingData = false;
let _pendingOpenData = null;

/** @returns {boolean} */
export function isMenuOpen() { return _isMenuOpen; }
/** @param {boolean} v */
export function setMenuOpen(v) { _isMenuOpen = v; }

/** @returns {string} */
export function getPlayerName() { return _playerName; }
/** @param {string} v */
export function setPlayerName(v) { _playerName = v; }

/** @returns {boolean} Ob die statischen Daten (Skins, Fraktionen etc.) bereits geladen wurden */
export function isDataLoaded() { return _isDataLoaded; }
/** @param {boolean} v */
export function setDataLoaded(v) { _isDataLoaded = v; }

/** @returns {boolean} Ob gerade ein erneuter Daten-Request läuft */
export function isRequestingData() { return _isRequestingData; }
/** @param {boolean} v */
export function setRequestingData(v) { _isRequestingData = v; }

/** @returns {object|null} Zwischengespeicherte OpenMenu-Daten für verzögertes Öffnen */
export function getPendingOpenData() { return _pendingOpenData; }
/** @param {object|null} v */
export function setPendingOpenData(v) { _pendingOpenData = v; }
