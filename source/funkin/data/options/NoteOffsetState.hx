package funkin.data.options;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.ui.FlxBar;

import funkin.objects.*;
import funkin.objects.SnowEmitter;
import funkin.objects.BGSprite;

class NoteOffsetState extends MusicBeatState
{
	var boyfriend:Character;
	var gf:Character;
	
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	
	var barPercent:Float = 0;
	var delayMin:Int = 0;
	var delayMax:Int = 500;
	var timeBarBG:FlxSprite;
	var timeBar:FlxBar;
	var timeTxt:FlxText;
	var beatText:Alphabet;
	var beatTween:FlxTween;
	
	var changeModeText:FlxText;
	
	function buildStage()
	{
		var bgX:Float = -600;
		var bgY:Float = 100;
		var bg = new BGSprite(null, -832 + bgX, -974 + bgY).loadFromSheet('stage/polus/sky', 'sky', 0);
		bg.scale.set(2, 2);
		bg.updateHitbox();
		bg.scrollFactor.set(0.3, 0.3);
		
		var stars = new BGSprite(null, -1205 + bgX, -1600 + bgY).loadFromSheet('stage/polus/sky', 'stars', 0);
		stars.scale.set(2, 2);
		stars.updateHitbox();
		stars.scrollFactor.set(1.1, 1.1);
		
		var mountains = new BGSprite(null, -1569 + bgX, -185 + bgY).loadFromSheet('stage/polus/bg2', 'bgBack', 0);
		mountains.scrollFactor.set(0.8, 0.8);
		
		var mountains2 = new BGSprite(null, -1467 + bgX, -25 + bgY).loadFromSheet('stage/polus/bg2', 'bgFront', 0);
		mountains2.scrollFactor.set(0.9, 0.9);
		
		var floor = new BGSprite(null, -1410 + bgX, -139 + bgY).loadFromSheet('stage/polus/bg2', 'groundnew', 0);
		insert(0, floor);
		insert(0, mountains2);
		insert(0, mountains);
		insert(0, stars);
		insert(0, bg);
		
		var snowEmitter = new SnowEmitter(floor.x, floor.y - 200, floor.width);
		snowEmitter.start(false, ClientPrefs.lowQuality ? 0.1 : 0.05);
		snowEmitter.scrollFactor.x.set(1, 1.5);
		snowEmitter.scrollFactor.y.set(1, 1.5);
		add(snowEmitter);
		snowEmitter.alpha.active = false;
	}
	
	override public function create()
	{
		// Cameras
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor = 0x0;
		camOther.bgColor = 0x0;
		
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		
		FlxG.camera.scroll.set(120, 130);
		FlxG.camera.zoom = 0.8;
		
		persistentUpdate = true;
		FlxG.sound.pause();
		
		// Characters
		gf = new Character(400, 130, 'gf');
		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
		gf.scrollFactor.set(0.95, 0.95);
		boyfriend = new Character(770, 100, 'bf', true);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(gf);
		add(boyfriend);
		
		buildStage();
		
		beatText = new Alphabet(0, 0, 'Beat Hit!', true, false, 0.05, 0.6);
		beatText.x += 260;
		beatText.alpha = 0;
		beatText.acceleration.y = 250;
		add(beatText);
		
		timeTxt = new FlxText(0, 600, FlxG.width, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.borderSize = 2;
		timeTxt.cameras = [camHUD];
		
		barPercent = ClientPrefs.noteOffset;
		updateNoteDelay();
		
		timeBarBG = new FlxSprite(0, timeTxt.y + 8).loadGraphic(Paths.image('timeBar'));
		timeBarBG.setGraphicSize(Std.int(timeBarBG.width * 1.2));
		timeBarBG.updateHitbox();
		timeBarBG.cameras = [camHUD];
		timeBarBG.screenCenter(X);
		
		timeBar = new FlxBar(0, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this, 'barPercent', delayMin, delayMax);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; // How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.cameras = [camHUD];
		
		add(timeBarBG);
		add(timeBar);
		add(timeTxt);
		
		///////////////////////
		
		var blackBox:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 40, FlxColor.BLACK);
		blackBox.scrollFactor.set();
		blackBox.alpha = 0.6;
		blackBox.cameras = [camHUD];
		add(blackBox);

		#if mobile
 		addVirtualPad(LEFT_RIGHT,B_X);
 		addVirtualPadCamera();
 		#end
		
		Conductor.bpm = 128.0;
		FlxG.sound.playMusic(Paths.music('offsetSong'), 1, true);
		
		super.create();
	}
	
