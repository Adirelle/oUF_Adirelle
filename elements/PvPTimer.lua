--[=[
Adirelle's oUF layout
(c) 2011-2014 Adirelle (adirelle@gmail.com)
All rights reserved.

Elements handled: .PvPTimer
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local _G = _G
local floor = _G.floor
local GetPVPTimer = _G.GetPVPTimer
local gsub = _G.gsub
local IsPVPTimerRunning = _G.IsPVPTimerRunning
local SecondsToTimeAbbrev = _G.SecondsToTimeAbbrev
--GLOBALS>

local function OnElapsed(timer, elapsed)
	timer.timeLeft = timer.timeLeft - 1000 * elapsed
	if timer.timeLeft <= 0 then
		timer:Hide()
	else
		local fmt, value = SecondsToTimeAbbrev(floor(timer.timeLeft / 1000))
		timer.text:SetFormattedText(gsub(fmt, " ", ""), value)
	end
end

local function OnUpdate(timer, elapsed)
	timer.elapsed = timer.elapsed + elapsed
	if timer.elapsed >= 1 then
		OnElapsed(timer, timer.elapsed)
		timer.elapsed = 0
	end
end

local function Update(self)
	local timer = self.PvPTimer
	if IsPVPTimerRunning() then
		timer.timeLeft, timer.elapsed = GetPVPTimer(), 0
		timer:Show()
		OnElapsed(timer, 0)
	else
		timer:Hide()
	end
end

local function Enable(self)
	local timer = self.PvPTimer
	if timer then
		timer:Hide()
		if self.unit == "player" then
			timer:SetScript('OnUpdate', OnUpdate)
			timer.elapsed, timer.timeLeft = 0, 0
			self:RegisterEvent('PLAYER_FLAGS_CHANGED', Update)
			return true
		end
	end
end

local function Disable(self)
	if self.PvPTimer then
		self.PvPTimer:Hide()
		self:UnregisterEvent('PLAYER_FLAGS_CHANGED', Update)
	end
end

oUF:AddElement('PvPTimer', Update, Enable, Disable)

