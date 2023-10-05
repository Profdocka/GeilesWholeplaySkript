--UNTERTITEL DER COMMANDS---

Citizen.CreateThread(function()
	TriggerEvent("chat:addSuggestion", "/gwspawnneutral",
		"Spawnt den jeweiligen Charakter neutral gegenüber des Spielers", {
			{ name = "VornameNachname", help = "Den Charakternamen zusammen geschrieben (Gibt Ausnahmen, required)" },
			{ name = "?true",           help = "Ob der Charakter seine Waffe bekommen soll (optional)" },
		})
	TriggerEvent("chat:addSuggestion", "/gwspawnbuddy", "Spawnt den jeweiligen Charakter als Buddy des Spielers", {
		{ name = "VornameNachname", help = "Den Charakternamen zusammen geschrieben (Gibt Ausnahmen, required)" },
		{ name = "?true",           help = "Ob der Charakter seine Waffe bekommen soll (optional)" },
	})
	TriggerEvent("chat:addSuggestion", "/gwspawngegner", "Spawnt den jeweiligen Charakter als Gegner des Spielers", {
		{ name = "VornameNachname", help = "Den Charakternamen zusammen geschrieben (Gibt Ausnahmen, required)" },
		{ name = "?true",           help = "Ob der Charakter seine Waffe bekommen soll (optional)" },
	})
	TriggerEvent("chat:addSuggestion", "/gwspawngruppe", "Spawnt alle Figuren einer Fraktion als Gegner oder Bodyguards",
		{
			{ name = "Fraktionsname", help = "Name der Fraktion, die man spawnen will (required)" },
			{ name = "Gesinnung",     help = "Freund oder Feind? [buddy]/[gegner] (required)" },
			{ name = "?true",         help = "Ob die Fraktion ihre Waffe bekommen soll (optional)" },
		})
	--TriggerEvent("chat:addSuggestion", "/switch", "Wechselt die Kontrolle des Spielers zu einem anderen Charakter", {
	--	{ name = "VornameNachname", help = "Den Charakternamen zusammen geschrieben (Gibt Ausnahmen, required)" },
	--})
	TriggerEvent("chat:addSuggestion", "/gwspawnmycar", "Spawnt das Hauptfahrzeug des eigenen Charakters", {})
	TriggerEvent("chat:addSuggestion", "/gwgesinnungneutral",
		"Ändert die Gesinnung des Charakters zu neutral", {
			{ name = "VornameNachname", help = "Den Namen zusammen geschrieben (Gibt Ausnahmen, required)" },
		})
	TriggerEvent("chat:addSuggestion", "/gwgesinnungbuddy",
		"Ändert die Gesinnung des Charakters zu freundlich", {
			{ name = "VornameNachname", help = "Den Namen zusammen geschrieben (Gibt Ausnahmen, required)" },
		})
	TriggerEvent("chat:addSuggestion", "/gwgesinnunggegner",
		"Ändert die Gesinnung des Charakters zu aggressiv", {
			{ name = "VornameNachname", help = "Den Namen zusammen geschrieben (Gibt Ausnahmen, required)" },
		})
	TriggerEvent("chat:addSuggestion", "/gwdropsingle",
		"Löscht einen existierenden Charakter oder Fahrzeug anhand dessen Namens", {
			{ name = "VornameNachname", help = "Den Namen zusammen geschrieben (Gibt Ausnahmen, required)" },
		})
	TriggerEvent("chat:addSuggestion", "/gwdropallpeds", "Löscht alle vom Spieler kreatierten Charaktere", {})
	TriggerEvent("chat:addSuggestion", "/gwdropallcars", "Löscht alle vom Spieler kreatierten Fahrzeuge", {})
	TriggerEvent("chat:addSuggestion", "/gwdropeverything", "Löscht halt ... alles.", {})
	TriggerEvent("chat:addSuggestion", "/gwlistall", "Listet alle aktiven Charaktere und Fahrzeuge in der Konsole auf",
		{})
	TriggerEvent("chat:addSuggestion", "/gwreskin", "Kleidet alle Charaktere erneut ein. Stichwort, grüne Haare", {})
	TriggerEvent("chat:addSuggestion", "/gwstopall", "Stop alle aktiven Charaktere", {})
	TriggerEvent("chat:addSuggestion", "/gwchangeskin",
		"Schaltet durch die Verkleidungen des Charakters durch", {
			{ name = "?index", help = "Zahlenindex um eine bestimmte Verkleidung zu bekommen. NOT WORKING" },
		})
end)
