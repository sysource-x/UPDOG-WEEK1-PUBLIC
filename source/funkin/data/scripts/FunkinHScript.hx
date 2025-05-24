package funkin.data.scripts;

import mobile.scripting.HScript;
import flixel.FlxState;
import funkin.data.scripts.FunkinScript;
import funkin.data.scripts.ScriptType;

/**
 * Implementação de FunkinScript usando HScript.
 * Permite executar, acessar e manipular scripts .hx/.hscript com tratamento de erro detalhado.
 */
class FunkinHScript extends FunkinScript {
    public var hscript:HScript;

    /**
     * Cria um novo FunkinHScript a partir de um caminho de script.
     * @param path Caminho do script (ex: "assets/shared/scripts/meuscript.hx")
     */
    public function new(path:String) {
        super();
        scriptType = ScriptType.HSCRIPT;
        scriptName = path;
        hscript = new HScript(path);
        hscript.onCreate(path);
    }

    /**
     * Para a execução do script, se aplicável.
     */
    override public function stop() {
        // Implemente se quiser parar a execução do script, se necessário
    }

    /**
     * Define uma variável no contexto do script.
     * @param variable Nome da variável.
     * @param data Valor a ser atribuído.
     */
    override public function set(variable:String, data:Dynamic):Void {
        hscript.set(variable, data);
    }

    /**
     * Obtém o valor de uma variável do script.
     * @param key Nome da variável.
     * @return Valor da variável.
     */
    override public function get(key:String):Dynamic {
        return hscript.get(key);
    }

    /**
     * Chama uma função definida no script.
     * @param func Nome da função.
     * @param args Argumentos opcionais.
     * @return Valor de retorno da função, se houver.
     */
    override public function call(func:String, ?args:Array<Dynamic>):Dynamic {
        return hscript.call(func, args);
    }

    /**
     * Escreve uma mensagem de trace no contexto do script.
     * @param text Texto a ser exibido.
     */
    override public function scriptTrace(text:String) {
        hscript.trace(text);
    }

    /**
     * (Opcional) Recarrega o script do arquivo.
     */
    public function reload() {
        hscript.reload();
    }

    /**
     * (Opcional) Define o "parent" do script, útil para integração com outros objetos.
     */
    public function setParent(parent:Dynamic) {
        hscript.setParent(parent);
    }

    /**
     * (Opcional) Retorna o nome do arquivo do script.
     */
    public function getFileName():String {
        return hscript.fileName;
    }
}

/*
Exemplo de uso:

import funkin.data.scripts.FunkinHScript;

var script = new FunkinHScript("assets/shared/scripts/meuscript.hx");
script.call("onCreate");
script.set("score", 1000);
var valor = script.get("score");
script.scriptTrace("Script carregado com sucesso!");
script.reload();
*/