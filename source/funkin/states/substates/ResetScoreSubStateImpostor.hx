package funkin.states.substates;

import funkin.utils.DifficultyUtil;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import funkin.data.*;
import funkin.states.*;
import funkin.objects.*;
import funkin.backend.MusicBeatSubstate;

using StringTools;

class ResetScoreSubStateImpostor extends MusicBeatSubstate
{
	var bg:FlxSprite;
	var onYes:Bool = false;
	var yesText:FlxText;
	var noText:FlxText;
	var song:String;
	var difficulty:Int;
	var week:Int;

	// Week -1 = Freeplay
	public function new(song:String, difficulty:Int, week:Int = -1)
	{
		this.song = song;
		this.difficulty = difficulty;
		this.week = week;

		super();

		var name:String = song;
		if (week > -1)
		{
			name = WeekData.weeksLoaded.get(WeekData.weeksList[week]).weekName;
		}
		name += ' (' + DifficultyUtil.difficulties[difficulty] + ')?';

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var yo = new FlxText(0, 0, FlxG.width, "Do you want to reset your current score?", 48);
		yo.setFormat(Paths.font("liber.ttf"), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		yo.screenCenter();
		yo.y -= 75;
		yo.borderSize = 1.25;
		yo.antialiasing = ClientPrefs.globalAntialiasing;
		add(yo);

		yesText = new FlxText(0, 0, FlxG.width, "Yes", 48);
		yesText.setFormat(Paths.font("liber.ttf"), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		yesText.screenCenter();
		yesText.x -= 200;
		yesText.borderSize = 1.25;
		yesText.antialiasing = ClientPrefs.globalAntialiasing;
		add(yesText);
		
		noText = new FlxText(0, 0, FlxG.width, "No", 48);
		noText.setFormat(Paths.font("liber.ttf"), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		noText.screenCenter();
		noText.x += 200;
		noText.borderSize = 1.25;
		noText.antialiasing = ClientPrefs.globalAntialiasing;
		add(noText);
		#if mobile
		addVirtualPad(LEFT_RIGHT, A_B);
		#end
		updateOptions();
	}

	override function update(elapsed:Float)
	{
		bg.alpha += elapsed * 1.5;
		if (bg.alpha > 0.6) bg.alpha = 0.6;

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P #if mobile || _virtualpad.buttonLeft.justPressed || _virtualpad.buttonRight.justPressed #end)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 1);
			onYes = !onYes;
			updateOptions();
		}
		if (controls.BACK #if mobile || _virtualpad.buttonB.justPressed #end)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			#if mobile
			closeSs();
                        #else
			close();
                        #end
		}
		else if (controls.ACCEPT #if mobile || _virtualpad.buttonA.justPressed #end)
		{
			if (onYes)
			{
				if (week == -1)
				{
					Highscore.resetSong(song, difficulty);
				}
				else
				{
					Highscore.resetWeek(WeekData.weeksList[week], difficulty);
				}
			}
			FlxG.sound.play(Paths.sound('cancelMenu'), 1);
			#if mobile
			closeSs();
			#else
			close();
                        #end
		}
		super.update(elapsed);
	}

	function updateOptions()
	{
		var scales:Array<Float> = [0.75, 1];
		var alphas:Array<Float> = [0.6, 1.25];
		var confirmInt:Int = onYes ? 1 : 0;

		yesText.alpha = alphas[confirmInt];
		yesText.scale.set(scales[confirmInt], scales[confirmInt]);
		noText.alpha = alphas[1 - confirmInt];
		noText.scale.set(scales[1 - confirmInt], scales[1 - confirmInt]);
	}
}
