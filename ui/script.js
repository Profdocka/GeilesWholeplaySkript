window.addEventListener("load", (e) => {
    let change = true;
    window.addEventListener("message", e => {
        const data = e.data;

        if (data.type === "cool") {
            if (change == true) {
                document.getElementById("watermark-itself").setAttribute("src", "./images/CorneliusCopperfield.png")
                fetch(`https://${GetParentResourceName()}/UI_PlayerModelSwitch`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: JSON.stringify({
                        characterName: "CorneliusCopperfield"
                    })
                }).then(resp => resp.json()).then(resp => console.log(JSON.stringify(resp)))
            } else {
                document.getElementById("watermark-itself").setAttribute("src", "./images/KussKultLogo.png")
                fetch(`https://${GetParentResourceName()}/UI_PlayerModelSwitch`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: JSON.stringify({
                        characterName: "WilliamMcFred"
                    })
                }).then(resp => resp.json()).then(resp => console.log(JSON.stringify(resp)))

            }
            change = !change
        }
        console.log(JSON.stringify(e.data))
    })
})