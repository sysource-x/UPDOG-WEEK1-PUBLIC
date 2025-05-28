package content.songs.meltdown;

import funkin.objects.BGSprite;

var cutsceneAssets = new FlxTypedGroup();

function onCreate()
{
	stage.add(cutsceneAssets);
	
	cutsceneAssets.zIndex = 20;
	
	cliff = new BGSprite(null, 0, 0).loadFromSheet('stage/polus/meltdown/cutscene/bg', 'polus_cliff');
	cutsceneAssets.add(cliff);
	cliff.scale.set(2, 2);
	cliff.updateHitbox();
	
	buildings = new BGSprite(null, cliff.x + (996 * cliff.scale.x / 2), cliff.y + (549 * cliff.scale.y / 2)).loadFromSheet('stage/polus/meltdown/cutscene/bg', 'bg_building');
	buildings.scale.set(cliff.scale.x, cliff.scale.y);
	buildings.updateHitbox();
	cutsceneAssets.add(buildings);
	buildings.zIndex = -2;
	
	brdige = new BGSprite(null, cliff.x + (1664 * cliff.scale.x / 2), cliff.y + (600 * cliff.scale.y / 2)).loadFromSheet('stage/polus/meltdown/cutscene/bg', 'bridge');
	brdige.scale.set(cliff.scale.x, cliff.scale.y);
	brdige.updateHitbox();
	cutsceneAssets.add(brdige);
	
	brdige.zIndex = 2;
	
	lava = new BGSprite(null, cliff.x + (-383 * cliff.scale.x / 2), cliff.y + (2574 * cliff.scale.y / 2)).loadFromSheet('stage/polus/meltdown/cutscene/bg', 'bottom_lava');
	lava.scale.set(cliff.scale.x, cliff.scale.y);
	lava.updateHitbox();
	cutsceneAssets.add(lava);
	lava.zIndex = 2;
	
	lavaCover = new BGSprite(null, cliff.x + (-386 * cliff.scale.x / 2), cliff.y + (3155 * cliff.scale.y / 2)).loadFromSheet('stage/polus/meltdown/cutscene/bg', 'upper_lava');
	lavaCover.scale.set(cliff.scale.x, cliff.scale.y);
	lavaCover.updateHitbox();
	cutsceneAssets.add(lavaCover);
	lavaCover.zIndex = 99;
	
	crew = new BGSprite(null, cliff.x + (1060 * cliff.scale.x / 2), cliff.y + (398 * cliff.scale.y / 2)).loadFromSheet('stage/polus/meltdown/cutscene/bg', 'bg_crewmates_fuck..my_butt_hurts');
	crew.scale.set(cliff.scale.x, cliff.scale.y);
	crew.updateHitbox();
	cutsceneAssets.add(crew);
	
	crew.zIndex = -1;
	cutsceneAssets.add(crew);
	
	lavaSplash = new BGSprite(null, cliff.x + (1700 * cliff.scale.x / 2), cliff.y + (2700 * cliff.scale.y / 2)).loadFromSheet('stage/polus/meltdown/cutscene/lava_splash', 'lava splash');
	lavaSplash.animation.curAnim.looped = false;
	lavaSplash.animation.pause();
	lavaSplash.scale.set((cliff.scale.x / 2) * 0.9, (cliff.scale.y / 2) * 0.9);
	lavaSplash.updateHitbox();
	lavaSplash.visible = false;
	cutsceneAssets.add(lavaSplash);
	lavaSplash.zIndex = 2;
	lavaSplash.offset.set(0,300);
	
	var charOffsetX = 200;
	var charOffsetY = 150;
	
	pushingBF = new BGSprite(null, cliff.x + (1500 * (cliff.scale.x / 2)) + charOffsetX,
		cliff.y + (300 * (cliff.scale.y / 2)) + charOffsetY).loadSparrowFrames('stage/polus/meltdown/cutscene/bf_meltdown_cutscene');
	pushingBF.scale.set(cliff.scale.x / 2, cliff.scale.y / 2);
	pushingBF.updateHitbox();
	pushingBF.animation.addByPrefix('ready', 'bf ready to push', 24, true);
	pushingBF.animation.addByPrefix('push', 'bf push him', 24, false);
	pushingBF.animation.play('ready');
	cutsceneAssets.add(pushingBF);
	pushingBF.zIndex = -1;
	
	impostor = new BGSprite(null, cliff.x + (1625 * cliff.scale.x / 2) + charOffsetX,
		cliff.y + (180 * cliff.scale.y / 2) + charOffsetY).loadSparrowFrames('stage/polus/meltdown/cutscene/red_meltdown_cutscene');
		
	impostor.scale.set(cliff.scale.x / 2, cliff.scale.y / 2);
	impostor.updateHitbox();
	impostor.animation.addByPrefix('nervous', 'nervous buddy', 24, false);
	impostor.animation.addByPrefix('getPushed', 'nervous getting pushed', 24, false);
	impostor.animation.addByPrefix('thumbsup', 'thumb up', 24, false);
	impostor.animation.addByPrefix('falling', 'falling buddy', 24);
	impostor.animation.play('nervous');
	impostor.animation.pause();
	impostor.animation.curAnim.curFrame = 0;
	cutsceneAssets.add(impostor);
	impostor.zIndex = -1;
	
	impostor.animation.onFrameChange.add((anim, frame, idx) -> {
		impostor.offset.set();
		
		switch (anim)
		{
			case 'getPushed':
				impostor.offset.set(0, 20.5 * 2);
			case 'falling':
				impostor.offset.set(-25 * 2, -15 * 2);
			case 'thumbsup':
				impostor.offset.set(-65 * 2, 5 * 2);
		}
	});
	
	impostor.animation.onFinish.add(anim -> {
		switch (anim)
		{
			case 'getPushed':
				impostor.animation.play('falling');
		}
	});
	
	refreshZ(cutsceneAssets);
	
	cutsceneAssets.visible = false;
}

