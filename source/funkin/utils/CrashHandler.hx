package funkin.utils;

import lime.system.System;
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import haxe.CallStack;
import flixel.FlxG;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;

class CrashHandler {
    private static var errorList:Array<String> = []; // Lista de erros acumulados
    private static var initialized:Bool = false;

    public static function init():Void {
        if (initialized) return;
        initialized = true;

        // Captura erros não tratados
        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);

        #if cpp
        untyped __global__.__hxcpp_set_critical_error_handler(onError);
        #elseif hl
        hl.Api.setErrorHandler(onError);
        #end
    }

    private static function onUncaughtError(e:UncaughtErrorEvent):Void {
        var message:String = Std.string(e.error);
        if (Std.isOfType(e.error, Error)) {
            var err = cast(e.error, Error);
            message = err.message;
        } else if (Std.isOfType(e.error, ErrorEvent)) {
            var err = cast(e.error, ErrorEvent);
            message = err.text;
        }

        var stackTrace = getStackTrace();
        logError("Uncaught Error: " + message + "\n\n" + stackTrace);

        e.preventDefault();
        e.stopPropagation();
        e.stopImmediatePropagation();

        showErrorScreen();
    }

    private static function getStackTrace():String {
        var stack = CallStack.exceptionStack();
        var stackTrace = "";
        for (entry in stack) {
            switch (entry) {
                case CFunction:
                    stackTrace += "Non-Haxe (C) Function\n";
                case Module(c):
                    stackTrace += "Module $c\n";
                case FilePos(parent, file, line, col):
                    switch (parent) {
                        case Method(className, method):
                            stackTrace += "($file) $className.$method() - line $line\n";
                        default:
                            stackTrace += "($file) - line $line\n";
                    }
                case LocalFunction(name):
                    stackTrace += "Local Function $name\n";
                case Method(className, method):
                    stackTrace += "$className - $method\n";
            }
        }
        return stackTrace;
    }

    public static function logError(errorMessage:String):Void {
        // Adiciona o erro à lista
        errorList.push(errorMessage);

        // Exibe o erro no console
        trace("Erro registrado: " + errorMessage);
    }

    public static function showErrorScreen():Void {
        var errorState = new FlxState();

        // Fundo da tela
        var background:FlxText = new FlxText(0, 0, FlxG.width, "");
        background.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        errorState.add(background);

        // Título
        var title:FlxText = new FlxText(0, 10, FlxG.width, "Crash Report");
        title.setFormat(null, 24, FlxColor.RED, "center");
        errorState.add(title);

        // Lista de erros
        var errorText:FlxText = new FlxText(10, 50, FlxG.width - 20, errorList.join("\n\n"));
        errorText.setFormat(null, 16, FlxColor.WHITE, "left");
        errorText.scrollFactor.set(); // Permite rolar o texto
        errorState.add(errorText);

        // Botão "OK" para fechar a janela de erros
        var okButton:FlxButton = new FlxButton(FlxG.width / 2 - 50, FlxG.height - 60, "OK", function() {
            FlxG.switchState(FlxG.state); // Retorna ao estado anterior
        });
        okButton.setGraphicSize(100, 40);
        okButton.color = FlxColor.GREEN;
        errorState.add(okButton);

        // Exibe o estado de erros
        FlxG.switchState(errorState);
    }

    public static function showSingleError(errorMessage:String):Void {
        logError(errorMessage); // Registra o erro
        showErrorScreen(); // Exibe a tela de erros
    }

    #if (cpp || hl)
    private static function onError(message:Dynamic):Void {
        logError("Critical Error: " + Std.string(message));
        showErrorScreen();
    }
    #end
}