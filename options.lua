local folder, core = ...

if not core.LibNameplates then return end

local MSQ = core.MSQ or LibStub("LibButtonFacade", true) or LibStub("Masque", true)
core.MSQ = MSQ

local LSM = core.LSM or LibStub("LibSharedMedia-3.0", true)
core.LSM = LSM

--Globals
local _G = _G
local pairs = pairs
local table_insert = table.insert
local table_sort = table.sort
local table_getn = table.getn
local tonumber = tonumber
local GetSpellInfo = GetSpellInfo
local select = select
local GetAddOnMetadata = GetAddOnMetadata

core.tooltip = core.tooltip or CreateFrame("GameTooltip", folder .. "Tooltip", UIParent, "GameTooltipTemplate")
local tooltip = core.tooltip
tooltip:Show()
tooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- local
local spellIDs = {}

local L = core.L or LibStub("AceLocale-3.0"):GetLocale(folder, true)

local P = {}
local prev_OnEnable = core.OnEnable
function core:OnEnable()
	P = self.db.profile
	prev_OnEnable(self)
	P = self.db.profile
end

local defaultSettings = core.defaultSettings.profile

defaultSettings.defaultBuffShow = 3
defaultSettings.defaultDebuffShow = 3
defaultSettings.showInterrupts = true
defaultSettings.abovePlayers = true
defaultSettings.aboveNPC = true
defaultSettings.aboveFriendly = true
defaultSettings.aboveNeutral = true
defaultSettings.aboveHostile = true
defaultSettings.watchCombatlog = true
defaultSettings.saveNameToGUID = true
defaultSettings.unknownSpellDataIcon = false
defaultSettings.blacklistTotems = true
defaultSettings.playerCombatWithOnly = false
defaultSettings.npcCombatWithOnly = false
defaultSettings.targetOnly = false

defaultSettings.barAnchorPoint = "BOTTOM"
defaultSettings.plateAnchorPoint = "TOP"
defaultSettings.barOffsetX = 0
defaultSettings.barOffsetY = -2
defaultSettings.iconsPerBar = 4
defaultSettings.numBars = 3
defaultSettings.intervalX = 4
defaultSettings.intervalY = 4
defaultSettings.barGrowth = 1
defaultSettings.shrinkBar = true
defaultSettings.showBarBackground = false

defaultSettings.iconSize = 28
defaultSettings.iconSize2 = 28
defaultSettings.textureSize = 0
defaultSettings.biggerSelfSpells = false
defaultSettings.borderTexture = "Interface\\AddOns\\SkomsPlateBuffs\\media\\DefaultBorder.blp"
defaultSettings.borderTextureBuff = "Interface\\AddOns\\SkomsPlateBuffs\\media\\DefaultBorder.blp"
defaultSettings.colorByType = true
defaultSettings.borderColorMode = "type"                        -- type (physical, magic, ...), category, custom
defaultSettings.borderCustomColor = { 0.12, 0.12, 0.12, 1 }     -- the dark look
defaultSettings.dispelGlow = true                              -- glow on Magic buffs the player's class can dispel
defaultSettings.dispelGlowScope = "other"                       -- other (Other buffs) or all (every buff but immunities)
defaultSettings.dispelGlowType = "pixel"
defaultSettings.dispelGlowColor = { 0.75, 0.4, 1 }
defaultSettings.glowColorMode = "default"                       -- default (native yellow), type, category
defaultSettings.color1 = {0.80, 0.00, 0.00, 1.00}
defaultSettings.color2 = {0.20, 0.60, 1.00, 1.00}
defaultSettings.color3 = {0.60, 0.00, 1.00, 1.00}
defaultSettings.color4 = {0.60, 0.40, 0.00, 1.00}
defaultSettings.color5 = {0.00, 0.60, 0.00, 1.00}
defaultSettings.color6 = {0.83, 0.83, 0.83, 1.00}
defaultSettings.cooldownSize = 11
defaultSettings.stackSize = 8
defaultSettings.showCooldown = true
defaultSettings.cdAnchor = "CENTER"
defaultSettings.cdOffsetX = 0
defaultSettings.cdOffsetY = 0
defaultSettings.cooldownFont = "Friz Quadrata TT"
defaultSettings.decimalThreshold = 5
defaultSettings.digitsnumber = 1
defaultSettings.durationLimit = 0
defaultSettings.showCooldown2 = false
defaultSettings.cooldown2Font = "Friz Quadrata TT"
defaultSettings.cooldown2Size = 10
defaultSettings.cd2Scaled = false
defaultSettings.cd2OffsetY = 0
defaultSettings.cd2BgAlpha = 0.75
defaultSettings.decimalThreshold2 = 0
defaultSettings.digitsnumber2 = 1
defaultSettings.durationLimit2 = 0
defaultSettings.interruptsScale = 1.4
defaultSettings.interruptsReduction = 0.3
defaultSettings.color7 = {0.20, 0.80, 0.60, 1.00}
defaultSettings.showClockOverlay = true
defaultSettings.clockOverlayAlpha = 0.9
defaultSettings.clockTargetOnly = false
defaultSettings.showSwipeEdge = true
defaultSettings.swipeEdgeTargetOnly = false
defaultSettings.verticalClock = false
defaultSettings.enableBlink = true
defaultSettings.blinkTargetOnly = true
defaultSettings.blinkThreshold = 3
defaultSettings.blinkMinDuration = 6
defaultSettings.enableFade = false
defaultSettings.fadeTargetOnly = false
defaultSettings.fadeThreshold = 3
defaultSettings.fadeMinDuration = 6

defaultSettings.increase = 1

-- side rows (left: important buffs, right: crowd control)
defaultSettings.sideSpacing = 2
defaultSettings.sideOffsetX = 2
defaultSettings.sideOffsetY = 0
defaultSettings.sideAnchorHealthBar = true
defaultSettings.sidePrioCC = 9
defaultSettings.sidePrioInterrupt = 7
defaultSettings.sidePrioRoot = 5
defaultSettings.sidePrioImmunity = 9
defaultSettings.sidePrioDefensive = 7
defaultSettings.sidePrioOffensive = 6
defaultSettings.sidePrioOther = 2
defaultSettings.sideGlowPulse = true
defaultSettings.sideHideNoDuration = true
defaultSettings.topSpacing = 2
defaultSettings.topRowSpacing = 2
defaultSettings.topOffsetX = 0
defaultSettings.topOffsetY = 10
defaultSettings.sidePrioImmunitySpell = 9
defaultSettings.sidePrioSnare = 4
defaultSettings.sidePrioDisarm = 6
defaultSettings.sidePrioSpeed = 3
defaultSettings.sidePrioShield = 5
defaultSettings.sidePrioHealing = 5
defaultSettings.spellScale = {}

