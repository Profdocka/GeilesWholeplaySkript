var memory = {};
var isMenuOpen = false;
var playerName = "";
isGoodToGo = true

const VEHICLE_VARIANT = -1
const PLAYER_VARIANT = 0
const NEUTRAL_VARIANT = 1
const FRIENDLY_VARIANT = 2
const AGGRESSIVE_VARIANT = 3
const GROUP_VARIANT = 4
const LOCATION_VARIANT = 5

window.addEventListener("load", (e) => {
    document.getElementById("gw-menu-screen").hidden = true
    window.addEventListener("message", async e => {
        switch (e.data.type) {
            case 'GW_InitialInfos':
                await registerSkinsForCharAndVeh(e.data)
                break;
            case 'GW_OpenMenu':
                if (isGoodToGo) {
                    playerName = e.data.playerName;
                    await openGWMenu(e.data);
                }
                break;


        }
    })
    document.getElementById("exit").addEventListener("click", (e) => {
        closeGWMenu();
    })
    addClickEventHandler(document.getElementById("mycar"), "UI_SpawnMyCar", {})
    optionsContainerButtons();
})

document.getElementById('search-bar').addEventListener('input', e => {
    let input = e.target.value.toUpperCase();
    const panels = document.getElementsByClassName('entity');
    for (let i = 0; i < panels.length; i++) {
        let text = panels[i].getElementsByTagName('div')[0].firstChild
        let val = text.textContent || text.innerText;
        if (val.toUpperCase().indexOf(input) > -1) {
            panels[i].style.display = "";
        } else {
            text = panels[i].getElementsByTagName('div')[0].lastChild
            val = text.textContent || text.innerText;
            if (val.toUpperCase().indexOf(input) > -1) {
                panels[i].style.display = "";
            } else {
                panels[i].style.display = "none";
            }
        }
    }
})

// Fokus auf das Suchfeld setzen, wenn die Taste "F" gedrückt wird
document.addEventListener("keydown", function (event) {
    const searchbar = document.getElementById("search-bar");
    if (event.key === "Escape") {
        closeGWMenu();
    }
    else if (event.key === "f" && document.activeElement !== searchbar) {
        event.preventDefault(); // Verhindert, dass "F" im Textfeld erscheint
        searchbar.focus();
    }
});

const fetchNUI = async (cbname, data) => {
    const options = {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(data)
    };
    const resp = await fetch(`https://${GetParentResourceName()}/${cbname}`, options);
    return await resp.json();
};

const registerSkinsForCharAndVeh = async (data) => {
    memory.characters = sortObjectKeysAlphabetically(data.characterSkins)
    memory.vehicles = sortObjectKeysAlphabetically(data.vehicleSkins)
    memory.factions = Object.keys(data.allFactions)
    memory.locations = Object.keys(data.locations).sort();
    memory.locationsObjects = data.locations
    memory.myVehicles = data.myVehicles
    //console.log(memory.characters)
    //console.log(memory.vehicles)
    //console.log(memory)
    //console.log(memory);
}

const registerActiveData = (gwData) => {
    memory.players = Object.values(gwData.players);
    memory.Acharacters = Object.values(gwData.characters);
    memory.Avehicles = Object.values(gwData.vehicles);
}

const openGWMenu = async (gwData) => {
    if (isMenuOpen == true) {
        closeGWMenu();
    }
    else {
        if (isMenuDataFunctional()) {
            registerActiveData(gwData)
            isMenuOpen = !isMenuOpen
            addEveryEntity();
        }
    }
}

