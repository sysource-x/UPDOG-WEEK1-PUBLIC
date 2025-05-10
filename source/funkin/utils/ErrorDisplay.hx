package util;

import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import haxe.CallStack;

class ErrorDisplay extends FlxSpriteGroup {
    public static var instance:ErrorDisplay;

    private var errorText:FlxText;
    private var bg:FlxSpriteGroup;

    public function new() {
        super();

        // Fundo semitransparente
        bg = new FlxSpriteGroup();
        FlxSpriteUtil.drawRect(bg, 0, 0, FlxG.width, FlxG.height, FlxColor.fromRGB(0, 0, 0, 180));
        add(bg);

        // Caixa de erro (texto)
        errorText = new FlxText(40, 40, FlxG.width - 80, "", 16);
        errorText.setFormat("VCR OSD Mono", 16, FlxColor.RED, "left");
        errorText.scrollFactor.set();
        errorText.borderStyle = FlxTextBorderStyle.OUTLINE;
        errorText.borderColor = FlxColor.BLACK;
        errorText.wordWrap = true;
        errorText.maxLines = 50; // suporta vários erros
        add(errorText);

        // Botão OK para fechar
        var closeButton = new FlxButton(FlxG.width / 2 - 40, FlxG.height - 60, "OK", function () {
            if (instance != null) {
                FlxG.state.remove(instance);
                instance = null;
            }
        });
        closeButton.label.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, "center");
        add(closeButton);
    }

    public static function show(error:Dynamic, ?state:FlxState):Void {
        var targetState = state != null ? state : FlxG.state;

        if (instance == null) {
            instance = new ErrorDisplay();
            targetState.add(instance);
        }

        var locationInfo = getCallerInfo();
        var message = "[ERROR] in " + locationInfo + ":\n" + Std.string(error);
        instance.errorText.text += message + "\n\n";
    }

    private static function getCallerInfo():String {
        var stack = CallStack.callStack();
        for (i in 0...stack.length) {
            switch (stack[i]) {
                case CFunction:
                case Module(m):
                case Method(classname, method): return classname + "." + method;
                case FilePos(_, file, line, _): return file + ":" + line;
                default:
            }
        }
        return "Unknown location";
    }
}
