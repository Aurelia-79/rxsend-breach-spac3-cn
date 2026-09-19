include("shared.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

util.AddNetworkString("AlphaWarheadTimer_CLIENTSIDE")

function ENT:Initialize()
	self:SetModel( self.GocNukeConsoleModel )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_NONE )
	self:SetCollisionGroup( COLLISION_GROUP_IN_VEHICLE )
	self:SetNoDraw( true )
end

function ENT:PlaySound(snd)
	local filt = RecipientFilter()
	filt:AddAllPlayers()

	self.NukeSound = CreateSound(game.GetWorld(), snd, filt)
	self.NukeSound:ChangeVolume(2)
	self.NukeSound:SetSoundLevel(0)

	self.NukeSound:Play()
end

local GOC_NUKE_SCREEN_USE_DISTANCE_SQR = 22500
local GOC_NUKE_SCREEN_TRACE_TOLERANCE_SQR = 256
local GOC_NUKE_CONSOLE_TRACE_RADIUS_SQR = 22500

local function IsGocNukeOperator( ply )
	if !IsValid( ply ) or !ply:IsPlayer() then return false end

	return ply:GTeam() == TEAM_GOC or ply:GetRoleName() == role.ClassD_GOCSpy
end

local function IsAimingAtGocNukeScreen( ply, nuke )
	local eyePos = ply:EyePos()
	local trace = ply:GetEyeTrace()
	if trace.Hit and eyePos:DistToSqr( trace.HitPos ) <= GOC_NUKE_SCREEN_USE_DISTANCE_SQR
		and nuke:IsGocNukeScreenHit( trace.HitPos ) then
		return true
	end

	-- Some map props do not always return the same trace triangle on the server.
	-- Fall back to the exact screen plane, while still requiring an unobstructed
	-- server-side line of sight to the console.
	local aimVector = ply:GetAimVector()
	for _, panel in ipairs( nuke:GetGocNukeScreenPanels() ) do
		local planeDot = aimVector:Dot( panel.normal )
		if math.abs( planeDot ) > 0.01 then
			local distance = ( panel.pos - eyePos ):Dot( panel.normal ) / planeDot
			if distance > 0 and distance * distance <= GOC_NUKE_SCREEN_USE_DISTANCE_SQR then
				local hitPos = eyePos + aimVector * distance
				if nuke:IsGocNukeScreenHit( hitPos ) then
					local traceOffset = planeDot < 0 and -panel.normal * 8 or panel.normal * 8
					local sightTrace = util.TraceLine( {
						start = eyePos,
						endpos = hitPos + traceOffset,
						filter = ply,
						mask = MASK_SOLID,
					} )

					if !sightTrace.Hit or sightTrace.HitPos:DistToSqr( hitPos ) <= GOC_NUKE_SCREEN_TRACE_TOLERANCE_SQR then
						return true
					end
				end
			end
		end
	end

	-- The console itself is a map prop and its server trace mesh does not always
	-- line up with the visual screen overlay.  A GOC operator looking at that
	-- same console from use range must still be able to activate the warhead.
	return trace.Hit
		and eyePos:DistToSqr( trace.HitPos ) <= GOC_NUKE_SCREEN_USE_DISTANCE_SQR
		and trace.HitPos:DistToSqr( nuke:GetPos() ) <= GOC_NUKE_CONSOLE_TRACE_RADIUS_SQR
end

hook.Add( "KeyPress", "RXSEND:GocNukeFallbackUse", function( ply, key )
	if key != IN_USE then return end
	if !ply:Alive() or ply:Health() <= 0 then return end

	for _, nuke in ipairs( ents.FindByClass( "entity_goc_nuke" ) ) do
		if IsValid( nuke ) and IsAimingAtGocNukeScreen( ply, nuke ) then
			nuke:Use( ply, ply )
			return
		end
	end
end )

