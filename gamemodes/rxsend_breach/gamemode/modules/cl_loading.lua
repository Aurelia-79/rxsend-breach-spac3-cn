-- ============================================================
--  国服适配：进服加载画面
--  玩家客户端加载完成后、主菜单出现前显示。
--  全部为纯代码绘制，不引用任何 .vmt/.png 材质，
--  因此不存在材质缺失导致白屏/黑屏的风险。
-- ============================================================

if CLIENT then

	--------------------------------------------------------
	-- 缩放与字体（按 1080p 为基准等比缩放，兼容 2K/4K）
	--------------------------------------------------------
	local S = math.Clamp( ScrH() / 1080, 0.55, 2.2 )

	local function F( n ) return math.max( 8, math.floor( n * S ) ) end

	surface.CreateFont( "RXSEND_Load_Title", {
		font = "Microsoft YaHei", size = F( 58 ), weight = 800,
		antialias = true, extended = true,
	} )
	surface.CreateFont( "RXSEND_Load_Brand", {
		font = "Microsoft YaHei", size = F( 15 ), weight = 600,
		antialias = true, extended = true,
	} )
	surface.CreateFont( "RXSEND_Load_Sub", {
		font = "Microsoft YaHei", size = F( 21 ), weight = 500,
		antialias = true, extended = true,
	} )
	surface.CreateFont( "RXSEND_Load_Small", {
		font = "Microsoft YaHei", size = F( 15 ), weight = 400,
		antialias = true, extended = true,
	} )

	--------------------------------------------------------
	-- 配色
	--------------------------------------------------------
	local BG_TOP   = { r = 14, g = 16, b = 23 }
	local BG_BOT   = { r = 5,  g = 6,  b = 9  }
	local ACCENT_R, ACCENT_G, ACCENT_B = 198, 46, 46

	--------------------------------------------------------
	-- 绘制工具
	--------------------------------------------------------

	-- 竖向渐变（切片实现，不依赖 gui/gradient 材质）
	local function VGradient( x, y, w, h, top, bot, alpha, steps )
		steps = steps or 40
		local sh = h / steps
		for i = 0, steps - 1 do
			local f = i / ( steps - 1 )
			surface.SetDrawColor(
				top.r + ( bot.r - top.r ) * f,
				top.g + ( bot.g - top.g ) * f,
				top.b + ( bot.b - top.b ) * f,
				alpha
			)
			surface.DrawRect( x, y + i * sh, w, sh + 1 )
		end
	end

	-- 四边暗角，让中心内容更聚焦
	local function Vignette( w, h, alpha, steps )
		steps = steps or 26
		local bandH = h * 0.34
		local bandW = w * 0.26
		local sh, sw = bandH / steps, bandW / steps
		for i = 0, steps - 1 do
			local f = 1 - ( i / ( steps - 1 ) )
			local a = alpha * f * f
			surface.SetDrawColor( 0, 0, 0, a )
			surface.DrawRect( 0, i * sh, w, sh + 1 )                    -- 上
			surface.DrawRect( 0, h - ( i + 1 ) * sh, w, sh + 1 )        -- 下
			surface.DrawRect( i * sw, 0, sw + 1, h )                    -- 左
			surface.DrawRect( w - ( i + 1 ) * sw, 0, sw + 1, h )        -- 右
		end
	end

	-- 环形圆弧：预分配顶点表，避免每帧产生 GC 垃圾
	local polyBuf = { {}, {}, {}, {} }

	local function Arc( cx, cy, rOut, rIn, a0, a1, segs, r, g, b, alpha )
		if alpha <= 1 then return end
		draw.NoTexture()
		surface.SetDrawColor( r, g, b, alpha )
		local step = ( a1 - a0 ) / segs
		local v1, v2, v3, v4 = polyBuf[ 1 ], polyBuf[ 2 ], polyBuf[ 3 ], polyBuf[ 4 ]
		for i = 0, segs - 1 do
			local s = a0 + step * i
			local e = s + step
			local cs, ss = math.cos( s ), math.sin( s )
			local ce, se = math.cos( e ), math.sin( e )
			v1.x, v1.y = cx + cs * rIn,  cy + ss * rIn
			v2.x, v2.y = cx + cs * rOut, cy + ss * rOut
			v3.x, v3.y = cx + ce * rOut, cy + se * rOut
			v4.x, v4.y = cx + ce * rIn,  cy + se * rIn
			surface.DrawPoly( polyBuf )
		end
	end

	-- 直角装饰角标
	local function Corner( x, y, len, th, dx, dy, r, g, b, alpha )
		surface.SetDrawColor( r, g, b, alpha )
		surface.DrawRect( dx > 0 and x or x - len, y, len, th )
		surface.DrawRect( x - ( dx > 0 and 0 or th ), dy > 0 and y or y - len, th, len )
	end

	-- 带柔边的文字发光
	local function GlowText( text, font, x, y, r, g, b, alpha, spread )
		for i = spread, 1, -1 do
			local a = alpha * 0.055 * ( 1 - ( i - 1 ) / spread )
			draw.SimpleText( text, font, x, y, Color( r, g, b, a ),
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( text, font, x + i, y, Color( r, g, b, a ),
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( text, font, x - i, y, Color( r, g, b, a ),
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
	end

	--------------------------------------------------------
	-- 轮换提示语
	--------------------------------------------------------
	local TIPS = {
		"按 F1 查看当前角色的目标与能力",
		"收容失效时，D 级人员的首要任务是逃离设施",
		"研究员可以用门禁卡开启对应等级的区域",
		"SCP-173 在被注视时无法移动，注意眨眼",
		"机动特遣队的职责是重新收容，而非清除所有人",
		"背包里的物品可以拖动整理，右键查看说明",
	}

	--------------------------------------------------------
	-- 面板
	--------------------------------------------------------
	local loading, startTime, fadeStart = nil, 0, nil
	local FADE_TIME = 0.7

	local function FadeOut()
		if fadeStart then return end
		if !IsValid( loading ) then return end
		fadeStart = RealTime()
		timer.Simple( FADE_TIME + 0.05, function()
			if IsValid( loading ) then loading:Remove() end
			loading = nil
		end )
	end

	local function Spawn()
		if IsValid( loading ) then return end

		loading = vgui.Create( "DPanel" )
		loading:SetPos( 0, 0 )
		loading:SetSize( ScrW(), ScrH() )
		loading:SetZPos( 32767 )
		loading:SetMouseInputEnabled( false )
		loading:SetKeyboardInputEnabled( false )
		startTime = RealTime()

		loading.Paint = function( self, w, h )
			local t  = RealTime() - startTime

			-- 自行管理淡入淡出，不依赖 Panel:SetAlpha 对自定义 Paint 的行为
			local fin  = math.Clamp( t / 0.45, 0, 1 )
			local fout = fadeStart and ( 1 - math.Clamp( ( RealTime() - fadeStart ) / FADE_TIME, 0, 1 ) ) or 1
			local A    = fin * fout
			if A <= 0.002 then return end

			local cx = w * 0.5
			local cy = h * 0.455

			----------------------------------------------------
			-- 背景
			----------------------------------------------------
			VGradient( 0, 0, w, h, BG_TOP, BG_BOT, 255 )

			-- 顶部极淡的暖光，避免整屏死黑
			VGradient( 0, 0, w, h * 0.5,
				{ r = ACCENT_R, g = ACCENT_G, b = ACCENT_B }, BG_TOP, 12 * A, 22 )

			Vignette( w, h, 165, 22 )

			----------------------------------------------------
			-- 旋转收容环
			----------------------------------------------------
			local ry   = cy - 122 * S
			local rOut = 47 * S
			local th   = 3 * S

			-- 外圈底环
			Arc( cx, ry, rOut, rOut - th, 0, math.pi * 2, 46, 78, 82, 96, 190 * A )

			-- 顺时针高亮弧
			local a0 = t * 1.35
			Arc( cx, ry, rOut, rOut - th, a0, a0 + math.pi * 0.42, 16,
				ACCENT_R, ACCENT_G, ACCENT_B, 255 * A )
			Arc( cx, ry, rOut, rOut - th, a0 + math.pi, a0 + math.pi * 1.42, 16,
				ACCENT_R, ACCENT_G, ACCENT_B, 150 * A )

			-- 内圈逆时针细弧
			local rIn2 = rOut - 11 * S
			local a1 = -t * 0.95
			Arc( cx, ry, rIn2, rIn2 - 1.6 * S, a1, a1 + math.pi * 0.68, 20,
				150, 158, 178, 130 * A )

			-- 中心呼吸点
			local pulse = 0.5 + 0.5 * math.sin( t * 2.4 )
			Arc( cx, ry, ( 5.5 + pulse * 2.2 ) * S, 0, 0, math.pi * 2, 18,
				ACCENT_R, ACCENT_G, ACCENT_B, ( 120 + 110 * pulse ) * A )

			----------------------------------------------------
			-- 标题
			----------------------------------------------------
			draw.SimpleText( "S C P   F O U N D A T I O N", "RXSEND_Load_Brand",
				cx, cy - 56 * S, Color( 132, 138, 156, 205 * A ),
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			GlowText( "RXSEND BREACH", "RXSEND_Load_Title", cx, cy - 14 * S,
				ACCENT_R, ACCENT_G, ACCENT_B, 255 * A, 5 )
			draw.SimpleText( "RXSEND BREACH", "RXSEND_Load_Title",
				cx, cy - 14 * S, Color( 244, 246, 250, 255 * A ),
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			----------------------------------------------------
			-- 分隔线 + 中心菱形
			----------------------------------------------------
			local dy = cy + 26 * S
			local dw = 150 * S
			for i = 0, 1 do
				local sign = i == 0 and -1 or 1
				local steps = 20
				for k = 0, steps - 1 do
					local f = k / ( steps - 1 )
					surface.SetDrawColor( 120, 126, 145, ( 1 - f ) * 150 * A )
					local segw = dw / steps
					surface.DrawRect( cx + sign * ( 13 * S + k * segw ) - ( sign < 0 and segw or 0 ),
						dy, segw + 1, 1 )
				end
			end
			draw.NoTexture()
			surface.SetDrawColor( ACCENT_R, ACCENT_G, ACCENT_B, 235 * A )
			local d = 4.5 * S
			surface.DrawPoly( {
				{ x = cx,     y = dy - d + 0.5 },
				{ x = cx + d, y = dy + 0.5 },
				{ x = cx,     y = dy + d + 0.5 },
				{ x = cx - d, y = dy + 0.5 },
			} )

			----------------------------------------------------
			-- 状态文字
			----------------------------------------------------
			local dots = string.rep( "·", 1 + math.floor( RealTime() * 2.6 ) % 3 )
			draw.SimpleText( "正在进入服务器 " .. dots, "RXSEND_Load_Sub",
				cx, cy + 62 * S, Color( 208, 212, 224, 245 * A ),
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			----------------------------------------------------
			-- 流光进度条（单向循环，不再来回摆动）
			----------------------------------------------------
			local bw = math.min( w * 0.30, 460 * S )
			local bh = math.max( 3, 4 * S )
			local bx = cx - bw * 0.5
			local by = cy + 98 * S

			surface.SetDrawColor( 32, 35, 44, 235 * A )
			surface.DrawRect( bx, by, bw, bh )

			-- 高亮段自左向右循环推进，两端带柔化
			local segW  = bw * 0.30
			local travel = bw + segW
			local head  = ( ( t * 0.62 ) % 1 ) * travel - segW
			local slices = 26
			local sw = segW / slices
			for i = 0, slices - 1 do
				local f = i / ( slices - 1 )
				-- 前端亮、尾端淡
				local a = math.sin( f * math.pi ) * 255 * A
				local sx = head + i * sw
				if sx + sw > bx and sx < bx + bw then
					local dx0 = math.max( sx, bx )
					local dx1 = math.min( sx + sw, bx + bw )
					surface.SetDrawColor( ACCENT_R, ACCENT_G + 18, ACCENT_B + 18, a )
					surface.DrawRect( dx0, by, dx1 - dx0 + 0.5, bh )
				end
			end

			-- 进度条上下细边
			surface.SetDrawColor( 96, 100, 118, 90 * A )
			surface.DrawRect( bx, by - 1, bw, 1 )
			surface.DrawRect( bx, by + bh, bw, 1 )

			----------------------------------------------------
			-- 轮换提示
			----------------------------------------------------
			local idx = ( math.floor( t / 4 ) % #TIPS ) + 1
			-- 每条提示自身淡入淡出，切换不生硬
			local phase = ( t % 4 ) / 4
			local ta = math.min( math.Clamp( phase / 0.14, 0, 1 ),
			                     math.Clamp( ( 1 - phase ) / 0.14, 0, 1 ) )
			draw.SimpleText( "提示：" .. TIPS[ idx ], "RXSEND_Load_Small",
				cx, cy + 146 * S, Color( 138, 144, 162, 210 * A * ta ),
				TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

			----------------------------------------------------
			-- 中心内容区角标
			----------------------------------------------------
			local bxw = math.min( w * 0.40, 620 * S )
			local bxh = 330 * S
			local l, r = cx - bxw * 0.5, cx + bxw * 0.5
			local tp, bt = cy - 150 * S, cy - 150 * S + bxh
			local cl, ct = 26 * S, math.max( 1, 2 * S )
			local ca = 120 * A
			Corner( l, tp,  cl, ct,  1,  1, 150, 156, 172, ca )
			Corner( r, tp,  cl, ct, -1,  1, 150, 156, 172, ca )
			Corner( l, bt,  cl, ct,  1, -1, 150, 156, 172, ca )
			Corner( r, bt,  cl, ct, -1, -1, 150, 156, 172, ca )

			----------------------------------------------------
			-- 底部信息
			----------------------------------------------------
			local pad = 26 * S
			draw.SimpleText( "地图  " .. game.GetMap(), "RXSEND_Load_Small",
				pad, h - pad, Color( 92, 97, 112, 190 * A ),
				TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM )
			draw.SimpleText( "SITE-19  ·  CN", "RXSEND_Load_Small",
				w - pad, h - pad, Color( 92, 97, 112, 190 * A ),
				TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM )
		end
	end

	Spawn()

	-- 主菜单就绪后淡出（保证至少显示约 1.8 秒，避免一闪而过）
	hook.Add( "InitPostEntity", "RXSEND_Loading_Fade", function()
		local elapsed = RealTime() - startTime
		timer.Simple( math.max( 0.6, 1.8 - elapsed ), FadeOut )
	end )

	-- 保险：最多 20 秒强制淡出
	timer.Simple( 20, FadeOut )

end