	var holdTime:Float = 0;
	
	override public function update(elapsed:Float)
	{
		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;
		
		if (controls.UI_LEFT_P #if mobile || _virtualpad.buttonLeft.justPressed #end)
		{
			barPercent = Math.max(delayMin, Math.min(ClientPrefs.noteOffset - 1, delayMax));
			updateNoteDelay();
		}
		else if (controls.UI_RIGHT_P #if mobile || _virtualpad.buttonRight.justPressed #end)
		{
			barPercent = Math.max(delayMin, Math.min(ClientPrefs.noteOffset + 1, delayMax));
			updateNoteDelay();
		}
		
		var mult:Int = 1;
		if (controls.UI_LEFT || controls.UI_RIGHT #if mobile || _virtualpad.buttonLeft.pressed || _virtualpad.buttonRight.pressed #end)
		{
			holdTime += elapsed;
			if (controls.UI_LEFT #if mobile || _virtualpad.buttonLeft.justPressed #end) mult = -1;
		}
		
		if (controls.UI_LEFT_R || controls.UI_RIGHT_R #if mobile || _virtualpad.buttonLeft.justReleased || _virtualpad.buttonRight.justReleased #end) holdTime = 0;
		
		if (holdTime > 0.5)
		{
			barPercent += 100 * elapsed * mult;
			barPercent = Math.max(delayMin, Math.min(barPercent, delayMax));
			updateNoteDelay();
		}
		
		if (controls.RESET #if mobile || _virtualpad.buttonX.justPressed #end)
		{
			holdTime = 0;
			barPercent = 0;
			updateNoteDelay();
		}
		
		if (controls.BACK #if mobile || _virtualpad.buttonB.justPressed #end)
		{
			if (zoomTween != null) zoomTween.cancel();
			if (beatTween != null) beatTween.cancel();
			
			// timeBar.destroy();
			// timeBarBG.destroy();
			FlxG.sound.resume();
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
			FlxG.switchState(new OptionsState());
		}
		
		super.update(elapsed);
	}
	
	var zoomTween:FlxTween;
	var lastBeatHit:Int = -1;
	
	override public function beatHit()
	{
		super.beatHit();
		
		if (lastBeatHit == curBeat)
		{
			return;
		}
		
		if (curBeat % 2 == 0)
		{
			boyfriend.dance();
			gf.dance();
		}
		
		if (curBeat % 4 == 2)
		{
			FlxG.camera.zoom = 0.95;
			
			if (zoomTween != null) zoomTween.cancel();
			zoomTween = FlxTween.tween(FlxG.camera, {zoom: 0.8}, 1,
				{
					ease: FlxEase.circOut,
					onComplete: function(twn:FlxTween) {
						zoomTween = null;
					}
				});
				
			beatText.alpha = 1;
			beatText.y = 320;
			beatText.velocity.y = -150;
			if (beatTween != null) beatTween.cancel();
			beatTween = FlxTween.tween(beatText, {alpha: 0}, 1,
				{
					ease: FlxEase.sineIn,
					onComplete: function(twn:FlxTween) {
						beatTween = null;
					}
				});
		}
		
		lastBeatHit = curBeat;
	}
	
	function updateNoteDelay()
	{
		ClientPrefs.noteOffset = Math.round(barPercent);
		timeTxt.text = 'Current offset: ' + Math.floor(barPercent) + ' ms';
	}
}
