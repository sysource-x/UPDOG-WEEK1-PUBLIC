package mobile.scripting;

import haxe.io.Path;
import hscript.Expr.Error;
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;
import openfl.utils.Assets;

/**
 * @author: CodenameEngine & GBLStudios
 * 
 * HScript is a wrapper for the Haxe Scripting Language (HScript).
 * It allows you to execute HScript code within your application.
 *
 * This class is part of the mobile.scripting package and extends the Script class.
 *
 * @see https://haxe.org/manual/hscript.html
 **/

class HScript extends Script {
    public var interp:Interp;
    public var parser:Parser;
    public var expr:Expr;
    public var code:String = null;
    var __importedPaths:Array<String>;

    private static final SCRIPT_SEARCH_PATHS:Array<String> = [
        "assets/source/",
        "assets/shared/scripts/",
        "assets/shared/stages/",
        "assets/shared/characters/"
    ];

    public static function initParser() {
        var parser = new Parser();
        parser.allowJSON = parser.allowMetadata = parser.allowTypes = true;
        #if (hscript >= "2.5.0")
        parser.preprocesorValues = Script.getDefaultPreprocessors();
        #end
        return parser;
    }

    public override function onCreate(path:String) {
        super.onCreate(path);

        interp = new Interp();

        try {
            if(Assets.exists(rawPath)) code = Assets.getText(rawPath);
        } catch(e) Logs.trace('Error while reading $path: ${Std.string(e)}', ERROR);

        parser = initParser();
        __importedPaths = [path];

        interp.errorHandler = _errorHandler;
        interp.importFailedCallback = importFailedCallback;
        interp.staticVariables = Script.staticVariables;
        interp.allowStaticVariables = interp.allowPublicVariables = true;

        interp.variables.set("trace", Reflect.makeVarArgs((args) -> {
            var v:String = Std.string(args.shift());
            for (a in args) v += ", " + Std.string(a);
            this.trace(v);
        }));

        #if GLOBAL_SCRIPT
        mobile.scripting.GlobalScript.call("onScriptCreated", [this, "hscript"]);
        #end
        loadFromString(code);
    }

    public override function loadFromString(code:String) {
        try {
            if (code != null && code.trim() != "")
                expr = parser.parseString(code, fileName);
        } catch(e:Error) {
            _errorHandler(e);
        } catch(e) {
            _errorHandler(new Error(ECustom(e.toString()), 0, 0, fileName, 0));
        }

        return this;
    }

    private function importFailedCallback(cl:Array<String>):Bool {
        for (searchPath in SCRIPT_SEARCH_PATHS) {
            var assetsPath = '$searchPath${cl.join("/")}';
            for (hxExt in ["hx", "hscript", "hsc", "hxs"]) {
                var p = '$assetsPath.$hxExt';
                if (__importedPaths.contains(p))
                    return true; // no need to reimport again
                if (Assets.exists(p)) {
                    var code = Assets.getText(p);
                    var expr:Expr = null;
                    try {
                        if (code != null && code.trim() != "") {
                            parser.line = 1;
                            expr = parser.parseString(code, cl.join("/") + "." + hxExt);
                        }
                    } catch(e:Error) {
                        _errorHandler(e);
                    } catch(e) {
                        _errorHandler(new Error(ECustom(e.toString()), 0, 0, fileName, 0));
                    }
                    if (expr != null) {
                        @:privateAccess
                        interp.exprReturn(expr);
                        __importedPaths.push(p);
                    }
                    return true;
                }
            }
        }
        return false;
    }

    private function _errorHandler(error:Error) {
        var fileName = error.origin;
        if (remappedNames != null && remappedNames.exists(fileName))
            fileName = remappedNames.get(fileName);
        var fn = '$fileName:${error.line}: ';
        var err = error.toString();
        if (err.startsWith(fn)) err = err.substr(fn.length);

        Logs.traceColored([
            Logs.logText(fn, GREEN),
            Logs.logText(err, RED)
        ], ERROR);

        #if mobile
        mobile.scripting.NativeAPI.showMessageBox("HSCRIPT ERROR", fn + err, MSG_ERROR);
        #end
    }

    public override function setParent(parent:Dynamic) {
        interp.scriptObject = parent;
    }

    public override function onLoad() {
        @:privateAccess
        interp.execute(parser.mk(EBlock([]), 0, 0));
        if (expr != null) {
            interp.execute(expr);
            call("new", []);
        }

        #if GLOBAL_SCRIPT
        mobile.scripting.GlobalScript.call("onScriptSetup", [this, "hscript"]);
        #end
    }

    public override function reload() {
        interp.allowStaticVariables = interp.allowPublicVariables = false;
        var savedVariables:Map<String, Dynamic> = [];
        for(k=>e in interp.variables) {
            if (!Reflect.isFunction(e)) {
                savedVariables[k] = e;
            }
        }
        var oldParent = interp.scriptObject;
        onCreate(path);

        for(k=>e in Script.getDefaultVariables(this))
            set(k, e);

        load();
        setParent(oldParent);

        for(k=>e in savedVariables)
            interp.variables.set(k, e);

        interp.allowStaticVariables = interp.allowPublicVariables = true;
    }

    private override function onCall(funcName:String, parameters:Array<Dynamic>):Dynamic {
        if (interp == null) return null;
        if (!interp.variables.exists(funcName)) return null;

        var func = interp.variables.get(funcName);
        if (func != null && Reflect.isFunction(func))
            return Reflect.callMethod(null, func, parameters);

        return null;
    }

    public override function get(val:String):Dynamic {
        return interp.variables.get(val);
    }

    public override function set(val:String, value:Dynamic) {
        interp.variables.set(val, value);
    }

    public override function trace(v:Dynamic) {
        var posInfo = interp.posInfos();
        Logs.traceColored([
            Logs.logText('${fileName}:${posInfo.lineNumber}: ', GREEN),
            Logs.logText(Std.isOfType(v, String) ? v : Std.string(v))
        ], TRACE);
    }

    public override function setPublicMap(map:Map<String, Dynamic>) {
        this.interp.publicVariables = map;
    }
}