package funkin.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.objects.shader.*;
import funkin.data.*;
import funkin.states.*;

// TODO:
// - Make the individual animations work
// - have change how offsets work bc the way they work rn for this is temporary and ass
// this is unused but dont delete this bc we are moving them from the script to here next update

class NoteSustainCover extends FlxSprite
{
	public static var handler:NoteSkinHelper;
	public static var keys:Int = 4;

	public var colorSwap:HSLColorSwap = null;

	private var idleAnim:String;
	private var textureLoaded:String = null;

	public var data:Int = 0;
	public var parentNote:Note = null;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0)
	{
		super(x, y);

		var skin:String = 'noteHoldCovers';

		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		loadAnims(skin);

		colorSwap = new HSLColorSwap();
		shader = colorSwap.shader;

		setupNoteCover(x, y, note);
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function setupNoteCover(x:Float, y:Float, note:Int = 0, texture:String = null, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0, ?field:PlayField, ?parentNote:Note)
	{
		// scale.set(1, 1);
		if (field != null) setPosition(x - field.members[note].swagWidth * 0.95, y - field.members[note].swagWidth * 0.95);
		else setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		
		if (parentNote != null) this.parentNote = parentNote;

		if (texture == null)
		{
			texture = 'noteHoldCovers';
			//if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) texture = PlayState.SONG.splashSkin;
		}

		if (textureLoaded != texture)
		{
			loadAnims(texture);
		}
		if (field != null)
		{
			scale.x *= field.scale;
			scale.y *= field.scale;
		}
		data = note;
		switch (texture)
		{
			default:
				// alpha = 0.6;
				alpha = 1;
				antialiasing = true;
				colorSwap.hue = hueColor;
				colorSwap.saturation = satColor;
				colorSwap.lightness = brtColor;
				animation.play('note' + note + 'start', true);
				//trace('note' + note + 'loop');
				//offset.set(-20, -20);
				// animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
		}
	}

	override public function update(elapsed:Float)
	{
		if(parentNote != null)
		{
			trace('test');
		}
	}

	function loadAnims(skin:String)
	{
		frames = Paths.getSparrowAtlas(skin);
		switch (skin)
		{
			default:
				for (note in 0...keys)
				{
					for (i in 0...handler.data.noteCoverAnimations[note].length)
					{
						animation.addByPrefix(handler.data.noteCoverAnimations[note][i].anim, handler.data.noteCoverAnimations[note][i].xmlName);
					}
				}
		}
	}
}
