/**
 * driversSubmenu.js – Overlay-Inhalt für die Fahrgemeinschafts-Verwaltung.
 *
 * Funktionen:
 * - Aktive Fahrgemeinschaften anzeigen (Fahrzeugname, Passagiere mit Sitz als Tooltip)
 * - Fahrgemeinschaft anklicken → Bearbeitungsfeld mit Drag & Drop
 * - Fahrgemeinschaft spawnen  (gwspawndrivers)
 * - Task setzen               (gwdriverstask) mit Ziel-Auswahl und Quick-Button
 * - Fahrgemeinschaft erstellen (gwdrivers)
 * - Passagiere aktualisieren  (gwdriversupdate)
 *
 * Nach jeder Aktion (Spawn, Task, Create, Update) wird das Menü geschlossen.
 */

import { memory, setMenuOpen } from './constants.js';
import { fetchNUI } from './api.js';
import { closeOverlay } from './overlay.js';

/** Verfügbare Task-Typen für Fahrgemeinschaften */
const TASK_TYPES = [
    'NONE', 'GETINVEHICLE', 'GETOUTOFVEHICLE',
    'DRIVETOCOORDS', 'ESCORT', 'CHASE'
];

/** Seat-Index → lesbarer Name */
const SEAT_LABELS = { '-1': 'Fahrer', '0': 'Beifahrer', '1': 'Hinten Links', '2': 'Hinten Rechts', '3': 'Sitz 4', '4': 'Sitz 5', '5': 'Sitz 6', '6': 'Sitz 7' };

/** Löst eine networkID über die nameMap in einen lesbaren Namen auf */
function resolveName(netID) {
    const nameMap = memory.driversInfo?.nameMap;
    const key = String(netID);
    return nameMap?.[key] ?? `Net:${netID}`;
}

/** Schließt Overlay + Hauptmenü nach einer Aktion */
function closeMenuAfterAction() {
    setMenuOpen(false);
    closeOverlay();
    document.getElementById('gw-menu-screen').style.display = 'none';
    document.getElementById('content-holder').innerHTML = '';
    fetchNUI('UI_CloseMenu', {});
}

// ─── Hilfs-Funktionen ────────────────────────────────────────────

function createSubheading(container, title) {
    const h3 = document.createElement('h3');
    h3.textContent = title;
    h3.classList.add('overlay-section-subtitle');
    container.append(h3);
}

function createInputField(container, label, placeholder) {
    const row = document.createElement('div');
    row.classList.add('overlay-input-row');
    const lbl = document.createElement('label');
    lbl.textContent = label;
    lbl.classList.add('overlay-input-label');
    const input = document.createElement('input');
    input.type = 'text';
    input.placeholder = placeholder;
    input.classList.add('overlay-input-field');
    row.append(lbl, input);
    container.append(row);
    return input;
}

function createActionButton(container, text, onClick) {
    const btn = document.createElement('button');
    btn.textContent = text;
    btn.classList.add('overlay-action-btn');
    btn.addEventListener('click', onClick);
    container.append(btn);
}

// ─── Sektion: Aktive Fahrgemeinschaften ──────────────────────────

/**
 * Rendert die aktiven Fahrgemeinschaften als Karten mit Fahrzeugname,
 * Passagier-Tooltip und Klick-zum-Bearbeiten.
 */
