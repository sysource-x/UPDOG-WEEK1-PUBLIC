/*
 * Copyright (C) 2025 Mobile Porting Team
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package mobile.backend;

/**
 * A storage class for mobile.
 * @author Karim Akra and Homura Akemi (HomuHomu833)
 */
#if android
import android.content.Context;
import android.widget.Toast;
import android.os.Environment;
#end
import haxe.CallStack;
import haxe.io.Path;
import lime.app.Application;
import lime.system.System as LimeSystem;
import lime.utils.Assets as LimeAssets;
import lime.utils.Log as LimeLogger;
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
 
using StringTools;

enum StorageType
{
	DATA;
	EXTERNAL;
	EXTERNAL_DATA;
	MEDIA;
}
class SUtil
{ // I'm lazy to remove the space of the functions
	    /**
	    * This returns the internal storage path that the game will use.
	    */
	    public static function getStorageDirectory(type:StorageType = MEDIA):String
		{
			var daPath:String = '';
	
			#if android
			// Internal storage for Android
			daPath = Context.getFilesDir() + '/';
			#elseif ios
			// Internal storage for iOS
			daPath = LimeSystem.applicationStorageDirectory;
			#end
	
			return daPath;
		}
	
		/**
		 * A simple function that checks for game files/folders.
		 */
		public static function checkFiles():Void
		{
			#if mobile
			// Verifica se a pasta necessária existe
			if (!FileSystem.exists(SUtil.getStorageDirectory()))
			{
				try {
					FileSystem.createDirectory(SUtil.getStorageDirectory());
				}
				catch (e){
					Lib.application.window.alert('Unable to create directory at ' + SUtil.getStorageDirectory(), 'Error!');
					LimeSystem.exit(1);
				}
			}
			// Verifica se os arquivos essenciais existem
			if (!FileSystem.exists(SUtil.getStorageDirectory() + 'assets') && !FileSystem.exists(SUtil.getStorageDirectory() + 'mods'))
			{
				Lib.application.window.alert("Missing necessary assets or mods folders. Please extract from APK.",
					'Error!');
				LimeSystem.exit(1);
			}
			else
			{
				// Verifica se os arquivos são diretórios
				if (!FileSystem.exists(SUtil.getStorageDirectory() + 'assets'))
				{
					Lib.application.window.alert("Missing 'assets' directory.", 'Error!');
					LimeSystem.exit(1);
				}
	
				if (!FileSystem.exists(SUtil.getStorageDirectory() + 'mods'))
				{
					Lib.application.window.alert("Missing 'mods' directory.", 'Error!');
					LimeSystem.exit(1);
				}
			}
			#end
		}
	
