package mobile.backend;

import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

import mobile.states.NativeAPI;

using StringTools;
using flixel.util.FlxArrayUtil;

class CrashHandler
{
	public static function init():Void
	{
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
	}

	private static function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		var errorMsg:String = "";
		if (Std.isOfType(e.error, Error)) {
			var err = cast(e.error, Error);
			errorMsg = err.message;
		} else if (Std.isOfType(e.error, ErrorEvent)) {
			var err = cast(e.error, ErrorEvent);
			errorMsg = err.text;
		} else {
			errorMsg = Std.string(e.error);
		}

		var stack = haxe.CallStack.exceptionStack();
		var errorList:Array<String> = [];

		for (item in stack) {
			switch (item) {
				case FilePos(parent, file, line, col):
					var funcName = "";
					switch (parent) {
						case Method(cla, func):
							funcName = '.$func';
						case _:
							funcName = '';
					}
					errorList.push('${file}:${line}${funcName}');
				case Module(c):
					errorList.push('Module: ${c}');
				case CFunction:
					errorList.push('Native/C Function');
				case LocalFunction(v):
					errorList.push('Local Function: ${v}');
				case Method(cl, m):
					errorList.push('${cl}.${m}');
			}
		}

		var stackMsg = errorList.length > 0 ? errorList.join('\n') : "[Sem stacktrace]";
		var fullMsg = 'Error: $errorMsg\n\nStacktrace:\n$stackMsg';

		// CoolUtil trocado pelo NativeAPI
		NativeAPI.showMessageBox("Error!", fullMsg);

		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end
		lime.system.System.exit(1);
	}

	#if (cpp || hl)
	private static function onError(message:Dynamic):Void
	{
		final log:Array<String> = [];

		if (message != null && message.length > 0)
			log.push(message);

		log.push(haxe.CallStack.toString(haxe.CallStack.exceptionStack(true)));

		#if sys
		saveErrorMessage(log.join('\n'));
		#end

		// CoolUtil trocado por NativeAPI
		NativeAPI.showMessageBox("Critical Error!", log.join('\n'));
		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end
		lime.system.System.exit(1);
	}
	#end

	#if sys
	private static function saveErrorMessage(message:String):Void
	{
		try
		{
			if (!FileSystem.exists('logs'))
				FileSystem.createDirectory('logs');

			File.saveContent('logs/'
				+ Date.now().toString().replace(' ', '-').replace(':', "'")
				+ '.txt', message);
		}
		catch (e:haxe.Exception)
			trace('Couldn\'t save error message. (${e.message})');
	}
	#end
}
