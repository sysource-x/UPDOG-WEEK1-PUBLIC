package funkin.objects;

import flixel.FlxSprite;

class CheckboxThingie extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var daValue(default, set):Bool;
	public var copyAlpha:Bool = true;
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public function new(x:Float = 0, y:Float = 0, ?checked = false)
	{
		super(x, y);

		loadGraphic(Paths.image('menu/options/impastacheckbox'), true, 30, 30);
		animation.add("unchecked", [0], 24, false);
		animation.add("unchecking", [0], 24, false);
		animation.add("checking", [1], 24, false);
		animation.add("checked", [1], 24, false);

		antialiasing = ClientPrefs.globalAntialiasing;
		updateHitbox();
		offset.set(0, 6);

		animationFinished(checked ? 'checking' : 'unchecking');
		animation.finishCallback = animationFinished;
		daValue = checked;
	}

	override function update(elapsed:Float)
	{
		if (sprTracker != null)
		{
			setPosition(sprTracker.x - 130 + offsetX, sprTracker.y + 30 + offsetY);
			if (copyAlpha)
			{
				alpha = sprTracker.alpha;
			}
		}
		super.update(elapsed);
	}

	private function set_daValue(check:Bool):Bool
	{
		if (check)
		{
			if (animation.curAnim.name != 'checked' && animation.curAnim.name != 'checking')
			{
				animation.play('checking', true);
			}
		}
		else if (animation.curAnim.name != 'unchecked' && animation.curAnim.name != 'unchecking')
		{
			animation.play("unchecking", true);
		}
		return check;
	}

	private function animationFinished(name:String)
	{
		switch (name)
		{
			case 'checking':
				animation.play('checked', true);

			case 'unchecking':
				animation.play('unchecked', true);
		}
	}
}