		/**
		 * Uncaught error handler, original made by: Sqirra-RNG and YoshiCrafter29
		 */
		public static function uncaughtErrorHandler():Void
		{
			Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
			Lib.application.onExit.add(function(exitCode:Int)
			{
				if (Lib.current.loaderInfo.uncaughtErrorEvents.hasEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR))
					Lib.current.loaderInfo.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
			});
		}
	
		private static function onError(e:UncaughtErrorEvent):Void
		{
			var stack:Array<String> = [];
			stack.push(e.error);
	
			for (stackItem in CallStack.exceptionStack(true))
			{
				switch (stackItem)
				{
					case CFunction:
						stack.push('C Function');
					case Module(m):
						stack.push('Module ($m)');
					case FilePos(s, file, line, column):
						stack.push('$file (line $line)');
					case Method(classname, method):
						stack.push('$classname (method $method)');
					case LocalFunction(name):
						stack.push('Local Function ($name)');
				}
			}
	
			e.preventDefault();
			e.stopPropagation();
			e.stopImmediatePropagation();
	
			final msg:String = stack.join('\n');
	
			#if sys
			try
			{
				if (!FileSystem.exists(SUtil.getStorageDirectory() + 'logs'))
					FileSystem.createDirectory(SUtil.getStorageDirectory() + 'logs');
	
				File.saveContent(SUtil.getStorageDirectory()
					+ 'logs/'
					+ Lib.application.meta.get('file')
					+ '-'
					+ Date.now().toString().replace(' ', '-').replace(':', "'")
					+ '.txt',
					msg + '\n');
			}
			catch (e:Dynamic)
			{
				#if (android && debug)
				Toast.makeText("Error!\nCouldn't save the crash dump because:\n" + e, Toast.LENGTH_LONG);
				#else
				LimeLogger.println("Error!\nCouldn't save the crash dump because:\n" + e);
				#end
			}
			#end
	
			LimeLogger.println(msg);
			Lib.application.window.alert(msg, 'Error!');
			LimeSystem.exit(1);
		}
	
		/**
		 * This is mostly a fork of https://github.com/openfl/hxp/blob/master/src/hxp/System.hx#L595
		 */
		#if sys
		public static function mkDirs(directory:String):Void
		{
			var total:String = '';
			if (directory.substr(0, 1) == '/')
				total = '/';
	
			var parts:Array<String> = directory.split('/');
			if (parts.length > 0 && parts[0].indexOf(':') > -1)
				parts.shift();
	
			for (part in parts)
			{
				if (part != '.' && part != '')
				{
					if (total != '' && total != '/')
						total += '/';
	
					total += part;
	
					if (!FileSystem.exists(total))
						FileSystem.createDirectory(total);
				}
			}
		}
	
		public static function saveContent(fileName:String = 'file', fileExtension:String = '.json',
				fileData:String = 'you forgot to add something in your code lol'):Void
		{
			try
			{
				if (!FileSystem.exists(SUtil.getStorageDirectory() + 'saves'))
					FileSystem.createDirectory(SUtil.getStorageDirectory() + 'saves');
	
				File.saveContent(SUtil.getStorageDirectory() + 'saves/' + fileName + fileExtension, fileData);
			}
			catch (e:Dynamic)
			{
				#if (android && debug)
				Toast.makeText("Error!\nCouldn't save the file because:\n" + e, Toast.LENGTH_LONG);
				#else
				LimeLogger.println("Error!\nCouldn't save the file because:\n" + e);
				#end
			}
		}
	
		/**
		 * Copies the content of copyPath and pastes it in savePath.
		 */
		public static function copyContent(copyPath:String, savePath:String):Void
		{
			try
			{
				if (!FileSystem.exists(savePath) && LimeAssets.exists(copyPath))
				{
					if (!FileSystem.exists(Path.directory(savePath)))
						SUtil.mkDirs(Path.directory(savePath));
	
					File.saveBytes(savePath, LimeAssets.getBytes(copyPath));
				}
			}
			catch (e:Dynamic)
			{
				#if (android && debug)
				Toast.makeText('Error!\nCouldn\'t copy the $copyPath because:\n' + e, Toast.LENGTH_LONG);
				#else
				LimeLogger.println('Error!\nCouldn\'t copy the $copyPath because:\n' + e);
				#end
			}
		}
		#end
	}
	/*
	----THE ORIGINAL CODE----
	#if sys
	public static function getStorageDirectory():String
		return #if android haxe.io.Path.addTrailingSlash(AndroidContext.getExternalFilesDir()) #elseif ios lime.system.System.documentsDirectory #else Sys.getCwd() #end;

	public static function saveContent(fileName:String, fileData:String, ?alert:Bool = true):Void
	{
		try
		{
			if (!FileSystem.exists('saves'))
				FileSystem.createDirectory('saves');

			File.saveContent('saves/$fileName', fileData);
			if (alert)
				CoolUtil.showPopUp('$fileName has been saved.', "Success!");
		}
		catch (e:Dynamic)
			if (alert)
				CoolUtil.showPopUp('$fileName couldn\'t be saved.\n(${e.message})', "Error!")
			else
				trace('$fileName couldn\'t be saved. (${e.message})');
	}

	#if android
	public static function requestPermissions():Void
	{
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			AndroidPermissions.requestPermissions(['READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO', 'READ_MEDIA_VISUAL_USER_SELECTED']);
		else
			AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);

		if (!AndroidEnvironment.isExternalStorageManager())
			AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');

		if ((AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU
			&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_MEDIA_IMAGES'))
			|| (AndroidVersion.SDK_INT < AndroidVersionCode.TIRAMISU
				&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE')))
			CoolUtil.showPopUp('If you accepted the permissions you are all good!' + '\nIf you didn\'t then expect a crash' + '\nPress OK to see what happens',
				'Notice!');

		try
		{
			if (!FileSystem.exists(SUtil.getStorageDirectory()))
				FileSystem.createDirectory(SUtil.getStorageDirectory());
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp('Please create directory to\n' + SUtil.getStorageDirectory() + '\nPress OK to close the game', 'Error!');
			lime.system.System.exit(1);
		}
	}
	#end
	#end
}
*/
