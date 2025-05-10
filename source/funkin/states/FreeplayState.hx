package funkin.states;

import mobile.backend.Error;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.util.FlxAxes;
import flixel.util.FlxStringUtil;

import funkin.data.WeekData;
import funkin.states.*;
import funkin.states.substates.ResetScoreSubStateImpostor;
import funkin.data.*;
import funkin.objects.RankIcon;
import funkin.backend.FunkinShader.FunkinRuntimeShader;
import funkin.utils.DifficultyUtil;
import funkin.states.substates.GameplayChangersSubstate;

class FreeplayState extends MusicBeatState
{
	public static var curWeek:Int = 0;
	public static var curSong:Int = 0;
	public static var curDiff:Int = 1;
	
	final ext:String = 'menu/freeplay/';
	
	var opts:FlxTypedGroup<FlxSprite>;
	var rankgrp:FlxTypedGroup<RankIcon>;
	var opsn:FlxTypedGroup<FlxText>;
	var opsc:FlxTypedGroup<FlxText>;
	
	var diffText:FlxText;
	var curPort:String;
	var scText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int;
	
	var port:FlxSprite;
	var dark:FlxSprite;
	var starFG:FlxBackdrop;
	var starBG:FlxBackdrop;
	var songs:Array<Dynamic> = []; // :Array<SongMetadata> = [];
	var songComposers:Array<String> = []; // :Array<SongMetadata> = [];
	var isWeekLocked:Bool;
	var weekText:FlxText;
	var portraitData:Array<String> = ['red', 'green'];
	var diffs:Array<String> = ['', '-hard'];
	
	/**
	 * To prevent spamming.
	 */
	var controlsLocked:Bool = false;
	
	override function create()
	{
		try {
			Paths.clearStoredMemory();
			Paths.clearUnusedMemory();

			#if desktop
			// Updating Discord Rich Presence
			DiscordClient.changePresence("Freeplay Menu", null);
			#end

			persistentUpdate = true;

			PlayState.isStoryMode = false;
			WeekData.reloadWeekFiles(false);
			DifficultyUtil.reset();

			var notblack:FlxSprite = new FlxSprite(0, 0).makeScaledGraphic(FlxG.width, FlxG.height, 0x06080C);
			add(notblack);

			var shader:FunkinRuntimeShader = createShader('outline');
			shader.setFloat("dist", 2);
			shader.setFloatArray("outlineColor", [255, 255, 255]);

			// Inicialização de elementos visuais
			starFG = new FlxBackdrop(Paths.image('menu/common/starFG'));
			starFG.antialiasing = ClientPrefs.globalAntialiasing;
			starFG.scrollFactor.set();

			starBG = new FlxBackdrop(Paths.image('menu/common/starBG'));
			starBG.antialiasing = ClientPrefs.globalAntialiasing;
			starBG.scrollFactor.set();

			var mainbackground:FlxSprite = new FlxSprite(-121, 226.8).loadGraphic(Paths.image('menu/common/bg'));

			dark = new FlxSprite(450, 0).loadGraphic(Paths.image(ext + 'dark2'));
			dark.scale.set(1, 1);
			dark.updateHitbox();
			dark.blend = ADD;
			dark.antialiasing = ClientPrefs.globalAntialiasing;

			port = new FlxSprite(100, 0).loadGraphic(Paths.image(ext + 'portrait'), true, 720, 720);
			port.shader = shader;
			for (i in 0...portraitData.length)
				port.animation.add(portraitData[i], [i], 0, false);
			port.x = FlxG.width - port.width;

			reloadWeekShit();
			changeSong(0);
			refreshDiffText();
			super.create();

			#if mobile
			addVirtualPad(FULL, A_B_C_X_Y_Z);
			#end
		} catch (e:Dynamic) {
			Error.logError("Error in create method: " + e);
			Error.showErrorScreen();
		}
	}
	
