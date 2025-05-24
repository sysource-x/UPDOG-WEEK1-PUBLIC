package mobile.scripting;

import haxe.Log;
import mobile.scripting.NativeAPI;
import mobile.scripting.NativeAPI.ConsoleColor;

class Logs {
    private static var __showing:Bool = false;

    public static var nativeTrace = Log.trace;

    public static function trace(msg:String, ?type:Dynamic, ?color:ConsoleColor) {
        #if sys
        Sys.println(msg);
        #else
        trace(msg);
        #end
    }

    public static function traceColored(arr:Array<LogText>, ?type:Dynamic) {
        var msg = [for (e in arr) e.text].join("");
        trace(msg);
    }

    public static function logText(text:String, color:ConsoleColor = ConsoleColor.LIGHTGRAY):LogText {
        return { text: text, color: color };
    }
}

typedef LogText = {
    var text:String;
    var color:ConsoleColor;
}