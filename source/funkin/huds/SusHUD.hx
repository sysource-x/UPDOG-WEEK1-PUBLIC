package funkin.huds;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxObject;
import flixel.util.FlxStringUtil;

import funkin.objects.Bar;
import funkin.objects.HealthIcon;
import funkin.huds.BaseHUD.ScoreData;

// renaming class cuz i felt like it also good to have the og hud just incase, will be deleted later
@:access(funkin.states.PlayState)
class SusHUD extends BaseHUD
{
	var healthBar:Bar;
	var iconP1:HealthIcon;
	var iconP2:HealthIcon;
	var scoreTxt:FlxText;
	var tablet:FlxSprite;
	var showRating:Bool = true;
	var showCombo:Bool = true;
	var ratingText:FlxText;
	var ratingScores:FlxTypedGroup<FlxText>;
	
	override function init()
	{
		name = 'IMPOSTOR';
		
		healthBar = new Bar(0, !ClientPrefs.downScroll ? 641 : 56, 'hud/healthBarGuide', function() return parent.health, parent.healthBounds.min, parent.healthBounds.max);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.antialiasing = ClientPrefs.globalAntialiasing;
		reloadHealthBarColors();
		add(healthBar);
		
		tablet = new FlxSprite(-46, !ClientPrefs.downScroll ? -38 : -143).loadGraphic(Paths.image('hud/healthBarFG'));
		tablet.frames = Paths.getSparrowAtlas('hud/healthBarFG');
		tablet.setGraphicSize(Std.int(tablet.width * 0.53), Std.int(tablet.height * 0.53)); // asset is wayyy too big oops
		tablet.updateHitbox();
		tablet.animation.addByPrefix('idle', 'healthbar', 48, true);
		tablet.animation.play('idle', true);
		tablet.flipY = ClientPrefs.downScroll;
		tablet.antialiasing = ClientPrefs.globalAntialiasing;
		healthBar.add(tablet); // the healthbar is a sprite group so i can do this and its easier imo
		
		iconP1 = new HealthIcon(parent.boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);
		
		iconP2 = new HealthIcon(parent.dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		
		scoreTxt = new FlxText(0, !ClientPrefs.downScroll ? healthBar.y + 45 : healthBar.y - 45, FlxG.width, "", 24);
		scoreTxt.setFormat(Paths.font("liber.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		// scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.hideHud;
		scoreTxt.antialiasing = ClientPrefs.globalAntialiasing;
		add(scoreTxt);
		
		ratingText = new FlxText(0, ClientPrefs.downScroll ? FlxG.height * 0.8 : FlxG.height * 0.1, FlxG.width, '');
		ratingText.setFormat(Paths.font("bahn.ttf"), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		ratingText.screenCenter(X);
		ratingText.antialiasing = ClientPrefs.globalAntialiasing;
		ratingText.borderSize = 2.5;
		insert(members.indexOf(scoreTxt), ratingText);
		
		ratingScores = new FlxTypedGroup();
		insert(members.indexOf(ratingText), ratingScores);
		
		for (i in 0...3)
		{
			final num = ratingScores.recycle(FlxText, setupScoreNum);
			ratingScores.add(num);
			num.kill();
		}
		
		onUpdateScore({score: 0, accuracy: 0, misses: 0});
		
		parent.setOnScripts('healthBar', healthBar); // for ike - do this if u wanna make a var accessible in hscript
		parent.setOnScripts('iconP1', iconP1);
		parent.setOnScripts('iconP2', iconP2);
		parent.setOnScripts('scoreTxt', scoreTxt);
		parent.setOnScripts('ratingText', ratingText);
		parent.setOnScripts('ratingScores', ratingScores);
	}
	
	override function onUpdateScore(data:ScoreData, missed:Bool = false)
	{
		var str:String = 'N/A';
		if (parent.totalPlayed != 0) // this is probably a bad way to do this im just trying to get it to work
		{
			// ranks based on your accuracy
			if (data.accuracy >= 98) str = 'S';
			else if (data.accuracy >= 90) str = 'A';
			else if (data.accuracy >= 80) str = 'B';
			else if (data.accuracy >= 70) str = 'C';
			else if (data.accuracy >= 60) str = 'D';
			else str = 'F';
		}
		
		final tempScore:String = 'Score: ${FlxStringUtil.formatMoney(data.score, false)}      '
			+ (!parent.instakillOnMiss ? 'Misses: ${data.misses}      ' : "")
			+ 'Rank: ${str}';
			
		scoreTxt.text = '${tempScore}\n';
	}
	
	public function updateIconsPosition()
	{
		final iconOffset:Int = 26;
		if (!healthBar.leftToRight)
		{
			iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
			iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		}
		else
		{
			iconP1.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
			iconP2.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		}
	}
	
	public function updateIconsScale(elapsed:Float)
	{
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();
		
		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
	}
	
	public function reloadHealthBarColors()
	{
		var dad = parent.dad;
		var boyfriend = parent.boyfriend;
		healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
	}
	
	public function flipBar()
	{
		healthBar.leftToRight = !healthBar.leftToRight;
		iconP1.flipX = !iconP1.flipX;
		iconP2.flipX = !iconP2.flipX;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		updateIconsPosition();
		updateIconsScale(elapsed);
	}
	
	override function beatHit()
	{
		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);
		
		iconP1.updateHitbox();
		iconP2.updateHitbox();
	}
	
	override function onCharacterChange()
	{
		reloadHealthBarColors();
		iconP1.changeIcon(parent.boyfriend.healthIcon);
		iconP2.changeIcon(parent.dad.healthIcon);
	}
	
	override function onHealthChange(health:Float)
	{
		var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);
		
		iconP1.animation.curAnim.curFrame = (healthBar.percent < 20) ? 1 : 0; // If health is under 20%, change player icon to frame 1 (losing icon), otherwise, frame 0 (normal)
		iconP2.animation.curAnim.curFrame = (healthBar.percent > 80) ? 1 : 0; // If health is over 80%, change opponent icon to frame 1 (losing icon), otherwise, frame 0 (normal)
	}
	
	static final customTextMap:Map<String, String> = [
		"shit" => "SHIT!",
		"bad" => "ASS",
		"good" => "GOOD",
		"sick" => "SUS!",
		"epic" => "SUSSY!"
	];
	
	override function popUpScore(ratingName:String, combo:Int)
	{
		FlxTween.cancelTweensOf(ratingText, ['scale.x', 'scale.y', 'alpha']);
		
		ratingScores.forEachAlive(text -> {
			FlxTween.cancelTweensOf(text, ['scale.x', 'scale.y', 'alpha']);
			text.kill();
		});
		
		// remap
		ratingText.text = customTextMap.get(ratingName.toLowerCase()) ?? ratingText.text;
		
		ratingText.visible = (!ClientPrefs.hideHud && showRating);
		ratingText.scale.set(0.8, 0.8);
		ratingText.alpha = 1;
		
		FlxTween.tween(ratingText.scale, {x: 1, y: 1}, 0.5, {ease: FlxEase.expoOut});
		FlxTween.tween(ratingText, {alpha: 0}, 0.5, {startDelay: 0.7});
		
		var seperatedScore:Array<Int> = [];
		if (combo >= 1000)
		{
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);
		
		var totalWidth:Float = (seperatedScore.length * 20) - 10;
		var daLoop:Int = 0;
		
		for (i in seperatedScore)
		{
			var num = ratingScores.recycle(FlxText, setupScoreNum); //might cache the graphics
			ratingScores.add(num);
			num.text = Std.string(i);
			
			num.screenCenter(X);
			num.x += (daLoop * 20) - (totalWidth / 2);
			
			num.visible = (!ClientPrefs.hideHud && showCombo);
			num.scale.set(0.6, 0.6);
			num.alpha = 1;
			
			FlxTween.tween(num.scale, {x: 0.5, y: 0.5}, 0.5, {ease: FlxEase.expoOut});
			
			FlxTween.tween(num, {alpha: 0}, 0.2,
				{
					onComplete: function(tween:FlxTween) {
						num.kill();
					},
					startDelay: Conductor.crotchet * 0.002
				});
				
			daLoop++;
		}
	}
	
	inline function setupScoreNum()
	{
		var num = new FlxText(0, ClientPrefs.downScroll ? FlxG.height * 0.85 : FlxG.height * 0.14, 0, '0');
		num.setFormat(Paths.font("liber.ttf"), 65, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		num.borderSize = 5;
		num.antialiasing = ClientPrefs.globalAntialiasing;
		
		return num;
	}
}
