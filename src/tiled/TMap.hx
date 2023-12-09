package tiled;

import haxe.DynamicAccess;
import haxe.Json;
import tiled.com.*;

@:allow(tiled.com.TObject)
@:allow(tiled.com.TLayer)
class TMap {
	public var wid : Int;
	public var hei : Int;
	public var tileWid : Int;
	public var tileHei : Int;

	public var tilesets : Array<TTileset> = [];
	public var layers : Array<TLayer> = [];
	public var objects : Map<String, Array<TObject>> = new Map();
	var props : Map<String,String> = new Map();

	public var bgColor : Null<UInt>;

	var source2TileResolver: (String) -> h2d.Tile;

	private function htmlHexToInt(s:String) : Null<UInt> {
		if( s.indexOf("#") == 0 )
			return Std.parseInt("0x" + s.substring(1));

		return null;
	}

	public function new(tmxRes:hxd.res.Resource, source2TileResolver: (String) -> h2d.Tile) {
		this.source2TileResolver = source2TileResolver;
		var folder = tmxRes.entry.directory;

		var json: haxe.DynamicAccess<Dynamic> = Json.parse(tmxRes.entry.getText());

		wid = json.get("width");
		hei = json.get("height");
		tileWid = json.get("tilewidth");
		tileHei = json.get("tileheight");
		bgColor = json.exists("backgroundcolor") ? htmlHexToInt(json.get("backgroundcolor")) : null;

		// Parse tilesets
		for(t in (cast json.get("tilesets"): Array<haxe.DynamicAccess<Dynamic>>)) {
			var set = readTileset(t);
			tilesets.push(set);
		}

		// Parse layers
		for(l in (cast json.get("layers"): Array<haxe.DynamicAccess<Dynamic>>)) {
			var layer = new TLayer( this, l.get("name"), l.get("id"), l.get("width"), l.get("height") );
			layers.push(layer);

			// Properties
			if( l.exists("properties") )
				for(eachProperty in (cast l.get("properties"): Array<haxe.DynamicAccess<Dynamic>>)){
					layer.setProp(eachProperty.get("name"), eachProperty.get("value"));
				}


			// Tile IDs
			if(l.exists("data")){
				var data = l.get("data");
				layer.setIds(data);
	
			}

			objects.set(l.get("name"), []);
			
		}

		// Parse layers
		for(l in (cast json.get("layers"): Array<haxe.DynamicAccess<Dynamic>>)) {
			if(l.exists("objects")){
				// Parse objects
				for(ol in (cast l.get("objects"): Array<haxe.DynamicAccess<Dynamic>>)) {
					var e = new TObject(this, ol.get("x"), ol.get("y"));
					if( ol.exists("width") ) e.wid = ol.get("width");
					if( ol.exists("height") ) e.hei = ol.get("height");
					if( ol.exists("name") ) e.name = ol.get("name");
					if( ol.exists("type") ) e.type = ol.get("type");
					if( ol.exists("gid") ) {
						e.tileId = ol.get("gid");
						e.y-=e.hei; // fix stupid bottom-left based coordinate
					}
					else if( ol.get("ellipse") ) {
						e.ellipse = true;
						if( e.wid==0 ) {
							// Fix 0-sized ellipses
							e.x-=tileWid>>1;
							e.y-=tileHei>>1;
							e.wid = tileWid;
							e.hei = tileHei;
						}
					}

					// Properties
					if( ol.exists("properties") ){
						for(p in (cast ol.get("properties"): Array<haxe.DynamicAccess<Dynamic>>)){
							e.setProp(p.get("name"), p.get("value"));
						}
							
					}
						
					objects.get(ol.get("name")).push(e);
				}
			}
		}


		// Parse map properties
		if (json.exists("properties")) {
			for (p in (cast json.get("properties"): Array<haxe.DynamicAccess<Dynamic>>)) {
				setProp(p.get("name"), p.get("value"));
			}
		}
	}

