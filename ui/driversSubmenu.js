/**
 * driversSubmenu.js – Overlay-Inhalt für die Fahrgemeinschafts-Verwaltung.
 *
 * Layout:
 * 1. Aktive Fahrgemeinschaften (Karten) → Klick öffnet Bearbeitungspanel (Sitze + Task)
 * 2. "Neue Fahrgemeinschaft" Button → Wizard: Fahrzeug wählen, dann Insassen
 * 3. Fahrgemeinschaft spawnen (Textfelder, gwspawndrivers)
 *
 * Alle Interaktionen (außer Spawn) nutzen Drag & Drop via Mouse-Events (FiveM-CEF-kompatibel).
 * Nach jeder Aktion wird das Menü geschlossen.
 */

import { memory, setMenuOpen } from './constants.js';
import { fetchNUI } from './api.js';
import { closeOverlay } from './overlay.js';

const TASK_TYPES = ['NONE', 'GETINVEHICLE', 'GETOUTOFVEHICLE', 'DRIVETOCOORDS', 'ESCORT', 'CHASE'];
const SEAT_LABELS = { '-1': 'Fahrer', '0': 'Beifahrer', '1': 'Hinten Links', '2': 'Hinten Rechts', '3': 'Sitz 4', '4': 'Sitz 5', '5': 'Sitz 6', '6': 'Sitz 7' };

function resolveName(netID) {
    const key = String(netID);
    return memory.driversInfo?.nameMap?.[key] ?? `Net:${netID}`;
}

function closeMenuAfterAction() {
    setMenuOpen(false);
    closeOverlay();
    document.getElementById('gw-menu-screen').style.display = 'none';
    document.getElementById('content-holder').innerHTML = '';
    fetchNUI('UI_CloseMenu', {});
}

// ═══════════════════════════════════════════════════════════════
// Custom Drag & Drop (Mouse-Events, FiveM-CEF-kompatibel)
// ═══════════════════════════════════════════════════════════════

let _dragState = null;
let _dragListenersActive = false;

function startDrag(e, net, name, originEl) {
    e.preventDefault();
    e.stopPropagation();
    const ghost = document.createElement('div');
    ghost.classList.add('driver-drag-ghost');
    ghost.textContent = name;
    ghost.style.left = e.clientX + 'px';
    ghost.style.top = e.clientY + 'px';
    document.body.append(ghost);
    _dragState = { el: originEl, net: String(net), name, ghost };
    document.querySelectorAll('.driver-edit-slot, .driver-pool-chips, .driver-target-drop, .driver-vehicle-drop').forEach(t => t.classList.add('drop-candidate'));
}

function onMouseMove(e) {
    if (!_dragState) return;
    _dragState.ghost.style.left = e.clientX + 'px';
    _dragState.ghost.style.top = e.clientY + 'px';
    document.querySelectorAll('.drag-over').forEach(el => el.classList.remove('drag-over'));
    const target = getDropTarget(e);
    if (target) target.classList.add('drag-over');
}

function onMouseUp(e) {
    if (!_dragState) return;
    const { net, name, ghost, el: originEl } = _dragState;
    _dragState = null;
    ghost.remove();
    document.querySelectorAll('.drop-candidate, .drag-over').forEach(t => {
        t.classList.remove('drop-candidate');
        t.classList.remove('drag-over');
    });
    const target = getDropTarget(e);
    if (!target) return;

    if (target.classList.contains('driver-pool-chips')) {
        originEl.remove();
        target.dispatchEvent(new CustomEvent('pool-refresh'));
        return;
    }
    if (target.classList.contains('driver-target-drop')) {
        target.querySelector('input').value = name;
        return;
    }
    if (target.classList.contains('driver-vehicle-drop')) {
        target.dataset.selectedNet = net;
        target.dataset.selectedName = name;
        const display = target.querySelector('.vehicle-drop-display');
        if (display) { display.textContent = name; display.classList.add('has-value'); }
        target.dispatchEvent(new CustomEvent('vehicle-selected'));
        return;
    }
    if (target.classList.contains('driver-edit-slot')) {
        originEl.remove();
        const existing = target.querySelector('.driver-edit-chip');
        if (existing) {
            existing.remove();
            document.getElementById('driver-pool-chips')?.dispatchEvent(new CustomEvent('pool-refresh'));
        }
        target.append(createMouseChip(net, name));
        document.getElementById('driver-pool-chips')?.dispatchEvent(new CustomEvent('pool-refresh'));
    }
}