	function createShader(fragFile:String = null, vertFile:String = null):FunkinRuntimeShader
	{
		return new FunkinRuntimeShader(fragFile == null ? null : File.getContent(Paths.modsShaderFragment(fragFile)));
	}
	
	function reloadWeekShit()
	{
		try {
			var i = curWeek;
			weekText.text = 'Week ' + (curWeek + 1);

			for (sb in opts.members) sb.destroy();
			for (sb in opsn.members) sb.destroy();
			for (sb in opsc.members) sb.destroy();
			for (sb in rankgrp.members) sb.destroy();

			opts.clear();
			opsn.clear();
			opsc.clear();
			rankgrp.clear();

			songs = [];
			isWeekLocked = weekIsLocked(WeekData.weeksList[i]);
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);

			WeekData.setDirectoryFromWeek(leWeek);

			for (song in leWeek.songs) {
				var colors:Array<Int> = song[2];
				if (colors == null || colors.length < 3) {
					colors = [146, 113, 253];
				}
				songs.push(song);
			}

			curSong = 0;
			for (i in 0...songs.length) {
				final colors = songs[i][2];

				var b:FlxSprite = new FlxSprite(-400, 270 - (curSong * 125) + (i * 125)).loadGraphic(Paths.image(ext + 'buttonColor'));
				b.alpha = (i >= 1 ? 0.5 : 1);
				b.antialiasing = ClientPrefs.globalAntialiasing;
				b.color = FlxColor.fromRGB(colors[0], colors[1], colors[2]);
				b.ID = i;
				opts.add(b);

				final rank:RankIcon = new RankIcon(310, -25, b);
				rank.setRank(Highscore.getRating(songs[i][0], curDiff) * 100);
				rankgrp.add(rank);

				var s:FlxText = new FlxText(-400, 282 - (curSong * 125) + (i * 125), -1, isWeekLocked ? '???' : songs[i][0]);
				s.setFormat(Paths.font("bahn.ttf"), 35, 0xFFFFFF, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				s.borderSize = 2.5;
				s.alpha = (i >= 1 ? 0.5 : 1);
				s.ID = i;
				s.antialiasing = ClientPrefs.globalAntialiasing;
				opsn.add(s);

				var c:FlxText = new FlxText(-400, 345 - (curSong * 125) + (i * 125), -1,
					(isWeekLocked ? 'Complete ' + CoolUtil.capitalize(WeekData.weeksList[curWeek]) + ' to unlock this song!' : songs[i][3]));
				c.setFormat(Paths.font("bahn.ttf"), 20, 0xFFFFFF, FlxTextAlign.LEFT);
				c.antialiasing = ClientPrefs.globalAntialiasing;
				c.alpha = (i >= 1 ? 0.5 : 1);
				c.ID = i;
				opsc.add(c);
			}

			changeSong(0);
		} catch (e:Dynamic) {
			Error.logError("Error in reloadWeekShit method: " + e);
			Error.showErrorScreen();
		}
	}
	
	function nahFuckOff()
	{
		FlxG.sound.play(Paths.sound('locked'));
		FlxG.camera.shake(0.003, 0.1, null, true, FlxAxes.XY);
	}
	
	function changeWeek(by:Int)
	{
		try {
			curWeek += by;
			if (curWeek < 0) {
				curWeek = 0;
				nahFuckOff();
				return;
			}
			if (curWeek >= WeekData.weeksList.length) {
				curWeek = WeekData.weeksList.length - 1;
				nahFuckOff();
				return;
			}
			weekText.text = 'Week ' + (curWeek + 1);
			reloadWeekShit();
		} catch (e:Dynamic) {
			Error.logError("Error in changeWeek method: " + e);
			Error.showErrorScreen();
		}
	}
	
	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked
			&& leWeek.weekBefore.length > 0
			&& (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}
	
