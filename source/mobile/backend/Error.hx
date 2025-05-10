package mobile.backend;

import flixel.FlxG;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;

class Error {
    public static function logError(errorMessage:String, fileName:String, lineNumber:Int):Void {
        // Diretório para salvar os logs
        var logDir:String = CoolUtil.getSavePath() + "/logs/";
        var logFile:String = logDir + "error_log.txt";

        // Certifique-se de que o diretório existe
        if (!FileSystem.exists(logDir)) {
            FileSystem.createDirectory(logDir);
        }

        // Mensagem de erro com timestamp
        var timestamp:String = Date.now().toString();
        var logMessage:String = "[" + timestamp + "] " + errorMessage + " (File: " + fileName + ", Line: " + lineNumber + ")";

        // Salva o log no arquivo
        try {
            var file:FileOutput = File.write(logFile, true);
            file.writeString(logMessage + "\n");
            file.close();
        } catch (e:Dynamic) {
            trace("Error saving log: " + e);
        }

        // Exibe o erro no console
        trace("Error registered: " + logMessage);

        // Exibe o erro em uma janela pop-up
        showErrorPopUp(errorMessage, fileName, lineNumber);
    }

    public static function showErrorPopUp(errorMessage:String, fileName:String, lineNumber:Int):Void {
        // Configura a mensagem do pop-up
        var title:String = "Error Detected";
        var message:String = "Error: " + errorMessage + "\nFile: " + fileName + "\nLine: " + lineNumber;

        // Mostra a janela pop-up
        CoolUtil.showPopUp(message, title);
    }
}