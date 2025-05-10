package mobile.backend;

import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

/*
 *
 * @author: Glauber (sysource_xyz)
 *
*/

class Error {
    private static var errorList:Array<String> = []; // Lista de erros acumulados
    private static var errorState:FlxState = null;  // Estado de exibição de erros

    public static function logError(errorMessage:String):Void {
        // Adiciona o erro à lista
        errorList.push(errorMessage);

        // Exibe o erro no console
        trace("Erro registrado: " + errorMessage);
    }

    public static function showErrorScreen():Void {
        // Cria um novo estado para exibir os erros
        errorState = new FlxState();

        // Fundo da tela
        var bg:FlxGroup = new FlxGroup();
        var background:FlxText = new FlxText(0, 0, FlxG.width, "");
        background.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.add(background);
        errorState.add(bg);

        // Título
        var title:FlxText = new FlxText(0, 10, FlxG.width, "Error List");
        title.setFormat(null, 24, FlxColor.RED, "center");
        errorState.add(title);

        // Lista de erros
        var errorText:FlxText = new FlxText(10, 50, FlxG.width - 20, errorList.join("\n\n"));
        errorText.setFormat(null, 16, FlxColor.WHITE, "left");
        errorText.scrollFactor.set(); // Permite rolar o texto
        errorState.add(errorText);

        // Botão "LEAVE" para sair do jogo
        var leaveButton:FlxButton = new FlxButton(FlxG.width / 2 - 100, FlxG.height - 60, "LEAVE", function() {
            Sys.exit(0); // Sai do jogo
        });
        leaveButton.setGraphicSize(200, 40);
        leaveButton.color = FlxColor.RED;
        errorState.add(leaveButton);

        // Botão "OK" para fechar a janela de erros
        var okButton:FlxButton = new FlxButton(FlxG.width / 2 + 10, FlxG.height - 60, "OK", function() {
            FlxG.switchState(FlxG.state); // Retorna ao estado anterior
        });
        okButton.setGraphicSize(200, 40);
        okButton.color = FlxColor.GREEN;
        errorState.add(okButton);

        // Exibe o estado de erros
        FlxG.switchState(errorState);
    }
}