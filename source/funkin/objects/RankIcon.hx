package funkin.objects;

import flixel.FlxSprite;

// This is a class for the icon that displays the rank you got on either an individual song or whole week

class RankIcon extends FlxSprite
{
	public static final offsets:Map<String, Array<Int>> = [
		'S' => [0, 0],
		'A' => [-25, -10],
		'B' => [-50, -10],
		'C' => [-50, -15],
		'D' => [-55, -8],
		'F' => [-50, -15]
	];
	
	public var rank:String = 'S';
	public var sprTracker:FlxSprite;
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	
	// icon for the ranking of a song. might move this to a separate hx if we put it into the story menu
	
	public function new(x:Float = 0, y:Float = 0, ?tracker:FlxSprite)
	{
		super(x, y);
		xAdd = x;
		yAdd = y;
		sprTracker = tracker;
		
		this.frames = Paths.getSparrowAtlas('menu/common/ranks');
		this.animation.addByPrefix('S', 'S', 24, true);
		this.animation.addByPrefix('A', 'A', 24, true);
		this.animation.addByPrefix('B', 'B', 24, true);
		this.animation.addByPrefix('C', 'C', 24, true);
		this.animation.addByPrefix('D', 'D', 24, true);
		this.animation.addByPrefix('F', 'F', 24, true);
		this.antialiasing = ClientPrefs.globalAntialiasing;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			scrollFactor.set(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);
			alpha = sprTracker.alpha;
		}
	}
	
	public function setRank(accuracy:Float) // might make it so it automatically remaps between 0 and 100 but i don't feel like doing that rn
	{
		this.visible = accuracy != 0.0;
		
		if (accuracy != 0.0)
		{
			if (accuracy >= 98) rank = 'S';
			else if (accuracy >= 90) rank = 'A';
			else if (accuracy >= 80) rank = 'B';
			else if (accuracy >= 70) rank = 'C';
			else if (accuracy >= 60) rank = 'D';
			else rank = 'F';
			
			this.animation.play(rank);
			this.offset.set(offsets[rank][0], offsets[rank][1]);
		}
	}
}