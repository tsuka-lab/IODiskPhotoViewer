package iodisk.model
{
	import flash.data.SQLResult;
	import flash.display.*;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.CompressionAlgorithm;
	
	import iodisk.view.Log;
	
	public class ThumbTable
	{
		public static const name:String = "thumbs";
		public static const schema:Array = [
			["id",     "INTEGER PRIMARY KEY AUTOINCREMENT"],
			["path",   "TEXT NOT NULL"],
			["thumb",  "TEXT NOT NULL"],
			["width",  "INTEGER NOT NULL"],
			["height", "INTEGER NOT NULL"]
		];
		
		public function ThumbTable()
		{
			
		}
		
		public static function createTable():SQLResult {
			return Database.createTable(ThumbTable.name, ThumbTable.schema);
		}
		
		public static function find_by_path(path:String):BitmapData {
			var result:SQLResult = Database.execute([
				"SELECT *",
				"FROM", ThumbTable.name,
				"WHERE path = :path"
			].join(" "), {
				":path": path
			});
			/*
			want to do that:
			Database.select(tableName, {
				column: "*",
				columns: [],
				where: ["path = :path AND width = :width", {}],
				order: "",
				limit: 3
			});
			*/
			
			
			if (!result
				|| !result.data
				|| result.data.length == 0) {
				return null;
			}
			// convert thumb to BitmapData
			var record:Object = result.data[0];
			var byteArray:ByteArray = ByteArray(record.thumb);
			byteArray.uncompress();
			var bmd:BitmapData = new BitmapData(record.width, record.height);
			bmd.setPixels(
				new Rectangle(0, 0, bmd.width, bmd.height),
				byteArray);
			return bmd;
		}
		
		public static function insertThumb(path:String, bmd:BitmapData):SQLResult {
			//var byteArray:ByteArray = (new JPEGEncoder(95)).encode(bmd);
			var byteArray:ByteArray = bmd.getPixels( new Rectangle(0, 0, bmd.width, bmd.height) );
			byteArray.compress();
			return Database.execute([
				"INSERT INTO",
				ThumbTable.name,
				"(path, thumb, width, height)",
				"VALUES (:path, :thumb, :width, :height)"
			].join(" "), {
				":path":   path,
				":thumb":  byteArray,
				":width":  bmd.width,
				":height": bmd.height
			});
		}
	}
}