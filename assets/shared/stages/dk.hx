
import openfl.filters.ShaderFilter;
import funkin.states.substates.GameOverSubstate;
import funkin.objects.video.FunkinVideoSprite;
import funkin.modchart.modifiers.AlphaModifier;
import funkin.modchart.modifiers.ScaleModifier;
import funkin.modchart.modifiers.TransformModifier;
import funkin.modchart.Modifier.ModifierType;
import funkin.modchart.Modifier;

var ext:String = 'stage/secret/'; // Edit secret to your stage name.
var video:FunkinVideoSprite;
var blackSprite:FlxSprite;
var ohioSprite:FlxSprite;

function onLoad() {

    var bytes = Assets.getBytes('assets/videos/banana.mp4');
    
    video = new FunkinVideoSprite(200,0).preload(bytes, [FunkinVideoSprite.MUTED]);
  	add(video);
    
    var bg:FlxSprite = new FlxSprite(0, 0);
    bg.loadGraphic(Paths.image(ext + "sky"));
    bg.scrollFactor.set(1,1);

    ohioSprite = new FlxSprite(0, 0).makeGraphic(1280, 720, 0xffffffff);
    ohioSprite.alpha = 0;
    ohioSprite.cameras = [camPause];
	add(ohioSprite);
    
    var bushes:FlxSprite = new FlxSprite(300, 225);
    bushes.loadGraphic(Paths.image(ext + "skyass"));
    bushes.scrollFactor.set(0.75,0.75);
    bushes.scale.set(0.5,0.5);

    var stars:FlxSprite = new FlxSprite(0, -75);
    stars.loadGraphic(Paths.image(ext + "tree3"));
    stars.scrollFactor.set(0.8,0.8);

    var mountains:FlxSprite = new FlxSprite(0, -75);
    mountains.loadGraphic(Paths.image(ext + "tree2"));
    mountains.scrollFactor.set(0.85,0.85);

    var mountains2:FlxSprite = new FlxSprite(0, -75);
    mountains2.loadGraphic(Paths.image(ext + "tree"));
    mountains2.scrollFactor.set(0.9,0.9);

    var floor:FlxSprite = new FlxSprite(0, 0);
    floor.loadGraphic(Paths.image(ext + "background"));

    GameOverSubstate.characterName = 'diddy-dead';
	GameOverSubstate.deathSoundName = 'diddyscream';
	GameOverSubstate.loopSoundName = 'GameOverDK';
	GameOverSubstate.endSoundName = 'GameOverDK_end';
    // overlay stuff haha hey

    FlxG.scaleMode.width = 960;    
    FlxG.camera.width = 960;
    game.camHUD.width = 960;
    //game.playHUD.healthBar.screenCenter(FlxAxes.X);
    //game.playHUD.scoreTxt.screenCenter(FlxAxes.X);

    anotherCam = new FlxCamera(0, 0, 1280, 720, 1);
    anotherCam.bgColor = 0x0;
    insertFlxCamera(FlxG.cameras.list.indexOf(game.camPause), anotherCam, false);

    blackSprite = new FlxSprite(0, 0).makeGraphic(1280, 720, 0xff000000);
    blackSprite.alpha = 1;
    blackSprite.cameras = [anotherCam];
    add(blackSprite); 

    if (ClientPrefs.shaders) {
        var vhs:FlxShader = newShader('rozebud');
        var filter:ShaderFilter = new ShaderFilter(vhs); // I'll rewrite this slightly to make it to use an for i loop
        
        game.camHUD.filters = [filter];
        game.camGame.filters = [filter];
        camPause.filters = [filter];
    }

    for(i in [bg, bushes, stars, mountains, mountains2, floor]) {

        i.antialiasing = ClientPrefs.globalAntialiasing;
        i.updateHitbox();
        i.scale.set(1.2,1.2);
        add(i);
    }
}

function insertFlxCamera(idx:Int,cam:FlxCamera,defDraw:Bool) {
    var cameras = [
        for (i in FlxG.cameras.list) {
            cam: i,
            defaultDraw: FlxG.cameras.defaults.contains(i)
        }
    ];

    for(i in cameras) FlxG.cameras.remove(i.cam, false);

    cameras.insert(idx, {cam: cam,defaultDraw: defDraw});

    for (i in cameras) FlxG.cameras.add(i.cam,i.defaultDraw);
}

