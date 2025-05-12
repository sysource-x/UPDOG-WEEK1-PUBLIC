import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.addons.transition.FlxTransitionableState;

var singAnimations = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];
var redCutscene:BGSprite;
var bfCutscene:BGSprite;
var shield:BGSprite;
var shieldBreakTop:BGSprite;
var shieldBreakBottom:BGSprite;
var invertMask:BGSprite;
var orangeGhost:BGSprite;
var boomBoxS:BGSprite;
var bfCutOffsets:Map<String, Array<Float>> = [
	'covered-grey' => [0, 0],
	'covered' => [1, -2]
	'uncover' => [1, 5]
	'awkward' => [4, 2]
	'trans' => [6, 35]
];
var anotherBlackSprite:FlxSprite;
var devCutscene:Bool = false;

var detective:Bool = false;

// var grayShader:AdjustColorShader;
// var grayShaderButTheOtherOne:AdjustColorShader;

function startInvestigationCountdown(seconds:Int)
{
	// Use a mutable reference for the countdown value
	var countdown = {value: seconds};
	
	investigationText.text = "Investigation ends in " + countdown.value;
	
	var countdownTimer:FlxTimer = new FlxTimer();
	countdownTimer.start(1, function(timer:FlxTimer) {
		countdown.value--; // Decrement the countdown value
		if (countdown.value >= 0)
		{
			investigationText.text = "Investigation ends in " + countdown.value;
		}
		else
		{
			investigationText.text = "Investigation complete!";
		}
	}, seconds + 1);
}

