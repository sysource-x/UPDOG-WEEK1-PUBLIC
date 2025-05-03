package funkin.states.substates;

import funkin.utils.CameraUtil;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import funkin.objects.shader.*;
import flixel.tweens.FlxTween;
import funkin.objects.*;
import funkin.states.*;
import funkin.data.*;
import funkin.backend.MusicBeatSubstate;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Character;

	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var defeat:BGSprite;
	var gameOver:BGSprite;
	var ct:FlxSprite;
	

	var colorSwap:ColorSwap;
	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;

	var stageSuffix:String = "";

	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	public static var camOffset:Array<Float> = [0, 0];

	public static var instance:GameOverSubstate;

	public static function resetVariables()
	{
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
		camOffset = [0, 0];
	}

	override function create()
	{
		instance = this;
		PlayState.instance.callOnScripts('onGameOverStart', []);
		
		if (!boyfriend.curCharacter.contains('diddy')) //sorry.
		{
			defeat = new BGSprite("defeat effect", boyfriend.getMidpoint().x, boyfriend.getMidpoint().y);
			defeat.x -= defeat.width * .5;
			defeat.scale.set(.044, 1);
			defeat.alpha = 0;
	
			gameOver = new BGSprite("game over", boyfriend.getMidpoint().x);
			gameOver.x -= gameOver.width * .5;
			gameOver.alpha = 0;
			
			insert(members.indexOf(boyfriend), defeat);
			add(gameOver);
		}


		colorSwap = new ColorSwap();
		colorSwap.saturation = colorSwap.brightness = 0;

		if (!boyfriend.curCharacter.contains('diddy'))
		boyfriend.shader = colorSwap.shader;

		ct = new FlxSprite(42.15, 668.3 + 100).loadGraphic(Paths.image('menu/common/controls_death'));
		ct.antialiasing = ClientPrefs.globalAntialiasing;
		// ct.scrollFactor.set();
		add(ct);

		#if mobile
		addVirtualPad(NONE,A_B);
		addVirtualPadCamera();
		#end

		super.create();
		if (defeat != null)
		{
			FlxTween.tween(defeat, { alpha: 1 }, 1.5, { ease: FlxEase.sineInOut });
			FlxTween.tween(defeat.scale, { x: 4.74 }, 3, { ease: FlxEase.quadOut });
		}

		if (gameOver != null)
		{
			FlxTimer.wait(0, () -> {
				gameOver.y = defeat.y - 200;
				FlxTween.tween(gameOver, { y: defeat.y - 50, alpha: 1 }, 2, { ease: FlxEase.quadOut, startDelay: 1 });
			});
		}


		FlxTween.tween(colorSwap, { saturation: -1, brightness: -.5 }, 3, { ease: FlxEase.linear });
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float)
	{
		super();

		PlayState.instance.setOnScripts('inGameOver', true);

		Conductor.songPosition = 0;
		
		boyfriend = new Character(x, y, characterName, true);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);

		camFollow = new FlxPoint(boyfriend.getMidpoint().x + camOffset[0], boyfriend.getMidpoint().y + camOffset[1]);

		if (deathSoundName != 'empty') FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.bpm = 100;
		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		camFollowPos = new FlxObject(0, 0, 1, 1);
		
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);
	}

	public var startedDeath:Bool = false;

	var isFollowingAlready:Bool = false;

	override function update(elapsed:Float)
	{
		PlayState.instance.callOnScripts('onUpdate', [elapsed]);
		PlayState.instance.callOnHScripts('update', [elapsed]);
		super.update(elapsed);
		

		if (boyfriend != null && defeat != null) defeat.centerOnObject(boyfriend,Y);

		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
		if (updateCamera)
		{
			var lerpVal:Float = FlxMath.bound(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (controls.ACCEPT #if mobile || _virtualpad.buttonA.justPressed #end)
		{
			endBullshit();
		}

		if (controls.BACK #if mobile || _virtualpad.buttonB.justPressed #end)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;

			FlxG.switchState(() -> PlayState.isStoryMode ? new StoryMenuState() : new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			PlayState.instance.callOnScripts('onGameOverConfirm', [false]);
		}
		if (boyfriend.animation.curAnim.name == 'firstDeath' && boyfriend.animation.curAnim.finished && startedDeath)
		{
			boyfriend.playAnim('deathLoop');
		}

		if (boyfriend.animation.curAnim.name == 'firstDeath')
		{
			if (boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);
				updateCamera = true;
				isFollowingAlready = true;
			}

			if (boyfriend.animation.curAnim.finished && !playingDeathSound)
			{
				coolStartDeath();
				startedDeath = true;
			}
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);


		if (ct != null)
		{
			var newScale = (FlxG.camera.viewWidth / FlxG.width);
			ct.scale.set(newScale,newScale);
			ct.updateHitbox();

			ct.x = FlxG.camera.viewX + (42.15 * newScale);
			ct.y = FlxG.camera.viewBottom - ct.height - (10 * newScale);
		}

	}

	override function beatHit()
	{
		super.beatHit();
	}

	public var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void		
	{
		PlayState.instance.callOnScripts('deathAnimStart', [volume]);
		FlxTween.tween(FlxG.camera, { zoom: 0.75 }, 4, { ease: FlxEase.smootherStepInOut });

		if (loopSoundName != 'empty') FlxG.sound.playMusic(Paths.music(loopSoundName), volume);

		PlayState.instance.callOnScripts('deathAnimStartPost', [volume]);
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			if (endSoundName != 'empty') FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer) {
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function() {
					FlxG.resetState();
				});
			});
			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
		}
	}
}
