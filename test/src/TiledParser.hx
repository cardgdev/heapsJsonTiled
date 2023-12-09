import hxd.Res;
import h2d.Scene;

class TiledParser {

    public var map: tiled.TMap;
    public var wrapper: h2d.Object;

    public function new() {

    }

    public function loadFile(tmxRes:hxd.res.Resource): h2d.Object {
        var map = new tiled.TMap(tmxRes, (src) -> {
            return Res.testtiles.toTile();
        });

        wrapper = new h2d.Object();

		// Render map
		for(l in map.layers){
            switch(getLayerTypeForName(l.name)){
                case BACKGROUND: {
                    map.renderLayerBitmap(l, this.wrapper);
                }
                case INVALID: {
                    
                }
            }
        }
		
        return wrapper;
    }


    function getLayerTypeForName(name:String):TiledLayerType {
        switch (name) {
            case "Background": {
                return BACKGROUND;
            }
            default: return INVALID;
        }
    }
}

enum TiledLayerType {
    BACKGROUND;
    INVALID;
}