const addEveryEntity = () => {
    const domElement = document.getElementById("content-holder");
    addActiveSection(domElement);
    createSectionLine(domElement, "Charaktere");
    memory.characters.forEach(rootskin => {
        addBlock(domElement, rootskin[0], PLAYER_VARIANT, "UI_SpawnCharacterOrVehicle")
        rootskin[1].forEach(subskin => {
            addBlock(domElement, subskin, PLAYER_VARIANT, "UI_SpawnCharacterOrVehicle")
        })

    });
    createSectionLine(domElement, "Fahrzeuge");
    memory.vehicles.forEach(rootskin => {
        addBlock(domElement, rootskin[0], VEHICLE_VARIANT, "UI_SpawnCharacterOrVehicle")
        rootskin[1].forEach(subskin => {
            addBlock(domElement, subskin, VEHICLE_VARIANT, "UI_SpawnCharacterOrVehicle")
        })
    });
    createSectionLine(domElement, "Fraktionen");
    memory.factions.forEach(faction => {
        addBlock(domElement, faction, GROUP_VARIANT, "UI_SpawnGroup")
    })
    createSectionLine(domElement, "Locations");
    memory.locations.forEach(location => {
        addBlock(domElement, location, LOCATION_VARIANT, "UI_Teleport")
    })
    document.getElementById("gw-menu-screen").style.display = "flex";
}

const closeGWMenu = () => {
    isMenuOpen = !isMenuOpen
    document.getElementById("gw-menu-screen").style.display = "none";
    let contentHolder = document.getElementById("content-holder").innerHTML = "";
    fetchNUI("UI_CloseMenu", {})
}

const addBlock = (ParentElement, name, variant, gameEvent) => {
    //console.log(name)
    const block = document.createElement('div');
    const textBlock = document.createElement('div');
    const logospace = document.createElement('div');
    const title = document.createElement('span');

    block.classList.add('entity');
    colorBlocksAccordingly(block, variant);

    if (variant === PLAYER_VARIANT || variant === VEHICLE_VARIANT) {
        block.addEventListener('click', e => {
            closeGWMenu();
            fetchNUI(gameEvent, { name: name, variant: variant })
        })
    }

    title.innerHTML = name
    //setText(title, name);

    if (variant === LOCATION_VARIANT) {
        if (memory.locationsObjects[name].isInterior == true) {
            logospace.classList.add('material-icons');
            logospace.style.color = "white";
            logospace.innerHTML = "home";
            block.append(logospace);
        }
        block.addEventListener('click', (e) => {
            closeGWMenu();
            fetchNUI(gameEvent, { name: name })
        })
    }

    textBlock.append(title);
    block.append(textBlock);

    if (variant === PLAYER_VARIANT || variant === GROUP_VARIANT) {
        let variantButtons = variantButtonRow(gameEvent, name)
        block.append(variantButtons)
    }



    ParentElement.appendChild(block);
}

function addActiveBlock(parentElement, options) {
    const block = document.createElement('div');
    const textBlock = document.createElement('div');
    const title = document.createElement('span');
    const subtitle = document.createElement('span');
    const footer = document.createElement('span');

    block.classList.add('entity');
    //textBlock.classList.add('entity');
    colorBlocksAccordingly(block, options.variant);

    if (options.variant === VEHICLE_VARIANT || options.variant === NEUTRAL_VARIANT) {
        addClickEventHandler(block, options.gameEvent, options)
    }

    textBlock.classList.add('active-info-text');
    title.innerHTML = options.name
    textBlock.append(title);

    let optionsButtons = document.createElement('div');

    if (options.variant === PLAYER_VARIANT || options.variant === NEUTRAL_VARIANT) {
        subtitle.innerHTML = "Fraktion: " + options.faction;
        subtitle.classList.add('active-info-text-faction');
        textBlock.append(subtitle);
        if (options.variant === PLAYER_VARIANT) {
            footer.innerHTML = options.playerName;
            footer.classList.add('active-info-text', 'active-info-text-player-name');
            textBlock.append(footer);
        } else {
            optionsButtons = variantButtonRow("UI_ChangeAttitude", options.name);
        }
    }

    if (options.variant === VEHICLE_VARIANT || options.variant === NEUTRAL_VARIANT) {
        const trashCanButton = document.createElement('div');
        trashCanButton.textContent = "delete";

        addClickEventHandler(trashCanButton, "UI_DeleteEntity", options);

        trashCanButton.classList.add('material-symbols-outlined', 'variant-aggressive');
        optionsButtons.append(trashCanButton);

        optionsButtons.classList.add('variants');
    }
    block.append(textBlock);
    block.append(optionsButtons);
    parentElement.appendChild(block);
}

