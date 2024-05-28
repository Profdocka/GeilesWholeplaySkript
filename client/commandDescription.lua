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
	TriggerEvent("chat:addSuggestion", "/gwdropdead", "Löscht alle toten Charaktere und kaputte Fahrzeuge",
		{})
	TriggerEvent("chat:addSuggestion", "/gwlistall", "Listet alle aktiven Charaktere und Fahrzeuge in der Konsole auf",
		{})
	TriggerEvent("chat:addSuggestion", "/gwreskin", "Kleidet alle Charaktere erneut ein. Stichwort, grüne Haare", {})
	TriggerEvent("chat:addSuggestion", "/gwstopall", "Stop alle aktiven Charaktere", {})
	TriggerEvent("chat:addSuggestion", "/gwchangeskin",
		"Schaltet durch die Verkleidungen des Charakters durch", {
			{ name = "?index", help = "Zahlenindex um eine bestimmte Verkleidung zu bekommen. NOT WORKING" },
		})
	TriggerEvent("chat:addSuggestion", "/gwtp",
		"Teleportiert den Spieler zu der Location anhand des zusammengeschriebenen Namens", {
			{ name = "LocationName", help = "Der Name der Location. (required)" }
		})
	TriggerEvent("chat:addSuggestion", "/gwrevievesingle",
		"Erweckt einen toten Charakter wieder zum Leben", {
			{ name = "VornameNachname", help = "Den Namen zusammen geschrieben (Gibt Ausnahmen, required)" },
		})
	TriggerEvent("chat:addSuggestion", "/gwsetoption",
		"Ändere eine persönliche Einstellung bezüglich Aspekten des Skripts", {
			{ name = "Option", help = "Den Namen der zu invertierenden Einstellung" },
		})
	TriggerEvent("chat:addSuggestion", "/gwr", "Lädt deinen aktuellen Charakter neu. Damit folgen dir wieder Bodyguards", {})
	TriggerEvent("chat:addSuggestion", "/gwrandomped", "Gibt dir einen zufälligen Charakter", {})
	TriggerEvent("chat:addSuggestion", "/gwrandomcar", "Gibt dir ein zufälliges Fahrzeug", {})
	TriggerEvent("chat:addSuggestion", "/gwspawnpoint", "Setzt deinen Respawnpunkt auf deine aktuelle Position", {})
	TriggerEvent("chat:addSuggestion", "/gwclearspawnpoint", "Entfernt deinen Respawnpunkt", {})
	TriggerEvent("chat:addSuggestion", "/gwfreunde", "Sorgt dafür das alle Spieler miteinander kooperieren können", {})
	TriggerEvent("chat:addSuggestion", "/gwfeinde", "Sorgt dafür das alle Spieler sich gegenseitig bekriegen können", {})
	TriggerEvent("chat:addSuggestion", "/gwsetownfaction",
	"Ändert die Fraktionszugehörigkeit des eigenen Spielers", {
		{ name = "Fraktionsname", help = "Die Fraktion zu der du wechseln willst. Weglassen zum zurücksetzen" },
	})
end)

RegisterCommand("gwsetoption", function(source, args)
	if args[1] then
		EnableOption(string.lower(args[1]))
	end
end, false)

---Clientseitige Einstellungen können hier ein oder ausgeschaltet werden 
---@param option string
EnableOption = function(option)
	if option == "unbesiegbar" then
		IsInvincible = not IsInvincible
		ShowNotification("Option " .. option .. " wurde geändert auf: " .. BoolToString(IsInvincible))
	elseif option == "formation" then
		WantsFormationSpawn = not WantsFormationSpawn
		ShowNotification("Option " .. option .. " wurde geändert auf: " .. BoolToString(WantsFormationSpawn))
	elseif option == "blips" then
		WantsBlips = not WantsBlips
		ShowNotification("Option " .. option .. " wurde geändert auf: " .. BoolToString(WantsBlips))
	else
		ShowNotification("~r~Es wurde keine entsprechende Option gefunden!")
		return
	end
end

---Ereignis um vom Server aus Client Einstellungen zu ändern
---@param option any
RegisterNetEvent("CEv_SetClientOption",function (option)
	EnableOption(option)
end)