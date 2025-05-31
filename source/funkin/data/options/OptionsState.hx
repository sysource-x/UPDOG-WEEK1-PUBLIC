package funkin.data.options;

import openfl.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import openfl.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import funkin.data.Controls;
import funkin.data.*;
import funkin.states.*;
import funkin.states.substates.*;
import funkin.objects.*;

using StringTools;

class OptionsState extends MusicBeatState
{

	public static var onPlayState:Bool = false;
	
	var ext:String = 'menu/options/';
	var opts:FlxTypedGroup<FlxSprite>;
	var boundaries:Int;
	var curSel:Int = 0;
	var boiText:FlxText;
	var boiText2:FlxText;
	var boiImage:FlxSprite;

	var buttons:Array<Dynamic> = [ // buttons! add translation later!
		// 106 + 75 + 75
		[116, 106, 0, 'Set Song Offset'],
		[116, 181, 1, 'Controls'],
		[116, 181+75, 1, 'Gameplay'],
		[116, 181+150, 1, 'Graphics'],
		[116, 181+225, 1, 'Misc'] // This game is like doing math, it hurts my brain !!
	];
	function changeSel(by = 0, silent = 1) {
		/*
			Changes Selection by the amount of by Yeah you know what this does
			- IF THE BY IS SET TO 0, THEN IT WILL NOT MAKE A NOISE
		*/
		FlxG.sound.play(Paths.sound('scrollMenu'), silent);
		curSel += by;
		if(curSel > boundaries - 1) curSel = 0;
		if(curSel < 0) curSel = boundaries - 1;
		trace(curSel);
		opts.forEach(function(spr:FlxSprite){
				spr.animation.curAnim.curFrame = (curSel == spr.ID ? 1 : 0);
		});
	}
	override function create()
	{
		#if desktop
		DiscordClient.changePresence("In the Options", null);
		#end

	
		var welcomeHereBruh:Array<String> = 
		['Vs Impostor v1.0.2',
		'in a good world this mods name is still updog'];
		boundaries = buttons.length;
		var notblack:FlxSprite = new FlxSprite(0,0).makeGraphic(FlxG.width,FlxG.height,0x06080C);
		add(notblack);

		opts = new FlxTypedGroup<FlxSprite>(); // GROUP ON GOD!

		var stars:FlxSprite = new FlxSprite(0,0).loadGraphic(Paths.image('stage/polus/stars'));
		stars.scale.set(0.5,0.5);
		stars.antialiasing = ClientPrefs.globalAntialiasing;
		stars.updateHitbox();
		add(stars);

		var bb:FlxSprite = new FlxSprite(0,0).loadGraphic(Paths.image('menu/common/blackbars'));
		bb.scale.set(2,2);
		bb.updateHitbox();
		add(bb);

		// Control panel thing
		var ct:FlxSprite = new FlxSprite(42.15, 668.3).loadGraphic(Paths.image('menu/common/controls'));
		ct.antialiasing = ClientPrefs.globalAntialiasing;
		add(ct);

		var phone:FlxSprite = new FlxSprite(79, 54).loadGraphic(Paths.image(ext + 'phone'));
		phone.antialiasing = ClientPrefs.globalAntialiasing;
		add(phone);
		// please come up with better variable names im begging bro
		boiText = new FlxText(500,110,640,welcomeHereBruh[0]);
		boiText.setFormat(Paths.font("bahn.ttf"), 50, 0xFFFFFF, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		boiText.borderSize = 1;
		boiText.y -= boiText.height/2;
		boiText.antialiasing = ClientPrefs.globalAntialiasing;
		add(boiText);

		boiImage = new FlxSprite(500, 150).loadGraphic(Paths.image(ext + 'red_art'));
		boiImage.antialiasing = ClientPrefs.globalAntialiasing;
		add(boiImage);

		boiText2 = new FlxText(500,510,640,welcomeHereBruh[1]);
		boiText2.setFormat(Paths.font("bahn.ttf"), 25, 0xFFFFFF, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		boiText2.borderSize = 1;
		boiText2.antialiasing = ClientPrefs.globalAntialiasing;
		add(boiText2);
		// MAKE BUTTONS
		add(opts);
		for(i in 0...buttons.length) {
			var but:FlxSprite = new FlxSprite(buttons[i][0], buttons[i][1]);
			but.frames = Paths.getSparrowAtlas('menu/common/blankbutton');
			but.animation.addByPrefix('idle', 'buttonFP instance 1', 0, false);
			but.animation.play('idle');
			but.antialiasing = ClientPrefs.globalAntialiasing;
			but.ID = i;
			//  It's not letting me do it the normal and not stupid way
			var txt:FlxText = new FlxText(buttons[i][0] + 9.4, buttons[i][1] + 11.35, -1, buttons[i][3]);
			txt.setFormat(Paths.font("notosans.ttf"), 35, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			txt.borderSize = 2.5;
			txt.ID = i;
			txt.antialiasing = ClientPrefs.globalAntialiasing;
			opts.add(but);
			add(txt);
		}
		changeSel(0, 0);
		ClientPrefs.saveSettings();

		#if mobile
		addVirtualPad(UP_DOWN, A_B);
		#end
		
		super.create();
	}
	function doItBruh() 
	{
		if(curSel >= 1) 
		{
			boiText.alpha = 0;
			boiImage.alpha = 0;
			boiText2.alpha = 0;
		}

		switch(curSel) {
			case 0:
				FlxG.switchState(new NoteOffsetState());
			case 1:
				openSubState(new ControlsSubState());
			case 2:
				openSubState(new GameplaySettingsSubState());
			case 3:
				openSubState(new GraphicsSettingsSubState());
			case 4:
				openSubState(new MiscSubState());
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		//if(FlxG.keys.justPressed.R) FlxG.resetState();
		if(controls.UI_DOWN_P #if mobile || _virtualpad.buttonDown.justPressed #end) {
			changeSel(1, 1);
		}
		if(controls.UI_UP_P #if mobile || _virtualpad.buttonUp.justPressed #end) {
			changeSel(-1, 1);
		}

		if(controls.ACCEPT #if mobile || _virtualpad.buttonA.justPressed #end) {
		   	_virtualpad.visible = false;
			doItBruh();
			//openSubState(new ControlsSubState());
		}
		if(controls.BACK #if mobile || _virtualpad.buttonB.justPressed #end) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else FlxG.switchState(new TitleState());
		}
		
	}
	override function closeSubState(){
		boiText.alpha = 1;
		boiImage.alpha = 1;
		boiText2.alpha = 1;

		super.closeSubState();
		ClientPrefs.saveSettings();
		#if mobile
		removeVirtualPad();
		addVirtualPad(UP_DOWN,A_B);
		#end
	}
}
