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
	{ "interrupt", "Interrupt lockouts", "sidePrioInterrupt" },
	{ "immunity", "Immunities", "sidePrioImmunity" },
	{ "immunity_spell", "Spell immunities", "sidePrioImmunity" },
	{ "buff_def", "Defensive buffs", "sidePrioDefensive" },
	{ "buff_off", "Offensive buffs", "sidePrioOffensive" },
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
			return "|cffffd100" .. L["Spell ID"] .. "|r " .. e.id .. (#e.ids > 1 and ("  (" .. #e.ids .. " " .. L["ranks"] .. ")") or "")
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
			reset = {
				type = "execute",
				name = L["Reset this spell"],
				order = 4,
				hidden = function() return not eff() end,
				func = function()
					P.sideSpells[name] = nil
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

local addID, addCat, addDuration = "", "buff_def", ""

core.SideSpellsOptionsTable = {
	type = "group",
	name = L["Side spells"],
	order = 7,
	childGroups = "tree",
	args = {
		desc = {
			type = "description",
			name = L["Every spell the side rows can show. Pick a category on the left to see its spells. Switch a spell off, move it to another category, or give it its own priority."],
			order = 1,
		},
		debug = {
			type = "toggle",
			name = L["Print side row auras in chat"],
			desc = L["Prints the name, ID and category each time an aura is added to a side row. Use it to find a spell you do not recognise."],
			width = "full",
			order = 2,
			get = function() return P.sideDebug end,
			set = function(_, v) P.sideDebug = v end,
		},
		addGroup = {
			type = "group",
			inline = true,
			name = L["Add a spell"],
			order = 3,
			args = {
				id = {
					type = "input",
					name = L["Spell ID"],
					order = 1,
					get = function() return addID end,
					set = function(_, v) addID = v end,
				},
				cat = {
					type = "select",
					name = L["Category"],
					order = 2,
					values = CATEGORY_VALUES,
					get = function() return addCat end,
					set = function(_, v) addCat = v end,
				},
				duration = {
					type = "input",
					name = L["Duration (seconds)"],
					desc = L["Optional. Auras on the left row without a known duration are hidden."],
					order = 3,
					get = function() return addDuration end,
					set = function(_, v) addDuration = v end,
				},
				add = {
					type = "execute",
					name = L["Add"],
					order = 4,
					func = function()
						local id = tonumber(addID)
						local name = id and GetSpellInfo(id)
						if not name then
							print("|cff33ff99" .. core.title .. "|r: " .. L["Unknown spell ID"])
							return
						end
						P.sideCustom[id] = addCat
						local d = tonumber(addDuration)
						P.sideCustomDuration[id] = (d and d > 0) and d or nil
						local o = P.sideSpells[name]
						if o then o.enabled = nil; Tidy(name) end
						addID, addDuration = "", ""
						Changed(true)
					end,
				},
			},
		},
		resetAll = {
			type = "execute",
			name = L["Reset the whole list"],
			desc = L["Removes every change and every spell you added."],
			confirm = true,
			order = 4,
			func = function()
				wipe(P.sideSpells)
				wipe(P.sideCustom)
				wipe(P.sideCustomDuration)
				Changed(true)
			end,
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
		local g = { type = "group", name = L[c[2]], order = 10 + i, args = {} }
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
			g.args.empty = { type = "description", name = L["No spells in this category."], order = 1 }
		end
	end
end

core.CoreOptionsTable.args.sidespells = core.SideSpellsOptionsTable
