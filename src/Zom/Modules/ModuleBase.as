package Zom.Modules{

	import Zom.Plugin.Base;
	import Zom.Moz;
	import Zom.Modules.*;
	import Zom.Events.ZomEvent;
	import Zom.Main.Shared;

	import flash.display.Stage;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Graphics;

	import flash.geom.Rectangle;

	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.net.URLLoader;
	import flash.display.LoaderInfo;

	import com.greensock.*;
	import com.greensock.loading.*;
	import com.greensock.events.LoaderEvent;

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent
	import flash.events.SecurityErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.FullScreenEvent;
	import flash.events.TimerEvent;
	import flash.events.MouseEvent;
	import com.brightcove.api.events.MediaEvent;
	import com.brightcove.api.events.AdEvent;

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;

	import flash.external.ExternalInterface;

	import flash.system.SecurityDomain;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;

	import flash.utils.Timer;

	public class ModuleBase extends Base{

		protected var _base:Base;

		public function ModuleBase($name:String='',$parentModule:Base=null){
			this.mouseChildren = true;
			this._base = $parentModule;
			this._base.addEventListener(MediaEvent.PLAY,onMediaPlay);
			this._base.addEventListener(MediaEvent.BEGIN,onMediaBegin);
			this._base.addEventListener(MediaEvent.STOP,onMediaStop);
			this._base.addEventListener(MediaEvent.BUFFER_BEGIN,onBufferBegin);
			this._base.addEventListener(MediaEvent.BUFFER_COMPLETE,onBufferComplete);
			this._base.addEventListener(MediaEvent.SEEK,onSeekBegin);
			this._base.addEventListener(MediaEvent.SEEK_NOTIFY,onSeekComplete);
			this._base.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreenToggle);
			this._base.addEventListener(Event.RESIZE, onVideoResize);
			this._base.addEventListener(AdEvent.AD_START, onAdBegin);
			this._base.addEventListener(AdEvent.AD_COMPLETE, onAdComplete);
			super($name,$parentModule as DisplayObjectContainer);
		}

		override public function get isPlaying():Boolean{
			return this._base.isPlaying;
		}

		override public function get isPaused():Boolean{
			return !this._base.isPlaying;
		}

		override public function get adPlaying():Boolean{
			return this._base.adPlaying;
		}

		override public function get isBuffering():Boolean{
			return this._base.isBuffering;
		}

		override public function get isSeeking():Boolean{
			return this._base.isSeeking;
		}
	
	}
}