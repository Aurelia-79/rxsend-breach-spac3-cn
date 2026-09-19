-- ============================================================================
-- RXSEND 对讲机频道分组
-- ============================================================================
-- 需求：
--   1) MTF（TEAM_NTF）、保安（TEAM_GUARD / TEAM_SECURITY）以及基金会方的所有
--      支援队伍（九尾狐 TEAM_QRT、落锤 TEAM_OSN 等）共用同一个频道。
--   2) 其他"未知单位"（混沌分裂者、GOC、UIU、蛇之手、破晓教团等）每支队伍
--      各自独立一个频道。
--   3) 频道号每局随机。
--
-- 实现要点：
--   * 频道号写在 GlobalInt/GlobalFloat 上，客户端可直接读取，无需额外 net。
--   * item_radio 的频道范围是 100.1 ~ 999.9，步长 0.1，且要求形如 "%d%d%d%.%d"
--     （三位整数 + 一位小数），所以随机值必须落在 100.1..999.9 且只保留一位小数。
--   * 玩家拿到对讲机时自动调到本阵营频道，玩家仍可手动改频（保留原有玩法）。
-- ============================================================================

BREACH = BREACH || {}
BREACH.Radio = BREACH.Radio || {}

-- 频道分组 ID。同一组 ID 的阵营共用一个频道号。
RADIO_GROUP_FOUNDATION = "foundation"

-- 阵营 -> 频道分组 ID
-- 没列进来的阵营（Class-D、科研、SCP、观察者等）不分配频道，
-- 保持对讲机出厂默认值，需要玩家自己手动调频。
BREACH.Radio.TeamGroups = {
	-- 基金会方：MTF + 保安 + 基金会支援队伍，全部共用一个频道
	[TEAM_NTF]      = RADIO_GROUP_FOUNDATION, -- 机动特遣队 MTF
	[TEAM_GUARD]    = RADIO_GROUP_FOUNDATION, -- 设施保安
	[TEAM_SECURITY] = RADIO_GROUP_FOUNDATION, -- 安保部门
	[TEAM_QRT]      = RADIO_GROUP_FOUNDATION, -- 九尾狐 / 快速反应小队
	[TEAM_OSN]      = RADIO_GROUP_FOUNDATION, -- 落锤 / 九尾狐特勤

	-- 未知单位：每支队伍各自独立频道
	[TEAM_CHAOS]    = "chaos",   -- 混沌分裂者
	[TEAM_GOC]      = "goc",     -- 全球超自然联盟
	[TEAM_USA]      = "uiu",     -- UIU 非常事务调查局
	[TEAM_DZ]       = "dz",      -- 蛇之手
	[TEAM_GRU]      = "gru",     -- GRU-P
	[TEAM_COTSK]    = "cotsk",   -- 破晓教团
	[TEAM_NAZI]     = "nazi",
	[TEAM_AMERICA]  = "america",
}

-- 所有需要分配频道的分组（去重后的列表）
BREACH.Radio.Groups = {
	RADIO_GROUP_FOUNDATION,
	"chaos",
	"goc",
	"uiu",
	"dz",
	"gru",
	"cotsk",
	"nazi",
	"america",
}

local function GlobalKey( groupid )
	return "RXSEND_RadioCh_" .. groupid
end

-- 取某个分组的频道号；没有分配过返回 nil
function BREACH.Radio:GetGroupChannel( groupid )
	if not groupid then return nil end
	local ch = GetGlobalFloat( GlobalKey( groupid ), 0 )
	if ch <= 0 then return nil end
	return ch
end

-- 取某个阵营的频道号
function BREACH.Radio:GetTeamChannel( gteam )
	local groupid = BREACH.Radio.TeamGroups[ gteam ]
	if not groupid then return nil end
	return BREACH.Radio:GetGroupChannel( groupid )
end

-- 取玩家所属频道号
function BREACH.Radio:GetPlayerChannel( ply )
	if not IsValid( ply ) or not ply.GTeam then return nil end
	return BREACH.Radio:GetTeamChannel( ply:GTeam() )
end

if SERVER then

	-- 生成一个符合 item_radio 校验规则的随机频道号：
	-- 三位整数部分（100..999）+ 一位小数（.1 .. .9，避开 .0）
	local function RandomChannel()
		local whole = math.random( 100, 999 )
		local frac = math.random( 1, 9 )
		return tonumber( string.format( "%d.%d", whole, frac ) )
	end

	-- 每局随机重新分配所有分组的频道，保证组间不重复
	function BREACH.Radio:Randomize()
		local used = {}

		for _, groupid in ipairs( BREACH.Radio.Groups ) do
			local ch
			-- 最多试 200 次避免极端情况死循环（可用组合有 900*9 = 8100 个，
			-- 组数远小于此，实际一两次就能成功）
			for _ = 1, 200 do
				ch = RandomChannel()
				if not used[ ch ] then break end
			end
			used[ ch ] = true
			SetGlobalFloat( GlobalKey( groupid ), ch )
		end

		print( "[RXSEND] Radio channels randomized: foundation=" ..
			tostring( BREACH.Radio:GetGroupChannel( RADIO_GROUP_FOUNDATION ) ) )
	end

	-- 把玩家手上的对讲机调到本阵营频道
	function BREACH.Radio:ApplyToPlayer( ply )
		if not IsValid( ply ) or not ply:IsPlayer() then return end

		local ch = BREACH.Radio:GetPlayerChannel( ply )
		if not ch then return end

		local radio = ply:GetWeapon( "item_radio" )
		if not IsValid( radio ) then return end

		-- 已经手动调过频就不要覆盖玩家的选择
		if radio.RXSEND_ChannelAssigned then return end
		radio.RXSEND_ChannelAssigned = true

		radio.Channel = ch

		net.Start( "SetFrequency" )
			net.WriteEntity( radio )
			net.WriteFloat( ch )
		net.Send( ply )
	end

	-- 玩家拿到对讲机时自动调频
	hook.Add( "PlayerSwitchWeapon", "RXSEND_RadioAutoChannel", function( ply, old, new )
		if not IsValid( new ) then return end
		if new:GetClass() ~= "item_radio" then return end
		timer.Simple( 0, function() BREACH.Radio:ApplyToPlayer( ply ) end )
	end )

	-- 领取装备后统一刷一遍（角色分配、支援出生、开箱子拿到对讲机都会走到）
	hook.Add( "PlayerLoadout", "RXSEND_RadioAutoChannel_Loadout", function( ply )
		timer.Simple( 0.5, function() BREACH.Radio:ApplyToPlayer( ply ) end )
	end )

end
