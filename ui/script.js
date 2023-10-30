var memory = {};
var isMenuOpen = false

const VEHICLE_VARIANT = -1
const PLAYER_VARIANT = 0
const NEUTRAL_VARIANT = 1
const FRIENDLY_VARIANT = 2
const AGGRESSIVE_VARIANT = 3

window.addEventListener("load", (e) => {
    document.getElementById("gw-menu-screen").hidden = true
    window.addEventListener("message", e => {
        switch (e.data.type) {
            case 'GW_InitialInfos':
                registerSkinsForCharAndVeh(e.data.characterSkins, e.data.vehicleSkins)
                break;
            case 'GW_OpenMenu':
                openGWMenu(e.data);
                break;

        }
    })
    document.getElementById("exit").addEventListener("click", (e) => {
        closeGWMenu();
    })
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

const registerSkinsForCharAndVeh = (characterSkins, vehicleSkins) => {
    memory.characters = sortObjectKeysAlphabetically(characterSkins)
    memory.vehicles = sortObjectKeysAlphabetically(vehicleSkins)
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
        registerActiveData(gwData)
        isMenuOpen = !isMenuOpen
        const domElement = document.getElementById("content-holder")
        memory.characters.forEach(rootskin => {
            addBlock(domElement, rootskin[0], PLAYER_VARIANT)
            rootskin[1].forEach(subskin => {
                addBlock(domElement, subskin, PLAYER_VARIANT)
            })

        });
        memory.vehicles.forEach(rootskin => {
            addBlock(domElement, rootskin[0])
            rootskin[1].forEach(subskin => {
                addBlock(domElement, subskin, VEHICLE_VARIANT)
            })

        });
        document.getElementById("gw-menu-screen").style.display = "flex";
    }
}

const closeGWMenu = () => {
    isMenuOpen = !isMenuOpen
    document.getElementById("gw-menu-screen").style.display = "none";
    let contentHolder = document.getElementById("content-holder").innerHTML = "";
    fetchNUI("UI_CloseMenu", {})
}

const addBlock = (ParentElement, name, variant) => {
    //console.log(name)
    const block = document.createElement('div');
    const textBlock = document.createElement('div')
    const title = document.createElement('span');

    block.classList.add('entity');

    block.addEventListener('click', e => {
        closeGWMenu();
        fetchNUI("UI_SpawnCharacterOrVehicle", {name: name, variant: PLAYER_VARIANT})
    })

    title.innerHTML = name
    //setText(title, name);

    textBlock.append(title);
    block.append(textBlock);

    if (variant === PLAYER_VARIANT) {
        const variantButtons = document.createElement('div')
        const neutralVariantButton = document.createElement('div')
        neutralVariantButton.textContent = "sentiment_neutral";
        const friendlyVariantButton = document.createElement('div')
        friendlyVariantButton.textContent = "sentiment_excited";
        const aggressiveVariantButton = document.createElement('div')
        aggressiveVariantButton.textContent = "sentiment_extremely_dissatisfied";

        addClickEventHandler(neutralVariantButton, "UI_SpawnCharacterOrVehicle", {name: name, variant: NEUTRAL_VARIANT})
        addClickEventHandler(friendlyVariantButton, "UI_SpawnCharacterOrVehicle", {name: name, variant: FRIENDLY_VARIANT})
        addClickEventHandler(aggressiveVariantButton, "UI_SpawnCharacterOrVehicle", {name: name, variant: AGGRESSIVE_VARIANT})

        variantButtons.classList.add('variants')
        neutralVariantButton.classList.add('material-symbols-outlined','variant-neutral')
        friendlyVariantButton.classList.add('material-symbols-outlined','variant-friendly')
        aggressiveVariantButton.classList.add('material-symbols-outlined','variant-aggressive')

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
        console.log(e.target.textContent);
        closeGWMenu();
        fetchNUI(nuiEventName, optionsObject)
    })
}

/*
    <div id="players-section">
    <div id="active-characters-section">
    <div id="active-vehicles-section">
    <div id="character-section">
    <div id="vehicle-section">
*/