function getDropTarget(e) {
    for (const el of document.elementsFromPoint(e.clientX, e.clientY)) {
        if (el.classList.contains('driver-edit-slot')) return el;
        if (el.classList.contains('driver-pool-chips')) return el;
        if (el.classList.contains('driver-target-drop')) return el;
        if (el.classList.contains('driver-vehicle-drop')) return el;
    }
    return null;
}

function ensureDragListeners() {
    if (_dragListenersActive) return;
    _dragListenersActive = true;
    document.addEventListener('mousemove', onMouseMove);
    document.addEventListener('mouseup', onMouseUp);
}

function createMouseChip(netID, name) {
    const chip = document.createElement('div');
    chip.classList.add('driver-edit-chip');
    chip.dataset.net = String(netID);
    chip.dataset.name = name;
    chip.textContent = name;
    chip.addEventListener('mousedown', e => { if (e.button === 0) startDrag(e, netID, name, chip); });
    return chip;
}

function createPoolChip(net, name, poolEl) {
    const chip = document.createElement('div');
    chip.classList.add('driver-pool-chip');
    chip.dataset.net = net;
    chip.textContent = name;
    chip.addEventListener('mousedown', e => { if (e.button === 0) startDrag(e, net, name, chip); });
    return chip;
}

// ═══════════════════════════════════════════════════════════════
// Hilfs-Funktionen
// ═══════════════════════════════════════════════════════════════

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

function createActionButton(container, text, onClick, cssClass) {
    const btn = document.createElement('button');
    btn.textContent = text;
    btn.classList.add(cssClass ?? 'overlay-action-btn');
    btn.addEventListener('click', onClick);
    container.append(btn);
    return btn;
}

/** NPC-Pool-Rendering (aktive Charaktere, die weder in den aktuellen Slots noch in anderen Fahrgemeinschaften sind) */
function buildPoolChips(poolChips, seatSlots, excludeVehNet) {
    poolChips.innerHTML = '';
    const occupied = new Set();
    // NPCs im aktuellen Panel
    if (seatSlots) {
        for (const slot of Object.values(seatSlots)) {
            const chip = slot.querySelector('.driver-edit-chip');
            if (chip) occupied.add(chip.dataset.net);
        }
    }
    // NPCs in anderen aktiven Fahrgemeinschaften
    const allDrivers = memory.driversInfo?.drivers;
    if (allDrivers) {
        for (const [vehNet, passengers] of Object.entries(allDrivers)) {
            if (excludeVehNet != null && String(vehNet) === String(excludeVehNet)) continue;
            if (passengers && typeof passengers === 'object') {
                for (const pedNet of Object.values(passengers)) {
                    occupied.add(String(pedNet));
                }
            }
        }
    }
    (memory.Acharacters ?? []).forEach(char => {
        if (!char) return;
        const net = String(char.networkID);
        if (occupied.has(net)) return;
        poolChips.append(createPoolChip(net, char.skin ?? char.name ?? net, poolChips));
    });
}

// ═══════════════════════════════════════════════════════════════
// Aktive Fahrgemeinschaften
// ═══════════════════════════════════════════════════════════════

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

        const header = document.createElement('div');
        header.classList.add('driver-card-header');
        const vehName = document.createElement('strong');
        vehName.textContent = resolveName(vehNet);
        const netBadge = document.createElement('span');
        netBadge.classList.add('driver-card-net-badge');
        netBadge.textContent = `#${vehNet}`;
        header.append(vehName, netBadge);
        card.append(header);

        if (passengers && typeof passengers === 'object') {
            const chipsRow = document.createElement('div');
            chipsRow.classList.add('driver-card-chips');
            for (const [seat, pedNet] of Object.entries(passengers)) {
                const chip = document.createElement('span');
                chip.classList.add('driver-chip');
                chip.textContent = resolveName(pedNet);
                const tooltip = document.createElement('span');
                tooltip.classList.add('driver-chip-tooltip');
                tooltip.textContent = SEAT_LABELS[seat] ?? `Sitz ${seat}`;
                chip.append(tooltip);
                chipsRow.append(chip);
            }
            card.append(chipsRow);
        }

        const taskInfo = info.driverstask?.[vehNet];
        if (taskInfo) {
            const taskSpan = document.createElement('span');
            const taskType = typeof taskInfo === 'string' ? taskInfo : (taskInfo.type ?? 'NONE');
            taskSpan.textContent = `Task: ${taskType}`;
            if (taskInfo.targetNet) taskSpan.textContent += ` → ${resolveName(taskInfo.targetNet)}`;
            taskSpan.classList.add('overlay-driver-task');
            card.append(taskSpan);
        }

        card.addEventListener('click', () => openEditPanel(vehNet, passengers));
        card.title = 'Klicken zum Bearbeiten';
        container.append(card);
    }
}

