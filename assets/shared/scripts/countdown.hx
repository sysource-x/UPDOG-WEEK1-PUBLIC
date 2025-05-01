package content.scripts;

import funkin.data.Conductor;
import funkin.objects.BGSprite;
import funkin.data.ClientPrefs;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;

var count:FlxSprite;

countdownLoops = 5.5;
countdownDelay = 0.1;


function onCountdownStarted()
{
	if (PlayState.startOnTime > 0) return;

	if (global.exists('ignoreCountdown')) return;
	
	count = new BGSprite('get-ready', 0, 0);
	FlxG.state.add(count);
	count.cameras = [camPause];
	
	count.scale.set(0.5, 0.5);
	count.updateHitbox();
	count.screenCenter();
	
	var oldY = count.y;
	count.y = FlxG.height;
	
	FlxG.sound.play(Paths.sound('cancelMenu'));
	
	FlxTween.tween(count, {y: oldY}, Conductor.crotchet / 1000, {ease: FlxEase.cubeInOut});
}

function onCountdownTick(tick)
{
	var spr = switch (tick)
	{
		case 0:
			countdownGetReady;
		case 1:
			countdownReady;
		case 2:
			countdownSet;
		case 3:
			countdownGo;
		case 4: null;
        case 5: null;
	}
	
	if (spr != null)
	{
		FlxG.state.remove(spr);
		spr.destroy();
	}

	if (global.exists('ignoreCountdown')) return;

	
	var time = Conductor.crotchet / 1000;
	
	if (tick < 4)
	{
		count.scale.set(0.55, 0.55);
		FlxTween.tween(count.scale, {x: 0.5, y: 0.5}, time / 2);
	}
	
	switch (tick)
	{
		case 0:
		
		case 1:
			count.loadGraphic(Paths.image('ready'));
			count.updateHitbox();
			
			count.screenCenter();
			
		case 2:
			count.loadGraphic(Paths.image('set'));
			count.updateHitbox();
			count.screenCenter();
			
		case 3:
			count.loadGraphic(Paths.image('go'));
			count.updateHitbox();
			
			count.screenCenter();
			
		case 4:
			FlxTween.tween(count, {y: FlxG.height}, time,
				{
					ease: FlxEase.cubeInOut,
					onComplete: Void -> {
						FlxG.state.remove(count);
						count.destroy();
					}
				});
	}
}
