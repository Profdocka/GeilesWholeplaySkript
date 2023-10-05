Owners = {
	williammcfred = {
		"McFredsTornado",
		"McFredsHelikopter",
		"McFredsHyperjet",
		"McFredsKITT",
		"McFredsAlterTornado"
	},
	igorscrubs = {
		"ScrubsPigalle"
	},
	omaroswita = {
		"OmaRoswitasBus"
	}
}

--Owners.alfonsvonschändler = {}
--Owners.amandagoingnorth = {}
Owners.andremiller = { "MillersBison" }
Owners.antoniaglatzkopf = { "GlatzkopfsNeon" }
Owners.apuali = { "AlisKalahani" }
Owners.arnoldpinbin = { "PinbinsDiamond" }
Owners.bensonbotrob = { "BotrobsMesa" }
--Owners.betzifrecher = {}
Owners.bobobarney = { "ObarneysWindsor" }
--Owners.brutusbermudez = {}
--Owners.burghardt = {}
Owners.carlosgonsalez = { "GonsalezTruck" }
--Owners.chestermcnut = {}
--Owners.chetdinhduc = {}
--Owners.clarktimberway = {}
--Owners.cleveland = {}
Owners.corneliuscopperfield = { "CopperfieldsStirling", "CopperfieldsFIB" }
Owners.dimitrismirnov = { "SmirnovsVan" }
Owners.douglessdunes = { "DunesEmperor", "DunesVolatus", "DunesZType", "DunesBuzzard" }
--Owners.eilertoberst = {}
--Owners.elvarparkers = {}
--Owners.ericguinabonn = {}
Owners.eugenegoverneuer = { "GoverneuersChino", "GoverneuersValkurie" }
--Owners.executor = {}
Owners.floydflemming = { "FlemmingsMaverick" }
Owners.frankfries = { "FriesDilletante" }
--Owners.fredellinefrecher = {}
--Owners.fredfrecher = {}
Owners.glatziglatzkopf = { "GlatzkopfsImpaler" }
Owners.glatziglatzkopflab = { "GlatzkopfsImpaler" }
--Owners.gorgewashmashington = {}
Owners.gregorygregelton = { "GregeltonsCognoscenti" }
--Owners.gustavogusto = {}
--Owners.haroldharrington = {}
Owners.hawlett = { "OmaRoswitasBus" }
Owners.herbertgoverneur = { "GoverneuersValkurie" }
--Owners.herrschröder = {}
Owners.hooliganhoppelkinn = { "HopkinsDubsta" }
Owners.hudsonhudson = { "HudsonsCruiser", "HudsonsWarrener" }
--Owners.hunterhotwire = {}
Owners.igorscrubs = {"ScrubsPigalle"}
Owners.joesephfrecher = { "FrechersBobcat", "FrechersFieldmaster" }
--Owners.johnjjcranford = {}
Owners.karlkarlson = { "KarlsonsGlendale" }
--Owners.kennycueguard = {}
Owners.konstantinscrubs = { "ScrubsFagaloa" }
--Owners.laolilin = {}
--Owners.laophongtau = {}
Owners.lester = { "LestersAsea", "LestersTruck" }
Owners.lipinghuan = { "LisCocoto" }
Owners.ludmillaleuvenia = { "LeuveniasSurano" }
Owners.mariondunby = { "DunbysCruiser", "DunbysGranger" }
Owners.marioseuchler = { "SeuchlersKrankenwagen" }
--Owners.martawrack = {}
Owners.maryannfrecher = { "FrechersBobcat" }
Owners.melanieparkers = { "ParkersPolicebike", "ParkersSurge" }
Owners.michaelgoingnorth = { "MichaelsTailgater" }
Owners.michaelmarty = { "MichaelsTailgater" }
Owners.nehadhussein = { "HusseinsStallion" }
Owners.nestornewton = { "NewtonsJetpack" }
--Owners.nigelhavock = {}
Owners.omaroswita = {"OmaRoswitasBus"}
Owners.ottokoeder = { "MSBirdseye" }
Owners.pammeladummigton = { "DummigtonsCoquette" }
Owners.patpaddington = { "PaddingtonsRiot" }
Owners.patrickpeddo = { "Peddobil" }
Owners.prestonkussbeard = { "KussbeardsVoodoo" }
Owners.rainerrechtsruck = { "TVTotalEgalVan" }
Owners.ralphhopkins = { "HopkinsDubsta" }
--Owners.reedmiller = {}
Owners.rhodiklil = { "KlilsVoltic" }
--Owners.robertaklil = {}
Owners.ronnyrabbit = { "RabbitsEsskey", "RabbitsTruck" }
--Owners.rudirogers = {}
--Owners.scottgulldige = {}
--Owners.seanmcfred = {}
--Owners.shermanshepherd = {}
Owners.siegfriedmcfred = { "McFredsRoosevelt" }
--Owners.tanteesmeralda = {}
--Owners.taxifahrer = {}
Owners.timmytimelton = { "TimeltonsIssi", "TimeltonsFahrrad" }
Owners.tysondoorhound = { "DoorhoundsSanctus" }
Owners.udowarndt = { "WarndtsGolf" }
Owners.uwestroehbaecker = { "WuffDuster" }
--Owners.viktorraswinova = {}
Owners.vincentvicente = { "VicentesTyrant" }
Owners.vladimirsmirnov = { "SmirnovsAbschleppwagen" }
Owners.wernerwrack = { "WracksStafford", "WracksYacht" }
Owners.williammcfred = { "McFredsTornado", "McFredsHelikopter",	"McFredsHyperjet", "McFredsKITT", "McFredsAlterTornado" }
--Owners.willihammcfett = {}
Owners.williwagner = { "McFredsSupersportwagen", "PRIUS" }
--Owners.winfriedmcfred = {}
Owners.wolfgangwuergenknecht = { "TVTotalEgalVan" }
Owners.zumian = { "Zumianmobile", "ZumiansVelum" }


