import tiled.TMap;
import tiled.com.*;

class Test extends hxd.App {
	// Boot
	static function main() {
		new Test();
	}

	// Engine ready
	override function init() {
		hxd.Res.initEmbed();
		var wrapper = new h2d.Object(s2d);
		wrapper.setScale(2);

		var mapObj = new TiledParser().loadFile(hxd.Res.poc_map);
		s2d.addChild(mapObj);
		
	}

}

