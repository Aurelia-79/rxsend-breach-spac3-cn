ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName		= "Alpha Warhead"
ENT.Information		= ""
ENT.Category		= "Breach"
ENT.Type = "anim"
ENT.Editable		= false
ENT.Spawnable		= true
ENT.AdminOnly		= false
ENT.TurningOn = false
ENT.ExplosionTime = 120
ENT.GocNukeConsoleModel = "models/noundation/electronics/consolenuke.mdl"

-- These are the two recessed black displays beneath the SCP logo on the
-- map's console model. They are model-space coordinates, not OBB estimates.
local GOC_NUKE_SCREENS = {
	{ localPos = Vector( -63.145, -14, 13 ), width = 25.71, height = 22 },
	{ localPos = Vector( -24.855, -14, 13 ), width = 25.71, height = 22 },
}
local GOC_NUKE_SCREEN_PLANE_TOLERANCE = 4

function ENT:GetGocNukeScreenPanels()
	local panels = {}

	for _, screen in ipairs( GOC_NUKE_SCREENS ) do
		panels[#panels + 1] = {
			pos = self:LocalToWorld( screen.localPos ),
			localPos = screen.localPos,
			-- The displays are on the negative local-Y face of the console.
			normal = -self:GetRight(),
			width = screen.width,
			height = screen.height,
			planeTolerance = GOC_NUKE_SCREEN_PLANE_TOLERANCE,
		}
	end

	return panels
end

function ENT:IsGocNukeScreenHit( worldPos )
	if not isvector( worldPos ) then return false end

	local localPos = self:WorldToLocal( worldPos )
	for _, panel in ipairs( self:GetGocNukeScreenPanels() ) do
		if math.abs( localPos.y - panel.localPos.y ) <= panel.planeTolerance
			and math.abs( localPos.x - panel.localPos.x ) <= panel.width * 0.5
			and math.abs( localPos.z - panel.localPos.z ) <= panel.height * 0.5 then
			return true
		end
	end

	return false
end

function ENT:SetupDataTables()

  self:NetworkVar( "Bool", 0, "Activated" )
  self:NetworkVar( "Int", 0, "DeactivationTime" )

  self:SetDeactivationTime(0)

end

net.Receive( "NukeStart", function()

  local nuke = net.ReadBool()
  SetGlobalBool( "NukeTime", nuke )

end )

BREACH.TimeDecision = {

	{ sound = "nextoren/sl/Resume90.ogg", time = 90, triggertime = 90 },
	{ sound = "nextoren/sl/Resume80.ogg", time = 80, triggertime = 80 },
	{ sound = "nextoren/sl/Resume70.ogg", time = 70, triggertime = 70 },
	{ sound = "nextoren/sl/Resume60.ogg", time = 60, triggertime = 60 },
	{ sound = "nextoren/sl/Resume50.ogg", time = 50, triggertime = 50 },
	{ sound = "nextoren/sl/Resume40.ogg", time = 40, triggertime = 40 },
	{ sound = "nextoren/sl/Resume30.ogg", time = 30, triggertime = 0 }

}
