package mobile.states;

import funkin.states.TitleState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxTextAlign;
import flixel.util.FlxColor;
import flixel.ui.FlxBar;
import flixel.ui.FlxBar.FlxBarFillDirection;

class StartBG extends MusicBeatState
{
    public var loadingImage:FlxSprite;
    public var loadingBar:FlxBar;
    public var loadedText:FlxText;
    public var maxLoopTimes:Int = 3; // no instant load, this are like 3 seconds
    public var loopTimes:Int = 0;
    public var canUpdate:Bool = true;
    public var ready:Bool = false;
    public var tapped:Bool = false;

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
        loadingBar.setRange(0, maxLoopTimes);
        add(loadingBar);

        loadedText = new FlxText(loadingBar.x, loadingBar.y + 4, FlxG.width, '', 16);
        loadedText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, FlxTextAlign.CENTER);
        add(loadedText);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (canUpdate && loopTimes < maxLoopTimes)
        {
            loopTimes++;
            loadingBar.value = loopTimes;
            loadedText.text = '$loopTimes/$maxLoopTimes';
            loadingBar.percent = Math.min((loopTimes / maxLoopTimes) * 100, 100);
        }
        else if (loopTimes >= maxLoopTimes)
        {
            loadedText.text = "Completed! Tap to continue...";
            ready = true;
            canUpdate = false;
        }

        // Ao tocar/clicar, toca o som e vai para TitleState
        if (ready && !tapped && (FlxG.mouse.justPressed || FlxG.touches.justStarted()))
        {
            tapped = true;
            FlxG.sound.play(Paths.sound('confirmMenu'));
            FlxG.switchState(new TitleState());
        }
    }

    /**
     * Show a quick loading animation.
     * Example: StartBG.showQuickLoading("algumaImagem", function() {
     *     // Código após o loading rápido
     * });
     * 
     * author: @GBLStudios_u5v(youtube channel)
     * 
     * @param imagePath 
     * @param onComplete 
     */
    public static function showQuickLoading(imagePath:String, onComplete:Void->Void)
    {
        var loading = new FlxSprite(0, 0, Paths.image(imagePath));
        loading.setGraphicSize(0, FlxG.height);
        loading.screenCenter();
        FlxG.state.add(loading);

        FlxTimer.wait(1, function(_) {
            loading.kill();
            if (onComplete != null) onComplete();
        });
    }
}