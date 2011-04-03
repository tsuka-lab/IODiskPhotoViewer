package iodisk.model
{
	import flash.display.*;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.system.System;
	
	import org.sappari.utils.BitmapDataUtil;

	public class ThumbLoader extends Loader
	{
		private var bmdArray:Array = [];
		
		public function ThumbLoader()
		{
			super();
			this.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
			this.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
		}
		
		private var imageUrls:Array = [];
		private var total:uint = 0;
		public function loadAll(urls:Array):void {
			imageUrls = urls;
			total = urls.length;
			_loadNext();
		}
		
		private function _loadNext():void {
			if (!imageUrls || imageUrls.length == 0) {
				trace("finish");
			}
			var url:String = imageUrls.shift();
			trace((total - imageUrls.length) + "/" +total);
			try {
				trace("loading: " + url);
				this.load(new URLRequest(url));
			} catch(err:Error) {
				trace("load error: " + url);
				_loadNext();
			}
		}
		
		private function onComplete(event:Event):void {
			trace("thumbnailing...");
			var bmd:BitmapData = BitmapDataUtil.resizeInsideIfLarge(
									Bitmap(content).bitmapData,
									100, 100, true);
			//bmdArray.push(bmd);
			this.unload();
			System.gc();
			//setTimeout(_loadNext, 2000);
			_loadNext();
		}
		
		private function onIoError(event:Event):void {
			_loadNext();
		}
	}
}