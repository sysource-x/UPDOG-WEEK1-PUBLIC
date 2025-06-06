package funkin.states.substates;

import funkin.data.options.ControlsSubState;
import funkin.objects.AttachedText;
import funkin.objects.CheckboxThingie;
import funkin.objects.Alphabet;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import funkin.backend.MusicBeatSubstate;
import funkin.data.options.ControlsSubState.ControlText;
import funkin.data.options.ControlsSubState.AttachedControlText;
import mobile.scripting.NativeAPI;

//finish this tmr
class GameplayChangersSubstate extends MusicBeatSubstate
{
	private var curOption:GameplayOption = null;
	private var curSelected:Int = 0;
	private var optionsArray:Array<Dynamic> = [];

	private var grpOptions:FlxTypedGroup<ControlText>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedControlText>;

	function getOptions()
	{
		var goption:GameplayOption = new GameplayOption('Scroll Type', 'scrolltype', 'string', 'Multiplicative', ["Multiplicative", "Constant"]);
		optionsArray.push(goption);

		var option:GameplayOption = new GameplayOption('Scroll Speed', 'scrollspeed', 'float', 1);
		option.scrollSpeed = 1.5;
		option.minValue = 0.5;
		option.changeValue = 0.1;
		if (goption.getValue().toLowerCase() != "constant")
		{
			option.displayFormat = '%vX';
			option.maxValue = 3;
		}
		else
		{
			option.displayFormat = "%v";
			option.maxValue = 6;
		}
		optionsArray.push(option);

		/*var option:GameplayOption = new GameplayOption('Playback Rate', 'songspeed', 'float', 1);
			option.scrollSpeed = 1;
			option.minValue = 0.5;
			option.maxValue = 2.5;
			option.changeValue = 0.1;
			option.displayFormat = '%vX';
			optionsArray.push(option); */

		var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthgain', 'float', 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthloss', 'float', 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0.5;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Instakill on Miss', 'instakill', 'bool', false);
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Practice Mode', 'practice', 'bool', false);
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Botplay', 'botplay', 'bool', false);
		optionsArray.push(option);
	}

	public function getOptionByName(name:String)
	{
		for (i in optionsArray)
		{
			var opt:GameplayOption = i;
			if (opt.name == name) return opt;
		}
		return null;
	}

	var phone:FlxSprite;

	public function new()
	{
		try {
			super();

			var bg:FlxSprite = new FlxSprite().makeScaledGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			bg.alpha = 0.6;
			add(bg);

			phone = new FlxSprite(Paths.image('menu/freeplay/phone'));
			phone.antialiasing = ClientPrefs.globalAntialiasing;
			add(phone);
			phone.screenCenter();

			// avoids lagspikes while scrolling through menus!
			grpOptions = new FlxTypedGroup<ControlText>();
			add(grpOptions);

			grpTexts = new FlxTypedGroup<AttachedControlText>();
			add(grpTexts);

			checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
			add(checkboxGroup);

			getOptions();

			for (i in 0...optionsArray.length)
			{
				var optionText:ControlText = new ControlText(phone.x + 34, 70 * i, optionsArray[i].name);
				optionText.forceX = optionText.x;
				// optionText.isMenuItem = true;
				optionText.yAdd = -(FlxG.height * 0.48) + phone.y + (74 * 2);
				optionText.xAdd = 120;
				optionText.yMult = 30;
				optionText.targetY = i;
				optionText.antialiasing = ClientPrefs.globalAntialiasing;
				grpOptions.add(optionText);

				optionText.snap();

				if (optionsArray[i].type == 'bool')
				{
					var checkbox:CheckboxThingie = new CheckboxThingie(phone.x + phone.width - 34, optionText.y, optionsArray[i].getValue() == true);
					checkbox.x -= checkbox.width;
					// checkbox.sprTracker = optionText;
					// checkbox.offsetY = -22;
					checkbox.ID = i;
					checkboxGroup.add(checkbox);

				}
				else
				{
					var valueText:AttachedControlText = new AttachedControlText('' + optionsArray[i].getValue(), phone.x + phone.width - 34);
					valueText.x = phone.x + phone.width - 34 - valueText.width;
					valueText.y = optionText.y;
					valueText.antialiasing = ClientPrefs.globalAntialiasing;
					// valueText.sprTracker = optionText;
					// valueText.copyAlpha = true;
					valueText.ID = i;
					grpTexts.add(valueText);
					optionsArray[i].setChild(valueText);
				}
				updateTextFrom(optionsArray[i]);
			}

			#if mobile
			addVirtualPad(FULL,A_B_X);
			#end

			changeSelection();
			reloadCheckboxes();
		} catch (e:Dynamic) {
			NativeAPI.showMessageBox("GameplayChangersSubstate Error", "An error occurred while opening the gameplay options:\n" + Std.string(e));
		}
	}

	var nextAccept:Int = 5;
	var holdTime:Float = 0;
	var holdValue:Float = 0;

