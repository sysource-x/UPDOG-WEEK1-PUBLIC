#if !macro
// flixel
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxBasic;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.util.FlxDestroyUtil;
#if sys
import sys.io.*;
import sys.*;
#end
#if DISCORD_ALLOWED
import funkin.api.Discord;
import funkin.api.Discord.DiscordClient;
#end
#if VIDEOS_ALLOWED
import hxvlc.flixel.*;
#end
import Init;
import funkin.Paths;
import funkin.data.ClientPrefs;
import funkin.data.Conductor;
import funkin.utils.CoolUtil;
import funkin.data.Highscore;
import funkin.states.*;
import funkin.objects.BGSprite;
import funkin.backend.MusicBeatState;

//Mobile Controls
import mobile.flixel.FlxHitbox;
import mobile.flixel.FlxVirtualPad;
import mobile.flixel.input.FlxMobileInputID;
import mobile.states.LoadingScreen;
import mobile.states.NativeAPI;

using StringTools;
#end
