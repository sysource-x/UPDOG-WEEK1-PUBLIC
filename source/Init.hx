package;

import flixel.FlxState;
import flixel.FlxG;
import flixel.input.keyboard.FlxKey;

import lime.app.Application;

class Init extends FlxState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	
	override public function create():Void
	{
		funkin.data.scripts.FunkinIris.InitLogger();
		
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		Paths.pushGlobalMods();
		
		funkin.data.WeekData.loadTheFirstEnabledMod();
		
		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];
		
		FlxG.mouse.visible = false;
		
		funkin.backend.PlayerSettings.init();
		
		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		
		ClientPrefs.loadPrefs();
		
		funkin.data.Highscore.load();
		
		funkin.objects.video.FunkinVideoSprite.init();
		
		FlxG.scaleMode = new funkin.backend.FunkinRatioScaleMode();
		
		if (FlxG.save.data != null && FlxG.save.data.fullscreen) FlxG.fullscreen = FlxG.save.data.fullscreen;
		if (FlxG.save.data.weekCompleted != null) funkin.states.StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		
		FlxG.mouse.visible = false;
		
		// MusicBeatState.transitionInState = funkin.states.transitions.FadeTransition;
		// MusicBeatState.transitionOutState = funkin.states.transitions.FadeTransition;
		
		#if !RELEASE_BUILD
		funkin.plugins.HotReloadPlugin.init();
		funkin.plugins.StateSwitchPlugin.init();
		#end
		
		#if debug
		FlxG.console.registerClass(funkin.data.ClientPrefs);
		FlxG.console.registerClass(funkin.Paths);
		FlxG.console.registerClass(funkin.states.PlayState);
		#end
		
		#if DISCORD_ALLOWED
		if (!DiscordClient.isInitialized)
		{
			DiscordClient.initialize();
			Application.current.onExit.add((ec) -> DiscordClient.shutdown());
		}
		#end
		
		super.create();
		
		FlxG.switchState(() -> new funkin.states.TitleState());
	}
}