	override function update(elapsed:Float)
	{
		try {
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
				#if mobile
				closeSs();
				#else
				close();
				#end
				ClientPrefs.saveSettings();
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
				else
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

									case 'string':
										var num:Int = curOption.curOption;
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
										curOption.setValue(curOption.options[num]);

										if (curOption.name == "Scroll Type")
										{
											var oOption:GameplayOption = getOptionByName("Scroll Speed");
											if (oOption != null)
											{
												if (curOption.getValue().toLowerCase() == "constant")
												{
													oOption.displayFormat = "%v";
													oOption.maxValue = 6;
												}
												else
												{
													oOption.displayFormat = "%vX";
													oOption.maxValue = 3;
													if (oOption.getValue() > 3) oOption.setValue(3);
												}
												updateTextFrom(oOption);
											}
										}
							}
							updateTextFrom(curOption);
							curOption.change();
							FlxG.sound.play(Paths.sound('scrollMenu'));
						}
						else if (curOption.type != 'string')
						{
							holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT #if mobile || _virtualpad.buttonLeft.pressed #end ? -1 : 1);
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
					var leOption:GameplayOption = optionsArray[i];
					leOption.setValue(leOption.defaultValue);
					if (leOption.type != 'bool')
					{
						if (leOption.type == 'string')
						{
							leOption.curOption = leOption.options.indexOf(leOption.getValue());
						}
						updateTextFrom(leOption);
					}

					if (leOption.name == 'Scroll Speed')
					{
						leOption.displayFormat = "%vX";
						leOption.maxValue = 3;
						if (leOption.getValue() > 3)
						{
							leOption.setValue(3);
						}
						updateTextFrom(leOption);
					}
					leOption.change();
				}
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadCheckboxes();
			}
		}
		} catch (e:Dynamic) {
			NativeAPI.showMessageBox("GameplayChangersSubstate Error", "An error occurred during gameplay options update:\n" + Std.string(e));
		}

		if (nextAccept > 0)
		{
			nextAccept -= 1;
		}
		super.update(elapsed);


		for (i in grpTexts)
		{
			i.x = phone.x + phone.width - 34 - i.width;
		}
	}

	function updateTextFrom(option:GameplayOption)
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

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0)
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
		curOption = optionsArray[curSelected]; // shorter lol
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function reloadCheckboxes()
	{
		for (checkbox in checkboxGroup)
		{
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
		}
	}
}

class GameplayOption
{
	private var child:ControlText;

	public var text(get, set):String;
	public var onChange:Void->Void = null; // Pressed enter (on Bool type options) or pressed/held left/right (on other types)

	public var type(get, default):String = 'bool'; // bool, int (or integer), float (or fl), percent, string (or str)

	// Bool will use checkboxes
	// Everything else will use a text
	public var showBoyfriend:Bool = false;
	public var scrollSpeed:Float = 50; // Only works on int/float, defines how fast it scrolls per second while holding left/right

	private var variable:String = null; // Variable from ClientPrefs.hx's gameplaySettings

	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; // Don't change this
	public var options:Array<String> = null; // Only used in string type
	public var changeValue:Dynamic = 1; // Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; // Only used in int/float/percent type
	public var maxValue:Dynamic = null; // Only used in int/float/percent type
	public var decimals:Int = 1; // Only used in float/percent type

	public var displayFormat:String = '%v'; // How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var name:String = 'Unknown';

	public function new(name:String, variable:String, type:String = 'bool', defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null)
	{
		this.name = name;
		this.variable = variable;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if (defaultValue == 'null variable value')
		{
			switch (type)
			{
				case 'bool':
					defaultValue = false;
				case 'int' | 'float':
					defaultValue = 0;
				case 'percent':
					defaultValue = 1;
				case 'string':
					defaultValue = '';
					if (options.length > 0)
					{
						defaultValue = options[0];
					}
			}
		}

		if (getValue() == null)
		{
			setValue(defaultValue);
		}

		switch (type)
		{
			case 'string':
				var num:Int = options.indexOf(getValue());
				if (num > -1)
				{
					curOption = num;
				}

			case 'percent':
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;
		}
	}

	public function change()
	{
		// nothing lol
		if (onChange != null)
		{
			onChange();
		}
	}

	public function getValue():Dynamic
	{
		return ClientPrefs.gameplaySettings.get(variable);
	}

	public function setValue(value:Dynamic)
	{
		ClientPrefs.gameplaySettings.set(variable, value);
	}

	public function setChild(child:ControlText)
	{
		this.child = child;
	}

	private function get_text()
	{
		if (child != null)
		{
			return child.text;
		}
		return null;
	}

	private function set_text(newValue:String = '')
	{
		if (child != null)
		{
			child.text = (newValue);
		}
		return null;
	}

	private function get_type()
	{
		var newValue:String = 'bool';
		switch (type.toLowerCase().trim())
		{
			case 'int' | 'float' | 'percent' | 'string':
				newValue = type;
			case 'integer':
				newValue = 'int';
			case 'str':
				newValue = 'string';
			case 'fl':
				newValue = 'float';
		}
		type = newValue;
		return type;
	}
}
