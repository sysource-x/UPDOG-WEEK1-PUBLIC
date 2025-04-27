package;

import funkin.backend.DebugDisplay;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;

class Main extends Sprite
{
	public static final PSYCH_VERSION:String = '0.5.2h';
	public static final NM_VERSION:String = '0.2';
	public static final FUNKIN_VERSION:String = '0.2.7';

	public static final startMeta = {
		width: 1280,
		height: 720,
		initialState: Init,
		skipSplash: false,
		startFullScreen: false,
		fps: 60
	};

	// You can pretty much ignore everything from here on - your code should go in your states.
	public static var fpsVar:DebugDisplay;

	static function __init__()
	{
		funkin.utils.MacroUtil.haxeVersionEnforcement();
	}

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		ClientPrefs.loadDefaultKeys();

		final game = new
			#if CRASH_HANDLER
			FNFGame
			#else
			FlxGame
			#end(startMeta.width, startMeta.height, #if !debug Splash #else startMeta.initialState #end, startMeta.fps, startMeta.fps, startMeta.skipSplash,
				startMeta.startFullScreen);

		// FlxG.game._customSoundTray wants just the class, it calls new from
		// create() in there, which gets called when it's added to stage
		// which is why it needs to be added before addChild(game) here

		// Also btw game has to be a variable for this to work ig - Orbyy

		@:privateAccess
		game._customSoundTray = funkin.objects.FunkinSoundTray;
		addChild(game);

		#if !mobile
		fpsVar = new DebugDisplay(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		if (fpsVar != null)
		{
			fpsVar.visible = ClientPrefs.showFPS;
		}
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.signals.gameResized.add(onResize);

		#if DISABLE_TRACES
		haxe.Log.trace = (v:Dynamic, ?infos:haxe.PosInfos) -> {}
		#end
	}

	static function onResize(w:Int, h:Int)
	{
		final scale:Float = Math.max(1, Math.min(w / FlxG.width, h / FlxG.height));
		if (fpsVar != null)
		{
			fpsVar.scaleX = fpsVar.scaleY = scale;
		}

		if (FlxG.cameras != null)
			for (i in FlxG.cameras.list)
			{
				if (i != null && i.filters != null)
					resetSpriteCache(i.flashSprite);
			}

		if (FlxG.game != null)
		{
			resetSpriteCache(FlxG.game);
		}
	}

	public static function resetSpriteCache(sprite:Sprite):Void
	{
		@:privateAccess
		{
			sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}
}

#if CRASH_HANDLER
class FNFGame extends FlxGame
{
	private static function crashGame()
	{
		null
		.draw();
	}

	/**
	 * Used to instantiate the guts of the flixel game object once we have a valid reference to the root.
	 */
	override function create(_):Void
	{
		try
		{
			_skipSplash = true;
			super.create(_);
		}
		catch (e)
		{
			onCrash(e);
		}
	}

	override function onFocus(_):Void
	{
		try
		{
			super.onFocus(_);
		}
		catch (e)
		{
			onCrash(e);
		}
	}

	override function onFocusLost(_):Void
	{
		try
		{
			super.onFocusLost(_);
		}
		catch (e)
		{
			onCrash(e);
		}
	}

	/**
	 * Handles the `onEnterFrame` call and figures out how many updates and draw calls to do.
	 */
	override function onEnterFrame(_):Void
	{
		try
		{
			super.onEnterFrame(_);
		}
		catch (e)
		{
			onCrash(e);
		}
	}

	/**
	 * This function is called by `step()` and updates the actual game state.
	 * May be called multiple times per "frame" or draw call.
	 */
	override function update():Void
	{
		#if CRASH_TEST
		if (FlxG.keys.justPressed.F9)
			crashGame();
		#end
		try
		{
			super.update();
		}
		catch (e)
		{
			onCrash(e);
		}
	}

	/**
	 * Goes through the game state and draws all the game objects and special effects.
	 */
	override function draw():Void
	{
		try
		{
			super.draw();
		}
		catch (e)
		{
			onCrash(e);
		}
	}

	private final function onCrash(e:haxe.Exception):Void
	{
		var emsg:String = "";
		for (stackItem in haxe.CallStack.exceptionStack(true))
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					emsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
					trace(stackItem);
			}
		}

		final crashReport = 'Error caught:' + e.message + '\nCallstack:\n' + emsg;

		FlxG.switchState(new funkin.backend.FallbackState(crashReport, () -> FlxG.switchState(() -> new TitleState())));
	}
}
#end
