import flixel.addons.transition.FlxTransitionableState;

var singAnimations = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
var bfStar:Character;
var redStar:Character;
var orange:BGSprite;
var green:BGSprite;
var redCutscene:BGSprite;
var gunshot:BGSprite;

global.set('ignoreCountdown',true);

function onCreate()
{
	bfStar = new Character(1500, -1150, 'bfStar', false);
	bfStar.flipX = false;
	bfStar.scrollFactor.set(1.2, 1.2);
	bfStar.alpha = 0;
	bfStar.zIndex = 1;
	
	redStar = new Character(-100, -1200, 'redStar', false);
	redStar.flipX = false;
	redStar.scrollFactor.set(1.2, 1.2);
	redStar.alpha = 0;
	redStar.zIndex = 1;
	
	stage.add(bfStar);
	stage.add(redStar);
	
	global.set('bfStar', bfStar);
	global.set('redStar', redStar);

	orange = new BGSprite(null, -800, 440).loadSparrowFrames('stage/polus/orange');
	orange.animation.addByPrefix('idle', 'orange_idle instance 1', 24, true);
	orange.animation.addByPrefix('wave', 'wave instance 1', 24, true);
	orange.animation.addByPrefix('walk', 'frolicking instance 1', 24, true);
	orange.animation.addByPrefix('die', 'death instance 1', 24, false);
	orange.animation.play('walk');
	orange.scale.set(0.8, 0.8);
	orange.alpha = 0;
	orange.zIndex = 4;
	stage.add(orange);
	
	// Set different offsets for each animation
	green = new BGSprite(null, -800, 450).loadSparrowFrames('stage/polus/orange');
	green.animation.addByPrefix('idle', 'stand instance 1', 24, true);
	green.animation.addByPrefix('kill', 'kill instance 1', 24, false);
	green.animation.addByPrefix('walk', 'sneak instance 1', 24, true);
	green.animation.addByPrefix('carry', 'pulling instance 1', 24, true);
	green.animation.play('walk');
	green.scale.set(0.8, 0.8);
	green.alpha = 0;
	green.zIndex = 4;
	stage.add(green);

	if(PlayState.isStoryMode)
	{
		redCutscene = new BGSprite(null, dad.x - 5, dad.y).loadSparrowFrames('stage/polus/sabotagecutscene/redCutscene');
		redCutscene.animation.addByPrefix('mad', 'red mad0', 24, false);
		redCutscene.scale.set(0.9, 0.9);
		redCutscene.animation.play('mad');
		redCutscene.visible = false;
		redCutscene.zIndex = 6;
		stage.add(redCutscene);

		gunshot = new BGSprite(null, redCutscene.x + 515, redCutscene.y + 90).loadSparrowFrames('stage/polus/sabotagecutscene/gunshot');
		gunshot.animation.addByPrefix('shot', 'stupid impact0', 24, false);
		gunshot.scale.set(0.9, 0.9);
		gunshot.visible = false;
		gunshot.zIndex = 2000;
		stage.add(gunshot);

		songEndCallback = sabotageCutscene1stHalf;
	}

	global.set('sussus_green', green);
	global.set('sussus_orange', orange);
}

function onBeatHit()
{
	var anim = bfStar.animation.curAnim.name;
	if (!StringTools.contains(anim, 'sing') && game.curBeat % 2 == 0) bfStar.dance();
	
	var anim2 = redStar.animation.curAnim.name;
	if (!StringTools.contains(anim2, 'sing') && game.curBeat % 2 == 0) redStar.dance();
}

function opponentNoteHit(note)
{
	if (redStar.alpha != 0.0)
	{
		redStar.playAnim(singAnimations[note.noteData], true);
		redStar.holdTimer = 0;
	}
}

function goodNoteHit(note)
{
	if (bfStar.alpha != 0.0)
	{
		bfStar.playAnim(singAnimations[note.noteData], true);
		bfStar.holdTimer = 0;
	}
}

function sabotageCutscene1stHalf()
{
	isCameraOnForcedPos = true;
	camZooming = false;
	dadGroup.visible = false;
	redCutscene.visible = true;
	FlxTween.tween(camFollow, {x: 1025, y: 500}, 2, {ease: FlxEase.expoOut});
	FlxTween.tween(FlxG.camera, {zoom: 0.65}, 2, {ease: FlxEase.expoOut});
	FlxTween.tween(camHUD, {alpha: 0}, 0.75, {ease: FlxEase.expoOut});
	FlxG.sound.play(Paths.sound('moogusCutscene'), 1);
	redCutscene.animation.play('mad');
	redCutscene.animation.onFinish.add((mad)->{
		var blackSprite = global.get('blackSprite');
		blackSprite.alpha = 1;
		blackSprite.cameras = [camGame];
		blackSprite.zIndex = 1900;
		blackSprite.scale.set(3000, 2000);
		refreshZ();
		gunshot.visible = true;
		gunshot.animation.play('shot');
		gunshot.animation.onFinish.add((mad)->{
			gunshot.visible = false;
		});
		new FlxTimer().start(2, function(tmr:FlxTimer) {
			endSong();
			FlxTransitionableState.skipNextTransOut = true;
		});
	});
}