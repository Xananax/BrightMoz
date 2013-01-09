package Zom.Plugin{

	import Zom.Main.Shared;

	import com.brightcove.api.APIModules;
	import com.brightcove.api.CustomModule;
	import com.brightcove.api.modules.ContentModule;
	import com.brightcove.api.modules.ExperienceModule;
	import com.brightcove.api.modules.VideoPlayerModule;
	import com.brightcove.api.modules.AdvertisingModule;
	
	import Zom.Events.*;
	import flash.events.ProgressEvent;
	import flash.events.HTTPStatusEvent;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import com.brightcove.api.events.MediaEvent;
	import com.brightcove.api.events.AdEvent;

	import com.greensock.loading.*;
	import com.greensock.easing.*;
	import com.greensock.*;
	import com.greensock.loading.display.*;
	import com.greensock.events.*;
	import flash.net.*;
	import flash.display.Loader;
	import com.greensock.loading.core.*;
	import flash.display.LoaderInfo;
	import flash.display.Graphics;
	import flash.system.LoaderContext;
	import flash.net.URLRequest;
	import flash.display.Sprite;
	import flash.display.Stage;	
	import flash.events.EventDispatcher;

	import flash.geom.Rectangle;

	import flash.external.ExternalInterface;
	
	import org.osflash.thunderbolt.Logger;
	import Zom.Main.Utils;

	public class Base extends CustomModule{

		// Statics and variables
		protected static var _version:String = '0.1.2';
		protected var _uniqueId:String;
		protected var _loader:LoaderMax;
		protected var _videoModule:VideoPlayerModule = null;
		protected var _experienceModule:ExperienceModule = null;
		protected var _contentModule:ContentModule = null;
		protected var _adModule:AdvertisingModule = null;
		protected var _videoStage:Stage;
		protected var _isPlaying:Boolean = false;
		protected var _isBuffering:Boolean = false;
		protected var _isSeeking:Boolean = false;
		protected var _isFullScreen:Boolean = false;
		protected var _adPlaying:Boolean = false;
		protected var _brightCoveInit:Boolean = false;
		protected var _modules:Object = {};
		protected var _modulesToSet:Object = {};
		protected var _params:Object = {};
		protected var _initSteps:Object = {
			'brightcove':false
		,	'load':false
		,	'stage':false
		};
		protected var _autoLoadAssetsDefinedInParams:Boolean = true;
		protected var _autoSetClickUrlIfFound:Boolean = true;
		protected var _autoSetTrackingUrlsIfFound:Boolean = true;
		protected var _click_url:String;
		protected var _trackingUrls:LoaderMax;
		protected var _parentModule:DisplayObjectContainer;
		protected var _canvasSprite:Sprite;
		protected var _maskSprite:Sprite;

		// constructor
		public function Base($name:String='Base',$parentModule:DisplayObjectContainer=null){
			Shared.setSecurity();
			Shared.onReadyInit(this);
			if($name){this.uniqueId = $name;}
			if($parentModule){this._parentModule = $parentModule;}
		}


		public function get canvasSprite():Sprite{
			if(!this._canvasSprite){this._canvasSprite = this;}
			return this._canvasSprite;
		}

		public function get maskSprite():Sprite{
			if(!this._maskSprite){this._maskSprite = this;}
			return this._maskSprite;
		}

		/**
		 * Called when the module has been added to stage, which might be before, or after brightcove initializes
		 */
		public function onAddedToStage():void{
			setModules();
			loadParams();
			_checkIfReady('stage');
		}

		/**
		 * Checks if everything is ready, and calls ready() if it is
		 * @param  $complete String set one task as complete by passing it's name
		 * @return           Boolean if ready or not
		 */
		protected function _checkIfReady($complete:String=''):Boolean{
			if($complete){
				log('task '+$complete+' ready',Shared.LOG_LEVEL_VERBOSE);
				this._initSteps[$complete] = true;
			}
			for(var n:String in this._initSteps){
				if(!this._initSteps[n]){return false;}
			}
			ready();
			return true;
		}

		/**
		 * Called when brightcove player initializes
		 */
		override protected function initialize():void{
			this._brightCoveInit = true;
			this.dispatchEvent(new ZomEvent(ZomEvent.INIT));
			_checkIfReady('brightcove');
		}

		/**
		 * places the object in it's container. Override in child classes
		 */
		public function place():void{
			if(this._params.x && this._params.y){
				Shared.place(_params,this,this.parent);
			}
			this.placeChildren();
			for(var n:String in this._modules){
				this._modules.place();
			}
		}

		/**
		 * Places display elements contained in the module. Called when place() is called, before placing the child modules.
		 * @return [description]
		 */
		protected function placeChildren():void{

		}

		/**
		 * At that point:
		 *  - Brightcove player should have loaded and brightcove modules have been set
		 *  - Moz modules have loaded
		 *  - Assets needed by every Moz module have loaded and are ready
		 *  - the module has been placed on stage
		 */
		protected function ready():void{
			place();
		}

		/**
		 * Returns a unique ID
		 * @return String the id
		 */
		public function get uniqueId():String{
			if(!this._uniqueId){this._uniqueId = this.name+'_'+Shared.nextId();}
			return this._uniqueId;
		}

		/**
		 * sets a unique id; No verification is done to check that the id is actually unique
		 * @param id String the id
		 */
		public function set uniqueId(id:String):void{
			this._uniqueId = id;
		}


		/**
		 * Logs a string
		 * @param  str   String the message
		 * @param  level one of the Shared.LOG_LEVEL_...
		 */
		protected function log(str:String,level:int=0):void{
			Shared.getLogger(this.uniqueId)(str,level);
		}

		/**
		 * Logs an error and returns an Error object
		 * @param  $err String the message
		 * @return      Error
		 */
		protected function logError($err:String):Error{
			return Shared.error(this.uniqueId,$err);
		}

		/**
		 * parses parameters after loading. If there are loaders to set, here is the right place
		 */
		protected function parseParams():void{
			for(var n:String in _params){
				if(_autoLoadAssetsDefinedInParams && (n=='url' || n.indexOf('_url')>=0) && n!=='click_url' && n!=='track_url'){
					this.load(_params[n],n.replace('_url',''));
				}
			}
			if(_autoSetClickUrlIfFound && 'click_url' in _params){
				this.setClickUrl(_params['click_url'],this);
			}
			if(_autoSetTrackingUrlsIfFound && 'track_url' in _params){
				_params['track_url'] = Shared.splitString(_params['track_url'],'||');
				this.setTrackingUrls(_params['track_url']);
			}
		}

		/**
		 * Loads all parameters namespaces to this module's unique ID (that is, "moduleName_property")
		 */
		public function loadParams():void{
			var n:String, str:String = 'params loaded: [';
			if(!this.stage){
				throw this.logError('params cannot load before stage is set');
				return;
			}
			Shared.loadParams(this.stage,_params,this.uniqueId);
			this.parseParams();
			for(n in _params){
				str+=n+'="'+_params[n]+'";'
			}
			str+='] -- end params';
			log(str,Shared.LOG_LEVEL_VERBOSE);
			if(this.modules.length){
				for(n in this.modules){
					(this.modules[n] as Base).loadParams();
				}
			}
		}

		/**
		 * Loads a single param. This is not used by loadParams, and makes no use of namespacing
		 * @param  $param          String the param name
		 * @param  $default:*=null * the default value in case the param does not exist; defaults to null;
		 * @return                 * the param's value of the default value provided
		 */
		public function param($param:String=null,$default:*=null):*{
			if(!this.stage){
				throw this.logError('stage is not set yet, access to params is not possible');
				return;
			}
			return Shared.param(this.stage,$param,$default)
		}

		/**
		 * Opens a new window with the passed url
		 * @param  url    String the url 
		 * @param  target String the window name
		 */
		public function openWindow(url:String,target:String="_blank"):void{
			Shared.openWindow(url,target);
		}

		/**
		 * Sets or gets a child module
		 * @param  $moduleName String the module name
		 * @param  $module     Class the module class
		 * @return    			Base a module       
		 */
		public function module($moduleName:String,$module:Class=null):Base{
			if($module){
				this._modules[$moduleName] = new $module($moduleName);
			}
			if($moduleName in this._modules){
				return this._modules[$moduleName];
			}
			return null;
		}

		/**
		 * Returns all the modules
		 * @return Object
		 */
		public function get modules():Object{
			return this._modules;
		}

		/**
		 * Sets all modules that have been defined in _modulesToSet
		 */
		public function setModules():void{
			var n:String, c:Class, isOn:String;
			for(n in _modulesToSet){
				c = Shared.classFromName(_modulesToSet[n]);
				isOn = param(n,'off').toLowerCase();
				if(c && (isOn == 'true' || isOn == '1' || isOn == 'on' || isOn == 'yes')){
					log('loading module '+n,Shared.LOG_LEVEL_LOG)
					this.module(n,c);
				}
			}
		}

		public function get loader():LoaderMax{
			if(!this._loader){
				this._loader = Shared.getLoader(this.uniqueId,{
					onComplete:this.onAssetsLoaded
				,	onError:this.onAssetsLoadingError
				});
			}
			return this._loader;
		}

		/**
		 * Returns a loader previously set
		 * @param  $str String the url used or the loader name
		 * @return      LoaderMax a LoaderMax instance
		 */
		public function getLoader($str:String):LoaderMax{
			if(!this._loader){return null;}
			return this.loader.getLoader(this.uniqueId+'_'+$str);
		}

		/**
		 * Returns the content of a loader previously set
		 * @param  $str String the name of the loader
		 * @return      ContentDisplay the contents as a Sprite. Use rawContent to get to the raw data
		 */
		public function getLoaderContent($str:String):ContentDisplay{
			if(!this._loader){return null;}
			return this.loader.getContent(this.uniqueId+'_'+$str);
		}

		/**
		 * Sets an image to load
		 * @param  $url String url of the image
		 * @param  $name String the name of the loader
		 * @return      ImageLoader an ImageLoader instance
		 */
		public function loadImage($url:String,$name:String=''):ImageLoader{
			$name = this.uniqueId+'_'+($name? 'loader_'+Shared.nextId() : $name);
			return Shared.loadImage($url,null,{name:$name},this.loader);
		}

		/**
		 * Sets an swf to load
		 * @param  $url String url of the SWF
		 * @param  $name String the name of the loader
		 * @return      SWFLoader the SWFLoader instance
		 */
		public function loadSWF($url:String,$name:String=''):SWFLoader{
			$name = this.uniqueId+'_'+($name? 'loader_'+Shared.nextId() : $name);
			return Shared.loadSWF($url,null,{name:$name},this.loader);
		}

		/**
		 * Sets an asset to load
		 * @param  $url  String url of the asset
		 * @param  $name String the name of the loader
		 * @return      LoaderMax a LoaderMax instance
		 */
		public function load($url:String,$name:String=''):LoaderCore{
			$name = this.uniqueId+'_'+($name? 'loader_'+Shared.nextId() : $name);
			return Shared.load($url,null,{name:$name},this.loader);
		}

		protected function onAssetsLoaded(evt:LoaderEvent):void{
			dispatchEvent(evt);
			_checkIfReady('loaded');
		}

		protected function onAssetsLoadingError(evt:LoaderEvent):void{
			log('error loading');
			dispatchEvent(evt);
		}

		/**
		 * Begins loading, if there is anything to load, or calls _checkIfReady. All loading assets must have been set prior
		 * to calling this function!
		 * Do not call this in every child class, but only in the main calling class;
		 */
		public function beginLoading():void{
			if(Shared.queueLength()){
				Shared.onLoadComplete(this.onAssetsLoaded);
				Shared.getQueue().load();
			}
			else{
				_checkIfReady();
			}
		}

		/**
		 * Hides an object
		 * @param  obj               DisplayObject
		 * @param  time              Number the time in seconds
		 * @param  delay             Number a delay time in seconds before hiding the object
		 * @param  removeIfInvisible Boolean if true, will set "visible = false" at the end of the tween. Defaults to true
		 * @return                   TweenLite a TweenLite Instance
		 */
		public function hide(time:Number=0.3,delay:Number=0, $obj:DisplayObject=null, removeIfInvisible:Boolean = true):TweenLite{
			if(!$obj){$obj=this.canvasSprite;}
			return Shared.opacity($obj,0,time,removeIfInvisible, {delay:delay});
		}

		/**
		 * Shows an object. If "visible" was set to false, it sets it to true before
		 * @param  obj               DisplayObject
		 * @param  time              Number the time in seconds
		 * @param  delay             Number a delay time in seconds before showing the object
		 * @return                   TweenLite a TweenLite Instance
		 */
		public function show(time:int=0.3, delay:Number=0, $obj:DisplayObject=null):TweenLite{
			if(!$obj){$obj=this.canvasSprite;}
			return Shared.opacity($obj,1,time,false,{delay:delay});
		}

		/**
		 * Sets urls to track on click or on view
		 * @param $urls Array an array of urls
		 */
		public function setTrackingUrls($urls:Array):void{
			var i:int = 0, $d:DataLoader;
			if(!this._trackingUrls){
				this._trackingUrls = new LoaderMax({
					name:"trackingUrls"
				,	onComplete:onTrackingComplete
				,	onError:onTrackingError
				,	auditSize:false
				,	autoLoad:false
				,	defaultContext:Shared.getLoaderContext()
				});
				for(i; i < $urls.length; i++){
					$d = new DataLoader($urls[i]);
					this._trackingUrls.append($d);
				}
			}
		}

		/**
		 * Called when the tracking urls have all loaded successfully
		 * @param  evt LoaderEvent
		 */
		protected function onTrackingComplete(evt:LoaderEvent):void{
			log('track accomplished');
		}

		/**
		 * Called when the tracking urls fail
		 * @param  evt LoaderEvent
		 */
		protected function onTrackingError(evt:LoaderEvent):void{
			log('track failed');
		}

		/**
		 * Loads the tracking urls
		 */
		public function track():void{
			if(this._trackingUrls){this._trackingUrls.load(true);}
		}

		/**
		 * [getVisibleArea description]
		 * @return [description]
		 */
		public function getVisibleArea():Rectangle{
			return Shared.getVisibleArea(this.maskSprite);
		}

		/**
		 * [redrawHitArea description]
		 * @return [description]
		 */
		public function redrawHitArea():void{
			if(this.maskSprite != this){
				var $m:Sprite = this.maskSprite;
				var $rect:Rectangle = this.getVisibleArea();
				var $g:Graphics = $m.graphics;
				$g.beginFill(0xff0000);
				$g.drawRect(($m.width-$rect.width)/2,($m.height-$rect.height)/2,$rect.width,$rect.height);
				$g.endFill();
				$m.alpha = 0;
			}
		}

		/**
		 * Sets onMouseOver() and onMouseOut() to work on hover
		 */
		protected function setHover($object:EventDispatcher=null):void{
			if(!$object){$object = this.maskSprite;}
			$object.addEventListener(MouseEvent.MOUSE_OVER,onMouseOver);
			$object.addEventListener(MouseEvent.MOUSE_OUT,onMouseOut);
		}

		protected function onMouseOver(evt:MouseEvent):void{
			dispatchEvent(evt);
		}

		protected function onMouseOut(evt:MouseEvent):void{
			dispatchEvent(evt);
		}

		public function get videoModule():VideoPlayerModule{
			if(!this._videoModule){
				if(!this._brightCoveInit){throw this.logError('cannot set videoModule before brightcove init;')}
				this._videoModule = player.getModule(APIModules.VIDEO_PLAYER) as VideoPlayerModule;
				this._videoModule.addEventListener(MediaEvent.PLAY,onMediaPlay);
				this._videoModule.addEventListener(MediaEvent.BEGIN,onMediaBegin);
				this._videoModule.addEventListener(MediaEvent.STOP,onMediaStop);
				this._videoModule.addEventListener(MediaEvent.BUFFER_BEGIN,onBufferBegin);
				this._videoModule.addEventListener(MediaEvent.BUFFER_COMPLETE,onBufferComplete);
				this._videoModule.addEventListener(MediaEvent.SEEK,onSeekBegin);
				this._videoModule.addEventListener(MediaEvent.SEEK_NOTIFY,onSeekComplete);
			}
			return this._videoModule;
		}

		public function get experienceModule():ExperienceModule{
			if(!this._experienceModule){
				if(!this._brightCoveInit){throw this.logError('cannot set experienceModule before brightcove init;')}
				this._experienceModule = player.getModule(APIModules.EXPERIENCE) as ExperienceModule;
				this._videoStage = this._experienceModule.getStage();
				this._videoStage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreenToggle);
				this._videoStage.addEventListener(Event.RESIZE, onVideoResize);
				if(!this._parentModule){this._parentModule = this._videoStage;}
			}
			return this._experienceModule
		}

		public function get videoStage():Stage{
			if(!this._experienceModule){
				if(!this._brightCoveInit){throw this.logError('cannot set playerStage before brightcove init;')}
				this.experienceModule;
				if(!this._experienceModule){throw this.logError('Experience Module is not set yet');return null;}
			}
			return this._videoStage;
		}

		public function get contentModule():ContentModule{
			if(!this._contentModule){
				if(!this._brightCoveInit){throw this.logError('cannot set adModule before brightcove init;')}
				this._contentModule = player.getModule(APIModules.CONTENT) as ContentModule;
			}
			return this._contentModule;
		}

		public function get adModule():AdvertisingModule{
			if(this._adModule){
				if(!this._brightCoveInit){throw this.logError('cannot set contentModule before brightcove init;')}
				this._adModule = player.getModule(APIModules.ADVERTISING) as AdvertisingModule;
				this._adModule.addEventListener(AdEvent.AD_START, onAdBegin);
				this._adModule.addEventListener(AdEvent.AD_COMPLETE, onAdComplete);
			}
			return this._adModule;
		}

		protected function onMediaPlay(evt:MediaEvent):void{
			log('Media plays',Shared.LOG_LEVEL_VERBOSE);
			_isPlaying = true;
			this.dispatchEvent(new ZomEvent(ZomEvent.MEDIA_PLAY));
			this.dispatchEvent(evt);
		}

		protected function onMediaBegin(evt:MediaEvent):void{
			log('Media begins',Shared.LOG_LEVEL_VERBOSE);
			_isPlaying = true;
			this.dispatchEvent(new ZomEvent(ZomEvent.MEDIA_PLAY));
			this.dispatchEvent(evt);
		}

		protected function onMediaStop(evt:MediaEvent):void{
			log('Media stopped',Shared.LOG_LEVEL_VERBOSE);
			_isPlaying = false;
			this.dispatchEvent(new ZomEvent(ZomEvent.MEDIA_STOP));
			this.dispatchEvent(evt);
		}

		protected function onBufferBegin(evt:MediaEvent = null):void{
			log('Buffering...',Shared.LOG_LEVEL_VERBOSE);
			_isBuffering = true;
			this.dispatchEvent(new ZomEvent(ZomEvent.MEDIA_STOP));
			this.dispatchEvent(evt);
		}

		protected function onBufferComplete(evt:MediaEvent = null):void{
			log('Buffering complete, resuming state',Shared.LOG_LEVEL_VERBOSE);
			_isBuffering = false;
			this.dispatchEvent(new ZomEvent(ZomEvent.MEDIA_PLAY));
			this.dispatchEvent(evt);
		}

		protected function onSeekBegin(evt:MediaEvent = null):void{
			log('Seek initiated',Shared.LOG_LEVEL_VERBOSE);
			_isSeeking = true;
			this.dispatchEvent(new ZomEvent(ZomEvent.MEDIA_STOP));
			this.dispatchEvent(evt);
		}

		protected function onSeekComplete(evt:MediaEvent = null):void{
			log('Seek complete, resuming state',Shared.LOG_LEVEL_VERBOSE);
			_isSeeking = false;
			this.dispatchEvent(new ZomEvent(ZomEvent.MEDIA_PLAY));
			this.dispatchEvent(evt);
		}

		protected function onAdBegin(evt:AdEvent):void {
			log('ad begins',Shared.LOG_LEVEL_VERBOSE)
			_adPlaying = true;
			this.dispatchEvent(evt);
		}

		protected function onAdComplete(evt:AdEvent):void {
			log('ad completed, resuming movie',Shared.LOG_LEVEL_VERBOSE)
			_adPlaying = false;
			this.dispatchEvent(evt);
		}

		protected function onFullScreenToggle(evt:FullScreenEvent):void{
			log('fullscreen event',Shared.LOG_LEVEL_VERBOSE)
			if(evt.fullScreen){this.onFullScreen(evt);}
			else{this.onNormalScreen(evt);}
			this.dispatchEvent(evt);
			this.onVideoResize(evt);
		}

		protected function onFullScreen(evt:Event):void{
			_isFullScreen = true;
			dispatchEvent(evt);
		}

		protected function onNormalScreen(evt:Event):void{
			_isFullScreen = false;
			dispatchEvent(evt);
		}

		protected function onVideoResize(evt:Event=null):void{
			log('video resize event',Shared.LOG_LEVEL_VERBOSE)
			dispatchEvent(evt);
			place();
		}

		public function setClickUrl($url:String = '', $object:Sprite=null):void{
			if(!$object){$object = this.maskSprite;}
			if(!$url){$url = this._params['click_url'];}
			this._click_url = $url;
			$object.useHandCursor = true;
			$object.buttonMode = true;
			$object.mouseChildren = false;
			$object.addEventListener(MouseEvent.CLICK,onClickLoadUrl);
		}

		protected function onClickLoadUrl(evt:MouseEvent=null):void{
			if(this._click_url){
				openWindow(this._click_url);
			}
		}

		public function get isPlaying():Boolean{
			return this._isPlaying;
		}

		public function get isPaused():Boolean{
			return !this._isPlaying;
		}

		public function get adPlaying():Boolean{
			return this._adPlaying;
		}

		public function get isBuffering():Boolean{
			return this._isBuffering;
		}

		public function get isSeeking():Boolean{
			return this._isSeeking;
		}

		public function addToParent():void{
			if(!this._parentModule){
				this.logError('cannot add myself to parent module as it does not exist');
				return;
			}
			hide(0);
			this._parentModule.addChild(this);
		}

	}

}