// ═══════════════════════════════════════════════════════════════
// Bearbeitungs-Panel (Klick auf aktive Fahrgemeinschaft)
// Kombiniert: Sitze (Drag & Drop) + Task-Auswahl + Ziel
// ═══════════════════════════════════════════════════════════════

function openEditPanel(vehNet, currentPassengers) {
    document.getElementById('driver-edit-panel')?.remove();
    ensureDragListeners();

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

    // ── Sitzplätze ──
    const seatsContainer = document.createElement('div');
    seatsContainer.classList.add('driver-edit-seats');
    const seatTitle = document.createElement('h4');
    seatTitle.textContent = 'Sitzplätze';
    seatsContainer.append(seatTitle);
    const seatSlots = {};
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
        if (pedNet != null) slot.append(createMouseChip(pedNet, resolveName(pedNet)));
        seatSlots[seatKey] = slot;
        seatsContainer.append(slot);
    }
    panel.append(seatsContainer);

    // ── NPC-Pool ──
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

    buildPoolChips(poolChips, seatSlots, vehNet);
    poolChips.addEventListener('pool-refresh', () => buildPoolChips(poolChips, seatSlots, vehNet));

    // ── Task-Sektion ──
    const taskSection = document.createElement('div');
    taskSection.classList.add('driver-edit-task-section');
    const taskTitle = document.createElement('h4');
    taskTitle.textContent = 'Task';
    taskSection.append(taskTitle);

    const taskSelect = document.createElement('select');
    taskSelect.classList.add('overlay-input-field', 'overlay-select');
    TASK_TYPES.forEach(t => {
        const opt = document.createElement('option');
        opt.value = t; opt.textContent = t;
        taskSelect.append(opt);
    });
    // Aktuellen Task vorauswählen
    const curTask = memory.driversInfo?.driverstask?.[vehNet];
    if (curTask) {
        const curType = typeof curTask === 'string' ? curTask : (curTask.type ?? 'NONE');
        taskSelect.value = curType;
    }
    taskSection.append(taskSelect);

    // Ziel-Feld (Drop-Target für Charakter-Chips)
    const targetRow = document.createElement('div');
    targetRow.classList.add('driver-target-drop');
    const targetLabel = document.createElement('label');
    targetLabel.classList.add('overlay-input-label');
    targetLabel.textContent = 'Verfolgungsziel (ESCORT/CHASE)';
    const targetInput = document.createElement('input');
    targetInput.type = 'text';
    targetInput.placeholder = 'Leer = eigener Charakter · NPC hierhin ziehen';
    targetInput.classList.add('overlay-input-field');
    // Aktuelles Target vorbelegen
    if (curTask?.targetNet) targetInput.value = resolveName(curTask.targetNet);
    targetRow.append(targetLabel, targetInput);
    taskSection.append(targetRow);

    panel.append(taskSection);

    // ── Aktions-Button (Speichern = Sitze + Task) ──
    const actions = document.createElement('div');
    actions.classList.add('driver-edit-actions');
    createActionButton(actions, 'Speichern', () => {
        // Fahrer-Sitz darf nicht leer sein
        const driverChip = seatSlots['-1']?.querySelector('.driver-edit-chip');
        if (!driverChip) {
            seatSlots['-1']?.classList.add('driver-slot-error');
            setTimeout(() => seatSlots['-1']?.classList.remove('driver-slot-error'), 1500);
            return;
        }
        const seatMap = {};
        let hasAny = false;
        for (let i = -1; i <= 6; i++) {
            const chip = seatSlots[String(i)]?.querySelector('.driver-edit-chip');
            if (chip) { seatMap[String(i)] = chip.dataset.name; hasAny = true; }
        }
        if (!hasAny) return;
        const vehName = resolveName(vehNet);
        fetchNUI('UI_DriversUpdateSeated', { vehicle: vehName, seatMap });
        const task = taskSelect.value;
        const target = targetInput.value.trim() || null;
        fetchNUI('UI_DriversTask', { vehicle: vehName, task, target });
        closeMenuAfterAction();
    });
    panel.append(actions);

    document.getElementById('overlay-content').append(panel);
    panel.scrollIntoView({ behavior: 'smooth' });
}

