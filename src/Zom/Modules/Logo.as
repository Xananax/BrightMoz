package Zom.Modules{

	import Zom.Plugin.Base;
	import Zom.Moz;
	import Zom.Modules.*;

	import flash.display.Stage;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Bitmap;
	import flash.display.Sprite;

	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.display.LoaderInfo;

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.events.MouseEvent;

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;

	import flash.system.SecurityDomain;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;

	import flash.utils.Timer;

	public class Logo extends ModuleBase{

		protected var _background:Bitmap;
		protected var _texts:MovieClip;
		protected var _logo:Sprite;
		protected var _logoImage:Bitmap;
		protected var _displayTimer:Timer;
		protected var _intervalTimer:Timer;
		protected var _url:String;
		protected var _loadersLoadedNmb:int = 0;
		protected var _loadersNmb:int = 0;
		protected var _minutes:int = 0;
		protected var _minutesElapsed:int = 0;
		protected var _currentTextFrame:int = 1;

		public function Logo(parent:Moz,options:Object){
			super(parent,options,'Logo');
			log(' ------- LOGO -------------');
			o.interval = int(o.interval);
			o.timer = int(o.timer);
			if(o.click_url){
				log('external url set to '+o.click_url);
				_url = o.click_url;
				_button.useHandCursor = true;
				_button.buttonMode = true;
				_button.mouseChildren = false;
				_button.addEventListener(MouseEvent.CLICK,onClick);
			}
			if(!o.background_url && !o.texts){init();}
			else{
				if(o.background_url){
					var bLoader:Loader = new Loader();
					bLoader.name = 'background';
					_addLoaderEvents(bLoader);
					_loadersNmb++;
				}
				if(o.texts_url){
					var tLoader:Loader = new Loader();
					tLoader.name = 'texts';
					_addLoaderEvents(tLoader);
					_loadersNmb++;
				}
				if(o.background_url){bLoader.load(new URLRequest(o.background_url),_moz._loaderContext);}
				if(o.texts_url){tLoader.load(new URLRequest(o.texts_url),_moz._loaderContext);}
			}
		}

		public function init():void{
			log('init');
			if(_texts){
				if(o.interval>1000){
					_minutes = Math.round(o.interval/1000/60);
					_intervalTimer = new Timer(1000,_minutes*60);
					_intervalTimer.addEventListener(TimerEvent.TIMER,intervalMinute);
					log('ad will display every '+_minutes+' minutes');

				}else{
					_intervalTimer = new Timer(o.interval);
					log('ad will display every '+(o.interval/1000)+' seconds');
				}
				_intervalTimer.addEventListener(TimerEvent.TIMER_COMPLETE,interval);
				
				_intervalTimer.start();
				_displayTimer = new Timer(o.timer,1);
				_displayTimer.addEventListener(TimerEvent.TIMER,display);
				log('ad will stay on for '+(o.timer/1000)+' seconds');
			}
			if(o._isSwf){
				_logo = o._content;
			}
			else{
				_logo = new Sprite();
				_logo.addChild(o._content);
			}
			log(_logo);
			_canvas.addChild(_logo);
			if(_background){
				_canvas.addChild(_background);
				_background.x = _logo.x + _logo.width;// + 25;
				//_background.y = _logo.y + 25;
				_hide(_background,true);
			}
			if(_texts){
				_canvas.addChild(_texts);
				_texts.x = _logo.x + _logo.width;// + 60;
				//_texts.y = _logo.y + 30;
				_hide(_texts,true);
			}
			_moz.addChild(this);
			place();
			_track();
		}

		override public function place():void{
			super.place();
		}

		protected function intervalMinute(e:TimerEvent):void{
			_minutesElapsed = e.target.currentCount / 60;
			log('still '+(_minutes - _minutesElapsed)+ ' minute before displaying ad');
		}

		protected function interval(e:TimerEvent):void{
			log('showing ad');
			_minutesElapsed = 0;
			if(_texts && !_adPlaying() && !_isSeeking() && !_isBuffering() && _isPlaying()){
				_text.gotoAndStop(_currentTextFrame);
				_currentTextFrame++;
				if(_currentTextFrame > _text.totalFrames){
					_currentTextFrame = 1;
				}
				_show(_texts);
				_show(_background);
				_displayTimer.reset();
				_displayTimer.start();
				_track();
			}else{
				_intervalTimer.start();
			}
		}

		protected function display(e:TimerEvent):void{
			log('hiding ad');
			//
			_hide(_texts);
			_hide(_background);
			_intervalTimer.reset();
			_intervalTimer.start();
		}

		protected function _loaderLoadedOrFailed():void{
			_loadersLoadedNmb++;
			log('total loaders:'+_loadersNmb);
			var $left:int = _loadersNmb - _loadersLoadedNmb;
			if(!$left){
				log('no loader left');
				init();
			}else{
				log('still '+$left+' loaders left')
			}
		}

		override protected function _onMouseOver(e:MouseEvent):void{
			super._onMouseOver(e);
			_displayTimer.reset();
			_intervalTimer.stop();
		}

		override protected function _onMouseOut(e:MouseEvent):void{
			super._onMouseOut(e);
			_intervalTimer.start();
		}

		override protected function _onMediaPlay(e:Event):void{
			log('media plays');
			_intervalTimer.start();
		}

		override protected function _onMediaStop(e:Event):void{
			log('media stops');
			_hide(_texts);
			_hide(_background);
			_intervalTimer.stop();
		}

		override protected function _showTweenComplete(obj:DisplayObject,target:Number=1):void{
			super._showTweenComplete(obj,target);
			_redrawHitArea();
		}

		override protected function _hideTweenComplete(obj:DisplayObject,target:Number=0):void{
			super._hideTweenComplete(obj,target);
			_redrawHitArea();
		}

		override protected function _onLoaderLoaded(evt:Event):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
			log('loaded '+mod+ ' from url '+loader.contentLoaderInfo.url);
			if(mod == 'background'){
				this._background = LoaderInfo(evt.target).content as Bitmap;
			}
			if(mod == 'texts'){
				try{
					//log(LoaderInfo(evt.target).content);
					this._texts = LoaderInfo(evt.target).content as MovieClip;
					//log(this._texts);
					this._texts.stop();
				}catch(e:Error){
					log('texts error: '+e);
				}
			}
			_loaderLoadedOrFailed();
		}

		override protected function _onLoaderIOError(evt:IOErrorEvent):void{
			super._onLoaderIOError(evt);
			_loaderLoadedOrFailed();
		}

		protected function onClick(e:MouseEvent):void{
			openWindow(_url);
		}
	}
}