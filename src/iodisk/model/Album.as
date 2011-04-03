package iodisk.model
{
	import flash.filesystem.File;
	
	import iodisk.view.Photo;
	
	public class Album extends Array
	{
		private var directory:File;
		private var imageFiles:Array;
		private var _firstPhotoIndex:int;
		private var _albumIndex:int;
		
		public function Album(dir:File, albumIndex:int, firstIndex:int, numElements:int=0)
		{
			super(numElements);
			
			_firstPhotoIndex = firstIndex;
			_albumIndex = albumIndex;
			if (!dir.isDirectory) {
				throw new Error(dir.nativePath + " is not directory.");
			}
			directory = dir;
			for each (var f:File in directory.getDirectoryListing()) {
				if (!f.isDirectory
					&& f.extension
					&& f.extension.match(/^(jpg|jpeg|png)$/i)) {
					this.push(new Photo(f, this));
				}
			}
		}
		
		public function get firstPhotoIndex():int {
			return _firstPhotoIndex;
		}
		
		public function get index():int {
			return _albumIndex;
		}
		
		public function get name():String {
			return directory.name;
		}
	}
}