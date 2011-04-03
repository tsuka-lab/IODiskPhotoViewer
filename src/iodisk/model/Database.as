package iodisk.model
{
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.errors.SQLError;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	
	import iodisk.view.Log;

	public class Database extends EventDispatcher
	{
		public static var connection:SQLConnection;
		
		public function Database(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public static function initialize(file:File):void {
			if (!Database.connection) {
				Database.connection = new SQLConnection();
				Database.connection.open(file);
			}
		}
		
		public static function createTable(tableName:String, schema:Array):SQLResult {
			return Database.execute([
				"CREATE TABLE IF NOT EXISTS ",
				tableName,
				"(\n",
				schema.map(function(item:Array, index:int, array:Array):String {
					return item[0] + " " + item[1];
				}).join(",\n"),
				"\n)"
			].join(""));
		}
		
		public static function execute(query:String, params:*=null):SQLResult {
			if (!Database.connection.connected) {
				return null;
			}
			var statement:SQLStatement = new SQLStatement();
			statement.text = query;
			if (params) {
				if (params is Object) {
					for (var key:String in params) {
						statement.parameters[key] = params[key];
					}
				} else if (params is Array) {
					for (var i:int=0; i<params.length; i++) {
						statement.parameters[i] = params[i];
					}
				}
			}
			//trace(statement.text);
			try {
				statement.sqlConnection = Database.connection;
				statement.execute();
			} catch(error:SQLError) {
				Log.debug([
					"--- " + error.message,
					"operation: " + error.operation,
					error.details,
					"---",
					statement.text,
					"---"
				].join("\n"));
				throw error;
				return null;
			}
			return statement.getResult();
		}
	}
}