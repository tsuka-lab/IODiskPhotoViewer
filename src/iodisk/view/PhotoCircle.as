package iodisk.view
{
	import caurina.transitions.Tweener;
	
	import flash.display.LineScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.ui.Keyboard;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import iodisk.model.*;
	
	import mx.core.UIComponent;
	import mx.events.ResizeEvent;

	public class PhotoCircle extends UIComponent
	{
		private var albums:Array = [];
		private var photos:Array = [];
		private var currentIndex:int = 0;
		private var currentAlbumIndex:int = 0;
		private var _radius:Number = 0;
		private var perAngleRadian:Number = 0;
		private var _zoom:Number = 1;
		private var maxSpeed:int = 20;
		private var _speed:int = 0;
		public var jumping:Boolean = false;
		
		public function PhotoCircle()
		{
			super();
			width = 200;
			height = 200;
			addEventListener(Event.ADDED_TO_STAGE, function():void {
				stage.addEventListener(ResizeEvent.RESIZE, function():void {
					onResize();
				});
				stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				stage.addEventListener(MouseEvent.MOUSE_DOWN, function():void {
					//zoom = _zoom + 0.05;
				});
				stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, function():void {
					//zoom = _zoom - 0.05;
				});
			});
		}
		
		private function onKeyDown(keyEvent:KeyboardEvent):void {
			switch (keyEvent.keyCode) {
				/*
				case Keyboard.N:
					rotateToNextAlbum();
					break;
				case Keyboard.P:
					rotateToPrevAlbum();
					break;
					*/
				case Keyboard.J:
					rotateToNext();
					break;
				case Keyboard.K:
					rotateToPrev();
					break;
				case Keyboard.UP:
					zoom = _zoom + 0.05;
					break;
				case Keyboard.DOWN:
					zoom = _zoom - 0.05;
					break;
				case Keyboard.RIGHT:
					speed = speed + 1;
					break;
				case Keyboard.LEFT:
					speed = speed - 1;
					break;
			}
		}
		
		public function onMouseWheel(mouseEvent:MouseEvent):void {
			if (mouseEvent.delta > 0) {
				rotateToPrev();
			} else {
				rotateToNext();
			}
		}
		
		public function get radius():Number {
			return _radius;
		}
		
		//
		// Album
		//
		public function rotateToNextAlbum():void {
			currentAlbumIndex += 1;
			if (currentAlbumIndex > albums.length - 1) {
				currentAlbumIndex = 0;
			}
			rotateToCurrentAlbumIndex();
		}
		
		public function rotateToPrevAlbum():void {
			if (currentIndex - Album(albums[currentAlbumIndex]).firstPhotoIndex <= 3) {
				currentAlbumIndex -= 1;
			}
			if (currentAlbumIndex < 0) {
				currentAlbumIndex = albums.length - 1;
			}
			rotateToCurrentAlbumIndex();
		}
		
		public function rotateToCurrentAlbumIndex():void {
			if (jumping) return;
			clearTimeout(animateTimeoutId);
			var beforeSpeed:int = speed;
			speed = 0;
			jumping = true;
			
			var fromPhoto:Photo = Photo(photos[currentIndex]);
			var destAlbum:Album = Album(albums[currentAlbumIndex]);
			
			var jump:int = 0;
			var isNext:Boolean = true;
			if (destAlbum.index == 0
				&& fromPhoto.album.index == albums.length-1) {
				// last album -> first album
				jump = photos.length - currentIndex;
				isNext = true;
			} else if (destAlbum.index == albums.length-1
						&& fromPhoto.album.index == 0) {
				// first album -> last album
				jump = currentIndex + destAlbum.length;
				isNext = false;
			} else {
				jump = Math.abs(destAlbum.firstPhotoIndex - currentIndex);
				isNext = (destAlbum.index - fromPhoto.album.index > 0);
			}
			
			Log.debug("jump: "+jump.toString());
			currentIndex = destAlbum.firstPhotoIndex;
			
			if (jump < 6) {
				rotateToCurrentIndex();
				jumping = false;
				dispatchEvent(new PhotoCircleEvent(
							isNext
								? PhotoCircleEvent.NextAlbum
								: PhotoCircleEvent.PrevAlbum,
							Album(albums[currentAlbumIndex]).name));
				zoom = 1;
				setTimeout(function():void {
					speed = 1;
				}, 2000);
			} else {
				var z:Number = (_zoom > 0.15) ? 0.15 : _zoom;
				var destRot:Number = getRotationOfCurrentIndex();
				var fromRot:Number = rotation;
				Log.debug(fromRot + " -> " + destRot);
				Tweener.removeTweens(this, "rotation", "y", "scale");
				var self:PhotoCircle = this;
				var rot1:Number = fromRot + (destRot - fromRot)/4;
				var rot2:Number = fromRot + 3*(destRot - fromRot)/4;
				
				zoomTo(z, {
					rotation: rot1,
					time: 1.2,
					transition: "easeInSine",
					onComplete: function():void {
						rot2 = correctDestRot(rotation, rot2);
						Log.debug("r1: "+rotation +" -> " + rot2);
						Tweener.addTween(self, {
							rotation: rot2,
							time: 0.9,
							transition: "linear",
							onComplete: function():void {
								destRot = correctDestRot(rotation, destRot);
								Log.debug("r2: "+rotation+" -> "+destRot);
								zoomTo(1/*_zoom*/, {
									rotation: destRot,
									time: 1.2,
									transition: "easeOutSine",
									onComplete: function():void {
										jumping = false;
										dispatchEvent(new PhotoCircleEvent(
											isNext
												? PhotoCircleEvent.NextAlbum
												: PhotoCircleEvent.PrevAlbum,
											Album(albums[currentAlbumIndex]).name));
										setTimeout(function():void {
											speed = 1;
										}, 2000);
									}
								});
							}
						});
					}
				});
			}
		}
		
		private function updateAlbumIndexByPhotoIndex():void {
			var newIndex:int = Photo(photos[currentIndex]).album.index;
			if (newIndex == currentAlbumIndex) return;
			
			var isNext:Boolean = true;
			if (currentAlbumIndex == albums.length-1
				&& newIndex == 0) {
				isNext = true;
			} else if (currentAlbumIndex == 0
						&& newIndex == albums.length-1) {
				isNext = false;
			} else if (newIndex - currentAlbumIndex > 0) {
				isNext = true;
			} else {
				isNext = false;
			}
			currentAlbumIndex = newIndex;
			
			dispatchEvent(new PhotoCircleEvent(
							isNext
								? PhotoCircleEvent.NextAlbum
								: PhotoCircleEvent.PrevAlbum,
							Album(albums[currentAlbumIndex]).name));
		}
		
		//
		// speed
		//
		public function get speed():int {
			return _speed;
		}
		
		public function set speed(value:int):void {
			if (jumping) return;
			if (value == speed) return;
			var pausing:Boolean = (speed == 0);
			_speed = value;
			Log.debug("speed: " + speed);
			if (pausing) animate();
		}
		
		/**
		 * speed=0   -> 1
		 * speed=max -> 0
		 */
		private function get speedRate():Number {
			var s:int = Math.abs(speed);
			if (s > maxSpeed) s = maxSpeed;
			return (maxSpeed - s) / maxSpeed;
		}
		
		private function animate():void {
			clearTimeout(animateTimeoutId);
			if (speed == 0) {
				zoom = 1;
				return;
			}
			if (speed > 0) {
				rotateToNext();
			} else {
				rotateToPrev();
			}
		}
		
		private var animateTimeoutId:int;
		private function waitAndAnimate():void {
			clearTimeout(animateTimeoutId);
			if (speed == 1 || speed == -1) {
				animateTimeoutId = setTimeout(animate, 2000);
			} else if (speed > 1 || speed < -1) {
				animate();
			}
			// speed == 0 -> stop
		}
		
		//
		// rotation
		//
		public function rotateToNext():void {
			if (jumping) return;
			//Log.debug("rotateToNext");
			currentIndex += 1;
			if (currentIndex > photos.length - 1) {
				currentIndex = 0;
			}
			rotateToCurrentIndex();
		}
		
		public function rotateToPrev():void {
			if (jumping) return;
			//Log.debug("rotateToPrev");
			currentIndex -= 1;
			if (currentIndex < 0) {
				currentIndex = photos.length - 1;
			}
			rotateToCurrentIndex();
		}

		public function rotateToCurrentIndex():void {
			clearTimeout(animateTimeoutId);
			updateAlbumIndexByPhotoIndex();
			
			Tweener.removeTweens(this, "rotation");
			Tweener.addTween(this, {
				rotation: getRotationOfCurrentIndex(),
				time: 0.6 * speedRate + 0.05,
				transition: (-1 == speed || speed == 1) ? "easeOutCubic" : "linear",
				onComplete: waitAndAnimate
			});
		}
		
		private function getRotationOfCurrentIndex():Number {
			var newRot:Number = convRadianToDegree(perAngleRadian * currentIndex);
			return correctDestRot(rotation, newRot);
		}
		
		private function correctDestRot(from:Number, dest:Number):Number {
			if (dest - from > 180) {
				dest -= 360;
			} else if (dest - from < -180) {
				dest += 360;
			}
			return dest;
		}
		
		private function convRadianToDegree(rad:Number):Number {
			return rad * 180 / Math.PI;
		}
		
		//
		// Load Images
		//
		public function load(dir:File):void {
			if (!dir.isDirectory) return;
			for each (var d:File in dir.getDirectoryListing()) {
				if (!d.isDirectory) continue;
				var album:Album = new Album(d, albums.length, photos.length);
				if (album.length == 0) continue;
				Log.debug("add album: " + album.name);
				albums.push(album);
				for each (var p:Photo in album) {
					photos.push(p);
					addChild(p);
				}
			}
			if (photos.length == 0) {
				Log.debug("no photos");
				return;
			}
			alignPhotos();
			
			// load thumbnails
			try {
				Database.initialize( dir.resolvePath("iodisk-thumbs.db") );
				ThumbTable.createTable();
			} catch(error:Error) {
				Log.debug("can not create a thumbnail database");
				return;
			}
			loadAllThumbnails();
			
			dispatchEvent(new PhotoCircleEvent(
							PhotoCircleEvent.NextAlbum,
							Album(albums[currentAlbumIndex]).name));
			
			//rotateTween();
		}
		
		/*
		private function rotateTween():void {
			Log.debug(rotation.toString());
			Tweener.addTween(this, {
				rotation: correctDestRot(rotation, rotation+90),
				time: 30,
				transition: "linear",
				onComplete: rotateTween
			});
		}
		*/
		
		private function alignPhotos():void {
			var margin:Number = Photo.thumbMaxWidth / 10;
			var circumference:Number = photos.length * (Photo.thumbMaxWidth + margin);
			_radius = circumference / (2 * Math.PI);
			perAngleRadian = 2 * Math.PI / photos.length;
			Log.debug("radius: "+radius);
			for (var i:int=0; i<photos.length; i++) {
				var photo:Photo = Photo(photos[i]);
				var angle:Number = -i * perAngleRadian;
				photo.x = radius * Math.cos(angle + Math.PI/2);
				photo.y = radius * Math.sin(angle + Math.PI/2);
				photo.rotation = angle * 180 / Math.PI;
			}
			zoom = 1;
			drawAlbumLine();
		}
		
		private function drawAlbumLine():void {
			var r:Number = radius + Photo.thumbMaxHeight;
			this.graphics.lineStyle(2, 0xFFFFFF, 1,
							false, LineScaleMode.NONE);
			for each (var album:Album in albums) {
				var angleRad:Number = -album.firstPhotoIndex * perAngleRadian + perAngleRadian/2;
				with (this.graphics) {
					moveTo(0, 0);
					lineTo(
						r * Math.cos(angleRad + Math.PI/2),
						r * Math.sin(angleRad + Math.PI/2)
					);
				}
			}
		}
		
		//
		// scale
		//
		public function set zoom(value:Number):void {
			if (jumping) return;
			if (value > 1) {
				value = 1;
			} else if (value < 0.001) {
				value = 0.001;
			}
			_zoom = value;
			Log.debug("zoom: " + value);
			zoomTo(_zoom);
		}
		
		private function zoomTo(z:Number, otherOption:Object = null):void {
			var unitScale:Number = stage.nativeWindow.height / Photo.thumbMaxHeight;
			var scale:Number = z * unitScale;
			var newY:Number = stage.nativeWindow.height/2 - radius * scale;
			if (newY > 0) newY = 0;
			
			var option:Object = {
				scaleX: scale,
				scaleY: scale,
				y: newY,
				time: 1,
				transition: "easeOutCubic"
			}
			if (otherOption) {
				for (var key:String in otherOption) {
					option[key] = otherOption[key];
				}
			}
			if (Tweener.isTweening(this)) {
				Tweener.removeTweens(this, "scaleX", "scaleY", "y");
				if (otherOption && otherOption["rotation"]) {
					Tweener.removeTweens(this, "rotation");
				}
			}
			Tweener.addTween(this, option);
		}
		
		private function onResize(event:ResizeEvent = null):void {
			this.x = this.stage.nativeWindow.width / 2;
			zoomTo(_zoom);
		}
		
		//
		// Thumbnail
		//
		private function loadAllThumbnails():void {
			var thumbPhotos:Array = [];
			for each (var p:Photo in photos) {
				thumbPhotos.push(p);
			}
			_loadAllThumbnails(thumbPhotos);
		}
		
		private function _loadAllThumbnails(thumbPhotos:Array):void {
			if (!thumbPhotos || thumbPhotos.length == 0) {
				trace("finish");
				dispatchEvent(new Event("allThumbComplete"));
				return;
			}
			var p:Photo = thumbPhotos.shift();
			Log.debug(
					(photos.length - thumbPhotos.length)
					+ "/"
					+ photos.length);
			p.addEventListener("thumbComplete", function():void {
				trace("complete");
				//System.gc();
				setTimeout(function():void {
					trace("next");
					_loadAllThumbnails(thumbPhotos);
				}, 10);
			});
			p.addEventListener("thumbError", function():void {
				_loadAllThumbnails(thumbPhotos);
			});
			p.addEventListener("thumbTimeout", function():void {
				_loadAllThumbnails(thumbPhotos);
			});
			p.loadThumbnail();
		}
	}
}