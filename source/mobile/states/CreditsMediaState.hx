package mobile.states;

import flixel.FlxG;
import flixel.FlxState;
import openfl.media.Video;
import openfl.net.NetConnection;
import openfl.net.NetStream;

class CreditsState extends FlxState
{
    var video:Video;
    var netStream:NetStream;

    override public function create()
    {
        super.create();

        var nc = new NetConnection();
        nc.connect(null);
        netStream = new NetStream(nc);

        video = new Video(1280, 720);
        video.attachNetStream(netStream);

        // Centraliza o vídeo na tela
        video.x = (FlxG.width - 1280) / 2;
        video.y = (FlxG.height - 720) / 2;
        addChild(video);

        // Coloque o vídeo em assets/videos/credits.mp4
        netStream.play("assets/videos/credits.mp4");

        // Quando terminar, pode ir para o TitleState ou outro
        netStream.onStatus = function(info) {
            if (info.code == "NetStream.Play.Stop") {
                FlxG.switchState(new TitleState());
            }
        };
    }

    override public function destroy()
    {
        super.destroy();
        netStream.close();
        removeChild(video);
    }
}