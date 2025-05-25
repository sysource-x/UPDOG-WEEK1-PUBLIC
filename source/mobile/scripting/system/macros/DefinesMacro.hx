package mobile.scripting.system.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class DefinesMacro {
    /**
     * Returns the defined values
     */
    public static var defines(get, null):Map<String, Dynamic>;

    #if macro
    public static function get_defines():Map<String, Dynamic> {
        return new Map();
    }
    #end
}