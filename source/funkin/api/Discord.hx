package funkin.api;

import Sys.sleep;
import discord_rpc.DiscordRpc;
import funkin.states.*;
#if LUA_ALLOWED
import llua.Lua;
import llua.State;
#end

class DiscordClient
{
	public static var discordPresences:Array<String> = [
		'Pegging Aren\'t I funny',
		'Pegging Aren\'t I funny 2',
		'The Green Peg from Peggle Song',
		'VS The Orange One',
		'B\'jornin\'',
		'Tickle Party (Freeplay)',
		'Finale (2026 remaster)',
		'Top 5',
		'Impostor Incident',
		'Trolla Baby',
		'Oversight',
		'Dripcore',
		'Monotone Attack 2: "That\'s Right You Have To Play Another Inside Joke Song To 100% The Mod"',
		'Legacy Moogus',
		'Overworld - HP: 400 - Mana: 200',
		'the guy from esculent\'s funeral',
		'DAREDEVIL',
		'Too-Slow',
		'Red vs. Afton',
		'Daddy Queerest',
		'Mongy Monday',
		'Tomongus Tuesday',
		'White Boy Wednesday',
		'Tomongus Tuesday 2: Thursday',
		'TERRARIA IS A BETTER GAME THAN PALWORLD IF YOU\'RE READING THIS AND DISAGREE FUCK YOU',
		'Boing Resussed',
		'Aaaaaaaand it\'s inappropriate',
		'Hopefully a good song',
		'Probably one of the bad songs',
		'Another song with that pizzicato voice. Great.'
	];

	public static var isInitialized:Bool = false;

	public function new()
	{
		trace("Discord Client starting...");
		DiscordRpc.start(
			{
				clientID: "1276234319852994754",
				onReady: onReady,
				onError: onError,
				onDisconnected: onDisconnected
			});
		trace("Discord Client started.");

		while (true)
		{
			DiscordRpc.process();
			sleep(2);
			// trace("Discord Client Update");
		}

		DiscordRpc.shutdown();
	}

	public static function shutdown()
	{
		DiscordRpc.shutdown();
	}

	static function onReady()
	{
		DiscordRpc.presence(
			{
				details: "mod",
				state: null,
				largeImageKey: 'icon',
				largeImageText: "mod"
			});
	}

	static function onError(_code:Int, _message:String)
	{
		trace('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String)
	{
		trace('Disconnected! $_code : $_message');
	}

	public static function initialize()
	{
		var DiscordDaemon = sys.thread.Thread.create(() -> {
			new DiscordClient();
		});
		trace("Discord Client initialized");
		isInitialized = true;
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float)
	{
		var startTimestamp:Float = if (hasStartTimestamp) Date.now().getTime() else 0;

		if (endTimestamp > 0)
		{
			endTimestamp = startTimestamp + endTimestamp;
		}

		DiscordRpc.presence(
			{
				details: details,
				state: state,
				largeImageKey: 'icon',
				largeImageText: "Engine Version: " + Main.NM_VERSION,
				smallImageKey: smallImageKey,
				// Obtained times are in milliseconds so they are divided so Discord can use it
				startTimestamp: Std.int(startTimestamp / 1000),
				endTimestamp: Std.int(endTimestamp / 1000)
			});

		// trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State)
	{
		Lua_helper.add_callback(lua, "changePresence",
			function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float) {
				changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
			});
	}
	#end
}
