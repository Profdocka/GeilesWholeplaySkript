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

window.addEventListener("load", (e) => {
    document.getElementById("gw-menu-screen").hidden = true
    window.addEventListener("message", e => {
        switch (e.data.type) {
            case 'GW_InitialInfos':
                registerSkinsForCharAndVeh(e.data)
                break;
            case 'GW_OpenMenu':
                playerName = e.data.playerName;
                openGWMenu(e.data);
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

const registerSkinsForCharAndVeh = (data) => {
    memory.characters = sortObjectKeysAlphabetically(data.characterSkins)
    memory.vehicles = sortObjectKeysAlphabetically(data.vehicleSkins)
    memory.factions = Object.keys(data.allFactions)
    memory.myVehicles = data.myVehicles
    //console.log(memory.characters)
    //console.log(memory.vehicles)
    //console.log(memory)
    //console.log(memory);
}

const registerActiveData = (gwData) => {
    memory.players = gwData.players
    memory.Acharacters = gwData.characters
    memory.Avehicles = gwData.vehicles
}

const openGWMenu = (gwData) => {
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
    const textBlock = document.createElement('div')
    const title = document.createElement('span');

    block.classList.add('entity');

    if (variant === PLAYER_VARIANT || variant === VEHICLE_VARIANT) {
        block.addEventListener('click', e => {
            closeGWMenu();
            fetchNUI(gameEvent, { name: name, variant: variant })
        })
    }

    title.innerHTML = name
    //setText(title, name);

    textBlock.append(title);
    block.append(textBlock);

    if (variant === PLAYER_VARIANT || variant === GROUP_VARIANT) {
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

        block.append(variantButtons)
    }

    ParentElement.appendChild(block);
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
                break;
            case "MeineFahrzeuge":
                createSectionLine(contentHolder, tabVariant);
                let lowerName = playerName.toLowerCase();
                //console.log("Der Owner: ", lowerName);
                //console.log(memory.myVehicles[lowerName]);

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
    if (memory.characters != null && isGoodToGo) {
        return true
    } else if(isGoodToGo == false) {
        return false
    } else {
        isGoodToGo = false;
        fetchNUI("UI_RequestMenuData", {});
        setTimeout(() => isGoodToGo = true, 5000);
        return false;
    }
}


/*
    <div id="players-section">
    <div id="active-characters-section">
    <div id="active-vehicles-section">
    <div id="character-section">
    <div id="vehicle-section">
*/