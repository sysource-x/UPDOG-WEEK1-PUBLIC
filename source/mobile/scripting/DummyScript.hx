package mobile.scripting;

class DummyScript extends Script {
    /**
     * Simple class for empty scripts or scripts whose language isn't imported yet.
     */
    public function new(path:String) {
        super(path);
    }

    public override function loadFromString(code:String) {
        return this;
    }

    public var variables:Map<String, Dynamic> = new Map();

    public override function get(v:String) {
        return variables.get(v);
    }

    public override function set(v:String, v2:Dynamic) {
        variables.set(v, v2);
    }

    public override function onCall(method:String, parameters:Array<Dynamic>):Dynamic {
        var func = variables.get(method);
        if (Reflect.isFunction(func))
            return (parameters != null && parameters.length > 0) ? Reflect.callMethod(null, func, parameters) : func();
        return null;
    }
}