--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.

Elements handled: .ReadyCheck
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")

local textures = {
	waiting  = READY_CHECK_WAITING_TEXTURE,
	ready    = READY_CHECK_READY_TEXTURE,
	notready = READY_CHECK_NOT_READY_TEXTURE,
	afk      = READY_CHECK_AFK_TEXTURE
}

local function FadeOut(self, elapsed)
	local delay = self.delay - elapsed
	if delay <= 0 then
		self:Hide()
	else
		self.icon:SetAlpha(math.min(delay, 1))
		self.delay = delay
	end
end

local function StopFadingOut(self)
	self.icon:SetAlpha(1)
	self:SetScript('OnUpdate', nil)
	self:SetScript('OnHide', nil)
end

local function StartFadingOut(self, delay)
	self.delay = delay
	self:SetScript('OnUpdate', FadeOut)
	self:SetScript('OnHide', StopFadingOut)
end

local function SetStatus(self, newStatus)
	local rc = self.ReadyCheck
	local oldStatus = rc.status
	if not IsRaidLeader() and not IsRaidOfficer() and not IsPartyLeader() then
		newStatus = nil
	end
	if oldStatus == newStatus then return end
	rc.status = newStatus
	if newStatus == 'waiting' or newStatus == 'ready' or newStatus == 'notready' then
		rc.icon:SetTexture(textures[newStatus])
		rc.icon:SetAlpha(1)
		rc:Show()
	elseif not newStatus and rc:IsShown() then
		if oldStatus == 'waiting' then
			rc.icon:SetTexture(textures.afk)
		end
		StartFadingOut(rc, 5)
	end
end

local function OnCheckStart(self, event, requestor)
	SetStatus(self, requestor == UnitName(self.unit) and 'ready' or 'waiting')
end

local function OnCheckAnswer(self, event, unitId, answer)
	local unit =(GetNumRaidMembers() > 0 and "raid" or "party") .. unitId
	if UnitIsUnit(unit, self.unit) then
		SetStatus(self, tonumber(answer) == 1 and 'ready' or 'notready')
	end
end

local function OnCheckFinished(self)
	SetStatus(self, nil)
end

local function Update(self, event)
	SetStatus(self, GetReadyCheckStatus(self.unit))
end

local function Enable(self)
	if self.ReadyCheck then
		self:RegisterEvent('READY_CHECK', OnCheckStart)
		self:RegisterEvent('READY_CHECK_CONFIRM', OnCheckAnswer)
		self:RegisterEvent('READY_CHECK_FINISHED', OnCheckFinished)
		return true
	end
end

local function Disable(self)
	local rc = self.ReadyCheck
	if rc then
		self:UnregisterEvent('READY_CHECK', OnCheckStart)
		self:UnregisterEvent('READY_CHECK_CONFIRM', OnCheckAnswer)
		self:UnregisterEvent('READY_CHECK_FINISHED', OnCheckFinished)
		rc:Hide()
	end
end

oUF:AddElement('ReadyCheck', Update, Enable, Disable)
