package Zom.Modules{

	import Zom.Plugin.Base;
	import Zom.Moz;
	import Zom.Modules.*;
	import Zom.Main.Shared;

	import flash.display.Stage;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import com.greensock.loading.display.*;

	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.display.LoaderInfo;

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.events.MouseEvent;
	import com.brightcove.api.events.MediaEvent;
	import com.brightcove.api.events.AdEvent;

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;

	import flash.system.SecurityDomain;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;

	import flash.utils.Timer;

	public class Pause extends ModuleBase{

		protected var _image:ContentDisplay;
		protected var _delayTimer:Timer = new Timer(500,1);
		protected var _adShown:Boolean = false;
		protected var _origLoaderWidth:int = 0;
		protected var _origLoaderHeight:int = 0;

		public function Pause($name:String='Pause',$parentModule:Base=null){
			super($name,$parentModule);
			this._params = {
					url:null //url of the image asset
				,	track_url:'' //url to load on view
				,	click_url:null //url to open in a new window on click
				,	x:'right' //placement on the x axis
				,	y:'top' //placement on the y axis
			}
			this._canvasSprite = new Sprite();
			this._maskSprite = new Sprite();
			this.addChild(this._canvasSprite);
			this.addChild(this._maskSprite);
			_delayTimer.addEventListener(TimerEvent.TIMER_COMPLETE,_delayTimerTime);
			this.addToParent();
		}

		/**
		 * At that point:
		 *  - Brightcove player should have loaded and brightcove modules have been set
		 *  - Moz modules have loaded
		 *  - Assets needed by every Moz module have loaded and are ready
		 *  - the module has been placed on stage
		 *  this also sets and places the logo, the background, and the texts
		 */
		override protected function ready():void{
			var $image:ContentDisplay = this.getLoaderContent('pause');
			if($image){
				this._image = $image;
				_origLoaderWidth = _image.width;
				_origLoaderHeight = _image.height;
				this.canvasSprite.addChild(this._image);
				hide(0);
			}
			super.ready();
		}

		/**
		 * places the object in it's container.
		 */
		override public function place():void{
			if(_image){
				var $stageWidth:Number = isFullScreen ? stage.stageWidth : videoModule.getDisplayWidth();
				var $stageHeight:Number = isFullScreen ? stage.stageHeight : videoModule.getDisplayHeight();
				var $maxHeight:Number = $stageHeight - 70;
				var $maxWidth:Number = _origLoaderWidth;
				_image.height = $maxHeight;
				_image.width = _origLoaderWidth * ($maxHeight / _origLoaderHeight);
				_image.x = videoModule.getX() + $stageWidth - _image.width;
				/**
				if(this._params.x && this._params.y){
					Shared.place(_params,this,this.parent);
				}
				this.placeChildren();
				for(var n:String in this._modules){
					this._modules[n].place();
				}
				**/
			}
		}

		/**
		 * Requests the pause overlay to be shown. Will start a 500ms timer that when ends, shows the ad
		 * the reason for the delay is to be sure there isn't an ad or buffer happening, as the events
		 * might be launched after pause
		 */
		protected function showPauseOverlay():void{
			if(!this._adShown){
				_delayTimer.reset();
				_delayTimer.start();
        	}
		}

		/**
		 * hides the overlay, and stops the delay timer
		 */
		protected function hidePauseOverlay():void{
			this._adShown = false;
			_delayTimer.reset();
			_delayTimer.stop();
			hide();
		}

		/**
		 * Called when the delay timer ends
		 * @param  evt the timer ends event
		 */
		protected function _delayTimerTime(evt:TimerEvent):void{
			if(!adPlaying && !isSeeking && !isBuffering){
				this._adShown = true;
				show();
				track();
				_delayTimer.stop();
			}else{
				_delayTimer.reset();
				_delayTimer.start();
			}
		}

		/**
		 * Called when media begins playing.
		 * requests a hiding of the pause overlay
		 * @param  evt the event
		 * @return
		 */
		override protected function onMediaBegin(evt:MediaEvent):void{
			super.onMediaBegin(evt);
			hidePauseOverlay();
		}

		/**
		 * Called when media begins playing
		 * requests a hiding of the pause overlay
		 * @param  e the event
		 */
		override protected function onMediaPlay(evt:MediaEvent):void{
			super.onMediaPlay(evt);
			hidePauseOverlay();
		}

		/**
		 * Called when media stops playing
		 * requests a showing of the pause overlay
		 * @param  e the event
		 */
		override protected function onMediaStop(evt:MediaEvent):void{
			super.onMediaStop(evt);
			showPauseOverlay();
		}


	}

}