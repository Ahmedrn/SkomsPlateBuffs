-- Settings window (/skpb): a modern, flat window with a sidebar, cards, switches and sliders,
-- in the spirit of MiniAuras. Every control reads and writes the same profile keys as the Warmane
-- version, so profiles stay compatible. Changes apply live (sliders when released).
local DUMP_EXTRA

local ADDON, core = ...
local function P() return core.db.profile end
local function Changed() core:ResetSideRows() end

------------------------------------------------------------------------------------------------
-- Look
------------------------------------------------------------------------------------------------
local FONT = STANDARD_TEXT_FONT
local COL = {
	bg = { 0.055, 0.058, 0.066, 0.97 },
	side = { 0.075, 0.078, 0.088, 1 },
	card = { 0.105, 0.108, 0.122, 1 },
	line = { 0.19, 0.2, 0.23, 1 },
	text = { 0.93, 0.93, 0.95 },
	dim = { 0.58, 0.6, 0.66 },
	accent = { 0.2, 1, 0.6 },
	off = { 0.26, 0.27, 0.31, 1 },
	warn = { 1, 0.45, 0.35 },
}
local PAD, GAP = 18, 12

local function Fill(f, c, layer)
	local t = f:CreateTexture(nil, layer or "BACKGROUND")
	t:SetAllPoints()
	t:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
	return t
end