function sortObjectKeysAlphabetically(obj) {
    const sortedEntries = Object.entries(obj).sort(([keyA], [keyB]) => keyA.localeCompare(keyB));
    const sortedObj = {};
    for (const [key, value] of sortedEntries) {
        sortedObj[key] = value;
    }
    return Object.entries(sortedObj);
}

function addClickEventHandler(recievingObject, nuiEventName, optionsObject) {
    recievingObject.addEventListener('click', e => {
        e.stopPropagation();
        //console.log(e.target.textContent);
        closeGWMenu();
        fetchNUI(nuiEventName, optionsObject)
    })
}

function createSectionLine(parentElement, sectionText) {
    const section = document.createElement('div');
    section.classList.add("custom-hr");

    const text = document.createElement('div');
    text.textContent = sectionText

    section.append(text);

    parentElement.append(section);
}

function optionsContainerButtons() {
    const homeTab = document.getElementById("homeTab");
    const characterTab = document.getElementById("characterTab");
    const vehicleTab = document.getElementById("vehicleTab");
    const factionTab = document.getElementById("factionTab");
    const locationTab = document.getElementById("locationTab");
    const myVehiclesTab = document.getElementById("myVehiclesTab");

    optionsContainerButtonHandler(homeTab, "Everything");
    optionsContainerButtonHandler(characterTab, "Charaktere");
    optionsContainerButtonHandler(vehicleTab, "Fahrzeuge");
    optionsContainerButtonHandler(factionTab, "Fraktionen");
    optionsContainerButtonHandler(locationTab, "Locations");
    optionsContainerButtonHandler(myVehiclesTab, "MeineFahrzeuge");

}

function variantButtonRow(gameEvent, name) {
    const variantButtons = document.createElement('div')
    const neutralVariantButton = document.createElement('div')
    neutralVariantButton.textContent = "sentiment_neutral";
    const friendlyVariantButton = document.createElement('div')
    friendlyVariantButton.textContent = "sentiment_excited";
    const aggressiveVariantButton = document.createElement('div')
    aggressiveVariantButton.textContent = "sentiment_extremely_dissatisfied";

    addClickEventHandler(neutralVariantButton, gameEvent, { name: name, variant: NEUTRAL_VARIANT })
    addClickEventHandler(friendlyVariantButton, gameEvent, { name: name, variant: FRIENDLY_VARIANT })
    addClickEventHandler(aggressiveVariantButton, gameEvent, { name: name, variant: AGGRESSIVE_VARIANT })

    variantButtons.classList.add('variants')
    neutralVariantButton.classList.add('material-symbols-outlined', 'variant-neutral')
    friendlyVariantButton.classList.add('material-symbols-outlined', 'variant-friendly')
    aggressiveVariantButton.classList.add('material-symbols-outlined', 'variant-aggressive')

    variantButtons.append(neutralVariantButton);
    variantButtons.append(friendlyVariantButton);
    variantButtons.append(aggressiveVariantButton);

    return variantButtons
}

