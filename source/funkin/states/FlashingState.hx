package funkin.states;

import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import flixel.addons.display.FlxBackdrop;
import funkin.data.*;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;
	var curSel = 0;
	var warnText:FlxText;
	var descText:FlxText;
	var starFG:FlxBackdrop;
	var starBG:FlxBackdrop;
	var enabled:Array<Bool> = [true, false, true, false];
	var goBackNum = 3; // make this the last num in the array
	var optionShit =
	[['Flashing Lights', 'Enables flashing lights'],
	['Low Quality', 'Less background elements, increased performance'],
	['Rich Presence', 'Shows the real name of the song you\'re playing'],
	['Start Game', 'Saves settings and starts the game']];
	var menuItems:FlxTypedGroup<FlxText>;

	function saveOpts() {
		ClientPrefs.flashing = enabled[0];
		ClientPrefs.lowQuality = enabled[1];
		ClientPrefs.disc_rpc = enabled[2];
		ClientPrefs.startedUp = true;
		ClientPrefs.saveSettings();
	}
	override function create()
	{
		FlxG.sound.playMusic(Paths.music('whatsUpDog'), 0.3);
		persistentUpdate = true;
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Startup Config Screen", null);
		#end

		trace('menu');
		menuItems = new FlxTypedGroup<FlxText>();
		add(menuItems);
		
		warnText = new FlxText(50, 200, 1280, 'First Startup Configuration', 24);
		descText = new FlxText(50, 620, 1280, '', 24);
		for(i in [warnText, descText]) {
			add(i);
		}

		trace('menu2');
		for(i in 0...optionShit.length) {
			var item = new FlxText(50, 300+(i*50), 1280, optionShit[i][0], 24);
			item.ID = i;
			menuItems.add(item);
		}
		super.create();
		trace('sel');
		changeSel(0);
		trace('seldone');
		#if mobile
		addVirtualPad(UP_DOWN,A);
		#end

	}
	function changeSel(oh:Int = 0) {
		//if(oh != 0) FlxG.sound.play(Paths.sound('scrollMenu'), 1);
		curSel+=oh; // Increment the thing

		// if < > blah shit
		if(curSel < 0) 
			curSel = optionShit.length - 1;
		if (curSel >= optionShit.length)
			curSel = 0;

		// Update the description..
		descText.text = optionShit[curSel][1];
		
		menuItems.forEach(function(spr:FlxText)
		{
			if(spr.ID != goBackNum)
				spr.text = (optionShit[spr.ID][0] + ': ') + (enabled[spr.ID] ? 'ON' : 'OFF');
			spr.color = (curSel == spr.ID ? 0x62E0CF : FlxColor.WHITE);
		});		
	}
	override function update(elapsed:Float)
	{
		// controls shit
		if(controls.UI_DOWN_P #if mobile || _virtualpad.buttonDown.justPressed #end)
			changeSel(1);
		if(controls.UI_UP_P #if mobile || _virtualpad.buttonUp.justPressed #end)
			changeSel(-1);
		if(controls.ACCEPT #if mobile || _virtualpad.buttonA.justPressed #end) {
			if(curSel == goBackNum) {
				saveOpts();
				FlxG.sound.play(Paths.sound('confirmMenu'));
				FlxTransitionableState.skipNextTransIn = false;
				FlxTransitionableState.skipNextTransOut = false;
				FlxG.switchState(new TitleState());
			} else {
				enabled[curSel] = !enabled[curSel];
				changeSel();
			}
		}
		super.update(elapsed);
	}
}