local function Outline(f, c)
	c = c or COL.line
	for _, e in ipairs({ { "TOPLEFT", "TOPRIGHT", 0, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", 0, 1 }, { "TOPLEFT", "BOTTOMLEFT", 1, 0 }, { "TOPRIGHT", "BOTTOMRIGHT", 1, 0 } }) do
		local t = f:CreateTexture(nil, "BORDER")
		t:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
		t:SetPoint(e[1]); t:SetPoint(e[2])
		if e[3] == 1 then t:SetWidth(1) else t:SetHeight(1) end
	end
end

local function Text(parent, size, col, flags)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont(FONT, size or 12, flags or "")
	col = col or COL.text
	fs:SetTextColor(col[1], col[2], col[3])
	fs:SetJustifyH("LEFT")
	fs:SetWordWrap(true)
	return fs
end

local function Tooltip(f, title, body)
	if not (title or body) then return end
	f:HookScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if title then GameTooltip:AddLine(title, 1, 1, 1) end
		if body then GameTooltip:AddLine(body, COL.dim[1], COL.dim[2], COL.dim[3], true) end
		GameTooltip:Show()
	end)
	f:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

------------------------------------------------------------------------------------------------
-- Controls. Each has :Refresh() (value and disabled state).
------------------------------------------------------------------------------------------------
local allControls = {}
local function Register(c, disabled)
	c.disabledFn = disabled
	allControls[#allControls + 1] = c
	return c
end

local function ApplyDisabled(c)
	local off = c.disabledFn and c.disabledFn() or false
	c:SetAlpha(off and 0.4 or 1)
	c.isOff = off
	if c.EnableMouse and c.mouseTarget then c.mouseTarget:EnableMouse(not off) end
	if c.inner and c.inner.SetEnabled then c.inner:SetEnabled(not off) end
end

local function RefreshAll()
	for _, c in ipairs(allControls) do
		if c:IsVisible() then
			if c.Update then c:Update() end
			ApplyDisabled(c)
		end
	end
end
core.RefreshUI = RefreshAll

local function Switch(parent, label, get, set, tip, disabled)
	local f = CreateFrame("Button", nil, parent)
	f:SetHeight(26)
	local track = CreateFrame("Frame", nil, f)
	track:SetSize(34, 18)
	track:SetPoint("LEFT")
	f.trackBg = Fill(track, COL.off)
	local knob = track:CreateTexture(nil, "ARTWORK")
	knob:SetSize(14, 14)
	knob:SetColorTexture(0.95, 0.95, 0.97, 1)
	local fs = Text(f, 12)
	fs:SetPoint("LEFT", track, "RIGHT", 10, 0)
	fs:SetPoint("RIGHT")
	fs:SetText(label)
	f.mouseTarget = f
	function f:Update()
		local on = get() and true or false
		knob:ClearAllPoints()
		if on then
			knob:SetPoint("RIGHT", track, "RIGHT", -2, 0)
			f.trackBg:SetColorTexture(COL.accent[1] * 0.75, COL.accent[2] * 0.75, COL.accent[3] * 0.75, 1)
		else
			knob:SetPoint("LEFT", track, "LEFT", 2, 0)
			f.trackBg:SetColorTexture(unpack(COL.off))
		end
	end
	f:SetScript("OnClick", function()
		if f.isOff then return end
		set(not get())
		Changed(); RefreshAll()
	end)
	Tooltip(f, tip and label, tip)
	return Register(f, disabled)
end

local function Slider(parent, label, min, max, step, get, set, tip, disabled, fmt)
	local f = CreateFrame("Frame", nil, parent)
	f:SetHeight(44)
	local fs = Text(f, 12)
	fs:SetPoint("TOPLEFT")
	fs:SetText(label)
	local box = CreateFrame("EditBox", nil, f)
	box:SetSize(48, 18)
	box:SetPoint("TOPRIGHT")
	box:SetAutoFocus(false)
	box:SetFont(FONT, 12, "")
	box:SetJustifyH("RIGHT")
	box:SetTextColor(COL.accent[1], COL.accent[2], COL.accent[3])
	local s = CreateFrame("Slider", nil, f)
	s:SetOrientation("HORIZONTAL")
	s:SetHeight(14)
	s:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -8)
	s:SetPoint("RIGHT", f, "RIGHT", 0, 0)
	s:SetMinMaxValues(min, max)
	s:SetValueStep(step)
	s:SetObeyStepOnDrag(true)
	local track = s:CreateTexture(nil, "BACKGROUND")
	track:SetColorTexture(unpack(COL.off))
	track:SetHeight(4)
	track:SetPoint("LEFT"); track:SetPoint("RIGHT")
	local fill = s:CreateTexture(nil, "ARTWORK")
	fill:SetColorTexture(COL.accent[1] * 0.75, COL.accent[2] * 0.75, COL.accent[3] * 0.75, 1)
	fill:SetHeight(4)
	fill:SetPoint("LEFT")
	local thumb = s:CreateTexture(nil, "OVERLAY")
	thumb:SetColorTexture(0.95, 0.95, 0.97, 1)
	thumb:SetSize(10, 14)
	s:SetThumbTexture(thumb)
	local function Show(v)
		box:SetText(fmt and fmt(v) or (step < 1 and string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", "") or tostring(math.floor(v + 0.5))))
		local w = s:GetWidth()
		if w and w > 0 then fill:SetWidth(math.max(1, (v - min) / (max - min) * w)) end
	end
	local updating = false
	function f:Update()
		updating = true
		local v = get() or min
		s:SetValue(v)
		Show(v)
		updating = false
	end
	s:SetScript("OnValueChanged", function(_, v)
		Show(v)
		if not updating then f.pending = v end
	end)
	local function Commit()
		if f.pending ~= nil then
			set(f.pending); f.pending = nil
			Changed(); RefreshAll()
		end
	end
	s:SetScript("OnMouseUp", Commit)
	-- no mouse wheel: the pages scroll with it, and a slider under the cursor would change instead
	s:EnableMouseWheel(false)
	box:SetScript("OnEnterPressed", function(self)
		local v = tonumber(self:GetText())
		if v then set(math.min(max, math.max(min, v))); Changed() end
		self:ClearFocus(); RefreshAll()
	end)
	box:SetScript("OnEscapePressed", function(self) self:ClearFocus(); f:Update() end)
	f:SetScript("OnSizeChanged", function() f:Update() end)
	f.inner = s
	Tooltip(s, tip and label, tip)
	return Register(f, disabled)
end

-- items: list of { value, text } or a function returning one
local function Dropdown(parent, label, items, get, set, tip, disabled, uiOnly)
	local f = CreateFrame("Frame", nil, parent)
	f:SetHeight(46)
	local fs = Text(f, 12)
	fs:SetPoint("TOPLEFT")
	fs:SetText(label)
	local function Items() return type(items) == "function" and items() or items end
	local function TextOf(v) for _, it in ipairs(Items()) do if it[1] == v then return it[2] end end return tostring(v or "") end
	local dd
	if MenuUtil and MenuUtil.CreateRadioMenu then
		dd = CreateFrame("DropdownButton", nil, f, "WowStyle1DropdownTemplate")
		dd:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -4)
		dd:SetPoint("RIGHT", f, "RIGHT")
		dd:SetupMenu(function(_, root)
			for _, it in ipairs(Items()) do
				root:CreateRadio(it[2], function(v) return v == get() end, function(v) set(v); if not uiOnly then Changed() end; RefreshAll() end, it[1])
			end
		end)
		function f:Update() dd:SetText(TextOf(get())) end
	else
		dd = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
		dd:SetHeight(22)
		dd:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -4)
		dd:SetPoint("RIGHT", f, "RIGHT")
		dd:SetScript("OnClick", function()
			local list, cur = Items(), get()
			local i = 1
			for n, it in ipairs(list) do if it[1] == cur then i = n % #list + 1 end end
			set(list[i][1]); if not uiOnly then Changed() end; RefreshAll()
		end)
		function f:Update() dd:SetText(TextOf(get())) end
	end
	f.inner = dd
	Tooltip(dd, tip and label, tip)
	return Register(f, disabled)
end

local function OpenColor(r, g, b, onChange)
	local function apply() local nr, ng, nb = ColorPickerFrame:GetColorRGB(); onChange(nr, ng, nb) end
	if ColorPickerFrame.SetupColorPickerAndShow then
		ColorPickerFrame:SetupColorPickerAndShow({ r = r, g = g, b = b, hasOpacity = false, swatchFunc = apply,
			cancelFunc = function() onChange(r, g, b) end })
	else
		ColorPickerFrame.func, ColorPickerFrame.cancelFunc = apply, function() onChange(r, g, b) end
		ColorPickerFrame:SetColorRGB(r, g, b)
		ColorPickerFrame:Show()
	end
end

local function Color(parent, label, get, set, tip, disabled)
	local f = CreateFrame("Button", nil, parent)
	f:SetHeight(24)
	local sw = CreateFrame("Frame", nil, f)
	sw:SetSize(22, 16)
	sw:SetPoint("LEFT")
	Outline(sw, { 0.4, 0.4, 0.45, 1 })
	local tex = sw:CreateTexture(nil, "ARTWORK")
	tex:SetPoint("TOPLEFT", 1, -1); tex:SetPoint("BOTTOMRIGHT", -1, 1)
	local fs = Text(f, 12)
	fs:SetPoint("LEFT", sw, "RIGHT", 10, 0)
	fs:SetPoint("RIGHT")
	fs:SetText(label)
	f.mouseTarget = f
	function f:Update() local r, g, b = get(); tex:SetColorTexture(r or 1, g or 1, b or 1, 1) end
	local pending
	f:SetScript("OnClick", function()
		if f.isOff then return end
		local r, g, b = get()
		OpenColor(r, g, b, function(nr, ng, nb)
			set(nr, ng, nb); f:Update()
			-- containers rebuild once the picker settles
			if pending then pending:Cancel() end
			pending = C_Timer.NewTimer(0.3, Changed)
		end)
	end)
	Tooltip(f, tip and label, tip)
	return Register(f, disabled)
end

local function Button(parent, label, onClick, tip, disabled, accent)
	local b = CreateFrame("Button", nil, parent)
	b:SetHeight(26)
	local bg = Fill(b, accent and { COL.accent[1] * 0.35, COL.accent[2] * 0.35, COL.accent[3] * 0.35, 1 } or { 0.17, 0.175, 0.2, 1 })
	Outline(b, accent and { COL.accent[1] * 0.6, COL.accent[2] * 0.6, COL.accent[3] * 0.6, 1 } or COL.line)
	local fs = Text(b, 12)
	fs:SetPoint("CENTER")
	fs:SetJustifyH("CENTER")
	b.label = fs
	b:SetScript("OnEnter", function() bg:SetAlpha(0.75) end)
	b:SetScript("OnLeave", function() bg:SetAlpha(1) end)
	b:SetScript("OnClick", function(self) if not self.isOff then onClick(self) end end)
	b.mouseTarget = b
	function b:Update() fs:SetText(type(label) == "function" and label() or label) end
	b:Update()
	b:SetWidth(math.max(90, fs:GetStringWidth() + 28))
	Tooltip(b, nil, tip)
	return Register(b, disabled)
end

local function Input(parent, label, get, set, tip, width)
	local f = CreateFrame("Frame", nil, parent)
	f:SetHeight(46)
	local fs = Text(f, 12)
	fs:SetPoint("TOPLEFT")
	fs:SetText(label)
	local bg = CreateFrame("Frame", nil, f)
	bg:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -4)
	bg:SetPoint("RIGHT")
	bg:SetHeight(22)
	Fill(bg, { 0.08, 0.08, 0.09, 1 })
	Outline(bg)
	local box = CreateFrame("EditBox", nil, bg)
	box:SetPoint("TOPLEFT", 6, 0); box:SetPoint("BOTTOMRIGHT", -6, 0)
	box:SetAutoFocus(false)
	box:SetFont(FONT, 12, "")
	box:SetTextColor(1, 1, 1)
	box:SetScript("OnEscapePressed", box.ClearFocus)
	box:SetScript("OnEnterPressed", function(self) set(self:GetText(), true); self:ClearFocus() end)
	box:SetScript("OnTextChanged", function(self, user) if user then set(self:GetText(), false) end end)
	function f:Update() if not box:HasFocus() then box:SetText(get() or "") end end
	f.box = box
	Tooltip(box, tip and label, tip)
	return Register(f)
end

local function Note(parent, text, col, size)
	local fs = Text(parent, size or 11, col or COL.dim)
	fs:SetText(text)
	return fs
end

------------------------------------------------------------------------------------------------
-- Page layout: cards stacked down a scroll child, controls in two columns inside a card.
------------------------------------------------------------------------------------------------
local Layout = {}
Layout.__index = Layout

local function NewLayout(parent, width)
	return setmetatable({ parent = parent, width = width, y = -PAD }, Layout)
end

function Layout:Title(text, sub)
	local t = Text(self.parent, 18, COL.text)
	t:SetPoint("TOPLEFT", PAD, self.y)
	t:SetText(text)
	self.y = self.y - 26
	if sub then
		local s = Note(self.parent, sub, COL.dim, 12)
		s:SetPoint("TOPLEFT", PAD, self.y)
		s:SetWidth(self.width - PAD * 2)
		self.y = self.y - s:GetStringHeight() - 8
	end
	self.y = self.y - 6
end

-- A card: returns an object with :Add(control, full), :Line(text), :Space(px), :End()
function Layout:Card(title, desc)
	local card = CreateFrame("Frame", nil, self.parent)
	card:SetPoint("TOPLEFT", PAD, self.y)
	card:SetWidth(self.width - PAD * 2)
	Fill(card, COL.card)
	Outline(card)
	local inner = { card = card, y = -14, col = 0, lineH = 0, w = self.width - PAD * 2 - 32, layout = self }
	if title then
		local t = Text(card, 13, COL.accent)
		t:SetPoint("TOPLEFT", 16, inner.y)
		t:SetText(title)
		inner.y = inner.y - 20
	end
	if desc then
		local d = Note(card, desc)
		d:SetPoint("TOPLEFT", 16, inner.y)
		d:SetWidth(inner.w)
		inner.y = inner.y - d:GetStringHeight() - 10
	end
	function inner:NewLine()
		if self.col > 0 then self.y = self.y - self.lineH - GAP; self.col = 0; self.lineH = 0 end
	end
	function inner:Add(c, full, width)
		local colW = (self.w - 24) / 2
		if full then self:NewLine() end
		c:ClearAllPoints()
		c:SetPoint("TOPLEFT", self.card, "TOPLEFT", 16 + (full and 0 or self.col * (colW + 24)), self.y)
		c:SetWidth(width or (full and self.w or colW))
		self.lineH = math.max(self.lineH, c:GetHeight())
		if full or self.col == 1 then
			self.y = self.y - self.lineH - GAP; self.col = 0; self.lineH = 0
		else
			self.col = 1
		end
		return c
	end
	function inner:Inline(list)
		-- several fixed-width controls on one line (buttons)
		self:NewLine()
		local x, h = 16, 0
		for _, c in ipairs(list) do
			c:ClearAllPoints()
			c:SetPoint("TOPLEFT", self.card, "TOPLEFT", x, self.y)
			x = x + c:GetWidth() + 8
			h = math.max(h, c:GetHeight())
		end
		self.y = self.y - h - GAP
	end
	function inner:Line(text, col)
		self:NewLine()
		local fs = Note(self.card, text, col)
		fs:SetPoint("TOPLEFT", 16, self.y)
		fs:SetWidth(self.w)
		self.y = self.y - fs:GetStringHeight() - 8
		return fs
	end
	function inner:Space(px) self:NewLine(); self.y = self.y - (px or 6) end
	function inner:End()
		self:NewLine()
		self.card:SetHeight(-self.y + 4)
		self.layout.y = self.layout.y - (-self.y + 4) - 14
		return self.card
	end
	return inner
end

function Layout:Height() return -self.y + PAD end

------------------------------------------------------------------------------------------------
-- Shared data
------------------------------------------------------------------------------------------------
local CATS = {
	-- key, name, tooltip, where it works ("enemy", "friend", "both"), kind
	{ "cc", "Crowd control", "Enemy plates: the game's crowd control tag plus the Forever spell list. Friendly plates: the game's tag.", "both", "debuff" },
	{ "root", "Roots", nil, "enemy", "debuff" },
	{ "snare", "Snares", nil, "enemy", "debuff" },
	{ "disarm", "Disarms", nil, "enemy", "debuff" },
	{ "healing_reduction", "Healing reduction", nil, "enemy", "debuff" },
	{ "interrupt", "Interrupt lockouts", "Shown when an enemy's cast is interrupted. Lengths are on the Interrupts page.", "enemy", "debuff" },
	{ "tag_bigdef", "Big defensives", "Buffs the game itself tags as a big defensive.", "both", "tag" },
	{ "tag_extdef", "External defensives", "Buffs the game itself tags as an external defensive.", "both", "tag" },
	{ "tag_important", "Important buffs", "Buffs the game itself tags as important.", "both", "tag" },
	{ "short", "Short buffs", "Any other buff that lasts at most the length set on the Enemy buffs page. Catches cooldowns the game does not tag (Recklessness, Death Wish...).", "both", "tag" },
	{ "immunity", "Immunities", nil, "friend", "list" },
	{ "buff_def", "Defensive buffs", nil, "friend", "list" },
	{ "buff_off", "Offensive buffs", nil, "friend", "list" },
	{ "shield", "Shields", nil, "friend", "list" },
	{ "speed", "Speed boosts", nil, "friend", "list" },
	{ "buff_other", "Other buffs", nil, "friend", "list" },
	{ "any", "Any other aura", "Everything no other category took. With Only my auras and Debuffs only, it is \"my debuffs\".", "both", "any" },
}
local CAT_NAME = {}
for _, c in ipairs(CATS) do CAT_NAME[c[1]] = c[2] end
-- a typical spell for each category, for its icon
local CAT_ICON = {
	cc = 853, root = 339, snare = 1715, disarm = 676, healing_reduction = 12294, interrupt = 6552,
	immunity = 642, buff_def = 871, buff_off = 1719, shield = 17, speed = 2983, buff_other = 774, any = 172,
	tag_bigdef = 871, tag_extdef = 1022, tag_important = 1719, short = 12328,
}
-- inline spell icon for labels, trimmed like an action button
local function SpellIcon(id, size)
	local t = id and C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
	if not t then return "" end
	size = size or 16
	return "|T" .. t .. ":" .. size .. ":" .. size .. ":0:0:64:64:5:59:5:59|t "
end
local function NameIcon(name)
	local ids = core.RanksByName and name and core.RanksByName[name:lower()]
	return SpellIcon(ids and ids[1])
end

local SHOW = { { "all", "Buffs and debuffs" }, { "debuffs", "Debuffs only" }, { "buffs", "Buffs only" } }
local GLOW_TYPES = { { "none", "None" }, { "pixel", "Thin frame" }, { "proc", "Soft halo" } }
local KIND_CARD = {
	{ "debuff", "Debuffs", "Crowd control works on every plate. The others only work on enemy plates: Forever applies debuff spell lists only to units you cannot help." },
	{ "tag", "Buffs the game tags", "Work on every plate. The game decides which spells carry each tag; addons cannot change it." },
	{ "list", "Buffs by spell list", "Friendly plates only. In combat Forever hides which buff an enemy has." },
	{ "any", "Everything else" },
}
local WHERE_NOTE = { enemy = " |cff888888(enemy plates)|r", friend = "" }
-- one card per kind of category, with only the ones that can work where they are shown
local function CategoryCards(L, get, set, disabled, friendlyOnly)
	for _, kind in ipairs(KIND_CARD) do
		local c
		for _, cat in ipairs(CATS) do
			if cat[5] == kind[1] and not (friendlyOnly and cat[4] == "enemy") then
				c = c or L:Card(kind[2], not (friendlyOnly and kind[1] ~= "list") and kind[3] or nil)
				local label = SpellIcon(CAT_ICON[cat[1]]) .. cat[2] .. (friendlyOnly and "" or WHERE_NOTE[cat[4]] or "")
				c:Add(Switch(c.card, label, function() return get(cat[1]) end, function(v) set(cat[1], v) end, cat[3], disabled))
			end
		end
		if c then c:End() end
	end
end

------------------------------------------------------------------------------------------------
-- Pages
------------------------------------------------------------------------------------------------
local pages = {}

local function PageGeneral(L)
	L:Title("General", "Skom's Plate Buffs shows the auras that matter around enemy nameplates: cooldowns on the left, crowd control on the right, your debuffs on top.")
	local c = L:Card("Preview")
	c:Line("Shows sample auras in every row on your target's nameplate, so you can place the rows without a fight. Out of combat.")
	c:Inline({ Button(c.card, function() return core:IsTesting() and "Stop preview" or "Start preview" end, function() core:ToggleTest(); RefreshAll() end, nil, nil, true) })
	c:End()
	c = L:Card("Show on", "Which nameplates get the rows.")
	c:Add(Switch(c.card, "Players", function() return P().abovePlayers end, function(v) P().abovePlayers = v end))
	c:Add(Switch(c.card, "NPCs", function() return P().aboveNPC end, function(v) P().aboveNPC = v end))
	c:Add(Switch(c.card, "Hostile", function() return P().aboveHostile end, function(v) P().aboveHostile = v end))
	c:Add(Switch(c.card, "Neutral", function() return P().aboveNeutral end, function(v) P().aboveNeutral = v end))
	c:Add(Switch(c.card, "Friendly", function() return P().aboveFriendly end, function(v) P().aboveFriendly = v end))
	c:End()
	c = L:Card("Buffs without a duration", "Druid forms, stances, paladin auras and other permanent buffs.")
	c:Add(Switch(c.card, "Hide buffs without a duration", function() return P().sideHideNoDuration end, function(v) P().sideHideNoDuration = v end,
		"Every row, enemy and friendly plates. The game's filter is a maximum length, so buffs over an hour are hidden too."), true)
	c:End()
	c = L:Card("Anchor")
	c:Add(Switch(c.card, "Anchor rows to the health bar", function() return P().sideAnchorHealthBar end, function(v) P().sideAnchorHealthBar = v end, "Off: anchor to the whole nameplate frame."), true)
	c:End()
end

-- one sub page per row
local ROW_TABS = {
	{ "rowLeft", "Left" }, { "rowRight", "Right" }, { "rowTop1", "Top" },
	{ "rowTop2", "Extra 1" }, { "rowTop3", "Extra 2" }, { "rowTop4", "Extra 3" }, { "rowTop5", "Extra 4" }, { "rowTop6", "Extra 5" },
	{ "friendly", "Friendly" },
}

local function RowEditor(L, key)
	local isTop = key:match("^rowTop")
	local topIndex = tonumber(key:match("%d"))
	local function R() return P()[key] end
	local function myDebuffs() return key == "rowTop1" and R().myDebuffs end

	local c = L:Card("Row")
	c:Add(Switch(c.card, "Enabled", function() return R().enabled end, function(v) R().enabled = v end))
	if key == "rowTop1" then
		c:Add(Switch(c.card, "My debuffs", function() return R().myDebuffs end, function(v) R().myDebuffs = v end,
			"Your own debuffs on enemies. Crowd control and disarms stay on their row. Hide some on the Spells page."))
	else
		c:Add(Switch(c.card, "Only my auras", function() return R().onlyMine end, function(v) R().onlyMine = v end, "Only auras you cast. These rows take their auras first."))
	end
	c:Add(Slider(c.card, "Icons (per kind of aura)", 1, isTop and 12 or 6, 1, function() return R().max end, function(v) R().max = v end))
	c:Add(Slider(c.card, "Icon size", 12, 64, 1, function() return R().size end, function(v) R().size = v end))
	c:Add(Dropdown(c.card, "Show", SHOW, function() return R().show end, function(v) R().show = v end, nil, myDebuffs))
	c:Add(Switch(c.card, "Glow", function() return R().glow end, function(v) R().glow = v end, "Glow around the icons, in the category colour and style (Appearance)."))
	if topIndex and topIndex > 1 then
		c:Inline({ Button(c.card, "Remove this row", function()
			P().topRowCount = math.max(1, (P().topRowCount or 1) - 1)
			Changed(); pages.rows.SelectRow("rowTop" .. (topIndex - 1))
		end, "Removes the last extra row.", function() return topIndex ~= (P().topRowCount or 1) end) })
	end
	c:End()

	c = L:Card("Position")
	if key == "rowLeft" or key == "rowRight" then
		local side = key == "rowLeft" and "Left" or "Right"
		for _, axis in ipairs({ "X", "Y" }) do
			c:Add(Slider(c.card, "Offset " .. axis, -60, 60, 1,
				function() return P()["side" .. side .. "Offset" .. axis] or P()["sideOffset" .. axis] end,
				function(v) P()["side" .. side .. "Offset" .. axis] = v end,
				axis == "X" and "Positive: further from the plate." or nil))
		end
		c:Add(Slider(c.card, "Spacing", -10, 30, 1, function() return P().sideSpacing end, function(v) P().sideSpacing = v end, "Shared by left and right."))
	else
		c:Line("Top rows stack upwards from the plate and share these settings.")
		c:Add(Slider(c.card, "Offset X", -100, 100, 1, function() return P().topOffsetX end, function(v) P().topOffsetX = v end))
		c:Add(Slider(c.card, "Offset Y", -60, 100, 1, function() return P().topOffsetY end, function(v) P().topOffsetY = v end))
		c:Add(Slider(c.card, "Spacing", -10, 30, 1, function() return P().topSpacing end, function(v) P().topSpacing = v end))
		c:Add(Slider(c.card, "Space between rows", -10, 30, 1, function() return P().topRowSpacing end, function(v) P().topRowSpacing = v end))
	end
	c:End()

	CategoryCards(L, function(k) return R().cats and R().cats[k] end,
		function(k, v) R().cats = R().cats or {}; R().cats[k] = v and true or false end, myDebuffs)
end

local function FriendlyEditor(L)
	local c = L:Card("Friendly nameplates", "Off: friendly plates get the same rows as enemies. On: one top row with the categories below. On Forever, friendly plates show buffs by spell list and debuffs as crowd control only.")
	local function off() return not P().friendlyTopRowOnly end
	c:Add(Switch(c.card, "Only a top row on friendly plates", function() return P().friendlyTopRowOnly end, function(v) P().friendlyTopRowOnly = v end), true)
	c:Add(Slider(c.card, "Icons", 1, 12, 1, function() return P().friendlyMax end, function(v) P().friendlyMax = v end, nil, off))
	c:Add(Slider(c.card, "Icon size", 12, 64, 1, function() return P().friendlySize end, function(v) P().friendlySize = v end, nil, off))
	c:Add(Switch(c.card, "Glow", function() return P().friendlyGlow end, function(v) P().friendlyGlow = v end, nil, off))
	c:Add(Slider(c.card, "Offset X", -100, 100, 1, function() return P().friendlyOffsetX or P().topOffsetX end, function(v) P().friendlyOffsetX = v end, nil, off))
	c:Add(Slider(c.card, "Offset Y", -60, 100, 1, function() return P().friendlyOffsetY or P().topOffsetY end, function(v) P().friendlyOffsetY = v end, "Lower moves the row down, towards the plate.", off))
	c:End()
	CategoryCards(L, function(k) return P().friendlyCats[k] end, function(k, v) P().friendlyCats[k] = v and true or false end, off, true)
end

local function PageAppearance(L)
	L:Title("Appearance")
	local c = L:Card("Border")
	c:Add(Dropdown(c.card, "Border colour", { { "custom", "Custom" }, { "category", "Category" } }, function() return P().borderColorMode end, function(v) P().borderColorMode = v end))
	c:Add(Color(c.card, "Custom colour", function() local t = P().borderCustomColor; return t[1], t[2], t[3] end,
		function(r, g, b) P().borderCustomColor = { r, g, b, 1 } end, nil, function() return P().borderColorMode ~= "custom" end))
	c:End()

	c = L:Card("Timer")
	c:Add(Switch(c.card, "Show the timer", function() return P().showCooldown end, function(v) P().showCooldown = v end))
	c:Add(Slider(c.card, "Decimals under (s)", 0, 10, 1, function() return P().decimalThreshold end, function(v) P().decimalThreshold = v end, "Tenths of a second below this. 0: never."))
	c:Add(Slider(c.card, "Timer size", 6, 30, 1, function() return P().cooldownSize end, function(v) P().cooldownSize = v end, "At the reference icon size; scales with each row's icons."))
	c:Add(Slider(c.card, "Stack size", 6, 30, 1, function() return P().stackSize end, function(v) P().stackSize = v end))
	c:Add(Slider(c.card, "Reference icon size", 12, 64, 1, function() return P().iconSize end, function(v) P().iconSize = v end, "Text is drawn at the sizes above on icons this big, and scaled for other sizes."), true)
	c:Space(4)
	local function noTime() return not P().timerColorByTime end
	c:Add(Switch(c.card, "Colour the timer by time left", function() return P().timerColorByTime end, function(v) P().timerColorByTime = v end), true)
	if core.timerByPercent then
		local tip = "Share of the aura's full duration still left. A 30 s debuff at 50% turns yellow with 15 s left; a 2 min one with 60 s left."
		c:Add(Slider(c.card, "Yellow under (% left)", 5, 95, 5, function() return P().timerYellowPct end, function(v) P().timerYellowPct = v end, tip, noTime))
		c:Add(Slider(c.card, "Orange under (% left)", 5, 95, 5, function() return P().timerOrangePct end, function(v) P().timerOrangePct = v end, tip, noTime))
		c:Add(Slider(c.card, "Red under (% left)", 5, 95, 5, function() return P().timerRedPct end, function(v) P().timerRedPct = v end, tip, noTime))
	else
		c:Add(Slider(c.card, "Yellow under (s)", 1, 60, 0.5, function() return P().timerYellowAt end, function(v) P().timerYellowAt = v end, nil, noTime))
		c:Add(Slider(c.card, "Orange under (s)", 0.5, 30, 0.5, function() return P().timerOrangeAt end, function(v) P().timerOrangeAt = v end, nil, noTime))
		c:Add(Slider(c.card, "Red under (s)", 0.5, 15, 0.5, function() return P().timerRedAt end, function(v) P().timerRedAt = v end, nil, noTime))
	end
	c:NewLine()
	for _, k in ipairs({ { "white", "White" }, { "yellow", "Yellow" }, { "orange", "Orange" }, { "red", "Red" } }) do
		c:Add(Color(c.card, k[2], function() local t = P().timerColors[k[1]]; return t[1], t[2], t[3] end,
			function(r, g, b) P().timerColors[k[1]] = { r, g, b } end, nil, noTime))
	end
	c:End()

	c = L:Card("Category colours and glow", "Used by rows with Glow on, and by borders set to Category. Forever can only draw still glows: a thin frame or a soft halo.")
	local list = {}
	for _, cat in ipairs(CATS) do if cat[1] ~= "any" then list[#list + 1] = { cat[1], cat[2] } end end
	list[#list + 1] = { "mydebuffs", "My debuffs" }
	for _, it in ipairs(list) do
		local k = it[1]
		c:Add(Color(c.card, it[2], function() local t = P().catGlow[k].color; return t[1], t[2], t[3] end,
			function(r, g, b) P().catGlow[k].color = { r, g, b } end))
		c:Add(Dropdown(c.card, "Glow", GLOW_TYPES, function() return P().catGlow[k].type end, function(v) P().catGlow[k].type = v end))
	end
	c:End()

	c = L:Card("Dispellable buffs")
	local function off() return not P().dispelGlow end
	c:Add(Switch(c.card, "Highlight enemy buffs I can dispel or steal", function() return P().dispelGlow end, function(v) P().dispelGlow = v end, "The game decides which buffs count."), true)
	c:Add(Dropdown(c.card, "Which rows", { { "all", "Every row" }, { "other", "Only \"Any other aura\" rows" } }, function() return P().dispelGlowScope end, function(v) P().dispelGlowScope = v end, nil, off))
	c:Add(Dropdown(c.card, "Glow", { { "pixel", "Thin frame" }, { "proc", "Soft halo" } }, function() return P().dispelGlowType end, function(v) P().dispelGlowType = v end, nil, off))
	c:Add(Color(c.card, "Glow colour", function() local t = P().dispelGlowColor; return t[1], t[2], t[3] end, function(r, g, b) P().dispelGlowColor = { r, g, b } end, nil, off))
	c:End()
end

local function PageEnemyBuffs(L)
	L:Title("Enemy buffs", "In combat Forever hides which buff an enemy has. Addons can only use the game's own tags and how long a buff lasts, so that is all this page offers.")
	local c = L:Card("What works on enemy plates")
	c:Line("|cffffffffBig defensives, External defensives, Important buffs|r: whatever the game tags that way.\n|cffffffffShort buffs|r: any other buff up to the length below.\n|cffffffffAny other aura|r: the rest.\nSpell lists (Immunities, Shields, Speed boosts...) only work on friendly plates.", COL.dim)
	c:End()
	c = L:Card("Short buffs", "Catches cooldowns the game does not tag, like Recklessness or Death Wish. Turn the category on in a row (Rows page).")
	c:Add(Slider(c.card, "Short means up to (seconds)", 5, 120, 1, function() return P().foreverShortSeconds end, function(v) P().foreverShortSeconds = v end, "Total length of the buff, not time left."), true)
	c:End()
	c = L:Card("Any other aura")
	c:Add(Switch(c.card, "Show buffs there too while Short buffs is on", function() return P().anyBuffsWithShort end, function(v) P().anyBuffsWithShort = v end,
		"The game has no minimum-length filter, so short buffs cannot be kept out of Any other aura. Off: Any other aura shows no buffs while a row shows Short buffs. On: it does, and short buffs show twice."), true)
	c:End()
end
local function PageInterrupts(L)
	L:Title("Interrupts", "When an enemy's cast is interrupted, the row showing Interrupt lockouts gets an icon nearest the plate, and its other auras move outwards while it lasts.")
	local c = L:Card("Lockout")
	c:Add(Switch(c.card, "Show interrupt lockouts", function() return P().showInterrupts ~= false end, function(v) P().showInterrupts = v end))
	c:Add(Slider(c.card, "Other players' kicks (s)", 1, 10, 0.5, function() return P().interruptLockout end, function(v) P().interruptLockout = v end,
		"Forever does not say which interrupt someone else used, so their kicks get this length and a generic icon."))
	c:End()
	c = L:Card("Your own kicks", "Recognised from your cast (or your pet's) just before the interrupt: shown with that spell's icon and length.")
	for _, e in ipairs(core.INTERRUPTS) do
		c:Add(Slider(c.card, SpellIcon(e[3] and e[3][1]) .. e[1] .. " (s)", 1, 10, 0.5, function() return (P().interruptLengths or {})[e[1]] or e[2] end,
			function(v) P().interruptLengths = P().interruptLengths or {}; P().interruptLengths[e[1]] = v end))
	end
	c:End()
end

local function SpellName(id) return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id) end

local function PageSpells(L)
	L:Title("Spells", "Every spell the categories know, with all Forever ranks. On Forever, spell lists work for debuffs on enemies and buffs on friendly plates.")
	local search, addId, addCat = "", "", "cc"
	local c = L:Card("Search")
	local results
	c:Add(Input(c.card, "Spell name or ID", function() return search end, function(v) search = v or ""; results:Update() end), true)
	results = CreateFrame("Frame", nil, c.card)
	results:SetHeight(150)
	local fs = Note(results, "", COL.text, 12)
	fs:SetPoint("TOPLEFT"); fs:SetPoint("RIGHT")
	fs:SetJustifyV("TOP")
	function results:Update()
		local q = (search or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
		if q == "" then fs:SetText("|cff888888Type to search.|r"); return end
		local lines, n, qid = {}, 0, tonumber(q)
		for cat, set in pairs(core.ids) do
			for id in pairs(set) do
				local name = SpellName(id)
				if (qid and id == qid) or (not qid and name and name:lower():find(q, 1, true)) then
					n = n + 1
					if n <= 10 then lines[#lines + 1] = string.format("%s%s |cff888888%d|r  |cff33ff99%s|r", SpellIcon(id), name or "?", id, CAT_NAME[cat] or cat) end
				end
			end
		end
		table.sort(lines)
		if n == 0 then fs:SetText("|cff888888No spell in the lists matches.|r") return end
		if n > 10 then lines[#lines + 1] = string.format("|cff888888... and %d more|r", n - 10) end
		fs:SetText(table.concat(lines, "\n"))
	end
	Register(results)
	c:Add(results, true)
	c:End()

	c = L:Card("My debuffs", "Your debuffs seen on Warmane for this class. Switch one off to hide it from the top row (every Forever rank of it).")
	local class = select(2, UnitClass("player"))
	local names = {}
	-- the list was recorded on Warmane (3.3.5): leave out what Forever (1.x) does not have
	local dropped = 0
	for name in pairs(((P().myDebuffs or {})[class]) or {}) do
		if core.NOT_ON_FOREVER[name:lower()] then dropped = dropped + 1 else names[#names + 1] = name end
	end
	table.sort(names)
	if #names == 0 then c:Line("Nothing recorded for this class.") end
	if dropped > 0 then c:Line(dropped .. " Warmane-only spells (TBC and Wrath, not on Forever) are left out.") end
	for _, name in ipairs(names) do
		c:Add(Switch(c.card, NameIcon(name) .. name, function() return not P().myDebuffHidden[name] end, function(v) P().myDebuffHidden[name] = (not v) or nil end))
	end
	c:End()

	c = L:Card("Add your own spell", "Adds a spell id to a category. Useful for Forever spells the built-in lists do not know.")
	local nameLine
	c:Add(Input(c.card, "Spell ID", function() return addId end, function(v) addId = v or ""; nameLine:Update() end))
	local cats = {}
	-- only categories that use spell lists: enemy debuffs and friendly buffs
	for _, cat in ipairs(CATS) do
		if (cat[5] == "debuff" and cat[1] ~= "interrupt") or cat[5] == "list" then
			cats[#cats + 1] = { cat[1], cat[2] .. (cat[5] == "list" and " (friendly)" or " (enemy)") }
		end
	end
	c:Add(Dropdown(c.card, "Category", cats, function() return addCat end, function(v) addCat = v end))
	nameLine = CreateFrame("Frame", nil, c.card)
	nameLine:SetHeight(16)
	local nfs = Note(nameLine, "", COL.text, 12)
	nfs:SetPoint("LEFT")
	function nameLine:Update()
		local id = tonumber(addId)
		nfs:SetText(not id and "" or SpellName(id) and (SpellIcon(id) .. SpellName(id)) or "|cffff7755Unknown on this client|r")
	end
	Register(nameLine)
	c:Add(nameLine)
	local custom
	local addBtn = Button(c.card, "Add", function()
		local id = tonumber(addId)
		if not id then return end
		P().customSpells[id] = addCat
		addId = ""
		Changed(); custom:Update(); RefreshAll()
	end, nil, function() return not tonumber(addId) end, true)
	c:Inline({ addBtn })
	custom = CreateFrame("Frame", nil, c.card)
	custom:SetHeight(20)
	custom.rows = {}
	function custom:Update()
		local list = {}
		for id, cat in pairs(P().customSpells) do if cat then list[#list + 1] = tonumber(id) end end
		table.sort(list)
		for i, id in ipairs(list) do
			local r = self.rows[i]
			if not r then
				r = CreateFrame("Frame", nil, self)
				r:SetHeight(24)
				r:SetPoint("TOPLEFT", 0, -(i - 1) * 26); r:SetPoint("RIGHT")
				r.fs = Note(r, "", COL.text, 12)
				r.fs:SetPoint("LEFT")
				r.del = Button(r, "Remove", function() P().customSpells[r.id] = nil; Changed(); self:Update() end)
				r.del:SetPoint("RIGHT")
				self.rows[i] = r
			end
			r.id = id
			r.fs:SetText(string.format("%s%s |cff888888%d|r  |cff33ff99%s|r", SpellIcon(id), SpellName(id) or "?", id, CAT_NAME[P().customSpells[id]] or "?"))
			r:Show()
		end
		for i = #list + 1, #self.rows do self.rows[i]:Hide() end
		if #list == 0 then
			self.empty = self.empty or Note(self, "No spells added yet.")
			self.empty:SetPoint("TOPLEFT")
			self.empty:Show()
		elseif self.empty then self.empty:Hide() end
		local h = math.max(20, #list * 26)
		self:SetHeight(h)
		-- once the page is laid out, the card and the page grow or shrink with the list
		local d = self.lastH and (h - self.lastH) or 0
		self.lastH = h
		if d ~= 0 and self.card and self.card:GetHeight() > 0 then
			self.card:SetHeight(self.card:GetHeight() + d)
			local child = self.card:GetParent()
			child:SetHeight(child:GetHeight() + d)
			local sf = child:GetParent()
			if sf and sf.UpdateBar then sf.UpdateBar() end
		end
	end
	Register(custom)
	custom:Update()
	c:Add(custom, true)
	custom.card = c:End()
end

-- Aura library: everything seen on nameplates out of combat, grouped by caster, class and kind
local CLASS_ORDER = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
local SRC_ORDER = { OTHER = 15, NPC = 20, UNKNOWN = 30 }
for i, c in ipairs(CLASS_ORDER) do SRC_ORDER[c] = i end
local ROW_NAME = { rowLeft = "Left row", rowRight = "Right row", rowTop1 = "Top row", rowTop2 = "Extra 1", rowTop3 = "Extra 2", rowTop4 = "Extra 3", rowTop5 = "Extra 4", rowTop6 = "Extra 5" }
local function SourceName(k)
	if k == "NPC" then return "NPCs" end
	if k == "OTHER" then return "Items & other" end
	if k == "UNKNOWN" then return "Caster unknown" end
	return (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[k]) or (k:sub(1, 1) .. k:sub(2):lower())
end
local function SourceColor(k)
	local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[k]
	if c then return c.r, c.g, c.b end
	if k == "NPC" then return 0.9, 0.8, 0.5 end
	if k == "OTHER" then return 0.85, 0.85, 0.85 end
	return COL.dim[1], COL.dim[2], COL.dim[3]
end

local function PageProfiles(L)
	L:Title("Profiles", "Profiles are shared by every character. Your Warmane profiles were imported on first load.")
	local db = core.db
	local function list(exceptCurrent)
		local out = {}
		for _, name in ipairs(db:GetProfiles()) do
			if not (exceptCurrent and name == db:GetCurrentProfile()) then out[#out + 1] = { name, name } end
		end
		table.sort(out, function(a, b) return a[1] < b[1] end)
		return out
	end
	local c = L:Card("Current profile")
	c:Add(Dropdown(c.card, "This character uses", function() return list(false) end, function() return db:GetCurrentProfile() end, function(v) db:SetProfile(v) end), true)
	local newName = ""
	c:Add(Input(c.card, "New profile name", function() return newName end, function(v, enter)
		newName = v or ""
		if enter and newName ~= "" then db:SetProfile(newName); newName = ""; RefreshAll() end
	end, "Type a name and press Enter. The new profile starts from the defaults."))
	c:End()
	c = L:Card("Copy, reset, delete")
	local src, del = nil, nil
	c:Add(Dropdown(c.card, "Copy settings from", function() return list(true) end, function() return src end, function(v) src = v end))
	c:Add(Dropdown(c.card, "Delete profile", function() return list(true) end, function() return del end, function(v) del = v end))
	local confirmReset, confirmDel = false, false
	local copyBtn = Button(c.card, "Copy", function() if src then db:CopyProfile(src); RefreshAll() end end, "Overwrites the current profile.", function() return not src end)
	local resetBtn = Button(c.card, function() return confirmReset and "Click again to reset" or "Reset current" end, function()
		if confirmReset then db:ResetProfile(); confirmReset = false else confirmReset = true; C_Timer.After(3, function() confirmReset = false; RefreshAll() end) end
		RefreshAll()
	end)
	local delBtn = Button(c.card, function() return confirmDel and "Click again to delete" or "Delete" end, function()
		if not del then return end
		if confirmDel then db:DeleteProfile(del); del = nil; confirmDel = false else confirmDel = true; C_Timer.After(3, function() confirmDel = false; RefreshAll() end) end
		RefreshAll()
	end, nil, function() return not del end)
	c:Inline({ copyBtn, resetBtn, delBtn })
	c:End()
end

local function PageAbout(L)
	L:Title("About")
	local c = L:Card("Skom's Plate Buffs " .. (core.version or ""))
	c:Line("Forever edition, built on the client's own aura frames (the way MiniAuras works), because in combat Forever hides aura spell ids and the combat log from addons.\n\n" ..
		"|cffffffffWorks|r: enemy debuffs by the Forever spell lists, my debuffs, crowd control, buffs the game tags (big and external defensives, important), short buffs, friendly buffs by spell list, interrupt lockouts, still glows, dispellable buff glow, timer colours, test mode, profiles.\n\n" ..
		"|cffffffffNot possible on Forever|r: enemy buffs by spell list (immunities, shields, speed boosts...); debuff lists on friendly plates; per-spell size, glow and priority; animated glows; which interrupt another player used.\n\n" ..
		"Commands: |cff33ff99/skpb|r opens this window, |cff33ff99/skpb test|r toggles the preview.", COL.text)
	c:End()
end

------------------------------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------------------------------
local window
local NAV = {
	{ "general", "General", PageGeneral },
	{ "rows", "Rows" },
	{ "appearance", "Appearance", PageAppearance },
	{ "buffs", "Enemy buffs", PageEnemyBuffs },
	{ "interrupts", "Interrupts", PageInterrupts },
	{ "spells", "Spells", PageSpells },
	{ "library", "Aura library" },
	{ "profiles", "Profiles", PageProfiles },
	{ "about", "About", PageAbout },
}

local function MakeScroll(parent)
	local sf = CreateFrame("ScrollFrame", nil, parent)
	local child = CreateFrame("Frame", nil, sf)
	child:SetSize(1, 1)
	sf:SetScrollChild(child)
	sf:EnableMouseWheel(true)
	local bar = sf:CreateTexture(nil, "OVERLAY")
	bar:SetColorTexture(1, 1, 1, 0.18)
	bar:SetWidth(3)
	local function UpdateBar()
		local h, ch = sf:GetHeight(), child:GetHeight()
		if ch <= h + 1 then bar:Hide(); return end
		bar:Show()
		local bh = math.max(30, h * h / ch)
		local y = (sf:GetVerticalScroll() / (ch - h)) * (h - bh)
		bar:ClearAllPoints()
		bar:SetPoint("TOPRIGHT", sf, "TOPRIGHT", -3, -y)
		bar:SetHeight(bh)
	end
	sf:SetScript("OnMouseWheel", function(self, d)
		local max = math.max(0, child:GetHeight() - self:GetHeight())
		self:SetVerticalScroll(math.min(max, math.max(0, self:GetVerticalScroll() - d * 50)))
		UpdateBar()
	end)
	sf:SetScript("OnSizeChanged", function(self, w) child:SetWidth(w); UpdateBar() end)
	sf.child, sf.UpdateBar = child, UpdateBar
	return sf
end

-- small icon for a caster group
local function SetSourceIcon(tex, k)
	tex:SetTexCoord(0, 1, 0, 1)
	if k == "NPC" then tex:SetTexture(134400); pcall(tex.SetAtlas, tex, "questnormal"); return end
	if k == "OTHER" then tex:SetTexture("Interface\\Icons\\INV_Misc_Bag_07"); tex:SetTexCoord(0.07, 0.93, 0.07, 0.93); return end
	if k == "UNKNOWN" or k == "all" then tex:SetTexture(134400) return end
	local ok = pcall(tex.SetAtlas, tex, "classicon-" .. k:lower())
	if ok and tex:GetAtlas() then return end
	tex:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
	local c = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[k]
	if c then tex:SetTexCoord(c[1], c[2], c[3], c[4]) end
end

-- Aura library: a browser. Casters on the left, kind and plate on top, one scrolling list with a
-- switch per spell.
local function BuildLibraryPage(content, width)
	local page = CreateFrame("Frame", nil, content)
	page:SetAllPoints()
	local F = { src = "all", kind = "all", plate = "all", q = "" }
	local seen = function() return core.db.global.seen end

	local title = Text(page, 18)
	title:SetPoint("TOPLEFT", PAD, -PAD)
	title:SetText("Aura library")
	local sub = Note(page, "Auras met on nameplates out of combat that a row could show: debuffs, buffs the game tags, short buffs and buffs on a friendly spell list. Mounts, tracking, long class buffs and the like are left out. Right-click a spell to move it to another category.", COL.dim, 12)
	sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
	sub:SetPoint("RIGHT", -PAD, 0)

	-- top bar: search + segmented filters
	local bar = CreateFrame("Frame", nil, page)
	bar:SetPoint("TOPLEFT", PAD, -PAD - 52)
	bar:SetPoint("RIGHT", -PAD, 0)
	bar:SetHeight(28)
	local searchBg = CreateFrame("Frame", nil, bar)
	searchBg:SetPoint("LEFT"); searchBg:SetSize(220, 26)
	Fill(searchBg, { 0.08, 0.08, 0.09, 1 }); Outline(searchBg)
	local search = CreateFrame("EditBox", nil, searchBg)
	search:SetPoint("TOPLEFT", 8, 0); search:SetPoint("BOTTOMRIGHT", -8, 0)
	search:SetAutoFocus(false); search:SetFont(FONT, 12, ""); search:SetTextColor(1, 1, 1)
	local hint = Text(searchBg, 12, COL.dim)
	hint:SetPoint("LEFT", 8, 0); hint:SetText("Search name or ID")
	search:SetScript("OnEscapePressed", search.ClearFocus)
	search:SetScript("OnEnterPressed", search.ClearFocus)

	local list -- forward
	local segs = {}
	local function Seg(items, key, anchor)
		local holder = CreateFrame("Frame", nil, bar)
		holder:SetHeight(26)
		holder:SetPoint("LEFT", anchor, "RIGHT", 12, 0)
		local x, btns = 0, {}
		for _, it in ipairs(items) do
			local b = CreateFrame("Button", nil, holder)
			b:SetHeight(26)
			b.bg = Fill(b, { 0.15, 0.155, 0.175, 1 })
			b.fs = Text(b, 12); b.fs:SetPoint("CENTER"); b.fs:SetText(it[2])
			b:SetWidth(b.fs:GetStringWidth() + 22)
			b:SetPoint("LEFT", x, 0); x = x + b:GetWidth() + 1
			b:SetScript("OnClick", function() F[key] = it[1]; list:Update() end)
			b.value = it[1]
			btns[#btns + 1] = b
		end
		holder:SetWidth(x)
		function holder:Paint()
			for _, b in ipairs(btns) do
				local on = F[key] == b.value
				b.bg:SetColorTexture(on and COL.accent[1] * 0.3 or 0.15, on and COL.accent[2] * 0.3 or 0.155, on and COL.accent[3] * 0.3 or 0.175, 1)
				b.fs:SetTextColor(on and COL.accent[1] or COL.text[1], on and COL.accent[2] or COL.text[2], on and COL.accent[3] or COL.text[3])
			end
		end
		segs[#segs + 1] = holder
		return holder
	end
	local kindSeg = Seg({ { "all", "All" }, { "b", "Buffs" }, { "d", "Debuffs" } }, "kind", searchBg)
	Seg({ { "all", "Any plate" }, { "e", "Enemies" }, { "f", "Friends" } }, "plate", kindSeg)

	local confirm = false
	local forget = Button(bar, function()
		if not confirm then return "Empty the library" end
		return "Sure? Click to delete " .. (core.seenCount or 0) .. " spells"
	end, function(self)
		if confirm then wipe(seen()); core.seenCount = 0; confirm = false; list:Update()
		else confirm = true; C_Timer.After(5, function() confirm = false; RefreshAll() end) end
		RefreshAll()
		self:SetWidth(math.max(140, self.label:GetStringWidth() + 28))
	end, "Deletes every spell the library has collected. Blocked spells stay blocked.")
	forget:SetWidth(140)
	forget.label:SetTextColor(1, 0.45, 0.4)
	forget:SetPoint("RIGHT")

	-- left: casters
	local side = CreateFrame("Frame", nil, page)
	side:SetPoint("TOPLEFT", PAD, -PAD - 90)
	side:SetPoint("BOTTOMLEFT", PAD, PAD)
	side:SetWidth(170)
	Fill(side, COL.card); Outline(side)
	local srcBtns = {}
	local SOURCES = { "all" }
	for _, k in ipairs(CLASS_ORDER) do SOURCES[#SOURCES + 1] = k end
	SOURCES[#SOURCES + 1] = "OTHER"; SOURCES[#SOURCES + 1] = "NPC"; SOURCES[#SOURCES + 1] = "UNKNOWN"
	for i, k in ipairs(SOURCES) do
		local b = CreateFrame("Button", nil, side)
		b:SetHeight(28)
		b:SetPoint("TOPLEFT", 1, -6 - (i - 1) * 29); b:SetPoint("RIGHT", -1, 0)
		b.bg = Fill(b, { 1, 1, 1, 0.06 })
		b.mark = b:CreateTexture(nil, "ARTWORK")
		b.mark:SetColorTexture(COL.accent[1], COL.accent[2], COL.accent[3], 1)
		b.mark:SetPoint("TOPLEFT"); b.mark:SetPoint("BOTTOMLEFT"); b.mark:SetWidth(3)
		b.icon = b:CreateTexture(nil, "ARTWORK")
		b.icon:SetSize(18, 18); b.icon:SetPoint("LEFT", 10, 0)
		if k ~= "all" then SetSourceIcon(b.icon, k) else b.icon:Hide() end
		b.fs = Text(b, 12)
		b.fs:SetPoint("LEFT", k == "all" and 10 or 34, 0)
		local r, g, bl = SourceColor(k)
		if k == "all" then r, g, bl = COL.text[1], COL.text[2], COL.text[3] end
		b.fs:SetTextColor(r, g, bl)
		b.fs:SetText(k == "all" and "Everyone" or SourceName(k))
		b.count = Text(b, 11, COL.dim)
		b.count:SetPoint("RIGHT", -10, 0)
		b:SetScript("OnClick", function() F.src = k; list:Update() end)
		srcBtns[k] = b
	end

	-- right: the list
	local scroll = MakeScroll(page)
	scroll:SetPoint("TOPLEFT", side, "TOPRIGHT", 12, 0)
	scroll:SetPoint("BOTTOMRIGHT", -PAD, PAD + 22)
	local status = Note(page, "", COL.dim, 11)
	status:SetPoint("BOTTOMLEFT", side, "BOTTOMRIGHT", 12, -2)
	local ROW_H, MAX_ROWS = 38, 400
	local rows = {}

	local OpenMoveMenu, ClassOf -- below
	local function HideKey(e, id)
		local key = e.n and e.n:lower()
		if key and core.RanksByName and core.RanksByName[key] then return "name", key end
		return "id", id
	end
	local function IsHidden(e, id)
		local kind, k = HideKey(e, id)
		return (kind == "name" and P().hiddenNames[k]) or P().hiddenSpells[id] or false
	end
	local function SetHidden(e, id, hide)
		if hide then
			local kind, k = HideKey(e, id)
			if kind == "name" then P().hiddenNames[k] = true else P().hiddenSpells[id] = true end
		else
			if e.n then P().hiddenNames[e.n:lower()] = nil end
			P().hiddenSpells[id] = nil
		end
		Changed()
	end

	-- which category list holds a spell now (custom moves included)
	local function CurrentCat(id)
		for c, set in pairs(core.ids or {}) do if set[id] then return c end end
	end
	-- Right-click menu: move a spell to another category. Only categories that work from a spell
	-- list are offered: enemy debuff lists for debuffs seen on enemies, friendly buff lists for
	-- buffs seen on friends. An enemy buff can only be placed by the game's tags.
	local function Targets(l)
		local out = {}
		for _, cat in ipairs(CATS) do
			if l.kind == "d" and l.e.e and cat[5] == "debuff" and cat[1] ~= "interrupt" then out[#out + 1] = cat end
			if l.kind == "b" and l.e.f and cat[5] == "list" then out[#out + 1] = cat end
		end
		return out
	end
	local function MoveTo(l, cat)
		-- every rank when the name is known, else just this id
		local ids = (l.e.n and core.RanksByName and core.RanksByName[l.e.n:lower()]) or { l.id }
		local found = false
		for _, rid in ipairs(ids) do if rid == l.id then found = true end end
		if not found then ids = { l.id } end
		for _, rid in ipairs(ids) do P().customSpells[rid] = cat end -- nil: back to the Warmane lists
		Changed(); list:Update(); RefreshAll()
	end
	function OpenMoveMenu(owner, l)
		if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
		local targets = Targets(l)
		local cur = CurrentCat(l.id)
		MenuUtil.CreateContextMenu(owner, function(_, root)
			root:CreateTitle(l.e.n or ("Spell " .. l.id))
			if #targets == 0 then
				root:CreateTitle("|cff888888Can't move: on enemies, buffs are placed by the game's tags|r")
			else
				local move = root:CreateButton("Move to")
				for _, cat in ipairs(targets) do
					move:CreateRadio(SpellIcon(CAT_ICON[cat[1]]) .. cat[2], function() return cur == cat[1] end, function() MoveTo(l, cat[1]) end)
				end
				if P().customSpells[l.id] then
					root:CreateButton("Back to the built-in lists", function() MoveTo(l, nil) end)
				end
			end
			-- the class it belongs to (saved for every rank, account wide)
			local cls = root:CreateButton("Class")
			local current = ClassOf(l.e, l.id)
			local function SetClass(k)
				local ids = (l.e.n and core.RanksByName and core.RanksByName[l.e.n:lower()]) or { l.id }
				local has = false
				for _, rid in ipairs(ids) do if rid == l.id then has = true end end
				if not has then ids = { l.id } end
				for _, rid in ipairs(ids) do core.db.global.classOf[rid] = k end
				list:Update()
			end
			for _, k in ipairs(CLASS_ORDER) do
				cls:CreateRadio(SourceName(k), function() return current == k end, function() SetClass(k) end)
			end
			cls:CreateRadio("Not a class spell", function() return current == "OTHER" end, function() SetClass("OTHER") end)
			if core.db.global.classOf[l.id] then cls:CreateButton("Automatic", function() SetClass(nil) end) end
			if l.canHide then
				local hidden = IsHidden(l.e, l.id)
				root:CreateButton(hidden and "Allow on the plates" or "Block from the plates", function() SetHidden(l.e, l.id, not hidden); list:Update(); RefreshAll() end)
			end
		end)
	end

	local function Row(i)
		if rows[i] then return rows[i] end
		local r = CreateFrame("Frame", nil, scroll.child)
		r:SetHeight(ROW_H - 4)
		r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H); r:SetPoint("RIGHT", -10, 0)
		r.bg = Fill(r, COL.card)
		r.head = Text(r, 13, COL.accent)
		r.head:SetPoint("BOTTOMLEFT", 4, 4)
		r.icon = r:CreateTexture(nil, "ARTWORK")
		r.icon:SetSize(28, 28); r.icon:SetPoint("LEFT", 6, 0)
		r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		r.name = Text(r, 13)
		r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 10, -1)
		r.info = Text(r, 11, COL.dim)
		r.info:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 10, 1)
		r.note = Text(r, 11, COL.dim)
		r.note:SetPoint("RIGHT", -12, 0)
		r.note:SetText("Can't block on enemies")
		-- pill switch: on = shown
		local sw = CreateFrame("Button", nil, r)
		sw:SetSize(40, 20); sw:SetPoint("RIGHT", -12, 0)
		sw.bg = Fill(sw, COL.off)
		sw.knob = sw:CreateTexture(nil, "ARTWORK")
		sw.knob:SetSize(16, 16); sw.knob:SetColorTexture(0.95, 0.95, 0.97, 1)
		sw:SetScript("OnClick", function() local l = r.line; if l and l.canHide then SetHidden(l.e, l.id, not IsHidden(l.e, l.id)); r:Paint() end end)
		r.sw = sw
		r.label = Text(r, 11, COL.dim)
		r.label:SetPoint("RIGHT", sw, "LEFT", -8, 0)
		r.status = Text(r, 12)
		r.status:SetPoint("RIGHT", -200, 0)
		r.status:SetJustifyH("RIGHT")
		r:EnableMouse(true)
		r:SetScript("OnEnter", function(self)
			local l = self.line
			if not (l and l.id) then return end
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			if GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(l.id) else GameTooltip:AddLine(l.e.n or "?") end
			GameTooltip:Show()
		end)
		r:SetScript("OnLeave", function() GameTooltip:Hide() end)
		r:SetScript("OnMouseUp", function(self, button)
			if button == "RightButton" and self.line and self.line.id then OpenMoveMenu(self, self.line) end
		end)
		function r:Paint()
			local l = self.line
			if not l then return end
			if l.header then
				self.bg:Hide(); self.icon:Hide(); self.name:Hide(); self.info:Hide(); self.note:Hide(); self.sw:Hide(); self.label:Hide(); self.status:Hide()
				self.head:Show(); self.head:SetText(l.header)
				return
			end
			self.head:Hide(); self.bg:Show(); self.icon:Show(); self.name:Show(); self.info:Show(); self.status:Show()
			local e, id = l.e, l.id
			local hidden = IsHidden(e, id)
			self.icon:SetTexture(C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id) or 134400)
			self.icon:SetDesaturated(hidden)
			self.name:SetText(e.n or "?")
			self.name:SetTextColor(hidden and COL.dim[1] or COL.text[1], hidden and COL.dim[2] or COL.text[2], hidden and COL.dim[3] or COL.text[3])
			local parts = { "ID " .. id }
			local cat = CurrentCat(id)
			if cat and CAT_NAME[cat] then parts[#parts + 1] = "|cffdddddd" .. CAT_NAME[cat] .. (P().customSpells[id] and " (moved)" or "") .. "|r" end
			parts[#parts + 1] = (e.e and e.f) and "enemies and friends" or e.e and "enemies" or "friends"
			if e.x then parts[#parts + 1] = e.x end
			if l.src then
				local who = {}
				for _, k in ipairs(SOURCES) do if k ~= "all" and k ~= "UNKNOWN" and l.src[k] then who[#who + 1] = SourceName(k) end end
				if #who > 0 then parts[#parts + 1] = table.concat(who, ", ") end
			end
			self.info:SetText(table.concat(parts, "  ·  "))
			-- where it really appears with the current rows
			local status
			if hidden then
				status = "|cffff7766Blocked by you|r"
			elseif e.tg == nil and e.du == nil then
				status = "|cffaa8855Not checked yet: seen before this version|r"
			else
				local where = core.WhereShown and core.WhereShown(e, id, l.kind) or {}
				if #where == 0 then
					status = "|cff888888No row shows it|r"
				else
					local names = {}
					for _, w in ipairs(where) do
						local n = (w.side == "friend" and P().friendlyTopRowOnly) and "Friendly row" or ROW_NAME[w.row] or w.row
						names[#names + 1] = n .. ((e.e and e.f) and (w.side == "enemy" and " (enemies)" or " (friends)") or "")
					end
					status = "|cff33ff99Shown: " .. table.concat(names, ", ") .. "|r"
				end
			end
			self.status:SetText(status)
			if l.canHide then
				self.note:Hide(); self.sw:Show(); self.label:Show()
				self.label:SetText(hidden and "Blocked" or "Allowed")
				self.sw.knob:ClearAllPoints()
				if hidden then
					self.sw.knob:SetPoint("LEFT", self.sw, "LEFT", 2, 0)
					self.sw.bg:SetColorTexture(unpack(COL.off))
				else
					self.sw.knob:SetPoint("RIGHT", self.sw, "RIGHT", -2, 0)
					self.sw.bg:SetColorTexture(COL.accent[1] * 0.75, COL.accent[2] * 0.75, COL.accent[3] * 0.75, 1)
				end
			else
				self.sw:Hide(); self.label:Hide(); self.note:Show()
			end
		end
		rows[i] = r
		return r
	end

	-- Only what a row could ever show: any debuff; buffs the game tags, short buffs, and buffs on
	-- a friendly spell list. Long untagged buffs (mounts, Find Minerals, Fortitude, food...) can
	-- only reach a plate through "Any other aura", so they are left out.
	local LIST_CATS = { "immunity", "buff_def", "buff_off", "shield", "speed", "buff_other" }
	local function CouldAppear(e, id, kind)
		if kind == "d" then return true end
		if e.tg and (e.tg.BIG_DEFENSIVE or e.tg.EXTERNAL_DEFENSIVE or e.tg.IMPORTANT) then return true end
		if e.du and e.du > 0 and e.du <= (P().foreverShortSeconds or 30) then return true end
		if e.f then for _, c in ipairs(LIST_CATS) do if core.ids[c] and core.ids[c][id] then return true end end end
		return false
	end
	local function Matches(e, id, q, qid)
		if q ~= "" and not ((qid and id == qid) or (not qid and e.n and e.n:lower():find(q, 1, true))) then return false end
		if F.plate ~= "all" and not e[F.plate] then return false end
		return true
	end
	-- A class only gets the spells that belong to a class (Well Fed eaten by a paladin is not a
	-- paladin spell): the spell has to be in the class spell ranks or the category lists.
	local function IsClassSpell(e, id)
		if e.n and core.RanksByName and core.RanksByName[e.n:lower()] then return true end
		for _, set in pairs(core.ids or {}) do if set[id] then return true end end
		return false
	end
	-- class of a spell from the database (trainer data of Forever + rank families), the names of
	-- those spells on this client, or what you set with right-click
	local byName
	function ClassOf(e, id)
		local set = core.db.global.classOf and core.db.global.classOf[id]
		if set then return set end
		if core.ClassBySpell and core.ClassBySpell[id] then return core.ClassBySpell[id] end
		local key = e.n and e.n:lower()
		if not key then return end
		if core.ClassByName and core.ClassByName[key] then return core.ClassByName[key] end
		if not byName then
			byName = {}
			for sid, c in pairs(core.ClassBySpell or {}) do
				local n = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(sid)
				if n then
					n = n:lower()
					if byName[n] == nil then byName[n] = c elseif byName[n] ~= c then byName[n] = false end
				end
			end
		end
		return byName[key] or nil
	end
	local function SourcesOf(e, id)
		local out = {}
		local known = ClassOf(e, id)
		if known then
			out[known] = true
			if e.c and e.c.NPC then out.NPC = true end
			return out
		end
		if e.c then
			-- a known class spell, or only ever cast by one class (Forever's own spells are not in
			-- the rank tables); something several classes use (potions, racials...) is "other"
			local classes = 0
			for k in pairs(e.c) do if k ~= "NPC" then classes = classes + 1 end end
			local classSpell = classes == 1 or IsClassSpell(e, id)
			for k in pairs(e.c) do
				if k == "NPC" then out.NPC = true else out[classSpell and k or "OTHER"] = true end
			end
		end
		if not next(out) then out.UNKNOWN = true end
		return out
	end
	local function FromSource(src, k)
		return k == "all" or src[k] or false
	end

	list = {}
	function list:Update()
		local store = seen()
		local q = (F.q or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
		local qid = tonumber(q)
		-- counts per caster for the sidebar (with the search and plate filters, any kind)
		local counts = {}
		for _, k in ipairs(SOURCES) do counts[k] = 0 end
		local items = { b = {}, d = {} }
		for id, e in pairs(store) do
			local useful = (e.d and CouldAppear(e, id, "d")) or (e.b and CouldAppear(e, id, "b"))
			if useful and Matches(e, id, q, qid) then
				local src = SourcesOf(e, id)
				for _, k in ipairs(SOURCES) do if FromSource(src, k) then counts[k] = counts[k] + 1 end end
				if FromSource(src, F.src) then
					for _, kind in ipairs({ "b", "d" }) do
						if e[kind] and (F.kind == "all" or F.kind == kind) and CouldAppear(e, id, kind) then
							local t = items[kind]
							t[#t + 1] = { id = id, e = e, src = src, kind = kind, canHide = (kind == "d" and e.e) or (kind == "b" and e.f) or false }
						end
					end
				end
			end
		end
		local lines = {}
		for _, kind in ipairs({ "b", "d" }) do
			local t = items[kind]
			table.sort(t, function(a, b) return (a.e.n or "") < (b.e.n or "") end)
			if #t > 0 then
				lines[#lines + 1] = { header = (kind == "b" and "Buffs" or "Debuffs") .. "  |cff888888" .. #t .. "|r" }
				for _, it in ipairs(t) do lines[#lines + 1] = it end
			end
		end
		local n = math.min(#lines, MAX_ROWS)
		for i = 1, n do local r = Row(i); r.line = lines[i]; r:Paint(); r:Show() end
		for i = n + 1, #rows do rows[i]:Hide(); rows[i].line = nil end
		scroll.child:SetHeight(math.max(1, n * ROW_H))
		scroll:SetVerticalScroll(0)
		scroll.UpdateBar()
		for k, b in pairs(srcBtns) do
			local on = F.src == k
			b.mark:SetShown(on); b.bg:SetAlpha(on and 1 or 0)
			b.count:SetText(counts[k] > 0 and counts[k] or "")
		end
		for _, sg in ipairs(segs) do sg:Paint() end
		local total = #items.b + #items.d
		if core.seenCount == 0 then status:SetText("Nothing seen yet. Walk near some nameplates out of combat.")
		elseif #lines > MAX_ROWS then status:SetText(string.format("%d shown of %d. Search or pick a class to narrow it.", MAX_ROWS - 2, total))
		else status:SetText(string.format("%d %s. Blocking works for debuffs on enemies and buffs on friends.", total, total == 1 and "aura" or "auras")) end
	end
	search:SetScript("OnTextChanged", function(self)
		F.q = self:GetText() or ""
		hint:SetShown(F.q == "")
		list:Update()
	end)
	page:SetScript("OnShow", function() list:Update() end)
	return page
end

local function BuildRowsPage(content, width)
	local page = CreateFrame("Frame", nil, content)
	page:SetAllPoints()
	local strip = CreateFrame("Frame", nil, page)
	strip:SetPoint("TOPLEFT", PAD, -PAD - 34)
	strip:SetPoint("RIGHT", -PAD, 0)
	strip:SetHeight(28)
	local title = Text(page, 18)
	title:SetPoint("TOPLEFT", PAD, -PAD)
	title:SetText("Rows")
	local sub = {}
	local tabs = {}
	local scroll = MakeScroll(page)
	scroll:SetPoint("TOPLEFT", 0, -PAD - 70)
	scroll:SetPoint("BOTTOMRIGHT")
	local current
	local function Visible(key)
		local i = tonumber(key:match("^rowTop(%d)"))
		return not i or i <= (P().topRowCount or 1)
	end
	local addBtn
	local function LayoutTabs()
		local x = 0
		for _, t in ipairs(tabs) do
			t:SetShown(Visible(t.key))
			if t:IsShown() then
				t:ClearAllPoints(); t:SetPoint("LEFT", strip, "LEFT", x, 0); x = x + t:GetWidth() + 4
				local on = t.key == current
				t.bg:SetColorTexture(on and COL.accent[1] * 0.3 or 0.15, on and COL.accent[2] * 0.3 or 0.155, on and COL.accent[3] * 0.3 or 0.175, 1)
				t.fs:SetTextColor(on and COL.accent[1] or COL.text[1], on and COL.accent[2] or COL.text[2], on and COL.accent[3] or COL.text[3])
			end
		end
		addBtn:ClearAllPoints(); addBtn:SetPoint("LEFT", strip, "LEFT", x + 6, 0)
		addBtn:SetShown((P().topRowCount or 1) < 6)
	end
	local function Build(key)
		if not sub[key] then
			local f = CreateFrame("Frame", nil, scroll.child)
			f:SetPoint("TOPLEFT"); f:SetWidth(width)
			local L = NewLayout(f, width)
			L.y = -4
			if key == "friendly" then FriendlyEditor(L) else RowEditor(L, key) end
			f:SetHeight(L:Height())
			f:Hide()
			sub[key] = f
		end
		return sub[key]
	end
	local function SelectRow(key)
		if not Visible(key) then key = "rowLeft" end
		current = key
		for k, f in pairs(sub) do if k ~= key then f:Hide() end end
		Build(key):Show()
		scroll.child:SetHeight(sub[key]:GetHeight())
		scroll:SetVerticalScroll(0)
		scroll.UpdateBar()
		LayoutTabs()
		RefreshAll()
	end
	for _, t in ipairs(ROW_TABS) do
		local b = CreateFrame("Button", nil, strip)
		b:SetHeight(26)
		b.key = t[1]
		b.bg = Fill(b, { 0.15, 0.155, 0.175, 1 })
		b.fs = Text(b, 12)
		b.fs:SetPoint("CENTER")
		b.fs:SetText(t[2])
		b:SetWidth(b.fs:GetStringWidth() + 24)
		b:SetScript("OnClick", function() SelectRow(t[1]) end)
		tabs[#tabs + 1] = b
	end
	addBtn = Button(strip, "+ Row", function()
		P().topRowCount = math.min(6, (P().topRowCount or 1) + 1)
		Changed(); SelectRow("rowTop" .. P().topRowCount)
	end, "Add an extra row above the plate.", nil, true)
	addBtn:SetWidth(64)
	page.SelectRow = SelectRow
	page.Build = Build
	page:SetScript("OnShow", function() SelectRow(current or "rowLeft") end)
	return page
end

local function BuildPage(id)
	if pages[id] then return pages[id] end
	local w = window.content:GetWidth()
	if id == "rows" then
		pages.rows = BuildRowsPage(window.content, w)
	elseif id == "library" then
		pages.library = BuildLibraryPage(window.content, w)
	else
		local sf = MakeScroll(window.content)
		sf:SetAllPoints()
		local L = NewLayout(sf.child, w)
		for _, n in ipairs(NAV) do if n[1] == id then n[3](L) end end
		sf.child:SetHeight(L:Height())
		sf:SetScript("OnShow", function() sf.UpdateBar() end)
		pages[id] = sf
	end
	pages[id]:Hide()
	return pages[id]
end

-- After the window first opens, build the other pages and row editors in the background, one per
-- frame, so switching to them later is instant.
local prebuilt = false
local function Prebuild()
	if prebuilt then return end
	prebuilt = true
	local queue = {}
	for _, n in ipairs(NAV) do queue[#queue + 1] = { n[1] } end
	for _, t in ipairs(ROW_TABS) do queue[#queue + 1] = { "rows", t[1] } end
	local i = 0
	local function Step()
		i = i + 1
		local job = queue[i]
		if not job then return end
		if not InCombatLockdown() then
			local page = BuildPage(job[1])
			if job[2] and page.Build then page.Build(job[2]) end
		end
		C_Timer.After(0.02, Step)
	end
	C_Timer.After(0.05, Step)
end

local function Select(id)
	for _, n in ipairs(NAV) do
		local b = window.nav[n[1]]
		local on = n[1] == id
		b.mark:SetShown(on)
		b.fs:SetTextColor(on and 1 or COL.dim[1], on and 1 or COL.dim[2], on and 1 or COL.dim[3])
		b.bg:SetAlpha(on and 1 or 0)
		if pages[n[1]] then pages[n[1]]:Hide() end
	end
	BuildPage(id)
	window.current = id
	pages[id]:Show() -- the rows page refreshes itself when shown
	if id ~= "rows" then RefreshAll() end
end

local function BuildWindow()
	window = CreateFrame("Frame", "SkomsPlateBuffsOptions", UIParent)
	window:SetSize(1120, 700)
	window:SetPoint("CENTER")
	window:SetFrameStrata("HIGH")
	window:SetToplevel(true)
	window:SetMovable(true)
	window:SetClampedToScreen(true)
	window:EnableMouse(true)
	Fill(window, COL.bg)
	Outline(window, { 0.25, 0.26, 0.3, 1 })
	tinsert(UISpecialFrames, "SkomsPlateBuffsOptions")

	local bar = CreateFrame("Frame", nil, window)
	bar:SetPoint("TOPLEFT"); bar:SetPoint("TOPRIGHT")
	bar:SetHeight(44)
	Fill(bar, { 0.08, 0.083, 0.095, 1 })
	bar:EnableMouse(true)
	bar:RegisterForDrag("LeftButton")
	bar:SetScript("OnDragStart", function() window:StartMoving() end)
	bar:SetScript("OnDragStop", function() window:StopMovingOrSizing() end)
	local icon = bar:CreateTexture(nil, "ARTWORK")
	icon:SetSize(24, 24)
	icon:SetPoint("LEFT", 14, 0)
	icon:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\icon.tga")
	local title = Text(bar, 15)
	title:SetPoint("LEFT", icon, "RIGHT", 10, 0)
	title:SetText("|cff33ff99Skom's|r Plate Buffs")
	local ver = Text(bar, 11, COL.dim)
	ver:SetPoint("LEFT", title, "RIGHT", 8, -1)
	ver:SetText(core.version or "")

	local close = CreateFrame("Button", nil, bar)
	close:SetSize(28, 28)
	close:SetPoint("RIGHT", -8, 0)
	local x = Text(close, 18, COL.dim)
	x:SetPoint("CENTER")
	x:SetText("×")
	close:SetScript("OnEnter", function() x:SetTextColor(1, 0.4, 0.4) end)
	close:SetScript("OnLeave", function() x:SetTextColor(COL.dim[1], COL.dim[2], COL.dim[3]) end)
	close:SetScript("OnClick", function() window:Hide() end)

	local preview = Button(bar, function() return core:IsTesting() and "Stop preview" or "Preview on target" end, function() core:ToggleTest(); RefreshAll() end,
		"Sample auras in every row on your target's nameplate.", nil, true)
	preview:SetWidth(140)
	preview:SetPoint("RIGHT", close, "LEFT", -8, 0)
	local profile = Text(bar, 11, COL.dim)
	profile:SetPoint("RIGHT", preview, "LEFT", -14, 0)
	local profileCtl = CreateFrame("Frame", nil, bar)
	function profileCtl:Update() profile:SetText("Profile: |cffffffff" .. core.db:GetCurrentProfile() .. "|r") end
	profileCtl:SetAllPoints(bar)
	Register(profileCtl)

	local side = CreateFrame("Frame", nil, window)
	side:SetPoint("TOPLEFT", 0, -44)
	side:SetPoint("BOTTOMLEFT")
	side:SetWidth(180)
	Fill(side, COL.side)
	window.nav = {}
	for i, n in ipairs(NAV) do
		local b = CreateFrame("Button", nil, side)
		b:SetHeight(34)
		b:SetPoint("TOPLEFT", 0, -12 - (i - 1) * 36)
		b:SetPoint("RIGHT")
		b.bg = Fill(b, { 1, 1, 1, 0.05 })
		b.mark = b:CreateTexture(nil, "ARTWORK")
		b.mark:SetColorTexture(COL.accent[1], COL.accent[2], COL.accent[3], 1)
		b.mark:SetPoint("TOPLEFT"); b.mark:SetPoint("BOTTOMLEFT")
		b.mark:SetWidth(3)
		b.fs = Text(b, 13)
		b.fs:SetPoint("LEFT", 20, 0)
		b.fs:SetText(n[2])
		b:SetScript("OnEnter", function() if window.current ~= n[1] then b.bg:SetAlpha(0.5) end end)
		b:SetScript("OnLeave", function() if window.current ~= n[1] then b.bg:SetAlpha(0) end end)
		b:SetScript("OnClick", function() Select(n[1]) end)
		window.nav[n[1]] = b
	end
	local hint = Text(side, 10, COL.dim)
	hint:SetPoint("BOTTOMLEFT", 16, 14)
	hint:SetPoint("RIGHT", -12, 0)
	hint:SetText("Changes apply at once.\nIn combat they wait until it ends.")

	local content = CreateFrame("Frame", nil, window)
	content:SetPoint("TOPLEFT", side, "TOPRIGHT", 0, 0)
	content:SetPoint("BOTTOMRIGHT", -2, 2)
	window.content = content
	window:SetScript("OnShow", function() RefreshAll() end)
	window:Hide()
end

function core:OpenOptions(page)
	if not window then BuildWindow() end
	window:Show()
	Select(page or window.current or "general")
	Prebuild()
end

-- profile switches change every value
local function OnProfile() if window and window:IsShown() then RefreshAll() end end

function core:SetupOptions()
	core.db.RegisterCallback(core, "OnProfileChanged", function() core:ResetSideRows(); OnProfile() end)
	core.db.RegisterCallback(core, "OnProfileCopied", function() core:ResetSideRows(); OnProfile() end)
	core.db.RegisterCallback(core, "OnProfileReset", function() core:ResetSideRows(); OnProfile() end)

	-- an entry in the game's AddOns settings that opens the window
	if Settings and Settings.RegisterCanvasLayoutCategory then
		local panel = CreateFrame("Frame")
		panel.name = "Skom's Plate Buffs"
		local t = Text(panel, 16)
		t:SetPoint("TOPLEFT", 16, -16)
		t:SetText("|cff33ff99Skom's|r Plate Buffs")
		local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
		b:SetSize(180, 26)
		b:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -14)
		b:SetText("Open settings")
		b:SetScript("OnClick", function()
			if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
			core:OpenOptions()
		end)
		local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, panel, panel.name)
		if ok and cat then Settings.RegisterAddOnCategory(cat) end
	end

	SLASH_SKOMSPLATEBUFFS1 = "/skpb"
	SLASH_SKOMSPLATEBUFFS2 = "/skomsplatebuffs"
	SlashCmdList.SKOMSPLATEBUFFS = function(msg)
		msg = (msg or ""):lower()
		if msg:match("^%s*test") then core:ToggleTest(); RefreshAll(); return end
		if msg:match("^%s*dump") then
			-- writes name and tooltip text of every class spell of Forever's trainer data into the
			-- saved variables, so they can be read outside the game and sorted into categories
			local out = {}
			core.db.global.spellDump = out
			local n, left = 0, 0
			local ids = {}
			for id, cls in pairs(core.ClassBySpell or {}) do ids[id] = cls end
			for _, list in pairs(core.RanksByName or {}) do
				for _, id in ipairs(list) do ids[id] = ids[id] or "?" end
			end
			for _, id in ipairs(DUMP_EXTRA) do ids[id] = ids[id] or "?" end
			-- count first: spells already cached load at once, which must not finish the count early
			for _ in pairs(ids) do left = left + 1 end
			core.Print("reading %d spells...", left)
			local function Done()
				left = left - 1
				if left == 0 then core.Print("spell dump done: %d spells. /reload to write it to disk.", n) end
			end
			for id, cls in pairs(ids) do
				local function save()
					local name = C_Spell.GetSpellName and C_Spell.GetSpellName(id)
					local desc = C_Spell.GetSpellDescription and C_Spell.GetSpellDescription(id)
					local info = C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
					out[id] = { c = cls, n = name, d = desc, i = info and info.iconID }
					n = n + 1
					Done()
				end
				if Spell and Spell.CreateFromSpellID then
					local sp = Spell:CreateFromSpellID(id)
					if sp:IsSpellEmpty() then Done() else sp:ContinueOnSpellLoad(save) end
				else save() end
			end
			return
		end
		core:OpenOptions()
	end
end

-- 1.x aura ids that differ from the trainer spell (procs, talents, pets, racials, items): /skpb dump
-- checks which of them exist on Forever and what their tooltip says.
DUMP_EXTRA = {
	7922, 20253, 20614, 20615, 12809, 5530, 12798, 23694, 12323, 676, 18498, 12721, 412609, 12328, 12292, 12975, 12976, 2565, 29131, 2687, 20230,
	1833, 408, 8643, 6770, 2070, 11297, 2094, 1776, 1777, 8629, 11285, 11286, 18425, 14251, 3409, 11201, 13218, 13222, 13223, 13224, 5760, 8692, 11398, 2818, 2819, 11353, 11354, 25349, 11327, 14177, 13750, 13877, 14278, 14183, 14143, 14149, 26888,
	12355, 12494, 12484, 12485, 12486, 6136, 7321, 18469, 11958, 12042, 12043, 11129, 28682, 11426, 12536, 22959, 12579, 400589, 2139,
	19503, 19386, 24132, 24133, 3355, 14308, 14309, 13810, 19185, 19229, 19410, 24394, 19577, 25999, 4167, 4168, 4169, 3604, 19263, 19574, 15571, 19801, 24131, 24134, 24135,
	16922, 19675, 1238122, 19970, 19971, 19972, 19973, 19974, 19975, 9007, 9824, 9826, 17116, 5229, 16689, 16870,
	3600, 8034, 8037, 10458, 16352, 16353, 16188, 16166, 8178, 16177, 16236, 16237, 16246, 16257, 16277, 16278, 16279, 16280, 17364, 408505, 408510, 1238640, 29203,
	20066, 20170, 25771, 20184, 21183, 20188, 20300, 20301, 20302, 20303, 20185, 20344, 20345, 20346, 20186, 20354, 20355, 20216, 20925, 20128, 20131, 20132, 20133,
	15487, 15269, 10060, 6788, 14751, 2651, 15258, 15473, 27827, 15357, 14893, 15359, 6346,
	24259, 19244, 19647, 22703, 18093, 18223, 17941, 18288, 7812, 19438, 19440, 19441, 19442, 19443, 20707, 18708, 4511, 18118, 17794, 17797, 17798, 17799, 17800, 6358, 7870,
	20549, 7744, 20594, 20554, 26296, 26297, 20572, 20600, 20580,
	6615, 24364, 3169, 2379, 13141, 8892, 5024, 19769, 4068, 835, 13327, 9774, 5134, 14530, 13099, 23605, 1604, 6713, 13181, 11350, 23097,
}
