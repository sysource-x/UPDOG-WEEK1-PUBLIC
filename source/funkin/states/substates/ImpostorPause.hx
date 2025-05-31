package funkin.states.substates;

import funkin.data.options.OptionsState;

import flixel.addons.transition.FlxTransitionableState;

import funkin.utils.CameraUtil;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxDestroyUtil;

import funkin.backend.MusicBeatSubstate;

class ImpostorPause extends MusicBeatSubstate
{
	static final defScale = 0.6;
	
	var curSel:Int = 0;
	
	var buttons:FlxTypedGroup<Button>;
	
	var pauseMusic:FlxSound;
	
	override function create()
	{
		this.cameras = [CameraUtil.lastCamera];

		pauseMusic = FlxG.sound.load(Paths.music('pause_theme'),1,true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		
		var bg = new FlxSprite().makeScaledGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);
		bg.alpha = 0.4;
		
		final frame = new FlxSprite().loadFromSheet('menu/pause/pause_assets', 'pause box mustaaaarrrrdddd');
		frame.scale.scale(defScale);
		frame.updateHitbox();
		frame.antialiasing = ClientPrefs.globalAntialiasing;
		add(frame);
		frame.screenCenter();
		
		final txt = new FlxSprite(0, 100).loadFromSheet('menu/pause/pause_assets', 'paused text');
		txt.scale.scale(defScale);
		txt.updateHitbox();
		txt.antialiasing = ClientPrefs.globalAntialiasing;
		txt.centerOnObject(frame, X);
		add(txt);
		
		buttons = new FlxTypedGroup();
		add(buttons);
		
		final resume = new Button(0, txt.y + txt.height + 20, 'resume', close);
		buttons.add(resume);
		resume.centerOnObject(frame, X);
		
		final restart = new Button(resume.x, resume.y + resume.height, 'restart', restartSong);
		buttons.add(restart);
		
		final options = new Button(resume.x, restart.y + restart.height, 'option', openOptions);
		buttons.add(options);
		
		final exit = new Button(resume.x, options.y + options.height, 'exit', exitSong);
		buttons.add(exit);
		
		changeSel();
		
		#if mobile
		addVirtualPad(UP_DOWN, A);
	        addVirtualPadCamera();
	        #end
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5) pauseMusic.volume += 0.01 * elapsed;
		super.update(elapsed);
		
		if (controls.UI_DOWN_P || controls.UI_UP_P #if mobile || _virtualpad.buttonDown.justPressed || _virtualpad.buttonUp.justPressed #end) changeSel((controls.UI_DOWN_P #if mobile || _virtualpad.buttonDown.justPressed #end) ? 1 : -1);
		if (controls.ACCEPT #if mobile || _virtualpad.buttonA.justPressed #end)
		{
			buttons.members[curSel].onClick();
		}
	}
	
	function openOptions()
	{
		PlayState.instance.paused = true;
		PlayState.instance.vocals.volume = 0;
		FlxG.switchState(() -> new OptionsState());
		@:privateAccess
		{
			if (pauseMusic._sound != null)
			{
				FlxG.sound.playMusic(pauseMusic._sound, 0);
				FlxTween.tween(FlxG.sound.music, {volume: 0.5}, 0.7);
			}
		}
		
		OptionsState.onPlayState = true;
	}
	
	function restartSong()
	{
		PlayState.instance.paused = true;
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;
		
		FlxG.resetState();
	}
	
	function exitSong()
	{
		PlayState.deathCounter = 0;
		PlayState.seenCutscene = false;
		FlxG.switchState(() -> PlayState.isStoryMode ? new StoryMenuState() : new FreeplayState());
		PlayState.cancelMusicFadeTween();
		FlxG.sound.playMusic(Paths.music('freakyMenu'));
		PlayState.changedDifficulty = false;
		PlayState.chartingMode = false;
	}
	
	function changeSel(diff:Int = 0)
	{
		// if (diff != 0)
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		buttons.members[curSel].isEnabled = false;
		
		curSel = FlxMath.wrap(curSel + diff, 0, buttons.length - 1);
		
		buttons.members[curSel].isEnabled = true;
	}

	override function destroy() {
		pauseMusic.destroy();
		super.destroy();
	}
}

@:access(funkin.states.substates.ImpostorPause)
private class Button extends FlxSprite
{
	var text:FlxSprite;
	
	public var isEnabled:Bool = false;
	
	public var onClick:Void->Void;
	
	public function new(x:Float = 0, y:Float = 0, text:String, onClick:Void->Void)
	{
		super(x, y);
		active = true;
		
		this.onClick = onClick;
		
		loadFromSheet('menu/pause/pause_assets', 'button blank', 0);
		animation.addByPrefix('button select', 'button select', 0);
		
		scale.scale(ImpostorPause.defScale);
		updateHitbox();
		
		this.text = new FlxSprite().loadFromSheet('menu/pause/pause_assets', '$text txt', 0);
		this.text.scale.scale(ImpostorPause.defScale);
		this.text.updateHitbox();
		this.text.antialiasing = ClientPrefs.globalAntialiasing;
		this.antialiasing = ClientPrefs.globalAntialiasing;
		
		this.active = this.text.active = true; // loadfromsheet disables this on anims of 1 frame
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		animation.play(isEnabled ? 'button select' : 'button blank');
		
		text.update(elapsed);
		
		text.centerOnObject(this, XY);
	}
	
	override function draw()
	{
		super.draw();
		text.draw();
	}
	
	override function destroy()
	{
		text = FlxDestroyUtil.destroy(text);
		super.destroy();
	}
}
