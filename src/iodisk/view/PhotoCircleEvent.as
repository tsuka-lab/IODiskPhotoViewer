package iodisk.view
{
	import flash.events.Event;

	public class PhotoCircleEvent extends Event
	{
		public static const NextAlbum:String = "nextAlbum";
		public static const PrevAlbum:String = "prevAlbum";
		private var _albumName:String = "";
		
		public function PhotoCircleEvent(type:String, album:String="", bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			_albumName = album;
		}
		
		public function get albumName():String {
			return _albumName;
		}
	}
}