function renderActiveDrivers(container) {
    createSubheading(container, 'Aktive Fahrgemeinschaften');

    const info = memory.driversInfo;
    if (!info?.drivers || Object.keys(info.drivers).length === 0) {
        const empty = document.createElement('p');
        empty.textContent = 'Keine aktiven Fahrgemeinschaften.';
        empty.classList.add('overlay-empty-text');
        container.append(empty);
        return;
    }

    for (const [vehNet, passengers] of Object.entries(info.drivers)) {
        const card = document.createElement('div');
        card.classList.add('overlay-driver-card', 'overlay-driver-card-clickable');

        // Kopfzeile: Fahrzeugname
        const header = document.createElement('div');
        header.classList.add('driver-card-header');
        const vehName = document.createElement('strong');
        vehName.textContent = resolveName(vehNet);
        const netBadge = document.createElement('span');
        netBadge.classList.add('driver-card-net-badge');
        netBadge.textContent = `#${vehNet}`;
        header.append(vehName, netBadge);
        card.append(header);

        // Passagier-Chips mit Hover-Tooltip
        if (passengers && typeof passengers === 'object') {
            const chipsRow = document.createElement('div');
            chipsRow.classList.add('driver-card-chips');

            for (const [seat, pedNet] of Object.entries(passengers)) {
                const chip = document.createElement('span');
                chip.classList.add('driver-chip');
                chip.textContent = resolveName(pedNet);

                // Tooltip mit Sitzplatz
                const tooltip = document.createElement('span');
                tooltip.classList.add('driver-chip-tooltip');
                tooltip.textContent = SEAT_LABELS[seat] ?? `Sitz ${seat}`;
                chip.append(tooltip);

                chipsRow.append(chip);
            }
            card.append(chipsRow);
        }

        // Task-Info
        const taskInfo = info.driverstask?.[vehNet];
        if (taskInfo) {
            const taskSpan = document.createElement('span');
            const taskType = typeof taskInfo === 'string' ? taskInfo : (taskInfo.type ?? 'NONE');
            taskSpan.textContent = `Task: ${taskType}`;
            if (taskInfo.targetNet) {
                taskSpan.textContent += ` → ${resolveName(taskInfo.targetNet)}`;
            }
            taskSpan.classList.add('overlay-driver-task');
            card.append(taskSpan);
        }

        // Klick → Bearbeitungs-Panel öffnen
        card.addEventListener('click', () => openEditPanel(vehNet, passengers));
        card.title = 'Klicken zum Bearbeiten';
        container.append(card);
    }
}

// ─── Custom Drag & Drop (Mouse-Events) ──────────────────────────
// FiveM CEF blockiert die native HTML5 Drag & Drop API.
// Eigene Implementierung mit mousedown/mousemove/mouseup.

let _dragState = null; // { el, net, name, originSlot, ghost }

function startDrag(e, net, name, originEl, originSlot) {
    e.preventDefault();

    // Ghost-Element erzeugen (folgt dem Cursor)
    const ghost = document.createElement('div');
    ghost.classList.add('driver-drag-ghost');
    ghost.textContent = name;
    ghost.style.left = e.clientX + 'px';
    ghost.style.top = e.clientY + 'px';
    document.body.append(ghost);

    _dragState = { el: originEl, net: String(net), name, originSlot, ghost };

    // Alle Drop-Targets hervorheben
    document.querySelectorAll('.driver-edit-slot, .driver-pool-chips').forEach(t => t.classList.add('drop-candidate'));
}

function onMouseMove(e) {
    if (!_dragState) return;
    _dragState.ghost.style.left = e.clientX + 'px';
    _dragState.ghost.style.top = e.clientY + 'px';

    // Hover-Highlight
    document.querySelectorAll('.drag-over').forEach(el => el.classList.remove('drag-over'));
    const target = getDropTarget(e);
    if (target) target.classList.add('drag-over');
}

function onMouseUp(e) {
    if (!_dragState) return;
    const { net, name, originSlot, ghost, el: originEl } = _dragState;
    _dragState = null;

    ghost.remove();
    document.querySelectorAll('.drop-candidate').forEach(t => t.classList.remove('drop-candidate'));
    document.querySelectorAll('.drag-over').forEach(t => t.classList.remove('drag-over'));

    const target = getDropTarget(e);
    if (!target) return;

    // Drop auf Pool → aus Slot entfernen
    if (target.classList.contains('driver-pool-chips')) {
        originEl.remove();
        target.dispatchEvent(new CustomEvent('chip-returned', { detail: { net, name } }));
        return;
    }

    // Drop auf Slot
    if (target.classList.contains('driver-edit-slot')) {
        // Entferne originalen Chip
        originEl.remove();
        // Entferne bestehenden Chip im Ziel-Slot
        const existing = target.querySelector('.driver-edit-chip');
        if (existing) {
            // Bestehenden Chip zurück zum Ursprung oder Pool bewegen
            existing.remove();
            // Signalisiere dass ein Chip frei wurde
            const pool = document.getElementById('driver-pool-chips');
            pool?.dispatchEvent(new CustomEvent('chip-returned', { detail: { net: existing.dataset.net, name: existing.dataset.name } }));
        }
        // Neuen Chip im Ziel-Slot anlegen
        target.append(createMouseChip(net, name));
        // Pool aktualisieren
        const pool = document.getElementById('driver-pool-chips');
        pool?.dispatchEvent(new CustomEvent('pool-refresh'));
    }
}

