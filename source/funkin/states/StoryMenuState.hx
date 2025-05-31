package funkin.states;

import flixel.addons.display.FlxBackdrop;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxStringUtil;
import flixel.util.FlxAxes;

import funkin.utils.DifficultyUtil;
import funkin.states.LoadingState;
import funkin.data.WeekData;
import funkin.states.TitleState;
import funkin.data.*;
import funkin.states.*;
import funkin.states.substates.ResetScoreSubStateImpostor;
import funkin.objects.RankIcon;

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	public static var curDiff:Int = 1;
	public static var curWeek:Int = 0;
	public static var curPlaying:String = 'bf';

	
	var ext:String = 'menu/story/';
	var map:FlxSprite;
	var selectedWeek:Bool = false;
	var weekNameText:FlxText;
	var songsText:FlxText;
	var weekText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var tweenMap:FlxTween;
	var intendedScore:Int = 0;
	var starFG:FlxBackdrop;
	var starBG:FlxBackdrop;
	var scoreText:FlxText;
	var beans:Array<FlxSprite> = [];
	var pointerLeft:FlxSprite;
	var pointerRight:FlxSprite;
	var checkmark:FlxSprite;
	var weekRank:RankIcon;
	
	var weekSpots:Array<String> = [
		'polus',
		'mira'
	];
	var diffs:Array<String> = ['', '-hard'];
	
	var loadedWeeks:Array<WeekData> = [];
	
	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);
		if (curWeek >= WeekData.weeksList.length) curWeek = 0;
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Story Menu", null);
		#end
		
		DifficultyUtil.reset();
		
		var notblack:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0x06080C);
		var grad:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image(ext + 'gradient'));
		
		starFG = new FlxBackdrop(Paths.image('menu/common/starFG'));
		starFG.updateHitbox();
		starFG.antialiasing = ClientPrefs.globalAntialiasing;
		starFG.scrollFactor.set();
		
		starBG = new FlxBackdrop(Paths.image('menu/common/starBG'));
		starBG.updateHitbox();
		starBG.antialiasing = ClientPrefs.globalAntialiasing;
		starBG.scrollFactor.set();
		
		var dark:FlxSprite = new FlxSprite(450, 0).loadGraphic(Paths.image(ext + 'dark'));
		dark.scale.set(1, 1);
		dark.updateHitbox();
		dark.antialiasing = ClientPrefs.globalAntialiasing;
		
		map = new FlxSprite(645, 295 - 115).loadGraphic(Paths.image(ext + 'maps'));
		/*map = new FlxSprite(645,295-115).loadGraphic(Paths.image(ext + 'maps'), true, 500, 500);
			for(i in 0...weekSpots.length) {
				map.animation.add(weekSpots[i], [i], 0, false);
			}
			map.animation.play(weekSpots[0]); */
		
		var bb:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menu/common/blackbars'));
		bb.scale.set(2, 2);
		bb.updateHitbox();
		
		var overlay:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image(ext + 'menu'));
		overlay.antialiasing = ClientPrefs.globalAntialiasing;
		
		var pc:FlxSprite = new FlxSprite(811, 62).loadGraphic(Paths.image(ext + 'storychars/' + curPlaying));
		
		var ct:FlxSprite = new FlxSprite(42.15, 668.3).loadGraphic(Paths.image('menu/common/controls_ex'));
		for (i in [notblack, grad, starBG, starFG, dark, map, bb, overlay, ct, pc])
		{
			i.antialiasing = ClientPrefs.globalAntialiasing;
			add(i);
			i.antialiasing = ClientPrefs.globalAntialiasing;
		}
		pointerLeft = new FlxSprite(625, 400).loadGraphic(Paths.image(ext + 'pointers'), true, 70, 70);
		pointerRight = new FlxSprite(1100, 400).loadGraphic(Paths.image(ext + 'pointers'), true, 70, 70);
		for (pointer in [pointerLeft, pointerRight])
		{
			pointer.animation.add('left', [0], 0, false);
			pointer.animation.add('mid', [1], 0, false);
			pointer.animation.add('right', [2], 0, false);
			pointer.antialiasing = ClientPrefs.globalAntialiasing;
			add(pointer);
		}
		
		// KEEP AS VARS
		var storyText:FlxText = new FlxText(40, 20, -1, 'Story');
		storyText.setFormat(Paths.font("bahn.ttf"), 60, 0xFFFFFF, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		var diffText2:FlxText = new FlxText(70, 450, -1, 'Difficulty:');
		diffText2.setFormat(Paths.font("bahn.ttf"), 50, 0xFFFFFF, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		// THE WEEK NAME
		weekText = new FlxText(70, 170, -1, 't');
		weekText.setFormat(Paths.font("bahn.ttf"), 60, 0xFFFFFF, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		// THE WEEK NAME TEXT
		weekNameText = new FlxText(70, 250, -1, '"Polus Problem"');
		weekNameText.setFormat(Paths.font("bahn.ttf"), 50, 0xFFFFFF, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		// SONGS LIST
		songsText = new FlxText(300, 315, -1, '');
		songsText.setFormat(Paths.font("bahn.ttf"), 25, 0xFFFFFF, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		// DIF
		diffText = new FlxText(370, 15, -1, 'Difficulty');
		diffText.setFormat(Paths.font("bahn.ttf"), 35, 0xFFFFFF, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		// SCORE LIST
		scoreText = new FlxText(23, 515, 543, 'FIX YO CODE FATASS!');
		scoreText.setFormat(Paths.font("bahn.ttf"), 50, 0xFFFFFF, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		for (i in [storyText, diffText2, weekText, weekNameText, songsText, scoreText, diffText])
		{
			i.borderSize = 2.5;
			add(i);
			i.antialiasing = ClientPrefs.globalAntialiasing;
		}
		
		// The week render
		var render:FlxSprite = new FlxSprite(30, 308).loadGraphic(Paths.image(ext + 'storyRender'));
		render.blend = ADD;
		render.antialiasing = ClientPrefs.globalAntialiasing;
		add(render);
		
		for (i in 0...5)
		{
			var bean:FlxSprite = new FlxSprite(284 + (50 * i), 463).loadGraphic(Paths.image(ext + 'beanDiff'), true, 46, 50);
			bean.animation.add('brah', [0, 1], 0, false);
			bean.animation.play('brah');
			bean.ID = i;
			beans.push(bean);
			bean.antialiasing = ClientPrefs.globalAntialiasing;
			add(bean);
		}
		
		checkmark = new FlxSprite(370, 185).loadGraphic(Paths.image(ext + 'checkmark'));
		checkmark.alpha = 0.01;
		checkmark.antialiasing = ClientPrefs.globalAntialiasing;
		add(checkmark);

		weekRank = new RankIcon(460, 505);
		//weekRank.setRank(100); // temp
		add(weekRank);
		
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			loadedWeeks.push(weekFile);
			WeekData.setDirectoryFromWeek(weekFile);
		}
		
		reloadSongList();
		#if mobile
		addVirtualPad(LEFT_RIGHT,A_B_X_C_D);
		#end
		super.create();
	}
	
	function nahFuckOff()
	{
		FlxG.sound.play(Paths.sound('locked'));
		FlxG.camera.shake(0.003, 0.1, null, true, FlxAxes.XY);
	}
	
	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked
			&& leWeek.weekBefore.length > 0
			&& (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}
	
	function changeWeek(change:Int = 0):Void
	{
		trace(curWeek);
		curWeek += change;
		if (curWeek < 0)
		{
			curWeek = 0;
			nahFuckOff();
			return;
		}
		if (curWeek >= loadedWeeks.length)
		{
			curWeek = loadedWeeks.length - 1;
			nahFuckOff();
			return;
		}
		
		trace(curWeek);
		var leWeek:WeekData = loadedWeeks[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);
		PlayState.storyWeek = curWeek;
		reloadSongList();
	}
	
	function reloadSongList()
	{
		var songString = '';
		var leWeek:WeekData = loadedWeeks[curWeek];
		
		pointerLeft.animation.play((curWeek - 1 <= -1) ? 'mid' : 'left');
		pointerRight.animation.play((curWeek + 1 >= loadedWeeks.length) ? 'mid' : 'right');
		
		reloadDiff();
		
		weekNameText.text = leWeek.storyName;
		weekText.text = CoolUtil.capitalize(leWeek.weekName).replace('k', 'k ');
		
		var songs:Array<Dynamic> = leWeek.songs;
		for (i in 0...songs.length)
		{
			songString += songs[i][0] + '\n';
		}
		songsText.text = songString;
		if (tweenMap != null) tweenMap.cancel();
		tweenMap = FlxTween.tween(map, {x: 645 - curWeek * 500}, 1,
		{
			ease: FlxEase.elasticOut,
			onComplete: function(twn:FlxTween) {
				tweenMap = null;
			}
		});

		checkmark.alpha = ((weekCompleted.exists(leWeek.weekName)) ? 1 : 0.01);
	}
	
	override function update(elapsed:Float)
	{
		starFG.x -= 0.03;
		starBG.x -= 0.01;
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 30, 0, 1)));
		if (Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;
		scoreText.text = "Score: " + FlxStringUtil.formatMoney(lerpScore, false, true);
		if (!selectedWeek)
		{
			if (controls.UI_LEFT_P #if mobile || _virtualpad.buttonLeft.justPressed #end) changeWeek(-1);
			if (controls.UI_RIGHT_P #if mobile || _virtualpad.buttonRight.justPressed #end) changeWeek(1);
			if (FlxG.keys.justPressed.E || FlxG.keys.justPressed.Q #if mobile || _virtualpad.buttonD.justPressed || _virtualpad.buttonC.justPressed #end) changeDiff();
			if (controls.ACCEPT #if mobile || _virtualpad.buttonA.justPressed #end) selectWeek();
			if (controls.BACK #if mobile || _virtualpad.buttonB.justPressed #end) 
			{
				FlxG.switchState(new TitleState());
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			if (FlxG.keys.justPressed.R #if mobile || _virtualpad.buttonX.justPressed #end) 
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubStateImpostor('', curDiff, curWeek));
			}
		}
                super.update(elapsed);
	}
	
	function reloadDiff()
	{
		diffText.text = 'Difficulty: ' + (diffs[curDiff - 1] == '-hard' ? 'HARD' : 'NORMAL');
		var leWeek:WeekData = loadedWeeks[curWeek];
		
		var weekDiff = leWeek.beanDiffs[curDiff - 1];
		for (i in beans) i.animation.curAnim.curFrame = ((i.ID >= weekDiff) ? 0 : 1);
		intendedScore = Highscore.getWeekScore(leWeek.fileName, curDiff);
		
		// basically we grab the accuracy from each song in the week and then add it to weekAccuracy to get the overall rank of the week
		/*
		var weekAccuracy:Float = 0;
		for (i in 0...leWeek.songs.length)
		{
			weekAccuracy += Highscore.getWeekRating(leWeek.songs[i][0], curDiff);
		}
		*/
		// the math is weekAccuracy value divided by the amount of songs in the week
		weekRank.setRank(Highscore.getWeekRating(leWeek.fileName, curDiff));
	}
	
	function changeDiff()
	{	
		FlxG.sound.play(Paths.sound('diffcheck'));
		curDiff = (curDiff == 1 ? 2 : 1);
		reloadDiff();
	}
	
	function selectWeek()
	{
		FlxG.sound.play(Paths.sound('confirmMenu'));
		var songArray:Array<String> = [];
		var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
		for (i in 0...leWeek.length)
		{
			songArray.push(leWeek[i][0]);
		}
		
		PlayState.storyPlaylist = songArray;
		PlayState.isStoryMode = true;
		selectedWeek = true;
		
		DifficultyUtil.reset();
		
		PlayState.storyDifficulty = curDiff;
		
		var songLowercase = Paths.formatToSongPath(PlayState.storyPlaylist[0].toLowerCase());
		
		PlayState.SONG = Song.loadFromJson(songLowercase + diffs[curDiff - 1], songLowercase);
		PlayState.campaignScore = 0;
		PlayState.campaignMisses = 0;
		
		LoadingState.loadAndSwitchState(new PlayState(), true);
	}

	override function closeSubState()
	{
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
		#if mobile
		removeVirtualPad();
		addVirtualPad(LEFT_RIGHT,A_B_X_C_D);
		#end
	}
}