// ═══════════════════════════════════════════════════════════════
// Wizard: Neue Fahrgemeinschaft erstellen
// Schritt 1: Fahrzeug per Drag & Drop auswählen
// Schritt 2: Insassen per Drag & Drop zuweisen
// ═══════════════════════════════════════════════════════════════

function openCreateWizard(hostContainer) {
    ensureDragListeners();

    const panel = document.createElement('div');
    panel.id = 'driver-create-wizard';
    panel.classList.add('driver-edit-panel');

    // Header
    const panelHeader = document.createElement('div');
    panelHeader.classList.add('driver-edit-header');
    const title = document.createElement('h3');
    title.textContent = 'Neue Fahrgemeinschaft aus Aktiven';
    const closeBtn = document.createElement('span');
    closeBtn.classList.add('material-icons', 'overlay-close');
    closeBtn.textContent = 'close';
    closeBtn.addEventListener('click', () => {
        panel.remove();
        hostContainer.querySelector('.driver-spawn-inputs')?.classList.remove('hidden');
        hostContainer.querySelector('.driver-spawn-buttons')?.classList.remove('hidden');
    });
    panelHeader.append(title, closeBtn);
    panel.append(panelHeader);

    // ── Schritt-Container ──
    const stepContainer = document.createElement('div');
    stepContainer.id = 'wizard-step-container';
    panel.append(stepContainer);

    renderWizardStep1(stepContainer, panel);

    hostContainer.append(panel);
    panel.scrollIntoView({ behavior: 'smooth' });
}

/** Schritt 1: Fahrzeug auswählen */
function renderWizardStep1(container, panel) {
    container.innerHTML = '';

    const subtitle = document.createElement('h4');
    subtitle.textContent = 'Schritt 1: Fahrzeug wählen';
    container.append(subtitle);

    // Drop-Zone für Fahrzeug
    const dropZone = document.createElement('div');
    dropZone.classList.add('driver-vehicle-drop');
    const display = document.createElement('span');
    display.classList.add('vehicle-drop-display');
    display.textContent = 'Fahrzeug hierhin ziehen';
    dropZone.append(display);
    container.append(dropZone);

    // Verfügbare Fahrzeuge
    const vehPoolTitle = document.createElement('h4');
    vehPoolTitle.textContent = 'Aktive Fahrzeuge';
    container.append(vehPoolTitle);
    const vehPool = document.createElement('div');
    vehPool.classList.add('driver-pool-chips');
    (memory.Avehicles ?? []).forEach(veh => {
        if (!veh) return;
        const net = String(veh.networkID);
        const name = veh.skin ?? veh.name ?? net;
        const chip = createPoolChip(net, name, vehPool);
        vehPool.append(chip);
    });
    container.append(vehPool);

    // Weiter-Button (nach Fahrzeugauswahl aktiviert)
    const nextBtn = createActionButton(container, 'Weiter →', () => {
        if (!dropZone.dataset.selectedName) return;
        renderWizardStep2(container, panel, dropZone.dataset.selectedName, dropZone.dataset.selectedNet);
    });
    nextBtn.classList.add('wizard-next-btn');
    nextBtn.disabled = true;

    dropZone.addEventListener('vehicle-selected', () => { nextBtn.disabled = false; });
}

