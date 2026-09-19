include( "shared.lua" )

--[[
net.Receive( "TurnSound", function()

	local time = net.ReadUInt( 8 )
	local sound = net.ReadString()

	timer.Create( "NukeTimer", time - 1, 1, function() end)

	surface.PlaySound( sound )

end)]]

net.Receive("AlphaWarheadTimer_CLIENTSIDE", function()
	local time = tonumber(net.ReadString())
	local remove = net.ReadBool()
	if !remove then
		timer.Create("NukeTimer", time - 1, 1, function() end)
	else
		timer.Remove("NukeTimer")
	end
end)

local GOC_NUKE_LOADING_MATERIAL = Material( "nextoren/nuke/nuke_monitor" )
local GOC_NUKE_ACTIVE_MATERIAL = Material( "nextoren/nuke/nuke_redux" )
local GOC_NUKE_RENDER_DISTANCE_SQR = 1000000

function ENT:Draw()
end

hook.Add( "PostDrawOpaqueRenderables", "RXSEND:GocNukeScreens", function()
	local eyePos = EyePos()

	for _, nuke in ipairs( ents.FindByClass( "entity_goc_nuke" ) ) do
		if IsValid( nuke ) and eyePos:DistToSqr( nuke:GetPos() ) <= GOC_NUKE_RENDER_DISTANCE_SQR then
			local material = nuke:GetActivated() and GOC_NUKE_ACTIVE_MATERIAL or GOC_NUKE_LOADING_MATERIAL
			render.SetMaterial( material )

			for _, panel in ipairs( nuke:GetGocNukeScreenPanels() ) do
				-- Draw both faces: the map console is static geometry while this
				-- overlay is an invisible entity, so one-sided rendering can vanish.
				render.DrawQuadEasy( panel.pos + panel.normal * 0.5, panel.normal, panel.width, panel.height, color_white, 0 )
				render.DrawQuadEasy( panel.pos - panel.normal * 0.5, -panel.normal, panel.width, panel.height, color_white, 180 )
			end
		end
	end
end )
