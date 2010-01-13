--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .RuneBar
--]=]

local parent, ns = ...
local oUF = assert(ns.oUF, "oUF is undefined in "..parent.." namespace")

local GetTime = GetTime
local function OnUpdate(rune)			
	local now = GetTime()
	rune:SetValue(now)
	if now > rune.readyTime then
		rune:SetScript('OnUpdate', nil)
	end
end

local function RuneUpdate(self, event, index)
	local rune = self.RuneBar[index]
	if not rune then return end
	if rune.UpdateRuneColor then
		rune:UpdateRuneColor()
	end
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
		self:UnregisterEvent('RUNE_POWER_UPDATE', Update)
		self:UnregisterEvent('RUNE_TYPE_UPDATE', Update)		
	end
end

oUF:AddElement('RuneBar', Update, Enable, Disable)