	function changeSong(by:Int)
	{
		try {
			curSong += by;
			if (by != 0) FlxG.sound.play(Paths.sound('scrollMenu'));

			if (curSong < 0) {
				curSong = 0;
				nahFuckOff();
				return;
			}
			if (curSong >= songs.length) {
				curSong = songs.length - 1;
				nahFuckOff();
				return;
			}

			if (curPort != songs[curSong][1]) {
				curPort = songs[curSong][1];
				port.animation.play(curPort);
				port.x = 1280;
				FlxTween.tween(port, {x: 1280 - port.width}, 0.25, {ease: FlxEase.quadOut});
			}

			refreshDiffText();
		} catch (e:Dynamic) {
			Error.logError("Error in changeSong method: " + e);
			Error.showErrorScreen();
		}
	}
	
	function startSong()
	{
		try {
			if (isWeekLocked) {
				nahFuckOff();
			} else {
				controlsLocked = true;

				FlxG.sound.play(Paths.sound('confirmMenu'));
				var songLowercase = songs[curSong][0];
				PlayState.SONG = Song.loadFromJson(songLowercase + diffs[curDiff - 1], songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDiff;
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
		} catch (e:Dynamic) {
			Error.logError("Error in startSong method: " + e);
			Error.showErrorScreen();
		}
	}
	
	function changeDiff()
	{
		FlxG.sound.play(Paths.sound('diffcheck'));
		curDiff = (curDiff == 1 ? 2 : 1);
		refreshDiffText();
	}
	
	function refreshDiffText()
	{
		trace(songs);
		intendedScore = Highscore.getScore(songs[curSong][0], curDiff);
		diffText.text = 'Difficulty: ' + (diffs[curDiff - 1] == '-hard' ? 'HARD' : 'NORMAL');
		for (i in 0...rankgrp.length)
		{
			rankgrp.members[i].setRank(Highscore.getRating(songs[i][0], curDiff) * 100);
		}
	}
	
	override function update(elapsed:Float)
	{
		starFG.x -= 0.12 * 60 * elapsed;
		starBG.x -= 0.04 * 60 * elapsed;
		
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.getElapsedLerp(0.6, elapsed)));
		if (Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;
		scText.text = "Score: " + FlxStringUtil.formatMoney(lerpScore, false, true);
		
		if (!controlsLocked)
		{
			if (FlxG.keys.justPressed.CONTROL #if mobile || _virtualpad.buttonC.justPressed #end)
			{
				persistentUpdate = false;
				#if mobile
			    removeVirtualPad();
			    #end
				openSubState(new GameplayChangersSubstate());
			}
			
			if (controls.UI_UP_P #if mobile || _virtualpad.buttonUp.justPressed #end) changeSong(-1);
			if (controls.UI_DOWN_P #if mobile || _virtualpad.buttonDown.justPressed #end) changeSong(1);
			if (controls.UI_LEFT_P #if mobile || _virtualpad.buttonLeft.justPressed #end) changeWeek(-1);
			if (controls.UI_RIGHT_P #if mobile || _virtualpad.buttonRight.justPressed #end) changeWeek(1);
			if (FlxG.keys.justPressed.E || FlxG.keys.justPressed.Q #if mobile || _virtualpad.buttonY.justPressed || _virtualpad.buttonZ.justPressed #end) changeDiff();
			if (controls.ACCEPT #if mobile || _virtualpad.buttonA.justPressed #end) startSong();
			if (controls.BACK #if mobile || _virtualpad.buttonB.justPressed #end)
			{
				controlsLocked = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxG.switchState(() -> new TitleState());
			}
			if (FlxG.keys.justPressed.R #if mobile || _virtualpad.buttonX.justPressed #end)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubStateImpostor(songs[curSong][0], curDiff));
			}
		}
		
		super.update(elapsed);
	}
	
	override function closeSubState()
	{
		persistentUpdate = true;
		changeSong(0);
		super.closeSubState();
		#if mobile
		removeVirtualPad();
		addVirtualPad(FULL,A_B_C_X_Y_Z);
		#end
	}
}
