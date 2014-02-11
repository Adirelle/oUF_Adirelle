--[=[
Adirelle's oUF layout
(c) 2009-2014 Adirelle (adirelle@gmail.com)
All rights reserved.
--]=]

local _G, addonName, private = _G, ...
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

if oUF_Adirelle.CreatePseudoHeader then return end

--<GLOBALS
local _G = _G
local CreateFrame = _G.CreateFrame
local ipairs = _G.ipairs
local pairs = _G.pairs
local tinsert = _G.tinsert
local type = _G.type
local UIParent = _G.UIParent
--GLOBALS>

local headerProto = {
	Debug = oUF.Debug
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
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
		return
	end
	self:Show()
	for i, frame in ipairs(self.frames) do
		frame:Enable()
	end
	self:Debug('Enabled')
end

function headerProto:Disable()
	if not self:IsShown() then
		return
	elseif not self:CanChangeProtectedState() then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
		return
	end
	for i, frame in ipairs(self.frames) do
		frame:Disable()
	end
	self:Hide()
	self:Debug('Disabled')
end

function headerProto:OnEvent(event, ...)
	if event == "PLAYER_REGEN_ENABLED" then
		self:UnregisterEvent('PLAYER_REGEN_ENABLED')
	end
	self:Debug('Updating on', event)
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
	for name, func in pairs(headerProto) do
		header[name] = func
	end

	header:SetScript('OnEvent', header.OnEvent)

	oUF_Adirelle.RegisterMovable(header, key, label)

	return header
end
