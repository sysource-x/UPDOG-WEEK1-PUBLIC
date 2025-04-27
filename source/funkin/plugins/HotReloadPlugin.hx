package funkin.plugins;

import flixel.addons.transition.FlxTransitionableState;

/**
 * Plugin that allows easy state reloading
 * 
 * 
 * press F5 to reload the state
 * 
 * press F6 to reload and refresh memory
 */
class HotReloadPlugin extends FlxBasic
{
	public static function init()
	{
		FlxG.plugins.addPlugin(new HotReloadPlugin());
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (FlxG.keys.justPressed.F5)
		{
			FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
		
		if (FlxG.keys.justPressed.F6)
		{
			FlxG.signals.preStateCreate.addOnce((state) -> {
				Paths.clearStoredMemory();
				Paths.clearUnusedMemory();
			});
			FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
		}
	}
}
