function onLoad() {
    // PlayState.instance.defaultCamZoom = 0.2;

    var bg:FlxSprite = new FlxSprite(-600, -200);
    bg.loadGraphic(Paths.image("stageback"));
	add(bg); 

    var stageFront:FlxSprite = new FlxSprite(-600, 600);
    stageFront.loadGraphic(Paths.image("stagefront"));
    add(stageFront);

    var stageCurtains:FlxSprite = new FlxSprite(-600, -300);
    stageCurtains.loadGraphic(Paths.image("stagecurtains"));
    add(stageCurtains);

    trace("DICK");
}