/** Findet das Drop-Target unter dem Cursor */
function getDropTarget(e) {
    const els = document.elementsFromPoint(e.clientX, e.clientY);
    for (const el of els) {
        if (el.classList.contains('driver-edit-slot')) return el;
        if (el.classList.contains('driver-pool-chips')) return el;
    }
    return null;
}

// Globale Listener (werden nur einmal registriert)
let _dragListenersActive = false;
function ensureDragListeners() {
    if (_dragListenersActive) return;
    _dragListenersActive = true;
    document.addEventListener('mousemove', onMouseMove);
    document.addEventListener('mouseup', onMouseUp);
}

/** Erzeugt einen per Maus verschiebbaren Chip */
function createMouseChip(netID, name) {
    const chip = document.createElement('div');
    chip.classList.add('driver-edit-chip');
    chip.dataset.net = String(netID);
    chip.dataset.name = name;
    chip.textContent = name;
    chip.addEventListener('mousedown', e => {
        if (e.button !== 0) return;
        startDrag(e, netID, name, chip, chip.parentElement);
    });
    return chip;
}

// ─── Bearbeitungs-Panel ──────────────────────────────────────────

/**
 * Öffnet ein Bearbeitungspanel für eine Fahrgemeinschaft.
 * Zeigt alle aktiven NPCs und ermöglicht Drag & Drop der Passagiere.
 */
