package funkin.data.options;

import haxe.Json;

import lime.utils.Assets;

import openfl.text.TextField;

import flixel.math.FlxRect;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxRect;
import flixel.FlxSubState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;

import funkin.data.Controls;
import funkin.data.*;
import funkin.states.*;
import funkin.objects.*;
import funkin.states.substates.*;
import funkin.backend.InputFormatter;
import funkin.backend.MusicBeatSubstate;

class ControlsSubState extends MusicBeatSubstate
{
	private static var curSelected:Int = -1;
	private static var curAlt:Bool = false;
	
	private static var defaultKey:String = 'Reset to Default Keys';
	
	private var bindLength:Int = 0;
	
	var optionShit:Array<Dynamic> = [
		['NOTES'],
		['Left', 'note_left'],
		['Down', 'note_down'],
		['Up', 'note_up'],
		['Right', 'note_right'],
		[''],
		['UI'],
		['Left', 'ui_left'],
		['Down', 'ui_down'],
		['Up', 'ui_up'],
		['Right', 'ui_right'],
		[''],
		['Reset', 'reset'],
		['Accept', 'accept'],
		['Back', 'back'],
		['Pause', 'pause'],
		[''],
		['VOLUME'],
		['Mute', 'volume_mute'],
		['Up', 'volume_up'],
		['Down', 'volume_down'],
		[''],
		['DEBUG'],
		['Key 1', 'debug_1'],
		['Key 2', 'debug_2']
	];
	
	private var grpOptions:FlxTypedGroup<ControlText>;
	private var grpInputs:Array<AttachedControlText> = [];
	private var grpInputsAlt:Array<AttachedControlText> = [];
	var rebindingKey:Bool = false;
	var nextAccept:Int = 5;
	
	public function new()
	{
		super();
		
		// var meh:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		// meh.alpha = 0.5;
		// add(meh);
		
		grpOptions = new FlxTypedGroup<ControlText>();
		add(grpOptions);
		
		optionShit.push(['']);
		optionShit.push([defaultKey]);
		
		for (i in 0...optionShit.length)
		{
			var isCentered:Bool = false;
			var isDefaultKey:Bool = (optionShit[i][0] == defaultKey);
			if (unselectableCheck(i, true))
			{
				isCentered = true;
			}
			
			var optionText:ControlText = new ControlText(500, (10 * i), optionShit[i][0]);
			optionText.isMenuItem = true;
			if (isCentered)
			{
				// optionText.yAdd = -55;
			}
			
			optionText.forceX = optionText.x;
			
			optionText.yMult = 30;
			optionText.targetY = i;
			
			optionText.snap();
			grpOptions.add(optionText);
			
			if (!isCentered)
			{
				addBindTexts(optionText, i);
				bindLength++;
				if (curSelected < 0) curSelected = i;
			}
		}
		changeSelection();
		#if mobile
 		addVirtualPad(FULL,A_B);
 		#end
	}
	
	var leaving:Bool = false;
	var bindingTime:Float = 0;
	
	final topBound:Float = 80;
	final bottomBound:Float = 643;
	
	function bindTextToPhone(spr:FlxSprite) // probavbly sdhould be called clip
	{
		if (spr.clipRect == null) spr.clipRect = new FlxRect(0, 0, spr.width, spr.height);
		
		if (spr.y < topBound)
		{
			var yDiff = topBound - spr.y;
			
			spr.clipRect.set(0, yDiff, spr.width, spr.height - yDiff);
		}
		else if (spr.y + spr.height > bottomBound)
		{
			var yDiff = spr.y + spr.height - bottomBound;
			
			spr.clipRect.set(0, 0, spr.width, spr.height - yDiff);
		}
		else
		{
			spr.clipRect.set(0, 0, spr.width, spr.height);
		}
		
		spr.clipRect = spr.clipRect;
	}
	