function optionsContainerButtonHandler(recievingObject, tabVariant) {
    recievingObject.addEventListener("click", e => {
        e.stopPropagation();
        const contentHolder = document.getElementById("content-holder");
        contentHolder.innerHTML = "";
        switch (tabVariant) {
            case "Everything":
                addEveryEntity();
                break;
            case "Charaktere":
                createSectionLine(contentHolder, tabVariant);
                memory.characters.forEach(rootskin => {
                    addBlock(contentHolder, rootskin[0], PLAYER_VARIANT, "UI_SpawnCharacterOrVehicle")
                    rootskin[1].forEach(subskin => {
                        addBlock(contentHolder, subskin, PLAYER_VARIANT, "UI_SpawnCharacterOrVehicle")
                    })
                });
                break;
            case "Fahrzeuge":
                createSectionLine(contentHolder, tabVariant);
                memory.vehicles.forEach(rootskin => {
                    addBlock(contentHolder, rootskin[0], VEHICLE_VARIANT, "UI_SpawnCharacterOrVehicle")
                    rootskin[1].forEach(subskin => {
                        addBlock(contentHolder, subskin, VEHICLE_VARIANT, "UI_SpawnCharacterOrVehicle")
                    })
                });
                break;
            case "Fraktionen":
                createSectionLine(contentHolder, tabVariant);
                memory.factions.forEach(faction => {
                    addBlock(contentHolder, faction, GROUP_VARIANT, "UI_SpawnGroup")
                })
                break;
            case "Locations":
                createSectionLine(contentHolder, tabVariant);
                memory.locations.forEach(location => {
                    addBlock(contentHolder, location, LOCATION_VARIANT, "UI_Teleport")
                })
                break;
            case "MeineFahrzeuge":
                createSectionLine(contentHolder, tabVariant);
                let lowerName = playerName.toLowerCase();
                console.log("Der Owner: ", lowerName);
                console.log(memory.myVehicles[lowerName]);

                if (memory.myVehicles[lowerName] != undefined) {
                    memory.myVehicles[lowerName].forEach(vehicle => {
                        addBlock(contentHolder, vehicle, VEHICLE_VARIANT, "UI_SpawnCharacterOrVehicle")
                    });
                }
                break;
        }
    })
}

function isMenuDataFunctional() {
    if (memory.characters != null && memory.myVehicles != null && isGoodToGo) {
        return true
    } else if (isGoodToGo == false) {
        return false
    } else {
        isGoodToGo = false;
        fetchNUI("UI_RequestMenuData", {});
        setTimeout(() => isGoodToGo = true, 5000);
        return false;
    }
}

function colorBlocksAccordingly(block, variant) {
    switch (variant) {
        case VEHICLE_VARIANT:
            block.classList.add('entity-vehicle');
            break;
        case GROUP_VARIANT:
            block.classList.add('entity-group');
            break;
        case LOCATION_VARIANT:
            block.classList.add('entity-location');
            break;
        default:
            break;
    }
}

function addActiveSection(domElement) {
    const contentHolder = domElement;
    createSectionLine(contentHolder, "Aktive");
    memory.players.forEach(player => {
        //addBlock(contentHolder, , GROUP_VARIANT, "UI_SpawnGroup")
        if (player != null) {
            player.networkID = networkIDWasNotFoundReplace(player.networkID)
            let options = { variant: PLAYER_VARIANT, networkID: player.networkID, name: player.skin, faction: player.faction, playerName: player.playerName, gameEvent: "UI_TeleportToPlayer" }
            addActiveBlock(contentHolder, options)
        }
    })
    memory.Acharacters.forEach(character => {
        if (character != null) {
            character.networkID = networkIDWasNotFoundReplace(character.networkID)
            let options = { variant: NEUTRAL_VARIANT, networkID: character.networkID, name: character.skin, faction: character.faction, gameEvent: "UI_RelocateCharacter" }
            addActiveBlock(contentHolder, options)
        }
    })
    memory.Avehicles.forEach(vehicle => {
        if (vehicle != null) {
            vehicle.networkID = networkIDWasNotFoundReplace(vehicle.networkID)
            let options = { variant: VEHICLE_VARIANT, networkID: vehicle.networkID, name: vehicle.skin, gameEvent: "UI_RelocateVehicle" }
            addActiveBlock(contentHolder, options)
        }
    })
}

function networkIDWasNotFoundReplace(networkID) {
    if (networkID == null || networkID == undefined) {
        networkID = 0
    }
    return networkID
}

/*
    <div id="players-section">
    <div id="active-characters-section">
    <div id="active-vehicles-section">
    <div id="character-section">
    <div id="vehicle-section">
*/