--[=[
Adirelle's oUF layout
(c) 2011-2021 Adirelle (adirelle@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Elements handled: .PvPTimer
--]=]

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

--<GLOBALS
local floor = assert(_G.floor, "_G.floor is undefined")
local GetPVPTimer = assert(_G.GetPVPTimer, "_G.GetPVPTimer is undefined")
local gsub = assert(_G.gsub, "_G.gsub is undefined")
local IsPVPTimerRunning = assert(_G.IsPVPTimerRunning, "_G.IsPVPTimerRunning is undefined")
local SecondsToTimeAbbrev = assert(_G.SecondsToTimeAbbrev, "_G.SecondsToTimeAbbrev is undefined")
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
			timer:SetScript("OnUpdate", OnUpdate)
			timer.elapsed, timer.timeLeft = 0, 0
			self:RegisterEvent("PLAYER_FLAGS_CHANGED", Update)
			return true
		end
	end
end

local function Disable(self)
	if self.PvPTimer then
		self.PvPTimer:Hide()
		self:UnregisterEvent("PLAYER_FLAGS_CHANGED", Update)
	end
end

oUF:AddElement("PvPTimer", Update, Enable, Disable)
