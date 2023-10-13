var memory = {};
var isMenuOpen = false

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

const openGWMenu = (gwData) => {
    if (isMenuOpen == true) {
        closeGWMenu();
    }
    else {
        isMenuOpen = !isMenuOpen
        const domElement = document.getElementById("content-holder")
        memory.characters.forEach(rootskin => {
            addBlock(domElement, rootskin[0])
            rootskin[1].forEach(subskin => {
                addBlock(domElement, subskin)
            })

        });
        memory.vehicles.forEach(rootskin => {
            addBlock(domElement, rootskin[0])
            rootskin[1].forEach(subskin => {
                addBlock(domElement, subskin)
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

const addBlock = (ParentElement, name) => {
    //console.log(name)
    const block = document.createElement('div');
    const textBlock = document.createElement('div')
    const title = document.createElement('span');

    block.classList.add('entity');

    block.addEventListener('click', e => {
        console.log(e.target.textContent);
        closeGWMenu();
        fetchNUI("UI_SpawnCharacterOrVehicle", {name: e.target.textContent})
    })

    title.innerHTML = name
    //setText(title, name);

    textBlock.append(title);
    block.append(textBlock);
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