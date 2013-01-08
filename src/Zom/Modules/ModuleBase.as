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

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent
	import flash.events.SecurityErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.events.MouseEvent;

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;

	import flash.external.ExternalInterface;

	import flash.system.SecurityDomain;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;

	import flash.utils.Timer;

	public class ModuleBase extends Sprite{

		protected var o:Object = {};
		protected var _moz:Moz;
		protected var _name:String = 'ModuleBase';
		protected var _canvas:Sprite = new Sprite();
		protected var _button:Sprite = new Sprite();
		protected var _baseAlpha:Number = .8;
		protected var _track_urls_loaders:Array = new Array();
		protected var _tweens:Object = {};
		protected var _tweenNumbers:int = 0;

		public function log(...args):void{
			var s:String = this._name+': '+args.join(', ');
			_moz.log(s);
		}

		public function options($opts:Object):Object{
			if($opts){
				for(var n:String in $opts){
					this.setOptions(n,$opts[n]);
				}
			}
			return this.o;
		}

		public function setOptions(name:String,value:*):void{
			var fnName:String = '_'+name;
			if(this[fnName]){
				this[fnName] = value;
			}else{
				this.o[name] = value;
			}
		}

		public function getOption(name:String):*{
			var fnName:String = '_'+name;
			if(this[fnName]){
				return this[fnName];
			}else if(this.o[name]){
				return this.o[name]
			}	
			return null;
		}

		public function ModuleBase(parent:Moz,options:Object,name:String){
			super();
			_name = name;
			o = options;
			_moz = parent;
			log('1: '+o.track_url);
			if(o.track_url){
				o.track_url = o.track_url.split('||').filter(function(item:*, index:int, array:Array):Boolean{return item != "";});;
				log('2:'+o.track_url);
				setTrackingUrls();
			}else{
				log('no tracking urls');
				o.track_url = [];
			}
			//_moz.addEventListener(ZomEvent.MEDIA_STOP,_onMediaStop)
			//_moz.addEventListener(ZomEvent.MEDIA_PLAY,_onMediaPlay)
			_moz.addEventListener(MediaEvent.PLAY,_onMediaPlay);
			_moz.addEventListener(MediaEvent.BEGIN,_onMediaBegin);
			_moz.addEventListener(MediaEvent.STOP,_onMediaStop);
			_moz.addEventListener(MediaEvent.BUFFER_BEGIN,_onBufferBegin);
			_moz.addEventListener(MediaEvent.BUFFER_COMPLETE,_onBufferComplete);
			_moz.addEventListener(MediaEvent.SEEK,_onSeek);
			_moz.addEventListener(MediaEvent.SEEK_NOTIFY,_onSeekComplete);
			_moz.addEventListener(AdEvent.AD_START, adStartHandler);
			_moz.addEventListener(AdEvent.AD_COMPLETE, adCompleteHandler);
			_canvas.addEventListener(Event.RESIZE, _onStageResize);
			addEventListener(Event.ADDED_TO_STAGE,_onAddedToStage);
			addChild(_canvas);
			addChild(_button);
			this.alpha = _baseAlpha;
			this.addEventListener(MouseEvent.MOUSE_OVER,_onMouseOver);
			this.addEventListener(MouseEvent.MOUSE_OUT,_onMouseOut);
		}

		protected function setTrackingUrls():void{
			log('t1')
			for(var i:int = 0; i < o.track_url.length; i++){
				log('will be tracking '+o.track_url[i]);
				o.track_url[i] = new URLRequest(o.track_url[i]);
				var $l:URLLoader = new URLLoader();
				$l.addEventListener(Event.COMPLETE,trackCallBack);
				$l.addEventListener(IOErrorEvent.IO_ERROR,trackError);
				$l.addEventListener(SecurityErrorEvent.SECURITY_ERROR,trackSecurity)
				_track_urls_loaders.push($l)
			}
		}

		protected function trackCallBack(e:Event):void{
			log('track accomplished');
		}

		protected function trackError(e:IOErrorEvent):void{
			log('track failed');
		}

		protected function trackSecurity(e:SecurityErrorEvent):void{
			log('track security error');
		}

		protected function _track():void{
			log('tracking '+o.track_url.length)
			for(var i:int = 0; i < _track_urls_loaders.length; i++){
				var $l:URLLoader = _track_urls_loaders[i] as URLLoader;
				try{
					log('track: '+o.track_url[i].url);
					$l.load(o.track_url[i]);
					log('track successful: '+o.track_url[i].url);
				}catch(e:Error){
					log('unable to track: '+o.track_url[i].url+': '+e);
				}
			}
		}

		protected function _init():void{
			place();
		}

		protected function _onAddedToStage(e:Event=null):void{
			removeEventListener(Event.ADDED_TO_STAGE,_onAddedToStage);
			_init();
		}

		protected function _onStageResize(e:Event=null):void{
			place();
		}

		protected function _onMouseOver(e:MouseEvent):void{
			_show(this,true,1);
		}

		protected function _onMouseOut(e:MouseEvent):void{
			_hide(this,false,_baseAlpha);
		}

		protected function _addLoaderEvents(loader:Loader):Loader{
			var cont:LoaderInfo = loader.contentLoaderInfo;

			cont.addEventListener(Event.COMPLETE, _onLoaderLoaded);
			cont.addEventListener(Event.INIT, _onLoaderInit);
			cont.addEventListener(IOErrorEvent.IO_ERROR, _onLoaderIOError);
			cont.addEventListener(HTTPStatusEvent.HTTP_STATUS, _onLoaderHttpStatus);
			cont.addEventListener(ProgressEvent.PROGRESS, _onLoaderProgress);

			return loader;
		}

		public function place():void{
			_redrawHitArea();
		}

		protected function _redrawHitArea():void{
			var bmd:BitmapData = new BitmapData(_canvas.width,_canvas.height,true,0);
			bmd.draw(_canvas);
			var rect:Rectangle = bmd.getColorBoundsRect(0xff000000,0xff000000,false);
			//log('rectangle: x:'+rect.x+' y:'+rect.y+', w:'+rect.width+', h:'+rect.height)
			var g:Graphics = _button.graphics;
			g.beginFill(0xff0000)
			g.drawRect((_canvas.width-rect.width)/2,(_canvas.height-rect.height)/2,rect.width,rect.height);
			g.endFill();
			_button.alpha = 0;
		}

		protected function _removeLoaderEvents(loader:Loader):Loader{
			var cont:LoaderInfo = loader.contentLoaderInfo;

			cont.removeEventListener(Event.COMPLETE, _onLoaderLoaded);
			cont.removeEventListener(Event.INIT, _onLoaderInit);
			cont.removeEventListener(IOErrorEvent.IO_ERROR, _onLoaderIOError);
			cont.removeEventListener(HTTPStatusEvent.HTTP_STATUS, _onLoaderHttpStatus);
			cont.removeEventListener(ProgressEvent.PROGRESS, _onLoaderProgress);

			return loader;
		}

		protected function _onLoaderLoaded(evt:Event):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
			log('loader '+mod+' loaded from url '+loader.contentLoaderInfo.url);
		}

		protected function _onLoaderInit(evt:Event):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
			log('loader '+mod+' init');
		}

		protected function _onLoaderIOError(evt:IOErrorEvent):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
			log('error in '+mod+': '+evt)
		}

		protected function _onLoaderHttpStatus(evt:HTTPStatusEvent):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
			log('http status in '+mod+evt.status);
		}

		protected function _onLoaderProgress(evt:ProgressEvent):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
		}

		protected function _show(obj:DisplayObject,quick:Boolean=false,target:Number=1):void{
			obj.visible = true;
			if(quick){
				_showTweenComplete(obj,target);
			}else{
				var $n:int = _tweenNumbers++;
				var $tween:Tween = new Tween(obj,"alpha",null,obj.alpha,target,0.3,true); 
				_tweens[$n] = $tween;
				$tween.addEventListener(
					TweenEvent.MOTION_FINISH
				,	function $showComplete():void{
						$tween.removeEventListener(TweenEvent.MOTION_FINISH,$showComplete);
						_showTweenComplete(obj,target);
						delete _tweens[$n];
					}
				);
			}
		}

		protected function _hide(obj:DisplayObject,quick:Boolean=false,target:Number=0):void{
			if(quick){
				_hideTweenComplete(obj,target);
			}else{
				var $n:int = _tweenNumbers++;
				var $tween:Tween = new Tween(obj,"alpha",null,obj.alpha,target,0.3,true); 
				_tweens[$n] = $tween;
				$tween.addEventListener(
					TweenEvent.MOTION_FINISH
				,	function $hideComplete():void{
						$tween.removeEventListener(TweenEvent.MOTION_FINISH,$hideComplete);
						_hideTweenComplete(obj,target);
						delete _tweens[$n];
					}
				);
			}
		}

		protected function _showTweenComplete(obj:DisplayObject,target:Number=1):void{
			obj.alpha = target;
		}

		protected function _hideTweenComplete(obj:DisplayObject,target:Number=0):void{
			obj.alpha = target;
			if(target<=0){obj.visible = false;}
		}

		public static function openWindow(url : String, window : String = "_blank", features : String = "") : void {
			ExternalInterface.call('window.open', url, window, features);
		}

		protected function _isPlaying():Boolean{
			return _moz.isPlaying;
		}

		protected function _adPlaying():Boolean{
			return _moz.adPlaying;
		}

		protected function _isBuffering():Boolean{
			return _moz.isBuffering;
		}

		protected function _isSeeking():Boolean{
			return _moz.isSeeking;
		}

		protected function _onMediaPlay(e:Event):void{

		}

		protected function _onMediaStop(e:Event):void{
			
		}
	
	}
}