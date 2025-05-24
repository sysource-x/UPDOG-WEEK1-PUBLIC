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
    private static inline function get_defines()
        return __getDefines();

    private static macro function __getDefines() {
        #if display
        return macro $v{[]};
        #else
        return macro $v{Context.getDefines()};
        #end
    }
    #end
}