/** Schritt 2: Insassen zuweisen */
function renderWizardStep2(container, panel, vehicleName) {
    container.innerHTML = '';

    const subtitle = document.createElement('h4');
    subtitle.textContent = `Schritt 2: Insassen für ${vehicleName}`;
    container.append(subtitle);

    // Zurück-Button
    createActionButton(container, '← Fahrzeug ändern', () => renderWizardStep1(container, panel), 'overlay-action-btn-secondary');

    // Sitzplätze
    const seatsContainer = document.createElement('div');
    seatsContainer.classList.add('driver-edit-seats');
    const seatSlots = {};
    for (let i = -1; i <= 6; i++) {
        const seatKey = String(i);
        const slot = document.createElement('div');
        slot.classList.add('driver-edit-slot');
        slot.dataset.seat = seatKey;
        const label = document.createElement('span');
        label.classList.add('driver-edit-slot-label');
        label.textContent = SEAT_LABELS[seatKey] ?? `Sitz ${i}`;
        slot.append(label);
        seatSlots[seatKey] = slot;
        seatsContainer.append(slot);
    }
    container.append(seatsContainer);

    // NPC-Pool
    const poolChips = document.createElement('div');
    poolChips.id = 'driver-pool-chips';
    poolChips.classList.add('driver-pool-chips');
    container.append(poolChips);
    buildPoolChips(poolChips, seatSlots, null);
    poolChips.addEventListener('pool-refresh', () => buildPoolChips(poolChips, seatSlots, null));

    // Erstellen-Button
    const actions = document.createElement('div');
    actions.classList.add('driver-edit-actions');
    createActionButton(actions, 'Fahrgemeinschaft erstellen', () => {
        // Fahrer-Sitz darf nicht leer sein
        const driverChip = seatSlots['-1']?.querySelector('.driver-edit-chip');
        if (!driverChip) {
            seatSlots['-1']?.classList.add('driver-slot-error');
            setTimeout(() => seatSlots['-1']?.classList.remove('driver-slot-error'), 1500);
            return;
        }
        // Flache members-Liste für DriversCreate (Driver zuerst)
        const members = [];
        for (let i = -1; i <= 6; i++) {
            const chip = seatSlots[String(i)]?.querySelector('.driver-edit-chip');
            if (chip) members.push(chip.dataset.name);
        }
        if (!members.length) return;
        fetchNUI('UI_DriversCreate', { vehicle: vehicleName, members });
        // SeatMap nachsenden, damit Sitzpositionen korrekt sind
        const seatMap = {};
        for (let i = -1; i <= 6; i++) {
            const chip = seatSlots[String(i)]?.querySelector('.driver-edit-chip');
            if (chip) seatMap[String(i)] = chip.dataset.name;
        }
        fetchNUI('UI_DriversUpdateSeated', { vehicle: vehicleName, seatMap });
        closeMenuAfterAction();
    });
    container.append(actions);
}

// ═══════════════════════════════════════════════════════════════
// Spawn-Sektion (unverändert, Texteingabe)
// ═══════════════════════════════════════════════════════════════

function renderSpawnSection(container) {
    createSubheading(container, 'Neue Fahrgemeinschaft');

    // Texteingaben (werden bei Wizard-Toggle versteckt)
    const inputsWrapper = document.createElement('div');
    inputsWrapper.classList.add('driver-spawn-inputs');
    const vehicleInput = createInputField(inputsWrapper, 'Fahrzeug / Fahrer', 'Name des Fahrzeugs oder Fahrers');
    const passengersInput = createInputField(inputsWrapper, 'Fahrer & Passagiere', 'z.B. MarionDunby HudsonHudson');
    container.append(inputsWrapper);

    // Button-Reihe: Spawnen (primär) + Neue aus Aktiven (sekundär)
    const btnRow = document.createElement('div');
    btnRow.classList.add('driver-spawn-buttons');
    createActionButton(btnRow, 'Spawnen', () => {
        const vehicle = vehicleInput.value.trim();
        const passengers = passengersInput.value.trim().split(/\s+/).filter(Boolean);
        if (!vehicle) return;
        fetchNUI('UI_SpawnDrivers', { vehicle, passengers });
        closeMenuAfterAction();
    });
    createActionButton(btnRow, '+ Neue aus Aktiven erstellen', () => {
        inputsWrapper.classList.add('hidden');
        btnRow.classList.add('hidden');
        document.getElementById('driver-create-wizard')?.remove();
        openCreateWizard(container);
    }, 'overlay-action-btn-secondary');
    container.append(btnRow);
}

// ═══════════════════════════════════════════════════════════════
// Haupt-Render
// ═══════════════════════════════════════════════════════════════

export function renderDriversOverlay(container) {
    const header = document.createElement('h2');
    header.textContent = 'Fahrgemeinschaften';
    header.classList.add('overlay-section-title');
    container.append(header);

    renderActiveDrivers(container);
    renderSpawnSection(container);
}

export function syncDriversState(driversInfo) {
    if (driversInfo) memory.driversInfo = driversInfo;
}
