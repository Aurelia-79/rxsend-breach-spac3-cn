local RunConsoleCommand = RunConsoleCommand
local tonumber = tonumber
local math = math

-- 国服适配：注册 !bot / !kickbots 聊天命令（原生 GMod bot 控制台命令）。
-- 原生命令：bot [name]（生成一个假客户端 bot）、bot_kick [name|all]（踢出 bot）。
-- data/ulib/groups.txt 里 superadmin 已允许 "ulx bot"、"ulx kickbots"。
-- 注：ULX 作为 addon 先于 gamemode 加载，此处可直接注册；ulx.command 会去重。

if SERVER and ulx and ulx.command then

	-- !bot           -> 生成 1 个随机名字的 bot
	-- !bot 3         -> 生成 3 个 bot
	-- !bot SomeName  -> 生成 1 个指定名字的 bot
	ulx.command("Utility", "ulx bot", function(calling_ply, arg)
		local n = tonumber(arg)
		if n and n > 0 then
			n = math.Clamp(math.floor(n), 1, 32)
			for i = 1, n do
				RunConsoleCommand("bot")
			end
			ulx.fancyLogAdmin(calling_ply, "#A spawned #i bots", n)
		else
			if arg and arg != "" then
				RunConsoleCommand("bot", arg)
			else
				RunConsoleCommand("bot")
			end
			ulx.fancyLogAdmin(calling_ply, "#A spawned a bot")
		end
	end, "!bot", true)

	-- !kickbots -> 踢出所有 bot
	ulx.command("Utility", "ulx kickbots", function(calling_ply)
		RunConsoleCommand("bot_kick", "all")
		ulx.fancyLogAdmin(calling_ply, "#A kicked all bots")
	end, "!kickbots", true)

end