ReplaceUmlaute = function(str)
	local tableAccents = {}
	tableAccents["À"] = "A"
	tableAccents["Á"] = "A"
	tableAccents["Â"] = "A"
	tableAccents["Ã"] = "A"
	tableAccents["Ä"] = "Ae"
	tableAccents["Å"] = "A"
	tableAccents["Æ"] = "AE"
	tableAccents["Ç"] = "C"
	tableAccents["È"] = "E"
	tableAccents["É"] = "E"
	tableAccents["Ê"] = "E"
	tableAccents["Ë"] = "E"
	tableAccents["Ì"] = "I"
	tableAccents["Í"] = "I"
	tableAccents["Î"] = "I"
	tableAccents["Ï"] = "I"
	tableAccents["Ð"] = "D"
	tableAccents["Ñ"] = "N"
	tableAccents["Ò"] = "O"
	tableAccents["Ó"] = "O"
	tableAccents["Ô"] = "O"
	tableAccents["Õ"] = "O"
	tableAccents["Ö"] = "Oe"
	tableAccents["Ø"] = "O"
	tableAccents["Ù"] = "U"
	tableAccents["Ú"] = "U"
	tableAccents["Û"] = "U"
	tableAccents["Ü"] = "Ue"
	tableAccents["Ý"] = "Y"
	tableAccents["Þ"] = "P"
	tableAccents["ß"] = "s"
	tableAccents["à"] = "a"
	tableAccents["á"] = "a"
	tableAccents["â"] = "a"
	tableAccents["ã"] = "a"
	tableAccents["ä"] = "ae"
	tableAccents["å"] = "a"
	tableAccents["æ"] = "ae"
	tableAccents["ç"] = "c"
	tableAccents["è"] = "e"
	tableAccents["é"] = "e"
	tableAccents["ê"] = "e"
	tableAccents["ë"] = "e"
	tableAccents["ì"] = "i"
	tableAccents["í"] = "i"
	tableAccents["î"] = "i"
	tableAccents["ï"] = "i"
	tableAccents["ð"] = "eth"
	tableAccents["ñ"] = "n"
	tableAccents["ò"] = "o"
	tableAccents["ó"] = "o"
	tableAccents["ô"] = "o"
	tableAccents["õ"] = "o"
	tableAccents["ö"] = "oe"
	tableAccents["ø"] = "o"
	tableAccents["ù"] = "u"
	tableAccents["ú"] = "u"
	tableAccents["û"] = "u"
	tableAccents["ü"] = "ue"
	tableAccents["ý"] = "y"
	tableAccents["þ"] = "p"
	tableAccents["ÿ"] = "y"

	local normalisedString = ''

	normalisedString = str:gsub("[%z\1-\127\194-\244][\128-\191]*", tableAccents)

	return normalisedString
end
