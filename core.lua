-- Skom's Plate Buffs, Forever edition.
--
-- Same rows, categories and settings as the Warmane version, drawn with the Forever client's own
-- AuraContainer frames (the way MiniAuras does it), because in combat Forever hides aura spell ids
-- and the combat log from addons. What that means per category:
--  * Debuffs on enemies (crowd control, roots, snares, disarms, healing reduction, my debuffs):
--    filtered by the spell lists in data.lua, built from Forever's own spell data.
--  * Buffs on enemies: only the game's own tags (big/external defensive, important), plus untagged
--    short buffs and "any other aura". Spell lists cannot pick out an enemy's buffs.
--  * Buffs on friendly plates: filtered by the spell lists. Debuffs there: crowd control tag only.
--  * Interrupt lockouts: not auras. Taken from the cast-interrupted events of nameplate units.
--  * Per-spell size, glow and priority would need to read each aura: not possible in combat.
local ADDON, ns = ...
local core = ns
_G.SkomsPlateBuffs = core

core.title = "SkomsPlateBuffs"
core.version = C_AddOns and C_AddOns.GetAddOnMetadata(ADDON, "Version") or ""

local cat = ns.SpellCategory
local P -- current profile

local function Print(msg, ...)
	print("|cff33ff99Skom's Plate Buffs|r: " .. string.format(msg, ...))
end
core.Print = Print

local function IsSecret(v)
	return issecretvalue and issecretvalue(v)
end

------------------------------------------------------------------------------------------------
-- Defaults: the Warmane keys this edition uses, with the Warmane default values.
------------------------------------------------------------------------------------------------
local function Row(t) return t end
core.defaultSettings = { profile = {
	abovePlayers = true, aboveNPC = true, aboveFriendly = true, aboveNeutral = true, aboveHostile = true,
	sideSpacing = 2, sideOffsetX = 2, sideOffsetY = 0, sideAnchorHealthBar = true,
	topSpacing = 2, topRowSpacing = 2, topOffsetX = 0, topOffsetY = 10, topRowCount = 2,
	sideHideNoDuration = true,
	borderColorMode = "custom", borderCustomColor = { 0.12, 0.12, 0.12, 1 },
	cooldownSize = 11, stackSize = 8, showCooldown = true, iconSize = 28, decimalThreshold = 5,
	sidePrioCC = 9, sidePrioInterrupt = 7, sidePrioRoot = 5, sidePrioImmunity = 9, sidePrioDefensive = 7,
	sidePrioOffensive = 6, sidePrioOther = 2, sidePrioImmunitySpell = 9, sidePrioSnare = 4, sidePrioDisarm = 6,
	sidePrioSpeed = 3, sidePrioShield = 5, sidePrioHealing = 5,
	catGlow = {
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
		tag_bigdef = { type = "proc", color = { 0.4, 0.8, 1 } },
		tag_extdef = { type = "proc", color = { 0.2, 1, 0.3 } },
		tag_important = { type = "proc", color = { 1, 0.25, 0.25 } },
		short = { type = "pixel", color = { 1, 0.55, 0.25 } },
	},
	rowLeft = Row { enabled = true, max = 3, size = 32, glow = true, onlyMine = false, show = "buffs",
		cats = { immunity = true, buff_def = true, buff_off = true, tag_bigdef = true, tag_extdef = true, tag_important = true, short = true } },
	rowRight = Row { enabled = true, max = 3, size = 32, glow = true, onlyMine = false, show = "debuffs",
		cats = { cc = true, root = true, interrupt = true, snare = true, healing_reduction = true, disarm = true } },
	rowTop1 = Row { enabled = true, max = 6, size = 24, glow = false, onlyMine = true, show = "debuffs", myDebuffs = true, cats = {} },
	rowTop2 = Row { enabled = true, max = 4, size = 28, glow = true, onlyMine = false, show = "buffs",
		cats = { buff_other = true, speed = true, shield = true } },
	rowTop3 = Row { enabled = true, max = 4, size = 24, glow = false, onlyMine = false, show = "all", cats = {} },
	rowTop4 = Row { enabled = true, max = 4, size = 24, glow = false, onlyMine = false, show = "all", cats = {} },
	rowTop5 = Row { enabled = true, max = 4, size = 24, glow = false, onlyMine = false, show = "all", cats = {} },
	rowTop6 = Row { enabled = true, max = 4, size = 24, glow = false, onlyMine = false, show = "all", cats = {} },
	myDebuffs = {}, myDebuffHidden = {},
	friendlyTopRowOnly = false, friendlyMax = 4, friendlySize = 28, friendlyGlow = true,
	friendlyCats = { cc = true, root = true, interrupt = true, disarm = true },
	dispelGlow = true, dispelGlowScope = "all", dispelGlowType = "pixel", dispelGlowColor = { 0.7, 0.45, 1 },
	customSpells = {},
	-- Forever only
	foreverShortSeconds = 30,
	showInterrupts = true, interruptLockout = 4, interruptLengths = {},
	timerColorByTime = true, timerYellowAt = 10, timerOrangeAt = 5, timerRedAt = 3,
	timerYellowPct = 50, timerOrangePct = 25, timerRedPct = 10,
	anyBuffsWithShort = false,
	hiddenSpells = {}, hiddenNames = {},
	timerColors = { white = { 1, 1, 1 }, yellow = { 1, 0.85, 0.1 }, orange = { 1, 0.5, 0 }, red = { 1, 0.1, 0.1 } },
} }

------------------------------------------------------------------------------------------------
-- Spell id sets
------------------------------------------------------------------------------------------------
local DEBUFF_CATS = { "cc", "disarm", "root", "healing_reduction", "snare" }
local BUFF_CATS = { "immunity", "buff_def", "buff_off", "shield", "speed", "buff_other" }
local IS_DEBUFF = { cc = true, disarm = true, root = true, healing_reduction = true, snare = true, interrupt = true }

-- What can really work on Forever, per kind of plate. In combat the client hides aura spell ids,
-- so the Warmane lists only work where the client applies them itself: harmful lists on units we
-- cannot assist, helpful lists on units we can. Everything else is the game's own tags and length.
local WORKS = {
	cc = "both", root = "enemy", snare = "enemy", disarm = "enemy", healing_reduction = "enemy", interrupt = "enemy",
	tag_bigdef = "both", tag_extdef = "both", tag_important = "both", short = "both",
	immunity = "friend", buff_def = "friend", buff_off = "friend", shield = "friend", speed = "friend", buff_other = "friend",
}
core.WORKS = WORKS
local function Works(c, side) local w = WORKS[c]; return w == "both" or w == side end
local TAG_CATS = { "tag_bigdef", "tag_extdef", "tag_important" }
local TAG_TOKEN = { tag_bigdef = "BIG_DEFENSIVE", tag_extdef = "EXTERNAL_DEFENSIVE", tag_important = "IMPORTANT" }

