package funkin.states;

import mobile.backend.Error;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxAxes;
import flixel.util.typeLimit.NextState;

import funkin.data.*;
import funkin.data.scripts.*;
import funkin.states.*;
import funkin.objects.*;
import funkin.data.options.*;
import funkin.objects.shader.*;

class TitleState extends MusicBeatState
{
	public static var initialized:Bool = false;
	
	public static var updateVersion = 'idk bro';
	
	public static var alreadyBeenInMenu:Bool = false;
	
	public static var curSel:Int = 0; // current selecto
	
	public static var PLAYED_V4:Bool = false;
	
	public static var PLAYED_V3:Bool = false;
	
	/**
	 * Checks ur appdata for a v3 and v4 save
	 */
	public static function checkPreviousVers()
	{
		static var checked = false;
		if (checked) return;
		checked = true;
		
		final appDataPath = Sys.getEnv("AppData");
		
		PLAYED_V4 = FileSystem.isDirectory('$appDataPath/ShadowMario/VS Impostor');
		
		PLAYED_V3 = FileSystem.isDirectory('$appDataPath/Team Funktastic/Kade Engine'); // is this the actual path of v3 ? idk
	}
	
	var trophy:FlxSprite = null;
	var lg:FlxSprite;
	var lt:FlxText;
	
	var bg:FlxSprite;
	var stars:FlxSprite;
	var ct:FlxSprite;
	
	var snowEmitter:SnowEmitter;
	
	var starFG:FlxBackdrop;
	var starBG:FlxBackdrop;
	
	var hasSplash = false;
	var opts:FlxTypedGroup<FlxSprite>;
	var ott:FlxTypedGroup<FlxText>;
	var colorSwap:ColorSwap;
	var tv:FlxSprite;
	var zared:FlxSprite;
	var canSelect:Bool;
	var v2Check = true; // SET THIS TO FALSE IN V2
	
	// Now that this state is hardcoded we can finally make it so it stays on the selection
	var boundaries = 4; // When to start looping the menu, just in case we're going with the shop-lock until V2.
	
	var buttons:Array<Dynamic> = [
		// buttons! add translation later!
		[52.65, 265.85, 'SM', 'Story Mode'],
		[52.65, 344.45, 'FP', 'Freeplay'],
		[52.65, 423.05, 'OP', 'Options'],
		[55.7, 500.5, 'SK', 'Skins'],
		[172.1, 500.5, 'SH', 'Shop']
	];
	
	var secretKey:Array<FlxKey> = [FlxKey.D, FlxKey.K];
	var lastKeysPressed:Array<FlxKey> = [];
	var keyTimer:Float = 0;

	var secretTriggered:Bool = false;
	
	function selectedOption()
	{
		try {
			FlxTransitionableState.skipNextTransIn = false;
			FlxTransitionableState.skipNextTransOut = false;

			final nextState:Null<NextState> = switch (curSel) {
				case 0: () -> new StoryMenuState();
				case 1: () -> new funkin.states.FreeplayState();
				case 2: () -> {
					OptionsState.onPlayState = false;
					return new funkin.data.options.OptionsState();
				}
				default: null;
			};

			if (nextState != null) {
				FlxG.sound.play(Paths.sound('confirmMenu'));
				FlxTimer.wait(0.5, FlxG.switchState.bind(nextState));
			} else {
				FlxG.sound.play(Paths.sound('locked'));
				FlxG.camera.shake(0.003, 0.1, null, true, FlxAxes.XY);
				return;
			}

			canSelect = false;

			opts.forEach(function(spr:FlxSprite) {
				if (curSel != spr.ID) FlxTween.tween(spr, {alpha: 0.25}, 0.5, {ease: FlxEase.quadOut});
			});
			ott.forEach(function(spr:FlxText) {
				if (curSel != spr.ID) FlxTween.tween(spr, {alpha: 0.25}, 0.5, {ease: FlxEase.quadOut});
			});

			FlxTween.tween(FlxG.camera, {'scroll.y': -700}, 1, {ease: FlxEase.quadIn});
		} catch (e:Dynamic) {
			Error.logError("Error in selectedOption method: " + e);
			Error.showErrorScreen();
		}
	}
	
	override public function create():Void
	{
		try {
			Paths.clearStoredMemory();
			Paths.clearUnusedMemory();

			#if LUA_ALLOWED
			Paths.pushGlobalMods();
			#end

			WeekData.loadTheFirstEnabledMod();
			checkPreviousVers();

			super.create();

			if (!initialized) {
				if (FlxG.save.data != null && FlxG.save.data.fullscreen) {
					FlxG.fullscreen = FlxG.save.data.fullscreen;
				}
				persistentUpdate = true;
				persistentDraw = true;
			}
			initialized = true;

			if (FlxG.save.data.startedUp == null) {
				trace('No save data detected, moving to FlashingState');
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				FlxG.switchState(new FlashingState());
			} else {
				if (initialized) startIntro();
				else {
					new FlxTimer().start(1, function(tmr:FlxTimer) {
						startIntro();
					});
				}
			}
		} catch (e:Dynamic) {
			Error.logError("Error in create method: " + e);
			Error.showErrorScreen();
		}
	}
	
