--UNTERTITEL DER COMMANDS---

Citizen.CreateThread(function()
	TriggerEvent("chat:addSuggestion", "/cpeds", "Löscht alle vom Spieler kreatierten Charaktere", {})
	TriggerEvent("chat:addSuggestion", "/reskin", "Kleidet alle Charaktere erneut ein. Stichwort, grüne Haare", {})
	TriggerEvent("chat:addSuggestion", "/resync", "Lässt die Einträge vom Server mit allen Clients synchronisieren", {})
	TriggerEvent("chat:addSuggestion", "/SpawnNeutral", "Spawnt den jeweiligen Charakter als neutralen NPC", {
		{ name = "VornameNachname", help = "Den Charakternamen zusammen geschrieben (Gibt Ausnahmen, required)" },
		{ name = "?true",         help = "Ob der Charakter seine Waffe bekommen soll (optional)" },
	})
	TriggerEvent("chat:addSuggestion", "/SpawnBuddy", "Spawnt den jeweiligen Charakter als Bodyguard des Spielers", {
		{ name = "VornameNachname", help = "Den Charakternamen zusammen geschrieben (Gibt Ausnahmen, required)" },
		{ name = "?true",         help = "Ob der Charakter seine Waffe bekommen soll (optional)" },
	})
	TriggerEvent("chat:addSuggestion", "/SpawnGegner", "Spawnt den jeweiligen Charakter als Gegner des Spielers", {
		{ name = "VornameNachname", help = "Den Charakternamen zusammen geschrieben (Gibt Ausnahmen, required)" },
		{ name = "?true",         help = "Ob der Charakter seine Waffe bekommen soll (optional)" },
	})
	TriggerEvent("chat:addSuggestion", "/fraktion", "Spawnt alle Figuren einer Fraktion als Gegner oder Bodyguards", {
		{ name = "Fraktionsname", help = "Name der Fraktion, die man spawnen will (required)" },
		{ name = "Gesinnung",   help = "Freund oder Feind? [buddy]/[gegner] (required)" },
		{ name = "?true",       help = "Ob die Fraktion ihre Waffe bekommen soll (optional)" },
	})

	TriggerEvent("chat:addSuggestion", "/switch", "Wechselt die Kontrolle des Spielers zu einem anderen Charakter", {
		{ name = "VornameNachname", help = "Den Charakternamen zusammen geschrieben (Gibt Ausnahmen, required)" },
	})
	TriggerEvent("chat:addSuggestion", "/cvehicles", "Löscht alle vom Spieler kreatierten Fahrzeuge", {})
	TriggerEvent("chat:addSuggestion", "/drop", "Löscht einen existierenden Charakter oder Fahrzeug anhand dessen Namens",
		{})
end)
