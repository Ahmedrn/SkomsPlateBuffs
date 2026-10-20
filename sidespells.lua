local folder, core = ...

if not core.LibNameplates then return end

-- The editable spell list of the side rows: every spell can be switched off, moved to another category
-- (the category decides the row) and given its own priority. Spells can be added by ID.
-- Overrides are stored by spell name, so every rank of a spell follows the same setting.

local pairs, ipairs, tonumber, tostring = pairs, ipairs, tonumber, tostring
local table_sort = table.sort
local GetSpellInfo = GetSpellInfo
local wipe = wipe

local L = core.L or LibStub("AceLocale-3.0"):GetLocale(folder, true)

local P = {}
do
	local prev_OnEnable = core.OnEnable
	function core:OnEnable()
		P = self.db.profile
		prev_OnEnable(self)
		P = self.db.profile
		self:RebuildSpellCategories()
		self:UpdateWantedCategories()
		self:BuildSideSpellUI()
	end
end

local defaultSettings = core.defaultSettings.profile
defaultSettings.sideSpells = {}
defaultSettings.sideCustom = {}
defaultSettings.sideCustomDuration = {}
defaultSettings.sideDebug = false

-- category order in the tree, its label, and the option that holds its default priority
local CATEGORIES = {
	{ "cc", "Crowd control", "sidePrioCC" },
	{ "root", "Roots", "sidePrioRoot" },
	{ "snare", "Snares", "sidePrioSnare" },
	{ "disarm", "Disarms", "sidePrioDisarm" },
	{ "healing_reduction", "Healing reduction", "sidePrioHealing" },
	{ "interrupt", "Interrupt lockouts", "sidePrioInterrupt" },
	{ "immunity", "Immunities", "sidePrioImmunity" },
	{ "immunity_spell", "Spell immunities", "sidePrioImmunitySpell" },
	{ "buff_def", "Defensive buffs", "sidePrioDefensive" },
	{ "shield", "Shields", "sidePrioShield" },
	{ "buff_off", "Offensive buffs", "sidePrioOffensive" },
	{ "speed", "Speed boosts", "sidePrioSpeed" },
	{ "buff_other", "Other buffs", "sidePrioOther" },
}
local CATEGORY_PRIO = {}
local CATEGORY_VALUES = {}
for _, c in ipairs(CATEGORIES) do
	CATEGORY_PRIO[c[1]] = c[3]
	CATEGORY_VALUES[c[1]] = L[c[2]]
end

-- ---------------------------------------------------------------------------------------------------------
-- the live category tables, built from the defaults plus the user's changes (edited in place: other files
-- keep local references to them)
-- ---------------------------------------------------------------------------------------------------------
function core:RebuildSpellCategories()
	local cats, byName, prio = core.SpellCategory, core.SpellCategoryByName, core.SpellPriorityByName
	wipe(cats)
	wipe(byName)
	wipe(prio)
	local ov = P.sideSpells

	-- every spell that has a category, even when switched off: "Other tracked auras" leaves these alone
	local names = core.CategorizedNames
	wipe(names)
	for id in pairs(core.SpellCategoryDefault) do
		local n = GetSpellInfo(id)
		if n then names[n] = true end
	end
	for id in pairs(P.sideCustom) do
		local n = GetSpellInfo(id)
		if n then names[n] = true end
	end

	local function add(id, cat)
		local name = GetSpellInfo(id)
		local o = name and ov[name]
		if o and o.enabled == false then return end
		cats[id] = (o and o.cat) or cat
	end
	for id, cat in pairs(core.SpellCategoryDefault) do add(id, cat) end
	for id, cat in pairs(P.sideCustom) do
		add(id, cat)
		local d = P.sideCustomDuration[id]
		if d and d > 0 then core.spellDuration[id] = d end
	end

	for id, cat in pairs(cats) do
		local name = GetSpellInfo(id)
		if name then
			local known = byName[name]
			if known == nil then byName[name] = cat
			elseif known ~= cat then byName[name] = false end
		end
	end
	for name, o in pairs(ov) do
		if o.prio then prio[name] = o.prio end
	end
