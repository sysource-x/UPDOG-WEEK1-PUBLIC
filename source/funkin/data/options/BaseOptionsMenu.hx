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
import funkin.data.*;
import funkin.states.*;
import funkin.states.substates.*;
import funkin.objects.*;
import funkin.backend.MusicBeatSubstate;

using StringTools;

class BaseOptionsMenu extends MusicBeatSubstate
{
	public var curOption:Option = null;
	public var curSelected:Int = 0;
	public var optionsArray:Array<Option>;

	public var grpOptions:FlxTypedGroup<FlxText>;
	public var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	public var grpTexts:FlxTypedGroup<FlxText>;

	public var boyfriend:Character = null;
	public var descText:FlxText;

	public var title:String;
	public var rpcTitle:String;

	public function new()
	{
		super();

		if (title == null) title = 'Options';
		if (rpcTitle == null) rpcTitle = 'Options Menu';

		#if desktop
		DiscordClient.changePresence(rpcTitle, null);
		#end

		setUpScript('Options');
		setOnScript('this', this);
		setOnScript('title', title);
		trace('options substate stuff whatever');

		// avoids lagspikes while scrolling through menus!
		grpOptions = new FlxTypedGroup<FlxText>();
		add(grpOptions);

		grpTexts = new FlxTypedGroup<FlxText>();
		add(grpTexts);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);


