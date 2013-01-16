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
	import org.osflash.thunderbolt.Logger;

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

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;

	import flash.system.SecurityDomain;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;

	import flash.utils.Timer;

	public class Moz extends Base{

		protected var _logo:Logo;

		/**
		 * Constructor
		 * @param $name         the name. Defaults to 'Moz', and is not supposed to change
		 * @param $parentModule supposed to stay null.
		 */
		public function Moz($name:String='Moz',$parentModule:DisplayObjectContainer=null):void{
			this.mouseChildren = true;
			super($name,$parentModule);
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
			log('added to stage, loading modules');
			setModules({
				'logo':'Zom.Modules.Logo'
			});
			loadParams();
			beginLoading();
			_checkIfReady('stage');
		}

	}

}
