--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .RuneBar
--]=]

local _debug
if tekDebug then
	local f = tekDebug:GetFrame("oUF_Adirelle_RuneBar")
	_debug = function(...) f:AddMessage(string.join(", ", tostringall(...)):gsub("([=:]), ", "%1")) end
else
	_debug = function() end
end

oUF.colors.runes = oUF.colors.runes or {
	{ 1, 0, 0  },
	{ 0, 0.5, 0 },
	{ 0, 1, 1 },
	{ 0.8, 0.1, 1 },
}

local function UpdateRuneColor(rune)
	local color = oUF.colors.runes[GetRuneType(rune.index) or false]
	if color then
		rune:SetStatusBarColor(unpack(color))
	end
end

local GetTime = GetTime
local function OnUpdate(rune)			
	local now = GetTime()
	rune:SetValue(now)
	if now > rune.readyTime then
		rune:SetScript('OnUpdate', nil)
	end
end

local function RuneUpdate(self, event, index)
	_debug('RuneUpdate', self, event, index)
	local rune = self.RuneBar[index]
	if not rune then return end
	UpdateRuneColor(rune)
	local start, duration, ready = GetRuneCooldown(index)
	if not ready then
		rune.duration = duration
		rune.readyTime = start + duration
		rune:SetMinMaxValues(start, start + duration)
		rune:SetScript('OnUpdate', OnUpdate)
	else
		rune:SetScript('OnUpdate', nil)		
	end
end

local function Update(self, event, index, ...)
	_debug('Update, self=', self, 'event=', event, 'index=', index, 'stack=', debugstack())
	if not tonumber(index) then
		if self.unit ~= 'player' then 
			return self.RuneBar:Hide()
		else
			self.RuneBar:Show()
		end
		for index = 1, 6 do 
			RuneUpdate(self, event, index) 
		end
	else
		RuneUpdate(self, event, index) 
	end		
end

local function Enable(self)
	if self.RuneBar then
		_debug('Enable', self)
		self:RegisterEvent('RUNE_POWER_UPDATE', Update)
		self:RegisterEvent('RUNE_TYPE_UPDATE', Update)		
		RuneFrame:Hide()
		RuneFrame.Show = RuneFrame.Hide
		RuneFrame:UnregisterAllEvents()
		return true
	end
end

local function Disable(self)
	if self.RuneBar then
		_debug('Disable', self)
		self:UnregisterEvent('RUNE_POWER_UPDATE', Update)
		self:UnregisterEvent('RUNE_TYPE_UPDATE', Update)		
	end
end

oUF:AddElement('RuneBar', Update, Enable, Disable)

