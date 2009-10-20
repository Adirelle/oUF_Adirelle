--[=[
Adirelle's oUF layout
(c) 2009 Adirelle (adirelle@tagada-team.net)
All rights reserved.
--]=]

local oUF = assert(_G.oUF, "oUF_Adirelle requires oUF")

local texture = [[Interface\TargetingFrame\UI-StatusBar]]
local objects = {}

local function UpdateTexture(object)
	if object.SetStatusBarTexture then
		object:SetStatusBarTexture(texture)
	else
		object:SetTexture(texture)
	end
	if type(object.PostTextureUpdate) == "function" then
		object:PostTextureUpdate(texture)
	end
end

function oUF:RegisterStatusBarTexture(object)
	local handler = object.SetStatusBarTexture or object.SetTexture
	assert(type(handler) == "function", "object has neither :SetTexture nor :SetStatusBarTexture") 
	objects[object] = true
	UpdateTexture(object)
end

local lsm = LibStub('LibSharedMedia-3.0', true)
if lsm then
	texture = lsm:Fetch("statusbar", 'BantoBar')	
	lsm.RegisterCallback(objects, 'LibSharedMedia_SetGlobal', function(_, media, value)
		if media == "statusbar" then
			texture = lsm:Fetch("statusbar", value)
			for object in pairs(objects) do
				UpdateTexture(object)
			end
		end
	end)
end
	