	public function startIntro()
	{
		try {
			if (!initialized) {
				if (FlxG.sound.music == null) {
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				}
			}

			#if DISCORD_ALLOWED
			DiscordClient.changePresence("In the Menu", null);
			#end

			var versionString = 'VS IMPOSTOR WEEK 1';
			canSelect = true;

			opts = new FlxTypedGroup<FlxSprite>();
			ott = new FlxTypedGroup<FlxText>();

			starFG = new FlxBackdrop(Paths.image('menu/common/starFG'));
			starFG.updateHitbox();
			starFG.antialiasing = ClientPrefs.globalAntialiasing;
			starFG.scrollFactor.set();
			add(starFG);

			starBG = new FlxBackdrop(Paths.image('menu/common/starBG'));
			starBG.antialiasing = ClientPrefs.globalAntialiasing;
			starBG.scrollFactor.set();
			add(starBG);

			// Background
			bg = new FlxSprite(-121, 226.8 + 700).loadGraphic(Paths.image('menu/common/bg'));

			// Outros elementos visuais...
			// Adicione mais verificações se necessário.

		} catch (e:Dynamic) {
			Error.logError("Error in startIntro method: " + e);
			Error.showErrorScreen();
		}
	}
	
	public static var transitioning:Bool = false;
	
	override public function update(elapsed:Float)
	{
		try {
			if (FlxG.save.data.startedUp == null) {
				super.update(elapsed);
				return;
			}
			if (starFG != null) {
				starFG.x -= 0.12 * 60 * elapsed;
			}
			if (starBG != null) {
				starBG.x -= 0.04 * 60 * elapsed;
			}

			var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

			if (isHardcodedState()) {
				#if mobile
				for (touch in FlxG.touches.list) {
					if (touch.justPressed) {
						pressedEnter = true;
					}
				}
				#end

				var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

				if (gamepad != null) {
					if (gamepad.justPressed.START) pressedEnter = true;

					#if switch
					if (gamepad.justPressed.B) pressedEnter = true;
					#end
				}

				if (canSelect) {
					if (controls.UI_DOWN_P #if mobile || _virtualpad.buttonDown.justPressed #end) {
						changeSel(1, 1);
					}
					if (controls.UI_UP_P #if mobile || _virtualpad.buttonUp.justPressed #end) {
						changeSel(-1, 1);
					}
					if (controls.ACCEPT #if mobile || _virtualpad.buttonA.justPressed #end) {
						selectedOption();
					}
				}
			}

			super.update(elapsed);
		} catch (e:Dynamic) {
			Error.logError("Error in update method: " + e);
			Error.showErrorScreen();
		}
	}

	function doSecretAction():Void
	{
		insert(members.indexOf(lg) - 1, tv);
		FlxG.sound.play(Paths.sound('confirmMenu'));
		FlxTween.tween(tv, {alpha: 1}, 2, {ease: FlxEase.linear});
		FlxG.mouse.visible = true;
	}
	
	function moveShitUp(tt:Float = 1)
	{
		trace('STARS0');
		FlxTween.tween(starFG, {alpha: 1}, tt, {ease: FlxEase.quadOut});
		FlxTween.tween(starBG, {alpha: 1}, tt, {ease: FlxEase.quadOut}); // Tween, make it more auraful and hype farmy later
		trace('STARS');
		FlxTween.tween(bg, {y: bg.y - 700}, tt, {ease: FlxEase.quadOut}); // Tween, make it more auraful and hype farmy later
		trace('STARS2');
		FlxTween.tween(lg, {x: 27, y: 82}, tt, {ease: FlxEase.quadInOut});
		
		if (trophy != null)
		{
			FlxTween.tween(trophy, {y: (82 - trophy.height) + 30}, tt, {ease: FlxEase.quadInOut, startDelay: 0.5});
		}
		
		trace('STARS3');
		FlxTween.tween(lt, {y: lt.y + 700}, tt, {ease: FlxEase.quadInOut});
		trace("STARS3");
		FlxTween.tween(ct, {y: ct.y - 100}, tt, {ease: FlxEase.quadIn}); // Tween, make it more auraful and hype farmy later
		trace('AND WE ARE DONE');
		
		FlxTween.num(snowEmitter.alpha.start.min, 1, 1, {ease: FlxEase.quadIn}, (f) -> {
			snowEmitter.alpha.set(f);
			
			snowEmitter.forEachAlive(p -> {
				p.alpha = f;
			});
		});
	}
	
	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	
	public function skipIntro():Void
	{
		if (callOnScript('onSkipIntro', []) != Globals.Function_Stop && !skippedIntro)
		{
			if (!alreadyBeenInMenu)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxG.sound.music.fadeIn(4, 0, 0.7);
				FlxG.camera.flash(FlxColor.BLACK, 0.5);
				alreadyBeenInMenu = true;
			}
			skippedIntro = true;
		}
	}
	
	function changeSel(by:Int = 0, volume:Float = 1)
	{
		/*
			Changes Selection by the amount of by Yeah you know what this does
			- IF THE BY IS SET TO 0, THEN IT WILL NOT MAKE A NOISE
		 */
		FlxG.sound.play(Paths.sound('scrollMenu'), volume);
		if (by != 0)
		{
			if (curSel > 2)
			{
				if (by > 0) curSel = 0;
				else curSel = 2;
			}
			else curSel += by;
		}
		if (curSel > boundaries) curSel = 0;
		if (curSel < 0) curSel = boundaries;
		// trace(curSel);
		opts.forEach(function(spr:FlxSprite) {
			spr.animation.curAnim.curFrame = (curSel == spr.ID ? 1 : 0);
		});
	}
}
