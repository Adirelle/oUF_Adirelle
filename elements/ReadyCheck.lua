--[=[
Adirelle's oUF raid layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .ReadyCheck	
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")

local textures = {
	waiting   = READY_CHECK_WAITING_TEXTURE,
	ready     = READY_CHECK_READY_TEXTURE,
	not_ready = READY_CHECK_NOT_READY_TEXTURE,
	afk       = READY_CHECK_AFK_TEXTURE
}

local function Update(self)
	local texture = textures[GetReadyCheckStatus(self.unit) or ""]
	local rc = self.ReadyCheck
	if texture then
		rc:SetTexture(texture)
		rc:Show()
	else
		rc:Hide()
	end
end

local function Enable(self)
	if self.ReadyCheck then
		self:RegisterEvent('READY_CHECK', Update)
		self:RegisterEvent('READY_CHECK_CONFIRM', Update)
		self:RegisterEvent('READY_CHECK_FINISHED', Update)
		return true
	end
end

local function Disable(self)
	local rc = self.ReadyCheck
	if rc then	
		self:UnregisterEvent('READY_CHECK')
		self:UnregisterEvent('READY_CHECK_CONFIRM')
		self:UnregisterEvent('READY_CHECK_FINISHED')
		rc:Hide()
	end
end

oUF:AddElement('ReadyCheck', Update, Enable, Disable)

