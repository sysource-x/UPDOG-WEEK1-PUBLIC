package content.scripts;

import flixel.FlxSprite;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup.FlxTypedGroup;

using StringTools;

// scripted and hardcoded to one skin. //doing this rq cuz its fast easy and i dont like the noteanimation system - data5
//missing shader functionality do later

var covers = new FlxTypedGroup();
var cachedFrames = Paths.getSparrowAtlas('noteskins/noteHoldCovers');
var colours = ['purple', 'blue', 'green', 'red'];
var oppCovers = [null, null, null, null];
var playerCovers = [null, null, null, null];

function onCreatePost()
{
	add(covers);
	covers.cameras = [camHUD];

	for (i in script_COVERSTARTOffsets)
	{
		i.x = 12;
		i.y = -17;
	}
}

function setupCover(cover)
{
	cover.antialiasing = ClientPrefs.globalAntialiasing;
	cover.frames = cachedFrames;
	cover.scrollFactor.set();
	for (i in colours)
	{
		var start = i + 'start';
		var loop = i + 'loop';
		var end = i + 'end';

		cover.animation.addByPrefix(start, start, 24, false);
		cover.animation.addByPrefix(loop, loop, 24, true);
		cover.animation.addByPrefix(end, end, 24, false);

		cover.animation.onFinish.add((anim) ->
		{
			if (anim == start)
			{
				cover.animation.play(loop);
			}
			if (anim == end)
			{
				cover.kill();
			}
		});

		cover.animation.onFrameChange.add((anim, frame, idx) ->
		{
			cover.offset.set();

			if (anim.indexOf('end') != -1)
			{
				cover.offset.set(26, 8);
			}
			else if (anim.indexOf('loop') != -1)
			{
			}
			else if (anim.indexOf('start') != -1)
			{
				cover.offset.set(-10, -10);
			}
		});
	}

	return cover;
}

function opponentNoteHit(note)
{
	if (curSong != 'Bananas' && ClientPrefs.noteCovers) handleNoteCover(note, oppCovers, true);
}

function goodNoteHit(note)
{
	if (curSong != 'Bananas' && ClientPrefs.noteCovers) handleNoteCover(note, playerCovers, !ClientPrefs.noteSplashes);
}

function handleNoteCover(note, coverArray, remove)
{
	var data = note.noteData;
	
	if (note.tail.length > 0 && coverArray[data] == null)
	{
		var cover = covers.recycle(FlxSprite);
		coverArray[data] = cover;
		covers.add(cover);
		
		if (cover.animation.getAnimationList().length == 0)
		{
			setupCover(cover);
		}
		else
		{
			cover.animation.stop();
		}

		run(cover, note);
	}
	else if (note.animation.curAnim.name.endsWith('end') && coverArray[data] != null)
	{
		var delay = .25 / game.songSpeed / note.multSpeed; // artificial ass delay so the cover doesnt cut off before the tail
		var cover = coverArray[data];
		
		new FlxTimer().start(delay, (f) -> {
			finishAnim(cover, data, remove);
		});
		
		coverArray[data] = null; // set it free
	}
}

function forceKillNoteCover(data, coverArray)
{ // haha
	if (coverArray[data] != null)
	{
		coverArray[data].kill();
		coverArray[data] = null;
	}
}

function run(cover, note)
{
	covers.cameras = playFields.cameras;
	cover.scrollFactor.set();
	
	var strum = note.playField.members[note.noteData];
	
	cover.animation.play(colours[note.noteData] + 'start');
	cover.scale.set(strum.scale.x, strum.scale.y);
	
	cover.x = strum.x + script_COVERSTARTOffsets[note.noteData].x + (strum.width - cover.width) * .5;
	cover.y = strum.y + script_COVERSTARTOffsets[note.noteData].y + (strum.height - cover.height) * .5;
}

function onKeyRelease(data)
{
	forceKillNoteCover(data, playerCovers);
}

function onNoteMiss(note)
{
	forceKillNoteCover(note.noteData, playerCovers);
}

function finishAnim(cover, data, remove)
{
	if (remove)
		cover.kill();
	else
		cover.animation.play(colours[data] + 'end');
}
