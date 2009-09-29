--[=[
Adirelle's oUF raid layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .TargetColor
--]=]

local colors
local NUM_COLORS = 20

local function LoadColors()
	local pi, cos, floor = math.pi, math.cos, math.floor
	colors = {}
	for i = 1, NUM_COLORS do
		local fr = (i * 11) % NUM_COLORS / NUM_COLORS		
		local fg = (fr + 1/3) % 1
		local fb = (fr + 2/3) % 1
		local r = fr < 0.5 and 1-fr*2 or fr*2-1
		local g = fg < 0.5 and 1-fg*2 or fg*2-1
		local b = fb < 0.5 and 1-fb*2 or fb*2-1
		colors[i] = { r, g, b }
	end
	LoadColors = nil
end

local function GetColorForGUID(guid)
	return tremove(colors)
end

local guidColorMap = setmetatable({}, {__index = function(t, guid)
	if not guid then return end
	local color = GetColorForGUID(guid)
	t[guid] = color
	return color
end})

local function ResetColors(_)
	for guid, color in pairs(guidColorMap) do
		tinsert(colors, color)
	end
	wipe(guidColorMap)
end

local function CheckDeadFoes(self, _, _, event, _, _, _, guid)
	if event == 'UNIT_DIED' and guid and guidColorMap[guid] then
		local color = guidColorMap[guid]
		guidColorMap[guid] = nil
		tinsert(colors, color)
	end
end

local function Update(self, event, unit)
	if unit and unit ~= self.unit then return end
	unit = self.unit
	local target = unit == "player" and "target" or unit..'target'
	local color
	if UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) and UnitCanAttack('player', target) then
		color = guidColorMap[UnitGUID(target)]
	end
	if color then
		local tc = self.TargetColor
		tc:SetColor(unpack(color, 1, 3))
		tc:Show()
	else
		self.TargetColor:Hide()
	end
end

local function Enable(self)
	if self.TargetColor then
		if not colors then
			LoadColors()
			oUF:RegisterEvent('PLAYER_REGEN_ENABLED', ResetColors)
			oUF:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED', CheckDeadFoes)
		end
		self:RegisterEvent('UNIT_TARGET', Update)
		self:RegisterEvent('UNIT_FLAGS', Update)
		return true
	end
end

local function Disable(self)
	if self.TargetColor then
		self:UnregisterEvent('UNIT_TARGET', Update)
		self:UnregisterEvent('UNIT_FLAGS', Update)
	end
end

oUF:AddElement('TargetColor', Update, Enable, Disable)

