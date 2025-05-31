package funkin.states;

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
		// SELECTING A STATE
		FlxTransitionableState.skipNextTransIn = false;
		FlxTransitionableState.skipNextTransOut = false;
		
		final nextState:Null<NextState> = switch (curSel)
		{
			case 0: () -> new StoryMenuState();
			case 1: () -> new funkin.states.FreeplayState();
			case 2: () -> {
					OptionsState.onPlayState = false;
					return new funkin.data.options.OptionsState();
				}
			default: null;
		}
		
		if (nextState != null)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			FlxTimer.wait(0.5, FlxG.switchState.bind(nextState));
		}
		else
		{
			FlxG.sound.play(Paths.sound('locked'));
			FlxG.camera.shake(0.003, 0.1, null, true, FlxAxes.XY);
			return;
		}
		
		canSelect = false;
		
		// WHEN ITS NOT SELECTED, MAKE BOTH ALPHA GAY
		opts.forEach(function(spr:FlxSprite) {
			if (curSel != spr.ID) FlxTween.tween(spr, {alpha: 0.25}, 0.5, {ease: FlxEase.quadOut});
		});
		ott.forEach(function(spr:FlxText) {
			if (curSel != spr.ID) FlxTween.tween(spr, {alpha: 0.25}, 0.5, {ease: FlxEase.quadOut});
		});
		
		// move the scroll instead of everything
		FlxTween.tween(FlxG.camera, {'scroll.y': -700}, 1, {ease: FlxEase.quadIn});
	}
	
	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		
		#if LUA_ALLOWED
		Paths.pushGlobalMods();
		#end
		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();
		
		checkPreviousVers();
		
		super.create();
		
		if (!initialized)
		{
			if (FlxG.save.data != null && FlxG.save.data.fullscreen)
			{
				FlxG.fullscreen = FlxG.save.data.fullscreen;
			}
			persistentUpdate = true;
			persistentDraw = true;
		}
		initialized = true;
		
		if (FlxG.save.data.startedUp == null) // && !FlashingState.leftState)
		{
			
			trace('No save data detected, moving to FlashingState');
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.switchState(new FlashingState());
		}
		else
		{
			if (initialized) startIntro();
			else
			{
				new FlxTimer().start(1, function(tmr:FlxTimer) {
					startIntro();
				});
			}
		}
	}
	
	public function startIntro()
	{
		if (!initialized)
		{
			if (FlxG.sound.music == null)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxG.sound.music.fadeIn(4, 0, 0.7);
			}
		}
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menu", null);
		#end
		
		var versionString = 'VS IMPOSTOR WEEK 1';
		canSelect = true;
		
		opts = new FlxTypedGroup<FlxSprite>(); // GROUP ON GOD!
		ott = new FlxTypedGroup<FlxText>(); // GROUP ON GOD!
		
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
		
		snowEmitter = new SnowEmitter(200, -100, FlxG.width + 200);
		snowEmitter.scale.set(0.5);
		snowEmitter.start(false, 0.05);
		snowEmitter.scrollFactor.x.set(0.8, 0.8);
		snowEmitter.scrollFactor.y.set(0.8, 0.8);
		
		final snowAlpha = alreadyBeenInMenu ? 1 : 0;
		
		snowEmitter.alpha.set(snowAlpha);
		
		tv = new FlxSprite(1100, 450);
		tv.frames = Paths.getSparrowAtlas("menu/main/tv");
		tv.animation.addByPrefix('idle', 'TVIDLE', 24, false);
		tv.animation.addByPrefix('on', 'TVON', 24, false);
		tv.alpha = 0;
		tv.scale.set(1, 1);
		tv.scrollFactor.set(1, 1);
		tv.antialiasing = ClientPrefs.globalAntialiasing;
		
		// Logo, probably make it a real sprite for later
		lg = new FlxSprite(27, 82).loadGraphic(Paths.image('menu/main/Logo'));
		lg.screenCenter();
		lg.scrollFactor.set();
		
		// Black bars, scaled them up ingame because It's black bars I dont think they need to be 1280x720
		var bb:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menu/common/blackbars'));
		bb.scale.set(2, 2);
		bb.updateHitbox();
		bb.scrollFactor.set();
		
		// Control panel thing
		ct = new FlxSprite(42.15, 668.3 + 100).loadGraphic(Paths.image('menu/common/controls'));
		ct.scrollFactor.set();
		
		lt = new FlxText(0, 715, 1280, 'Press Enter to Start');
		lt.setFormat(Paths.font("bahn.ttf"), 25, 0xFFFFFF, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		lt.y -= lt.height;
		lt.borderSize = 2.5;
		lt.antialiasing = ClientPrefs.globalAntialiasing;
		lt.scrollFactor.set();
		
		// This does not optimize anything.
		
		for (i in [bg, bb, lg, ct])
		{
			add(i);
			i.antialiasing = ClientPrefs.globalAntialiasing;
		}
		add(lt);
		bg.antialiasing = false;
		
		insert(members.indexOf(bb), snowEmitter);
		
		zared = new FlxSprite().loadGraphic(Paths.image('menu/secret/zared'));
		zared.antialiasing = ClientPrefs.globalAntialiasing;
		zared.scrollFactor.set();
		
		// Color swap/grayscale, remove in V2.
		colorSwap = new ColorSwap();
		colorSwap.saturation = -1;
		
		var versionText:FlxText = new FlxText(0, (alreadyBeenInMenu ? 0 : -70), 1280, versionString);
		versionText.setFormat(Paths.font("bahn.ttf"), 25, FlxColor.WHITE, FlxTextAlign.CENTER);
		add(versionText);
		versionText.antialiasing = ClientPrefs.globalAntialiasing;
		versionText.scrollFactor.set();
		
		if (PLAYED_V3 || PLAYED_V4) // add trophy
		{
			var anim = PLAYED_V3 ? PLAYED_V4 ? 'v3-4' : 'v3' : 'v4';
			
			trophy = new FlxSprite().loadFromSheet('menu/main/trophy', anim, 0);
			trophy.scrollFactor.set();
			trophy.antialiasing = ClientPrefs.globalAntialiasing;
			
			trophy.scale.scale(0.4);
			trophy.updateHitbox();
			
			trophy.x = (27 + (lg.width - trophy.width) / 2);
			trophy.y = (82 - trophy.height) + 30 + (alreadyBeenInMenu ? 0 : -200);
			insert(members.indexOf(lg), trophy);
		}
		
		add(opts);
		add(ott);
		
		for (i in 0...5)
		{
			var but:FlxSprite = new FlxSprite(buttons[i][0] - (alreadyBeenInMenu ? 0 : 500), buttons[i][1]).loadFromSheet('menu/main/menubuttons', 'button' + buttons[i][2], 0);
			but.antialiasing = ClientPrefs.globalAntialiasing;
			but.ID = i;
			//  It's not letting me do it the normal and not stupid way
			var txt:FlxText = new FlxText(buttons[i][0] + (i > 2 ? 0 : 9.4) - (alreadyBeenInMenu ? 0 : 500), buttons[i][1] + 11.35, (i > 2 ? 113 : -1), buttons[i][3]);
			txt.setFormat(Paths.font("notosans.ttf"), 35, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			if (i > 2)
			{ // UGH
				txt.setFormat(Paths.font("notosans.ttf"), 35, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				txt.y += but.height;
				if (v2Check)
				{
					but.shader = colorSwap.shader;
					txt.color = 0x393939;
					but.color = 0x393939;
				}
			}
			txt.borderSize = 2.5;
			txt.ID = i;
			txt.antialiasing = ClientPrefs.globalAntialiasing;
			opts.add(but);
			ott.add(txt);
			
			but.scrollFactor.set();
			txt.scrollFactor.set();
		}
		// trace(opts);
		changeSel(0, 0);
		if (!alreadyBeenInMenu)
		{
			trace('snow here');
			// WHEN TRANSITIONING FROM TITLESTATE
			FlxTween.tween(versionText, {y: 0}, 1, {ease: FlxEase.quadOut});
		}
		else
		{
			moveShitUp(0.01);
			trace('fuck');
		}
		
		persistentUpdate = true;
		skipIntro();
		
		callOnScript('onCreatePost', []);
	}
	
	public static var transitioning:Bool = false;
	
	override function update(elapsed:Float)
	{
		if (FlxG.save.data.startedUp == null) {super.update(elapsed); return;}
		if (starFG != null)
		{
			starFG.x -= 0.12 * 60 * elapsed;
		}
		if (starBG != null)
		{
			starBG.x -= 0.04 * 60 * elapsed;
		}
		
		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;
		
		if (isHardcodedState())
		{
			#if mobile
			for (touch in FlxG.touches.list)
			{
				if (touch.justPressed)
				{
					pressedEnter = true;
				}
			}
			#end
			
			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
			
			if (gamepad != null)
			{
				if (gamepad.justPressed.START) pressedEnter = true;
				
				#if switch
				if (gamepad.justPressed.B) pressedEnter = true;
				#end
			}
			
			// EASTER EGG
			
			// IF CAN PRESS ON THING
			if (transitioning)
			{
				#if mobile
				if (_virtualpad == null) {
					addVirtualPad(FULL, A_B);
				}
				#end
				if (FlxG.mouse.justPressed && members.indexOf(tv) != -1 && tv.overlapsPoint(FlxG.mouse.getWorldPosition()))
				{
					tv.animation.play('on');
					tv.x += -115;
					tv.y += -80;
					
					FlxG.sound.play(Paths.sound('secret'));
					new FlxTimer().start(1.4, function(tmr:FlxTimer) {
						PlayState.storyDifficulty = 1;
						PlayState.isStoryMode = false;
						PlayState.SONG = Song.loadFromJson('bananas', 'bananas');
						FlxG.switchState(new PlayState());
						FlxG.mouse.visible = false;
					});
				}
				
				final finalKey:FlxKey = FlxG.keys.firstJustPressed();
				
				if (finalKey != -1)
				{
					keyTimer = 1;
					lastKeysPressed.push(finalKey);
					
					inline function checkForMatch(arra:Array<Int>):Bool
					{
						var matched:Bool = true;
						
						if (arra.length == 0) return false;
						
						for (k => i in arra)
						{
							if (lastKeysPressed[k] != i)
							{
								matched = false;
							}
						}
						
						return matched;
					}
					
					if (checkForMatch(secretKey)) // dk
					{
						doSecretAction();
						
						secretKey = []; // prevents from doing multiple times
					}
					
					if (checkForMatch([FlxKey.Z, FlxKey.A, FlxKey.R, FlxKey.E, FlxKey.D]) && members.indexOf(zared) == -1)
					{
						add(zared);
						zared.screenCenter(); // Center the zared sprite on the screen
						new FlxTimer().start(1, (_) -> openfl.system.System.exit(0));
						FlxG.sound.play(Paths.sound('loud'));
					}
				}
				
				if (keyTimer > 0)
				{
					keyTimer -= elapsed;
				}
				
				if (keyTimer <= 0)
				{
					lastKeysPressed.resize(0);
				}
				
				if (canSelect)
				{
					if (controls.UI_DOWN_P #if mobile || _virtualpad.buttonDown.justPressed #end)
					{
						changeSel(1, 1);
					}
					if (controls.UI_UP_P #if mobile || _virtualpad.buttonUp.justPressed #end)
					{
						changeSel(-1, 1);
					}
					if (controls.UI_RIGHT_P #if mobile || _virtualpad.buttonRight.justPressed #end)
					{
						if (curSel == 3)
						{
							curSel = 4;
							changeSel(0, 1);
						}
					}
					if (controls.UI_LEFT_P #if mobile || _virtualpad.buttonLeft.justPressed #end)
					{
						if (curSel == 4)
						{
							curSel = 3;
							changeSel(0, 1);
						}
					}
					if (controls.ACCEPT #if mobile || _virtualpad.buttonA.justPressed #end)
					{
						selectedOption();
					}
					if (_virtualpad.buttonB.justPressed && !secretTriggered)
					{
					    doSecretAction();
					    secretTriggered = true;
					}
				}
			}
			if (initialized && !transitioning && skippedIntro)
			{
				if (pressedEnter && callOnScript('onEnter', []) != Globals.Function_Stop)
				{
					FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
					moveShitUp();
					transitioning = true;
					
					opts.forEach(function(spr:FlxSprite) {
						FlxTween.tween(spr, {x: buttons[spr.ID][0]}, 1, {ease: FlxEase.quadOut, startDelay: spr.ID / 6});
					});
					ott.forEach(function(spr:FlxText) {
						FlxTween.tween(spr, {x: buttons[spr.ID][0] + (spr.ID > 2 ? 0 : 9.4)}, 1, {ease: FlxEase.quadOut, startDelay: spr.ID / 6});
					});
					// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
					#if mobile
					addVirtualPad(FULL,A_B);
					#end
				}
			}
		}
		
		super.update(elapsed);
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
