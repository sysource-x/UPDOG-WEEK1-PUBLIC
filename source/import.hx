#if !macro
// flixel
import flixel.*;
import flixel.math.*;
import flixel.text.*;
import flixel.util.*;
import flixel.tweens.*;
import flixel.sound.*;
#if sys
import sys.io.*;
import sys.*;
#end
// #if DISCORD_ALLOWED
// import funkin.api.Discord;
// import funkin.api.Discord.DiscordClient;
// #end
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

//Mobile Controls/FlxButtons
import android.flixel.*;
import android.backend.*;
import android.states.*;

using StringTools;
#end