function openEditPanel(vehNet, currentPassengers) {
    // Bestehenden Edit-Panel entfernen falls vorhanden
    document.getElementById('driver-edit-panel')?.remove();

    const panel = document.createElement('div');
    panel.id = 'driver-edit-panel';
    panel.classList.add('driver-edit-panel');

    // Header
    const panelHeader = document.createElement('div');
    panelHeader.classList.add('driver-edit-header');
    const title = document.createElement('h3');
    title.textContent = `Bearbeiten: ${resolveName(vehNet)}`;
    const closeBtn = document.createElement('span');
    closeBtn.classList.add('material-icons', 'overlay-close');
    closeBtn.textContent = 'close';
    closeBtn.addEventListener('click', () => panel.remove());
    panelHeader.append(title, closeBtn);
    panel.append(panelHeader);

    // Aktuelle Sitzplätze (Drop-Targets)
    const seatsContainer = document.createElement('div');
    seatsContainer.classList.add('driver-edit-seats');
    const seatTitle = document.createElement('h4');
    seatTitle.textContent = 'Sitzplätze';
    seatsContainer.append(seatTitle);

    // Sammle verwendete pedNets
    const usedPedNets = new Set();
    const seatSlots = {};

    // Erzeuge Slots für Sitze -1 bis 6
    for (let i = -1; i <= 6; i++) {
        const seatKey = String(i);
        const pedNet = currentPassengers?.[seatKey];

        const slot = document.createElement('div');
        slot.classList.add('driver-edit-slot');
        slot.dataset.seat = seatKey;

        const label = document.createElement('span');
        label.classList.add('driver-edit-slot-label');
        label.textContent = SEAT_LABELS[seatKey] ?? `Sitz ${i}`;
        slot.append(label);

        if (pedNet != null) {
            const occupant = createMouseChip(pedNet, resolveName(pedNet));
            slot.append(occupant);
            usedPedNets.add(String(pedNet));
        }

        seatSlots[seatKey] = slot;
        seatsContainer.append(slot);
    }
    panel.append(seatsContainer);

    // NPC-Pool (alle aktiven Charaktere die noch nicht zugewiesen sind)
    const poolContainer = document.createElement('div');
    poolContainer.classList.add('driver-edit-pool');
    const poolTitle = document.createElement('h4');
    poolTitle.textContent = 'Verfügbare NPCs';
    poolContainer.append(poolTitle);

    const poolChips = document.createElement('div');
    poolChips.id = 'driver-pool-chips';
    poolChips.classList.add('driver-pool-chips');
    poolContainer.append(poolChips);
    panel.append(poolContainer);

    function refreshPool() {
        poolChips.innerHTML = '';
        // Sammle alle belegten Nets aus den Slots
        const occupied = new Set();
        for (const slot of Object.values(seatSlots)) {
            const chip = slot.querySelector('.driver-edit-chip');
            if (chip) occupied.add(chip.dataset.net);
        }
        // Zeige alle aktiven Charaktere die nicht belegt sind
        const activeChars = memory.Acharacters ?? [];
        activeChars.forEach(char => {
            if (!char) return;
            const net = String(char.networkID);
            if (occupied.has(net)) return;
            const chip = document.createElement('div');
            chip.classList.add('driver-pool-chip');
            chip.dataset.net = net;
            const chipName = char.skin ?? char.name ?? net;
            chip.textContent = chipName;
            chip.addEventListener('mousedown', e => {
                if (e.button !== 0) return;
                startDrag(e, net, chipName, chip, poolChips);
            });
            poolChips.append(chip);
        });
    }
    refreshPool();

    // Pool-Events: Chip zurückgekommen oder Refresh nötig
    poolChips.addEventListener('chip-returned', () => refreshPool());
    poolChips.addEventListener('pool-refresh', () => refreshPool());

    // Mouse-basiertes Drag & Drop aktivieren
    ensureDragListeners();

    // Speichern-Button
    const saveRow = document.createElement('div');
    saveRow.classList.add('driver-edit-actions');
    createActionButton(saveRow, 'Speichern', () => {
        // Sitzplatz-genaue Zuordnung: { seatIndex: characterName }
        const seatMap = {};
        let hasAny = false;
        for (let i = -1; i <= 6; i++) {
            const slot = seatSlots[String(i)];
            const chip = slot?.querySelector('.driver-edit-chip');
            if (chip) {
                seatMap[String(i)] = chip.dataset.name;
                hasAny = true;
            }
        }
        if (!hasAny) return;
        fetchNUI('UI_DriversUpdateSeated', { vehicle: resolveName(vehNet), seatMap });
        closeMenuAfterAction();
    });
    panel.append(saveRow);

    // Panel in den Overlay-Content einfügen
    const overlayContent = document.getElementById('overlay-content');
    overlayContent.append(panel);
    panel.scrollIntoView({ behavior: 'smooth' });
}

// ─── Sektion: Spawnen ────────────────────────────────────────────

function renderSpawnSection(container) {
    createSubheading(container, 'Fahrgemeinschaft spawnen');
    const vehicleInput = createInputField(container, 'Fahrzeug / Fahrer', 'Name des Fahrzeugs oder Fahrers');
    const passengersInput = createInputField(container, 'Fahrer & Passagiere', 'z.B. MarionDunby HudsonHudson');

    createActionButton(container, 'Spawnen', () => {
        const vehicle = vehicleInput.value.trim();
        const passengers = passengersInput.value.trim().split(/\s+/).filter(Boolean);
        if (!vehicle) return;
        fetchNUI('UI_SpawnDrivers', { vehicle, passengers });
        closeMenuAfterAction();
    });
}

// ─── Sektion: Task setzen ────────────────────────────────────────