		var titleText:FlxText = new FlxText(500,106,0,title);
		titleText.setFormat(Paths.font("bahn.ttf"), 25, 0xFFFFFF, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.antialiasing = ClientPrefs.globalAntialiasing;
		add(titleText);

		descText = new FlxText(500,630,640,'Ghost Tapping is an overall bad option and you should');
		descText.setFormat(Paths.font("bahn.ttf"), 25, 0xFFFFFF, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.borderSize = 1;
		descText.y = 630 - descText.height;
		descText.antialiasing = ClientPrefs.globalAntialiasing;
		add(descText);

		for (i in 0...optionsArray.length)
		{
			trace('opp');
			var optionText:FlxText = new FlxText(0, 160+(30 * i), -1, optionsArray[i].name);
			optionText.setFormat(Paths.font("bahn.ttf"), 25, 0xFFFFFF, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			optionText.borderSize = 1;
			optionText.ID = i;
			optionText.antialiasing = ClientPrefs.globalAntialiasing;
			optionText.x += 500;
			/*optionText.forceX = 300;
				optionText.yMult = 90; */
			grpOptions.add(optionText);

			if (optionsArray[i].type == 'bool')
			{
				trace('cb');
				var checkbox:CheckboxThingie = new CheckboxThingie(1140, optionText.y, optionsArray[i].getValue() == true);
				checkbox.x -= checkbox.width;
				checkbox.ID = i;
				checkboxGroup.add(checkbox);
			}
			else if (optionsArray[i].type != 'button' && optionsArray[i].type != 'label')
			{
				trace('bra');
				var valueText:FlxText = new FlxText(500,optionText.y, 640, optionsArray[i].getValue());// optionText.width + 60);
				valueText.setFormat(Paths.font("bahn.ttf"), 25, 0x62E0CF, FlxTextAlign.RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				//valueText.copyAlpha = true;
				valueText.ID = i;
				valueText.borderSize = 1;
				valueText.antialiasing = ClientPrefs.globalAntialiasing;
				grpTexts.add(valueText);
			}

			if (optionsArray[i].showBoyfriend && boyfriend == null)
			{
				reloadBoyfriend();
			}
			updateTextFrom(optionsArray[i]);
		}

		#if mobile
		addVirtualPad(FULL,A_B_X);
		#end

		changeSelection();
		reloadCheckboxes();

		setOnScript('grpOptions', grpOptions);
		setOnScript('grpTexts', grpTexts);
		setOnScript('checkboxGroup', checkboxGroup);
		setOnScript('titleText', titleText);
		setOnScript('descText', descText);
		callOnScript('onCreatePost', []);
	}

	public function addOption(option:Option)
	{
		if (optionsArray == null || optionsArray.length < 1) optionsArray = [];
		optionsArray.push(option);
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	override function update(elapsed:Float)
	{
		if (controls.UI_UP_P #if mobile || _virtualpad.buttonUp.justPressed #end)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P #if mobile || _virtualpad.buttonDown.justPressed #end)
		{
			changeSelection(1);
		}

		if (controls.BACK #if mobile || _virtualpad.buttonB.justPressed #end)
		{
		    	ClientPrefs.saveSettings();
			#if mobile
 			closeSs();
 			#else
 			close();
 			#end
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if (nextAccept <= 0)
		{
			var usesCheckbox = true;
			if (curOption.type != 'bool')
			{
				usesCheckbox = false;
			}

			if (usesCheckbox)
			{
				if (controls.ACCEPT #if mobile || _virtualpad.buttonA.justPressed #end)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					curOption.setValue((curOption.getValue() == true) ? false : true);
					curOption.change();
					reloadCheckboxes();
				}
			}
			else if (curOption.type == 'button')
			{
				if (controls.ACCEPT #if mobile || _virtualpad.buttonA.justPressed #end) curOption.callback();
			}
			else if (curOption.type != 'label')
			{
				if (controls.UI_LEFT || controls.UI_RIGHT #if mobile || _virtualpad.buttonLeft.pressed || _virtualpad.buttonRight.pressed #end)
				{
					var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P #if mobile || _virtualpad.buttonLeft.justPressed || _virtualpad.buttonRight.justPressed #end);
					if (holdTime > 0.5 || pressed)
					{
						if (pressed)
						{
							var add:Dynamic = null;
							if (curOption.type != 'string')
							{
								add = controls.UI_LEFT #if mobile || _virtualpad.buttonLeft.pressed #end ? -curOption.changeValue : curOption.changeValue;
							}

							switch (curOption.type)
							{
								case 'int' | 'float' | 'percent':
									holdValue = curOption.getValue() + add;
									if (holdValue < curOption.minValue) holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

									switch (curOption.type)
									{
										case 'int':
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);

										case 'float' | 'percent':
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
									}
									reloadCheckboxes();

								case 'string':
									var num:Int = curOption.curOption; // lol
									if (controls.UI_LEFT_P #if mobile || _virtualpad.buttonLeft.justPressed #end) --num;
									else num++;

									if (num < 0)
									{
										num = curOption.options.length - 1;
									}
									else if (num >= curOption.options.length)
									{
										num = 0;
									}

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]); // lol
									reloadCheckboxes();
									// trace(curOption.options[num]);
							}
							updateTextFrom(curOption);
							curOption.change();
							FlxG.sound.play(Paths.sound('scrollMenu'));
						}
						else if (curOption.type != 'string')
						{
							holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT #if mobile || _virtualpad.buttonLeft.justPressed #end ? -1 : 1);
							if (holdValue < curOption.minValue) holdValue = curOption.minValue;
							else if (holdValue > curOption.maxValue) holdValue = curOption.maxValue;

							switch (curOption.type)
							{
								case 'int':
									curOption.setValue(Math.round(holdValue));

								case 'float' | 'percent':
									curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));
							}
							updateTextFrom(curOption);
							reloadCheckboxes();
							curOption.change();
						}
					}

					if (curOption.type != 'string')
					{
						holdTime += elapsed;
					}
				}
				else if (controls.UI_LEFT_R || controls.UI_RIGHT_R #if mobile || _virtualpad.buttonLeft.justReleased || _virtualpad.buttonRight.justReleased #end)
				{
					clearHold();
				}
			}

			if (controls.RESET #if mobile || _virtualpad.buttonX.justPressed #end)
			{
				for (i in 0...optionsArray.length)
				{
					var leOption:Option = optionsArray[i];
					if (leOption.type != 'button' && leOption.type != 'label')
					{
						leOption.setValue(leOption.defaultValue);
						if (leOption.type != 'bool')
						{
							if (leOption.type == 'string')
							{
								leOption.curOption = leOption.options.indexOf(leOption.getValue());
							}
							updateTextFrom(leOption);
						}
						leOption.change();
					}
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}

		if (boyfriend != null && boyfriend.animation.curAnim.finished)
		{
			boyfriend.dance();
		}

		if (nextAccept > 0)
		{
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function updateTextFrom(option:Option)
	{
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();
		if (option.type == 'percent') val *= 100;
		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold()
	{
		if (holdTime > 0.5)
		{
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		holdTime = 0;
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;
		if (curSelected < 0) curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length) curSelected = 0;
		
		descText.text = optionsArray[curSelected].description;
		descText.y = 630 - descText.height;

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			

			item.alpha = 0.6;
			if(curSelected == item.ID)
			{
				item.alpha = 1;
			}
		}
		for (text in grpTexts)
		{
			text.alpha = 0.6;
			if (text.ID == curSelected)
			{
				text.alpha = 1;
			}
		}


		if (boyfriend != null)
		{
			boyfriend.visible = optionsArray[curSelected].showBoyfriend;
		}
		curOption = optionsArray[curSelected]; // shorter lol
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	public function reloadBoyfriend()
	{
		var wasVisible:Bool = false;
		if (boyfriend != null)
		{
			wasVisible = boyfriend.visible;
			boyfriend.kill();
			remove(boyfriend);
			boyfriend.destroy();
		}

		boyfriend = new Character(800, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		insert(1, boyfriend);
		boyfriend.visible = wasVisible;
	}

	function reloadCheckboxes()
	{
		for (checkbox in checkboxGroup)
		{
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
		}
		for (i in grpTexts) {
			var yea:String;
			if (Std.isOfType(optionsArray[i.ID].getValue(), Bool)) {
				yea = (optionsArray[i.ID].getValue() ? 'ON' : 'OFF');
			} else yea = optionsArray[i.ID].getValue();
			i.text = yea;
		}
	}
}
