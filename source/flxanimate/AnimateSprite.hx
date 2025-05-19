package flxanimate;

import flxanimate.FlxAnimate.Settings;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;
import haxe.Json;

class AnimateSprite extends FlxAnimate
{
	public function new(X:Float = 0, Y:Float = 0, ?Path:String, ?Settings:Settings)
	{
		#if mobile
		if (Path != null)
		{
			var jsonPath = 'assets/shared/' + Path + '.json';
			var imagePath = 'assets/shared/' + Path + '.png';

			if (Assets.exists(jsonPath) && Assets.exists(imagePath))
			{
				var jsonData = Json.parse(Assets.getText(jsonPath));
				var bitmapData = Assets.getBitmapData(imagePath);

				super(X, Y, jsonData, bitmapData, Settings);
				return;
			}
		}
		#end

		// Fallback para desktop
		super(X, Y, Path, Settings);
	}

	override function draw()
	{
		if (anim.curInstance == null || anim.curSymbol == null)
			return;
		super.draw();
	}
}