function onUpdatePost(e)
{
	if (FlxG.keys.justPressed.G)
	{
		// push();
		// impostor2.visible = !impostor2.visible;
		// trace(impostor2.visible);
		
		// onEvent('', 'showEnd', '');

		// setSongTime(163099);
	}
	// FlxG.camera.zoom = 0.3;
	// isCameraOnForcedPos = true;
	
	// FlxG.camera.target = impostor;
}

function push()
{
	
	FlxG.camera.zoom += 0.05;
	FlxTween.tween(FlxG.camera, {zoom: 0.5},0.1, {ease: FlxEase.sineOut});
	// defaultCamZoom = 0.475;


	pushingBF.animation.play('push');
	impostor.animation.play('getPushed');
	impostor.zIndex = 3;
	refreshZ(cutsceneAssets);
	
	// kinda ugly but it works
	
	var sc = impostor.scale.x;
	
	FlxTween.tween(impostor, {y: impostor.y - 50}, 0.2,
		{
			ease: FlxEase.sineOut,
			onComplete: Void -> {
				FlxTween.tween(impostor, {y: lavaSplash.y + impostor.frameHeight + 300}, 2, {ease: FlxEase.sineIn, onComplete: splash});
				FlxTween.tween(impostor.scale, {x: sc * 1.7, y: sc * 1.7}, 1, {ease: FlxEase.sineOut,onComplete: Void->{
					FlxTween.tween(impostor.scale, {x: sc * 1.3,y: sc * 1.3}, 1, {ease: FlxEase.sineIn});

				}});
			}
		});
		
	FlxTween.tween(impostor, {x: impostor.x + 80}, 0.4,
		{
			ease: FlxEase.sineOut,
			onComplete: Void -> {
				FlxTween.tween(impostor, {x: impostor.x - 80}, 1, {ease: FlxEase.sineIn, startDelay: 0.5});
				
			}
		});


	FlxTween.tween(camFollow, {y: camFollow.y - 25},0.2,{onComplete: Void->{
		FlxTween.tween(camFollow, {y: lavaSplash.y + 300},1.2);
		FlxTween.tween(FlxG.camera, {zoom: 0.35},1.2);
	}});

}

function splash()
{
	FlxTween.cancelTweensOf(impostor, ['scale.x', 'scale.y', 'y', 'x']);
	lavaSplash.animation.resume();
	lavaSplash.visible = true;
	
	impostor.animation.play('thumbsup');
	
	impostor.visible = false;
}

function onEvent(ev, v1, v2)
{
	switch (ev)
	{
		case '':
			switch (v1)
			{
				case 'redTurn':
					impostor.animation.play('nervous',true);


				case 'hideGame':
					FlxG.camera._fxFadeColor = FlxColor.BLACK;
					FlxTween.tween(FlxG.camera, {_fxFadeAlpha: 1}, 0.5);
					FlxTween.tween(camHUD, {alpha: 0}, 0.5);
					global.get('snowEmitter').speed.set(700,900);
					global.get('snowEmitter').frequency = 0.07;
					canReset = false;
				case 'hideGame2':
					FlxTween.tween(FlxG.camera, {_fxFadeAlpha: 1}, 2);
				case 'showEnd':
					dadGroup.visible = false;
					boyfriendGroup.visible = false;
					gfGroup.visible = false;

					stage.forEachOfType(BGSprite,(f->{
						f.alpha = 0;
					}));

					cutsceneAssets.visible = true;

					global.get('redVoters').visible = false;
					global.get('bfVoters').visible = false;

					// cutsceneAssets.alpha = 1;
					global.get('base_bg').alpha = 1;
					global.get('base_bg').zIndex = 18;
					global.get('base_stars').zIndex = 18;
					global.get('base_stars').alpha = 1;
					
					stage.remove(global.get('snowEmitter'));
					
					cutsceneAssets.add(global.get('snowEmitter'));
					global.get('snowEmitter').zIndex = -2;
					// global.get('snowEmitter').speed.set(700,900);
					// global.get('snowEmitter').frequency = 0.07;
	
					refreshZ();
					refreshZ(cutsceneAssets);
					
					isCameraOnForcedPos = true;
					snapCamFollowToPos(cliff.x + 2000, cliff.y + 300);
					
					FlxG.camera._fxFadeAlpha = 1;
					FlxG.camera._fxFadeColor = FlxColor.BLACK;
					FlxTween.tween(FlxG.camera, {_fxFadeAlpha: 0}, 0.5);
					
					FlxTween.tween(camFollow, {y: cliff.y + 400}, 1, {ease: FlxEase.sineOut});
					
					camZooming = false;
					
					// camHUD.visible = false;

					FlxG.camera.zoom = 0.5;
					defaultCamZoom = 0.5;

				case 'push':
					push();


			}
	}
}
