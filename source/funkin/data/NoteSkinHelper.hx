package funkin.data;

import haxe.Json;
import haxe.format.JsonParser;
import funkin.objects.*;
import flixel.math.FlxPoint;

// havent implemented this
typedef Animation =
{
	?color:String, // used for playing the note animations. Fuck. this sucks
	?anim:String,
	?xmlName:String,

	?offsets:Array<Float>
}

typedef NoteSkinData =
{
	?globalSkin:String,
	?playerSkin:String,
	?opponentSkin:String,
	?extraSkin:String,
	?noteSplashSkin:String,
	?noteCoverSkin:String,
	?hasQuants:Bool,
	?isQuants:Bool
	,
	?isPixel:Bool,
	?pixelSize:Array<Int>,
	?antialiasing:Bool,
	?sustainSuffix:String,
	/*
		[
			{ anim: "idle", xmlName: "fuck", offsets: [x, y]},
			{ anim: "sustain", xmlName: "fuck", offsets: [x, y]},
			{ anim: "sustain end", xmlName: "fuck", offsets: [x, y]},
		]
	 */
	?noteAnimations:Array<Array<Animation>>,

	/*
		[
			{ anim: "idle", xmlName: "fuck", offsets: [x, y]},
			{ anim: "press", xmlName: "fuck", offsets: [x, y]},
			{ anim: "confirm", xmlName: "fuck", offsets: [x, y]},
		]
	 */
	?receptorAnimations:Array<Array<Animation>>,

	/*
		[

		]
	 */
	?noteSplashAnimations:Array<Animation>,

	?noteCoverAnimations:Array<Array<Animation>>,

	?singAnimations:Array<String>
}

class NoteSkinHelper
{
	static final defaultTexture:String = 'NOTE_assets';
	static final defaultSplashTexture:String = 'noteSplashes';
	static final defaultCoverTexture:String = 'noteHoldCovers';

	static final defaultNoteAnimations:Array<Array<Animation>> = [
		[
			{
				color: "purple",
				anim: "purpleScroll",
				xmlName: "purple",
				offsets: [0, 0]
			},
			{
				color: "purple",
				anim: "purplehold",
				xmlName: "purple hold piece",
				offsets: [0, 0]
			},
			{
				color: "purple",
				anim: 'purpleholdend',
				xmlName: 'pruple end hold',
				offsets: [0, 0]
			}
		],
		[
			{
				color: "blue",
				anim: "blueScroll",
				xmlName: "blue",
				offsets: [0, 0]
			},
			{
				color: "blue",
				anim: "bluehold",
				xmlName: "blue hold piece",
				offsets: [0, 0]
			},
			{
				color: "blue",
				anim: "blueholdend",
				xmlName: "blue hold end",
				offsets: [0, 0]
			}
		],
		[
			{
				color: "green",
				anim: "greenScroll",
				xmlName: "green",
				offsets: [0, 0]
			},
			{
				color: "green",
				anim: "greenhold",
				xmlName: "green hold piece",
				offsets: [0, 0]
			},
			{
				color: "green",
				anim: "greenholdend",
				xmlName: "green hold end",
				offsets: [0, 0]
			}
		],
		[
			{
				color: "red",
				anim: "redScroll",
				xmlName: "red",
				offsets: [0, 0]
			},
			{
				color: "red",
				anim: "redhold",
				xmlName: "red hold piece",
				offsets: [0, 0]
			},
			{
				color: "red",
				anim: "redholdend",
				xmlName: "red hold end",
				offsets: [0, 0]
			}
		]
	];
	static final defaultReceptorAnimations:Array<Array<Animation>> = [
		[
			{
				color: "",
				anim: 'static',
				xmlName: "arrowLEFT",
				offsets: [0, 0]
			},
			{
				color: "",
				anim: "pressed",
				xmlName: "left press",
				offsets: [0, 0]
			},
			{
				color: "",
				anim: "confirm",
				xmlName: "left confirm",
				offsets: [0, 0]
			}
		],
		[
			{
				color: "",
				anim: "static",
				xmlName: "arrowDOWN",
				offsets: [0, 0]
			},
			{
				color: "",
				anim: "pressed",
				xmlName: "down press",
				offsets: [0, 0]
			},
			{
				color: "",
				anim: "confirm",
				xmlName: "down confirm",
				offsets: [0, 0]
			}
		],
		[
			{
				color: "",
				anim: "static",
				xmlName: "arrowUP",
				offsets: [0, 0]
			},
			{
				color: "",
				anim: "pressed",
				xmlName: "up press",
				offsets: [0, 0]
			},
			{
				color: "",
				anim: "confirm",
				xmlName: "up confirm",
				offsets: [0, 0]
			}
		],
		[
			{
				color: "",
				anim: "static",
				xmlName: "arrowRIGHT",
				offsets: [0, 0]
			},
			{
				color: "",
				anim: "pressed",
				xmlName: "right press",
				offsets: [0, 0]
			},
			{
				color: "",
				anim: "confirm",
				xmlName: "right confirm",
				offsets: [0, 0]
			}
		]
	];
	static final defaultNoteSplashAnimations:Array<Animation> = [
		{anim: "note0", xmlName: "note splash purple", offsets: [0, 0]},
		{anim: "note1", xmlName: "note splash blue", offsets: [0, 0]},
		{anim: "note2", xmlName: "note splash green", offsets: [0, 0]},
		{anim: "note3", xmlName: "note splash red", offsets: [0, 0]}
	];
	static final defaultNoteCoverAnimations:Array<Array<Animation>> = [
		[{anim: "note0start", xmlName: "purplestart", offsets: [0, 0]},
		{anim: "note0loop", xmlName: "purpleloop", offsets: [0, 0]},
		{anim: "note0end", xmlName: "purpleend", offsets: [0, 0]}],

		[{anim: "note1start", xmlName: "bluestart", offsets: [0, 0]},
		{anim: "note1loop", xmlName: "blueloop", offsets: [0, 0]},
		{anim: "note1end", xmlName: "blueend", offsets: [0, 0]}],
		
		[{anim: "note2start", xmlName: "greenstart", offsets: [0, 0]},
		{anim: "note2loop", xmlName: "greenloop", offsets: [0, 0]},
		{anim: "note2end", xmlName: "greenend", offsets: [0, 0]}],

		[{anim: "note3start", xmlName: "redstart", offsets: [0, 0]},
		{anim: "note3loop", xmlName: "redloop", offsets: [0, 0]},
		{anim: "note3end", xmlName: "redend", offsets: [0, 0]}]
	];
	public static final fallbackReceptorAnims:Array<Animation> = [
		{
			color: "",
			anim: 'static',
			xmlName: "placeholder",
			offsets: [0, 0]
		},
		{
			color: "",
			anim: "pressed",
			xmlName: "placeholder",
			offsets: [0, 0]
		},
		{
			color: "",
			anim: "confirm",
			xmlName: "placeholder",
			offsets: [0, 0]
		}
	];

