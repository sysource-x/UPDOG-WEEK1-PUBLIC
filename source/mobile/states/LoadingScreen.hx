package mobile.states;

import Splash;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxBar;
import flixel.ui.FlxBar.FlxBarFillDirection;

class LoadingScreen extends MusicBeatState
{
    public static var nextState:Class<FlxState>;

    public var loadingImage:FlxSprite;
    public var loadingBar:FlxBar;
    public var loadedText:FlxText;
    public var ready:Bool = false;
    public var tapped:Bool = false;
    public var minTime:Float = 3; // 3 segundos fixos
    var elapsedTime:Float = 0;

    public function new()
    {
        super();

        add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xfffde871));

        loadingImage = new FlxSprite(0, 0, Paths.image('menuBG'));
        loadingImage.setGraphicSize(0, FlxG.height);
        loadingImage.updateHitbox();
        loadingImage.screenCenter();
        add(loadingImage);

        loadingBar = new FlxBar(0, FlxG.height - 26, FlxBarFillDirection.LEFT_TO_RIGHT, FlxG.width, 26);
        add(loadingBar);

        loadedText = new FlxText(loadingBar.x, loadingBar.y + 4, FlxG.width, 'Loading...', 16);
        loadedText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, "center");
        add(loadedText);

        ready = false;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        elapsedTime += elapsed;

        if (!ready && elapsedTime >= minTime) {
            ready = true;
            loadedText.text = "Completed! Tap to continue...";
            loadingBar.value = loadingBar.max;
        }

        if (ready) {
            if (!tapped && (FlxG.mouse.justPressed || FlxG.touches.justStarted().length > 0)) {
                tapped = true;
                FlxG.sound.play(Paths.sound('confirmMenu'));
                FlxG.switchState(() -> Type.createInstance(nextState, []));
            }
        }
    }
}