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

local icons = {}
local timerFrame
local mmin = math.min

local function UpdateAlpha(self)
	local now = GetTime()
	for icon, expireTime in pairs(icons) do
		local alpha = mmin(expireTime - now, 1)
		if alpha <= 0 then
			alpha = 1
			icon:Hide()
			icons[icon] =  nil
		end
		if icon:GetAlpha() ~= alpha then
			icon:SetAlpha(alpha)
		end
	end
	if not next(icons) then
		self:Hide()
	end
end

local function Update(self)
	local status = GetReadyCheckStatus(self.unit)
	local rc = self.ReadyCheck
	if rc.status == status then return end
	print('readycheck change', self.unit, 'old:', rc.status, 'new:', status)
	rc.status = status
	if status then
		icons[rc] = nil
		rc:SetTexture(textures[status])
		rc:SetAlpha(1.0)
		rc:Show()
	else		
		if not timerFrame then
			timerFrame = CreateFrame("Frame")
			timerFrame:SetScript('OnUpdate', UpdateAlpha)
		end
		icons[rc] = GetTime() + 5
		timerFrame:Show()
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

