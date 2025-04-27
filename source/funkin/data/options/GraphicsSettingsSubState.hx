package funkin.data.options;

import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class GraphicsSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Graphics';
		rpcTitle = 'Graphics Settings Menu'; // for Discord Rich Presence
		
		var option:Option = new Option('Anti-Aliasing', 'Makes everything pretty\nDisable this for better performance', 'globalAntialiasing', 'bool', true);
		option.showBoyfriend = true;
		option.onChange = onChangeAntiAliasing; // Changing onChange is only needed if you want to make a special interaction after it changes the value
		addOption(option);

		var option:Option = new Option('Low Quality', // Name
			'Disables background details, improves performance', // Description
			'lowQuality', // Save data variable name
			'bool', // Variable type
			false); // Default value
		addOption(option);
		
		var option:Option = new Option('Flashing Lights', "Enables flashing lights", 'flashing', 'bool', true);
		addOption(option);
		
		var option:Option = new Option('Camera Zooms', "If unchecked, the camera won't zoom in on a beat hit.", 'camZooms', 'bool', true);
		addOption(option);

		var option:Option = new Option('Note Splashes', "Notes create particles on Sus/Sussy rating", 'noteSplashes', 'bool', true);
		addOption(option);

		var option:Option = new Option('Note Covers', "Notes have particles while they're held", 'noteCovers', 'bool', true);
		addOption(option);
		
		var option:Option = new Option('Hide HUD', 'Hides most HUD elements', 'hideHud', 'bool', false);
		addOption(option);

		var option:Option = new Option('Shaders', 'Enables shaders', 'shaders', 'bool', true);
		addOption(option);
		
		#if !html5 // Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate', "Framerate Cap", 'framerate', 'int', 60);
		option.minValue = 60;
		option.maxValue = 240;
		option.displayFormat = '%v FPS';
		option.onChange = onChangeFramerate;
		addOption(option);
		#end
		
		super();
	}
	
	function onChangeAntiAliasing()
	{
		for (sprite in members)
		{
			var sprite:Dynamic = sprite; // Make it check for FlxSprite instead of FlxBasic
			var sprite:FlxSprite = sprite; // Don't judge me ok
			if (sprite != null && (sprite is FlxSprite) && !(sprite is FlxText))
			{
				sprite.antialiasing = ClientPrefs.globalAntialiasing;
			}
		}
	}
	
	function onChangeFramerate()
	{
		if (ClientPrefs.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.framerate;
			FlxG.drawFramerate = ClientPrefs.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.framerate;
			FlxG.updateFramerate = ClientPrefs.framerate;
		}
	}
}
