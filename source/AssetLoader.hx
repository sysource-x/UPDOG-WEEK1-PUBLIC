package source;

/* This file are just a test */

import openfl.utils.Assets;
import haxe.ds.StringMap;

class AssetLoader {
    public static var loadedAssets:StringMap<Dynamic> = new StringMap();

    public static function loadAllAssetsFrom(path:String):Void {
        #if mobile
        var list = Assets.list();
        for (file in list) {
            if (file.startsWith(path)) {
                trace('Loading: ' + file);
                if (file.endsWith(".png") || file.endsWith(".jpg")) {
                    loadedAssets.set(file, Assets.getBitmapData(file));
                } else if (file.endsWith(".ogg") || file.endsWith(".mp3")) {
                    loadedAssets.set(file, Assets.getSound(file));
                } else if (file.endsWith(".json") || file.endsWith(".txt") || file.endsWith(".hx")) {
                    loadedAssets.set(file, Assets.getText(file));
                } else {
                    // Outros tipos
                    loadedAssets.set(file, Assets.getBytes(file));
                }
            }
        }
        #end
    }

    public static function getAsset(path:String):Dynamic {
        return loadedAssets.get(path);
    }
}