	static final defaultSingAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var data:NoteSkinData;

	public function new(path:String)
	{
		var rawJson = null;

		try
		{
			rawJson = File.getContent(path).trim();
			data = parseJSON(rawJson);
		}
		catch (e:Dynamic)
		{
			data = {};
			trace(e);
		}
		resolveData(data);
	}

	public static function resolveData(data:NoteSkinData)
	{
		if (data.globalSkin == null) data.globalSkin = defaultTexture;
		if (data.playerSkin == null) data.playerSkin = data.globalSkin;
		if (data.opponentSkin == null) data.opponentSkin = data.globalSkin;
		if (data.extraSkin == null) data.extraSkin = data.globalSkin;
		if (data.noteSplashSkin == null) data.noteSplashSkin = defaultSplashTexture;
		if (data.noteCoverSkin == null) data.noteCoverSkin = defaultCoverTexture;
		if (data.hasQuants == null) data.hasQuants = false;
		if (data.isQuants == null) data.isQuants = false;
		if (data.isPixel == null) data.isPixel = false;
		if (data.pixelSize == null) data.pixelSize = [4, 5];
		if (data.antialiasing == null) data.antialiasing = true;
		if (data.sustainSuffix == null) data.sustainSuffix = 'ENDS';
		if (data.noteAnimations == null) data.noteAnimations = defaultNoteAnimations;
		if (data.receptorAnimations == null) data.receptorAnimations = defaultReceptorAnimations;
		if (data.noteSplashAnimations == null) data.noteSplashAnimations = defaultNoteSplashAnimations;
		if (data.noteCoverAnimations == null) data.noteCoverAnimations = defaultNoteCoverAnimations;
		if (data.singAnimations == null) data.singAnimations = defaultSingAnimations;
	}

	public static function parseJSON(rawJson:String):NoteSkinData
	{
		var data:NoteSkinData = cast Json.parse(rawJson);
		return data;
	}

	public static var arrowSkins:Array<String> = [];

	public static function setNoteHelpers(helper:NoteSkinHelper, keys:Int = 4)
	{
		trace('set helpers!');

		Note.handler = helper;
		StrumNote.handler = helper;
		NoteSplash.handler = helper;
		NoteSustainCover.handler = helper;

		Note.keys = keys;
		StrumNote.keys = keys;
		NoteSustainCover.keys = keys;
	}
}