end

-- ---------------------------------------------------------------------------------------------------------
-- options
-- ---------------------------------------------------------------------------------------------------------
local function Changed(rebuildTree)
	core:RebuildSpellCategories()
	if core.ResetSideRows then core:ResetSideRows() end
	if rebuildTree then core:BuildSideSpellUI() end
	local registry = LibStub("AceConfigRegistry-3.0", true)
	if registry then registry:NotifyChange(core.title) end
end

local function Override(name)
	local o = P.sideSpells[name]
	if not o then
		o = {}
		P.sideSpells[name] = o
	end
	return o
end

local function Tidy(name)
	local o = P.sideSpells[name]
	if o and o.enabled == nil and o.cat == nil and o.prio == nil then
		P.sideSpells[name] = nil
	end
end

-- ---------------------------------------------------------------------------------------------------------
-- spell descriptions (from the game's own tooltip)
-- ---------------------------------------------------------------------------------------------------------
local descCache = {}
local function SpellDescription(id)
	local d = descCache[id]
	if d then return d end
	local tip = core.tooltip
	if not tip then return "" end
	tip:SetOwner(UIParent, "ANCHOR_NONE")
	tip:ClearLines()
	tip:SetHyperlink("spell:" .. id)
	local text = ""
	local name = tip:GetName()
	for i = tip:NumLines(), 2, -1 do
		local fs = _G[name .. "TextLeft" .. i]
		local t = fs and fs:GetText()
		if t and t ~= "" then
			text = t
			break
		end
	end
	if text ~= "" then descCache[id] = text end
	return text
end

local function SpellTooltip(id, extra)
	local d = SpellDescription(id)
	return (d ~= "" and (d .. "\n\n") or "") .. "|cffffd100" .. L["Spell ID"] .. "|r " .. id .. (extra or "")
end

-- one entry per spell name: { name, id (for the icon), cat (default), ids = {...}, custom = true if only added by the user }
local function CollectEntries()
	local entries = {}
	local function add(id, cat, custom)
		local name = GetSpellInfo(id)
		if not name then return end
		local e = entries[name]
		if not e then
			e = { name = name, id = id, cat = cat, custom = custom, ids = {} }
			entries[name] = e
		elseif id < e.id then
			e.id, e.cat = id, cat
		end
		if not custom then e.custom = false end
		e.ids[#e.ids + 1] = id
	end
	for id, cat in pairs(core.SpellCategoryDefault) do add(id, cat, false) end
	for id, cat in pairs(P.sideCustom) do
		if not core.SpellCategoryDefault[id] then add(id, cat, true) end
	end
	return entries
end

-- ---------------------------------------------------------------------------------------------------------
-- glow controls (per category, per spell)
-- ---------------------------------------------------------------------------------------------------------
local WHITE = { 1, 1, 1 }
local GLOW_VALUES = {
	none = L["No glow"],
	border = L["Border"],
	pixel = L["Pixel glow"],
	shine = L["Autocast shine"],
	button = L["Action button glow"],
	proc = L["Proc glow"],
}
local GLOW_SORTING = { "none", "border", "pixel", "shine", "button", "proc" }
local SPELL_GLOW_VALUES = { default = L["Same as the category"] }
for k, v in pairs(GLOW_VALUES) do SPELL_GLOW_VALUES[k] = v end
local SPELL_GLOW_SORTING = { "default", "none", "border", "pixel", "shine", "button", "proc" }
local GLOW_DESC = L["Pixel glow, autocast shine, action button glow and proc glow need LibCustomGlow-1.0 (it comes with WeakAuras). Without it they are drawn as the border."]

-- glow of a category
local function CategoryGlowArgs(cat, order, prefix)
	prefix = prefix or ""
	local function cg()
		local t = P.catGlow[cat]
		if not t then
			t = { type = "none", color = { 1, 1, 1 } }
			P.catGlow[cat] = t
		end
		return t
	end
	return {
		[prefix .. "glowType"] = {
			type = "select",
			name = L["Glow"],
			desc = GLOW_DESC,
			order = order,
			values = GLOW_VALUES,
			sorting = GLOW_SORTING,
			get = function() return cg().type or "none" end,
			set = function(_, v) cg().type = v; Changed() end,
		},
		[prefix .. "glowColor"] = {
			type = "color",
			name = L["Glow color"],
			desc = L["Used when the glow color is set to By category (Main settings, Appearance)."],
			order = order + 1,
			get = function() local c = cg().color or WHITE; return c[1], c[2], c[3] end,
			set = function(_, r, g, b) cg().color = { r, g, b }; Changed() end,
		},
	}
end

-- glow of one spell (by name): overrides the category
function core.SpellGlowArgs(name, order)
	local function cur() return P.spellGlow[name] end
	local function make()
		local t = P.spellGlow[name]
		if not t then
			t = {}
			P.spellGlow[name] = t
		end
		return t
	end
	local function tidy()
		local t = P.spellGlow[name]
		if t and t.type == nil and t.color == nil then P.spellGlow[name] = nil end
	end
	return {
		glowType = {
			type = "select",
			name = L["Glow"],
			desc = GLOW_DESC,
			order = order,
			values = SPELL_GLOW_VALUES,
			sorting = SPELL_GLOW_SORTING,
			get = function() local t = cur(); return (t and t.type) or "default" end,
			set = function(_, v)
				if v == "default" then
					local t = cur()
					if t then t.type = nil end
					tidy()
				else
					make().type = v
				end
				Changed()
			end,
		},
		glowCustomColor = {
			type = "toggle",
			name = L["Custom glow color"],
			order = order + 1,
			get = function() local t = cur(); return t and t.color ~= nil end,
			set = function(_, v)
				if v then
					make().color = { 1, 1, 1 }
				else
					local t = cur()
					if t then t.color = nil end
					tidy()
				end
				Changed()
			end,
		},
		glowColor = {
			type = "color",
			name = L["Glow color"],
			order = order + 2,
			disabled = function() local t = cur(); return not (t and t.color) end,
			get = function() local t = cur(); local c = (t and t.color) or WHITE; return c[1], c[2], c[3] end,
			set = function(_, r, g, b) make().color = { r, g, b }; Changed() end,
		},
	}
end

-- add a spell to a category by ID
local pendingID = {}
local function AddSpell(cat)
	local id = tonumber(pendingID[cat])
	local name = id and GetSpellInfo(id)
	if not name then
		print("|cff33ff99" .. core.title .. "|r: " .. L["Unknown spell ID"])
		return
	end
	P.sideCustom[id] = cat
	local o = P.sideSpells[name]
	if o then
		o.enabled = nil
		Tidy(name)
	end
	pendingID[cat] = ""
	Changed(true)
end

-- settings of a category group: priority, glow, add a spell
local function CategoryArgs(cat)
	local args = {
		catPriority = {
			type = "range",
			name = L["Priority"],
			desc = L["The higher the priority, the closer to the nameplate. With more auras than icons, the lowest priorities are the ones left out."],
			order = 2,
			min = 1, max = 10, step = 1,
			get = function() return P[CATEGORY_PRIO[cat]] end,
			set = function(_, v) P[CATEGORY_PRIO[cat]] = v; Changed() end,
		},
		addID = {
			type = "input",
			name = L["Add a spell by ID"],
			order = 8,
			get = function() return pendingID[cat] or "" end,
			set = function(_, v) pendingID[cat] = v end,
		},
		addSpell = {
			type = "execute",
			name = L["Add"],
			order = 9,
			width = "half",
			func = function() AddSpell(cat) end,
		},
	}
	for k, v in pairs(CategoryGlowArgs(cat, 3)) do args[k] = v end
	return args
end

local function EntryOptions(e)
	local name = e.name
	local function eff() return P.sideSpells[name] end
	local function effCat()
		local o = eff()
		return (o and o.cat) or e.cat
	end
	local function CategoryPrio()
		return P[CATEGORY_PRIO[effCat()] or "sidePrioOther"] or 1
	end

	return {
		type = "group",
		name = function()
			local o = eff()
			if o and o.enabled == false then return "|cff808080" .. name .. "|r" end
			return name
		end,
		icon = function() return select(3, GetSpellInfo(e.id)) end,
		desc = function()
			return SpellTooltip(e.id, #e.ids > 1 and ("  (" .. #e.ids .. " " .. L["ranks"] .. ")") or "")
		end,
		args = {
			enabled = {
				type = "toggle",
				name = L["Show"],
				desc = L["Show this spell on the side rows"],
				order = 1,
				get = function() local o = eff(); return not (o and o.enabled == false) end,
				set = function(_, v)
					if v then
						local o = eff()
						if o then o.enabled = nil end
						Tidy(name)
					else
						Override(name).enabled = false
					end
					Changed()
				end,
			},
			category = {
				type = "select",
				name = L["Category"],
				desc = L["The category decides the row: crowd control, roots and interrupt lockouts go right, the rest goes left."],
				order = 2,
				values = CATEGORY_VALUES,
				get = effCat,
				set = function(_, v)
					if v == e.cat then
						local o = eff()
						if o then o.cat = nil end
						Tidy(name)
					else
						Override(name).cat = v
					end
					Changed(true)
				end,
			},
			priorityGroup = {
				type = "group",
				inline = true,
				name = L["Priority"],
				order = 3,
				args = {
					customPriority = {
						type = "toggle",
						name = L["Custom priority"],
						order = 1,
						get = function() local o = eff(); return o and o.prio ~= nil end,
						set = function(_, v)
							if v then
								Override(name).prio = CategoryPrio()
							else
								local o = eff()
								if o then o.prio = nil end
								Tidy(name)
							end
							Changed()
						end,
					},
					priority = {
						type = "range",
						name = L["Priority"],
						desc = L["The higher the priority, the closer to the nameplate."],
						order = 2,
						min = 1, max = 10, step = 1,
						disabled = function() local o = eff(); return not (o and o.prio) end,
						get = function() local o = eff(); return (o and o.prio) or CategoryPrio() end,
						set = function(_, v)
							Override(name).prio = v
							Changed()
						end,
					},
				},
			},
			glowGroup = {
				type = "group",
				inline = true,
				name = L["Glow"],
				order = 3.5,
				args = core.SpellGlowArgs(name, 1),
			},
			scale = {
				type = "range",
				name = L["Icon size multiplier"],
				desc = L["Multiplies the row's icon size for this spell (1 = the row's size). Used in the top rows only."],
				order = 3.6,
				min = 0.5, max = 3, step = 0.25,
				get = function() return P.spellScale[name] or 1 end,
				set = function(_, v)
					if math.abs(v - 1) < 0.001 then P.spellScale[name] = nil else P.spellScale[name] = v end
					Changed()
				end,
			},
			duration = {
				type = "input",
				name = L["Duration (seconds)"],
				desc = L["Optional. Auras without a known duration are hidden in category rows."],
				order = 3.8,
				hidden = function() return not e.custom end,
				get = function() return tostring(P.sideCustomDuration[e.id] or "") end,
				set = function(_, v)
					local d = tonumber(v)
					for _, id in ipairs(e.ids) do
						P.sideCustomDuration[id] = (d and d > 0) and d or nil
					end
					Changed()
				end,
			},
			reset = {
				type = "execute",
				name = L["Reset this spell"],
				order = 4,
				hidden = function() return not (eff() or P.spellScale[name] or P.spellGlow[name]) end,
				func = function()
					P.sideSpells[name] = nil
					P.spellScale[name] = nil
					P.spellGlow[name] = nil
					Changed(true)
				end,
			},
			remove = {
				type = "execute",
				name = L["Remove spell from list"],
				order = 5,
				hidden = function() return not e.custom end,
				func = function()
					for _, id in ipairs(e.ids) do
						P.sideCustom[id] = nil
						P.sideCustomDuration[id] = nil
					end
					P.sideSpells[name] = nil
					Changed(true)
				end,
			},
		},
	}
end

-- ---------------------------------------------------------------------------------------------------------
-- My debuffs: the debuffs the player applies (hard crowd control stays on the right row). The list starts with the
-- class's own debuffs and grows with every debuff the player applies.
-- ---------------------------------------------------------------------------------------------------------
local function IsHardCCSpell(id, name)
	local c = core.SpellCategory[id] or core.SpellCategoryByName[name or ""]
	return c == "cc" or c == "interrupt" or c == "disarm"
end

function core:LearnMyDebuff(id, name)
	if not name or P.myDebuffs == nil or P.myDebuffs[name] then return end
	if IsHardCCSpell(id, name) then return end
	P.myDebuffs[name] = id
	if core.BuildMyDebuffsUI then
		core:BuildMyDebuffsUI()
		local registry = LibStub("AceConfigRegistry-3.0", true)
		if registry then registry:NotifyChange(core.title) end
	end
end

local function MyDebuffEntry(name, id)
	local function o() return P.sideSpells[name] end
	return {
		type = "group",
		name = function()
			if P.myDebuffHidden[name] then return "|cff808080" .. name .. "|r" end
			return name
		end,
		icon = function() return select(3, GetSpellInfo(id)) end,
		desc = function() return SpellTooltip(id) end,
		args = {
			show = {
				type = "toggle",
				name = L["Show"],
				desc = L["Show this spell on the side rows"],
				order = 1,
				get = function() return not P.myDebuffHidden[name] end,
				set = function(_, v)
					P.myDebuffHidden[name] = (not v) or nil
					Changed()
				end,
			},
			scale = {
				type = "range",
				name = L["Icon size multiplier"],
				desc = L["Multiplies the row's icon size for this spell (1 = the row's size). Used in the top rows only."],
				order = 2,
				min = 0.5, max = 3, step = 0.25,
				get = function() return P.spellScale[name] or 1 end,
				set = function(_, v)
					if math.abs(v - 1) < 0.001 then P.spellScale[name] = nil else P.spellScale[name] = v end
					Changed()
				end,
			},
			priorityGroup = {
				type = "group",
				inline = true,
				name = L["Priority"],
				order = 3,
				args = {
					customPriority = {
						type = "toggle",
						name = L["Custom priority"],
						order = 1,
						get = function() local t = o(); return t and t.prio ~= nil end,
						set = function(_, v)
							if v then
								Override(name).prio = 5
							else
								local t = o()
								if t then t.prio = nil end
								Tidy(name)
							end
							Changed()
						end,
					},
					priority = {
						type = "range",
						name = L["Priority"],
						desc = L["The higher the priority, the closer to the nameplate."],
						order = 2,
						min = 1, max = 10, step = 1,
						disabled = function() local t = o(); return not (t and t.prio) end,
						get = function() local t = o(); return (t and t.prio) or 5 end,
						set = function(_, v) Override(name).prio = v; Changed() end,
					},
				},
			},
			glowGroup = {
				type = "group",
				inline = true,
				name = L["Glow"],
				order = 4,
				args = core.SpellGlowArgs(name, 1),
			},
		},
	}
end

function core:BuildMyDebuffsUI()
	local args = core.SideSpellsOptionsTable.args
	local group = args.cat_mydebuffs
	if not group then
		group = {
			type = "group",
			name = L["My debuffs"],
			order = 5,
			args = {
				desc = {
					type = "description",
					name = L["Your own debuffs on enemies, except hard crowd control (stuns, fears, disarms, silences), which stays on the right row. Switch off the ones you do not want to see, set a size multiplier and a glow. The list starts with your class's debuffs and grows with every debuff you apply."],
					order = 1,
				},
			},
		}
		for k, v in pairs(CategoryGlowArgs("mydebuffs", 3)) do group.args[k] = v end
		args.cat_mydebuffs = group
	end
	for k in pairs(group.args) do
		if k:find("^spell") then group.args[k] = nil end
	end
	local entries = {}
	for _, id in ipairs(core.MyDebuffSeeds or {}) do
		local name = GetSpellInfo(id)
		if name and not IsHardCCSpell(id, name) then entries[name] = id end
	end
	for name, id in pairs(P.myDebuffs or {}) do
		if not entries[name] then entries[name] = id end
	end
	local list = {}
	for name, id in pairs(entries) do list[#list + 1] = { name, id } end
	table_sort(list, function(a, b) return a[1] < b[1] end)
	for i, e in ipairs(list) do
		local entry = MyDebuffEntry(e[1], e[2])
		entry.order = 10 + i
		group.args["spell" .. e[2]] = entry
	end
	group.name = L["My debuffs"] .. " (" .. #list .. ")"
end

core.SideSpellsOptionsTable = {
	type = "group",
	name = L["Spells"],
	order = 3,
	childGroups = "tree",
	args = {
		desc = {
			type = "description",
			name = L["Every spell the rows can show, by category. Pick a category on the left for its priority and glow, and its spells. Switch a spell off, move it to another category, give it its own priority or glow, or add spells by ID."],
			order = 1,
		},
		tools = {
			type = "group",
			name = L["Tools"],
			order = 200,
			args = {
				debug = {
					type = "toggle",
					name = L["Print row auras in chat"],
					desc = L["Prints the name, ID and category each time an aura is added to a category row. Use it to find a spell you do not recognise."],
					width = "full",
					order = 1,
					get = function() return P.sideDebug end,
					set = function(_, v) P.sideDebug = v end,
				},
				resetAll = {
					type = "execute",
					name = L["Reset the whole list"],
					desc = L["Removes every change and every spell you added."],
					confirm = true,
					order = 2,
					func = function()
						wipe(P.sideSpells)
						wipe(P.sideCustom)
						wipe(P.sideCustomDuration)
						Changed(true)
					end,
				},
			},
		},
	},
}

function core:BuildSideSpellUI()
	local args = core.SideSpellsOptionsTable.args
	for key in pairs(args) do
		if key:find("^cat_") then args[key] = nil end
	end

	local groups = {}
	for i, c in ipairs(CATEGORIES) do
		local g = { type = "group", name = L[c[2]], order = 10 + i, args = CategoryArgs(c[1]) }
		groups[c[1]] = g
		args["cat_" .. c[1]] = g
	end

	local list = {}
	for _, e in pairs(CollectEntries()) do list[#list + 1] = e end
	table_sort(list, function(a, b) return a.name < b.name end)

	local count = {}
	for i, e in ipairs(list) do
		local o = P.sideSpells[e.name]
		local cat = (o and o.cat) or e.cat
		local g = groups[cat] or groups.buff_other
		g.args["spell" .. e.id] = EntryOptions(e)
		g.args["spell" .. e.id].order = i
		count[cat] = (count[cat] or 0) + 1
	end
	for _, c in ipairs(CATEGORIES) do
		local g = groups[c[1]]
		g.name = L[c[2]] .. " (" .. (count[c[1]] or 0) .. ")"
		if not count[c[1]] then
			g.args.empty = { type = "description", name = L["No spells in this category."], order = 10 }
		end
	end
	core:BuildMyDebuffsUI()
end

core.CoreOptionsTable.args.spells = core.SideSpellsOptionsTable
