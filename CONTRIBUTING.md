# Beitragen / Contributing

Danke für dein Interesse am Geilen Wholeplay Skript! Hier erfährst du, wie du neue Inhalte hinzufügen kannst.

> **English speakers:** This guide is in German. The key points: follow PascalCase naming conventions, use the JSON schemas shown below, and note that all creative content (character names, lore) is copyrighted by the Kuss Kult Kurator.

---

## Neuen Charakter hinzufügen

1. Erstelle eine JSON-Datei in `characters/` mit dem Namen `VornameNachname.json` (z.B. `WilliamMcFred.json`)
2. Exportiere den Ped aus **Menyoo Spooner** oder erstelle die JSON manuell
3. Wichtige Felder:

```json
{
  "OutfitPedData": {
    "ModelHash": "1885233650",
    "PedProperties": {
      "PedComps": { ... },
      "PedProps": { ... },
      "HeadFeatures": { ... },
      "Weapon": "weapon_pistol_mk2",
      "WalkStyle": null,
      "Voice": null
    }
  }
}
```

### Skin-Variante erstellen

Für alternative Outfits eines bestehenden Charakters:

1. Datei benennen als `VornameNachnameSuffix.json` (z.B. `WilliamMcFredParty.json`)
2. Das Feld `"IsSkinOf"` hinzufügen, das auf den Basis-Charakter verweist:

```json
{
  "OutfitPedData": {
    "ModelHash": "1885233650",
    "IsSkinOf": "WilliamMcFred",
    ...
  }
}
```

---

## Neues Fahrzeug hinzufügen

1. Erstelle eine JSON-Datei in `vehicles/` mit dem Namen `NachnameFahrzeugmodell.json` (z.B. `McFredsTornado.json`)
2. Exportiere das Fahrzeug aus **Menyoo Spooner** oder erstelle die JSON manuell
3. Wichtige Felder:

```json
{
  "Vehicle": {
    "ModelHash": "1531094468",
    "VehicleProperties": {
      "Colours": { ... },
      "NumberPlateText": "MCFRED",
      "Neons": { ... },
      "Mods": { ... }
    }
  }
}
```

4. Wenn das Fahrzeug einem Charakter gehört, trage es in `server/ownersOfVehicles.lua` ein

---

## Neues Diorama erstellen

Am einfachsten im Spiel:

1. Spawne alle gewünschten Charaktere und Fahrzeuge und positioniere sie
2. Führe `/gwsavediorama dioramaname` aus
3. Die Datei wird automatisch als `dioramas/dioramaname.json` gespeichert

Manuelles Format:

```json
{
  "characters": [
    {
      "name": "WilliamMcFred",
      "faction": "CHAOS",
      "weapon": true,
      "vector4": { "coords": { "x": 0.0, "y": 0.0, "z": 0.0 }, "heading": 0.0 }
    }
  ],
  "vehicles": [
    {
      "name": "McFredsTornado",
      "vector4": { "coords": { "x": 0.0, "y": 0.0, "z": 0.0 }, "heading": 0.0 }
    }
  ]
}
```

---

## Benennungskonventionen

| Typ | Format | Beispiel |
|---|---|---|
| Charakter | `VornameNachname` | `WilliamMcFred` |
| Skin-Variante | `VornameNachnameSuffix` | `WilliamMcFredParty` |
| Fahrzeug | `NachnameFahrzeugmodell` | `McFredsTornado` |
| Diorama | `kleingeschrieben` | `mcfredag` |

Alle Namen sind **PascalCase** (Großbuchstabe bei jedem neuen Wort), zusammengeschrieben, ohne Leerzeichen.

---

## Hinweis zum Urheberrecht

Der **Quellcode** steht unter der MIT License und darf frei verwendet werden. Alle **kreativen Inhalte** (Charakternamen, Ortsnamen, Fraktionen, Logos, Lore des Kuss Kult Universums) sind urheberrechtlich geschützt durch den **Kuss Kult Kurator**. Siehe [LICENSE](LICENSE) für Details.
