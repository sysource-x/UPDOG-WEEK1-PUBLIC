package funkin.states;

import haxe.ds.Vector;

import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;

import flixel.util.FlxSave;
import flixel.util.FlxStringUtil;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.util.helpers.FlxBounds;
import flixel.util.FlxSignal;

import funkin.objects.Note.EventNote;
import funkin.data.scripts.FunkinScript.ScriptType;
import funkin.huds.BaseHUD;
import funkin.data.scripts.*;
import funkin.data.scripts.FunkinLua;
import funkin.data.Section.SwagSection;
import funkin.data.Song.SwagSong;
import funkin.data.StageData;
import funkin.game.Rating;
import funkin.objects.*;
import funkin.data.*;
import funkin.states.*;
import funkin.states.substates.*;
import funkin.states.editors.*;
import funkin.data.scripts.FunkinLua.ModchartSprite;
import funkin.modchart.*;
import funkin.backend.SyncedFlxSoundGroup;
import funkin.utils.DifficultyUtil;
import funkin.game.RatingInfo;

@:structInit class SpeedEvent
{
	public var position:Float; // the y position where the change happens (modManager.getVisPos(songTime))
	public var startTime:Float; // the song position (conductor.songTime) where the change starts
	public var songTime:Float; // the song position (conductor.songTime) when the change ends
	@:optional public var startSpeed:Null<Float>; // the starting speed
	public var speed:Float; // speed mult after the change
}

class PlayState extends MusicBeatState
{
	public var modManager:ModManager;
	
	var speedChanges:Array<SpeedEvent> = [
		{
			position: 0,
			songTime: 0,
			startTime: 0,
			startSpeed: 1,
			speed: 1,
		}
	];
	
	public var currentSV:SpeedEvent =
		{
			position: 0,
			startTime: 0,
			songTime: 0,
			speed: 1,
			startSpeed: 1
		};
		
	var noteRows:Array<Array<Array<Note>>> = [[], []];
	
	public static var meta:Metadata = null;
	
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;
	public static var arrowSkin:String = '';
	public static var noteSplashSkin:String = '';
	public static var noteCoverSkin:String = '';
	public static var ratingStuff:Array<RatingInfo> = [
		new RatingInfo('You Suck!', 0.2),
		new RatingInfo('Shit', 0.4),
		new RatingInfo('Bad', 0.5),
		new RatingInfo('Bruh', 0.6),
		new RatingInfo('Meh', 0.69),
		new RatingInfo('Nice', 0.7),
		new RatingInfo('Good', 0.8),
		new RatingInfo('Great', 0.9),
		new RatingInfo('Great', 0.9),
		new RatingInfo('Sick!', 1),
		new RatingInfo('Perfect!!', 1),
	];
	
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartObjects:Map<String, FlxSprite> = new Map<String, FlxSprite>();
	
	// event variables
	public var hscriptGlobals:Map<String, Dynamic> = new Map();
	public var variables:Map<String, Dynamic> = new Map();
	
	public var isCameraOnForcedPos:Bool = false;
	
	public var boyfriendMap:Map<String, Character> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	
	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Character;
	
	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;
	
	public var gfSpeed:Int = 1;
	
	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;
	
	public static var curStage:String = 'stage';
	
	public var stage:Stage;
	
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	
	public var spawnTime:Float = 3000;
	
