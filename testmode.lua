-- Test mode: sample icons in every row on your target's nameplate, so rows can be placed without a
-- fight. Plain frames, not AuraContainers (those only ever show real auras), drawn with the same
-- sizes, offsets, borders and glows. Out of combat only.
local ADDON, core = ...

-- one sample spell per aura group (1.x Forever ids)
local SAMPLE = {
	cc_tag = 118, cc = 853, disarm = 676, root = 339, healing_reduction = 12294, snare = 1715,
	mine = 772, bigdef = 871, extdef = 1022, imp = 1719, short = 12328, immunity = 642,
	buff_def = 871, buff_off = 1719, shield = 17, speed = 2983, buff_other = 774,
	anydebuff = 172, anybuff = 1459, interrupt = 6552,
}

local active = false
local holders = {}
local pool = {}

local function Texture(id)
	local t = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
	return t or 134400
end

local function Clear()
	-- back to the pool: frames can never be freed, so they are reused
	for _, h in ipairs(holders) do h:Hide(); pool[#pool + 1] = h end
	wipe(holders)
end

local function GetHolder()
	local h = table.remove(pool) or CreateFrame("Frame", nil, UIParent)
	h.icons = h.icons or {}
	for _, b in ipairs(h.icons) do b:Hide(); if b.glowFrame then b.glowFrame:Hide() end end
	holders[#holders + 1] = h
	return h
end

local function Icon(h, i, size)
	local b = h.icons[i]
	if not b then
		b = CreateFrame("Frame", nil, h)
		b.border = b:CreateTexture(nil, "BACKGROUND", nil, 0)
		b.icon = b:CreateTexture(nil, "BACKGROUND", nil, 1)
		b.icon:SetAllPoints()
		b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
		b.cd:SetAllPoints()
		b.cd:SetDrawEdge(false)
		b.cd:SetReverse(true)
		h.icons[i] = b
	end
	b:SetSize(size, size)
	b.border:ClearAllPoints()
	b.border:SetPoint("TOPLEFT", -1, 1)
	b.border:SetPoint("BOTTOMRIGHT", 1, -1)
	return b
end

local function Draw()
	Clear()
	if not active or InCombatLockdown() then return end
	local plate = C_NamePlate.GetNamePlateForUnit("target")
	if not plate then return end
	local P = core.db.profile
	local anchor = core.AnchorFrame(plate)
	local layout = core.BuildLayout("enemy")
	for rowKey, groups in pairs(layout) do
		if type(groups) ~= "table" then groups = nil end
		if groups then
		-- a sample interrupt lockout first in the row that shows them
		if layout.interruptRow == rowKey then
			groups = { { key = "interrupt", color = groups[1] and groups[1].color or { 1, 0.5, 0 } }, unpack(groups) }
		end
		local where, max, size, glow, x, y = core.RowGeometry(rowKey, "enemy")
		local f = core.FLOW[where]
		local spacing = where == "top" and (P.topSpacing or 2) or (P.sideSpacing or 2)
		local h = GetHolder()
		h:SetParent(plate)
		h:SetFrameLevel(anchor:GetFrameLevel() + 10)
		-- one sample per group, up to the row's max
		local n = math.min(max, #groups)
		h:SetSize(math.max(1, n * size + (n - 1) * spacing), size)
		h:ClearAllPoints()
		h:SetPoint(f.point, anchor, f.rel, x, y)
		for i = 1, n do
			local g = groups[i]
			local b = Icon(h, i, size)
			b:ClearAllPoints()
			local offset = (i - 1) * (size + spacing)
			if where == "left" then b:SetPoint("RIGHT", h, "RIGHT", -offset, 0) else b:SetPoint("LEFT", h, "LEFT", offset, 0) end
			local c = P.borderColorMode == "category" and g.color or P.borderCustomColor or { 0, 0, 0 }
			b.border:SetColorTexture(c[1], c[2], c[3], 1)
			b.icon:SetTexture(Texture(SAMPLE[g.key] or 134400))
			-- samples spread over the timer colours: 25, 12, 6 and 2 s left of 30
			local left = ({ 25, 12, 6, 2 })[(i - 1) % 4 + 1]
			b.cd:SetCooldown(GetTime() - (30 - left), 30)
			local fs = b.cd.GetCountdownFontString and b.cd:GetCountdownFontString()
			if fs then fs:SetFont(STANDARD_TEXT_FONT, math.max(6, (P.cooldownSize or 11) * size / math.max(1, P.iconSize or 28)), "OUTLINE") end
			if fs then fs:SetTextColor(core.TimerColor(left, 30)) end
			-- one glow per sample icon, made again only when its look (halo or thin frame) or size changes
			local look = glow and g.color.glowType or nil
			if look and (b.glowLook ~= look or b.glowSize ~= size) then
				if b.glowFrame then b.glowFrame:Hide() end
				local tex = core.AddGlow(b, g.color, size)
				b.glowFrame, b.glowTex, b.glowLook, b.glowSize = tex and tex:GetParent() or nil, tex, look, size
			end
			if b.glowTex and look then b.glowTex:SetVertexColor(g.color[1], g.color[2], g.color[3], 1) end
			if b.glowFrame then b.glowFrame:SetShown(look ~= nil and b.glowLook == look) end
			b:Show()
		end
		h:Show()
		end
	end
end

local ev = CreateFrame("Frame")
ev:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_REGEN_DISABLED" then Clear() else Draw() end
end)

function core:ToggleTest()
	active = not active
	if active then
		ev:RegisterEvent("PLAYER_TARGET_CHANGED")
		ev:RegisterEvent("NAME_PLATE_UNIT_ADDED")
		ev:RegisterEvent("PLAYER_REGEN_DISABLED")
		ev:RegisterEvent("PLAYER_REGEN_ENABLED")
		core.Print("test mode on: target any nameplate to see sample auras in every row. /skpb test to stop.")
	else
		ev:UnregisterAllEvents()
		core.Print("test mode off.")
	end
	Draw()
end

function core:IsTesting() return active end
core.RedrawTest = Draw