	public function getLayer(name:String) : Null<TLayer> {
		for (l in layers)
			if (l.name == name)
				return l;

		return null;
	}

	public function getObject(layer:String, name:String) : Null<TObject> {
		if( !objects.exists(layer) )
			return null;

		for(o in objects.get(layer))
			if( o.name==name )
				return o;

		return null;
	}


	public function getObjects(layer:String, ?type:String) : Array<TObject> {
		if( !objects.exists(layer) )
			return [];

		return type==null ? objects.get(layer) : objects.get(layer).filter( function(o) return o.type==type );
	}

	public function getPointObjects(layer:String, ?type:String) : Array<TObject> {
		if( !objects.exists(layer) )
			return [];

		return objects.get(layer).filter( function(o) return o.isPoint() && ( type==null || o.type==type ) );
	}

	public function getRectObjects(layer:String, ?type:String) : Array<TObject> {
		if( !objects.exists(layer) )
			return [];

		return objects.get(layer).filter( function(o) return o.isRect() && ( type==null || o.type==type ) );
	}


	public function renderLayerBitmap(l:TLayer, ?p) : h2d.Object {
		var wrapper = new h2d.Object(p);
		var cx = 0;
		var cy = 0;
		for(id in l.getIds()) {
			if( id!=0 ) {
				var b = new h2d.Bitmap(getTile(id), wrapper);
				b.setPosition(cx*tileWid, cy*tileHei);
				if( l.isXFlipped(cx,cy) ) {
					b.scaleX = -1;
					b.x+=tileWid;
				}
				if( l.isYFlipped(cx,cy) ) {
					b.scaleY = -1;
					b.y+=tileHei;
				}
			}

			cx++;
			if( cx>=wid ) {
				cx = 0;
				cy++;
			}
		}
		return wrapper;
	}


	public function getTiles(l:TLayer) : Array<{ t:h2d.Tile, x:Int, y:Int }> {
		var out = [];
		var cx = 0;
		var cy = 0;
		for(id in l.getIds()) {
			if( id!=0 )
				out.push({
					t : getTile(id),
					x : cx*tileWid,
					y : cy*tileHei,
				});

			cx++;
			if( cx>=wid ) {
				cx = 0;
				cy++;
			}
		}
		return out;
	}

	function getTileSet(tileId:Int) : Null<TTileset> {
		for(set in tilesets)
			if( tileId>=set.baseId && tileId<=set.lastId )
				return set;
		return null;
	}

	public inline function getTile(tileId:Int) : Null<h2d.Tile> {
		var s = getTileSet(tileId);
		return s!=null ? s.getTile(tileId) : null;
	}

	function readTileset(tilesetObj:DynamicAccess<Dynamic>) : TTileset {
		var tile = source2TileResolver(tilesetObj.get("image"));

		var e = new TTileset(tilesetObj.get("name"), tile, tilesetObj.get("tilewidth"), tilesetObj.get("tileheight"), tilesetObj.get("firstgid"), tilesetObj.get("margin"), tilesetObj.get("spacing"));
		return e;
	}

	private function removeLeadingSlash(path: String): String {
		if(path.indexOf("/") == 0){
	    	return path.substring(1, path.length);
		}
		return path;
	}

	public function setProp(name, v) {
		props.set(name, v);
	}

	public inline function hasProp(name) {
		return props.exists(name);
	}

	public function getPropStr(name) : Null<String> {
		return props.get(name);
	}

	public function getPropInt(name) : Int {
		var v = getPropStr(name);
		return v==null ? 0 : Std.parseInt(v);
	}

	public function getPropFloat(name) : Float {
		var v = getPropStr(name);
		return v==null ? 0 : Std.parseFloat(v);
	}

	public function getPropBool(name) : Bool {
		var v = getPropStr(name);
		return v=="true";
	}
}
