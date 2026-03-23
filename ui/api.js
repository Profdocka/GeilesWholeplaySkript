/**
 * api.js – Kommunikationsschicht zwischen der NUI (Browser) und der Lua-Seite.
 * Stellt fetchNUI bereit, das POST-Requests an die FiveM NUI-Callbacks sendet.
 */

/**
 * Sendet einen NUI-Callback an die Lua-Schicht und gibt die JSON-Antwort zurück.
 * @param {string} cbname  Name des registrierten NUI-Callbacks (z.B. "UI_CloseMenu")
 * @param {object} data    Daten, die an den Callback übergeben werden
 * @returns {Promise<object>}
 */
export async function fetchNUI(cbname, data) {
    const options = {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8'
        },
        body: JSON.stringify(data)
    };
    const resp = await fetch(`https://${GetParentResourceName()}/${cbname}`, options);
    return await resp.json();
}
