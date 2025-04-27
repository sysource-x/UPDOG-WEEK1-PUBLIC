package funkin.plugins;

import funkin.backend.PlayerSettings;
import funkin.states.editors.CharacterEditorState;
import funkin.states.editors.ChartingState;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;

/**
 * Plugin that allows easy access to different states
 * 
 * 
 * press F8 to open debug state
 * 
 */
class StateSwitchPlugin extends FlxBasic
{
	public static function init()
	{
		FlxG.plugins.addPlugin(new StateSwitchPlugin());
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.F8)
		{
			FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
			FlxG.switchState(() -> new DebugState());
		}
	}
}

class DebugState extends FlxState
{
	var cur:FlxText;

	// not ripping apart or adding compile time to this so do it manually
	public var stateList:Array<Class<FlxState>> = [ChartingState, CharacterEditorState, TitleState, StoryMenuState, FreeplayState];

	var curSel:Int = 0;

	override function create()
	{
		super.create();

		cur = new FlxText(0, FlxG.height / 2 - 16, FlxG.width,Type.getClassName(stateList[curSel]), 32);
		add(cur);
		cur.alignment = CENTER;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var tempSel = curSel;

		if (PlayerSettings.player1.controls.UI_LEFT_P || PlayerSettings.player1.controls.UI_RIGHT_P)
			curSel += PlayerSettings.player1.controls.UI_RIGHT_P ? 1 : -1;

		curSel = FlxMath.wrap(curSel, 0, stateList.length - 1);

		if (curSel != tempSel)
		{
			cur.text = Type.getClassName(stateList[curSel]);
		}

		if (PlayerSettings.player1.controls.ACCEPT)
		{
			FlxG.switchState(() -> Type.createInstance(stateList[curSel],[]));
		}
	}
}