function ENT:Use(activator, caller)
	if !IsValid( activator ) or !activator:IsPlayer() then return end
	if preparing then return end
	if postround then return end
	if self.RXSENDNextUse and self.RXSENDNextUse > CurTime() then return end
	self.RXSENDNextUse = CurTime() + 0.35

	Additionaltime = Additionaltime || 0

	if IsGocNukeOperator( activator ) then
		if self:GetActivated() or timer.Exists( "AlphaWarhead_Start" ) or timer.Exists( "AlphaWarhead_Begin" ) then return end

		if isfunction(StopAlphaWarhead) then StopAlphaWarhead() end
		for i, v in pairs(player.GetAll()) do
			if v:GTeam() == TEAM_GOC then
				v:AddToStatistics("l:activated_warhead", 100 )
			end
		end
		hook.Run("BreachLog_EnableGocNuke", activator)
		--Additionaltime = Additionaltime + 90
		--roundEnd = roundEnd + 90
		self:SetActivated(true)
		self.activator = activator
		--[[
		net.Start("UpdateTime")
		net.WriteString(GetRoundTime() + Additionaltime)
		net.Broadcast()]]
		--net.Start("ForcePlaySound")
		self:PlaySound("nextoren/sl/warheadcrank.ogg")
		--net.Broadcast()

		if self:GetDeactivationTime() == 0 and !GetGlobalBool("Evacuation", false) and !GetGlobalBool("Evacuation_HUD", false) then
			BroadcastPlayMusic(BR_MUSIC_GOC_NUKE)
		end

		timer.Pause("RoundTime")
		timer.Pause("Evacuation")
		timer.Pause("EvacuationWarhead")
		timer.Pause("EndRound_Timer")

		Shaky = Shaky || {}
		Shaky.RoundStats = Shaky.RoundStats || {}
		Shaky.RoundStats.ActivatedTimes = ( Shaky.RoundStats.ActivatedTimes || 0 ) + 1

		SetGlobalBool( "NukeTime", true )

		timer.Create("AlphaWarhead_Start", 12, 1, function()
			local tim = self:GetDeactivationTime()
			local domus = true
			if tim == 0 then
				
				
				self:PlaySound("nextoren/round_sounds/main_decont/final_nuke.mp3")
				self:SetDeactivationTime(133)

			elseif tim > 70 and tim <= 80 then
				self:PlaySound("nextoren/sl/Resume80.ogg")
				self:SetDeactivationTime(80)
			elseif tim > 60 and tim <= 70 then
				self:PlaySound("nextoren/sl/Resume70.ogg")
				self:SetDeactivationTime(70)
			elseif tim > 50 and tim <= 60 then
				self:PlaySound("nextoren/sl/Resume60.ogg")
				self:SetDeactivationTime(60)
			elseif tim > 40 and tim <= 50 then
				self:PlaySound("nextoren/sl/Resume50.ogg")
				self:SetDeactivationTime(50)
			elseif tim > 30 and tim <= 40 then
				self:PlaySound("nextoren/sl/Resume40.ogg")
				self:SetDeactivationTime(40)
			elseif tim <= 30 then
				self:PlaySound("nextoren/sl/Resume30.ogg")
				self:SetDeactivationTime(30)
			else
				self:PlaySound("nextoren/sl/Resume90.ogg")
				self:SetDeactivationTime(90)
			end
			SetGlobalBool( "NukeTime", true )
			SetGlobalBool( "Evacuation_HUD", true )
			self.RXSENDStartedEvacuation = false
			self.RXSENDGocEvacuationVehicles = false
			-- GOC 核弹流程：只生成撤离载具，不播放撤离音乐（保持 BR_MUSIC_GOC_NUKE）
			if isfunction( EvacuationWarhead ) then
				self.RXSENDGocEvacuationVehicles = EvacuationWarhead( true, self:GetDeactivationTime() ) == true
			end
			for _, ply in pairs(player.GetAll()) do ply:BrTip(0, "[RX Breach]", Color(255,0,0,200), "l:goc_nuke_start", color_white) end
			timer.Create("GOC_EVACUATION_SEQUENCE", self:GetDeactivationTime() - 6, 1, function()
				if timer.Exists("AlphaWarhead_Begin") then
					if isfunction(goose_plz_fuck_off_goc) then goose_plz_fuck_off_goc() end
					for i, v in pairs(player.GetAll()) do
						if v:GTeam() == TEAM_GOC or v:GTeam() == TEAM_GOC_CONTAIN then
							ParticleEffectAttach("mr_portal_1a_ff", PATTACH_POINT_FOLLOW, v, v:LookupAttachment("waist"))
							timer.Simple(2.6, function()
								if IsValid(v) and ( v:GTeam() == TEAM_GOC or v:GTeam() == TEAM_GOC_CONTAIN ) and v:Alive() then
									net.Start("ThirdPersonCutscene")
									net.WriteUInt(3, 4)
									net.WriteBool(true)
									net.Send(v)
									v:SetForcedAnimation("MPF_Deploy", 2, function() ParticleEffectAttach("mr_portal_1a", PATTACH_POINT_FOLLOW, v, v:LookupAttachment("waist")) v:EmitSound("nextoren/others/introfirstshockwave.wav", 115, 100, 1.4) v:GodEnable() end, function()
										v:GodDisable()
										v:AddToStatistics("l:escaped", 560 * tonumber("1."..tostring(v:GetNLevel() * 2)) )
										v:LevelBar()
										v:SetupNormal()
										v:SetSpectator()
										--v:RXSENDNotify("l:your_current_exp ", Color(255,0,0), v:GetNEXP())
									end, nil)
								end
							end)
						end
					end
				end
			end)
			timer.Create("AlphaWarhead_Begin", self:GetDeactivationTime(), 1, function()
				for i, v in pairs(player.GetAll()) do
					if v:GTeam() != TEAM_SPEC && v:Alive() && v:Health() > 0 && v:GTeam() != TEAM_GOC then
						v:AddToStatistics("l:detonated_warhead_for_non_goc", -100)
						--v:LevelBar()
						v:ScreenFade(SCREENFADE.IN, color_black, 1, 1)
						timer.Simple(1, function()
							if IsValid(v) && v:GTeam() != TEAM_SPEC && v:Alive() && v:Health() > 0 && v:GTeam() != TEAM_GOC then
								v:LevelBar()
								v:SetupNormal()
								v:SetSpectator()
							end
						end)
					end
				end

				--[[
				endround = true
				why = " Alpha WarHead has exploded"
				gamestarted = false
				BroadcastLua( "gamestarted = false" )]]

				hook.Run("BreachLog_GocNukeDetonation")
				AlphaWarheadBoomEffect()
				net.Start("AlphaWarheadTimer_CLIENTSIDE")
				net.WriteString("")
				net.WriteBool(true)
				net.Broadcast()
				SetGlobalBool("NukeTime", false)
				if IsValid(self.activator) then self.activator:CompleteAchievement("bigboom") end
				Breach_EndRound("l:roundend_GOCNUKE")
			end)

			net.Start("AlphaWarheadTimer_CLIENTSIDE")
			net.WriteString(tostring(math.floor(timer.TimeLeft("AlphaWarhead_Begin"))))
			net.WriteBool(false)
			net.Broadcast()

		end)

	elseif self:GetActivated() and !IsGocNukeOperator( activator ) and self:GetDeactivationTime() > 22 then
		hook.Run("BreachLog_DisableGocNuke", activator)
		for i, v in pairs(ents.FindByClass("alphawarhead_monitor")) do
			if IsValid(v) then v:Remove() end
		end
		SetGlobalBool( "NukeTime", false )
		SetGlobalBool( "Evacuation_HUD", false )
		timer.Remove("AlphaWarhead_Begin")
		timer.Remove("AlphaWarhead_Start") -- ?
		timer.Remove("GOC_EVACUATION_SEQUENCE")
		if self.RXSENDGocEvacuationVehicles and isfunction( RXSENDCancelGocEvacuationVehicles ) then
			RXSENDCancelGocEvacuationVehicles()
		end
		if self.RXSENDStartedEvacuation then
			SetGlobalBool( "Evacuation", false )
		end
		self.RXSENDGocEvacuationVehicles = false
		self.RXSENDStartedEvacuation = false

		timer.UnPause("RoundTime")
		timer.UnPause("Evacuation")
		timer.UnPause("EvacuationWarhead")
		timer.UnPause("EndRound_Timer")

		self:SetActivated(false)

		--BroadcastLua("RunConsoleCommand(\"stopsound\")")
		net.Start("AlphaWarheadTimer_CLIENTSIDE")
		net.WriteString("")
		net.WriteBool(true)
		net.Broadcast()

		BroadcastLua("cltime = "..tostring(timer.TimeLeft("RoundTime")))

		if GetGlobalBool( "Evacuation", false ) then
			BroadcastPlayMusic( BR_MUSIC_EVACUATION )
		else
			BroadcastStopMusic()
		end
		self.NukeSound:Stop()
		--timer.Simple(0.3, function()
			net.Start("ForcePlaySound")
			net.WriteString("nextoren/round_sounds/intercom/goc_nuke_cancel.mp3")
			net.Broadcast()
		--end)

	end

end

local checkcd = checkcd || 0
function ENT:Think()

	if checkcd > CurTime() then return end
	checkcd = CurTime() + 1

	if timer.Exists("AlphaWarhead_Begin") then
		self:SetDeactivationTime(math.floor(timer.TimeLeft("AlphaWarhead_Begin")))
	end

end
