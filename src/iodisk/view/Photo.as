package iodisk.view
{
	import flash.display.*;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.system.System;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import iodisk.model.Album;
	import iodisk.model.ThumbTable;
	
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	
	import org.sappari.utils.BitmapDataUtil;

	public class Photo extends Canvas
	{
		private var _file:File;
		public static var thumbMaxWidth:uint = 600;
		public static var thumbMaxHeight:uint = 600;
		private var loadingTimeoutId:int;
		private var loading:Boolean = false;
		private var thumbBitmap:Bitmap;
		private var _album:Album;
		
		public function Photo(f:File, a:Album)
		{
			super();
			_file = f;
			_album = a;
			
			thumbBitmap = new Bitmap(null, PixelSnapping.NEVER, false);
			var thumbContainer:UIComponent = new UIComponent();
			thumbContainer.addChild(thumbBitmap);
			this.addChild(thumbContainer);
		}
		
		public function get file():File {
			return _file;
		}
		
		public function get album():Album {
			return _album;
		}
		
		private function setBitmapData(bmd:BitmapData):void {
			//this.thumbImage.source = (new JPEGEncoder(100)).encode(bmd);
			thumbBitmap.bitmapData = bmd;
			thumbBitmap.x = -bmd.width/2;
			thumbBitmap.y = -bmd.height/2;
		}
		
		public function loadThumbnail():void {
			//Log.debug("check cache");
			var cachedBmd:BitmapData = ThumbTable.find_by_path(file.nativePath);
			if (cachedBmd) {
				Log.debug("cache hit");
				setBitmapData(cachedBmd);
				//System.gc();
				dispatchEvent(new Event("thumbComplete"));
				return;
			}
			
			Log.debug("no cache");
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function():void {
				clearTimeout(loadingTimeoutId);
				loading = false;
				Log.debug("resizing...");
				var bmd:BitmapData = BitmapDataUtil.resizeInsideIfLarge(
											Bitmap(loader.content).bitmapData,
											Photo.thumbMaxWidth,
											Photo.thumbMaxHeight,
											true);
				setBitmapData(bmd);
				ThumbTable.insertThumb(file.nativePath, bmd);
				loader.unload();
				System.gc();
				dispatchEvent(new Event("thumbComplete"));
			}, false, 0, true);
			
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function():void {
				clearTimeout(loadingTimeoutId);
				loading = false;
				Log.debug("io error: " + file.nativePath);
				dispatchEvent(new Event("thumbError"));
			}, false, 0, true);
			
			try {
				Log.debug("loading: "+file.nativePath);
				loader.load(new URLRequest(file.url));
				loading = true;
				loadingTimeoutId = setTimeout(function():void {
					if (loading) {
						Log.debug("loading timeout!");
						dispatchEvent(new Event("thumbTimeout"));
					}
				}, 10000);
			} catch(err:Error) {
				loading = false;
				Log.debug(err.message);
				dispatchEvent(new Event("thumbError"));
			}
		}
	}
}