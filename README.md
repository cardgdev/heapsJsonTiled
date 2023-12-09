# About

This is a fork of https://github.com/deepnight/heapsTiled to use the JSON format of Tiled maps. Also fixes some bugs in the original repo. 

A new callback argument has been added to the TMap class to map tileset image sources to Tiles programmatically. This way, paths to images do not have to be baked into the map files and do not have to be ad-hoc loaded by the map. All of these changes also means that *entire maps can be defined in a single file* which can be easily be loaded between Tiles and heaps, simplifying the resource layout.

Very simple example:

```haxe

    public function tiledFile2Object(tmxRes:hxd.res.Resource): h2d.Object {
        var map = new tiled.TMap(tmxRes, (src) -> {
		
            if(src.contains("my_tileset.png")){
                return Res.my_tileset.toTile();
            }
			
	    return Res.fallbacktiles.toTile();
			
        });

        var wrapper = new h2d.Object();

	// Render map
	for(l in map.layers){
            map.renderLayerBitmap(l, wrapper);
        }
		
        return wrapper;
    }



```
