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
	import Zom.Widgets.Pie;

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;
	import com.greensock.*;

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
		protected var _showTextTween:TweenLite;
		protected var _showBackgroundTween:TweenLite;
		protected var _hideTextTween:TweenLite;
		protected var _hideBackgroundTween:TweenLite;
		protected var _frequencyPie:Pie = new Pie(10);
		protected var _displayPie:Pie = new Pie(5);
		protected var _frequencyElapsed:int = 0;
		protected var _frequencyTotal:int = 0;
		protected var _displayElapsed:int = 0;
		protected var _displayTotal:int = 0;
		private var _timersTick:int = 100;

		public function Logo($name:String='Logo',$parentModule:Base=null){
			super($name,$parentModule);
			this._params = {
					frequency:'10' //how ofen the overlay displays
				,	displayFor: '5' //how long to display the overlay
				,	width: 100 //unused
				,	height: 50 //unused
				,	loop:true //if the overlay text loops back to the first frame after reaching the end
				,	url: null //the logo asset url
				,	background_url:null //the text background asset url
				,	texts_url:null //the text url
				,	track_url:'' //url to track on a view
				,	click_url:null //url to open on a new window on click
				,	x:'left' //placement on x axis
				,	y:'top' //placement on y axis
				,	fadeIn:'0.5' //speed of fade in
				,	fadeInDelta:'0.2' //difference between background fade in and text fade in
			}
			this._canvasSprite = new Sprite();
			this._maskSprite = new Sprite();
			this.addChild(this._canvasSprite);
			this.addChild(this._maskSprite);
			start();
			this.addToParent();
		}

		/**
		 * parses parameters, sets the values for frequency and how long the overlay displays
		 */
		override protected function parseParams($params:Object):void{
			super.parseParams($params);
			_params['displayFor'] = int(_params['displayFor']) * 1000;
			_params['frequency'] = int(_params['frequency']) * 1000;
			_params['fadeIn'] = Number(_params['fadeIn']);
			_params['fadeInDelta'] = Number(_params['fadeInDelta']);
			log('ad will display for '+_params['displayFor'] + 'ms every ' + _params['frequency'] + 'ms; it will fade in '+_params['fadeIn']+ 's, text will be delayed for '+ _params['fadeInDelta']+ 's');
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
			super.ready();
			var $logoLoader:ContentDisplay = this.getLoaderContent('logo');
			var $backgroundLoader:ContentDisplay = this.getLoaderContent('background');
			var $textsLoader:ContentDisplay = this.getLoaderContent('texts');

			if($logoLoader){
				log('logo loaded');
				this._logo = $logoLoader;
				this.canvasSprite.addChild(this._logo);
				if($textsLoader){
					log('texts loaded');
					this._texts = $textsLoader.rawContent as MovieClip;
					this._texts.x = _logo.x + _logo.width;
					this._texts.alpha = 0;
					this._texts.visible = false;
					if($backgroundLoader){
						log('background loaded');
						this._background = $backgroundLoader;
						this.canvasSprite.addChild(this._background);
						this._background.x = _logo.x + _logo.width;
						this._background.alpha = 0;
						this._background.visible = false;
					}else{log('no background');}
					this.canvasSprite.addChild(this._texts);
				}else{log('no texts');}
			}else{log('no logo');}
			setHover(this);
			if(_texts){
				createPies();
				createTimers();
				startFrequencyTimer();
			}
			show();
			track();
		}


		protected function createPies():void{
			if(CONFIG::debug){
				if(_texts){
					this._frequencyPie.x = 15;
					this._displayPie.x = 25;
					this._frequencyPie.y = 15;
					this._displayPie.y = 20;
					this._displayPie.alpha = this._frequencyPie.alpha = .5;
					this.addChild(this._frequencyPie);
					this.addChild(this._displayPie);
				}
			}
		}

		protected function createTimers():void{
			createFrequencyTimer();
			createDisplayTimer();
		}

		protected function createFrequencyTimer():void{
			log('creating frequency timer');
			var $freq:int = _params['frequency'];
			_frequencyTotal = Math.round($freq/_timersTick);
			this._frequencyTimer = new Timer(_timersTick,_frequencyTotal);
			this._frequencyTimer.addEventListener(TimerEvent.TIMER,onFrequencyTick);
			this._frequencyTimer.addEventListener(TimerEvent.TIMER_COMPLETE,onFrequencyTime);
			log('ad will display every '+$freq+'ms');
		}

		protected function createDisplayTimer():void{
			log('creating display timer');
			var $time:int = _params['displayFor'];
			_displayTotal = Math.round($time/_timersTick);
			this._displayTimer = new Timer(_timersTick,_displayTotal);
			this._displayTimer.addEventListener(TimerEvent.TIMER,onDisplayTick);
			this._displayTimer.addEventListener(TimerEvent.TIMER_COMPLETE,onDisplayTime);
			log('ad will display for '+$time+ 'ms')
		}

		/**
		 * Returns the display timer, or creates it and sets the relevant event listeners
		 * @return the timer
		 */
		public function get displayTimer():Timer{
			if(this._displayTimer == null){createTimers();}
			return this._displayTimer;
		}

		/**
		 * Returns the frequency timer, or creates it and sets the relevant event listeners
		 * @return the timer
		 */
		public function get frequencyTimer():Timer{
			if(this._frequencyTimer == null){createTimers();}
			return this._frequencyTimer;
		}

		/**
		 * Called each time the frequency timer ticks
		 * @param  e the event
		 */
		protected function onFrequencyTick(e:TimerEvent):void{
			_frequencyElapsed++;
			_frequencyPie.draw(_frequencyElapsed/_frequencyTotal);
		}

		/**
		 * Called when the frequency timer reaches its end (which is every 'frequency')
		 * @param  e the event
		 */
		protected function onFrequencyTime(e:TimerEvent):void{
			log('time to show the ad');
			_frequencyElapsed = 0;
			_frequencyPie.draw(0);
			if(!adPlaying && !isSeeking && !isBuffering && isPlaying){
				log('showing ad',Shared.LOG_LEVEL_LOG);
				showAssets();
				startDisplayTimer(true);
				track();
			}else{
				startFrequencyTimer(true);
			}
		}

		protected function onDisplayTick(e:TimerEvent):void{
			_displayElapsed++;
			_displayPie.draw(_displayElapsed/_displayTotal);
		}

		/**
		 * Called when the display timer reaches its end (which is every 'displayFor')
		 * @param  e the event
		 */
		protected function onDisplayTime(e:TimerEvent):void{
			log('hiding ad');
			_displayElapsed = 0;
			_displayPie.draw(0);
			if(_texts){
				if((this._texts.currentFrame == this._texts.totalFrames) && _params['loop']){
					this._texts.gotoAndStop(1);
					startFrequencyTimer(true);
				}else{
					this._texts.nextFrame();
					startFrequencyTimer(true);
				}
				hideAssets();
			}
		}

		protected function startFrequencyTimer($andReset:Boolean = false):void{
			if(_texts){
				if($andReset){resetFrequencyTimer();}
				log('starting frequency timer');
				frequencyTimer.start();
			}
		}

		protected function stopFrequencyTimer($andReset:Boolean = false):void{
			if(_texts){
				log('stopping frequency timer')
				if($andReset){resetFrequencyTimer();}
				frequencyTimer.stop();
			}
		}

		protected function resetFrequencyTimer():void{
			log('resetting frequency timer');
			frequencyTimer.reset();
			_frequencyElapsed = 0;
			_frequencyPie.draw(0);		
		}

		protected function startDisplayTimer($andReset:Boolean = false):void{
			if(_texts){
				if($andReset){resetDisplayTimer();}
				log('starting display timer');
				displayTimer.start();
			}		
		}

		protected function stopDisplayTimer($andReset:Boolean = false):void{
			if(_texts){
				log('stopping frequency timer')
				if($andReset){resetDisplayTimer();}
				displayTimer.stop();
			}
		}

		protected function resetDisplayTimer():void{
			log('resetting display timer');
			displayTimer.reset();
			_displayElapsed = 0;
			_displayPie.draw(0);		
		}

		/**
		 * Called when the mouse hovers the logo or it's overlay
		 * @param  e the event
		 */
		override protected function onMouseOver(evt:MouseEvent):void{
			super.onMouseOver(evt);
			stopFrequencyTimer(true);
		}

		/**
		 * Called when the mouse hovers out of the logo or an overlay
		 * @param  e the event
		 */
		override protected function onMouseOut(evt:MouseEvent):void{
			super.onMouseOut(evt);
			startFrequencyTimer();
		}

		/**
		 * Called when media begins playing
		 * @param  e the event
		 */
		override protected function onMediaBegin(evt:MediaEvent):void{
			startFrequencyTimer();
			super.onMediaBegin(evt);
		}

		/**
		 * Called when the buffer completes and playing resumes.
		 * @param  evt the event
		 * @return
		 */
		override protected function onBufferComplete(evt:MediaEvent = null):void{
			startFrequencyTimer();
			super.onBufferBegin(evt);	
		}

		/**
		 * Called when an ad has finished playing
		 * @param  evt the event
		 * @return
		 */
		override protected function onAdComplete(evt:AdEvent):void {
			//startFrequencyTimer
			super.onAdComplete(evt);
		}

		/**
		 * Called when media begins playing
		 * @param  e the event
		 */
		override protected function onMediaPlay(evt:MediaEvent):void{
			startFrequencyTimer();
			super.onMediaPlay(evt);
		}

		/**
		 * Called when the player begins buffering
		 * @param  evt the event
		 * @return
		 */
		override protected function onBufferBegin(evt:MediaEvent = null):void{
			onStoppingEvent();
			super.onBufferBegin(evt)
		}

		/**
		 * Called when the player initiates a seek
		 * @param  evt the event
		 * @return
		 */
		override protected function onSeekBegin(evt:MediaEvent = null):void{
			onStoppingEvent();
			super.onSeekBegin(evt);
		}

		/**
		 * Called when an ad begins playing
		 * @param  evt the event
		 * @return
		 */
		override protected function onAdBegin(evt:AdEvent):void {
			onStoppingEvent();
			super.onAdBegin(evt);
		}

		/**
		 * Called when media stops playing
		 * @param  e the event
		 */
		override protected function onMediaStop(evt:MediaEvent):void{
			onStoppingEvent();
			super.onMediaStop(evt);
		}

		protected function onStoppingEvent():void{
			hideAssets();
			stopFrequencyTimer();			
		}

		/**
		 * shows the text and the background
		 * @param  $speed the speed of showing, defaults to .3 seconds
		 * @param  $delay the delay between showing the background and the texts (the texts are shown last)
		 */
		public function showAssets($speed:Number=-1, $delay:Number=-1):void{
			if(_texts){
				if($speed<0){$speed = _params['fadeIn'];}
				if($delay<0){$delay = _params['fadeInDelta'];}
				show($speed,$delay,_texts);
				if(_background){
					show($speed,0,_background);
				}
			}
		}

		/**
		 * Hides the text and the background
		 * @param  $speed the speed of hiding, defaults to .3 seconds
		 * @param  $delay the delay between hiding the background and the texts (the texts are hidden first)
		 */
		public function hideAssets($speed:Number=-1, $delay:Number=-1):void{
			if(_texts){
				if($speed<0){$speed = _params['fadeIn'];}
				if($delay<0){$delay = _params['fadeInDelta'];}
				hide($speed,0,_texts);
				if(_background){
					hide($speed,$delay,_background);
				}
			}
		}

	}
}