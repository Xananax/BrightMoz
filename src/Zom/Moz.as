/**
 * Main is the Cinemoz Player
 * It sets:
 * 		- top logo with possible messages
 * 		- pause screen
 * 		- ad
 */
package Zom{

	import Zom.Plugin.Base;
	import Zom.Modules.*;
	import Zom.Events.*;
	import Zom.Main.Logger;
	import Zom.Main.Shared;

	import flash.display.Stage;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Bitmap
	import flash.display.Sprite;
	import flash.display.DisplayObjectContainer;

	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.net.URLLoader;

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.events.FullScreenEvent;
	import com.brightcove.api.events.MediaEvent;
	import com.brightcove.api.events.AdEvent;

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;

	import flash.system.SecurityDomain;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;

	import flash.utils.Timer;

	public class Moz extends Base{

		protected var _logo:Logo;
		protected var _pause:Pause;

		/**
		 * Constructor
		 * @param $name         the name. Defaults to 'Moz', and is not supposed to change
		 * @param $parentModule supposed to stay null.
		 */
		public function Moz($name:String='Moz',$parentModule:DisplayObjectContainer=null):void{
			this.mouseChildren = true;
			Shared.setSecurity();
			super($name,$parentModule);
			start();
		}

		/**
		 * Called when brightcove player initializes
		 * sets the brightcove modules and adds itself to stage.
		 */
		override protected function initialize():void{
			super.initialize();
			super.setBrightcoveModules(true);
		}

		/**
		 * called when the module is added to stage.
		 * Sets the moz modules, and begins loading.
		 */
		override public function onAddedToStage():void{
			Logger.setStage(this.stage);
			log('added to stage, loading modules');
			setModules({
				'logo':'Zom.Modules.Logo'
			,	'pause':'Zom.Modules.Pause'
			});
			loadParams();
			beginLoading();
			_checkIfReady('stage');
		}


		/**
		 * Called when media is playing
		 * @param  evt the event
		 * @return
		 */
		override protected function onMediaPlay(evt:MediaEvent):void{
			log('Media plays',Shared.LOG_LEVEL_VERBOSE);
			super.onMediaPlay(evt);
		}

		/**
		 * Called when media begins playing.
		 * @param  evt the event
		 * @return
		 */
		override protected function onMediaBegin(evt:MediaEvent):void{
			log('Media begins',Shared.LOG_LEVEL_VERBOSE);
			super.onMediaBegin(evt);
		}

		/**
		 * Called when media is stopped or paused
		 * @param  evt the event
		 * @return
		 */
		override protected function onMediaStop(evt:MediaEvent):void{
			log('Media stopped',Shared.LOG_LEVEL_VERBOSE);
			super.onMediaStop(evt);
		}

		/**
		 * Called when the player begins buffering
		 * @param  evt the event
		 * @return
		 */
		override protected function onBufferBegin(evt:MediaEvent = null):void{
			log('Buffering...',Shared.LOG_LEVEL_VERBOSE);
			super.onBufferBegin(evt);
		}

		/**
		 * Called when the buffer completes and playing resumes.
		 * @param  evt the event
		 * @return
		 */
		override protected function onBufferComplete(evt:MediaEvent = null):void{
			log('Buffering complete, resuming state',Shared.LOG_LEVEL_VERBOSE);
			super.onBufferComplete(evt);
		}

		/**
		 * Called when the player initiates a seek
		 * @param  evt the event
		 * @return
		 */
		override protected function onSeekBegin(evt:MediaEvent = null):void{
			log('Seek initiated',Shared.LOG_LEVEL_VERBOSE);
			super.onSeekBegin(evt);
		}

		/**
		 * Called when seek has complete and the player has reached where it should
		 * @param  evt the event
		 * @return
		 */
		override protected function onSeekComplete(evt:MediaEvent = null):void{
			log('Seek complete, resuming state',Shared.LOG_LEVEL_VERBOSE);
			super.onSeekComplete(evt);
		}

		/**
		 * Called when an ad begins playing
		 * @param  evt the event
		 * @return
		 */
		override protected function onAdBegin(evt:AdEvent):void {
			log('ad begins',Shared.LOG_LEVEL_VERBOSE)
			super.onAdBegin(evt);
		}

		/**
		 * Called when an ad has finished playing
		 * @param  evt the event
		 * @return
		 */
		override protected function onAdComplete(evt:AdEvent):void {
			log('ad completed, resuming movie',Shared.LOG_LEVEL_VERBOSE)
			super.onAdComplete(evt);
		}

		/**
		 * Called when the player changes from fullscreen to normal or from normal to fullscreen
		 * @param  evt the event
		 * @return
		 */
		override protected function onFullScreenToggle(evt:FullScreenEvent):void{
			log('fullscreen event',Shared.LOG_LEVEL_VERBOSE)
			super.onFullScreenToggle(evt);
		}

		/**
		 * Called when the player is resized, or fullscreen is toggled on or off
		 * @param  evt the event
		 * @return
		 */
		override protected function onVideoResize(evt:Event=null):void{
			log('video resize event',Shared.LOG_LEVEL_VERBOSE)
			super.onVideoResize(evt);
		}

	}

}
