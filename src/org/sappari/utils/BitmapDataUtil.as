package org.sappari.utils
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	
	public class BitmapDataUtil
	{
		public function BitmapDataUtil()
		{
		}
		
		public static function resizeInsideIfLarge(bmd:BitmapData, maxWidth:Number, maxHeight:Number, smoothing:Boolean=false):BitmapData {
			return (bmd.width < maxWidth && bmd.height < maxHeight)
						? bmd
						: BitmapDataUtil.resizeInside(bmd, maxWidth, maxHeight, smoothing);
		}

		public static function resizeInside(bmd:BitmapData, maxWidth:Number, maxHeight:Number, smoothing:Boolean=false):BitmapData {
			var newWidth:Number = 0;
			var newHeight:Number = 0;
			if (bmd.width/bmd.height >= maxWidth/maxHeight) {
				// horizontally long image
				newWidth = maxWidth;
				newHeight = bmd.height * maxWidth/bmd.width;
			} else {
				// vertically long image
				newHeight = maxHeight;
				newWidth = bmd.width * maxHeight/bmd.height;
			}
			return BitmapDataUtil.resizeBy(bmd, newWidth, newHeight, smoothing);
		}
		
		public static function resizeBy(bmd:BitmapData, width:Number, height:Number, smoothing:Boolean=false):BitmapData {
			var matrix:Matrix = new Matrix();
			matrix.scale(width/bmd.width, height/bmd.height);
			var newBmd:BitmapData = new BitmapData(width, height);
			newBmd.draw(bmd, matrix, null, null, null, smoothing);
			return newBmd;
		}
	}
}