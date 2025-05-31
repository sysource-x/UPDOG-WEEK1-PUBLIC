package mobile.backend;

import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.group.FlxTypedGroup;

class ErrorCaught
{
    public static function showError(e:Dynamic)
    {
        var errorMsg = "";
        if (Std.isOfType(e, haxe.Exception))
            errorMsg = cast(e, haxe.Exception).message;
        else if (Std.isOfType(e, String))
            errorMsg = cast(e, String);
        else
            errorMsg = Std.string(e);

        var stack = haxe.CallStack.exceptionStack(true);
        var list:Array<String> = [];
        for (item in stack)
        {
            switch (item)
            {
                case FilePos(_, file, line, _):
                    list.push('$file (linha $line)');
                default:
            }
        }
        if (list.length == 0) list.push("[Without stacktrace]");

        var title = list[0].split("/").pop().split("\\").pop(); // só o nome do arquivo
        FlxG.switchState(new ErrorCaughtState(title, errorMsg, list));
    }
}

class ErrorCaughtState extends FlxState
{
    var msg:String;
    var title:String;
    var stack:Array<String>;
    var scroll:FlxTypedGroup<FlxText>;
    var scrollPos:Int = 0;

    public function new(title:String, msg:String, stack:Array<String>)
    {
        super();
        this.title = title;
        this.msg = msg;
        this.stack = stack;
    }

    override public function create()
    {
        super.create();
        var t = new FlxText(0, 10, FlxG.width, "File error: " + title, 24);
        t.setFormat(null, 24, 0xFFFF0000, "center");
        add(t);

        var m = new FlxText(0, 50, FlxG.width, "Message: " + msg, 16);
        m.setFormat(null, 16, 0xFFFFFFFF, "center");
        add(m);

        scroll = new FlxTypedGroup<FlxText>();
        add(scroll);

        updateList();

        var btn = new FlxButton(FlxG.width/2 - 40, FlxG.height - 40, "Close", function()
        {
            FlxG.resetState();
        });
        add(btn);
    }

    function updateList()
    {
        scroll.clear();
        var maxVisible = Std.int((FlxG.height - 120) / 20);
        for (i in 0...maxVisible)
        {
            var idx = scrollPos + i;
            if (idx >= stack.length) break;
            var f = new FlxText(0, 90 + i * 20, FlxG.width, stack[idx], 14);
            f.setFormat(null, 14, 0xFFAAAAAA, "center");
            scroll.add(f);
        }
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        // Scroll com seta para cima/baixo
        if (FlxG.keys.justPressed.UP && scrollPos > 0) {
            scrollPos--;
            updateList();
        }
        if (FlxG.keys.justPressed.DOWN && scrollPos < stack.length - 1) {
            scrollPos++;
            updateList();
        }
    }
}