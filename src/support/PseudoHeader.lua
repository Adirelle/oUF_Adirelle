--[=[
Adirelle's oUF layout
(c) 2009-2021 Adirelle (adirelle@gmail.com)

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
--]=]

local _G, assert = _G, _G.assert
local oUF_Adirelle = assert(_G.oUF_Adirelle)
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

if oUF_Adirelle.CreatePseudoHeader then
	return
end

--<GLOBALS
local CreateFrame = assert(_G.CreateFrame, "_G.CreateFrame is undefined")
local ipairs = assert(_G.ipairs, "_G.ipairs is undefined")
local pairs = assert(_G.pairs, "_G.pairs is undefined")
local tinsert = assert(_G.tinsert, "_G.tinsert is undefined")
local type = assert(_G.type, "_G.type is undefined")
local UIParent = assert(_G.UIParent, "_G.UIParent is undefined")
--GLOBALS>

local headerProto = {
	Debug = oUF.Debug,
}

function headerProto:AddFrame(frame)
	assert(type(frame.Enable) == "function", "header:AddFrame(frame): frame.Enable should be a function")
	assert(type(frame.Disable) == "function", "header:AddFrame(frame): frame.Disable should be a function")
	tinsert(self.frames, frame)
end

function headerProto:Enable()
	if self:IsShown() then
		return
	elseif not self:CanChangeProtectedState() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	self:Show()
	for _, frame in ipairs(self.frames) do
		frame:Enable()
	end
	self:Debug("Enabled")
end

function headerProto:Disable()
	if not self:IsShown() then
		return
	elseif not self:CanChangeProtectedState() then
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end
	for _, frame in ipairs(self.frames) do
		frame:Disable()
	end
	self:Hide()
	self:Debug("Disabled")
end

function headerProto:OnEvent(event)
	if event == "PLAYER_REGEN_ENABLED" then
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:Debug("Updating on", event)
	if self:GetEnabledSetting() and self:ShouldEnable() then
		self:Enable()
	else
		self:Disable()
	end
end

function oUF_Adirelle.CreatePseudoHeader(name, key, label, width, height, from, anchor, to, offsetX, offsetY)
	local header = CreateFrame("Frame", name, UIParent, "SecureFrameTemplate")
	header:SetSize(width, height)
	header:SetPoint(from, anchor, to, offsetX, offsetY)

	header.frames = {}
	for subName, func in pairs(headerProto) do
		header[subName] = func
	end

	header:SetScript("OnEvent", header.OnEvent)

	oUF_Adirelle.RegisterMovable(header, key, label)

	return header
end