-- glow per category (type: none, border, pixel, shine, button, proc) and per spell (by name, overrides the category)
defaultSettings.catGlow = {
	cc = { type = "proc", color = { 1, 0.3, 0.3 } },
	root = { type = "border", color = { 1, 0.65, 0.2 } },
	snare = { type = "border", color = { 0.7, 0.9, 0.3 } },
	disarm = { type = "proc", color = { 0.95, 0.75, 0.2 } },
	speed = { type = "border", color = { 0.4, 0.9, 1 } },
	shield = { type = "border", color = { 0.6, 0.8, 1 } },
	healing_reduction = { type = "border", color = { 0.8, 0.3, 0.8 } },
	interrupt = { type = "proc", color = { 1, 0.5, 0 } },
	immunity = { type = "button", color = { 0.4, 0.8, 1 } },
	immunity_spell = { type = "button", color = { 0.4, 0.8, 1 } },
	buff_def = { type = "button", color = { 0.2, 1, 0.3 } },
	buff_off = { type = "proc", color = { 1, 0.25, 0.25 } },
	buff_other = { type = "none", color = { 0.8, 0.8, 0.8 } },
	tracked = { type = "none", color = { 1, 1, 0.3 } },
	mydebuffs = { type = "none", color = { 1, 0.8, 0.2 } },
}
defaultSettings.spellGlow = {}

-- the rows: left and right hold one row each, above the plate there are up to four.
-- cats: which categories the row shows; "classic" = whatever the classic filters / Bar spells list let through.
defaultSettings.topRowCount = 2
defaultSettings.rowLeft = {
	enabled = true, max = 3, size = 32, glow = true, onlyMine = false, show = "buffs",
	cats = { immunity = true, buff_def = true, buff_off = true }
}
defaultSettings.rowRight = {
	enabled = true, max = 3, size = 32, glow = true, onlyMine = false, show = "debuffs",
	cats = { cc = true, root = true, interrupt = true, snare = true, healing_reduction = true, disarm = true }
}
-- top row 1: my debuffs. The other top rows start empty-ish; the user adds them.
defaultSettings.rowTop1 = {
	enabled = true, max = 6, size = 24, glow = false, onlyMine = true, show = "debuffs", myDebuffs = true,
	cats = {}
}
-- "My debuffs" list (Spells tab): debuffs learned as the player applies them, and the ones the user hides
defaultSettings.myDebuffs = {}
defaultSettings.myDebuffHidden = {}
defaultSettings.rowTop2 = {
	enabled = true, max = 4, size = 28, glow = true, onlyMine = false, show = "buffs",
	cats = { buff_other = true, speed = true, shield = true }
}
defaultSettings.rowTop3 = {
	enabled = true, max = 4, size = 24, glow = false, onlyMine = false, show = "all",
	cats = {}
}
defaultSettings.rowTop4 = {
	enabled = true, max = 4, size = 24, glow = false, onlyMine = false, show = "all",
	cats = {}
}
defaultSettings.rowTop5 = {
	enabled = true, max = 4, size = 24, glow = false, onlyMine = false, show = "all",
	cats = {}
}
defaultSettings.rowTop6 = {
	enabled = true, max = 4, size = 24, glow = false, onlyMine = false, show = "all",
	cats = {}
}