	override function update(elapsed:Float)
	{			
		if (!rebindingKey)
		{
			if (controls.UI_UP_P #if mobile || _virtualpad.buttonUp.justPressed #end)
			{
				changeSelection(-1);
			}
			if (controls.UI_DOWN_P #if mobile || _virtualpad.buttonDown.justPressed #end)
			{
				changeSelection(1);
			}
			if (controls.UI_LEFT_P || controls.UI_RIGHT_P #if mobile || _virtualpad.buttonLeft.justPressed || _virtualpad.buttonRight.justPressed #end)
			{
				changeAlt();
			}
			
			if (controls.BACK #if mobile || _virtualpad.buttonB.justPressed #end)
			{
				ClientPrefs.reloadControls();
				#if mobile
 			        closeSs();
 			        #else
 			        close();
 			        #end
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			
			if (controls.ACCEPT #if mobile || _virtualpad.buttonA.justPressed #end && nextAccept <= 0)
			{
				if (optionShit[curSelected][0] == defaultKey)
				{
					ClientPrefs.keyBinds = ClientPrefs.defaultKeys.copy();
					reloadKeys();
					changeSelection();
					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
				else if (!unselectableCheck(curSelected))
				{
					bindingTime = 0;
					rebindingKey = true;
					if (curAlt)
					{
						grpInputsAlt[getInputTextNum()].alpha = 0;
					}
					else
					{
						grpInputs[getInputTextNum()].alpha = 0;
					}
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
			}
		}
		else
		{
			var keyPressed:Int = FlxG.keys.firstJustPressed();
			if (keyPressed > -1)
			{
				var keysArray:Array<FlxKey> = ClientPrefs.keyBinds.get(optionShit[curSelected][1]);
				keysArray[curAlt ? 1 : 0] = keyPressed;
				
				var opposite:Int = (curAlt ? 0 : 1);
				if (keysArray[opposite] == keysArray[1 - opposite])
				{
					keysArray[opposite] = NONE;
				}
				ClientPrefs.keyBinds.set(optionShit[curSelected][1], keysArray);
				
				reloadKeys();
				FlxG.sound.play(Paths.sound('confirmMenu'));
				rebindingKey = false;
			}
			
			bindingTime += elapsed;
			if (bindingTime > 5)
			{
				if (curAlt)
				{
					grpInputsAlt[curSelected].alpha = 1;
				}
				else
				{
					grpInputs[curSelected].alpha = 1;
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
				rebindingKey = false;
				bindingTime = 0;
			}
		}
		
		if (nextAccept > 0)
		{
			nextAccept -= 1;
		}
		super.update(elapsed);



		grpOptions.forEach(bindTextToPhone);
		for (i in grpInputs)
			bindTextToPhone(i);
		for (i in grpInputsAlt)
			bindTextToPhone(i);
	}
	
	function getInputTextNum()
	{
		var num:Int = 0;
		for (i in 0...curSelected)
		{
			if (optionShit[i].length > 1)
			{
				num++;
			}
		}
		return num;
	}
	
	function changeSelection(change:Int = 0)
	{
		do
		{
			curSelected += change;
			if (curSelected < 0) curSelected = optionShit.length - 1;
			if (curSelected >= optionShit.length) curSelected = 0;
		}
		while (unselectableCheck(curSelected));
		
		var bullShit:Int = 0;
		
		for (i in 0...grpInputs.length)
		{
			grpInputs[i].alpha = 0.6;
		}
		for (i in 0...grpInputsAlt.length)
		{
			grpInputsAlt[i].alpha = 0.6;
		}
		
		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;
			
			if (!unselectableCheck(bullShit - 1))
			{
				item.alpha = 0.6;
				if (item.targetY == 0)
				{
					item.alpha = 1;
					if (curAlt)
					{
						for (i in 0...grpInputsAlt.length)
						{
							if (grpInputsAlt[i].sprTracker == item)
							{
								grpInputsAlt[i].alpha = 1;
								break;
							}
						}
					}
					else
					{
						for (i in 0...grpInputs.length)
						{
							if (grpInputs[i].sprTracker == item)
							{
								grpInputs[i].alpha = 1;
								break;
							}
						}
					}
				}
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	
	function changeAlt()
	{
		curAlt = !curAlt;
		for (i in 0...grpInputs.length)
		{
			if (grpInputs[i].sprTracker == grpOptions.members[curSelected])
			{
				grpInputs[i].alpha = 0.6;
				if (!curAlt)
				{
					grpInputs[i].alpha = 1;
				}
				break;
			}
		}
		for (i in 0...grpInputsAlt.length)
		{
			if (grpInputsAlt[i].sprTracker == grpOptions.members[curSelected])
			{
				grpInputsAlt[i].alpha = 0.6;
				if (curAlt)
				{
					grpInputsAlt[i].alpha = 1;
				}
				break;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	
	private function unselectableCheck(num:Int, ?checkDefaultKey:Bool = false):Bool
	{
		if (optionShit[num][0] == defaultKey)
		{
			return checkDefaultKey;
		}
		return optionShit[num].length < 2 && optionShit[num][0] != defaultKey;
	}
	
	private function addBindTexts(optionText:ControlText, num:Int)
	{
		// 200 400 650
		var keys:Array<Dynamic> = ClientPrefs.keyBinds.get(optionShit[num][1]);
		var text1 = new AttachedControlText(InputFormatter.getKeyName(keys[0]), 200, 0);
		text1.setPosition(optionText.x + 400, optionText.y);
		text1.sprTracker = optionText;
		grpInputs.push(text1);
		add(text1);
		
		var text2 = new AttachedControlText(InputFormatter.getKeyName(keys[1]), 350, 0);
		text2.setPosition(optionText.x + 650, optionText.y);
		text2.sprTracker = optionText;
		grpInputsAlt.push(text2);
		add(text2);
	}
	
	function reloadKeys()
	{
		while (grpInputs.length > 0)
		{
			var item:AttachedControlText = grpInputs[0];
			item.kill();
			grpInputs.remove(item);
			item.destroy();
		}
		while (grpInputsAlt.length > 0)
		{
			var item:AttachedControlText = grpInputsAlt[0];
			item.kill();
			grpInputsAlt.remove(item);
			item.destroy();
		}
		
		trace('Reloaded keys: ' + ClientPrefs.keyBinds);
		
		for (i in 0...grpOptions.length)
		{
			if (!unselectableCheck(i, true))
			{
				addBindTexts(grpOptions.members[i], i);
			}
		}
		
		var bullShit:Int = 0;
		for (i in 0...grpInputs.length)
		{
			grpInputs[i].alpha = 0.6;
		}
		for (i in 0...grpInputsAlt.length)
		{
			grpInputsAlt[i].alpha = 0.6;
		}
		
		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;
			
			if (!unselectableCheck(bullShit - 1))
			{
				item.alpha = 0.6;
				if (item.targetY == 0)
				{
					item.alpha = 1;
					if (curAlt)
					{
						for (i in 0...grpInputsAlt.length)
						{
							if (grpInputsAlt[i].sprTracker == item)
							{
								grpInputsAlt[i].alpha = 1;
							}
						}
					}
					else
					{
						for (i in 0...grpInputs.length)
						{
							if (grpInputs[i].sprTracker == item)
							{
								grpInputs[i].alpha = 1;
							}
						}
					}
				}
			}
		}
	}
}

class ControlText extends FlxText // quick and easy
{
	public var forceX:Float = Math.NEGATIVE_INFINITY;
	public var targetY:Int = 0;
	public var yMult:Float = 120;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var isMenuItem:Bool = false;
	
	public function new(x:Float, y:Float, text:String)
	{
		super(x, y, 0, text, 25);
		
		this.setFormat(Paths.font("bahn.ttf"), 25, 0xFFFFFF, LEFT, OUTLINE, FlxColor.BLACK);
	}
	
	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);
			
			final lerpRate = FlxMath.getElapsedLerp(0.16, elapsed);
			
			y = FlxMath.lerp(y, (scaledY * yMult) + (FlxG.height * 0.48) + yAdd, lerpRate);
			if (forceX != Math.NEGATIVE_INFINITY)
			{
				x = forceX;
			}
			else
			{
				x = FlxMath.lerp(x, (targetY * 20) + 90 + xAdd, lerpRate);
			}
		}
		
		super.update(elapsed);
	}
	
	public function snap()
	{
		final scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);
		
		y = (scaledY * yMult) + (FlxG.height * 0.48) + yAdd;
	}
}

class AttachedControlText extends ControlText
{
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var sprTracker:FlxSprite;
	public var copyVisible:Bool = true;
	public var copyAlpha:Bool = false;

	
	
	public function new(text:String = "", ?offsetX:Float = 0, ?offsetY:Float = 0)
	{
		super(0, 0, text);
		isMenuItem = false;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
	}
	
	override function update(elapsed:Float)
	{
		if (sprTracker != null)
		{
			setPosition(sprTracker.x + offsetX, sprTracker.y + offsetY);
			if (copyVisible)
			{
				visible = sprTracker.visible;
			}
			if (copyAlpha)
			{
				alpha = sprTracker.alpha;
			}
		}
		
		super.update(elapsed);
	}
}