function postModifierRegister()
{
    modManager.quickRegister(new AlphaModifier(modManager));
    modManager.quickRegister(new TransformModifier(modManager));
    modManager.quickRegister(new ScaleModifier(modManager));

    modManager.setValue("transformX", 75, 0);
    modManager.setValue("transformX", -75, 1);
    modManager.setValue("miniX", -3);
    modManager.setValue("miniY", -3);
    modManager.setValue("alpha", 1, 1);
}

function onCreatePost()
{   
    video.cameras = [camHUD];
  	video.onReady.addOnce(()->{
        video.setGraphicSize(0,722);
 		video.updateHitbox();
  		video.screenCenter(FlxAxes.X);
 
  	});

    game.playHUD.showRating = false;
    game.playHUD.showCombo = false;
    game.playHUD.scoreTxt.visible = false;
    game.playHUD.healthBar.visible = false;
    game.playHUD.iconP1.visible = false;
    game.playHUD.iconP2.visible = false;
}   

function onSpawnNotePost(note:Note) // No longer need to modify clientprefs for this to work.
{
    if (note.mustPress == true) {
        note.noteSplashDisabled = true;
    }
    note.visible = note.mustPress;
}

function onSongStart()
{
    FlxTween.tween(blackSprite, {alpha: 0}, 0.05, {ease: FlxEase.linear, startDelay: 0.05});
    video.playVideo();
}

function onDestroy()
{
    FlxG.scaleMode.width = 1280; 
    FlxG.camera.width = 1280;
}

function onEvent(eventName, value1, value2)
{   
    switch(eventName) 
    {
        case 'orange':
            switch(value1)
            {
                case 'dk':
                    FlxG.camera.zoom -= 0.1;
                    FlxTween.tween(video, {alpha: 0}, 0.6, {ease: FlxEase.linear, onComplete: function() 
                    {
                        video.alpha = 0;
                        FlxTween.tween(ohioSprite, {alpha: 0}, 0.3, {ease: FlxEase.linear});
                    }});                       
            }
        case 'camTween':
			if (value1 == '')
			{
				game.isCameraOnForcedPos = false;
				return;
			}
			
			game.isCameraOnForcedPos = true;
			var coords = value1.split(',');
			var timing = value2.split(',');
			
			if (value2 == '' && coords.length >= 2)
			{
				var x = Std.parseFloat(coords[0]);
				var y = Std.parseFloat(coords[1]);
				game.camFollow.set(x, y);
				
				if (coords.length == 3)
				{
					var zoom = Std.parseFloat(coords[2]);
					FlxG.camera.zoom = zoom;
					game.defaultCamZoom = zoom;
				}
				return;
			}
			
			if (coords.length == 1 && timing.length == 2)
			{
				var zoom = Std.parseFloat(coords[0]);
				var time = Std.parseFloat(timing[0]);
				var easingMethod = CoolUtil.getEase(timing[1]);
				
				if (easingMethod == null)
				{
					trace('Invalid easing method: ' + timing[1]);
					return;
				}
				
				function bindZoom() game.defaultCamZoom = FlxG.camera.zoom;
				
				FlxTween.tween(FlxG.camera, {zoom: zoom}, time,
					{
						ease: easingMethod,
						onUpdate: bindZoom,
						onComplete: function(tween:FlxTween) {
							FlxTimer.wait(0, bindZoom);
						}
					});
					
				return;
			}
			
			if ((coords.length == 2 || coords.length == 3) && timing.length == 2)
			{
				var x = Std.parseFloat(coords[0]);
				var y = Std.parseFloat(coords[1]);
				var time = Std.parseFloat(timing[0]);
				var easingMethod = CoolUtil.getEase(timing[1]);
				
				if (easingMethod == null)
				{
					trace('Invalid easing method: ' + timing[1]);
					return;
				}
				
				FlxTween.tween(game.camFollow, {x: x, y: y}, time, {ease: easingMethod});
				
				if (coords.length == 3)
				{
					var zoom = Std.parseFloat(coords[2]);
					
					function bindZoom() game.defaultCamZoom = FlxG.camera.zoom;
					
					FlxTween.tween(FlxG.camera, {zoom: zoom}, time,
						{
							ease: easingMethod,
							onUpdate: bindZoom,
							onComplete: function(tween:FlxTween) {
								FlxTimer.wait(0, bindZoom);
							}
						});
				}
			}
			else
			{
				trace('Invalid input for camTween event.');
			}
    }
}
