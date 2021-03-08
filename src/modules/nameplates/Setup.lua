--[=[
Adirelle's oUF layout
(c) 2009-2016 Adirelle (adirelle@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
--]=]

local _G = _G
local oUF_Adirelle, assert = _G.oUF_Adirelle, _G.assert
local oUF = assert(oUF_Adirelle.oUF, "oUF is undefined in oUF_Adirelle")

-- luacheck: push no max comment line length
local settings = {
	-- Commented out CVars can be configured in Blizzard nameplate panel.

	-- nameplateShowAll       = 0,
	nameplateShowOnlyNames = 0, -- Whether to hide the nameplate bars

	-- nameplateShowSelf                 = 0,
	NameplatePersonalShowWithTarget = 0, -- Determines if the personal nameplate is shown when selecting a target. 0 = targeting has no effect, 1 = show on hostile target, 2 = show on any target
	NameplatePersonalShowInCombat = 0, -- Determines if the the personal nameplate is shown when you enter combat.
	NameplatePersonalShowAlways = 0, -- Determines if the the personal nameplate is always shown.
	NameplatePersonalClickThrough = 1, -- When enabled, the personal nameplate is transparent to mouse clicks.
	NameplatePersonalHideDelaySeconds = 3.0, -- Determines the length of time in seconds that the personal nameplate will be visible after no visibility conditions are met.
	NameplatePersonalHideDelayAlpha = 0.45, -- Determines the alpha of the personal nameplate after no visibility conditions are met (during the period of time specified by NameplatePersonalHideDelaySeconds).

	-- nameplateShowEnemies        = 1,
	nameplateShowEnemyGuardians = 1,
	-- nameplateShowEnemyMinions   = 1,
	-- nameplateShowEnemyMinus     = 1,
	nameplateShowEnemyPets = 1,
	nameplateShowEnemyTotems = 1,

	-- nameplateShowFriends           = 0,
	nameplateShowDebuffsOnFriendly = 1,
	nameplateShowFriendlyGuardians = 0,
	-- nameplateShowFriendlyMinions   = 0,
	nameplateShowFriendlyNPCs = 0,
	nameplateShowFriendlyPets = 0,
	nameplateShowFriendlyTotems = 0,

	-- NamePlateClassificationScale        = 1.0,  -- Applied to the classification icon for nameplates.
	NamePlateMaximumClassificationScale = 1.25, -- This is the maximum effective scale of the classification icon for nameplates.

	nameplateOccludedAlphaMult = 0.4, -- Alpha multiplier of nameplates for occluded targets.

	nameplateGlobalScale = 1.0, -- Applies global scaling to non-self nameplates, this is applied AFTER selected, min, and max scale.
	nameplateSelfScale = 1.0, -- The scale of the self nameplate.
	nameplateSelectedScale = 1.2, -- The scale of the selected nameplate.
	nameplateLargerScale = 1.2, -- An additional scale modifier for important monsters.
	-- NamePlateHorizontalScale   = 1.0, -- Applied to horizontal size of all nameplates.
	-- NamePlateVerticalScale     = 1.0, -- Applied to vertical size of all nameplates.

	nameplateSelfAlpha = 0.75, -- The alpha of the self nameplate.
	nameplateNotSelectedAlpha = 0.8, -- The alpha of the non-selected nameplate when there is a target.
	nameplateSelectedAlpha = 1.0, -- The alpha of the selected nameplate.

	nameplateMaxAlphaDistance = 40, -- The distance from the camera that nameplates will reach their maximum alpha.
	nameplateMaxAlpha = 1.0, -- The max alpha of nameplates.

	nameplateMaxScaleDistance = 10, -- The distance from the camera that nameplates will reach their maximum scale.
	nameplateMaxScale = 1.0, -- The max scale of nameplates.

	nameplateMinAlphaDistance = 0, -- The distance from the max distance that nameplates will reach their minimum alpha.
	nameplateMinAlpha = 0.5, -- The minimum alpha of nameplates.

	nameplateMinScaleDistance = 0, -- The distance from the max distance that nameplates will reach their minimum scale.
	nameplateMinScale = 0.8, -- The minimum scale of nameplates.

	nameplateMaxDistance = 60,

	-- nameplateMotion            = 0,     -- Defines the movement/collision model for nameplates
	nameplateMotionSpeed = 0.03, -- Controls the rate at which nameplate animates into their target locations [0.0-1.0]
	nameplateOverlapV = 0.7, -- Percentage amount for vertical overlap of nameplates
	nameplateOverlapH = 0.8, -- Percentage amount for horizontal overlap of nameplates

	nameplateOtherAtBase = 0, -- Position other nameplates at the base, rather than overhead

	nameplateSelfTopInset = 0.5, -- The inset from the top (in screen percent) that the self nameplate is clamped to.
	nameplateSelfBottomInset = 0.2, -- The inset from the bottom (in screen percent) that the self nameplate is clamped to.
	nameplateLargeTopInset = 0.1, -- The inset from the top (in screen percent) that large nameplates are clamped to.
	nameplateLargeBottomInset = 0.15, -- The inset from the bottom (in screen percent) that large nameplates are clamped to.
	nameplateOtherTopInset = 0.0, -- The inset from the top (in screen percent) that the non-self nameplates are clamped to.
	nameplateOtherBottomInset = 0.1, -- The inset from the bottom (in screen percent) that the non-self nameplates are clamped to.

	-- nameplateResourceOnTarget      = 0,   -- Nameplate class resource overlay mode. 0=self, 1=target
	nameplateClassResourceTopInset = 0.03, -- The inset from the top (in screen percent) that nameplates are clamped to when class resources are being displayed on them.

	clampTargetNameplateToScreen = 1, -- Clamps the target's nameplate to the edges of the screen, even if the target is off-screen.
	nameplateTargetRadialPosition = 1, -- When target is off screen, position its nameplate radially around sides and bottom. 1: Target Only. 2: All In Combat
	nameplateTargetBehindMaxDistance = 15, -- The max distance to show the target nameplate when the target is behind the camera.
}
-- luacheck: pop

oUF:Factory(function()
	oUF:SetActiveStyle("Adirelle_Nameplate")
	oUF:SpawnNamePlates("oUF_Adirelle_", function()
	end, settings)
end)
