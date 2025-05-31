package funkin.data.options;

import flixel.FlxG;

using StringTools;

class GameplaySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Gameplay Settings';
		rpcTitle = 'Gameplay Settings Menu'; // for Discord Rich Presence

		// I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Downscroll', // Name
			'Changes position of the notes', // Description
			'downScroll', // Save data variable name
			'bool', // Variable type
			false); // Default value
		addOption(option);
		
		var option:Option = new Option('Ghost Tapping', "Removes penalty for hitting keys when no notes are present",
			'ghostTapping', 'bool', true);
		addOption(option);

		var option:Option = new Option('Disable Reset Button', "Disables the Reset button", 'noReset', 'bool', false);
		addOption(option);

		var option:Option = new Option('Keyboard Enabled',
			'Check this if you want to play with\na keyboard on the Android Port',
			'keyboardEnabled',
			'bool',
			false);
		addOption(option);
		/*
		var option:Option = new Option('Mechanics', 'Check this if you want to enable mechanics!',
		'mechanics', 'bool', true);
		addOption(option);*/



		

		super();
	}

	function onChangeHitsoundVolume()
	{
		FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
	}

	function addHitWindowOption(dName:String, prefID:String, min:Float = 15.0, max:Float = 200.0, scrollSpeed:Float = 15)
	{
		var option:Option = new Option('$dName Hit Window', 'Changes the amount of time you have\nfor hitting a "$dName" in milliseconds.', prefID, 'float',
			max);
		option.displayFormat = '%vms';
		option.scrollSpeed = scrollSpeed;
		option.minValue = min;
		option.maxValue = max;
		option.changeValue = 0.1;
		addOption(option);
	}
}