function onCreate()
{
	/* if (ClientPrefs.shaders) {
		grayShaderButTheOtherOne = new AdjustColorShader();
		grayShader = new AdjustColorShader();
	} */
	
	if(devCutscene || (PlayState.isStoryMode && !PlayState.seenCutscene))
	{
		songStartCallback = sabotageCutscene2ndHalf;
	
		Paths.sound('sabotageCutscene'); //caching the cutscene audio
		
		bfCutscene = new BGSprite(null, boyfriend.x + 10, boyfriend.y + 25).loadSparrowFrames('stage/polus/sabotagecutscene/bfCutscene');
		bfCutscene.animation.addByPrefix('covered-grey', 'boyfriend gray covered0', 24, false);
		bfCutscene.animation.addByPrefix('trans', 'boyfriend ready', 24, false);
		bfCutscene.animation.addByPrefix('awkward', 'boyfriend awkward', 24, false);
		bfCutscene.animation.addByPrefix('covered', 'boyfriend covered0', 24, true);
		bfCutscene.animation.addByPrefix('uncover', 'boyfriend uncover0', 24, false);
		bfCutscene.animation.addByIndices('uncoverLoop', 'boyfriend uncover', [for (i in 16 ... 28) i], '', 24); // array comprehension... my beloved.
		bfCutscene.animation.finishCallback = (ani:String) -> {
			if (ani == 'uncover')
				bfCutscene.animation.play('uncoverLoop', true);
		};
		bfCutscene.scale.set(1.1, 1.1);
		//bfCutscene.visible = false;
		bfCutscene.zIndex = 1950;
		stage.add(bfCutscene);

		orangeGhost = new BGSprite(null, 1040, 210).loadSparrowFrames('stage/polus/sabotagecutscene/ghostOrange');
		orangeGhost.animation.addByPrefix('ghost', 'ghost orange0', 24, false);
		// 900 250
		orangeGhost.alpha = 0;
		orangeGhost.zIndex = 12;
		stage.add(orangeGhost);

		shield = new BGSprite(null, bfCutscene.x - 115, bfCutscene.y - 40).loadSparrowFrames('stage/polus/sabotagecutscene/shield');
		shield.animation.addByPrefix('break', 'shield breaks0', 24, false);
		shield.scale.set(1.1, 1.1);
		shield.zIndex = 2000;
		shield.blend = 0;
		stage.add(shield);

		shieldBreakBottom = new BGSprite(null, shield.x - 25, shield.y - 50).loadSparrowFrames('stage/polus/sabotagecutscene/shield');
		shieldBreakBottom.animation.addByPrefix('shatter', 'shield shatter bottom0', 24, false);
		shieldBreakBottom.scale.set(1.1, 1.1);
		shieldBreakBottom.visible = false;
		shieldBreakBottom.zIndex = 12;
		shieldBreakBottom.blend = 0;
		stage.add(shieldBreakBottom);

		shieldBreakTop = new BGSprite(null, shield.x - 75, shield.y - 100).loadSparrowFrames('stage/polus/sabotagecutscene/shield');
		shieldBreakTop.animation.addByPrefix('shatter', 'shield shatter top0', 24, false);
		shieldBreakTop.scale.set(1.1, 1.1);
		shieldBreakTop.visible = false;
		shieldBreakTop.zIndex = 2000;
		shieldBreakTop.blend = 0;
		stage.add(shieldBreakTop);

		invertMask = new BGSprite(null, shield.x - 300, shield.y - 325).loadSparrowFrames('stage/polus/sabotagecutscene/tempshieldthing');
		invertMask.animation.addByPrefix('glow', 'temp0', 24, false);
		invertMask.scale.set(1.1, 1.1);
		invertMask.blend = 0;
		invertMask.zIndex = 2000;
		invertMask.visible = false;
		// if (ClientPrefs.shaders) 
		// {
		//     var invert:FlxShader = newShader('invertColor');
		// 	invertMask.shader = invert;
		// }
		stage.add(invertMask);

		redCutscene = new BGSprite(null, dad.x - 10, dad.y - 7).loadSparrowFrames('stage/polus/sabotagecutscene/redCutscene');
		redCutscene.animation.addByPrefix('awky', 'red AWKWARD0', 24, false);
		redCutscene.animation.addByIndices('idle', 'red AWKWARD0', [0], "", 24, false);
		redCutscene.animation.addByPrefix('trans', 'red transition back', 24, false);
		redCutscene.scale.set(0.9, 0.9);
		redCutscene.zIndex = 6;
		stage.add(redCutscene);

		anotherBlackSprite = new FlxSprite(600, 0).makeScaledGraphic(3000, 2000, 0xff000000);
		anotherBlackSprite.zIndex = 2020;
		stage.add(anotherBlackSprite);
	}
	
	boomBoxS = new BGSprite().loadSparrowFrames('stage/polus/meltdown/boomboxfall');
	boomBoxS.animation.addByPrefix('anim', 'boombox falls', 24, false);
	boomBoxS.zIndex = gfGroup.zIndex + 10;
	boomBoxS.scale.set(1.1, 1.1);
	boomBoxS.alpha = .001;
	
	global.set('boomBoxS', boomBoxS);
	
	global.set('startInvestigationCountdown', startInvestigationCountdown);
	
	saboDetective = new Character(2540, 81, 'detectiveSabotage', false);
	saboDetective.alpha = 0;
	saboDetective.flipX = false;
	saboDetective.zIndex = 3;
	stage.add(saboDetective);
	
	global.set('sabo_detective', saboDetective);
	
	var struct = {};
	
	detectiveIcon = new BGSprite("stage/polus/detective", 90, 1000);
	detectiveIcon.scale.set(0.65, 0.65);
	game.insert(members.indexOf(playHUD),detectiveIcon);
	detectiveIcon.cameras = [game.camHUD];
	
	struct.detectiveIcon = detectiveIcon;
	
	detectiveUI2 = new BGSprite("stage/polus/inside", -160, 1000);
	detectiveUI2.scale.set(0.6, 0.6);
	game.insert(members.indexOf(playHUD),detectiveUI2);
	detectiveUI2.cameras = [game.camHUD];
	
	struct.detectiveUI2 = detectiveUI2;
	
	flxBar = new FlxBar(270, 560, FlxBarFillDirection.LEFT_TO_RIGHT, 290, 45, null, null, 0, 60, true);
	flxBar.createFilledBar(0xff000000, 0xFF62E0CF, true);
	flxBar.setParent(null, "x", "y", true);
	flxBar.percent = 0;
	flxBar.scale.set(1.3, 1.3);
	flxBar.alpha = 0;
	flxBar.cameras = [game.camHUD];
	game.insert(members.indexOf(playHUD),flxBar);
	
	struct.flxBar = flxBar;
	
	detectiveUI = new BGSprite('stage/polus/frame', -160, 1000);
	detectiveUI.scale.set(0.6, 0.6);
	detectiveUI.cameras = [game.camHUD];
	game.insert(members.indexOf(playHUD),detectiveUI);
	
	struct.detectiveUI = detectiveUI;
	
	investigationText = new FlxText(180, 1000, 480, "Investigation ends in 0", true);
	investigationText.setFormat(Paths.font("bahn.ttf"), 24, 0xFFFFFF, "center");
	investigationText.cameras = [game.camHUD];
	investigationText.alpha = 1;
	investigationText.antialiasing = ClientPrefs.globalAntialiasing;
	game.insert(members.indexOf(playHUD),investigationText);
	
	struct.investigationText = investigationText;
	
	applebar = new BGSprite("stage/polus/saboSpotlight", 2250, -350);
	applebar.alpha = 0;
	applebar.blend = 0;
	stage.add(applebar);
	
	applebar.zIndex = 15;
	global.set('sabo_spotlight', applebar);
	
	global.set('detectiveUI', struct);
}

