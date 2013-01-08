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

		protected var _version:String = '0.1.1.52';
		protected var _modules:Object = {
			 pause: {
				on: false
			//,	img: null
			//,	url: null
			,	x:0
			,	y:0
			,	delay:6000
			,	_loader:null
			,	_content:null
			,	track_url:''
			}
		,	logo: {
				on: false
			,	interval:'5000'
			,	timer: '2000'
			,	width: 100
			,	height: 50
			,	loop:true
			,	url: null
			,	click_url:null
			,	background_url:null
			,	texts_url:null
			,	track_url:''
			,	x:'top'
			,	y:'left'
			,	_loader:null
			,	_content:null
			}
		}
		protected var _loadersNmb:int = 0;
		protected var _loadersLoadedNmb:int = 0;
		public var _loaderContext:LoaderContext = new LoaderContext();
		protected var _logo:*= null;
		protected var _tweens:Object = {};
		protected var _tweenNumbers:int = 0;

		public function Moz():void{
			super();
			_loaderContext.applicationDomain = ApplicationDomain.currentDomain;
			_loaderContext.securityDomain = SecurityDomain.currentDomain;
			log('---- Moz ---- ')
		}

		override public function log(...args):void{
			CONFIG::debug{
				Logger.info.apply(null, args);
			}
		}

		override protected function _loadParams():void{
			super._loadParams();
			var $log:String = new String();
			log('Loading Params');
			for(var mod:String in _modules){
				$log = 'loading params for '+mod;
				_modules[mod].on = _param(mod,_modules[mod].on);
				if(_modules[mod].on){
					if(_modules[mod].hasOwnProperty('_loader')){_loadersNmb++;}
					$log+=' -- [';
					for(var opt:String in _modules[mod]){
						if(opt == 'on' || opt.indexOf('_') == 0){continue;}
						_modules[mod][opt] = _param(mod+'_'+opt,_modules[mod][opt]);
						$log+=opt+'="'+_modules[mod][opt]+'";';
					}
					$log+='] -- '+mod;
				}
				else{
					$log+=' : OFF';
				}
				log($log);
			}
		}

		override protected function _init():void{
			log('will load parameters now');
			_loadParams();
			log('parameters loaded');
			var $url:String = '';
			for(var mod:String in _modules){
				if(_modules[mod].on && _modules[mod].url){
					$url = _modules[mod].url;
					_modules[mod]._isSwf = ($url.substring($url.lastIndexOf(".")+1, $url.length).toLowerCase() == 'swf') ? true : false;
					log('will load an swf file');
					try {
						_modules[mod]._loader = new Loader();
						_modules[mod]._loader.name = mod;
						_addLoaderEvents(mod,_modules[mod]._loader).load(new URLRequest($url),_loaderContext);
					}catch(e:Error){
						log('error in '+mod,e);
					}
				}
			}
			log('Moz initiated');
		}

		protected function _ready():void{
			log(' --- ready ! --- version '+_version);
			var mod:String;
			if(_modules.logo && _modules.logo._content){
				log('instanciating logo')
				_logo = new Logo(this,_modules.logo);
				log('!LOGO!!!!')
			}
			for(mod in _modules){
				if(_modules[mod]._content !== null){
					try{
						_hide(mod,true);
						//addChild(_modules[mod]._content);
					}catch(e:Error){
						log('module hiding error: '+e);
					}
				}
			}
			_place();
			for(mod in _modules){
				if(_modules[mod]._content !== null){
					_show(mod);
				}
			}
		}


		protected function _place():void{
			log('placing');
			var $content:DisplayObject;
			var $mod:Object;
			var $width:int = _video.getWidth();
			var $height:int = _video.getHeight();

			for(var mod:String in _modules){
				$mod = _modules[mod];
				$content = $mod._content;
				if($content){
					$content.x = parseDimension($mod.x,$content.width,$width);
					$content.y = parseDimension($mod.y,$content.height,$height);
					log(mod+' placed at x:'+$content.x + ' y:'+$content.y);
				}
			}
		}

		/**
		 * Tweening Stuff
		 */
		
		protected function _show(module:String,quick:Boolean=false):void{
			var mod:Object = _modules[module];
			if(mod._content){
				var $d:DisplayObject = mod._content as DisplayObject;
				$d.visible = true;
				if(quick){
					_showTweenComplete(module);
				}
				else{
					var $n:int = _tweenNumbers++;
					var $tween:Tween = new Tween($d,"alpha",null,$d.alpha,1,0.3,true); 
					_tweens[$n] = $tween;
					$tween.addEventListener(
						TweenEvent.MOTION_FINISH
					,	function $showComplete(e:TweenEvent):void{
							$tween.removeEventListener(TweenEvent.MOTION_FINISH,$showComplete);
							_showTweenComplete(module);
							delete _tweens[$n];
						}
					);
				}
			}
		}

		protected function _hide(module:String,quick:Boolean=false):void{
			var mod:Object = _modules[module];
			if(mod._content){
				var $d:DisplayObject = mod._content as DisplayObject;
				if(quick){
					_hideTweenComplete(module);
				}else{
					var $n:int = _tweenNumbers++;
					var $tween:Tween = new Tween($d,"alpha",null,$d.alpha,0,0.3,true); 
					_tweens[$n] = $tween;
					$tween.addEventListener(
						TweenEvent.MOTION_FINISH
					,	function $hideComplete():void{
							$tween.removeEventListener(TweenEvent.MOTION_FINISH,$hideComplete);
							_hideTweenComplete(module);
							delete _tweens[$n];
						}
					);
				}
			}
		}

		protected function _showTweenComplete(module:String):void{
			_modules[module]._content.alpha = 1;
		}

		protected function _hideTweenComplete(module:String):void{
			_modules[module]._content.alpha = 0;
			_modules[module]._content.visible = false;
		}
		/****************************
		 LOADER STUFF
		*/

		protected function _loaderLoadedOrFailed(mod:String,loader:Loader,e:Event):void{
			_removeLoaderEvents(loader);
			_loadersLoadedNmb++;
			if((_loadersLoadedNmb - _loadersLoadedNmb) <= 0){
				_ready();
			}
			else{
				log('still '+(_loadersLoadedNmb - _loadersLoadedNmb)+' loaders to go');
			}
		}

		override protected function _onLoaderLoaded(evt:Event):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
			try{
				if(_modules[mod]._isSwf){
					_modules[mod]._content = LoaderInfo(evt.target).content as MovieClip;
					_modules[mod]._content.stop();
				}else{
					_modules[mod]._content = LoaderInfo(evt.target).content as Bitmap;
				}
				_modules[mod]._origWidth = _modules[mod]._content.width;
				_modules[mod]._origHeight = _modules[mod]._content.height;
			}catch(e:Error){
				log('loader error: '+mod+' - '+e);
			}
			log(mod+' loaded');
			_loaderLoadedOrFailed(mod,loader,evt);
		}

		override protected function _onLoaderInit(evt:Event):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
			log(mod+' init');
			if(_modules[mod]._isSwf){
				(evt.target.content as MovieClip).stop();
			}
		}

		override protected function _onLoaderIOError(evt:IOErrorEvent):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
			log(mod+' failed',evt);
			_loaderLoadedOrFailed(mod,loader,evt);
		}

		override protected function _onLoaderHttpStatus(evt:HTTPStatusEvent):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
			log(mod+' http status:'+evt.status);
		}

		override protected function _onLoaderProgress(evt:ProgressEvent):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
			var $progress:Number = Math.round((evt.bytesLoaded/evt.bytesTotal) * 100);
			//log(mod+' progress:' + $progress + '%');
		}

	}

}