-- v0.5: the old enemy-buff behaviour (immunity/defensive/offensive lists secretly meaning the
-- game's tags, plus a global short-buffs switch) becomes real categories; glow types become the
-- two looks Forever can draw.
local function Migrate(P)
	if not P or P.catsV2 then return end
	local function fix(cats)
		if type(cats) ~= "table" then return end
		if cats.immunity or cats.buff_def or cats.immunity_spell then cats.tag_bigdef = true; cats.tag_extdef = true end
		if cats.buff_off then
			cats.tag_important = true
			if P.foreverShortBuffs ~= false then cats.short = true end
		end
	end
	for _, k in ipairs({ "rowLeft", "rowRight", "rowTop1", "rowTop2", "rowTop3", "rowTop4", "rowTop5", "rowTop6" }) do
		if P[k] then fix(P[k].cats) end
	end
	fix(P.friendlyCats)
	local g = P.catGlow
	if g then
		local function copy(from, to)
			if g[from] then g[to] = { type = g[from].type, color = { unpack(g[from].color or { 1, 1, 1 }) } } end
		end
		copy("immunity", "tag_bigdef"); copy("buff_def", "tag_extdef"); copy("buff_off", "tag_important"); copy("buff_off", "short")
		for _, e in pairs(g) do
			if type(e) == "table" then
				if e.type == "border" then e.type = "pixel" elseif e.type == "button" or e.type == "shine" then e.type = "proc" end
			end
		end
	end
	if P.dispelGlowType ~= "pixel" then P.dispelGlowType = "proc" end
	P.catsV2 = true
end
core.Migrate = Migrate

-- Disjoint copies, in the order above, so one aura never lands in two groups.
local ids = {}
-- Rebuilt on every settings change, because custom spells (Spells tab) are added to their category.
local function BuildIds()
	for k in pairs(ids) do ids[k] = nil end
	local custom = {}
	for id, c in pairs(P and P.customSpells or {}) do
		if c then
			c = c == "immunity_spell" and "immunity" or c
			custom[c] = custom[c] or {}
			custom[c][tonumber(id) or id] = true
		end
	end
	local seen = {}
	local function take(list, extra)
		local out = {}
		for id in pairs(list or {}) do if not seen[id] then out[id] = true; seen[id] = true end end
		for id in pairs(extra or {}) do if not seen[id] then out[id] = true; seen[id] = true end end
		return out
	end
	-- custom spells first, so they belong to the category picked for them
	for _, c in ipairs(DEBUFF_CATS) do ids[c] = take(custom[c]) end
	for _, c in ipairs(DEBUFF_CATS) do for id in pairs(take(cat[c])) do ids[c][id] = true end end
	seen = {}
	for _, c in ipairs(BUFF_CATS) do ids[c] = take(custom[c]) end
	for id in pairs(take(cat.immunity, cat.immunity_spell)) do ids.immunity[id] = true end
	for _, c in ipairs(BUFF_CATS) do if c ~= "immunity" then for id in pairs(take(cat[c])) do ids[c][id] = true end end end
end
core.BuildIds = BuildIds
core.ids = ids

local function Union(list, into)
	into = into or {}
	for _, c in ipairs(list) do for id in pairs(ids[c] or {}) do into[id] = true end end
	return into
end

-- Debuffs Ahmed's Warmane profiles recorded that only exist from TBC or Wrath on.
core.NOT_ON_FOREVER = {
	["blood frenzy"] = true, ["shattering throw"] = true, ["trauma"] = true, ["unrelenting assault"] = true,
	["avenger's shield"] = true, ["heart of the crusader"] = true, ["holy vengeance"] = true,
	["judgements of the just"] = true, ["vindication"] = true,
}
-- 1.x debuffs the rank table (from MiniAuras) does not list
local EXTRA_RANKS = {
	["deep wounds"] = { 12721 }, ["dazed"] = { 1604 }, ["forbearance"] = { 25771 },
	["judgement of justice"] = { 20184 }, ["judgement of light"] = { 20185, 20344, 20345, 20346 },
	["judgement of wisdom"] = { 20186, 20354, 20355 },
}
for name, list in pairs(EXTRA_RANKS) do ns.RanksByName[name] = ns.RanksByName[name] or list end

-- Every Forever rank of a spell name (the Warmane settings store names).
local function IdsForName(name, out)
	local fam = ns.RanksByName[name:lower()]
	if fam then for _, id in ipairs(fam) do out[id] = true end end
	return out
end

local PRIO_KEY = {
	cc = "sidePrioCC", root = "sidePrioRoot", snare = "sidePrioSnare", disarm = "sidePrioDisarm",
	healing_reduction = "sidePrioHealing", immunity = "sidePrioImmunity", buff_def = "sidePrioDefensive",
	buff_off = "sidePrioOffensive", shield = "sidePrioShield", speed = "sidePrioSpeed", buff_other = "sidePrioOther",
	tag_bigdef = "sidePrioImmunity", tag_extdef = "sidePrioDefensive", tag_important = "sidePrioOffensive", short = "sidePrioOffensive",
}

------------------------------------------------------------------------------------------------
-- Row layout -> aura groups
------------------------------------------------------------------------------------------------
local TOP_KEYS = { "rowTop1", "rowTop2", "rowTop3", "rowTop4", "rowTop5", "rowTop6" }

local function ActiveRows()
	local list = {}
	local function add(k) local r = P[k]; if r and r.enabled then list[#list + 1] = k end end
	add("rowLeft"); add("rowRight")
	for i = 1, math.min(P.topRowCount or 1, 6) do add(TOP_KEYS[i]) end
	-- rows set to "only my auras" take their auras first, like on Warmane
	local mine, rest = {}, {}
	for _, k in ipairs(list) do
		if P[k].onlyMine or (k == "rowTop1" and P[k].myDebuffs) then mine[#mine + 1] = k else rest[#rest + 1] = k end
	end
	for _, k in ipairs(rest) do mine[#mine + 1] = k end
	return mine
end

local function CatColor(c)
	local g = P.catGlow and P.catGlow[c]
	local col = g and g.color or { 1, 1, 1 }
	return { col[1], col[2], col[3], glowType = g and g.type or "none" }
end

-- Builds { rowKey -> list of group specs } for one side ("enemy" or "friend").
-- A spec: { key, filter, candidates, color, prio, mapped }.
local function BuildLayout(side)
	local rows = {}
	local order = ActiveRows()
	-- each category goes to the first row (in priority order) that shows it and can show it here
	local owner = {}
	for _, k in ipairs(order) do
		local row = P[k]
		if not (k == "rowTop1" and row.myDebuffs) and row.cats then
			for c in pairs(WORKS) do
				if row.cats[c] and not owner[c] and Works(c, side) then
					local debuff = IS_DEBUFF[c]
					if (debuff and row.show ~= "buffs") or (not debuff and row.show ~= "debuffs") then owner[c] = k end
				end
			end
		end
	end

	-- with "My debuffs" on, my own debuffs go to the top row before any other row
	local myRow = P.rowTop1 and P.rowTop1.enabled and P.rowTop1.myDebuffs and side == "enemy"
	-- buff tags taken by a row are kept out of the groups below them, so nothing shows twice
	local function NotTags(f, upto)
		for _, t in ipairs(TAG_CATS) do
			if t == upto then break end
			if owner[t] then f = f .. "|!" .. TAG_TOKEN[t] end
		end
		return f
	end
	-- friendly plates: buffs on a spell list that a row shows stay with that list
	local listed = {}
	if side == "friend" then for _, c in ipairs(BUFF_CATS) do if owner[c] then Union({ c }, listed) end end end
	-- spells hidden on the Spells page: the client only honours id lists on harmful auras of
	-- enemies and helpful auras of friends, so that is where hiding works
	local hiddenIds = {}
	for id, on in pairs(P.hiddenSpells or {}) do if on then hiddenIds[tonumber(id) or id] = true end end
	for name, on in pairs(P.hiddenNames or {}) do if on then IdsForName(name, hiddenIds) end end
	if side == "friend" then for id in pairs(hiddenIds) do listed[id] = true end end
	local function Without(set)
		if not next(hiddenIds) then return set end
		local out = {}
		for id in pairs(set or {}) do if not hiddenIds[id] then out[id] = true end end
		return out
	end
	local function Copy(t) local o = {} for k in pairs(t) do o[k] = true end return o end
	-- "Hide buffs without a duration" caps every buff group (the filter is a maximum length)
	local noDuration = P.sideHideNoDuration and 3600 or nil
	local function Cap(cand)
		if noDuration then
			cand = cand or {}
			if not cand.maxDuration or cand.maxDuration > noDuration then cand.maxDuration = noDuration end
		end
		return cand
	end
	local function NotListed(cand)
		if next(listed) then cand = cand or {}; cand.excludeSpellIDs = listed end
		return cand
	end

	for _, k in ipairs(order) do
		local row = P[k]
		local groups = {}
		local mineOnly = row.onlyMine
		local function add(key, filter, candidates, c, prio, mapped)
			candidates = candidates or {}
			-- an empty id map means "no ids required" to the client, so it would match everything
			if candidates.includeSpellIDs and next(candidates.includeSpellIDs) == nil then
				candidates.includeSpellIDs = { [2147483647] = true }
			end
			if candidates.excludeSpellIDs and next(candidates.excludeSpellIDs) == nil then
				candidates.excludeSpellIDs = nil
			end
			if mineOnly then
				candidates.isFromPlayerOrPlayerPet = true
				if not filter:find("PLAYER", 1, true) then filter = filter .. "|PLAYER" end
			end
			if next(candidates) == nil then candidates = nil end
			groups[#groups + 1] = { key = key, filter = filter, candidates = candidates, color = c, prio = prio or 0, mapped = mapped,
				helpful = filter:find("^HELPFUL") ~= nil }
		end
		local function Prio(c) return P[PRIO_KEY[c]] or 0 end

		if k == "rowTop1" and row.myDebuffs then
			-- my debuffs come here first (like on Warmane); hard crowd control and disarms stay on the
			-- row that shows them, and the ones hidden in the Spells tab are left out
			local exclude = {}
			-- (also what an "only my auras" row takes: my debuffs on that row's lists stay there)
			for _, c in ipairs(DEBUFF_CATS) do
				if owner[c] and owner[c] ~= k and (c == "cc" or c == "disarm" or P[owner[c]].onlyMine) then Union({ c }, exclude) end
			end
			for name, hidden in pairs(P.myDebuffHidden or {}) do if hidden then IdsForName(name, exclude) end end
			for id in pairs(hiddenIds) do exclude[id] = true end
			if side == "enemy" then
				add("mine", "HARMFUL|PLAYER|!CROWD_CONTROL", { isFromPlayerOrPlayerPet = true, excludeSpellIDs = exclude }, CatColor("mydebuffs"), 0, next(exclude) ~= nil)
			else
				add("mine", "HARMFUL|PLAYER", { isFromPlayerOrPlayerPet = true }, CatColor("mydebuffs"))
			end
		else
			-- debuffs: the game's crowd control tag everywhere, the Warmane lists on enemies
			for _, c in ipairs(DEBUFF_CATS) do
				if owner[c] == k then
					if c == "cc" then add("cc_tag", "HARMFUL|CROWD_CONTROL", side == "enemy" and next(hiddenIds) and { excludeSpellIDs = Copy(hiddenIds) } or nil, CatColor(c), Prio(c) + 0.5) end
					if side == "enemy" then
						local cand = { includeSpellIDs = Without(ids[c]) }
						local f = "HARMFUL|!CROWD_CONTROL"
						-- my own go to the top row first, unless this row only shows my auras
						if myRow and not mineOnly and c ~= "cc" and c ~= "disarm" then cand.isFromPlayerOrPlayerPet = false; f = f .. "|!PLAYER" end
						add(c, f, cand, CatColor(c), Prio(c), true)
					end
				end
			end
			-- buffs the game tags (every plate)
			if owner.tag_bigdef == k then add("bigdef", "HELPFUL|BIG_DEFENSIVE", Cap(NotListed()), CatColor("tag_bigdef"), Prio("tag_bigdef") + 0.5) end
			if owner.tag_extdef == k then add("extdef", NotTags("HELPFUL|EXTERNAL_DEFENSIVE", "tag_extdef"), Cap(NotListed()), CatColor("tag_extdef"), Prio("tag_extdef")) end
			if owner.tag_important == k then add("imp", NotTags("HELPFUL|IMPORTANT", "tag_important"), Cap(NotListed()), CatColor("tag_important"), Prio("tag_important")) end
			if owner.short == k then
				add("short", NotTags("HELPFUL"), NotListed({ maxDuration = P.foreverShortSeconds or 30 }), CatColor("short"), Prio("short") - 0.5)
			end
			-- buffs by spell list (friendly plates only)
			if side == "friend" then
				for _, c in ipairs(BUFF_CATS) do
					if owner[c] == k then add(c, "HELPFUL", Cap({ includeSpellIDs = Without(ids[c]) }), CatColor(c), Prio(c)) end
				end
			end
			-- everything else
			if row.cats and row.cats.any then
				-- an "only my auras" row adds nothing here while My debuffs shows all of mine on top
				if row.show ~= "buffs" and not (myRow and mineOnly) then
					local f = owner.cc and "HARMFUL|!CROWD_CONTROL" or "HARMFUL"
					local cand
					if side == "enemy" then
						local owned = {}
						for _, c in ipairs(DEBUFF_CATS) do if owner[c] then owned[#owned + 1] = c end end
						cand = { excludeSpellIDs = Union(owned, Copy(hiddenIds)) }
						if myRow then cand.isFromPlayerOrPlayerPet = false; f = f .. "|!PLAYER" end
					end
					add("anydebuff", f, cand, CatColor("buff_other"), -1, cand ~= nil)
				end
				-- The client has no minimum-length filter, so a short buff would match both the short
				-- group and this one and show twice. Unless asked, this row leaves buffs to it.
				local shortTaken = owner.short and not P.anyBuffsWithShort
				if row.show ~= "debuffs" and not shortTaken then
					add("anybuff", NotTags("HELPFUL"), NotListed(noDuration and { maxDuration = noDuration } or nil), CatColor("buff_other"), -2)
				end
			end
		end
		table.sort(groups, function(a, b) return a.prio > b.prio end)
		if owner.interrupt == k and side == "enemy" then rows.interruptRow = k end
		if #groups > 0 then rows[k] = groups end
	end
	return rows
end

------------------------------------------------------------------------------------------------
-- Containers
------------------------------------------------------------------------------------------------
local FLOW = {
	left = { axis = "Horizontal", anchor = "TOPRIGHT", h = "Left", v = "Down", point = "RIGHT", rel = "LEFT" },
	right = { axis = "Horizontal", anchor = "TOPLEFT", h = "Right", v = "Down", point = "LEFT", rel = "RIGHT" },
	top = { axis = "Horizontal", anchor = "BOTTOMLEFT", h = "Right", v = "Up", point = "BOTTOM", rel = "TOP" },
}

local function RowGeometry(k, side)
	if side == "friend" and P.friendlyTopRowOnly then
		return "top", P.friendlyMax, P.friendlySize, P.friendlyGlow, P.friendlyOffsetX or P.topOffsetX, P.friendlyOffsetY or P.topOffsetY
	end
	local row = P[k]
	if k == "rowLeft" or k == "rowRight" then
		local s = k == "rowLeft" and "Left" or "Right"
		local x = P["side" .. s .. "OffsetX"] or P.sideOffsetX or 0
		local y = P["side" .. s .. "OffsetY"] or P.sideOffsetY or 0
		return k == "rowLeft" and "left" or "right", row.max, row.size, row.glow, k == "rowLeft" and -x or x, y
	end
	-- top rows stack upwards
	local y = P.topOffsetY or 0
	for _, tk in ipairs(TOP_KEYS) do
		if tk == k then break end
		local r = P[tk]
		local i = tonumber(tk:match("%d"))
		if r and r.enabled and i <= (P.topRowCount or 1) then y = y + r.size + (P.topRowSpacing or 2) end
	end
	return "top", row.max, row.size, row.glow, P.topOffsetX or 0, y
end

-- Static glows only, like MiniAuras: a looping animation would run on every pre-built button, and
-- buttons cannot be scripted while auras are secret. The Warmane glow types map to two looks.
local GLOW_LOOK = {
	proc = "halo", button = "halo", shine = "halo",
	pixel = "pixel", border = "pixel",
}
local SLOT_GLOW = "Interface\\AddOns\\" .. ADDON .. "\\media\\SlotGlow.tga"

local function AddGlow(button, color, size)
	local look = GLOW_LOOK[color.glowType]
	if not look then return end
	local glow = CreateFrame("Frame", nil, button)
	glow:SetFrameLevel(button:GetFrameLevel() + 5)
	local tex = glow:CreateTexture(nil, "OVERLAY")
	tex:SetAllPoints()
	local pad
	if look == "halo" then
		tex:SetTexture(SLOT_GLOW)
		tex:SetBlendMode("BLEND")
		pad = size / 5
	else
		tex:SetAtlas("wowlabs-spell-icon-frame-highlight")
		tex:SetDesaturated(true)
		tex:SetBlendMode("BLEND")
		pad = size * 0.15
	end
	tex:SetVertexColor(color[1], color[2], color[3], 1)
	glow:SetPoint("TOPLEFT", button, "TOPLEFT", -pad, pad)
	glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", pad, -pad)
	glow:Show()
	return tex
end
core.AddGlow = AddGlow

-- Glow on enemy buffs the player can dispel or steal: the client shows it only on those.
local function HasStealFilter()
	return Enum and Enum.CustomAuraButtonDispelTypeStealableFilter and Enum.CustomAuraButtonDispelTypeStealableFilter.Stealable
		and Enum.CustomAuraButtonDispelTypeTextureStyle and true or false
end

local function AddDispelGlow(button, size)
	if not (HasStealFilter() and button.AddDispelTypeTexture) then return end
	local col = P.dispelGlowColor or { 0.7, 0.45, 1 }
	local look = { glowType = P.dispelGlowType == "pixel" and "pixel" or "proc", col[1], col[2], col[3] }
	local tex = AddGlow(button, look, size)
	if not tex then return end
	local map = {}
	for _, k in ipairs({ "Magic", "Curse", "Disease", "Poison", "Bleed", "None", "" }) do
		map[k] = CreateColor(col[1], col[2], col[3], 1)
	end
	button:AddDispelTypeTexture(tex, {
		style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
		showWhenHarmful = false,
		showWhenHelpful = true,
		showWithoutDispelType = true,
		stealableFilter = Enum.CustomAuraButtonDispelTypeStealableFilter.Stealable,
		customDispelColorMap = map,
	})
end

local function DurationTextSupported()
	return C_StringUtil and C_StringUtil.CreateNumericRuleFormatter and Enum.NumericRuleFormatRounding and true or false
end

-- Same formatter as MiniAuras: tenths under the threshold, whole seconds, then minutes and hours.
local formatters = {}
local function Formatter(threshold)
	local fmt = formatters[threshold]
	if fmt then return fmt end
	local down, up = Enum.NumericRuleFormatRounding.Down, Enum.NumericRuleFormatRounding.Up
	fmt = C_StringUtil.CreateNumericRuleFormatter()
	if threshold > 0 then
		fmt:AddBreakpoint({ threshold = 0, step = 0.1, format = "%.1f" })
		fmt:AddBreakpoint({ threshold = threshold, step = 1, rounding = up, format = "%d" })
	else
		fmt:AddBreakpoint({ threshold = 0, step = 1, rounding = up, format = "%d" })
	end
	fmt:AddBreakpoint({ threshold = 91, step = 1, rounding = down, min = 1, format = "%dm", components = { { div = 60, rounding = up } } })
	fmt:AddBreakpoint({ threshold = 5401, step = 1, rounding = down, min = 1, format = "%dh", components = { { div = 3600, rounding = up } } })
	formatters[threshold] = fmt
	return fmt
end

-- Timer colour by time left (white > yellow > orange > red), drawn by the client from a colour
-- curve bound to the aura's remaining duration, the way MiniAuras colours its countdown.
local timeCurve
-- colour by share of the full duration when the client can (RemainingPercent), else by seconds
local PERCENT_PROP = Enum.DurationTextBindingProperty and Enum.DurationTextBindingProperty.RemainingPercent
core.timerByPercent = PERCENT_PROP ~= nil
local function Bands()
	local t
	if PERCENT_PROP then
		t = { P.timerYellowPct or 50, P.timerOrangePct or 25, P.timerRedPct or 10 }
	else
		t = { P.timerYellowAt or 10, P.timerOrangeAt or 5, P.timerRedAt or 3 }
	end
	table.sort(t, function(a, b) return a > b end)
	return t[1], t[2], t[3]
end
local function TimeCurve()
	if timeCurve then return timeCurve end
	if not (C_CurveUtil and C_CurveUtil.CreateColorCurve and Enum.LuaCurveType and Enum.DurationTextBindingProperty) then return nil end
	local c = C_CurveUtil.CreateColorCurve()
	c:SetType(Enum.LuaCurveType.Linear)
	local col = P.timerColors
	local y, o, r = Bands()
	local function C(t) return CreateColor(t[1], t[2], t[3]) end
	-- descending x, hard steps (each band edge is two points a hair apart)
	local function Band(top, scale, eps)
		c:AddPoint(top, C(col.white))
		c:AddPoint(y * scale + eps, C(col.white))
		c:AddPoint(y * scale, C(col.yellow))
		c:AddPoint(o * scale + eps, C(col.yellow))
		c:AddPoint(o * scale, C(col.orange))
		c:AddPoint(r * scale + eps, C(col.orange))
		c:AddPoint(r * scale, C(col.red))
	end
	if PERCENT_PROP then
		-- The client's docs do not say whether RemainingPercent runs 0-1 or 0-100, so the curve
		-- carries both: a 0-100 copy above 1 and a 0-1 copy below it. Whichever the client uses,
		-- the bands land on the same share of the aura's full duration.
		Band(100, 1, 0.05)
		c:AddPoint(1.0001, C(col.red))
		Band(1, 0.01, 0.0005)
	else
		Band(36000, 1, 0.05)
	end
	c:AddPoint(0, C(col.red))
	timeCurve = c
	return c
end
core.ResetTimeCurve = function() timeCurve = nil end

-- Same colours for timers the addon draws itself (interrupts, test mode).
function core.TimerColor(left, total)
	local col = P.timerColors
	if not P.timerColorByTime then return 1, 1, 1 end
	local y, o, r = Bands()
	local v = left
	if PERCENT_PROP then v = (total and total > 0) and left / total * 100 or 100 end
	local t = v < r and col.red or v < o and col.orange or v < y and col.yellow or col.white
	return t[1], t[2], t[3]
end

local function InitButton(button, color, size, glow, dispel)
	if button.SetFlattensRenderLayers then button:SetFlattensRenderLayers(true) end
	button:SetSize(size, size)
	button:EnableMouse(false)

	local border = button:CreateTexture(nil, "BACKGROUND", nil, 0)
	local thick = 1
	border:SetPoint("TOPLEFT", -thick, thick)
	border:SetPoint("BOTTOMRIGHT", thick, -thick)
	local c = P.borderColorMode == "category" and color or P.borderCustomColor or { 0, 0, 0 }
	border:SetColorTexture(c[1], c[2], c[3], 1)

	local icon = button:CreateTexture(nil, "BACKGROUND", nil, 1)
	icon:SetAllPoints(button)
	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	button:SetIcon(icon)

	local cd = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	cd:SetAllPoints(button)
	cd:SetDrawEdge(false)
	cd:SetDrawBling(false)
	cd:SetReverse(true)
	button:SetDurationCooldown(cd)

	-- Text scales with the icon like on Warmane: setting x (row size / icon size setting).
	local scale = size / math.max(1, P.iconSize or 28)
	local overlay = CreateFrame("Frame", nil, button)
	overlay:SetAllPoints(button)
	overlay:SetFrameLevel(cd:GetFrameLevel() + 2)

	-- Our own timer text, bound to the aura by the client (MiniAuras does the same). The cooldown's
	-- own numbers are hidden, so OmniCC-style addons cannot restyle them to a fixed size.
	local text = DurationTextSupported() and overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	if text and P.showCooldown then
		cd:SetHideCountdownNumbers(true)
		text:SetFont(STANDARD_TEXT_FONT, math.max(6, (P.cooldownSize or 11) * scale), "OUTLINE")
		text:SetPoint("CENTER", button, "CENTER", 0, 0)
		local curve = P.timerColorByTime and TimeCurve()
		button:SetDurationText(text, {
			textFormatter = Formatter(P.decimalThreshold or 5),
			textColor = curve and { curve = curve, property = PERCENT_PROP or Enum.DurationTextBindingProperty.RemainingDuration } or nil,
		})
	else
		cd:SetHideCountdownNumbers(not P.showCooldown)
		local fs = cd.GetCountdownFontString and cd:GetCountdownFontString()
		if fs then
			local font, _, flags = fs:GetFont()
			if font then fs:SetFont(font, math.max(6, (P.cooldownSize or 11) * scale), flags or "OUTLINE") end
		end
	end

	local stacks = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	local font, _, flags = stacks:GetFont()
	if font then stacks:SetFont(font, math.max(6, (P.stackSize or 8) * scale), flags or "OUTLINE") end
	stacks:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
	button:SetApplicationCount(stacks)

	if glow then AddGlow(button, color, size) end
	if dispel then AddDispelGlow(button, size) end
end

-- One spelling per filter, like MiniAuras: tokens sorted by name, a negation right after its token.
local canonical = {}
local function Canonical(f)
	if canonical[f] then return canonical[f] end
	local tokens, seen = {}, {}
	for t in f:gmatch("[^|%s]+") do if not seen[t] then seen[t] = true; tokens[#tokens + 1] = t end end
	table.sort(tokens, function(a, b)
		local ba, bb = a:gsub("^!", ""), b:gsub("^!", "")
		if ba ~= bb then return ba < bb end
		return a:byte(1) ~= 33 and b:byte(1) == 33
	end)
	canonical[f] = table.concat(tokens, "|")
	return canonical[f]
end

local counter = 0
local function NewContainer(k, side, groups)
	local where, max, size, glow, x, y = RowGeometry(k, side)
	local f = FLOW[where]
	counter = counter + 1
	local frame = CreateFrame("AuraContainer", "SkomsPlateBuffs_C" .. counter, UIParent, "CustomAuraContainerTemplate")
	frame:Hide()
	frame:SetFlowLayoutAxis(AnchorUtil.FlowLayoutAxis[f.axis])
	frame:SetFlowLayoutAnchorPoint(f.anchor)
	frame:SetFlowLayoutGrowthDirection(AnchorUtil.FlowDirection[f.h], AnchorUtil.FlowDirection[f.v])
	frame:SetUnit("none")
	local spacing = where == "top" and (P.topSpacing or 2) or (P.sideSpacing or 2)
	local c = { frame = frame, where = where, x = x, y = y, max = max, mapped = {} }
	for i, g in ipairs(groups) do
		local dispel = side == "enemy" and P.dispelGlow and g.helpful
			and (P.dispelGlowScope == "all" or g.key == "anybuff")
		frame:AddAuraGroup(g.key, Canonical(g.filter), {
			maxFrameCount = max,
			candidateFilters = g.candidates,
			-- my debuffs: soonest to expire first; the rest keep the order they arrived in
			sortMethod = AuraContainerSortMethod and (g.key == "mine" and AuraContainerSortMethod.ExpirationOnly or AuraContainerSortMethod.AuraInstanceIDOnly) or nil,
			sortDirection = AuraContainerSortDirection and AuraContainerSortDirection.Normal or nil,
			initializeFrame = function(button) InitButton(button, g.color, size, glow, dispel) end,
			layout = {
				elementSpacing = spacing, lineSpacing = spacing, elementSpacingX = spacing, elementSpacingY = spacing,
				elementWidth = size, elementHeight = size, layoutIndex = i,
			},
		})
		if g.mapped then c.mapped[#c.mapped + 1] = g.key end
	end
	return c
end

local layouts -- side -> rowKey -> groups
local sets = {} -- plate -> { enemy = {containers}, friend = {containers} }
local warned = false

-- The layout a side really uses: friendly plates may have their own single top row.
local function SideLayout(side)
	if not layouts then return {} end
	if not (side == "friend" and P.friendlyTopRowOnly) then return layouts[side] or {} end
	if layouts.friendTop then return layouts.friendTop end
	-- one top row with the friendly categories
	local saved = P.rowTop1
	local fake = { enabled = true, max = P.friendlyMax, size = P.friendlySize, glow = P.friendlyGlow, show = "all", cats = P.friendlyCats }
	P.rowTop1 = fake
	local oldCount, oldLeft, oldRight = P.topRowCount, P.rowLeft.enabled, P.rowRight.enabled
	P.topRowCount, P.rowLeft.enabled, P.rowRight.enabled = 1, false, false
	local ok, l = pcall(BuildLayout, "friend")
	P.rowTop1, P.topRowCount, P.rowLeft.enabled, P.rowRight.enabled = saved, oldCount, oldLeft, oldRight
	layouts.friendTop = ok and l or {}
	return layouts.friendTop
end

-- Would this library entry land in a row? Same checks the client makes, on what was recorded.
local function GroupTakes(g, e, id, kind)
	local want = kind == "b" and "HELPFUL" or "HARMFUL"
	for tok in g.filter:gmatch("[^|]+") do
		local neg = tok:sub(1, 1) == "!"
		local t = neg and tok:sub(2) or tok
		if t == "HELPFUL" or t == "HARMFUL" then
			if t ~= want then return false end
		elseif t == "PLAYER" then
			if neg then if e.me and not e.o then return false end
			elseif not e.me then return false end
		else
			local has = (e.tg and e.tg[t]) and true or false
			if neg == has then return false end
		end
	end
	local c = g.candidates
	if c then
		if c.includeSpellIDs and not c.includeSpellIDs[id] then return false end
		if c.excludeSpellIDs and c.excludeSpellIDs[id] then return false end
		if c.maxDuration and not (e.du and e.du > 0 and e.du <= c.maxDuration) then return false end
		if c.isFromPlayerOrPlayerPet == true and not e.me then return false end
		if c.isFromPlayerOrPlayerPet == false and e.me and not e.o then return false end
	end
	return true
end
local ROW_ORDER = { "rowLeft", "rowRight", "rowTop1", "rowTop2", "rowTop3", "rowTop4", "rowTop5", "rowTop6" }
-- { { side = "enemy"|"friend", row = key }, ... } for the plates it was seen on
function core.WhereShown(e, id, kind)
	local out = {}
	for _, side in ipairs({ "enemy", "friend" }) do
		if e[side == "enemy" and "e" or "f"] then
			local lay = SideLayout(side)
			for _, k in ipairs(ROW_ORDER) do
				local groups = lay[k]
				if type(groups) == "table" then
					for _, g in ipairs(groups) do
						if GroupTakes(g, e, id, kind) then out[#out + 1] = { side = side, row = k }; break end
					end
				end
			end
		end
	end
	return out
end

local function BuildSet(side)
	local list = {}
	local lay = SideLayout(side)
	for k, groups in pairs(lay) do
		if k == "interruptRow" then list.interruptRow = groups; groups = nil end
		local ok, c = true, nil
		if groups then ok, c = pcall(NewContainer, k, side, groups) end
		if ok and c then c.rowKey = k end
		if ok and c then
			list[#list + 1] = c
		elseif not ok and not warned then
			warned = true
			Print("could not build a row: %s", tostring(c))
		end
	end
	return list
end

local function AnchorFrame(plate)
	local uf = plate.UnitFrame
	if P.sideAnchorHealthBar and uf and uf.HealthBarsContainer then return uf.HealthBarsContainer end
	return uf or plate
end

local function Shown(unit, friendly)
	local isPlayer = UnitIsPlayer(unit)
	if not IsSecret(isPlayer) then
		if isPlayer and not P.abovePlayers then return false end
		if not isPlayer and not P.aboveNPC then return false end
	end
	if friendly then return P.aboveFriendly end
	local reaction = UnitReaction(unit, "player")
	if not IsSecret(reaction) and reaction == 4 then return P.aboveNeutral end
	return P.aboveHostile
end

local function HideSet(list)
	for _, c in ipairs(list or {}) do
		c.frame:Hide()
		c.frame:SetUnit("none")
	end
end

function core:Attach(unit)
	if not P or UnitIsUnit(unit, "player") then return end
	local plate = C_NamePlate.GetNamePlateForUnit(unit)
	if not plate then return end
	local assist = UnitCanAssist("player", unit)
	-- spell-id maps on debuffs only work on units we cannot assist; a secret answer is treated as friendly
	local friendly = IsSecret(assist) or assist
	local side = friendly and "friend" or "enemy"
	local set = sets[plate]
	if not set then set = {}; sets[plate] = set end
	HideSet(set[friendly and "enemy" or "friend"])
	if not Shown(unit, friendly and not IsSecret(assist)) then HideSet(set[side]); return end
	set[side] = set[side] or BuildSet(side)
	local anchor = AnchorFrame(plate)
	set.side, set.anchor, set.unit, set.plate = side, anchor, unit, plate
	if set.kick then set.kick:Hide(); set.kickToken = (set.kickToken or 0) + 1 end
	for _, c in ipairs(set[side]) do
		local f, frame = FLOW[c.where], c.frame
		frame:Hide()
		frame:SetParent(plate)
		frame:ClearAllPoints()
		frame:SetPoint(f.point, anchor, f.rel, c.x, c.y)
		frame:SetFrameLevel(anchor:GetFrameLevel() + 10)
		frame:SetUnit(unit)
		frame:Show() -- showing is what makes the client re-read the unit
	end
end

function core:Detach(unit)
	local plate = C_NamePlate.GetNamePlateForUnit(unit)
	local set = plate and sets[plate]
	if set then
		HideSet(set.enemy); HideSet(set.friend)
		set.unit = nil
		if set.kick then set.kick:Hide(); set.kickToken = (set.kickToken or 0) + 1 end
	end
end

------------------------------------------------------------------------------------------------
-- Interrupt lockouts. Not an aura, and Forever hides the combat log, but the cast-stop event on a
-- nameplate says whether the cast was interrupted (the interrupter is secret, only its presence
-- can be tested). The lockout length cannot be read, so it is a setting.
------------------------------------------------------------------------------------------------
local KICK_ICON = 132938 -- Kick

-- Interrupts and their lockout on Forever, by every rank's id. When the kick is yours (or your
-- pet's) the addon knows which spell it was from your own cast, so it shows that spell and its
-- length. Anyone else's kick shows the generic icon and the length set in Rows.
local INTERRUPTS = {
	-- name, lockout seconds, ids
	{ "Shield Bash", 3, { 72, 1671, 1672 } },
	{ "Pummel", 4, { 6552, 6554 } },
	{ "Kick", 5, { 1766, 1767, 1768, 1769 } },
	{ "Counterspell", 8, { 2139 } },
	{ "Earth Shock", 2, { 8042, 8044, 8045, 8046, 10412, 10413, 10414 } },
	{ "Spell Lock", 6, { 19244, 19647 } },
	{ "Feral Charge", 4, { 1238122 } },
}
local INTERRUPT_BY_ID = {}
for _, e in ipairs(INTERRUPTS) do for _, id in ipairs(e[3]) do INTERRUPT_BY_ID[id] = e end end
core.INTERRUPTS = INTERRUPTS

local lastKick -- { spellId, time } of my or my pet's last interrupt cast

local function KickLength(e)
	local custom = P.interruptLengths and P.interruptLengths[e[1]]
	return custom or e[2]
end

local function KickFrame(set)
	local b = set.kick
	if b then return b end
	b = CreateFrame("Frame", nil, set.plate)
	b.border = b:CreateTexture(nil, "BACKGROUND", nil, 0)
	b.border:SetPoint("TOPLEFT", -1, 1)
	b.border:SetPoint("BOTTOMRIGHT", 1, -1)
	b.icon = b:CreateTexture(nil, "BACKGROUND", nil, 1)
	b.icon:SetAllPoints()
	b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
	b.cd:SetAllPoints()
	b.cd:SetDrawEdge(false)
	b.cd:SetReverse(true)
	set.kick = b
	return b
end

local function RowContainer(set, rowKey)
	for _, c in ipairs(set.enemy or {}) do if c.rowKey == rowKey then return c end end
end

local function PlaceRow(set, c, shift)
	local f = FLOW[c.where]
	local dx = c.where == "left" and -shift or shift
	c.frame:ClearAllPoints()
	c.frame:SetPoint(f.point, set.anchor, f.rel, c.x + dx, c.y)
end

function core:OnInterrupted(unit, spellId)
	local plate = C_NamePlate.GetNamePlateForUnit(unit)
	local set = plate and sets[plate]
	if not (set and set.side == "enemy" and set.enemy and set.enemy.interruptRow and P.showInterrupts ~= false) then return end
	local rowKey = set.enemy.interruptRow
	local where, _, size, glow, x, y = RowGeometry(rowKey, "enemy")
	local spacing = where == "top" and (P.topSpacing or 2) or (P.sideSpacing or 2)
	local b = KickFrame(set)
	b:SetParent(set.plate)
	b:SetFrameLevel(set.anchor:GetFrameLevel() + 11)
	b:SetSize(size, size)
	local color = CatColor("interrupt")
	local bc = P.borderColorMode == "category" and color or P.borderCustomColor or { 0, 0, 0 }
	b.border:SetColorTexture(bc[1], bc[2], bc[3], 1)
	-- my own kick: its icon and length; anyone else's: generic icon, length from Rows
	local mine = lastKick and (GetTime() - lastKick.time) < 0.6 and INTERRUPT_BY_ID[lastKick.spellId]
	local dur = P.interruptLockout or 4
	if mine then
		lastKick = nil
		dur = KickLength(mine)
		local tex = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(mine[3][1])
		b.icon:SetTexture(tex or KICK_ICON)
	else
		b.icon:SetTexture(KICK_ICON)
	end
	if glow and not b.glowTex then b.glowTex = AddGlow(b, color, size) end
	if b.glowTex then b.glowTex:GetParent():SetShown(glow and true or false); b.glowTex:SetVertexColor(color[1], color[2], color[3], 1) end
	local fs = b.cd.GetCountdownFontString and b.cd:GetCountdownFontString()
	if fs then fs:SetFont(STANDARD_TEXT_FONT, math.max(6, (P.cooldownSize or 11) * size / math.max(1, P.iconSize or 28)), "OUTLINE") end
	b.cd:SetCooldown(GetTime(), dur)
	if fs then
		local endTime = GetTime() + dur
		if b.ticker then b.ticker:Cancel() end
		b.ticker = C_Timer.NewTicker(0.1, function(t)
			local left = endTime - GetTime()
			if left <= 0 or not b:IsShown() then t:Cancel(); return end
			fs:SetTextColor(core.TimerColor(left, dur))
		end)
		fs:SetTextColor(core.TimerColor(dur, dur))
	end
	-- the lockout sits nearest the plate and pushes the row's auras outwards while it lasts
	b:ClearAllPoints()
	local f = FLOW[where]
	local c = RowContainer(set, rowKey)
	if where == "left" then
		b:SetPoint("RIGHT", set.anchor, "LEFT", x, y)
	elseif where == "right" then
		b:SetPoint("LEFT", set.anchor, "RIGHT", x, y)
	else
		b:SetPoint("BOTTOMRIGHT", set.anchor, "TOPLEFT", x - spacing, y)
	end
	if c and where ~= "top" then PlaceRow(set, c, size + spacing) end
	b:Show()
	set.kickToken = (set.kickToken or 0) + 1
	local token = set.kickToken
	C_Timer.After(dur, function()
		if set.kickToken ~= token then return end
		b:Hide()
		if c and where ~= "top" and set.anchor then PlaceRow(set, c, 0) end
	end)
end

local function ForEachPlate(fn)
	for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
		local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
		if unit then fn(unit) end
	end
end

-- Settings changed: throw the containers away and build new ones (their groups are fixed once made).
local pendingRebuild = false
-- WoW frames can never be freed, so containers are only rebuilt when what they were built with
-- changes (groups, sizes, looks). A change of position only moves the existing ones.
local function Ser(v, out)
	local t = type(v)
	if t == "table" then
		local keys = {}
		for k in pairs(v) do keys[#keys + 1] = k end
		table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
		out[#out + 1] = "{"
		for _, k in ipairs(keys) do out[#out + 1] = tostring(k) .. "="; Ser(v[k], out); out[#out + 1] = "," end
		out[#out + 1] = "}"
	else
		out[#out + 1] = tostring(v)
	end
end
local SKIN_KEYS = { "borderColorMode", "borderCustomColor", "cooldownSize", "stackSize", "showCooldown", "iconSize",
	"decimalThreshold", "timerColorByTime", "timerYellowPct", "timerOrangePct", "timerRedPct", "timerYellowAt",
	"timerOrangeAt", "timerRedAt", "timerColors", "dispelGlow", "dispelGlowScope", "dispelGlowType", "dispelGlowColor",
	"topSpacing", "sideSpacing" }
local builtKey
local function BuildKey()
	local out = {}
	for _, side in ipairs({ "enemy", "friend" }) do
		local lay = SideLayout(side)
		out[#out + 1] = side
		Ser(lay, out)
		local rows = {}
		for k in pairs(lay) do if k ~= "interruptRow" then rows[#rows + 1] = k end end
		table.sort(rows)
		for _, k in ipairs(rows) do
			local where, max, size, glow = RowGeometry(k, side)
			out[#out + 1] = table.concat({ k, where, tostring(max), tostring(size), tostring(glow) }, ":")
		end
	end
	for _, k in ipairs(SKIN_KEYS) do out[#out + 1] = k; Ser(P[k], out) end
	return table.concat(out, ";")
end

function core:ResetSideRows()
	if InCombatLockdown() then pendingRebuild = true; return end
	pendingRebuild = false
	P = core.db.profile
	Migrate(P)
	BuildIds()
	timeCurve = nil
	layouts = { enemy = BuildLayout("enemy") }
	layouts.friend = BuildLayout("friend")
	local key = BuildKey()
	if key ~= builtKey then
		for _, set in pairs(sets) do HideSet(set.enemy); HideSet(set.friend) end
		sets = {}
		builtKey = key
	else
		-- same containers: only their offsets may have changed (Attach below re-anchors them)
		for _, set in pairs(sets) do
			for _, side in ipairs({ "enemy", "friend" }) do
				for _, c in ipairs(set[side] or {}) do
					local _, _, _, _, x, y = RowGeometry(c.rowKey, side)
					c.x, c.y = x, y
				end
			end
		end
	end
	ForEachPlate(function(u) core:Attach(u) end)
	if core.RedrawTest then core.RedrawTest() end
end
core.Rebuild = core.ResetSideRows
core.BuildLayout = BuildLayout
core.RowGeometry = RowGeometry
core.FLOW = FLOW
core.AnchorFrame = AnchorFrame
core.ForEachPlate = ForEachPlate

------------------------------------------------------------------------------------------------
-- Start up
------------------------------------------------------------------------------------------------
local function DeepCopy(t)
	local c = {}
	for k, v in pairs(t) do c[k] = type(v) == "table" and DeepCopy(v) or v end
	return c
end

local IMPORT_PROFILE = "Sync_Retail"

-- Aura discovery: out of combat the client tells addons which spell each nameplate aura is, so
-- every one seen is remembered (account wide) for the Spells page, where it can be hidden.
core.defaultSettings.global = { seen = {} }
local SEEN_MAX = 2000
core.seenCount = 0
local function Record(unit)
	if InCombatLockdown() or not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return end
	local store = core.db and core.db.global and core.db.global.seen
	if not store or not UnitExists(unit) then return end
	local assist = UnitCanAssist("player", unit)
	if IsSecret(assist) then return end
	local who = assist and "f" or "e"
	local now = time()
	for _, filter in ipairs({ "HELPFUL", "HARMFUL" }) do
		for i = 1, 40 do
			local a = C_UnitAuras.GetAuraDataByIndex(unit, i, filter)
			if not a then break end
			local id, name = a.spellId, a.name
			-- only auras the game itself would put on a nameplate (its own nameplate filter)
			local np
			local npToken = AuraUtil and AuraUtil.AuraFilters and AuraUtil.AuraFilters.IncludeNameplateOnly
			if npToken and a.auraInstanceID and C_UnitAuras.IsAuraFilteredOutByInstanceID and not IsSecret(a.auraInstanceID) then
				local ok, out = pcall(C_UnitAuras.IsAuraFilteredOutByInstanceID, unit, a.auraInstanceID, filter .. "|" .. npToken)
				if ok and not IsSecret(out) then np = not out end
			elseif a.nameplateShowAll ~= nil and not IsSecret(a.nameplateShowAll) then
				np = a.nameplateShowAll and true or false
			end
			-- (kept for information only: the rows here do not use the game's nameplate filter, so
			-- an aura it leaves out can still reach a row)
			if id and name and not IsSecret(id) and not IsSecret(name) then
				local e = store[id]
				if not e and core.seenCount < SEEN_MAX then
					e = { n = name }
					store[id] = e
					core.seenCount = core.seenCount + 1
				end
				if e then
					e[filter == "HELPFUL" and "b" or "d"] = true -- buff / debuff
					e[who] = true -- seen on enemy / friendly plates
					e.t = now
					e.np = np
					-- what the plates' filters need to place it: the game's tags, length, caster
					local iid = a.auraInstanceID
					if iid and not IsSecret(iid) and C_UnitAuras.IsAuraFilteredOutByInstanceID then
						e.tg = {}
						for _, t in ipairs({ "CROWD_CONTROL", "BIG_DEFENSIVE", "EXTERNAL_DEFENSIVE", "IMPORTANT" }) do
							local ok, out = pcall(C_UnitAuras.IsAuraFilteredOutByInstanceID, unit, iid, filter .. "|" .. t)
							if ok and not IsSecret(out) and not out then e.tg[t] = true end
						end
					end
					local du = a.duration
					if du and not IsSecret(du) then e.du = du end
					local src0 = a.sourceUnit
					if src0 and not IsSecret(src0) then
						local mine = UnitIsUnit(src0, "player") or UnitIsUnit(src0, "pet")
						if not IsSecret(mine) then if mine then e.me = true else e.o = true end end
					end
					-- who cast it: a player's class, or NPC (only when the caster has a unit token)
					local src = a.sourceUnit
					if src and not IsSecret(src) and UnitExists(src) then
						local isPlayer = UnitIsPlayer(src)
						if not IsSecret(isPlayer) then
							e.c = e.c or {}
							if isPlayer then
								local _, cls = UnitClass(src)
								if cls and not IsSecret(cls) then e.c[cls] = true end
							else
								e.c.NPC = true
							end
						end
					end
					local dn = a.dispelName
					if dn and not IsSecret(dn) then e.x = dn end
				end
			end
		end
	end
end
local scanPending = {}
local function QueueScan(unit)
	if scanPending[unit] or InCombatLockdown() then return end
	scanPending[unit] = true
	C_Timer.After(0.5, function()
		scanPending[unit] = nil
		pcall(Record, unit)
	end)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(_, event, arg, ...)
	if event == "ADDON_LOADED" then
		if arg ~= ADDON then return end
		ev:UnregisterEvent("ADDON_LOADED")
		local imported = false
		-- v0.1 kept a flat table with no profiles: replace it with the import too
		if SkomsPlateBuffsDB and not SkomsPlateBuffsDB.profiles then SkomsPlateBuffsDB = nil end
		if not SkomsPlateBuffsDB and ns.WarmaneDB then
			SkomsPlateBuffsDB = DeepCopy(ns.WarmaneDB)
			SkomsPlateBuffsDB.profileKeys = {}
			SkomsPlateBuffsDB.namespaces = nil
			imported = true
		end
		local default = (SkomsPlateBuffsDB and SkomsPlateBuffsDB.profiles and SkomsPlateBuffsDB.profiles[IMPORT_PROFILE]) and IMPORT_PROFILE or true
		core.db = LibStub("AceDB-3.0"):New("SkomsPlateBuffsDB", core.defaultSettings, default)
		for _, e in ipairs({ "OnProfileChanged", "OnProfileCopied", "OnProfileReset" }) do
			core.db.RegisterCallback(core, e, "ResetSideRows")
		end
		P = core.db.profile
		Migrate(P)
		-- one-off: put back the library emptied by mistake on 2026-11-20 (import.lua)
		if ns.SeenRestore and not core.db.global.restored20261120 then
			local seen = core.db.global.seen
			for id, e in pairs(ns.SeenRestore) do if not seen[id] then seen[id] = e end end
			core.db.global.restored20261120 = true
		end
		if ns.SeenRestore2 and not core.db.global.restored20261120b then
			local seen = core.db.global.seen
			for id, e in pairs(ns.SeenRestore2) do if not seen[id] then seen[id] = e end end
			core.db.global.restored20261120b = true
		end
		core.db.global.classOf = core.db.global.classOf or {}
		-- /skpb dump output only has to survive one save (it is read from the file outside the game)
		core.db.global.spellDump = nil
		for _ in pairs(core.db.global.seen) do core.seenCount = core.seenCount + 1 end
		if core.SetupOptions then core:SetupOptions() end
		if imported then Print("your Warmane settings were imported (all profiles). This character uses \"%s\"; change it in /skpb, Profiles.", core.db:GetCurrentProfile()) end
		if not (C_NamePlate and pcall(CreateFrame, "AuraContainer", nil, nil, "CustomAuraContainerTemplate")) then
			Print("this client has no AuraContainer frames, so the plates cannot be drawn here.")
			return
		end
		BuildIds()
		layouts = { enemy = BuildLayout("enemy"), friend = BuildLayout("friend") }
		builtKey = BuildKey()
		ev:RegisterEvent("NAME_PLATE_UNIT_ADDED")
		ev:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
		ev:RegisterEvent("UNIT_FACTION")
		ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
		ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
		ev:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "pet")
		ev:RegisterEvent("PLAYER_ENTERING_WORLD")
		ev:RegisterEvent("PLAYER_REGEN_ENABLED")
		ev:RegisterEvent("UNIT_AURA")
	elseif event == "UNIT_AURA" then
		-- only new auras can teach the library anything: skip refreshes and removals (most UNIT_AURA events)
		-- the event's fields can be secret (combat, instances): never test them then
		if InCombatLockdown() or not (arg and arg:find("^nameplate")) then return end
		local info = ...
		if type(info) == "table" then
			local full, added = info.isFullUpdate, info.addedAuras
			if not IsSecret(full) and not IsSecret(added) and not full and not added then return end
		end
		QueueScan(arg)
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		core:Attach(arg)
		QueueScan(arg)
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		core:Detach(arg)
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local _, spellId = ...
		if spellId and not IsSecret(spellId) and INTERRUPT_BY_ID[spellId] then
			lastKick = { spellId = spellId, time = GetTime() }
		end
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
		if not (arg and arg:find("^nameplate")) then return end
		local _, spellId, interruptedBy = ...
		-- secret inside instances: only its presence may be tested
		-- a secret value is never nil, so it counts as present without being tested
		if IsSecret(interruptedBy) or interruptedBy then core:OnInterrupted(arg, spellId) end
	elseif event == "UNIT_FACTION" then
		if arg and arg:find("^nameplate") then core:Attach(arg) end
	elseif event == "PLAYER_ENTERING_WORLD" then
		ForEachPlate(function(u) core:Attach(u) end)
	elseif event == "PLAYER_REGEN_ENABLED" then
		if pendingRebuild then core:ResetSideRows() end
		ForEachPlate(QueueScan)
	end
end)