function updateDetectiveIcon(elapsed:Float)
{
	var mult:Float = FlxMath.lerp(0.7, detectiveIcon.scale.x, Math.exp(-elapsed * 9));
	detectiveIcon.scale.set(mult, mult);
	// detectiveIcon.updateHitbox(); nope haha!
}

function onBeatHit()
{
	/*
		NOTE TO SELF MAYBE MAKE IT SO IT SLOWS DOWN WHEN THE SONG GETS SLOW AND EMOTIONAL #LOWKEY
	*/
	detectiveIcon.scale.set(0.65, 0.65);
	detectiveIcon.updateHitbox();
	updateDetectiveIcon(FlxG.elapsed);
	
	var anim = saboDetective.animation.curAnim.name;
	if (!StringTools.contains(anim, 'sing') && game.curBeat % 2 == 0) saboDetective.dance();
	
	/*
	switch (curBeat) {
		case 200: // the grayening
			detective = true;
				if (ClientPrefs.shaders) {
				FlxTween.tween(grayShader, {saturation: -90, brightness: -50, contrast: 32}, Conductor.crotchet * .001 * 24, {ease: FlxEase.sineOut});
				FlxTween.tween(grayShaderButTheOtherOne, {saturation: -50, brightness: -25, contrast: 25}, Conductor.crotchet * .001 * 24, {ease: FlxEase.sineOut});
			}
			
		case 312: // the ungrayening
				if (ClientPrefs.shaders) {
				FlxTween.tween(grayShader, {saturation: 0, brightness: 0, contrast: 0}, Conductor.crotchet * .001 * 8, {ease: FlxEase.quadInOut});
				FlxTween.tween(grayShaderButTheOtherOne, {saturation: 0, brightness: 0, contrast: 0}, Conductor.crotchet * .001 * 8, {ease: FlxEase.quadInOut});
			}
			
		case 320: // reset notes shader
			detective = false;
			for (strum in playerStrums)
				strum.shader = (strum.animation.name == 'static' ? null : strum.colorSwap.shader);
	}
	*/
}

function onUpdatePost(e)
{
	if (devCutscene && FlxG.keys.justPressed.F5)
		FlxG.resetState();
	updateDetectiveIcon(e);
	
	/*
	if (ClientPrefs.shaders) {
		if (detective) {
			for (strum in playerStrums) // have to account for custom note color setup maybe? Theres no option for those atm
				strum.shader = (strum.animation.name == 'static' ? grayShader.shader : grayShaderButTheOtherOne.shader);
		}
	}
	*/
}

function goodNoteHit(note)
{
	saboDetective.playAnim(singAnimations[note.noteData], true);
	saboDetective.holdTimer = 0;
}

var testTimer:FlxTimer;