core.CoreOptionsTable = {
	name = core.title,
	type = "group",
	childGroups = "tab",
	get = function(info)
		local key = info[#info]
		return P[key]
	end,
	set = function(info, v)
		local key = info[#info]
		P[key] = v
	end,
	args = {}
}

core.DisplayOptionsTable = {
	type = "group",
	name = L["Display conditions"],
	order = 2,
	childGroups = "tab",
	get = function(info)
		local key = info[#info]
		return P[key]
	end,
	set = function(info, v)
		local key = info[#info]
		P[key] = v
	end,
	args = {
		displayHeader = {
			type = "header",
			name = L["Aura type"],
			order = 1
		},
		defaultBuffShow = {
			type = "select",
			name = L["Show Buffs"],
			desc = L["Show buffs above nameplate."],
			order = 2,
			values = {ALL, L["Mine + SpellList"], L["Only SpellList"], L["Mine Only"], L["None"]}
		},
		defaultDebuffShow = {
			type = "select",
			name = L["Show Debuffs"],
			desc = L["Show debuffs above nameplate."],
			order = 3,
			values = {ALL, L["Mine + SpellList"], L["Only SpellList"], L["Mine Only"], L["None"]}
		},
		showInterrupts = {
			type = "toggle",
			name = L["Show Interrupts"],
			desc = L["Show Interrupts as simulated debuffs above player nameplates."],
			order = 4
		},
		typeHeader = {
			type = "header",
			name = L["Unit type"],
			order = 5
		},
		blank1 = {
			type = "description",
			name = "",
			order = 6
		},
		abovePlayers = {
			type = "toggle",
			name = L["Players"],
			desc = L["Add buffs above players. 'Class Color in Nameplates' must be enabled."],
			order = 7
		},
		aboveNPC = {
			type = "toggle",
			name = L["NPC"],
			desc = L["Add buffs above NPCs"],
			order = 8
		},
		reactionHeader = {
			name = L["Unit reaction"],
			type = "header",
			order = 9
		},
		blank2 = {
			type = "description",
			name = "",
			order = 10
		},		
		aboveFriendly = {
			type = "toggle",
			name = L["Friendly"],
			desc = L["Add buffs above friendly plates"],
			order = 11
		},
		aboveNeutral = {
			type = "toggle",
			name = L["Neutral"],
			desc = L["Add buffs above neutral plates"],
			order = 12
		},
		aboveHostile = {
			type = "toggle",
			name = L["Hostile"],
			desc = L["Add buffs above hostile plates"],
			order = 13
		},
		otherHeader = {
			name = L["Misc"],
			type = "header",
			order = 14
		},
		blank3 = {
			type = "description",
			name = "",
			order = 15
		},
		watchCombatlog = {
			type = "toggle",
			name = L["Watch Combatlog"],
			desc = L["Watch combatlog for people gaining/losing spells.\nDisable this if you're having performance issues."],
			order = 16,
			get = function()
				return P.watchCombatlog
			end,
			set = function(info, val)
				P.watchCombatlog = not P.watchCombatlog
				core:RegisterCLEU()
			end
		},
		saveNameToGUID = {
			type = "toggle",
			name = L["Save player GUID"],
			desc = L["Remember player GUID's so target/mouseover isn't needed every time nameplate appears.\nKeep this enabled"],
			order = 17,
			get = function(info)
				return P.saveNameToGUID
			end,
			set = function(info, val)
				P.saveNameToGUID = val
			end
		},
		unknownSpellDataIcon = {
			type = "toggle",
			name = L["Show question mark"],
			desc = L["Displays a question mark above unidentified nameplates. Identify them by target or mouseover."],
			order = 18
		},
		blacklistTotems = {
			type = "toggle",
			name = L["Blacklist Totems"],
			desc = L["Ignore SkomsPlateBuffs on totem nameplates"],
			order = 19
		},
		playerCombatWithOnly = {
			type = "toggle",
			name = L["Player combat only"],
			desc = L["Only show spells above nameplates that are in combat."],
			order = 20,
			set = function(info, val)
				P.playerCombatWithOnly = val
				core:Disable()
				core:Enable()
			end
		},
		npcCombatWithOnly = {
			type = "toggle",
			name = L["NPC combat only"],
			desc = L["Only show spells above nameplates that are in combat."],
			order = 21,
			set = function(info, val)
				P.npcCombatWithOnly = val
				core:Disable()
				core:Enable()
			end
		},
		targetOnly = {
			type = "toggle",
			name = L["Target Only"],
			desc = L["Only show spell icons above your current target."],
			order = 22,
			set = function(info, val)
				P.targetOnly = val
				core:UpdateAllPlates()
			end
		},
		enabled = {
			type = "toggle",
			name = L["Disable addon"],
			desc = L["Disables all processes until the checkbox is unchecked or you reload the UI."],
			order = 23,
			get = function()
				return not core:IsEnabled()
			end,
			set = function(info, val)
				if val then
					core:Disable()
				else
					core:Enable()
				end
			end
		},
		blank4 = {
			type = "description",
			name = "",
			order = 24
		},
		blank5 = {
			type = "description",
			name = "",
			order = 25
		},
	}
}

core.DefaultSpellOptionsTable = {
	type = "group",
	name = L["Style settings"],
	order = 3,
	get = function(info)
		local key = info[#info]
		return P[key]
	end,
	set = function(info, v)
		local key = info[#info]
		P[key] = v
	end,
	args = {
		iconHeader = {
			type = "header",
			name = L["Icon settings"],
			order = 1
		},
		blank1 = {
			type = "description",
			name = "",
			order = 2,
		},
		iconSize = {
			type = "range",
			name = L["Icon width"],
			desc = L["Size of the icons."],
			order = 3,
			min = 8,
			max = 80,
			step = 1,
			set = function(info, val)
				P.iconSize = val
				core:ResetIconSizes()
			end
		},
		iconSize2 = {
			type = "range",
			name = L["Icon height"],
			desc = L["Size of the icons."],
			order = 4,
			min = 8,
			max = 80,
			step = 1,
			set = function(info, val)
				P.iconSize2 = val
				core:ResetIconSizes()
			end
		},
		textureSize = {
			name = L["Texture zoom"],
			desc = L["increase texture zoom.\nDefault=0.0"],
			type = "range",
			order = 5,
			min = 0,
			max = 0.3,
			step = 0.01,
			bigStep = 0.1,
			set = function(info, val)
				P.textureSize = val
				core:ResetAllPlateIcons()
			end
		},
		biggerSelfSpells = {
			type = "toggle",
			name = L["Larger self spells"],
			desc = L["Make your spells 20% bigger then other's."],
			order = 6
		},
		borderHeader = {
			type = "header",
			name = L["Border settings"],
			order = 7
		},
		borderTexture = {
			name = L["Debuff Border Texture"],
			type = "select",
			order = 8,
			values = {
				[""] = NONE,
				["Interface\\AddOns\\SkomsPlateBuffs\\media\\DefaultBorder.blp"] = L["Default"],
				["Interface\\AddOns\\SkomsPlateBuffs\\media\\ThinBorder.tga"] = L["Thin"],
				["Interface\\AddOns\\SkomsPlateBuffs\\media\\SquareBorder.tga"] = L["Square"],
				["Interface\\AddOns\\SkomsPlateBuffs\\media\\ThinSquareBorder.tga"] = L["Thin Square"],
				["Masque"] = (MSQ and "Masque" or nil)
			},
			set = function(info, val)
				P.borderTexture = val
				core:ResetAllPlateIcons()
			end
		},
		borderTextureBuff = {
			name = L["Buff Border Texture"],
			type = "select",
			order = 9,
			values = {
				[""] = NONE,
				["Interface\\AddOns\\SkomsPlateBuffs\\media\\DefaultBorder.blp"] = L["Default"],
				["Interface\\AddOns\\SkomsPlateBuffs\\media\\ThinBorder.tga"] = L["Thin"],
				["Interface\\AddOns\\SkomsPlateBuffs\\media\\SquareBorder.tga"] = L["Square"],
				["Interface\\AddOns\\SkomsPlateBuffs\\media\\ThinSquareBorder.tga"] = L["Thin Square"],
				["Masque"] = (MSQ and "Masque" or nil)
			},
			set = function(info, val)
				P.borderTextureBuff = val
				core:ResetAllPlateIcons()
			end
		},
		blank2 = {
			type = "description",
			name = "",
			order = 10,
		},
		colorByType = {
			type = "toggle",
			name = L["Color debuff by type"],
			desc = L["If not set Physical color used for all debuffs"],
			order = 11,
			width = "double",
			get = function(info)
				return P.colorByType
			end,
			set = function(info, val)
				P.colorByType = val
			end
		},
		blank3 = {
			type = "description",
			name = "",
			order = 12,
		},
		color1 = {
			type = "color",
			name = L["Physical"],
			order = 13,
			hasAlpha = true,
			get = function(info)
				return P.color1[1], P.color1[2], P.color1[3], P.color1[4] or 1
			end,
			set = function(info, r, g, b, a)
				P.color1 = {r, g, b, a}
			end
		},
		color2 = {
			name = L["Magic"],
			type = "color",
			order = 14,
			hasAlpha = true,
			get = function(info)
				return P.color2[1], P.color2[2], P.color2[3], P.color2[4] or 1
			end,
			set = function(info, r, g, b, a)
				P.color2 = {r, g, b, a}
			end
		},
		color3 = {
			name = L["Curse"],
			type = "color",
			order = 15,
			hasAlpha = true,
			get = function(info)
				return P.color3[1], P.color3[2], P.color3[3], P.color3[4] or 1
			end,
			set = function(info, r, g, b, a)
				P.color3 = {r, g, b, a}
			end
		},
		color4 = {
			name = L["Disease"],
			type = "color",
			order = 16,
			hasAlpha = true,
			get = function(info)
				return P.color4[1], P.color4[2], P.color4[3], P.color4[4] or 1
			end,
			set = function(info, r, g, b, a)
				P.color4 = {r, g, b, a}
			end
		},
		color5 = {
			name = L["Poison"],
			type = "color",
			order = 17,
			hasAlpha = true,
			get = function(info)
				return P.color5[1], P.color5[2], P.color5[3], P.color5[4] or 1
			end,
			set = function(info, r, g, b, a)
				P.color5 = {r, g, b, a}
			end
		},
		color6 = {
			name = L["Buff"],
			type = "color",
			order = 18,
			hasAlpha = true,
			get = function(info)
				return P.color6[1], P.color6[2], P.color6[3], P.color6[4] or 1
			end,
			set = function(info, r, g, b, a)
				P.color6 = {r, g, b, a}
			end
		},
		blank4 = {
			type = "description",
			name = "",
			order = 19,
		},
		textHeader = {
			type = "header",
			name = L["Text settings"],
			order = 20
		},
		blank5 = {
			type = "description",
			name = "",
			order = 21,
		},
		cooldownSize = {
			type = "range",
			name = L["Duration Text Size"],
			order = 22,
			min = 6,
			max = 20,
			step = 1,
			set = function(info, val)
				P.cooldownSize = val
				core:ResetDurationSizes()
			end
		},
		stackSize = {
			type = "range",
			name = L["Stack Text Size"],
			order = 23,
			min = 6,
			max = 20,
			step = 1,
			set = function(info, val)
				P.stackSize = val
				core:ResetStackSizes()
			end
		},
		blank6 = {
			type = "description",
			name = "",
			order = 24,
		},
		showCooldown = {
			type = "toggle",
			name = L["Show Duration"],
			desc = L["Show duration text on the spell icon."],
			width = "full",
			order = 25,
			set = function(info, val)
				P.showCooldown = val
				core:ResetDurationSizes()
			end
		},
		cdAnchor = {
			type = "select", 
			order = 26,
			name = L["Text Anchor"],
			desc = L["Anchor point for the duration text relative to the icon."],
			values = {
				BOTTOM = L["Under Icon"],
				CENTER = L["On Icon"],
				TOP = L["Above Icon"]
			},
			set = function(info, val)
				P.cdAnchor = val
				P.cdOffsetX = defaultSettings.cdOffsetX
				P.cdOffsetY = defaultSettings.cdOffsetY
				core:UpdateAllDurationAnchors()
			end,
			disabled = function() return not P.showCooldown end
		},
		cdOffsetX = {
			type = "range",
			name = L["Offset X"],
			order = 27,
			min = -30,
			max = 30,
			step = 0.5,
			set = function(info, val)
				P.cdOffsetX = val
				core:UpdateAllDurationAnchors()
			end,
			disabled = function() return not P.showCooldown end
		},
		cdOffsetY = {
			type = "range",
			name = L["Offset Y"],
			order = 28,
			min = -30,
			max = 30,
			step = 0.5,
			set = function(info, val)
				P.cdOffsetY = val
				core:UpdateAllDurationAnchors()
			end,
			disabled = function() return not P.showCooldown end
		},
		cooldownFont = {
			type = "select",
			name = L["Text Font"],
			order = 29,
			values = LSM:HashTable("font"),
			dialogControl = "LSM30_Font",
			get = function()
				return P.cooldownFont or defaultSettings.cooldownFont
			end,
			set = function(_, val)
				P.cooldownFont = val
				core:ResetDurationSizes()
			end,
			disabled = function() return not P.showCooldown end
		},
		decimalThreshold = {
			type = "range",
			name = L["Decimal Threshold"],
			desc = L["Show decimal digits for durations below this value (in seconds).\n0 = no threshold."],
			order = 30,
			min = 0,
			max = 60,
			step = 1,
			disabled = function() return not P.showCooldown end
		},
		digitsnumber = {
			type = "range",
			name = L["Decimal precision"],
			desc = L["Number of decimal places for duration values below 'Decimal Threshold'"],
			order = 31,
			min = 0,
			max = 2,
			step = 1,
			disabled = function() return not P.showCooldown end
		},
		durationLimit = {
			type = "range",
			name = L["Duration Threshold"],
			desc = L["Hide the duration text while the remaining time is above this value (in seconds).\n0 = no limit."],
			order = 32,
			min = 0,
			max = 300,
			step = 1,
			set = function(info, val)
				P.durationLimit = val
				core:ResetDurationSizes()
			end,
			disabled = function() return not P.showCooldown end
		},
		blank7 = {
			type = "description",
			name = "",
			order = 33
		},
		showCooldown2 = {
			type = "toggle",
			name = L["Alt. Duration Text"],
			desc = L["Displays an alternative duration text below the icon with a dark background."],
			width = "full",
			order = 34,
			set = function(info, val)
				P.showCooldown2 = val
				core:UpdateAllDuration2()
			end
		},
		cooldown2Font = {
			type = "select",
			name = L["Text Font"],
			order = 35,
			values = LSM:HashTable("font"),
			dialogControl = "LSM30_Font",
			get = function()
				return P.cooldown2Font or defaultSettings.cooldown2Font
			end,
			set = function(_, val)
				P.cooldown2Font = val
				core:UpdateAllDuration2()
			end,
			disabled = function() return not P.showCooldown2 end
		},
		cooldown2Size = {
			type = "range",
			name = L["Text Size"],
			order = 36,
			min = 6,
			max = 20,
			step = 1,
			set = function(info, val)
				P.cooldown2Size = val
				core:UpdateAllDuration2()
			end,
			disabled = function() return not P.showCooldown2 end
		},
		cd2OffsetY = {
			type = "range",
			name = L["Offset Y"],
			order = 37,
			min = -30,
			max = 30,
			step = 0.5,
			set = function(info, val)
				P.cd2OffsetY = val
				core:UpdateAllDuration2()
			end,
			disabled = function() return not P.showCooldown2 end
		},
		cd2BgAlpha = {
			type = "range",
			name = L["Background Opacity"],
			order = 38,
			min = 0,
			max = 1,
			step = 0.01,
			isPercent = true,
			set = function(_, val)
				P.cd2BgAlpha = val
				core:UpdateAllDuration2()
			end,
			disabled = function() return not P.showCooldown2 end
		},
		decimalThreshold2 = {
			type = "range",
			name = L["Decimal Threshold"],
			desc = L["Show decimal digits for durations below this value (in seconds).\n0 = no threshold."],
			order = 39,
			min = 0,
			max = 60,
			step = 1,
			disabled = function() return not P.showCooldown2 end
		},
		digitsnumber2 = {
			type = "range",
			name = L["Decimal precision"],
			desc = L["Number of decimal places for duration values below 'Decimal Threshold'"],
			order = 40,
			min = 0,
			max = 2,
			step = 1,
			disabled = function() return not P.showCooldown2 end
		},
		durationLimit2 = {
			type = "range",
			name = L["Duration Threshold"],
			desc = L["Hide the duration text while the remaining time is above this value (in seconds).\n0 = no limit."],
			order = 41,
			min = 0,
			max = 300,
			step = 1,
			set = function(info, val)
				P.durationLimit2 = val
				core:ResetDurationSizes()
			end,
			disabled = function() return not P.showCooldown2 end
		},
		cd2Scaled = {
			type = "toggle",
			name = L["Scale with Icon"],
			desc = L["Scales the alt. duration text using each spell's icon scale."],
			order = 42,
			set = function(info, val)
				P.cd2Scaled = val
				core:UpdateAllDuration2()
			end,
			disabled = function() return not P.showCooldown2 end
		},
		blank8 = {
			type = "description",
			name = "\n",
			order = 43
		},
		interruptsHeader = {
			type = "header",
			name = L["Interrupts settings"],
			order = 44
		},
		blank9 = {
			type = "description",
			name = "",
			order = 45
		},
		interruptsScale = {
			type = "range",
			name = L["Icon Scale"],
			order = 46,
			min = 1,
			max = 3,
			step = 0.1,
			set = function(info, val)
				P.interruptsScale = val
				core:ResetDurationSizes()
				core:ResetStackSizes()
				core:ResetIconSizes()
			end
		},
		interruptsReduction = {
			type = "range",
			name = L["Duration Reduction"],
			desc = L["Forces a duration reduction factor on all interrupts to conservatively handle healer talents cases (up to 30%)."],
			order = 47,
			min = 0,
			max = 0.3,
			step = 0.1,
		},
		color7 = {
			name = L["Border Color"],
			type = "color",
			order = 48,
			hasAlpha = true,
			get = function(info)
				return P.color7[1], P.color7[2], P.color7[3], P.color7[4] or 1
			end,
			set = function(info, r, g, b, a)
				P.color7 = {r, g, b, a}
			end
		},
		blank10 = {
			type = "description",
			name = "\n",
			order = 49
		},
		animationHeader = {
			type = "header",
			name = L["Animation settings"],
			order = 50
		},
		showClockOverlay = {
			type = "toggle",
			name = L["Enable Swipe"],
			desc = L["Show a radial swipe overlay over spell icons indicating the time remaining."],
			order = 51,
			set = function(info, val)
				P.showClockOverlay = val
				core:UpdateAllClockOverlays()
			end
		},
		clockTargetOnly = {
			type = "toggle",
			name = L["Swipe on target only"],
			desc = L["Restrict the swipe overlay to auras on the target's nameplate only."],
			order = 52,
			set = function(info, val)
				P.clockTargetOnly = val
				core:UpdateAllClockOverlays()
			end,
			disabled = function() return not P.showClockOverlay end
		},
		clockOverlayAlpha = {
			type = "range",
			name = L["Swipe Opacity"],
			desc = L["Set the opacity of the swipe overlay."],
			order = 53, 
			min = 0,
			max = 1,
			step = 0.05,
			isPercent = true,
			set = function(info, val)
				P.clockOverlayAlpha = val
				core:UpdateAllClockOverlays()
			end,
			disabled = function() return not P.showClockOverlay end,
		},
		showSwipeEdge = {
			type = "toggle",
			name = L["Show Edge"],
			desc = L["Show a bright edge along the swipe as it progresses."],
			order = 54,
			set = function(info, val)
				P.showSwipeEdge = val
				core:UpdateAllClockOverlays()
			end,
			disabled = function() return not P.showClockOverlay or P.verticalClock end
		},
		swipeEdgeTargetOnly = {
			type = "toggle",
			name = L["Edge on target only"],
			desc = L["Restrict the edge effect to auras on the target's nameplate only."],
			order = 55,
			set = function(info, val)
				P.swipeEdgeTargetOnly = val
				core:UpdateAllClockOverlays()
			end,
			disabled = function()
				return not P.showClockOverlay or not P.showSwipeEdge or P.clockTargetOnly or P.verticalClock
			end
		},
		verticalClock = {
			type = "toggle",
			name = L["Vertical Swipe"],
			desc = L["Use a vertical fill instead of the default radial swipe."],
			order = 56,
			set = function(info, val)
				P.verticalClock = val
				core:UpdateAllClockOverlays()
			end,
			disabled = function() return not P.showClockOverlay end
		},
		blank11 = {
			type = "description",
			name = "",
			order = 57,
		},
		enableBlink = {
			type = "toggle",
			name = L["Enable Blink"],
			desc = L["Blink the icon as its duration expires"],
			order = 58,
		},
		blinkTargetOnly = {
			type = "toggle",
			name = L["Only blink on target"],
			desc = L["Restrict blinking effect to auras on the target's nameplate only"],
			order = 59,
			disabled = function() return not P.enableBlink end
		},
		blinkThreshold = {
			type = "range",
			name = L["Blink threshold time"],
			desc = L["Blink icon below x seconds"],
			order = 60,
			min = 0,
			max = 10,
			step = 1,
			disabled = function() return not P.enableBlink end
		},
		blinkMinDuration = {
			type = "range",
			name = L["Min duration for Blink"],
			desc = L["Blink effect will only apply to auras with a duration longer than this value."],
			order = 61,
			min = 3,
			max = 10,
			step = 1,
			disabled = function() return not P.enableBlink end
		},
		blank12 = {
			type = "description",
			name = "",
			order = 62,
		},
		enableFade = {
			type = "toggle",
			name = L["Enable Fade"],
			desc = L["Progressively fade out the icon as its duration expires"],
			order = 63,
		},
		fadeTargetOnly = {
			type = "toggle",
			name = L["Only fade on target"],
			desc = L["Restrict fade effect to auras on the target's nameplate only"],
			order = 64,
			disabled = function() return not P.enableFade end
		},
		fadeThreshold = {
			type = "range",
			name = L["Fade threshold time"],
			desc = L["Progressive fade out icon below x seconds"],
			order = 65,
			min	= 0,
			max	= 10,
			step = 1,
			disabled = function() return not P.enableFade end
		},
		fadeMinDuration = {
			type = "range",
			name = L["Min duration for Fade"],
			desc = L["Fade effect will only apply to auras with a duration longer than this value."],
			order = 66,
			min = 3,
			max = 10,
			step = 1,
			disabled = function() return not P.enableFade end
		},
		blank13 = {
			type = "description",
			name = "",
			order = 67,
		},
		blank14 = {
			type = "description",
			name = "",
			order = 68,
		},
	}
}

local tmpNewName = ""
local tmpNewID = ""

core.SpellOptionsTable = {
	type = "group",
	name = L["Bar spells"],
	order = 5,
	args = {
		inputName = {
			type = "input",
			name = L["Spell name"],
			desc = L["Input a spell name. (case sensitive)\nOr spell ID"],
			order = 1,
			get = function(info)
				return tmpNewName, tmpNewID
			end,
			set = function(info, val)
				local spellLink = GetSpellLink(tonumber(val) or val)
				if spellLink then
					local spellID = spellLink:match("spell:(%d+)")
					if spellID then
						local spellName = GetSpellInfo(spellID)
						if spellName then
							tmpNewName = spellName
							tmpNewID = tonumber(spellID)
							return
						end
					end
				end
				tmpNewName = val
				tmpNewID = L["ID not set"]
			end
		},
		addName = {
			type = "execute",
			name = L["Add spell"],
			desc = L["Add spell to list."],
			order = 2,
			func = function(info)
				if tmpNewName ~= "" then
					if tmpNewID ~= "" then
						core:AddNewSpell(tmpNewName, tmpNewID)
					else
						core:AddNewSpell(tmpNewName)
					end
					LibStub("AceConfigDialog-3.0"):SelectGroup(core.title, "spells", tmpNewName)
					tmpNewName = ""
				end
			end
		},
	}
}

local ROW_TITLES = {
	rowLeft = "Left row",
	rowRight = "Right row",
	rowTop1 = "Top row",
	rowTop2 = "Extra top row 1",
	rowTop3 = "Extra top row 2",
	rowTop4 = "Extra top row 3",
	rowTop5 = "Extra top row 4",
	rowTop6 = "Extra top row 5",
}

local ROW_CATS = {
	{ "cc", "Crowd control" },
	{ "root", "Roots" },
	{ "snare", "Snares" },
	{ "disarm", "Disarms" },
	{ "healing_reduction", "Healing reduction" },
	{ "interrupt", "Interrupt lockouts" },
	{ "immunity", "Immunities" },
	{ "buff_def", "Defensive buffs" },
	{ "shield", "Shields" },
	{ "buff_off", "Offensive buffs" },
	{ "speed", "Speed boosts" },
	{ "buff_other", "Other buffs" },
	{ "any", "Any other aura" },
}

local ROW_CAT_DESC = {
	any = "Every aura no earlier row took. Combine it with Only my auras and Debuffs only to get \"my debuffs\".",
}

local function NotifyOptions()
	local registry = LibStub("AceConfigRegistry-3.0", true)
	if registry then registry:NotifyChange(core.title) end
end

local MAX_TOP_ROWS = 6

local function AddTopRow()
	P.topRowCount = math.min(MAX_TOP_ROWS, (P.topRowCount or 1) + 1)
	core:ResetSideRows()
	NotifyOptions()
end

local function RowOptions(rowKey, order)
	local topIndex = tonumber(rowKey:match("^rowTop(%d+)$"))
	local function row() return P[rowKey] end
	local isCat = {}
	for _, c in ipairs(ROW_CATS) do isCat[c[1]] = true end

	local group = {
		type = "group",
		name = L[ROW_TITLES[rowKey]],
		order = order,
		hidden = topIndex and function() return topIndex > (P.topRowCount or 1) end or nil,
		get = function(info)
			local k = info[#info]
			if isCat[k] then return row().cats[k] end
			return row()[k]
		end,
		set = function(info, v)
			local k = info[#info]
			if isCat[k] then
				row().cats[k] = v and true or nil
			else
				row()[k] = v
			end
			core:ResetSideRows()
		end,
		args = {
			enabled = { type = "toggle", name = L["Enabled"], order = 1 },
			max = { type = "range", name = L["Max icons"], order = 2, min = 1, max = topIndex and 12 or 6, step = 1 },
			size = { type = "range", name = L["Icon size"], order = 3, min = 12, max = 64, step = 1 },
			show = {
				type = "select",
				name = L["Show"],
				order = 4,
				values = { all = L["Buffs and debuffs"], debuffs = L["Debuffs only"], buffs = L["Buffs only"] },
			},
			onlyMine = {
				type = "toggle",
				name = L["Only my auras"],
				desc = L["Only show auras you cast."],
				order = 5
			},
			glow = {
				type = "toggle",
				name = L["Glow"],
				desc = L["Glow around the icons of the categories (not around other auras)."],
				order = 6
			},
			addRow = {
				type = "execute",
				name = L["Add an extra top row"],
				desc = L["Rows above the nameplate. Each one has its own content, size and number of icons."],
				order = 7,
				hidden = function() return (P.topRowCount or 1) >= MAX_TOP_ROWS end,
				func = AddTopRow,
			},
			remove = {
				type = "execute",
				name = L["Remove this extra row"],
				order = 7.5,
				hidden = function() return not (topIndex and topIndex > 1 and topIndex == (P.topRowCount or 1)) end,
				func = function()
					P.topRowCount = math.max(1, (P.topRowCount or 1) - 1)
					core:ResetSideRows()
					NotifyOptions()
				end,
			},
			catHeader = { type = "header", name = L["Show in this row"], order = 10 },
			catDesc = {
				type = "description",
				name = L["An aura goes to the first row that takes it. Rows set to Only my auras come first, then left, right and the top rows in order."],
				order = 11
			},
		}
	}
	for i, c in ipairs(ROW_CATS) do
		local t = { type = "toggle", name = L[c[2]], order = 20 + i, width = "full" }
		if ROW_CAT_DESC[c[1]] then t.desc = L[ROW_CAT_DESC[c[1]]] end
		group.args[c[1]] = t
	end
	if rowKey == "rowTop1" then
		group.args.myDebuffs = {
			type = "toggle",
			name = L["My debuffs"],
			desc = L["Shows your own debuffs on enemies, except hard crowd control (stuns, fears, disarms, silences), which stays on the right row. Pick which ones to show, their size and glow in the Spells tab, My debuffs."],
			order = 3.5,
			width = "full",
		}
		-- with My debuffs on, what this row shows is decided in the Spells tab
		local function off() return P.rowTop1.myDebuffs end
		for _, k in ipairs{ "show", "onlyMine", "catHeader", "catDesc" } do group.args[k].hidden = off end
		for _, c in ipairs(ROW_CATS) do group.args[c[1]].hidden = off end
	end
	return group
end

core.RowsOptionsTable = {
	type = "group",
	name = L["Rows"],
	order = 1,
	get = function(info)
		return P[info[#info]]
	end,
	set = function(info, v)
		P[info[#info]] = v
		core:ResetSideRows()
	end,
	args = {
		desc = {
			type = "description",
			name = L["Each row shows the categories you choose. Left and right are one row each, above the plate there are up to four rows. An aura goes to the first row that takes it. Which spells belong to which category, their priority and their glow are set in the Spells tab."],
			order = 1
		},
		sideHideNoDuration = {
			type = "toggle",
			name = L["Hide buffs without a duration"],
			desc = L["Forms, stances and other permanent buffs are not shown in category rows."],
			width = "full",
			order = 2
		},
		sideGlowPulse = {
			type = "toggle",
			name = L["Pulsing border glow"],
			desc = L["The border glow fades in and out. Without it the glow stays steady."],
			width = "full",
			order = 3
		},
		addRow = {
			type = "execute",
			name = L["Add an extra top row"],
			desc = L["Rows above the nameplate. Each one has its own content, size and number of icons."],
			order = 4,
			hidden = function() return (P.topRowCount or 1) >= MAX_TOP_ROWS end,
			func = AddTopRow,
		},
		rowLeft = RowOptions("rowLeft", 10),
		rowRight = RowOptions("rowRight", 11),
		rowTop1 = RowOptions("rowTop1", 12),
		rowTop2 = RowOptions("rowTop2", 13),
		rowTop3 = RowOptions("rowTop3", 14),
		rowTop4 = RowOptions("rowTop4", 15),
		rowTop5 = RowOptions("rowTop5", 16),
		rowTop6 = RowOptions("rowTop6", 17),
	}
}

core.PositionOptionsTable = {
	type = "group",
	name = L["Position"],
	order = 2,
	get = function(info)
		return P[info[#info]]
	end,
	set = function(info, v)
		P[info[#info]] = v
		core:ResetSideRows()
	end,
	args = {
		sideHeader = { type = "header", name = L["Left and right rows"], order = 1 },
		sideAnchorHealthBar = {
			type = "toggle",
			name = L["Anchor to the health bar"],
			desc = L["Off: anchor to the whole nameplate frame."],
			width = "full",
			order = 2
		},
		sideSpacing = { type = "range", name = L["Spacing"], order = 3, min = -10, max = 30, step = 1 },
		sideOffsetX = { type = "range", name = L["Offset X"], order = 4, min = -60, max = 60, step = 1 },
		sideOffsetY = { type = "range", name = L["Offset Y"], order = 5, min = -60, max = 60, step = 1 },
		topHeader = { type = "header", name = L["Rows above the plate"], order = 10 },
		topSpacing = { type = "range", name = L["Spacing"], order = 11, min = -10, max = 30, step = 1 },
		topRowSpacing = { type = "range", name = L["Space between rows"], order = 12, min = -10, max = 30, step = 1 },
		topOffsetX = { type = "range", name = L["Offset X"], order = 13, min = -100, max = 100, step = 1 },
		topOffsetY = { type = "range", name = L["Offset Y"], order = 14, min = -60, max = 100, step = 1 },
		testHeader = { type = "header", name = L["Test"], order = 20 },
		glowShowcase = {
			type = "execute",
			name = L["Glow showcase"],
			desc = L["Opens a window with every glow style on a sample icon, to compare them. Also /spb glow."],
			order = 22,
			func = function() core:ToggleGlowShowcase() end,
		},
		iconTestMode = {
			type = "toggle",
			name = L["Test Mode"],
			desc = L["For each spell on someone, multiply it by 3.\nThis option won't be saved at logout."],
			order = 21,
			get = function()
				return core.iconTestMode
			end,
			set = function()
				core.iconTestMode = not core.iconTestMode
			end
		},
	}
}

-- Main settings: rows, display conditions, appearance (the old Display conditions and Style settings tabs, minus the classic-bar parts)
do
	local style = core.DefaultSpellOptionsTable
	style.name = L["Appearance"]
	style.order = 3
	for _, k in ipairs{ "iconSize", "iconSize2", "biggerSelfSpells", "interruptsScale" } do
		if style.args[k] then style.args[k].hidden = true end
	end
	core.DisplayOptionsTable.order = 2
	-- colours: of the border, and of the glow
	local function recolor() core:ResetSideRows() end
	style.args.colorByType.hidden = true
	style.args.borderColorMode = {
		type = "select",
		name = L["Border color"],
		desc = L["By spell type: physical, magic, curse, disease, poison (the colours below). By category: the category colours of the Spells tab. Custom: one colour for every icon."],
		order = 10.5,
		values = { type = L["By spell type"], category = L["By category"], custom = L["Custom color"] },
		get = function() return P.borderColorMode end,
		set = function(_, v) P.borderColorMode = v; recolor() end,
	}
	style.args.borderCustomColor = {
		type = "color",
		name = L["Custom border color"],
		desc = L["Dark by default."],
		order = 10.6,
		hasAlpha = true,
		disabled = function() return P.borderColorMode ~= "custom" end,
		get = function() local c = P.borderCustomColor; return c[1], c[2], c[3], c[4] or 1 end,
		set = function(_, r, g, b, a) P.borderCustomColor = { r, g, b, a }; recolor() end,
	}
	style.args.glowHeader = { type = "header", name = L["Glow"], order = 200 }
	style.args.glowColorMode = {
		type = "select",
		name = L["Glow color"],
		desc = L["Default: the style's own look (yellow, as in retail). By spell type: physical, magic, curse, disease, poison. By category: the category colours of the Spells tab. A colour set on a spell always wins."],
		order = 201,
		values = { default = L["Default (yellow)"], type = L["By spell type"], category = L["By category"] },
		get = function() return P.glowColorMode end,
		set = function(_, v) P.glowColorMode = v; recolor() end,
	}
	local function noDispel() return not P.dispelGlow end
	style.args.dispelGlow = {
		type = "toggle",
		name = L["Highlight buffs I can dispel"],
		desc = L["Magic buffs on enemies that your class can remove (Dispel Magic, Purge, Spellsteal, Devour Magic, Shield Slam) get their own glow. Classes that cannot dispel buffs never see it."],
		order = 202,
		width = "full",
		get = function() return P.dispelGlow end,
		set = function(_, v) P.dispelGlow = v; recolor() end,
	}
	style.args.dispelGlowScope = {
		type = "select",
		name = L["Which buffs"],
		order = 203,
		disabled = noDispel,
		values = { other = L["Other buffs only"], all = L["All buffs except immunities"] },
		get = function() return P.dispelGlowScope end,
		set = function(_, v) P.dispelGlowScope = v; recolor() end,
	}
	style.args.dispelGlowType = {
		type = "select",
		name = L["Glow"],
		order = 204,
		disabled = noDispel,
		values = { border = L["Border"], pixel = L["Pixel glow"], shine = L["Autocast shine"], button = L["Action button glow"], proc = L["Proc glow"] },
		get = function() return P.dispelGlowType end,
		set = function(_, v) P.dispelGlowType = v; recolor() end,
	}
	style.args.dispelGlowColor = {
		type = "color",
		name = L["Glow color"],
		order = 205,
		disabled = noDispel,
		get = function() local c = P.dispelGlowColor; return c[1], c[2], c[3] end,
		set = function(_, r, g, b) P.dispelGlowColor = { r, g, b }; recolor() end,
	}
	-- Show buffs / Show debuffs / Show interrupts: each row decides now (Buffs and debuffs, Only my auras, categories)
	for _, k in ipairs{ "displayHeader", "defaultBuffShow", "defaultDebuffShow", "showInterrupts" } do
		if core.DisplayOptionsTable.args[k] then core.DisplayOptionsTable.args[k].hidden = true end
	end
	if core.DisplayOptionsTable.args.unknownSpellDataIcon then core.DisplayOptionsTable.args.unknownSpellDataIcon.hidden = true end

	core.MainOptionsTable = {
		type = "group",
		name = L["Main settings"],
		order = 1,
		childGroups = "tree",
		args = {
			rows = core.RowsOptionsTable,
			display = core.DisplayOptionsTable,
			style = style,
		}
	}
end

core.CoreOptionsTable.args.main     = core.MainOptionsTable
core.CoreOptionsTable.args.position = core.PositionOptionsTable

do
	local _spelliconcache = {}
	local function SpellString(spellID, size)
		size = size or 12
		if not _spelliconcache[spellID .. size] then
			if spellID and tonumber(spellID) then
				local icon = select(3, GetSpellInfo(spellID))
				_spelliconcache[spellID .. size] = "\124T" .. icon .. ":" .. size .. "\124t"
				return _spelliconcache[spellID .. size]
			else
				return "\124TInterface\\Icons\\Inv_misc_questionmark" .. ":" .. size .. "\124t"
			end
		else
			return _spelliconcache[spellID .. size]
		end
	end

	function core:BuildSpellUI()
		local SpellOptionsTable = core.SpellOptionsTable
		
		for key in pairs(SpellOptionsTable.args) do
			if key ~= "inputName" and key ~= "addName" and not key:find("^keep_") then
				SpellOptionsTable.args[key] = nil
			end
		end

		local list = {}
		for name, data in pairs(P.spellOpts) do
			if not P.ignoreDefaultSpell[name] and not core.CategorizedNames[name] then
				table_insert(list, name)
			end
		end

		table_sort(list, function(a, b) return (a and b) and a < b end)

		local testDone = false
		local spellName, data, spellID
		local spellDesc, spellTexture
		local iconSize
		local nameColour
		local iconTexture

		for i = 1, table_getn(list) do
			spellName = list[i]
			data = P.spellOpts[spellName]
			spellID = P.spellOpts[spellName].spellID or L["ID not set"]
			iconSize = data.increase or P.increase
			iconTexture = SpellString(spellID, 28)

			if data.show == 1 then
				nameColour = "|cff00ff00%s|r" --green
			elseif data.show == 3 then
				nameColour = "|cffff0000%s|r" --red
			elseif data.show == 5 then
				nameColour = "|cffcd00cd%s|r" --purple
			elseif data.show == 4 then
				nameColour = "|cffb9ffff%s|r" --birizoviy
			else
				nameColour = "|cffffff00%s|r" --yellow
			end

			spellDesc = L["To show a description you can assign a valid Spell ID.\nThis aura will still be tracked based on the Spell Name"]
			spellTexture = "Interface\\Icons\\Inv_misc_questionmark"

			if spellID and type(spellID) == "number" then
				tooltip:SetHyperlink("spell:" .. spellID)
				spellTexture = select(3, GetSpellInfo(spellID))
				
				local lines = tooltip:NumLines()
				if lines > 0 then
					spellDesc = _G[folder .. "TooltipTextLeft" .. lines] and _G[folder .. "TooltipTextLeft" .. lines]:GetText() or spellDesc
				end
			end

			--add spell to table.
			SpellOptionsTable.args[spellName] = {
				type = "group",
				name = iconTexture .. " " .. nameColour:format(spellName .. " (" .. iconSize .. ") #" .. spellID),
				desc = spellDesc,
				order = i,
				args = {}
			}
			SpellOptionsTable.args[spellName].args.spellTitle = {
				type = "header",
				name = spellName,
				order = 1
			}
			SpellOptionsTable.args[spellName].args.blank = {
				type = "description",
				name = "",
				order = 2
			}
			SpellOptionsTable.args[spellName].args.spellDesc = {
				type = "description",
				name = spellDesc,
				image = spellTexture,
				imageWidth = 32,
				imageHeight = 32,
				order = 3
			}
			SpellOptionsTable.args[spellName].args.blank2 = {
				type = "description",
				name = "",
				order = 4
			}
			SpellOptionsTable.args[spellName].args.showOpt = {
				type = "select",
				name = L["Show"],
				desc = L["Always show spell, only show your spell, never show spell"],
				values = {
					L["Always"],
					L["Mine only"],
					L["Never"],
					L["Only Friend"],
					L["Only Enemy"]
				},
				order = 5,
				get = function(info)
					return P.spellOpts[info[#info-1]].show or 1
				end,
				set = function(info, val)
					P.spellOpts[info[#info-1]].show = val
					core:BuildSpellUI()
				end
			}
			SpellOptionsTable.args[spellName].args.iconSize = {
				type = "range",
				name = L["Icon Scale"],
				order = 6,
				min = 1,
				max = 3,
				step = 0.05,
				get = function(info)
					return P.spellOpts[info[#info-1]].increase or P.increase
				end,
				set = function(info, val)
					P.spellOpts[info[#info-1]].increase = val
					core:ResetDurationSizes()
					core:ResetStackSizes()
					core:ResetIconSizes()
					core:BuildSpellUI()
				end
			}
			SpellOptionsTable.args[spellName].args.spellID = {
				type = "input",
				name = L["Spell ID"],
				order = 7,
				get = function(info)
					return tostring(P.spellOpts[info[#info-1]].spellID or L["ID not set"])
				end,
				set = function(info, val)
					local num = tonumber(val)
					if num and info[#info-1] == GetSpellInfo(num) then
						P.spellOpts[info[#info-1]].spellID = num
					else
						P.spellOpts[info[#info-1]].spellID = L["ID not set"]
						P.spellOpts[info[#info-1]].grabid = false
					end
					core:BuildSpellUI()
				end
			}
			if data.when then
				SpellOptionsTable.args[spellName].args.addedWhen = {
					type = "description",
					name = L["Added: "] .. data.when,
					order = 8
				}
			end
			SpellOptionsTable.args[spellName].args.grabID = {
				type = "toggle",
				name = L["Check Spell ID"],
				desc = L["Check exact Spell ID for this aura. Useful when different spells share a name"],
				order = 9,
				get = function(info)
					return P.spellOpts[info[#info-1]].grabid
				end,
				set = function(info, val)
					P.spellOpts[info[#info-1]].grabid = not P.spellOpts[info[#info-1]].grabid
				end,
				disabled = function(info)
					return type(P.spellOpts[info[#info-1]].spellID) ~= "number"
				end
			}
			if core.SpellGlowArgs then
				for k, v in pairs(core.SpellGlowArgs(spellName, 11)) do
					SpellOptionsTable.args[spellName].args[k] = v
				end
			end
			SpellOptionsTable.args[spellName].args.removeSpell = {
				type = "execute",
				order = 10,
				name = L["Remove Spell"],
				desc = L["Remove spell from list"],
				func = function(info)
					core:RemoveSpell(info[#info-1])
				end
			}
		end
	end
end

core.AboutOptionsTable = {
	name = L["About"],
	type = "group",
	childGroups = "tab",
	get = function(info)
		local key = info[#info]
		return P[key]
	end,
	set = function(info, v)
		local key = info[#info]
		P[key] = v
	end,
	args = (function()
		local args = {}
		local fields = {
			"Title",
			"Notes",
			"Author",
			"X-Backporter",
			"X-Modder",
			"Version",
			"X-Date",
			"X-Website",
		}
		local haseditbox = {
			["X-Website"] = true,
		}
		local fNames = {
			["X-Backporter"] = "Backporter",
			["X-Modder"] = "Modder",
			["X-Date"] = "Date",
			["X-Website"] = "Website",
		}
		local yellow = "|cffffd100%s|r"
		for i, field in ipairs(fields) do
			local val = GetAddOnMetadata(folder, field)
			if val then
				if haseditbox[field] then
					args[field] = {
						type = "input",
						name = fNames[field] or field,
						desc = L["Click and press Ctrl-C to copy"],
						width = "double",
						order = i,
						get = function(info)
							local key = info[#info]
							return GetAddOnMetadata(folder, key)
						end
					}
				else
					args[field] = {
						type = "description",
						name = yellow:format((fNames[field] or field) .. ": ") .. val,
						width = "full",
						order = i,
					}
				end
			end
		end
		return args
	end)()
}