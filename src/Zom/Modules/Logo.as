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

	public class Logo extends ModuleBase{

		protected var _background:ContentDisplay;
		protected var _texts:MovieClip;
		protected var _logo:ContentDisplay;
		protected var _displayTimer:Timer;
		protected var _frequencyTimer:Timer;
		protected var _minutes:int = 0;
		protected var _minutesElapsed:int = 0;

		public function Logo($name:String='Logo',$parentModule:Base=null){
			this._canvasSprite = new Sprite();
			this._maskSprite = new Sprite();
			this.addChild(this._canvasSprite);
			this.addChild(this._maskSprite);
			this._params = {
					frequency:'5000'
				,	displayFor: '2000'
				,	width: 100
				,	height: 50
				,	loop:true
				,	logo_url: null
				,	background_url:null
				,	texts_url:null
				,	track_url:''
				,	click_url:null
				,	x:'top'
				,	y:'left'
			}
			super($name,$parentModule);
			this.addToParent();
		}

		override protected function parseParams():void{
			super.parseParams();
			_params['displayFor'] = int(_params['displayFor']);
			_params['frequency'] = int(_params['frequency']);
		}

		override protected function ready():void{
			var $logoLoader:ContentDisplay = this.getLoaderContent('logo');
			var $backgroundLoader:ContentDisplay = this.getLoaderContent('background');
			var $textsLoader:ContentDisplay = this.getLoaderContent('text');

			if($logoLoader){
				this._logo = $logoLoader;
				this.canvasSprite.addChild(this._logo);
			}
			if($backgroundLoader){
				this._background = $backgroundLoader;
				this.canvasSprite.addChild(this._background);
				_background.x = _logo.x + _logo.width;
			}
			if($textsLoader){
				this._texts = $textsLoader.rawContent as MovieClip;
				this.canvasSprite.addChild(this._texts);
				_texts.x = _logo.x + _logo.width;
			}
			hideAssets(0);
			show();
			setHover(this);
			track();
		}

		public function get displayTimer():Timer{
			if(!this._displayTimer){
				this._displayTimer = new Timer(_params['displayFor'],1);
				this._displayTimer.addEventListener(TimerEvent.TIMER,onDisplayTime);
			}
			return this._displayTimer;
		}

		public function get frequencyTimer():Timer{
			if(!this._frequencyTimer){
				var $freq:int = _params['frequency'];
				if($freq>1000){
					_minutes = Math.round($freq/1000/60);
					this._frequencyTimer = new Timer(1000,_minutes*60);
					this._frequencyTimer.addEventListener(TimerEvent.TIMER,onFrequencyTick);
					log('ad will display every '+_minutes+' minutes');
				}else{
					this._frequencyTimer = new Timer($freq);
					log('ad will display every '+($freq/1000)+' seconds');
				}
				this._frequencyTimer.addEventListener(TimerEvent.TIMER_COMPLETE,onFrequencyTime);
			}
			return this._frequencyTimer;
		}

		protected function onFrequencyTick(e:TimerEvent):void{
			_minutesElapsed = e.target.currentCount / 60;
			log('still '+(_minutes - _minutesElapsed)+ ' minute before displaying ad',Shared.LOG_LEVEL_VERBOSE);
		}

		protected function onFrequencyTime(e:TimerEvent):void{
			log('showing ad',Shared.LOG_LEVEL_LOG);
			_minutesElapsed = 0;
			if(!adPlaying && !isSeeking && !isBuffering && isPlaying){
				showAssets();
				displayTimer.reset();
				displayTimer.start();
				track();
			}else{
				frequencyTimer.start();
			}
		}

		protected function onDisplayTime(e:TimerEvent):void{
			log('hiding ad');
			this._texts.nextFrame();
			hideAssets();
			this.frequencyTimer.reset();
			this.frequencyTimer.start();
		}

		override protected function onMouseOver(e:MouseEvent):void{
			super.onMouseOver(e);
			displayTimer.reset();
			frequencyTimer.stop();
		}

		override protected function onMouseOut(e:MouseEvent):void{
			super.onMouseOut(e);
			frequencyTimer.start();
		}

		override protected function onMediaPlay(e:MediaEvent):void{
			log('media plays');
			frequencyTimer.start();
		}

		override protected function onMediaStop(e:MediaEvent):void{
			log('media stops');
			hideAssets();
			frequencyTimer.stop();
		}

		public function showAssets($speed:int=0.3):void{
			if(_texts){
				show($speed,0.2,_texts);
				if(_background){show($speed,0,_background);}
			}
		}

		public function hideAssets($speed:int=0.3):void{
			if(_texts){
				hide($speed,0,_texts);
				if(_background){hide($speed,0,_background);}
			}
		}

	}
}