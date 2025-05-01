// Character scripts are basically the same as stage scripts so lol

function onStartCountdown()
{
    game.gf.playAnim('idle-right', false); // so i don't know why it doesn't work if i don't play an animation ill fix ts later
    game.gf.idleSuffix = '-right';
    game.gf.recalculateDanceIdle();
}

function onSectionHit(curSection)
{
    var direction:String = !mustHitSection ? '-left' : '-right'; // depending on who the section is focused on she'll look in their direction

    if (game.gf.idleSuffix != direction) // making sure shes not already looking in the direction we want
    {
        game.gf.playAnim('turn' + direction, true);
        game.gf.idleSuffix = direction;
        game.gf.recalculateDanceIdle();
        game.gf.danced = false; // fuck my gay life
    }
}