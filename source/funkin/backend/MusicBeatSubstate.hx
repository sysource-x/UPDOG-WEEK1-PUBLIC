package funkin.backend;

import funkin.backend.PlayerSettings;
import funkin.data.*;
import funkin.data.scripts.*;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}

	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls return PlayerSettings.player1.controls;

	public var scripted:Bool = false;
	public var scriptName:String = 'Placeholder';
	public var script:OverrideStateScript;

	public function setUpScript(s:String = 'Placeholder')
	{
		scripted = true;
		scriptName = s;

		var scriptFile = FunkinIris.getPath('scripts/menus/substates/$scriptName', false);

		if (FileSystem.exists(scriptFile))
		{
			script = OverrideStateScript.fromFile(scriptFile);
			trace('$scriptName script [$scriptFile] found!');
		}
		else
		{
			trace('$scriptName script [$scriptFile] is null!');
		}

		setOnScript('add', this.add);
		setOnScript('close', close);
		setOnScript('this', this);
		callOnScript('onCreate', []);
	}

	inline function isHardcodedState() return (script != null && !script.customMenu) || (script == null);

	inline function setOnScript(name:String, value:Dynamic)
	{
		if (script != null) script.set(name, value);
	}

	public function callOnScript(name:String, vars:Array<Any>, ignoreStops:Bool = false)
	{
		var returnVal:Dynamic = Globals.Function_Continue;
		if (script != null)
		{
			var ret:Dynamic = script.call(name, vars);
			if (ret == Globals.Function_Halt)
			{
				ret = returnVal;
				if (!ignoreStops) return returnVal;
			};

			if (ret != Globals.Function_Continue && ret != null) returnVal = ret;

			if (returnVal == null) returnVal = Globals.Function_Continue;
		}
		return returnVal;
	}

	#if mobile
 	var _virtualpad:FlxVirtualPad;
 
 	public function addVirtualPad(?DPad:FlxDPadMode, ?Action:FlxActionMode) {
 		_virtualpad = new FlxVirtualPad(DPad, Action);
 		add(_virtualpad);
 	}
 
     	public function addVirtualPadCamera() {
 		var virtualpadcam = new flixel.FlxCamera();
 		virtualpadcam.bgColor.alpha = 0;
 		FlxG.cameras.add(virtualpadcam, false);
 		_virtualpad.cameras = [virtualpadcam];
     	}
 
 	public function removeVirtualPad() {
 		remove(_virtualpad);
 	}
 	public function closeSs() {
 		FlxTransitionableState.skipNextTransOut = true;
 		FlxG.resetState();
 	}
 	#end

	override function destroy()
	{
		callOnScript('onDestroy', []);
		super.destroy();
	}

	override function update(elapsed:Float)
	{
		// everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0) stepHit();

		callOnScript('onUpdate', [elapsed]);

		super.update(elapsed);
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep / 4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrotchet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0) beatHit();
		callOnScript('onStepHit', [curStep]);
	}

	public function beatHit():Void
	{
		callOnScript('onBeatHit', [curBeat]);
	}
}