	public var vocals:VocalGroup;
	
	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];
	
	var strumLine:FlxSprite;
	
	// Handles the new epic mega sexy cam code that i've done
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	
	static var prevCamFollow:FlxPoint;
	static var prevCamFollowPos:FlxObject;
	
	public var playFields:FlxTypedGroup<PlayField>;
	public var opponentStrums:PlayField;
	public var playerStrums:PlayField;
	public var extraFields:Array<PlayField> = [];
	
	@:isVar public var strumLineNotes(get, null):Array<StrumNote>;
	
	@:noCompletion function get_strumLineNotes()
	{
		var notes:Array<StrumNote> = [];
		if (playFields != null && playFields.length > 0)
		{
			for (field in playFields.members)
			{
				for (sturm in field.members)
					notes.push(sturm);
			}
		}
		return notes;
	}
	
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var grpNoteCovers:FlxTypedGroup<NoteSustainCover>;
	
	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	
	var flashSprite:FlxSprite; // reactor flash assets
	
	var curSong:String = "";
	
	public var healthBounds:FlxBounds<Float> = new FlxBounds(0.0, 2.0);
	@:isVar public var health(default, set):Float = 1;
	
	@:noCompletion function set_health(v:Float):Float
	{
		health = v;
		callHUDFunc(p -> p.onHealthChange(v));
		return v;
	}
	
	var songPercent:Float = 0;
	
	public var combo:Int = 0;
	public var ratingsData:Array<Rating> = [
		new Rating('epic'),
		new Rating('sick'),
		new Rating('good'),
		new Rating('bad'),
		new Rating('shit')
	];
	
	public var epics:Int = 0;
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	
	var generatedMusic:Bool = false;
	
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	
	var updateTime:Bool = true;
	
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;
	public static var startOnTime:Float = 0;
	
	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled(default, set):Bool = false;
	public var practiceMode:Bool = false;
	
	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;
	
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var camPause:FlxCamera;
	public var cameraSpeed:Float = 1;
	
	public var defaultScoreAddition:Bool = true;
	
	var stageData:StageFile;
	
	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	
	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var campaignAccuracy:Float = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;
	
	public var defaultCamZoomAdd:Float = 0;
	public var defaultCamZoom:Float = 1.05;
	public var defaultHudZoom:Float = 1;
	public var beatsPerZoom:Int = 4;
	
	var totalBeat:Int = 0;
	var totalShake:Int = 0;
	var timeBeat:Float = 1;
	var gameZ:Float = 0.015;
	var hudZ:Float = 0.03;
	var gameShake:Float = 0.003;
	var hudShake:Float = 0.003;
	var shakeTime:Bool = false;
	
	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	
	public var inCutscene:Bool = false;
	public var ingameCutscene:Bool = false;
	
	public var skipCountdown:Bool = false;
	public var countdownSounds:Bool = true;
	public var countdownDelay:Float = 0;
	
	var songLength:Float = 0;
	
	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;
	
	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end
	
	// Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;
	
	// Script shit
	public static var instance:PlayState;
	
	public var luaArray:Array<FunkinLua> = [];
	public var funkyScripts:Array<FunkinScript> = [];
	public var hscriptArray:Array<FunkinIris> = [];
	
	public var notetypeScripts:Map<String, FunkinScript> = []; // custom notetypes for scriptVer '1'
	public var eventScripts:Map<String, FunkinScript> = []; // custom events for scriptVer '1'
	
	public static var noteSkin:funkin.data.NoteSkinHelper;
	
	// might make this a map ngl
	public var script_NOTEOffsets:Vector<FlxPoint>;
	public var script_STRUMOffsets:Vector<FlxPoint>;
	public var script_SUSTAINOffsets:Vector<FlxPoint>;
	public var script_SUSTAINENDOffsets:Vector<FlxPoint>;
	public var script_SPLASHOffsets:Vector<FlxPoint>;
	public var script_COVERSTARTOffsets:Vector<FlxPoint>;
	public var script_COVERLOOPOffsets:Vector<FlxPoint>;
	public var script_COVERENDOffsets:Vector<FlxPoint>;
	
	var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	
	public var introSoundsSuffix:String = '';
	
	// Debug buttons
	var debugKeysChart:Array<FlxKey>;
	var debugKeysCharacter:Array<FlxKey>;
	
	// Less laggy controls
	public var keysArray:Array<Dynamic>;
	
	public var camCurTarget:Character = null;
	
	public var onPauseSignal:FlxSignal = new FlxSignal();
	public var onResumeSignal:FlxSignal = new FlxSignal();
	
	public var playHUD:BaseHUD = null;
	
	public var soundMode:String = ''; // crude setup but its done quick. essentially make this = "SWAP" in the case the vocals ALSO contain the inst. it will mute the inst track when vocals play and vice versa
	
	/**
	 * Called when the Song should start
	 * 
	 * Change this to set custom behavior
	 * 
	 * Generally though your custom callback Should end with `startCountdown` to start the song
	 */
	public var songStartCallback:Null<Void->Void> = null;
	
	/**
	 * Called when the Song should end
	 * 
	 * Change this to set custom behavior
	 */
	public var songEndCallback:Null<Void->Void> = null;
	
	@:noCompletion public function set_cpuControlled(val:Bool)
	{
		if (playFields != null && playFields.members.length > 0)
		{
			for (field in playFields.members)
			{
				if (field.isPlayer) field.autoPlayed = val;
			}
		}
		return cpuControlled = val;
	}
	
	function setStageData(stageData:StageFile)
	{
		defaultCamZoom = stageData.defaultZoom;
		FlxG.camera.zoom = defaultCamZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		
		if (stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;
		
		boyfriendCameraOffset = stageData.camera_boyfriend != null ? stageData.camera_boyfriend : [0, 0];

		opponentCameraOffset = stageData.camera_opponent != null ? stageData.camera_opponent : [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend != null ? stageData.camera_girlfriend : [0, 0];

		if (boyfriendGroup == null) boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		else
		{
			boyfriendGroup.x = BF_X;
			boyfriendGroup.y = BF_Y;
		}
		if (dadGroup == null) dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		else
		{
			dadGroup.x = DAD_X;
			dadGroup.y = DAD_Y;
		}
		
		if (gfGroup == null) gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		else
		{
			gfGroup.x = GF_X;
			gfGroup.y = GF_Y;
		}
	}
	
	// null checking
	function callHUDFunc(f:BaseHUD->Void) if (playHUD != null) f(playHUD);
	
	#if (debug && !RELEASE_BUILD)
	inline function addFlxWatches()
	{
		FlxG.watch.addFunction('curStep', () -> curStep);
		FlxG.watch.addFunction('curBeat', () -> curBeat);
		FlxG.watch.addFunction('curSection', () -> curSection);
		
		FlxG.watch.addFunction('songTime', () -> Std.string(FlxStringUtil.formatTime(FlxG.sound.music.time / 1000) + ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000)));
		FlxG.watch.addFunction('conductorPos', () -> Std.int(Conductor.songPosition));
	}
	#end
	
	override public function create()
	{
		Paths.clearStoredMemory();
		
		skipCountdown = false;
		countdownSounds = true;
		
		// for lua
		instance = this;
		
		#if (debug && !RELEASE_BUILD)
		addFlxWatches();
		#end
		
		GameOverSubstate.resetVariables();
		
		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; // Reset to default
		
		keysArray = [
			ClientPrefs.keyBinds.exists('note_left') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')) : null,
			ClientPrefs.keyBinds.exists('note_down') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')) : null,
			ClientPrefs.keyBinds.exists('note_up') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')) : null,
			ClientPrefs.keyBinds.exists('note_right') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right')) : null
		];
		
		songStartCallback = startCountdown;
		songEndCallback = endSong;
		
		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}
		
		if (FlxG.sound != null && FlxG.sound.music != null) {
            if (FlxG.sound.music != null) {
                FlxG.sound.music.stop();
            }
        }
		
		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		
		camGame = new FlxCamera();
		camOther = new FlxCamera();
		camHUD = new FlxCamera();
		camPause = new FlxCamera(); // camera for da pause menu, doing this bc pause menu goes to whatever the highest camera is
		
		camHUD.bgColor = 0x0;
		camOther.bgColor = 0x0;
		camPause.bgColor = 0x0;
		
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camPause, false);
		
		setOnScripts('this', this);
		
		setOnScripts('camGame', camGame);
		setOnScripts('camHUD', camHUD);
		setOnScripts('camOther', camOther);
		setOnScripts('camPause', camPause); // doubt we'll need but incase
		
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteCovers = new FlxTypedGroup<NoteSustainCover>();
		
		persistentUpdate = true;
		persistentDraw = true;
		
		if (SONG == null) SONG = Song.loadFromJson('tutorial');
		
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;
		
		arrowSkin = SONG.arrowSkin;
		
		initNoteSkinning();
		
		#if desktop
		storyDifficultyText = DifficultyUtil.difficulties[storyDifficulty];
		
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode) // fix this again
		{
			// detailsText = "";
		}
		else
		{
			// detailsText = "";
		}
		setOnScripts('isStoryMode', isStoryMode);
		
		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end
		
		var songName:String = Paths.formatToSongPath(SONG.song);
		
		if (SONG.stage == null || SONG.stage.length == 0) SONG.stage = 'stage';
		curStage = SONG.stage;
		
		stage = new Stage(curStage);
		stageData = stage.stageData;
		setStageData(stageData); // change to setter
		setOnScripts('stage', stage);
		
		// STAGE SCRIPTS
		stage.buildStage();
		
		if (stage.curStageScript != null)
		{
			switch (stage.curStageScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast stage.curStageScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast stage.curStageScript);
				#end
			}
			funkyScripts.push(stage.curStageScript);
			// trace(stage.curStageScript.scriptName);
		}
		
		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}
		
		if (callOnHScripts("onAddSpriteGroups", []) != Globals.Function_Stop)
		{
			add(stage);
			stage.add(gfGroup);
			stage.add(dadGroup);
			stage.add(boyfriendGroup);
		}
		
		// "GLOBAL" SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('scripts/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var script = initFunkinIris(folder + file);
									if (script != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1) SONG.gfVersion = gfVersion = 'gf';
		
		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter, gf);
			
			setOnScripts('gf', gf);
			setOnScripts('gfGroup', gfGroup);
		}
		
		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter, dad);
		dadMap.set(dad.curCharacter, dad);
		
		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter, boyfriend);
		boyfriendMap.set(boyfriend.curCharacter, boyfriend);
		
		setOnScripts('dad', dad);
		setOnScripts('dadGroup', dadGroup);
		
		setOnScripts('boyfriend', boyfriend);
		setOnScripts('boyfriendGroup', boyfriendGroup);
		
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}
		else
		{
			camPos.set(opponentCameraOffset[0], opponentCameraOffset[1]);
			camPos.x += dad.getGraphicMidpoint().x + dad.cameraPosition[0];
			camPos.y += dad.getGraphicMidpoint().y + dad.cameraPosition[1];
		}
		
		/* this is unneeded i think
			if (dad.curCharacter == gf.curCharacter && gf != null)
			{
				dad.setPosition(GF_X, GF_Y);
				if (gf != null) gf.visible = false;
			}
		 */
		
		flashSprite = new FlxSprite(0, 0).makeGraphic(1280, 720, 0xFFb30000);
		flashSprite.alpha = 0;
		flashSprite.cameras = [camOther];
		add(flashSprite);
		setOnScripts('flashSprite', flashSprite);
		
		Conductor.songPosition = -5000;
		
		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50);
		strumLine.visible = false;
		strumLine.scrollFactor.set();
		
		// temp
		updateTime = true;
		
		playFields = new FlxTypedGroup<PlayField>();
		add(playFields);
		add(grpNoteCovers);
		add(grpNoteSplashes);
		
		playHUD = new funkin.huds.SusHUD(this);
		insert(members.indexOf(playFields), playHUD); // Data told me to do this
		playHUD.cameras = [camHUD];
		
		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
		
		var cover:NoteSustainCover = new NoteSustainCover(100, 100, 0);
		grpNoteCovers.add(cover);
		cover.alpha = 0.0;
		
		meta = Metadata.getSong();
		
		generateSong(SONG.song);
		modManager = new ModManager(this);
		setOnHScripts("modManager", modManager);
		
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;
		
		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);
		
		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);
		
		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);
		
		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		FlxG.fixedTimestep = false;
		moveCameraSection();
		
		botplayTxt = new FlxText(400, 525, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("liber.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		
		playFields.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		grpNoteCovers.cameras = [camHUD];
		notes.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		
		setOnScripts('playFields', playFields);
		setOnScripts('grpNoteSplashes', grpNoteSplashes);
		setOnScripts('grpNoteCovers', grpNoteCovers);
		setOnScripts('notes', notes);
		setOnScripts('botplayTxt', botplayTxt);
		callOnLuas('onCreate', []);

		addHitbox(3);
   		_hitbox.visible = false;
		
		startingSong = true;
		
		// SONG SPECIFIC SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('songs/' + Paths.formatToSongPath(SONG.song) + '/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('songs/' + Paths.formatToSongPath(SONG.song) + '/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0,
			Paths.mods(Paths.currentModDirectory + '/songs/' + Paths.formatToSongPath(SONG.song) + '/'));
			
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/songs/' + Paths.formatToSongPath(SONG.song) + '/')); // using push instead of insert because these should run after everything else
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var sc = initFunkinIris(folder + file);
									if (sc != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		if (songStartCallback == null)
		{
			FlxG.log.error('songStartCallback is null! using default callback.');
			songStartCallback = startCountdown;
		}
		
		songStartCallback();
		
		RecalculateRating();
		updateScoreBar();
		
		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.hitsoundVolume > 0) Paths.sound('hitsound');
		Paths.sound('missnote1');
		Paths.sound('missnote2');
		Paths.sound('missnote3');
		
		if (PauseSubState.songName != null)
		{
			Paths.music(PauseSubState.songName);
		}
		else if (ClientPrefs.pauseMusic != 'None')
		{
			Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic));
		}
		
		#if desktop // DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, getPresence(), null);
		#end
		
		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		
		callOnScripts('onCreatePost', []);
		
		super.create();
		
		Paths.clearUnusedMemory();
		
		cacheCountdown();
		
		refreshZ(stage);
	}
	
	function noteskinLoading(skin:String = 'default')
	{
		if (FileSystem.exists(Paths.modsNoteskin(skin))) noteSkin = new NoteSkinHelper(Paths.modsNoteskin(skin));
		else if (FileSystem.exists(Paths.noteskin(skin))) noteSkin = new NoteSkinHelper(Paths.noteskin(skin));
		
		if (noteSkin == null) {
			noteSkin = new NoteSkinHelper(Paths.noteskin('default'));
		}
		
		arrowSkin = skin;
		
		if (noteSkin == null) {
            noteSkin = new NoteSkinHelper(Paths.noteskin('default'));
		}
	}
	
	function initNoteSkinning()
	{
		script_NOTEOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINENDOffsets = new Vector<FlxPoint>(SONG.keys);
		script_STRUMOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SPLASHOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERSTARTOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERLOOPOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERENDOffsets = new Vector<FlxPoint>(SONG.keys);
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i] = new FlxPoint();
			script_STRUMOffsets[i] = new FlxPoint();
			script_SUSTAINOffsets[i] = new FlxPoint();
			script_SUSTAINENDOffsets[i] = new FlxPoint();
			script_SPLASHOffsets[i] = new FlxPoint();
			script_COVERSTARTOffsets[i] = new FlxPoint();
			script_COVERLOOPOffsets[i] = new FlxPoint();
			script_COVERENDOffsets[i] = new FlxPoint();
		}
		
		// trace('noteskin file: "${SONG.arrowSkin}"');
		
		var skin = SONG.arrowSkin;
		if (skin == '' || skin == 'null' || skin == null) skin = 'default';
		
		noteskinLoading(skin);
		
		trace('Quants turned on: ${ClientPrefs.noteSkin.contains('Quant')}');
		trace('HAS quants: ${noteSkin.data.hasQuants}');
		
		if (ClientPrefs.noteSkin.contains('Quant') && noteSkin.data.hasQuants) noteskinLoading('QUANT$skin');
		
		NoteSkinHelper.setNoteHelpers(noteSkin, SONG.keys);
		
		// trace(noteSkin.data);
		
		arrowSkin = noteSkin.data.globalSkin;
		NoteSkinHelper.arrowSkins = [noteSkin.data.playerSkin, noteSkin.data.opponentSkin];
		if (SONG.lanes > 2)
		{
			for (i in 2...SONG.lanes)
			{
				NoteSkinHelper.arrowSkins.push(noteSkin.data.extraSkin);
			}
		}
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i].x = noteSkin.data.noteAnimations[i][0].offsets[0];
			script_NOTEOffsets[i].y = noteSkin.data.noteAnimations[i][0].offsets[1];
			
			script_SUSTAINOffsets[i].x = noteSkin.data.noteAnimations[i][1].offsets[0];
			script_SUSTAINOffsets[i].y = noteSkin.data.noteAnimations[i][1].offsets[1];
			
			script_SUSTAINENDOffsets[i].x = noteSkin.data.noteAnimations[i][2].offsets[0];
			script_SUSTAINENDOffsets[i].y = noteSkin.data.noteAnimations[i][2].offsets[1];
			
			script_SPLASHOffsets[i].x = noteSkin.data.noteSplashAnimations[i].offsets[0];
			script_SPLASHOffsets[i].y = noteSkin.data.noteSplashAnimations[i].offsets[1];
			
			script_COVERSTARTOffsets[i].x = noteSkin.data.noteCoverAnimations[i][0].offsets[0];
			script_COVERSTARTOffsets[i].y = noteSkin.data.noteCoverAnimations[i][0].offsets[1];
			
			script_COVERLOOPOffsets[i].x = noteSkin.data.noteCoverAnimations[i][1].offsets[0];
			script_COVERLOOPOffsets[i].y = noteSkin.data.noteCoverAnimations[i][1].offsets[1];
			
			script_COVERENDOffsets[i].x = noteSkin.data.noteCoverAnimations[i][2].offsets[0];
			script_COVERENDOffsets[i].y = noteSkin.data.noteCoverAnimations[i][2].offsets[1];
		}
		
		noteSplashSkin = noteSkin.data.noteSplashSkin;
		noteCoverSkin = noteSkin.data.noteCoverSkin;
	}
	
	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
				note.resizeByRatio(ratio);
			for (note in unspawnNotes)
				note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}
	
	public function addTextToDebug(text:String, color:FlxColor = FlxColor.WHITE)
	{
		#if LUA_ALLOWED
		if (luaDebugGroup == null)
		{
			luaDebugGroup = new FlxTypedGroup();
			luaDebugGroup.cameras = [camOther];
			add(luaDebugGroup);
		}
		
		var recycledText = luaDebugGroup.recycle(DebugLuaText, () -> new DebugLuaText(text, luaDebugGroup, color));
		recycledText.text = text;
		recycledText.color = color;
		recycledText.disableTime = 6;
		recycledText.alpha = 1;
		
		luaDebugGroup.insert(0, recycledText);
		
		luaDebugGroup.forEachAlive((spr:DebugLuaText) -> {
			spr.y += recycledText.height;
		});
		
		recycledText.y = 10;
		#end
	}
	
	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter, newBoyfriend);
				}
				
			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter, newDad);
				}
				
			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter, newGf);
				}
		}
	}
	
	function startCharacterScripts(name:String, char:Character) // taken from SSG
	{
		// trace(name);
		if (char.curCharacterScript != null)
		{
			switch (char.curCharacterScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast char.curCharacterScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast char.curCharacterScript);
				#end
			}
			funkyScripts.push(char.curCharacterScript);
			trace(char.curCharacterScript.scriptName);
		}
	}
	
	function initFunkinIris(filePath:String, ?name:String)
	{
		try {
			var script:FunkinIris = FunkinIris.fromFile(filePath);
			if (script.parsingException != null)
			{
				script.stop();
				NativeAPI.showMessageBox("Script Error", "Error parsing script:\n" + filePath + "\n" + Std.string(script.parsingException));
				return null;
			}
			trace('script $filePath initiated.');
			script.call('onCreate');
			hscriptArray.push(script);
			funkyScripts.push(script);
			return script;
		} catch (e:Dynamic) {
			NativeAPI.showMessageBox("Script Error", "Failed to load script:\n" + filePath + "\n" + Std.string(e));
			return null;
		}
	}
	
	function setStageData(stageData:StageFile)
	{
		defaultCamZoom = stageData.defaultZoom;
		FlxG.camera.zoom = defaultCamZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		
		if (stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;
		
		boyfriendCameraOffset = stageData.camera_boyfriend != null ? stageData.camera_boyfriend : [0, 0];

		opponentCameraOffset = stageData.camera_opponent != null ? stageData.camera_opponent : [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend != null ? stageData.camera_girlfriend : [0, 0];

		if (boyfriendGroup == null) boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		else
		{
			boyfriendGroup.x = BF_X;
			boyfriendGroup.y = BF_Y;
		}
		if (dadGroup == null) dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		else
		{
			dadGroup.x = DAD_X;
			dadGroup.y = DAD_Y;
		}
		
		if (gfGroup == null) gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		else
		{
			gfGroup.x = GF_X;
			gfGroup.y = GF_Y;
		}
	}
	
	// null checking
	function callHUDFunc(f:BaseHUD->Void) if (playHUD != null) f(playHUD);
	
	#if (debug && !RELEASE_BUILD)
	inline function addFlxWatches()
	{
		FlxG.watch.addFunction('curStep', () -> curStep);
		FlxG.watch.addFunction('curBeat', () -> curBeat);
		FlxG.watch.addFunction('curSection', () -> curSection);
		
		FlxG.watch.addFunction('songTime', () -> Std.string(FlxStringUtil.formatTime(FlxG.sound.music.time / 1000) + ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000)));
		FlxG.watch.addFunction('conductorPos', () -> Std.int(Conductor.songPosition));
	}
	#end
	
	override public function create()
	{
		Paths.clearStoredMemory();
		
		skipCountdown = false;
		countdownSounds = true;
		
		// for lua
		instance = this;
		
		#if (debug && !RELEASE_BUILD)
		addFlxWatches();
		#end
		
		GameOverSubstate.resetVariables();
		
		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; // Reset to default
		
		keysArray = [
			ClientPrefs.keyBinds.exists('note_left') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')) : null,
			ClientPrefs.keyBinds.exists('note_down') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')) : null,
			ClientPrefs.keyBinds.exists('note_up') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')) : null,
			ClientPrefs.keyBinds.exists('note_right') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right')) : null
		];
		
		songStartCallback = startCountdown;
		songEndCallback = endSong;
		
		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}
		
		if (FlxG.sound != null && FlxG.sound.music != null) {
            if (FlxG.sound.music != null) {
                FlxG.sound.music.stop();
            }
        }
		
		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		
		camGame = new FlxCamera();
		camOther = new FlxCamera();
		camHUD = new FlxCamera();
		camPause = new FlxCamera(); // camera for da pause menu, doing this bc pause menu goes to whatever the highest camera is
		
		camHUD.bgColor = 0x0;
		camOther.bgColor = 0x0;
		camPause.bgColor = 0x0;
		
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camPause, false);
		
		setOnScripts('this', this);
		
		setOnScripts('camGame', camGame);
		setOnScripts('camHUD', camHUD);
		setOnScripts('camOther', camOther);
		setOnScripts('camPause', camPause); // doubt we'll need but incase
		
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteCovers = new FlxTypedGroup<NoteSustainCover>();
		
		persistentUpdate = true;
		persistentDraw = true;
		
		if (SONG == null) SONG = Song.loadFromJson('tutorial');
		
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;
		
		arrowSkin = SONG.arrowSkin;
		
		initNoteSkinning();
		
		#if desktop
		storyDifficultyText = DifficultyUtil.difficulties[storyDifficulty];
		
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode) // fix this again
		{
			// detailsText = "";
		}
		else
		{
			// detailsText = "";
		}
		setOnScripts('isStoryMode', isStoryMode);
		
		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end
		
		var songName:String = Paths.formatToSongPath(SONG.song);
		
		if (SONG.stage == null || SONG.stage.length == 0) SONG.stage = 'stage';
		curStage = SONG.stage;
		
		stage = new Stage(curStage);
		stageData = stage.stageData;
		setStageData(stageData); // change to setter
		setOnScripts('stage', stage);
		
		// STAGE SCRIPTS
		stage.buildStage();
		
		if (stage.curStageScript != null)
		{
			switch (stage.curStageScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast stage.curStageScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast stage.curStageScript);
				#end
			}
			funkyScripts.push(stage.curStageScript);
			// trace(stage.curStageScript.scriptName);
		}
		
		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}
		
		if (callOnHScripts("onAddSpriteGroups", []) != Globals.Function_Stop)
		{
			add(stage);
			stage.add(gfGroup);
			stage.add(dadGroup);
			stage.add(boyfriendGroup);
		}
		
		// "GLOBAL" SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('scripts/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var script = initFunkinIris(folder + file);
									if (script != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1) SONG.gfVersion = gfVersion = 'gf';
		
		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter, gf);
			
			setOnScripts('gf', gf);
			setOnScripts('gfGroup', gfGroup);
		}
		
		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter, dad);
		dadMap.set(dad.curCharacter, dad);
		
		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter, boyfriend);
		boyfriendMap.set(boyfriend.curCharacter, boyfriend);
		
		setOnScripts('dad', dad);
		setOnScripts('dadGroup', dadGroup);
		
		setOnScripts('boyfriend', boyfriend);
		setOnScripts('boyfriendGroup', boyfriendGroup);
		
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}
		else
		{
			camPos.set(opponentCameraOffset[0], opponentCameraOffset[1]);
			camPos.x += dad.getGraphicMidpoint().x + dad.cameraPosition[0];
			camPos.y += dad.getGraphicMidpoint().y + dad.cameraPosition[1];
		}
		
		/* this is unneeded i think
			if (dad.curCharacter == gf.curCharacter && gf != null)
			{
				dad.setPosition(GF_X, GF_Y);
				if (gf != null) gf.visible = false;
			}
		 */
		
		flashSprite = new FlxSprite(0, 0).makeGraphic(1280, 720, 0xFFb30000);
		flashSprite.alpha = 0;
		flashSprite.cameras = [camOther];
		add(flashSprite);
		setOnScripts('flashSprite', flashSprite);
		
		Conductor.songPosition = -5000;
		
		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50);
		strumLine.visible = false;
		strumLine.scrollFactor.set();
		
		// temp
		updateTime = true;
		
		playFields = new FlxTypedGroup<PlayField>();
		add(playFields);
		add(grpNoteCovers);
		add(grpNoteSplashes);
		
		playHUD = new funkin.huds.SusHUD(this);
		insert(members.indexOf(playFields), playHUD); // Data told me to do this
		playHUD.cameras = [camHUD];
		
		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
		
		var cover:NoteSustainCover = new NoteSustainCover(100, 100, 0);
		grpNoteCovers.add(cover);
		cover.alpha = 0.0;
		
		meta = Metadata.getSong();
		
		generateSong(SONG.song);
		modManager = new ModManager(this);
		setOnHScripts("modManager", modManager);
		
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;
		
		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);
		
		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);
		
		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);
		
		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		FlxG.fixedTimestep = false;
		moveCameraSection();
		
		botplayTxt = new FlxText(400, 525, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("liber.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		
		playFields.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		grpNoteCovers.cameras = [camHUD];
		notes.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		
		setOnScripts('playFields', playFields);
		setOnScripts('grpNoteSplashes', grpNoteSplashes);
		setOnScripts('grpNoteCovers', grpNoteCovers);
		setOnScripts('notes', notes);
		setOnScripts('botplayTxt', botplayTxt);
		callOnLuas('onCreate', []);

		addHitbox(3);
   		_hitbox.visible = false;
		
		startingSong = true;
		
		// SONG SPECIFIC SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('songs/' + Paths.formatToSongPath(SONG.song) + '/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('songs/' + Paths.formatToSongPath(SONG.song) + '/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0,
			Paths.mods(Paths.currentModDirectory + '/songs/' + Paths.formatToSongPath(SONG.song) + '/'));
			
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/songs/' + Paths.formatToSongPath(SONG.song) + '/')); // using push instead of insert because these should run after everything else
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var sc = initFunkinIris(folder + file);
									if (sc != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		if (songStartCallback == null)
		{
			FlxG.log.error('songStartCallback is null! using default callback.');
			songStartCallback = startCountdown;
		}
		
		songStartCallback();
		
		RecalculateRating();
		updateScoreBar();
		
		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.hitsoundVolume > 0) Paths.sound('hitsound');
		Paths.sound('missnote1');
		Paths.sound('missnote2');
		Paths.sound('missnote3');
		
		if (PauseSubState.songName != null)
		{
			Paths.music(PauseSubState.songName);
		}
		else if (ClientPrefs.pauseMusic != 'None')
		{
			Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic));
		}
		
		#if desktop // DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, getPresence(), null);
		#end
		
		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		
		callOnScripts('onCreatePost', []);
		
		super.create();
		
		Paths.clearUnusedMemory();
		
		cacheCountdown();
		
		refreshZ(stage);
	}
	
	function noteskinLoading(skin:String = 'default')
	{
		if (FileSystem.exists(Paths.modsNoteskin(skin))) noteSkin = new NoteSkinHelper(Paths.modsNoteskin(skin));
		else if (FileSystem.exists(Paths.noteskin(skin))) noteSkin = new NoteSkinHelper(Paths.noteskin(skin));
		
		if (noteSkin == null) {
			noteSkin = new NoteSkinHelper(Paths.noteskin('default'));
		}
		
		arrowSkin = skin;
		
		if (noteSkin == null) {
            noteSkin = new NoteSkinHelper(Paths.noteskin('default'));
		}
	}
	
	function initNoteSkinning()
	{
		script_NOTEOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINENDOffsets = new Vector<FlxPoint>(SONG.keys);
		script_STRUMOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SPLASHOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERSTARTOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERLOOPOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERENDOffsets = new Vector<FlxPoint>(SONG.keys);
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i] = new FlxPoint();
			script_STRUMOffsets[i] = new FlxPoint();
			script_SUSTAINOffsets[i] = new FlxPoint();
			script_SUSTAINENDOffsets[i] = new FlxPoint();
			script_SPLASHOffsets[i] = new FlxPoint();
			script_COVERSTARTOffsets[i] = new FlxPoint();
			script_COVERLOOPOffsets[i] = new FlxPoint();
			script_COVERENDOffsets[i] = new FlxPoint();
		}
		
		// trace('noteskin file: "${SONG.arrowSkin}"');
		
		var skin = SONG.arrowSkin;
		if (skin == '' || skin == 'null' || skin == null) skin = 'default';
		
		noteskinLoading(skin);
		
		trace('Quants turned on: ${ClientPrefs.noteSkin.contains('Quant')}');
		trace('HAS quants: ${noteSkin.data.hasQuants}');
		
		if (ClientPrefs.noteSkin.contains('Quant') && noteSkin.data.hasQuants) noteskinLoading('QUANT$skin');
		
		NoteSkinHelper.setNoteHelpers(noteSkin, SONG.keys);
		
		// trace(noteSkin.data);
		
		arrowSkin = noteSkin.data.globalSkin;
		NoteSkinHelper.arrowSkins = [noteSkin.data.playerSkin, noteSkin.data.opponentSkin];
		if (SONG.lanes > 2)
		{
			for (i in 2...SONG.lanes)
			{
				NoteSkinHelper.arrowSkins.push(noteSkin.data.extraSkin);
			}
		}
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i].x = noteSkin.data.noteAnimations[i][0].offsets[0];
			script_NOTEOffsets[i].y = noteSkin.data.noteAnimations[i][0].offsets[1];
			
			script_SUSTAINOffsets[i].x = noteSkin.data.noteAnimations[i][1].offsets[0];
			script_SUSTAINOffsets[i].y = noteSkin.data.noteAnimations[i][1].offsets[1];
			
			script_SUSTAINENDOffsets[i].x = noteSkin.data.noteAnimations[i][2].offsets[0];
			script_SUSTAINENDOffsets[i].y = noteSkin.data.noteAnimations[i][2].offsets[1];
			
			script_SPLASHOffsets[i].x = noteSkin.data.noteSplashAnimations[i].offsets[0];
			script_SPLASHOffsets[i].y = noteSkin.data.noteSplashAnimations[i].offsets[1];
			
			script_COVERSTARTOffsets[i].x = noteSkin.data.noteCoverAnimations[i][0].offsets[0];
			script_COVERSTARTOffsets[i].y = noteSkin.data.noteCoverAnimations[i][0].offsets[1];
			
			script_COVERLOOPOffsets[i].x = noteSkin.data.noteCoverAnimations[i][1].offsets[0];
			script_COVERLOOPOffsets[i].y = noteSkin.data.noteCoverAnimations[i][1].offsets[1];
			
			script_COVERENDOffsets[i].x = noteSkin.data.noteCoverAnimations[i][2].offsets[0];
			script_COVERENDOffsets[i].y = noteSkin.data.noteCoverAnimations[i][2].offsets[1];
		}
		
		noteSplashSkin = noteSkin.data.noteSplashSkin;
		noteCoverSkin = noteSkin.data.noteCoverSkin;
	}
	
	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
				note.resizeByRatio(ratio);
			for (note in unspawnNotes)
				note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}
	
	public function addTextToDebug(text:String, color:FlxColor = FlxColor.WHITE)
	{
		#if LUA_ALLOWED
		if (luaDebugGroup == null)
		{
			luaDebugGroup = new FlxTypedGroup();
			luaDebugGroup.cameras = [camOther];
			add(luaDebugGroup);
		}
		
		var recycledText = luaDebugGroup.recycle(DebugLuaText, () -> new DebugLuaText(text, luaDebugGroup, color));
		recycledText.text = text;
		recycledText.color = color;
		recycledText.disableTime = 6;
		recycledText.alpha = 1;
		
		luaDebugGroup.insert(0, recycledText);
		
		luaDebugGroup.forEachAlive((spr:DebugLuaText) -> {
			spr.y += recycledText.height;
		});
		
		recycledText.y = 10;
		#end
	}
	
	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter, newBoyfriend);
				}
				
			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter, newDad);
				}
				
			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter, newGf);
				}
		}
	}
	
	function startCharacterScripts(name:String, char:Character) // taken from SSG
	{
		// trace(name);
		if (char.curCharacterScript != null)
		{
			switch (char.curCharacterScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast char.curCharacterScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast char.curCharacterScript);
				#end
			}
			funkyScripts.push(char.curCharacterScript);
			trace(char.curCharacterScript.scriptName);
		}
	}
	
	function initFunkinIris(filePath:String, ?name:String)
	{
		try {
			var script:FunkinIris = FunkinIris.fromFile(filePath);
			if (script.parsingException != null)
			{
				script.stop();
				NativeAPI.showMessageBox("Script Error", "Error parsing script:\n" + filePath + "\n" + Std.string(script.parsingException));
				return null;
			}
			trace('script $filePath initiated.');
			script.call('onCreate');
			hscriptArray.push(script);
			funkyScripts.push(script);
			return script;
		} catch (e:Dynamic) {
			NativeAPI.showMessageBox("Script Error", "Failed to load script:\n" + filePath + "\n" + Std.string(e));
			return null;
		}
	}
	
	function setStageData(stageData:StageFile)
	{
		defaultCamZoom = stageData.defaultZoom;
		FlxG.camera.zoom = defaultCamZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		
		if (stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;
		
		boyfriendCameraOffset = stageData.camera_boyfriend != null ? stageData.camera_boyfriend : [0, 0];

		opponentCameraOffset = stageData.camera_opponent != null ? stageData.camera_opponent : [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend != null ? stageData.camera_girlfriend : [0, 0];

		if (boyfriendGroup == null) boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		else
		{
			boyfriendGroup.x = BF_X;
			boyfriendGroup.y = BF_Y;
		}
		if (dadGroup == null) dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		else
		{
			dadGroup.x = DAD_X;
			dadGroup.y = DAD_Y;
		}
		
		if (gfGroup == null) gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		else
		{
			gfGroup.x = GF_X;
			gfGroup.y = GF_Y;
		}
	}
	
	// null checking
	function callHUDFunc(f:BaseHUD->Void) if (playHUD != null) f(playHUD);
	
	#if (debug && !RELEASE_BUILD)
	inline function addFlxWatches()
	{
		FlxG.watch.addFunction('curStep', () -> curStep);
		FlxG.watch.addFunction('curBeat', () -> curBeat);
		FlxG.watch.addFunction('curSection', () -> curSection);
		
		FlxG.watch.addFunction('songTime', () -> Std.string(FlxStringUtil.formatTime(FlxG.sound.music.time / 1000) + ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000)));
		FlxG.watch.addFunction('conductorPos', () -> Std.int(Conductor.songPosition));
	}
	#end
	
	override public function create()
	{
		Paths.clearStoredMemory();
		
		skipCountdown = false;
		countdownSounds = true;
		
		// for lua
		instance = this;
		
		#if (debug && !RELEASE_BUILD)
		addFlxWatches();
		#end
		
		GameOverSubstate.resetVariables();
		
		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; // Reset to default
		
		keysArray = [
			ClientPrefs.keyBinds.exists('note_left') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')) : null,
			ClientPrefs.keyBinds.exists('note_down') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')) : null,
			ClientPrefs.keyBinds.exists('note_up') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')) : null,
			ClientPrefs.keyBinds.exists('note_right') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right')) : null
		];
		
		songStartCallback = startCountdown;
		songEndCallback = endSong;
		
		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}
		
		if (FlxG.sound != null && FlxG.sound.music != null) {
            if (FlxG.sound.music != null) {
                FlxG.sound.music.stop();
            }
        }
		
		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		
		camGame = new FlxCamera();
		camOther = new FlxCamera();
		camHUD = new FlxCamera();
		camPause = new FlxCamera(); // camera for da pause menu, doing this bc pause menu goes to whatever the highest camera is
		
		camHUD.bgColor = 0x0;
		camOther.bgColor = 0x0;
		camPause.bgColor = 0x0;
		
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camPause, false);
		
		setOnScripts('this', this);
		
		setOnScripts('camGame', camGame);
		setOnScripts('camHUD', camHUD);
		setOnScripts('camOther', camOther);
		setOnScripts('camPause', camPause); // doubt we'll need but incase
		
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteCovers = new FlxTypedGroup<NoteSustainCover>();
		
		persistentUpdate = true;
		persistentDraw = true;
		
		if (SONG == null) SONG = Song.loadFromJson('tutorial');
		
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;
		
		arrowSkin = SONG.arrowSkin;
		
		initNoteSkinning();
		
		#if desktop
		storyDifficultyText = DifficultyUtil.difficulties[storyDifficulty];
		
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode) // fix this again
		{
			// detailsText = "";
		}
		else
		{
			// detailsText = "";
		}
		setOnScripts('isStoryMode', isStoryMode);
		
		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end
		
		var songName:String = Paths.formatToSongPath(SONG.song);
		
		if (SONG.stage == null || SONG.stage.length == 0) SONG.stage = 'stage';
		curStage = SONG.stage;
		
		stage = new Stage(curStage);
		stageData = stage.stageData;
		setStageData(stageData); // change to setter
		setOnScripts('stage', stage);
		
		// STAGE SCRIPTS
		stage.buildStage();
		
		if (stage.curStageScript != null)
		{
			switch (stage.curStageScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast stage.curStageScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast stage.curStageScript);
				#end
			}
			funkyScripts.push(stage.curStageScript);
			// trace(stage.curStageScript.scriptName);
		}
		
		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}
		
		if (callOnHScripts("onAddSpriteGroups", []) != Globals.Function_Stop)
		{
			add(stage);
			stage.add(gfGroup);
			stage.add(dadGroup);
			stage.add(boyfriendGroup);
		}
		
		// "GLOBAL" SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('scripts/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var sc = initFunkinIris(folder + file);
									if (sc != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1) SONG.gfVersion = gfVersion = 'gf';
		
		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter, gf);
			
			setOnScripts('gf', gf);
			setOnScripts('gfGroup', gfGroup);
		}
		
		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter, dad);
		dadMap.set(dad.curCharacter, dad);
		
		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter, boyfriend);
		boyfriendMap.set(boyfriend.curCharacter, boyfriend);
		
		setOnScripts('dad', dad);
		setOnScripts('dadGroup', dadGroup);
		
		setOnScripts('boyfriend', boyfriend);
		setOnScripts('boyfriendGroup', boyfriendGroup);
		
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}
		else
		{
			camPos.set(opponentCameraOffset[0], opponentCameraOffset[1]);
			camPos.x += dad.getGraphicMidpoint().x + dad.cameraPosition[0];
			camPos.y += dad.getGraphicMidpoint().y + dad.cameraPosition[1];
		}
		
		/* this is unneeded i think
			if (dad.curCharacter == gf.curCharacter && gf != null)
			{
				dad.setPosition(GF_X, GF_Y);
				if (gf != null) gf.visible = false;
			}
		 */
		
		flashSprite = new FlxSprite(0, 0).makeGraphic(1280, 720, 0xFFb30000);
		flashSprite.alpha = 0;
		flashSprite.cameras = [camOther];
		add(flashSprite);
		setOnScripts('flashSprite', flashSprite);
		
		Conductor.songPosition = -5000;
		
		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50);
		strumLine.visible = false;
		strumLine.scrollFactor.set();
		
		// temp
		updateTime = true;
		
		playFields = new FlxTypedGroup<PlayField>();
		add(playFields);
		add(grpNoteCovers);
		add(grpNoteSplashes);
		
		playHUD = new funkin.huds.SusHUD(this);
		insert(members.indexOf(playFields), playHUD); // Data told me to do this
		playHUD.cameras = [camHUD];
		
		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
		
		var cover:NoteSustainCover = new NoteSustainCover(100, 100, 0);
		grpNoteCovers.add(cover);
		cover.alpha = 0.0;
		
		meta = Metadata.getSong();
		
		generateSong(SONG.song);
		modManager = new ModManager(this);
		setOnHScripts("modManager", modManager);
		
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;
		
		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);
		
		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);
		
		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);
		
		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		FlxG.fixedTimestep = false;
		moveCameraSection();
		
		botplayTxt = new FlxText(400, 525, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("liber.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		
		playFields.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		grpNoteCovers.cameras = [camHUD];
		notes.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		
		setOnScripts('playFields', playFields);
		setOnScripts('grpNoteSplashes', grpNoteSplashes);
		setOnScripts('grpNoteCovers', grpNoteCovers);
		setOnScripts('notes', notes);
		setOnScripts('botplayTxt', botplayTxt);
		callOnLuas('onCreate', []);

		addHitbox(3);
   		_hitbox.visible = false;
		
		startingSong = true;
		
		// SONG SPECIFIC SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('songs/' + Paths.formatToSongPath(SONG.song) + '/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('songs/' + Paths.formatToSongPath(SONG.song) + '/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0,
			Paths.mods(Paths.currentModDirectory + '/songs/' + Paths.formatToSongPath(SONG.song) + '/'));
			
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/songs/' + Paths.formatToSongPath(SONG.song) + '/')); // using push instead of insert because these should run after everything else
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var sc = initFunkinIris(folder + file);
									if (sc != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		if (songStartCallback == null)
		{
			FlxG.log.error('songStartCallback is null! using default callback.');
			songStartCallback = startCountdown;
		}
		
		songStartCallback();
		
		RecalculateRating();
		updateScoreBar();
		
		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.hitsoundVolume > 0) Paths.sound('hitsound');
		Paths.sound('missnote1');
		Paths.sound('missnote2');
		Paths.sound('missnote3');
		
		if (PauseSubState.songName != null)
		{
			Paths.music(PauseSubState.songName);
		}
		else if (ClientPrefs.pauseMusic != 'None')
		{
			Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic));
		}
		
		#if desktop // DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, getPresence(), null);
		#end
		
		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		
		callOnScripts('onCreatePost', []);
		
		super.create();
		
		Paths.clearUnusedMemory();
		
		cacheCountdown();
		
		refreshZ(stage);
	}
	
	function noteskinLoading(skin:String = 'default')
	{
		if (FileSystem.exists(Paths.modsNoteskin(skin))) noteSkin = new NoteSkinHelper(Paths.modsNoteskin(skin));
		else if (FileSystem.exists(Paths.noteskin(skin))) noteSkin = new NoteSkinHelper(Paths.noteskin(skin));
		
		if (noteSkin == null) {
			noteSkin = new NoteSkinHelper(Paths.noteskin('default'));
		}
		
		arrowSkin = skin;
		
		if (noteSkin == null) {
            noteSkin = new NoteSkinHelper(Paths.noteskin('default'));
		}
	}
	
	function initNoteSkinning()
	{
		script_NOTEOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINENDOffsets = new Vector<FlxPoint>(SONG.keys);
		script_STRUMOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SPLASHOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERSTARTOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERLOOPOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERENDOffsets = new Vector<FlxPoint>(SONG.keys);
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i] = new FlxPoint();
			script_STRUMOffsets[i] = new FlxPoint();
			script_SUSTAINOffsets[i] = new FlxPoint();
			script_SUSTAINENDOffsets[i] = new FlxPoint();
			script_SPLASHOffsets[i] = new FlxPoint();
			script_COVERSTARTOffsets[i] = new FlxPoint();
			script_COVERLOOPOffsets[i] = new FlxPoint();
			script_COVERENDOffsets[i] = new FlxPoint();
		}
		
		// trace('noteskin file: "${SONG.arrowSkin}"');
		
		var skin = SONG.arrowSkin;
		if (skin == '' || skin == 'null' || skin == null) skin = 'default';
		
		noteskinLoading(skin);
		
		trace('Quants turned on: ${ClientPrefs.noteSkin.contains('Quant')}');
		trace('HAS quants: ${noteSkin.data.hasQuants}');
		
		if (ClientPrefs.noteSkin.contains('Quant') && noteSkin.data.hasQuants) noteskinLoading('QUANT$skin');
		
		NoteSkinHelper.setNoteHelpers(noteSkin, SONG.keys);
		
		// trace(noteSkin.data);
		
		arrowSkin = noteSkin.data.globalSkin;
		NoteSkinHelper.arrowSkins = [noteSkin.data.playerSkin, noteSkin.data.opponentSkin];
		if (SONG.lanes > 2)
		{
			for (i in 2...SONG.lanes)
			{
				NoteSkinHelper.arrowSkins.push(noteSkin.data.extraSkin);
			}
		}
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i].x = noteSkin.data.noteAnimations[i][0].offsets[0];
			script_NOTEOffsets[i].y = noteSkin.data.noteAnimations[i][0].offsets[1];
			
			script_SUSTAINOffsets[i].x = noteSkin.data.noteAnimations[i][1].offsets[0];
			script_SUSTAINOffsets[i].y = noteSkin.data.noteAnimations[i][1].offsets[1];
			
			script_SUSTAINENDOffsets[i].x = noteSkin.data.noteAnimations[i][2].offsets[0];
			script_SUSTAINENDOffsets[i].y = noteSkin.data.noteAnimations[i][2].offsets[1];
			
			script_SPLASHOffsets[i].x = noteSkin.data.noteSplashAnimations[i].offsets[0];
			script_SPLASHOffsets[i].y = noteSkin.data.noteSplashAnimations[i].offsets[1];
			
			script_COVERSTARTOffsets[i].x = noteSkin.data.noteCoverAnimations[i][0].offsets[0];
			script_COVERSTARTOffsets[i].y = noteSkin.data.noteCoverAnimations[i][0].offsets[1];
			
			script_COVERLOOPOffsets[i].x = noteSkin.data.noteCoverAnimations[i][1].offsets[0];
			script_COVERLOOPOffsets[i].y = noteSkin.data.noteCoverAnimations[i][1].offsets[1];
			
			script_COVERENDOffsets[i].x = noteSkin.data.noteCoverAnimations[i][2].offsets[0];
			script_COVERENDOffsets[i].y = noteSkin.data.noteCoverAnimations[i][2].offsets[1];
		}
		
		noteSplashSkin = noteSkin.data.noteSplashSkin;
		noteCoverSkin = noteSkin.data.noteCoverSkin;
	}
	
	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
				note.resizeByRatio(ratio);
			for (note in unspawnNotes)
				note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}
	
	public function addTextToDebug(text:String, color:FlxColor = FlxColor.WHITE)
	{
		#if LUA_ALLOWED
		if (luaDebugGroup == null)
		{
			luaDebugGroup = new FlxTypedGroup();
			luaDebugGroup.cameras = [camOther];
			add(luaDebugGroup);
		}
		
		var recycledText = luaDebugGroup.recycle(DebugLuaText, () -> new DebugLuaText(text, luaDebugGroup, color));
		recycledText.text = text;
		recycledText.color = color;
		recycledText.disableTime = 6;
		recycledText.alpha = 1;
		
		luaDebugGroup.insert(0, recycledText);
		
		luaDebugGroup.forEachAlive((spr:DebugLuaText) -> {
			spr.y += recycledText.height;
		});
		
		recycledText.y = 10;
		#end
	}
	
	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter, newBoyfriend);
				}
				
			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter, newDad);
				}
				
			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter, newGf);
				}
		}
	}
	
	function startCharacterScripts(name:String, char:Character) // taken from SSG
	{
		// trace(name);
		if (char.curCharacterScript != null)
		{
			switch (char.curCharacterScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast char.curCharacterScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast char.curCharacterScript);
				#end
			}
			funkyScripts.push(char.curCharacterScript);
			trace(char.curCharacterScript.scriptName);
		}
	}
	
	function initFunkinIris(filePath:String, ?name:String)
	{
		try {
			var script:FunkinIris = FunkinIris.fromFile(filePath);
			if (script.parsingException != null)
			{
				script.stop();
				NativeAPI.showMessageBox("Script Error", "Error parsing script:\n" + filePath + "\n" + Std.string(script.parsingException));
				return null;
			}
			trace('script $filePath initiated.');
			script.call('onCreate');
			hscriptArray.push(script);
			funkyScripts.push(script);
			return script;
		} catch (e:Dynamic) {
			NativeAPI.showMessageBox("Script Error", "Failed to load script:\n" + filePath + "\n" + Std.string(e));
			return null;
		}
	}
	
	function setStageData(stageData:StageFile)
	{
		defaultCamZoom = stageData.defaultZoom;
		FlxG.camera.zoom = defaultCamZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		
		if (stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;
		
		boyfriendCameraOffset = stageData.camera_boyfriend != null ? stageData.camera_boyfriend : [0, 0];

		opponentCameraOffset = stageData.camera_opponent != null ? stageData.camera_opponent : [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend != null ? stageData.camera_girlfriend : [0, 0];

		if (boyfriendGroup == null) boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		else
		{
			boyfriendGroup.x = BF_X;
			boyfriendGroup.y = BF_Y;
		}
		if (dadGroup == null) dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		else
		{
			dadGroup.x = DAD_X;
			dadGroup.y = DAD_Y;
		}
		
		if (gfGroup == null) gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		else
		{
			gfGroup.x = GF_X;
			gfGroup.y = GF_Y;
		}
	}
	
	// null checking
	function callHUDFunc(f:BaseHUD->Void) if (playHUD != null) f(playHUD);
	
	#if (debug && !RELEASE_BUILD)
	inline function addFlxWatches()
	{
		FlxG.watch.addFunction('curStep', () -> curStep);
		FlxG.watch.addFunction('curBeat', () -> curBeat);
		FlxG.watch.addFunction('curSection', () -> curSection);
		
		FlxG.watch.addFunction('songTime', () -> Std.string(FlxStringUtil.formatTime(FlxG.sound.music.time / 1000) + ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000)));
		FlxG.watch.addFunction('conductorPos', () -> Std.int(Conductor.songPosition));
	}
	#end
	
	override public function create()
	{
		Paths.clearStoredMemory();
		
		skipCountdown = false;
		countdownSounds = true;
		
		// for lua
		instance = this;
		
		#if (debug && !RELEASE_BUILD)
		addFlxWatches();
		#end
		
		GameOverSubstate.resetVariables();
		
		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; // Reset to default
		
		keysArray = [
			ClientPrefs.keyBinds.exists('note_left') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')) : null,
			ClientPrefs.keyBinds.exists('note_down') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')) : null,
			ClientPrefs.keyBinds.exists('note_up') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')) : null,
			ClientPrefs.keyBinds.exists('note_right') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right')) : null
		];
		
		songStartCallback = startCountdown;
		songEndCallback = endSong;
		
		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}
		
		if (FlxG.sound != null && FlxG.sound.music != null) {
            if (FlxG.sound.music != null) {
                FlxG.sound.music.stop();
            }
        }
		
		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		
		camGame = new FlxCamera();
		camOther = new FlxCamera();
		camHUD = new FlxCamera();
		camPause = new FlxCamera(); // camera for da pause menu, doing this bc pause menu goes to whatever the highest camera is
		
		camHUD.bgColor = 0x0;
		camOther.bgColor = 0x0;
		camPause.bgColor = 0x0;
		
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camPause, false);
		
		setOnScripts('this', this);
		
		setOnScripts('camGame', camGame);
		setOnScripts('camHUD', camHUD);
		setOnScripts('camOther', camOther);
		setOnScripts('camPause', camPause); // doubt we'll need but incase
		
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteCovers = new FlxTypedGroup<NoteSustainCover>();
		
		persistentUpdate = true;
		persistentDraw = true;
		
		if (SONG == null) SONG = Song.loadFromJson('tutorial');
		
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;
		
		arrowSkin = SONG.arrowSkin;
		
		initNoteSkinning();
		
		#if desktop
		storyDifficultyText = DifficultyUtil.difficulties[storyDifficulty];
		
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode) // fix this again
		{
			// detailsText = "";
		}
		else
		{
			// detailsText = "";
		}
		setOnScripts('isStoryMode', isStoryMode);
		
		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end
		
		var songName:String = Paths.formatToSongPath(SONG.song);
		
		if (SONG.stage == null || SONG.stage.length == 0) SONG.stage = 'stage';
		curStage = SONG.stage;
		
		stage = new Stage(curStage);
		stageData = stage.stageData;
		setStageData(stageData); // change to setter
		setOnScripts('stage', stage);
		
		// STAGE SCRIPTS
		stage.buildStage();
		
		if (stage.curStageScript != null)
		{
			switch (stage.curStageScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast stage.curStageScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast stage.curStageScript);
				#end
			}
			funkyScripts.push(stage.curStageScript);
			// trace(stage.curStageScript.scriptName);
		}
		
		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}
		
		if (callOnHScripts("onAddSpriteGroups", []) != Globals.Function_Stop)
		{
			add(stage);
			stage.add(gfGroup);
			stage.add(dadGroup);
			stage.add(boyfriendGroup);
		}
		
		// "GLOBAL" SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('scripts/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var sc = initFunkinIris(folder + file);
									if (sc != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1) SONG.gfVersion = gfVersion = 'gf';
		
		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter, gf);
			
			setOnScripts('gf', gf);
			setOnScripts('gfGroup', gfGroup);
		}
		
		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter, dad);
		dadMap.set(dad.curCharacter, dad);
		
		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter, boyfriend);
		boyfriendMap.set(boyfriend.curCharacter, boyfriend);
		
		setOnScripts('dad', dad);
		setOnScripts('dadGroup', dadGroup);
		
		setOnScripts('boyfriend', boyfriend);
		setOnScripts('boyfriendGroup', boyfriendGroup);
		
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}
		else
		{
			camPos.set(opponentCameraOffset[0], opponentCameraOffset[1]);
			camPos.x += dad.getGraphicMidpoint().x + dad.cameraPosition[0];
			camPos.y += dad.getGraphicMidpoint().y + dad.cameraPosition[1];
		}
		
		/* this is unneeded i think
			if (dad.curCharacter == gf.curCharacter && gf != null)
			{
				dad.setPosition(GF_X, GF_Y);
				if (gf != null) gf.visible = false;
			}
		 */
		
		flashSprite = new FlxSprite(0, 0).makeGraphic(1280, 720, 0xFFb30000);
		flashSprite.alpha = 0;
		flashSprite.cameras = [camOther];
		add(flashSprite);
		setOnScripts('flashSprite', flashSprite);
		
		Conductor.songPosition = -5000;
		
		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50);
		strumLine.visible = false;
		strumLine.scrollFactor.set();
		
		// temp
		updateTime = true;
		
		playFields = new FlxTypedGroup<PlayField>();
		add(playFields);
		add(grpNoteCovers);
		add(grpNoteSplashes);
		
		playHUD = new funkin.huds.SusHUD(this);
		insert(members.indexOf(playFields), playHUD); // Data told me to do this
		playHUD.cameras = [camHUD];
		
		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
		
		var cover:NoteSustainCover = new NoteSustainCover(100, 100, 0);
		grpNoteCovers.add(cover);
		cover.alpha = 0.0;
		
		meta = Metadata.getSong();
		
		generateSong(SONG.song);
		modManager = new ModManager(this);
		setOnHScripts("modManager", modManager);
		
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;
		
		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);
		
		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);
		
		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);
		
		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		FlxG.fixedTimestep = false;
		moveCameraSection();
		
		botplayTxt = new FlxText(400, 525, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("liber.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		
		playFields.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		grpNoteCovers.cameras = [camHUD];
		notes.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		
		setOnScripts('playFields', playFields);
		setOnScripts('grpNoteSplashes', grpNoteSplashes);
		setOnScripts('grpNoteCovers', grpNoteCovers);
		setOnScripts('notes', notes);
		setOnScripts('botplayTxt', botplayTxt);
		callOnLuas('onCreate', []);

		addHitbox(3);
   		_hitbox.visible = false;
		
		startingSong = true;
		
		// SONG SPECIFIC SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('songs/' + Paths.formatToSongPath(SONG.song) + '/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('songs/' + Paths.formatToSongPath(SONG.song) + '/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0,
			Paths.mods(Paths.currentModDirectory + '/songs/' + Paths.formatToSongPath(SONG.song) + '/'));
			
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/songs/' + Paths.formatToSongPath(SONG.song) + '/')); // using push instead of insert because these should run after everything else
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var sc = initFunkinIris(folder + file);
									if (sc != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		if (songStartCallback == null)
		{
			FlxG.log.error('songStartCallback is null! using default callback.');
			songStartCallback = startCountdown;
		}
		
		songStartCallback();
		
		RecalculateRating();
		updateScoreBar();
		
		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.hitsoundVolume > 0) Paths.sound('hitsound');
		Paths.sound('missnote1');
		Paths.sound('missnote2');
		Paths.sound('missnote3');
		
		if (PauseSubState.songName != null)
		{
			Paths.music(PauseSubState.songName);
		}
		else if (ClientPrefs.pauseMusic != 'None')
		{
			Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic));
		}
		
		#if desktop // DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, getPresence(), null);
		#end
		
		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		
		callOnScripts('onCreatePost', []);
		
		super.create();
		
		Paths.clearUnusedMemory();
		
		cacheCountdown();
		
		refreshZ(stage);
	}
	
	function noteskinLoading(skin:String = 'default')
	{
		if (FileSystem.exists(Paths.modsNoteskin(skin))) noteSkin = new NoteSkinHelper(Paths.modsNoteskin(skin));
		else if (FileSystem.exists(Paths.noteskin(skin))) noteSkin = new NoteSkinHelper(Paths.noteskin(skin));
		
		if (noteSkin == null) {
			noteSkin = new NoteSkinHelper(Paths.noteskin('default'));
		}
		
		arrowSkin = skin;
		
		if (noteSkin == null) {
            noteSkin = new NoteSkinHelper(Paths.noteskin('default'));
		}
	}
	
	function initNoteSkinning()
	{
		script_NOTEOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINENDOffsets = new Vector<FlxPoint>(SONG.keys);
		script_STRUMOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SPLASHOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERSTARTOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERLOOPOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERENDOffsets = new Vector<FlxPoint>(SONG.keys);
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i] = new FlxPoint();
			script_STRUMOffsets[i] = new FlxPoint();
			script_SUSTAINOffsets[i] = new FlxPoint();
			script_SUSTAINENDOffsets[i] = new FlxPoint();
			script_SPLASHOffsets[i] = new FlxPoint();
			script_COVERSTARTOffsets[i] = new FlxPoint();
			script_COVERLOOPOffsets[i] = new FlxPoint();
			script_COVERENDOffsets[i] = new FlxPoint();
		}
		
		// trace('noteskin file: "${SONG.arrowSkin}"');
		
		var skin = SONG.arrowSkin;
		if (skin == '' || skin == 'null' || skin == null) skin = 'default';
		
		noteskinLoading(skin);
		
		trace('Quants turned on: ${ClientPrefs.noteSkin.contains('Quant')}');
		trace('HAS quants: ${noteSkin.data.hasQuants}');
		
		if (ClientPrefs.noteSkin.contains('Quant') && noteSkin.data.hasQuants) noteskinLoading('QUANT$skin');
		
		NoteSkinHelper.setNoteHelpers(noteSkin, SONG.keys);
		
		// trace(noteSkin.data);
		
		arrowSkin = noteSkin.data.globalSkin;
		NoteSkinHelper.arrowSkins = [noteSkin.data.playerSkin, noteSkin.data.opponentSkin];
		if (SONG.lanes > 2)
		{
			for (i in 2...SONG.lanes)
			{
				NoteSkinHelper.arrowSkins.push(noteSkin.data.extraSkin);
			}
		}
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i].x = noteSkin.data.noteAnimations[i][0].offsets[0];
			script_NOTEOffsets[i].y = noteSkin.data.noteAnimations[i][0].offsets[1];
			
			script_SUSTAINOffsets[i].x = noteSkin.data.noteAnimations[i][1].offsets[0];
			script_SUSTAINOffsets[i].y = noteSkin.data.noteAnimations[i][1].offsets[1];
			
			script_SUSTAINENDOffsets[i].x = noteSkin.data.noteAnimations[i][2].offsets[0];
			script_SUSTAINENDOffsets[i].y = noteSkin.data.noteAnimations[i][2].offsets[1];
			
			script_SPLASHOffsets[i].x = noteSkin.data.noteSplashAnimations[i].offsets[0];
			script_SPLASHOffsets[i].y = noteSkin.data.noteSplashAnimations[i].offsets[1];
			
			script_COVERSTARTOffsets[i].x = noteSkin.data.noteCoverAnimations[i][0].offsets[0];
			script_COVERSTARTOffsets[i].y = noteSkin.data.noteCoverAnimations[i][0].offsets[1];
			
			script_COVERLOOPOffsets[i].x = noteSkin.data.noteCoverAnimations[i][1].offsets[0];
			script_COVERLOOPOffsets[i].y = noteSkin.data.noteCoverAnimations[i][1].offsets[1];
			
			script_COVERENDOffsets[i].x = noteSkin.data.noteCoverAnimations[i][2].offsets[0];
			script_COVERENDOffsets[i].y = noteSkin.data.noteCoverAnimations[i][2].offsets[1];
		}
		
		noteSplashSkin = noteSkin.data.noteSplashSkin;
		noteCoverSkin = noteSkin.data.noteCoverSkin;
	}
	
	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
				note.resizeByRatio(ratio);
			for (note in unspawnNotes)
				note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}
	
	public function addTextToDebug(text:String, color:FlxColor = FlxColor.WHITE)
	{
		#if LUA_ALLOWED
		if (luaDebugGroup == null)
		{
			luaDebugGroup = new FlxTypedGroup();
			luaDebugGroup.cameras = [camOther];
			add(luaDebugGroup);
		}
		
		var recycledText = luaDebugGroup.recycle(DebugLuaText, () -> new DebugLuaText(text, luaDebugGroup, color));
		recycledText.text = text;
		recycledText.color = color;
		recycledText.disableTime = 6;
		recycledText.alpha = 1;
		
		luaDebugGroup.insert(0, recycledText);
		
		luaDebugGroup.forEachAlive((spr:DebugLuaText) -> {
			spr.y += recycledText.height;
		});
		
		recycledText.y = 10;
		#end
	}
	
	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter, newBoyfriend);
				}
				
			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter, newDad);
				}
				
			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter, newGf);
				}
		}
	}
	
	function startCharacterScripts(name:String, char:Character) // taken from SSG
	{
		// trace(name);
		if (char.curCharacterScript != null)
		{
			switch (char.curCharacterScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast char.curCharacterScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast char.curCharacterScript);
				#end
			}
			funkyScripts.push(char.curCharacterScript);
			trace(char.curCharacterScript.scriptName);
		}
	}
	
	function initFunkinIris(filePath:String, ?name:String)
	{
		try {
			var script:FunkinIris = FunkinIris.fromFile(filePath);
			if (script.parsingException != null)
			{
				script.stop();
				NativeAPI.showMessageBox("Script Error", "Error parsing script:\n" + filePath + "\n" + Std.string(script.parsingException));
				return null;
			}
			trace('script $filePath initiated.');
			script.call('onCreate');
			hscriptArray.push(script);
			funkyScripts.push(script);
			return script;
		} catch (e:Dynamic) {
			NativeAPI.showMessageBox("Script Error", "Failed to load script:\n" + filePath + "\n" + Std.string(e));
			return null;
		}
	}
	
	function setStageData(stageData:StageFile)
	{
		defaultCamZoom = stageData.defaultZoom;
		FlxG.camera.zoom = defaultCamZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		
		if (stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;
		
		boyfriendCameraOffset = stageData.camera_boyfriend != null ? stageData.camera_boyfriend : [0, 0];

		opponentCameraOffset = stageData.camera_opponent != null ? stageData.camera_opponent : [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend != null ? stageData.camera_girlfriend : [0, 0];

		if (boyfriendGroup == null) boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		else
		{
			boyfriendGroup.x = BF_X;
			boyfriendGroup.y = BF_Y;
		}
		if (dadGroup == null) dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		else
		{
			dadGroup.x = DAD_X;
			dadGroup.y = DAD_Y;
		}
		
		if (gfGroup == null) gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		else
		{
			gfGroup.x = GF_X;
			gfGroup.y = GF_Y;
		}
	}
	
	// null checking
	function callHUDFunc(f:BaseHUD->Void) if (playHUD != null) f(playHUD);
	
	#if (debug && !RELEASE_BUILD)
	inline function addFlxWatches()
	{
		FlxG.watch.addFunction('curStep', () -> curStep);
		FlxG.watch.addFunction('curBeat', () -> curBeat);
		FlxG.watch.addFunction('curSection', () -> curSection);
		
		FlxG.watch.addFunction('songTime', () -> Std.string(FlxStringUtil.formatTime(FlxG.sound.music.time / 1000) + ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000)));
		FlxG.watch.addFunction('conductorPos', () -> Std.int(Conductor.songPosition));
	}
	#end
	
	override public function create()
	{
		Paths.clearStoredMemory();
		
		skipCountdown = false;
		countdownSounds = true;
		
		// for lua
		instance = this;
		
		#if (debug && !RELEASE_BUILD)
		addFlxWatches();
		#end
		
		GameOverSubstate.resetVariables();
		
		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; // Reset to default
		
		keysArray = [
			ClientPrefs.keyBinds.exists('note_left') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')) : null,
			ClientPrefs.keyBinds.exists('note_down') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')) : null,
			ClientPrefs.keyBinds.exists('note_up') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')) : null,
			ClientPrefs.keyBinds.exists('note_right') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right')) : null
		];
		
		songStartCallback = startCountdown;
		songEndCallback = endSong;
		
		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}
		
		if (FlxG.sound != null && FlxG.sound.music != null) {
            if (FlxG.sound.music != null) {
                FlxG.sound.music.stop();
            }
        }
		
		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		
		camGame = new FlxCamera();
		camOther = new FlxCamera();
		camHUD = new FlxCamera();
		camPause = new FlxCamera(); // camera for da pause menu, doing this bc pause menu goes to whatever the highest camera is
		
		camHUD.bgColor = 0x0;
		camOther.bgColor = 0x0;
		camPause.bgColor = 0x0;
		
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camPause, false);
		
		setOnScripts('this', this);
		
		setOnScripts('camGame', camGame);
		setOnScripts('camHUD', camHUD);
		setOnScripts('camOther', camOther);
		setOnScripts('camPause', camPause); // doubt we'll need but incase
		
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteCovers = new FlxTypedGroup<NoteSustainCover>();
		
		persistentUpdate = true;
		persistentDraw = true;
		
		if (SONG == null) SONG = Song.loadFromJson('tutorial');
		
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;
		
		arrowSkin = SONG.arrowSkin;
		
		initNoteSkinning();
		
		#if desktop
		storyDifficultyText = DifficultyUtil.difficulties[storyDifficulty];
		
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode) // fix this again
		{
			// detailsText = "";
		}
		else
		{
			// detailsText = "";
		}
		setOnScripts('isStoryMode', isStoryMode);
		
		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end
		
		var songName:String = Paths.formatToSongPath(SONG.song);
		
		if (SONG.stage == null || SONG.stage.length == 0) SONG.stage = 'stage';
		curStage = SONG.stage;
		
		stage = new Stage(curStage);
		stageData = stage.stageData;
		setStageData(stageData); // change to setter
		setOnScripts('stage', stage);
		
		// STAGE SCRIPTS
		stage.buildStage();
		
		if (stage.curStageScript != null)
		{
			switch (stage.curStageScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast stage.curStageScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast stage.curStageScript);
				#end
			}
			funkyScripts.push(stage.curStageScript);
			// trace(stage.curStageScript.scriptName);
		}
		
		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}
		
		if (callOnHScripts("onAddSpriteGroups", []) != Globals.Function_Stop)
		{
			add(stage);
			stage.add(gfGroup);
			stage.add(dadGroup);
			stage.add(boyfriendGroup);
		}
		
		// "GLOBAL" SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('scripts/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var sc = initFunkinIris(folder + file);
									if (sc != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1) SONG.gfVersion = gfVersion = 'gf';
		
		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter, gf);
			
			setOnScripts('gf', gf);
			setOnScripts('gfGroup', gfGroup);
		}
		
		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter, dad);
		dadMap.set(dad.curCharacter, dad);
		
		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter, boyfriend);
		boyfriendMap.set(boyfriend.curCharacter, boyfriend);
		
		setOnScripts('dad', dad);
		setOnScripts('dadGroup', dadGroup);
		
		setOnScripts('boyfriend', boyfriend);
		setOnScripts('boyfriendGroup', boyfriendGroup);
		
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}
		else
		{
			camPos.set(opponentCameraOffset[0], opponentCameraOffset[1]);
			camPos.x += dad.getGraphicMidpoint().x + dad.cameraPosition[0];
			camPos.y += dad.getGraphicMidpoint().y + dad.cameraPosition[1];
		}
		
		/* this is unneeded i think
			if (dad.curCharacter == gf.curCharacter && gf != null)
			{
				dad.setPosition(GF_X, GF_Y);
				if (gf != null) gf.visible = false;
			}
		 */
		
		flashSprite = new FlxSprite(0, 0).makeGraphic(1280, 720, 0xFFb30000);
		flashSprite.alpha = 0;
		flashSprite.cameras = [camOther];
		add(flashSprite);
		setOnScripts('flashSprite', flashSprite);
		
		Conductor.songPosition = -5000;
		
		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50);
		strumLine.visible = false;
		strumLine.scrollFactor.set();
		
		// temp
		updateTime = true;
		
		playFields = new FlxTypedGroup<PlayField>();
		add(playFields);
		add(grpNoteCovers);
		add(grpNoteSplashes);
		
		playHUD = new funkin.huds.SusHUD(this);
		insert(members.indexOf(playFields), playHUD); // Data told me to do this
		playHUD.cameras = [camHUD];
		
		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
		
		var cover:NoteSustainCover = new NoteSustainCover(100, 100, 0);
		grpNoteCovers.add(cover);
		cover.alpha = 0.0;
		
		meta = Metadata.getSong();
		
		generateSong(SONG.song);
		modManager = new ModManager(this);
		setOnHScripts("modManager", modManager);
		
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;
		
		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);
		
		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);
		
		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);
		
		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		FlxG.fixedTimestep = false;
		moveCameraSection();
		
		botplayTxt = new FlxText(400, 525, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("liber.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		
		playFields.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		grpNoteCovers.cameras = [camHUD];
		notes.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		
		setOnScripts('playFields', playFields);
		setOnScripts('grpNoteSplashes', grpNoteSplashes);
		setOnScripts('grpNoteCovers', grpNoteCovers);
		setOnScripts('notes', notes);
		setOnScripts('botplayTxt', botplayTxt);
		callOnLuas('onCreate', []);

		addHitbox(3);
   		_hitbox.visible = false;
		
		startingSong = true;
		
		// SONG SPECIFIC SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('songs/' + Paths.formatToSongPath(SONG.song) + '/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('songs/' + Paths.formatToSongPath(SONG.song) + '/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0,
			Paths.mods(Paths.currentModDirectory + '/songs/' + Paths.formatToSongPath(SONG.song) + '/'));
			
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/songs/' + Paths.formatToSongPath(SONG.song) + '/')); // using push instead of insert because these should run after everything else
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var sc = initFunkinIris(folder + file);
									if (sc != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		if (songStartCallback == null)
		{
			FlxG.log.error('songStartCallback is null! using default callback.');
			songStartCallback = startCountdown;
		}
		
		songStartCallback();
		
		RecalculateRating();
		updateScoreBar();
		
		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.hitsoundVolume > 0) Paths.sound('hitsound');
		Paths.sound('missnote1');
		Paths.sound('missnote2');
		Paths.sound('missnote3');
		
		if (PauseSubState.songName != null)
		{
			Paths.music(PauseSubState.songName);
		}
		else if (ClientPrefs.pauseMusic != 'None')
		{
			Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic));
		}
		
		#if desktop // DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, getPresence(), null);
		#end
		
		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		
		callOnScripts('onCreatePost', []);
		
		super.create();
		
		Paths.clearUnusedMemory();
		
		cacheCountdown();
		
		refreshZ(stage);
	}
	
	function noteskinLoading(skin:String = 'default')
	{
		if (FileSystem.exists(Paths.modsNoteskin(skin))) noteSkin = new NoteSkinHelper(Paths.modsNoteskin(skin));
		else if (FileSystem.exists(Paths.noteskin(skin))) noteSkin = new NoteSkinHelper(Paths.noteskin(skin));
		
		if (noteSkin == null) {
			noteSkin = new NoteSkinHelper(Paths.noteskin('default'));
		}
		
		arrowSkin = skin;
		
		if (noteSkin == null) {
            noteSkin = new NoteSkinHelper(Paths.noteskin('default'));
		}
	}
	
	function initNoteSkinning()
	{
		script_NOTEOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINENDOffsets = new Vector<FlxPoint>(SONG.keys);
		script_STRUMOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SPLASHOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERSTARTOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERLOOPOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERENDOffsets = new Vector<FlxPoint>(SONG.keys);
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i] = new FlxPoint();
			script_STRUMOffsets[i] = new FlxPoint();
			script_SUSTAINOffsets[i] = new FlxPoint();
			script_SUSTAINENDOffsets[i] = new FlxPoint();
			script_SPLASHOffsets[i] = new FlxPoint();
			script_COVERSTARTOffsets[i] = new FlxPoint();
			script_COVERLOOPOffsets[i] = new FlxPoint();
			script_COVERENDOffsets[i] = new FlxPoint();
		}
		
		// trace('noteskin file: "${SONG.arrowSkin}"');
		
		var skin = SONG.arrowSkin;
		if (skin == '' || skin == 'null' || skin == null) skin = 'default';
		
		noteskinLoading(skin);
		
		trace('Quants turned on: ${ClientPrefs.noteSkin.contains('Quant')}');
		trace('HAS quants: ${noteSkin.data.hasQuants}');
		
		if (ClientPrefs.noteSkin.contains('Quant') && noteSkin.data.hasQuants) noteskinLoading('QUANT$skin');
		
		NoteSkinHelper.setNoteHelpers(noteSkin, SONG.keys);
		
		// trace(noteSkin.data);
		
		arrowSkin = noteSkin.data.globalSkin;
		NoteSkinHelper.arrowSkins = [noteSkin.data.playerSkin, noteSkin.data.opponentSkin];
		if (SONG.lanes > 2)
		{
			for (i in 2...SONG.lanes)
			{
				NoteSkinHelper.arrowSkins.push(noteSkin.data.extraSkin);
			}
		}
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i].x = noteSkin.data.noteAnimations[i][0].offsets[0];
			script_NOTEOffsets[i].y = noteSkin.data.noteAnimations[i][0].offsets[1];
			
			script_SUSTAINOffsets[i].x = noteSkin.data.noteAnimations[i][1].offsets[0];
			script_SUSTAINOffsets[i].y = noteSkin.data.noteAnimations[i][1].offsets[1];
			
			script_SUSTAINENDOffsets[i].x = noteSkin.data.noteAnimations[i][2].offsets[0];
			script_SUSTAINENDOffsets[i].y = noteSkin.data.noteAnimations[i][2].offsets[1];
			
			script_SPLASHOffsets[i].x = noteSkin.data.noteSplashAnimations[i].offsets[0];
			script_SPLASHOffsets[i].y = noteSkin.data.noteSplashAnimations[i].offsets[1];
			
			script_COVERSTARTOffsets[i].x = noteSkin.data.noteCoverAnimations[i][0].offsets[0];
			script_COVERSTARTOffsets[i].y = noteSkin.data.noteCoverAnimations[i][0].offsets[1];
			
			script_COVERLOOPOffsets[i].x = noteSkin.data.noteCoverAnimations[i][1].offsets[0];
			script_COVERLOOPOffsets[i].y = noteSkin.data.noteCoverAnimations[i][1].offsets[1];
			
			script_COVERENDOffsets[i].x = noteSkin.data.noteCoverAnimations[i][2].offsets[0];
			script_COVERENDOffsets[i].y = noteSkin.data.noteCoverAnimations[i][2].offsets[1];
		}
		
		noteSplashSkin = noteSkin.data.noteSplashSkin;
		noteCoverSkin = noteSkin.data.noteCoverSkin;
	}
	
	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
				note.resizeByRatio(ratio);
			for (note in unspawnNotes)
				note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}
	
	public function addTextToDebug(text:String, color:FlxColor = FlxColor.WHITE)
	{
		#if LUA_ALLOWED
		if (luaDebugGroup == null)
		{
			luaDebugGroup = new FlxTypedGroup();
			luaDebugGroup.cameras = [camOther];
			add(luaDebugGroup);
		}
		
		var recycledText = luaDebugGroup.recycle(DebugLuaText, () -> new DebugLuaText(text, luaDebugGroup, color));
		recycledText.text = text;
		recycledText.color = color;
		recycledText.disableTime = 6;
		recycledText.alpha = 1;
		
		luaDebugGroup.insert(0, recycledText);
		
		luaDebugGroup.forEachAlive((spr:DebugLuaText) -> {
			spr.y += recycledText.height;
		});
		
		recycledText.y = 10;
		#end
	}
	
	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter, newBoyfriend);
				}
				
			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter, newDad);
				}
				
			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter, newGf);
				}
		}
	}
	
	function startCharacterScripts(name:String, char:Character) // taken from SSG
	{
		// trace(name);
		if (char.curCharacterScript != null)
		{
			switch (char.curCharacterScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast char.curCharacterScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast char.curCharacterScript);
				#end
			}
			funkyScripts.push(char.curCharacterScript);
			trace(char.curCharacterScript.scriptName);
		}
	}
	
	function initFunkinIris(filePath:String, ?name:String)
	{
		try {
			var script:FunkinIris = FunkinIris.fromFile(filePath);
			if (script.parsingException != null)
			{
				script.stop();
				NativeAPI.showMessageBox("Script Error", "Error parsing script:\n" + filePath + "\n" + Std.string(script.parsingException));
				return null;
			}
			trace('script $filePath initiated.');
			script.call('onCreate');
			hscriptArray.push(script);
			funkyScripts.push(script);
			return script;
		} catch (e:Dynamic) {
			NativeAPI.showMessageBox("Script Error", "Failed to load script:\n" + filePath + "\n" + Std.string(e));
			return null;
		}
	}
	
	function setStageData(stageData:StageFile)
	{
		defaultCamZoom = stageData.defaultZoom;
		FlxG.camera.zoom = defaultCamZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		
		if (stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;
		
		boyfriendCameraOffset = stageData.camera_boyfriend != null ? stageData.camera_boyfriend : [0, 0];

		opponentCameraOffset = stageData.camera_opponent != null ? stageData.camera_opponent : [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend != null ? stageData.camera_girlfriend : [0, 0];

		if (boyfriendGroup == null) boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		else
		{
			boyfriendGroup.x = BF_X;
			boyfriendGroup.y = BF_Y;
		}
		if (dadGroup == null) dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		else
		{
			dadGroup.x = DAD_X;
			dadGroup.y = DAD_Y;
		}
		
		if (gfGroup == null) gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		else
		{
			gfGroup.x = GF_X;
			gfGroup.y = GF_Y;
		}
	}
	
	// null checking
	function callHUDFunc(f:BaseHUD->Void) if (playHUD != null) f(playHUD);
	
	#if (debug && !RELEASE_BUILD)
	inline function addFlxWatches()
	{
		FlxG.watch.addFunction('curStep', () -> curStep);
		FlxG.watch.addFunction('curBeat', () -> curBeat);
		FlxG.watch.addFunction('curSection', () -> curSection);
		
		FlxG.watch.addFunction('songTime', () -> Std.string(FlxStringUtil.formatTime(FlxG.sound.music.time / 1000) + ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000)));
		FlxG.watch.addFunction('conductorPos', () -> Std.int(Conductor.songPosition));
	}
	#end
	
	override public function create()
	{
		Paths.clearStoredMemory();
		
		skipCountdown = false;
		countdownSounds = true;
		
		// for lua
		instance = this;
		
		#if (debug && !RELEASE_BUILD)
		addFlxWatches();
		#end
		
		GameOverSubstate.resetVariables();
		
		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; // Reset to default
		
		keysArray = [
			ClientPrefs.keyBinds.exists('note_left') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')) : null,
			ClientPrefs.keyBinds.exists('note_down') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')) : null,
			ClientPrefs.keyBinds.exists('note_up') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')) : null,
			ClientPrefs.keyBinds.exists('note_right') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right')) : null
		];
		
		songStartCallback = startCountdown;
		songEndCallback = endSong;
		
		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}
		
		if (FlxG.sound != null && FlxG.sound.music != null) {
            if (FlxG.sound.music != null) {
                FlxG.sound.music.stop();
            }
        }
		
		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		
		camGame = new FlxCamera();
		camOther = new FlxCamera();
		camHUD = new FlxCamera();
		camPause = new FlxCamera(); // camera for da pause menu, doing this bc pause menu goes to whatever the highest camera is
		
		camHUD.bgColor = 0x0;
		camOther.bgColor = 0x0;
		camPause.bgColor = 0x0;
		
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camPause, false);
		
		setOnScripts('this', this);
		
		setOnScripts('camGame', camGame);
		setOnScripts('camHUD', camHUD);
		setOnScripts('camOther', camOther);
		setOnScripts('camPause', camPause); // doubt we'll need but incase
		
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteCovers = new FlxTypedGroup<NoteSustainCover>();
		
		persistentUpdate = true;
		persistentDraw = true;
		
		if (SONG == null) SONG = Song.loadFromJson('tutorial');
		
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;
		
		arrowSkin = SONG.arrowSkin;
		
		initNoteSkinning();
		
		#if desktop
		storyDifficultyText = DifficultyUtil.difficulties[storyDifficulty];
		
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode) // fix this again
		{
			// detailsText = "";
		}
		else
		{
			// detailsText = "";
		}
		setOnScripts('isStoryMode', isStoryMode);
		
		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end
		
		var songName:String = Paths.formatToSongPath(SONG.song);
		
		if (SONG.stage == null || SONG.stage.length == 0) SONG.stage = 'stage';
		curStage = SONG.stage;
		
		stage = new Stage(curStage);
		stageData = stage.stageData;
		setStageData(stageData); // change to setter
		setOnScripts('stage', stage);
		
		// STAGE SCRIPTS
		stage.buildStage();
		
		if (stage.curStageScript != null)
		{
			switch (stage.curStageScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast stage.curStageScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast stage.curStageScript);
				#end
			}
			funkyScripts.push(stage.curStageScript);
			// trace(stage.curStageScript.scriptName);
		}
		
		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}
		
		if (callOnHScripts("onAddSpriteGroups", []) != Globals.Function_Stop)
		{
			add(stage);
			stage.add(gfGroup);
			stage.add(dadGroup);
			stage.add(boyfriendGroup);
		}
		
		// "GLOBAL" SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('scripts/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var sc = initFunkinIris(folder + file);
									if (sc != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1) SONG.gfVersion = gfVersion = 'gf';
		
		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter, gf);
			
			setOnScripts('gf', gf);
			setOnScripts('gfGroup', gfGroup);
		}
		
		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter, dad);
		dadMap.set(dad.curCharacter, dad);
		
		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter, boyfriend);
		boyfriendMap.set(boyfriend.curCharacter, boyfriend);
		
		setOnScripts('dad', dad);
		setOnScripts('dadGroup', dadGroup);
		
		setOnScripts('boyfriend', boyfriend);
		setOnScripts('boyfriendGroup', boyfriendGroup);
		
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}
		else
		{
			camPos.set(opponentCameraOffset[0], opponentCameraOffset[1]);
			camPos.x += dad.getGraphicMidpoint().x + dad.cameraPosition[0];
			camPos.y += dad.getGraphicMidpoint().y + dad.cameraPosition[1];
		}
		
		/* this is unneeded i think
			if (dad.curCharacter == gf.curCharacter && gf != null)
			{
				dad.setPosition(GF_X, GF_Y);
				if (gf != null) gf.visible = false;
			}
		 */
		
		flashSprite = new FlxSprite(0, 0).makeGraphic(1280, 720, 0xFFb30000);
		flashSprite.alpha = 0;
		flashSprite.cameras = [camOther];
		add(flashSprite);
		setOnScripts('flashSprite', flashSprite);
		
		Conductor.songPosition = -5000;
		
		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50);
		strumLine.visible = false;
		strumLine.scrollFactor.set();
		
		// temp
		updateTime = true;
		
		playFields = new FlxTypedGroup<PlayField>();
		add(playFields);
		add(grpNoteCovers);
		add(grpNoteSplashes);
		
		playHUD = new funkin.huds.SusHUD(this);
		insert(members.indexOf(playFields), playHUD); // Data told me to do this
		playHUD.cameras = [camHUD];
		
		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
		
		var cover:NoteSustainCover = new NoteSustainCover(100, 100, 0);
		grpNoteCovers.add(cover);
		cover.alpha = 0.0;
		
		meta = Metadata.getSong();
		
		generateSong(SONG.song);
		modManager = new ModManager(this);
		setOnHScripts("modManager", modManager);
		
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;
		
		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);
		
		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);
		
		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);
		
		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		FlxG.fixedTimestep = false;
		moveCameraSection();
		
		botplayTxt = new FlxText(400, 525, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("liber.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		
		playFields.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		grpNoteCovers.cameras = [camHUD];
		notes.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		
		setOnScripts('playFields', playFields);
		setOnScripts('grpNoteSplashes', grpNoteSplashes);
		setOnScripts('grpNoteCovers', grpNoteCovers);
		setOnScripts('notes', notes);
		setOnScripts('botplayTxt', botplayTxt);
		callOnLuas('onCreate', []);

		addHitbox(3);
   		_hitbox.visible = false;
		
		startingSong = true;
		
		// SONG SPECIFIC SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('songs/' + Paths.formatToSongPath(SONG.song) + '/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('songs/' + Paths.formatToSongPath(SONG.song) + '/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0,
			Paths.mods(Paths.currentModDirectory + '/songs/' + Paths.formatToSongPath(SONG.song) + '/'));
			
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/songs/' + Paths.formatToSongPath(SONG.song) + '/')); // using push instead of insert because these should run after everything else
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var sc = initFunkinIris(folder + file);
									if (sc != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		if (songStartCallback == null)
		{
			FlxG.log.error('songStartCallback is null! using default callback.');
			songStartCallback = startCountdown;
		}
		
		songStartCallback();
		
		RecalculateRating();
		updateScoreBar();
		
		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.hitsoundVolume > 0) Paths.sound('hitsound');
		Paths.sound('missnote1');
		Paths.sound('missnote2');
		Paths.sound('missnote3');
		
		if (PauseSubState.songName != null)
		{
			Paths.music(PauseSubState.songName);
		}
		else if (ClientPrefs.pauseMusic != 'None')
		{
			Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic));
		}
		
		#if desktop // DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, getPresence(), null);
		#end
		
		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		
		callOnScripts('onCreatePost', []);
		
		super.create();
		
		Paths.clearUnusedMemory();
		
		cacheCountdown();
		
		refreshZ(stage);
	}
	
	function noteskinLoading(skin:String = 'default')
	{
		if (FileSystem.exists(Paths.modsNoteskin(skin))) noteSkin = new NoteSkinHelper(Paths.modsNoteskin(skin));
		else if (FileSystem.exists(Paths.noteskin(skin))) noteSkin = new NoteSkinHelper(Paths.noteskin(skin));
		
		if (noteSkin == null) {
			noteSkin = new NoteSkinHelper(Paths.noteskin('default'));
		}
		
		arrowSkin = skin;
		
		if (noteSkin == null) {
            noteSkin = new NoteSkinHelper(Paths.noteskin('default'));
		}
	}
	
	function initNoteSkinning()
	{
		script_NOTEOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINENDOffsets = new Vector<FlxPoint>(SONG.keys);
		script_STRUMOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SPLASHOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERSTARTOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERLOOPOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERENDOffsets = new Vector<FlxPoint>(SONG.keys);
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i] = new FlxPoint();
			script_STRUMOffsets[i] = new FlxPoint();
			script_SUSTAINOffsets[i] = new FlxPoint();
			script_SUSTAINENDOffsets[i] = new FlxPoint();
			script_SPLASHOffsets[i] = new FlxPoint();
			script_COVERSTARTOffsets[i] = new FlxPoint();
			script_COVERLOOPOffsets[i] = new FlxPoint();
			script_COVERENDOffsets[i] = new FlxPoint();
		}
		
		// trace('noteskin file: "${SONG.arrowSkin}"');
		
		var skin = SONG.arrowSkin;
		if (skin == '' || skin == 'null' || skin == null) skin = 'default';
		
		noteskinLoading(skin);
		
		trace('Quants turned on: ${ClientPrefs.noteSkin.contains('Quant')}');
		trace('HAS quants: ${noteSkin.data.hasQuants}');
		
		if (ClientPrefs.noteSkin.contains('Quant') && noteSkin.data.hasQuants) noteskinLoading('QUANT$skin');
		
		NoteSkinHelper.setNoteHelpers(noteSkin, SONG.keys);
		
		// trace(noteSkin.data);
		
		arrowSkin = noteSkin.data.globalSkin;
		NoteSkinHelper.arrowSkins = [noteSkin.data.playerSkin, noteSkin.data.opponentSkin];
		if (SONG.lanes > 2)
		{
			for (i in 2...SONG.lanes)
			{
				NoteSkinHelper.arrowSkins.push(noteSkin.data.extraSkin);
			}
		}
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i].x = noteSkin.data.noteAnimations[i][0].offsets[0];
			script_NOTEOffsets[i].y = noteSkin.data.noteAnimations[i][0].offsets[1];
			
			script_SUSTAINOffsets[i].x = noteSkin.data.noteAnimations[i][1].offsets[0];
			script_SUSTAINOffsets[i].y = noteSkin.data.noteAnimations[i][1].offsets[1];
			
			script_SUSTAINENDOffsets[i].x = noteSkin.data.noteAnimations[i][2].offsets[0];
			script_SUSTAINENDOffsets[i].y = noteSkin.data.noteAnimations[i][2].offsets[1];
			
			script_SPLASHOffsets[i].x = noteSkin.data.noteSplashAnimations[i].offsets[0];
			script_SPLASHOffsets[i].y = noteSkin.data.noteSplashAnimations[i].offsets[1];
			
			script_COVERSTARTOffsets[i].x = noteSkin.data.noteCoverAnimations[i][0].offsets[0];
			script_COVERSTARTOffsets[i].y = noteSkin.data.noteCoverAnimations[i][0].offsets[1];
			
			script_COVERLOOPOffsets[i].x = noteSkin.data.noteCoverAnimations[i][1].offsets[0];
			script_COVERLOOPOffsets[i].y = noteSkin.data.noteCoverAnimations[i][1].offsets[1];
			
			script_COVERENDOffsets[i].x = noteSkin.data.noteCoverAnimations[i][2].offsets[0];
			script_COVERENDOffsets[i].y = noteSkin.data.noteCoverAnimations[i][2].offsets[1];
		}
		
		noteSplashSkin = noteSkin.data.noteSplashSkin;
		noteCoverSkin = noteSkin.data.noteCoverSkin;
	}
	
	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
				note.resizeByRatio(ratio);
			for (note in unspawnNotes)
				note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}
	
	public function addTextToDebug(text:String, color:FlxColor = FlxColor.WHITE)
	{
		#if LUA_ALLOWED
		if (luaDebugGroup == null)
		{
			luaDebugGroup = new FlxTypedGroup();
			luaDebugGroup.cameras = [camOther];
			add(luaDebugGroup);
		}
		
		var recycledText = luaDebugGroup.recycle(DebugLuaText, () -> new DebugLuaText(text, luaDebugGroup, color));
		recycledText.text = text;
		recycledText.color = color;
		recycledText.disableTime = 6;
		recycledText.alpha = 1;
		
		luaDebugGroup.insert(0, recycledText);
		
		luaDebugGroup.forEachAlive((spr:DebugLuaText) -> {
			spr.y += recycledText.height;
		});
		
		recycledText.y = 10;
		#end
	}
	
	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter, newBoyfriend);
				}
				
			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter, newDad);
				}
				
			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter, newGf);
				}
		}
	}
	
	function startCharacterScripts(name:String, char:Character) // taken from SSG
	{
		// trace(name);
		if (char.curCharacterScript != null)
		{
			switch (char.curCharacterScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast char.curCharacterScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast char.curCharacterScript);
				#end
			}
			funkyScripts.push(char.curCharacterScript);
			trace(char.curCharacterScript.scriptName);
		}
	}
	
	function initFunkinIris(filePath:String, ?name:String)
	{
		try {
			var script:FunkinIris = FunkinIris.fromFile(filePath);
			if (script.parsingException != null)
			{
				script.stop();
				NativeAPI.showMessageBox("Script Error", "Error parsing script:\n" + filePath + "\n" + Std.string(script.parsingException));
				return null;
			}
			trace('script $filePath initiated.');
			script.call('onCreate');
			hscriptArray.push(script);
			funkyScripts.push(script);
			return script;
		} catch (e:Dynamic) {
			NativeAPI.showMessageBox("Script Error", "Failed to load script:\n" + filePath + "\n" + Std.string(e));
			return null;
		}
	}
	
	function setStageData(stageData:StageFile)
	{
		defaultCamZoom = stageData.defaultZoom;
		FlxG.camera.zoom = defaultCamZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		
		if (stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;
		
		boyfriendCameraOffset = stageData.camera_boyfriend != null ? stageData.camera_boyfriend : [0, 0];

		opponentCameraOffset = stageData.camera_opponent != null ? stageData.camera_opponent : [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend != null ? stageData.camera_girlfriend : [0, 0];

		if (boyfriendGroup == null) boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		else
		{
			boyfriendGroup.x = BF_X;
			boyfriendGroup.y = BF_Y;
		}
		if (dadGroup == null) dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		else
		{
			dadGroup.x = DAD_X;
			dadGroup.y = DAD_Y;
		}
		
		if (gfGroup == null) gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		else
		{
			gfGroup.x = GF_X;
			gfGroup.y = GF_Y;
		}
	}
	
	// null checking
	function callHUDFunc(f:BaseHUD->Void) if (playHUD != null) f(playHUD);
	
	#if (debug && !RELEASE_BUILD)
	inline function addFlxWatches()
	{
		FlxG.watch.addFunction('curStep', () -> curStep);
		FlxG.watch.addFunction('curBeat', () -> curBeat);
		FlxG.watch.addFunction('curSection', () -> curSection);
		
		FlxG.watch.addFunction('songTime', () -> Std.string(FlxStringUtil.formatTime(FlxG.sound.music.time / 1000) + ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000)));
		FlxG.watch.addFunction('conductorPos', () -> Std.int(Conductor.songPosition));
	}
	#end
	
	override public function create()
	{
		Paths.clearStoredMemory();
		
		skipCountdown = false;
		countdownSounds = true;
		
		// for lua
		instance = this;
		
		#if (debug && !RELEASE_BUILD)
		addFlxWatches();
		#end
		
		GameOverSubstate.resetVariables();
		
		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; // Reset to default
		
		keysArray = [
			ClientPrefs.keyBinds.exists('note_left') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')) : null,
			ClientPrefs.keyBinds.exists('note_down') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')) : null,
			ClientPrefs.keyBinds.exists('note_up') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')) : null,
			ClientPrefs.keyBinds.exists('note_right') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right')) : null
		];
		
		songStartCallback = startCountdown;
		songEndCallback = endSong;
		
		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}
		
		if (FlxG.sound != null && FlxG.sound.music != null) {
            if (FlxG.sound.music != null) {
                FlxG.sound.music.stop();
            }
        }
		
		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		
		camGame = new FlxCamera();
		camOther = new FlxCamera();
		camHUD = new FlxCamera();
		camPause = new FlxCamera(); // camera for da pause menu, doing this bc pause menu goes to whatever the highest camera is
		
		camHUD.bgColor = 0x0;
		camOther.bgColor = 0x0;
		camPause.bgColor = 0x0;
		
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camPause, false);
		
		setOnScripts('this', this);
		
		setOnScripts('camGame', camGame);
		setOnScripts('camHUD', camHUD);
		setOnScripts('camOther', camOther);
		setOnScripts('camPause', camPause); // doubt we'll need but incase
		
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteCovers = new FlxTypedGroup<NoteSustainCover>();
		
		persistentUpdate = true;
		persistentDraw = true;
		
		if (SONG == null) SONG = Song.loadFromJson('tutorial');
		
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;
		
		arrowSkin = SONG.arrowSkin;
		
		initNoteSkinning();
		
		#if desktop
		storyDifficultyText = DifficultyUtil.difficulties[storyDifficulty];
		
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode) // fix this again
		{
			// detailsText = "";
		}
		else
		{
			// detailsText = "";
		}
		setOnScripts('isStoryMode', isStoryMode);
		
		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end
		
		var songName:String = Paths.formatToSongPath(SONG.song);
		
		if (SONG.stage == null || SONG.stage.length == 0) SONG.stage = 'stage';
		curStage = SONG.stage;
		
		stage = new Stage(curStage);
		stageData = stage.stageData;
		setStageData(stageData); // change to setter
		setOnScripts('stage', stage);
		
		// STAGE SCRIPTS
		stage.buildStage();
		
		if (stage.curStageScript != null)
		{
			switch (stage.curStageScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast stage.curStageScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast stage.curStageScript);
				#end
			}
			funkyScripts.push(stage.curStageScript);
			// trace(stage.curStageScript.scriptName);
		}
		
		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}
		
		if (callOnHScripts("onAddSpriteGroups", []) != Globals.Function_Stop)
		{
			add(stage);
			stage.add(gfGroup);
			stage.add(dadGroup);
			stage.add(boyfriendGroup);
		}
		
		// "GLOBAL" SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('scripts/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var sc = initFunkinIris(folder + file);
									if (sc != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1) SONG.gfVersion = gfVersion = 'gf';
		
		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter, gf);
			
			setOnScripts('gf', gf);
			setOnScripts('gfGroup', gfGroup);
		}
		
		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter, dad);
		dadMap.set(dad.curCharacter, dad);
		
		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter, boyfriend);
		boyfriendMap.set(boyfriend.curCharacter, boyfriend);
		
		setOnScripts('dad', dad);
		setOnScripts('dadGroup', dadGroup);
		
		setOnScripts('boyfriend', boyfriend);
		setOnScripts('boyfriendGroup', boyfriendGroup);
		
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}
		else
		{
			camPos.set(opponentCameraOffset[0], opponentCameraOffset[1]);
			camPos.x += dad.getGraphicMidpoint().x + dad.cameraPosition[0];
			camPos.y += dad.getGraphicMidpoint().y + dad.cameraPosition[1];
		}
		
		/* this is unneeded i think
			if (dad.curCharacter == gf.curCharacter && gf != null)
			{
				dad.setPosition(GF_X, GF_Y);
				if (gf != null) gf.visible = false;
			}
		 */
		
		flashSprite = new FlxSprite(0, 0).makeGraphic(1280, 720, 0xFFb30000);
		flashSprite.alpha = 0;
		flashSprite.cameras = [camOther];
		add(flashSprite);
		setOnScripts('flashSprite', flashSprite);
		
		Conductor.songPosition = -5000;
		
		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50);
		strumLine.visible = false;
		strumLine.scrollFactor.set();
		
		// temp
		updateTime = true;
		
		playFields = new FlxTypedGroup<PlayField>();
		add(playFields);
		add(grpNoteCovers);
		add(grpNoteSplashes);
		
		playHUD = new funkin.huds.SusHUD(this);
		insert(members.indexOf(playFields), playHUD); // Data told me to do this
		playHUD.cameras = [camHUD];
		
		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
		
		var cover:NoteSustainCover = new NoteSustainCover(100, 100, 0);
		grpNoteCovers.add(cover);
		cover.alpha = 0.0;
		
		meta = Metadata.getSong();
		
		generateSong(SONG.song);
		modManager = new ModManager(this);
		setOnHScripts("modManager", modManager);
		
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;
		
		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);
		
		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);
		
		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);
		
		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		
		FlxG.fixedTimestep = false;
		moveCameraSection();
		
		botplayTxt = new FlxText(400, 525, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("liber.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		
		playFields.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		grpNoteCovers.cameras = [camHUD];
		notes.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		
		setOnScripts('playFields', playFields);
		setOnScripts('grpNoteSplashes', grpNoteSplashes);
		setOnScripts('grpNoteCovers', grpNoteCovers);
		setOnScripts('notes', notes);
		setOnScripts('botplayTxt', botplayTxt);
		callOnLuas('onCreate', []);

		addHitbox(3);
   		_hitbox.visible = false;
		
		startingSong = true;
		
		// SONG SPECIFIC SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('songs/' + Paths.formatToSongPath(SONG.song) + '/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('songs/' + Paths.formatToSongPath(SONG.song) + '/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0,
			Paths.mods(Paths.currentModDirectory + '/songs/' + Paths.formatToSongPath(SONG.song) + '/'));
			
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/songs/' + Paths.formatToSongPath(SONG.song) + '/')); // using push instead of insert because these should run after everything else
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var sc = initFunkinIris(folder + file);
									if (sc != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		if (songStartCallback == null)
		{
			FlxG.log.error('songStartCallback is null! using default callback.');
			songStartCallback = startCountdown;
		}
		
		songStartCallback();
		
		RecalculateRating();
		updateScoreBar();
		
		// PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if (ClientPrefs.hitsoundVolume > 0) Paths.sound('hitsound');
		Paths.sound('missnote1');
		Paths.sound('missnote2');
		Paths.sound('missnote3');
		
		if (PauseSubState.songName != null)
		{
			Paths.music(PauseSubState.songName);
		}
		else if (ClientPrefs.pauseMusic != 'None')
		{
			Paths.music(Paths.formatToSongPath(ClientPrefs.pauseMusic));
		}
		
		#if desktop // DISCORD_ALLOWED
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, getPresence(), null);
		#end
		
		if (!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		
		callOnScripts('onCreatePost', []);
		
		super.create();
		
		Paths.clearUnusedMemory();
		
		cacheCountdown();
		
		refreshZ(stage);
	}
	
	function noteskinLoading(skin:String = 'default')
	{
		if (FileSystem.exists(Paths.modsNoteskin(skin))) noteSkin = new NoteSkinHelper(Paths.modsNoteskin(skin));
		else if (FileSystem.exists(Paths.noteskin(skin))) noteSkin = new NoteSkinHelper(Paths.noteskin(skin));
		
		if (noteSkin == null) {
			noteSkin = new NoteSkinHelper(Paths.noteskin('default'));
		}
		
		arrowSkin = skin;
		
		if (noteSkin == null) {
            noteSkin = new NoteSkinHelper(Paths.noteskin('default'));
		}
	}
	
	function initNoteSkinning()
	{
		script_NOTEOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SUSTAINENDOffsets = new Vector<FlxPoint>(SONG.keys);
		script_STRUMOffsets = new Vector<FlxPoint>(SONG.keys);
		script_SPLASHOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERSTARTOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERLOOPOffsets = new Vector<FlxPoint>(SONG.keys);
		script_COVERENDOffsets = new Vector<FlxPoint>(SONG.keys);
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i] = new FlxPoint();
			script_STRUMOffsets[i] = new FlxPoint();
			script_SUSTAINOffsets[i] = new FlxPoint();
			script_SUSTAINENDOffsets[i] = new FlxPoint();
			script_SPLASHOffsets[i] = new FlxPoint();
			script_COVERSTARTOffsets[i] = new FlxPoint();
			script_COVERLOOPOffsets[i] = new FlxPoint();
			script_COVERENDOffsets[i] = new FlxPoint();
		}
		
		// trace('noteskin file: "${SONG.arrowSkin}"');
		
		var skin = SONG.arrowSkin;
		if (skin == '' || skin == 'null' || skin == null) skin = 'default';
		
		noteskinLoading(skin);
		
		trace('Quants turned on: ${ClientPrefs.noteSkin.contains('Quant')}');
		trace('HAS quants: ${noteSkin.data.hasQuants}');
		
		if (ClientPrefs.noteSkin.contains('Quant') && noteSkin.data.hasQuants) noteskinLoading('QUANT$skin');
		
		NoteSkinHelper.setNoteHelpers(noteSkin, SONG.keys);
		
		// trace(noteSkin.data);
		
		arrowSkin = noteSkin.data.globalSkin;
		NoteSkinHelper.arrowSkins = [noteSkin.data.playerSkin, noteSkin.data.opponentSkin];
		if (SONG.lanes > 2)
		{
			for (i in 2...SONG.lanes)
			{
				NoteSkinHelper.arrowSkins.push(noteSkin.data.extraSkin);
			}
		}
		
		for (i in 0...SONG.keys)
		{
			script_NOTEOffsets[i].x = noteSkin.data.noteAnimations[i][0].offsets[0];
			script_NOTEOffsets[i].y = noteSkin.data.noteAnimations[i][0].offsets[1];
			
			script_SUSTAINOffsets[i].x = noteSkin.data.noteAnimations[i][1].offsets[0];
			script_SUSTAINOffsets[i].y = noteSkin.data.noteAnimations[i][1].offsets[1];
			
			script_SUSTAINENDOffsets[i].x = noteSkin.data.noteAnimations[i][2].offsets[0];
			script_SUSTAINENDOffsets[i].y = noteSkin.data.noteAnimations[i][2].offsets[1];
			
			script_SPLASHOffsets[i].x = noteSkin.data.noteSplashAnimations[i].offsets[0];
			script_SPLASHOffsets[i].y = noteSkin.data.noteSplashAnimations[i].offsets[1];
			
			script_COVERSTARTOffsets[i].x = noteSkin.data.noteCoverAnimations[i][0].offsets[0];
			script_COVERSTARTOffsets[i].y = noteSkin.data.noteCoverAnimations[i][0].offsets[1];
			
			script_COVERLOOPOffsets[i].x = noteSkin.data.noteCoverAnimations[i][1].offsets[0];
			script_COVERLOOPOffsets[i].y = noteSkin.data.noteCoverAnimations[i][1].offsets[1];
			
			script_COVERENDOffsets[i].x = noteSkin.data.noteCoverAnimations[i][2].offsets[0];
			script_COVERENDOffsets[i].y = noteSkin.data.noteCoverAnimations[i][2].offsets[1];
		}
		
		noteSplashSkin = noteSkin.data.noteSplashSkin;
		noteCoverSkin = noteSkin.data.noteCoverSkin;
	}
	
	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
				note.resizeByRatio(ratio);
			for (note in unspawnNotes)
				note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}
	
	public function addTextToDebug(text:String, color:FlxColor = FlxColor.WHITE)
	{
		#if LUA_ALLOWED
		if (luaDebugGroup == null)
		{
			luaDebugGroup = new FlxTypedGroup();
			luaDebugGroup.cameras = [camOther];
			add(luaDebugGroup);
		}
		
		var recycledText = luaDebugGroup.recycle(DebugLuaText, () -> new DebugLuaText(text, luaDebugGroup, color));
		recycledText.text = text;
		recycledText.color = color;
		recycledText.disableTime = 6;
		recycledText.alpha = 1;
		
		luaDebugGroup.insert(0, recycledText);
		
		luaDebugGroup.forEachAlive((spr:DebugLuaText) -> {
			spr.y += recycledText.height;
		});
		
		recycledText.y = 10;
		#end
	}
	
	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter, newBoyfriend);
				}
				
			case 1:
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter, newDad);
				}
				
			case 2:
				if (gf != null && !gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter, newGf);
				}
		}
	}
	
	function startCharacterScripts(name:String, char:Character) // taken from SSG
	{
		// trace(name);
		if (char.curCharacterScript != null)
		{
			switch (char.curCharacterScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast char.curCharacterScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast char.curCharacterScript);
				#end
			}
			funkyScripts.push(char.curCharacterScript);
			trace(char.curCharacterScript.scriptName);
		}
	}
	
	function initFunkinIris(filePath:String, ?name:String)
	{
		try {
			var script:FunkinIris = FunkinIris.fromFile(filePath);
			if (script.parsingException != null)
			{
				script.stop();
				NativeAPI.showMessageBox("Script Error", "Error parsing script:\n" + filePath + "\n" + Std.string(script.parsingException));
				return null;
			}
			trace('script $filePath initiated.');
			script.call('onCreate');
			hscriptArray.push(script);
			funkyScripts.push(script);
			return script;
		} catch (e:Dynamic) {
			NativeAPI.showMessageBox("Script Error", "Failed to load script:\n" + filePath + "\n" + Std.string(e));
			return null;
		}
	}
	
	function setStageData(stageData:StageFile)
	{
		defaultCamZoom = stageData.defaultZoom;
		FlxG.camera.zoom = defaultCamZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];
		
		if (stageData.camera_speed != null) cameraSpeed = stageData.camera_speed;
		
		boyfriendCameraOffset = stageData.camera_boyfriend != null ? stageData.camera_boyfriend : [0, 0];

		opponentCameraOffset = stageData.camera_opponent != null ? stageData.camera_opponent : [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend != null ? stageData.camera_girlfriend : [0, 0];

		if (boyfriendGroup == null) boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		else
		{
			boyfriendGroup.x = BF_X;
			boyfriendGroup.y = BF_Y;
		}
		if (dadGroup == null) dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		else
		{
			dadGroup.x = DAD_X;
			dadGroup.y = DAD_Y;
		}
		
		if (gfGroup == null) gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		else
		{
			gfGroup.x = GF_X;
			gfGroup.y = GF_Y;
		}
	}
	
	// null checking
	function callHUDFunc(f:BaseHUD->Void) if (playHUD != null) f(playHUD);
	
	#if (debug && !RELEASE_BUILD)
	inline function addFlxWatches()
	{
		FlxG.watch.addFunction('curStep', () -> curStep);
		FlxG.watch.addFunction('curBeat', () -> curBeat);
		FlxG.watch.addFunction('curSection', () -> curSection);
		
		FlxG.watch.addFunction('songTime', () -> Std.string(FlxStringUtil.formatTime(FlxG.sound.music.time / 1000) + ' / ' + FlxStringUtil.formatTime(FlxG.sound.music.length / 1000)));
		FlxG.watch.addFunction('conductorPos', () -> Std.int(Conductor.songPosition));
	}
	#end
	
	override public function create()
	{
		Paths.clearStoredMemory();
		
		skipCountdown = false;
		countdownSounds = true;
		
		// for lua
		instance = this;
		
		#if (debug && !RELEASE_BUILD)
		addFlxWatches();
		#end
		
		GameOverSubstate.resetVariables();
		
		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; // Reset to default
		
		keysArray = [
			ClientPrefs.keyBinds.exists('note_left') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')) : null,
			ClientPrefs.keyBinds.exists('note_down') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')) : null,
			ClientPrefs.keyBinds.exists('note_up') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')) : null,
			ClientPrefs.keyBinds.exists('note_right') ? ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right')) : null
		];
		
		songStartCallback = startCountdown;
		songEndCallback = endSong;
		
		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}
		
		if (FlxG.sound != null && FlxG.sound.music != null) {
            if (FlxG.sound.music != null) {
                FlxG.sound.music.stop();
            }
        }
		
		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		
		camGame = new FlxCamera();
		camOther = new FlxCamera();
		camHUD = new FlxCamera();
		camPause = new FlxCamera(); // camera for da pause menu, doing this bc pause menu goes to whatever the highest camera is
		
		camHUD.bgColor = 0x0;
		camOther.bgColor = 0x0;
		camPause.bgColor = 0x0;
		
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camPause, false);
		
		setOnScripts('this', this);
		
		setOnScripts('camGame', camGame);
		setOnScripts('camHUD', camHUD);
		setOnScripts('camOther', camOther);
		setOnScripts('camPause', camPause); // doubt we'll need but incase
		
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteCovers = new FlxTypedGroup<NoteSustainCover>();
		
		persistentUpdate = true;
		persistentDraw = true;
		
		if (SONG == null) SONG = Song.loadFromJson('tutorial');
		
		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;
		
		arrowSkin = SONG.arrowSkin;
		
		initNoteSkinning();
		
		#if desktop
		storyDifficultyText = DifficultyUtil.difficulties[storyDifficulty];
		
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode) // fix this again
		{
			// detailsText = "";
		}
		else
		{
			// detailsText = "";
		}
		setOnScripts('isStoryMode', isStoryMode);
		
		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end
		
		var songName:String = Paths.formatToSongPath(SONG.song);
		
		if (SONG.stage == null || SONG.stage.length == 0) SONG.stage = 'stage';
		curStage = SONG.stage;
		
		stage = new Stage(curStage);
		stageData = stage.stageData;
		setStageData(stageData); // change to setter
		setOnScripts('stage', stage);
		
		// STAGE SCRIPTS
		stage.buildStage();
		
		if (stage.curStageScript != null)
		{
			switch (stage.curStageScript.scriptType)
			{
				case HSCRIPT:
					hscriptArray.push(cast stage.curStageScript);
				#if LUA_ALLOWED
				case LUA:
					luaArray.push(cast stage.curStageScript);
				#end
			}
			funkyScripts.push(stage.curStageScript);
			// trace(stage.curStageScript.scriptName);
		}
		
		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}
		
		if (callOnHScripts("onAddSpriteGroups", []) != Globals.Function_Stop)
		{
			add(stage);
			stage.add(gfGroup);
			stage.add(dadGroup);
			stage.add(boyfriendGroup);
		}
		
		// "GLOBAL" SCRIPTS
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getSharedPath('scripts/')];
		
		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		
		for (mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		#end
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (!filesPushed.contains(file))
					{
						if (file.endsWith('.lua'))
						{
							#if LUA_ALLOWED
							var script = new FunkinLua(folder + file);
							luaArray.push(script);
							funkyScripts.push(script);
							filesPushed.push(file);
							#end
						}
						else
						{
							for (ext in FunkinIris.exts)
							{
								if (file.endsWith('.$ext'))
								{
									var sc = initFunkinIris(folder + file);
									if (sc != null)
									{
										filesPushed.push(file);
									}
									break;
								}
							}
						}
					}
				}
			}
		}
		
		var gfVersion:String = SONG.gfVersion;
		if (gfVersion == null || gfVersion.length < 1) SONG.gfVersion = gfVersion = 'gf';
		
		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter, gf);
			
			setOnScripts('gf', gf);
			setOnScripts('gfGroup', gfGroup);
		}
		
		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter, dad);
		dadMap.set(dad.curCharacter, dad);
		
		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter, boyfriend);
		boyfriendMap.set(boyfriend.curCharacter, boyfriend);
		
		setOnScripts('dad', dad);
		setOnScripts('dadGroup', dadGroup);
		
		setOnScripts('boyfriend', boyfriend);
		setOnScripts('boyfriendGroup', boyfriendGroup);
		
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}
		else
		{
			camPos.set(opponentCameraOffset[0], opponentCameraOffset[1]);
			camPos.x += dad.getGraphicMidpoint().x + dad.cameraPosition[0];
			camPos.y += dad.getGraphicMidpoint().y + dad.cameraPosition[1];
		}
		
		/* this is unneeded i think
			if (dad.curCharacter == gf.curCharacter && gf != null)
			{
				dad.setPosition(GF_X, GF_Y);
				if (gf != null) gf.visible = false;
			}
		 */
		
		flashSprite = new FlxSprite(0, 0).makeGraphic(1280, 720, 0xFFb30000);
		flashSprite.alpha = 0;
		flashSprite.cameras = [camOther];
		add(flashSprite);
		setOnScripts('flashSprite', flashSprite);
		
		Conductor.songPosition = -5000;
		
		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50);
		strumLine.visible = false;
		strumLine.scrollFactor.set();
		
		// temp
		updateTime = true;
		
		playFields