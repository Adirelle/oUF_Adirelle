--[=[
Adirelle's oUF raid layout
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

local icons = {}
local fadeOutFrame

local function FadeOutIcons()
	local now = GetTime()
	for icon, expireTime in pairs(icons) do
		local alpha = math.min(expireTime - now, 1)
		if alpha <= 0 then
			icon:Hide()
			icons[icon] = nil
		else
			icon:SetAlpha(alpha)
		end
	end
	if not next(icons) then
		fadeOutFrame:Hide()
	end
end

local function SetStatus(self, newStatus)
	local rc = self.ReadyCheck
	local oldStatus = rc.status
	if oldStatus == newStatus then return end
	--print('ReadyCheck:SetStatus', self.unit, ':', oldStatus, '=>', newStatus)
	rc.status = newStatus
	if newStatus == 'waiting' or newStatus == 'ready' or newStatus == 'notready' then
		--print('=> showing texture', textures[newStatus])
		rc:SetTexture(textures[newStatus])
		rc:SetAlpha(1)
		rc:Show()
		icons[rc] = nil
	elseif not newStatus and rc:IsShown() then
		if oldStatus == 'waiting' then
			rc:SetTexture(textures.afk)
			--print("=> afking")
		end
		--print("=> starting fade out timer")
		icons[rc] = GetTime()+5
		fadeOutFrame:Show()
	end
end

local function OnCheckStart(self, event)
	--print('ReadyCheck:OnCheckStart', event, self.unit)
	SetStatus(self, 'waiting')
end

local function OnCheckAnswer(self, event, unitId, answer)
	local unit =(GetNumRaidMembers() > 0 and "raid" or "party") .. unitId
	if UnitIsUnit(unit, self.unit) then
		--print('ReadyCheck:OnCheckAnswer', event, unit, answer)
		SetStatus(self, tonumber(answer) == 1 and 'ready' or 'notready')
	end
end

local function OnCheckFinished(self)
	--print('ReadyCheck:OnCheckFinished', self.unit)
	SetStatus(self, nil)
end

local function Update(self, event)
	local status = GetReadyCheckStatus(self.unit)
	--print('ReadyCheck:Update', event, self.unit, status)
	SetStatus(self, status)
end

local function Enable(self)
	if self.ReadyCheck then
		self:RegisterEvent('READY_CHECK', OnCheckStart)
		self:RegisterEvent('READY_CHECK_CONFIRM', OnCheckAnswer)
		self:RegisterEvent('READY_CHECK_FINISHED', OnCheckFinished)
		if not fadeOutFrame then
			fadeOutFrame = CreateFrame("Frame")
			fadeOutFrame:SetScript('OnUpdate', FadeOutIcons)
			fadeOutFrame:Hide()
		end
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
