package mobile.states;

import funkin.states.TitleState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.text.FlxTextAlign;
import flixel.util.FlxColor;
import flixel.ui.FlxBar;
import flixel.ui.FlxBar.FlxBarFillDirection;
import openfl.utils.Assets;
import flixel.util.FlxTimer;

class StartBG extends MusicBeatState
{
    public var loadingImage:FlxSprite;
    public var loadingBar:FlxBar;
    public var loadedText:FlxText;
    public var ready:Bool = false;
    public var tapped:Bool = false;
    public var minTime:Float = 3; // segundos mínimos de loading
    var elapsedTime:Float = 0;
    var assetsToLoad:Array<String>;
    var loadedAssets:Int = 0;
    var totalAssets:Int = 0;

    public function new()
    {
        super();

        // Só mostra a tela se for a primeira vez
        if (FlxG.save.data.loadedOnce == true) {
            FlxG.switchState(new TitleState());
            return;
        }

        add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xfffde871));

        loadingImage = new FlxSprite(0, 0, Paths.image('menuBG'));
        loadingImage.setGraphicSize(0, FlxG.height);
        loadingImage.updateHitbox();
        loadingImage.screenCenter();
        add(loadingImage);

        loadingBar = new FlxBar(0, FlxG.height - 26, FlxBarFillDirection.LEFT_TO_RIGHT, FlxG.width, 26);
        add(loadingBar);

        loadedText = new FlxText(loadingBar.x, loadingBar.y + 4, FlxG.width, '', 16);
        loadedText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, FlxTextAlign.CENTER);
        add(loadedText);

        // Liste todos os assets que você quer garantir que estejam carregados
        // Carrega todos os arquivos de assets/ e content/ (qualquer extensão)
        assetsToLoad = Assets.list().filter(path ->
            path.startsWith("assets/") || path.startsWith("content/")
        );
        totalAssets = assetsToLoad.length;
        loadedAssets = 0;

        if (totalAssets == 0) {
            // Se não houver assets, só espera o tempo mínimo
            ready = false;
        } else {
            loadNextAsset();
        }
    }

    function loadNextAsset()
    {
        if (loadedAssets < totalAssets) {
            var asset = assetsToLoad[loadedAssets];
            if (asset.endsWith(".png")) {
                Assets.loadBitmapData(asset).onComplete(_ -> {
                    loadedAssets++;
                    updateBar();
                    loadNextAsset();
                });
            } else if (asset.endsWith(".ogg") || asset.endsWith(".mp3")) {
                Assets.loadSound(asset).onComplete(_ -> {
                    loadedAssets++;
                    updateBar();
                    loadNextAsset();
                });
            } else if (
                asset.endsWith(".json") ||
                asset.endsWith(".txt") ||
                asset.endsWith(".hx") ||
                asset.endsWith(".sml") ||
                asset.endsWith(".frag")
            ) {
                Assets.loadText(asset).onComplete(_ -> {
                    loadedAssets++;
                    updateBar();
                    loadNextAsset();
                });
            } else if (
                asset.endsWith(".ttf") ||
                asset.endsWith(".otf") ||
                asset.endsWith(".mp4")
            ) {
                // Não há loader assíncrono para esses tipos, apenas conta como carregado
                loadedAssets++;
                updateBar();
                loadNextAsset();
            } else {
                // Outros tipos, apenas conta como carregado
                loadedAssets++;
                updateBar();
                loadNextAsset();
            }
        } else {
            ready = true;
            updateBar();
        }
    }

    function updateBar()
    {
        loadingBar.setRange(0, totalAssets);
        loadingBar.value = loadedAssets;
        loadedText.text = '${loadedAssets}/${totalAssets}';
        loadingBar.percent = totalAssets > 0 ? Math.min((loadedAssets / totalAssets) * 100, 100) : 100;
        if (loadedAssets >= totalAssets) {
            loadedText.text = "Completed! Tap to continue...";
        }
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        elapsedTime += elapsed;

        // Só libera se carregou tudo E passou o tempo mínimo
        if (ready && elapsedTime >= minTime) {
            if (!tapped && (FlxG.mouse.justPressed || FlxG.touches.justStarted())) {
                tapped = true;
                FlxG.sound.play(Paths.sound('confirmMenu')); // se quiser, pode tirar
                FlxG.save.data.loadedOnce = true;
                FlxG.save.flush();
                FlxG.switchState(new Splash());
            }
        }
    }
}