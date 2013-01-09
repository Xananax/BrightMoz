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

		public function Moz($name:String='Moz',$parentModule:DisplayObjectContainer=null):void{
			this.mouseChildren = true;
			this._modulesToSet = {
				'Logo':'Logo'
			}
			super($name,$parentModule);
		}

		override protected function initialize():void{
			super.initialize();
			this.videoModule;
			this.experienceModule;
			this.contentModule;
			this.adModule;
			this.videoStage.addChild(this);
		}

		override public function onAddedToStage():void{
			this.module('Logo',Logo);
			super.onAddedToStage();
			beginLoading();
		}

	}

}