function renderTaskSection(container) {
    createSubheading(container, 'Task setzen');
    const vehicleInput = createInputField(container, 'Fahrzeug', 'Name des Fahrzeugs');

    // Task-Typ Dropdown
    const taskRow = document.createElement('div');
    taskRow.classList.add('overlay-input-row');
    const taskLabel = document.createElement('label');
    taskLabel.textContent = 'Task';
    taskLabel.classList.add('overlay-input-label');
    const taskSelect = document.createElement('select');
    taskSelect.classList.add('overlay-input-field', 'overlay-select');
    TASK_TYPES.forEach(t => {
        const opt = document.createElement('option');
        opt.value = t;
        opt.textContent = t;
        taskSelect.append(opt);
    });
    taskRow.append(taskLabel, taskSelect);
    container.append(taskRow);

    // Ziel-Eingabe mit NPC-Picker
    const targetRow = document.createElement('div');
    targetRow.classList.add('overlay-input-row');
    const targetLabel = document.createElement('label');
    targetLabel.textContent = 'Ziel (für ESCORT/CHASE)';
    targetLabel.classList.add('overlay-input-label');

    const targetFieldRow = document.createElement('div');
    targetFieldRow.classList.add('target-field-row');

    const targetInput = document.createElement('input');
    targetInput.type = 'text';
    targetInput.placeholder = 'Charaktername';
    targetInput.classList.add('overlay-input-field');

    // Quick-Button: Eigenen Charakter als Ziel (leeres Feld = Server nutzt eigenen Player)
    const selfBtn = document.createElement('button');
    selfBtn.classList.add('overlay-quick-btn');
    selfBtn.title = 'Eigenen Charakter als Ziel';
    selfBtn.innerHTML = '<span class="material-icons" style="font-size:18px">person_pin</span>';
    selfBtn.addEventListener('click', () => {
        targetInput.value = '';
        targetInput.placeholder = '→ Eigener Charakter (Standard)';
    });

    targetFieldRow.append(targetInput, selfBtn);
    targetRow.append(targetLabel, targetFieldRow);
    container.append(targetRow);

    createActionButton(container, 'Task zuweisen', () => {
        const vehicle = vehicleInput.value.trim();
        const task = taskSelect.value;
        const target = targetInput.value.trim() || null;
        if (!vehicle) return;
        fetchNUI('UI_DriversTask', { vehicle, task, target });
        closeMenuAfterAction();
    });
}

// ─── Sektion: Erstellen ──────────────────────────────────────────

function renderCreateSection(container) {
    createSubheading(container, 'Fahrgemeinschaft zuweisen');
    const vehicleInput = createInputField(container, 'Fahrzeug', 'Name des aktiven Fahrzeugs');
    const membersInput = createInputField(container, 'Fahrer & Passagiere', 'z.B. MarionDunby HudsonHudson');

    createActionButton(container, 'Zuweisen', () => {
        const vehicle = vehicleInput.value.trim();
        const members = membersInput.value.trim().split(/\s+/).filter(Boolean);
        if (!vehicle || !members.length) return;
        fetchNUI('UI_DriversCreate', { vehicle, members });
        closeMenuAfterAction();
    });
}

// ─── Sektion: Aktualisieren ──────────────────────────────────────

function renderUpdateSection(container) {
    createSubheading(container, 'Passagiere aktualisieren');
    const vehicleInput = createInputField(container, 'Fahrzeug', 'Name des aktiven Fahrzeugs');
    const driverInput = createInputField(container, 'Neuer Fahrer', 'Charaktername');
    const passengersInput = createInputField(container, 'Neue Passagiere', 'z.B. HudsonHudson VladimirSmirnov');

    createActionButton(container, 'Aktualisieren', () => {
        const vehicle = vehicleInput.value.trim();
        const driver = driverInput.value.trim();
        const passengers = passengersInput.value.trim().split(/\s+/).filter(Boolean);
        if (!vehicle || !driver) return;
        fetchNUI('UI_DriversUpdate', { vehicle, driver, passengers });
        closeMenuAfterAction();
    });
}

// ─── Haupt-Render ────────────────────────────────────────────────

export function renderDriversOverlay(container) {
    const header = document.createElement('h2');
    header.textContent = 'Fahrgemeinschaften';
    header.classList.add('overlay-section-title');
    container.append(header);

    renderActiveDrivers(container);
    renderSpawnSection(container);
    renderTaskSection(container);
    renderCreateSection(container);
    renderUpdateSection(container);
}

/**
 * Aktualisiert die DriversInfo im memory-Store von außen (z.B. per Server-Event).
 * @param {object} driversInfo  Neue DriversInfo-Daten vom Server
 */
export function syncDriversState(driversInfo) {
    if (driversInfo) {
        memory.driversInfo = driversInfo;
    }
}