function sabotageCutscene2ndHalf() // this a little dire to look at but its ok
{
	testTimer = new FlxTimer().start((0.825), function(tmr:FlxTimer) {
		if (gf != null
			&& tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0
			&& gf.animation.curAnim != null)
		{
			gf.dance();
		}
	}, 20);
	
	new FlxTimer().start(0.125, function(tmr:FlxTimer) {
		FlxG.sound.play(Paths.sound('sabotageCutscene'), 1);
	});
	
	var blackSprite = global.get('blackSprite');
	blackSprite.alpha = 1;
	blackSprite.cameras = [camGame];
	blackSprite.zIndex = 1900;
	blackSprite.scale.set(3000, 2000);
	blackSprite.x += 300;
	refreshZ();

	FlxTween.tween(anotherBlackSprite, {alpha:0}, 3, {ease: FlxEase.expoOut});

	boyfriend.visible = false;
	dad.visible = false;
	redCutscene.animation.play('idle');
	
	isCameraOnForcedPos = true;
	camZooming = false;

	camFollow.set(1400, 685);
	camFollowPos.setPosition(1400, 685);
	FlxTween.tween(camFollow, {x: 1490, y: 685}, 0.5, {ease: FlxEase.expoIn});
	FlxG.camera.zoom = 1;
	FlxTween.tween(FlxG.camera, {zoom: 1.3}, 0.75, {ease: FlxEase.expoIn, onComplete: function(twn:FlxTween)
	{ 
		FlxTween.tween(FlxG.camera, {zoom: 1.25}, 0.75, {ease: FlxEase.expoOut, onComplete: function(twn:FlxTween)
		{ 
			FlxTween.tween(FlxG.camera, {zoom: 1.3}, 1, {ease: FlxEase.expoOut});
			FlxTween.tween(camFollow, {x: 1500, y: 685}, 1, {ease: FlxEase.expoOut});
		}});
	}});

	camHUD.alpha = 0;
	shield.animation.play('break');
	bfCutscene.animation.play('covered-grey');
	bfCutscene.offset.set(bfCutOffsets['covered-grey'][0], bfCutOffsets['covered-grey'][1]);

	new FlxTimer().start(2.75, function(tmr:FlxTimer) {
		camGame.shake(0.00075, .5);
		invertMask.visible = true;
		invertMask.animation.play('glow');
		invertMask.animation.pause();
		invertMask.alpha = 0;
		invertMask.scale.set(1.5, 1.5);
		FlxTween.tween(invertMask, {alpha: 1, 'scale.x': .6, 'scale.y': .6}, .5, {ease: FlxEase.quadIn});
		
		new FlxTimer().start(0.5, function(tmr:FlxTimer) {
			blackSprite.visible = false;
			blackSprite.x -= 300;
			shield.visible = false;
			bfCutscene.animation.play('covered');
			bfCutscene.offset.set(bfCutOffsets['covered'][0], bfCutOffsets['covered'][1]);
			bfCutscene.zIndex = 12;
			for(i in [shieldBreakTop, shieldBreakBottom])
			{
				i.animation.play('shatter');
				i.visible = true;
				i.animation.onFinish.add((anim)->{
					i.visible = false;
				});
			}
			invertMask.visible = true;
			invertMask.animation.resume();
			invertMask.animation.onFinish.add((anim)->{
				invertMask.visible = false;
			});
			refreshZ();
			camGame.shake(0.006, .5);
			FlxTween.tween(invertMask.scale, {x: 1.5, y: 1.5}, .75, {ease: FlxEase.quadOut});
			FlxTween.tween(FlxG.camera, {zoom: 0.9}, 1.3, {ease: FlxEase.expoOut});
			FlxTween.tween(camFollow, {x: 1445, y: 665}, 1.3, {ease: FlxEase.expoOut});
			new FlxTimer().start(0.3, function(tmr:FlxTimer) {
				orangeGhost.animation.play('ghost');
				orangeGhost.visible = true;
				FlxTween.tween(orangeGhost, {x:1000, y:250, alpha: 0.5}, 3, {ease: FlxEase.expoOut});
			});
			new FlxTimer().start(4.5, function(tmr:FlxTimer) {
				FlxTween.tween(orangeGhost, {alpha: 0}, 0.75, {ease: FlxEase.expoOut});
			});
		});
	});
	
	new FlxTimer().start(7.5, function(tmr:FlxTimer) {
		FlxTween.tween(camFollow, {x: 620, y: 670}, 2.3, {ease: FlxEase.quadInOut, startDelay: 0.1});
		FlxTween.tween(FlxG.camera, {zoom: 0.85}, 2.3, {ease: FlxEase.quadInOut, startDelay: 0.1});
	});
	
	new FlxTimer().start(8.3, function(tmr:FlxTimer) {
		bfCutscene.animation.play('uncover');
		bfCutscene.offset.set(bfCutOffsets['uncover'][0], bfCutOffsets['uncover'][1]);
	});
	
	new FlxTimer().start(9, function(tmr:FlxTimer) {
		redCutscene.animation.play('awky');
	});
	
	new FlxTimer().start(11.3, function(tmr:FlxTimer) {
		bfCutscene.animation.play('awkward');
		bfCutscene.offset.set(bfCutOffsets['awkward'][0], bfCutOffsets['awkward'][1]);
		FlxTween.tween(camFollow, {y: 560}, 1.75, {ease: FlxEase.quadInOut});
		FlxTween.tween(camFollow, {x: 850}, 1.75, {ease: FlxEase.sineInOut});
		FlxTween.tween(FlxG.camera, {zoom: 0.65}, 1.75, {ease: FlxEase.quadInOut});
	});

	new FlxTimer().start(14, function(tmr:FlxTimer) {
		FlxTween.tween(camFollow, {x: 1025, y: 500}, 1.5, {ease: FlxEase.quadOut});
		FlxTween.tween(FlxG.camera, {zoom: 0.5}, 1.5, {ease: FlxEase.sineOut});
	});

	new FlxTimer().start(15.75, function(tmr:FlxTimer) {
		redCutscene.animation.play('trans');
		bfCutscene.animation.play('trans');
		redCutscene.offset.set(5, -6);
		bfCutscene.offset.set(bfCutOffsets['trans'][0], bfCutOffsets['trans'][1]);
	});

	new FlxTimer().start(16.5, function(tmr:FlxTimer) {
		startCountdown();
		bfCutscene.visible = false;
		redCutscene.visible = false;
		boyfriend.visible = true;
		dad.visible = true;
		isCameraOnForcedPos = false;
		FlxTween.tween(camHUD, {alpha: 1}, 0.75, {ease: FlxEase.expoOut, startDelay: 0.25});
		PlayState.seenCutscene = true;
		FlxTransitionableState.skipNextTransOut = false;
	});
}

function onDestroy()
{
	FlxTransitionableState.skipNextTransOut = false;
}