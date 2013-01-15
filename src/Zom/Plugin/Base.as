package Zom.Plugin{

	import Zom.Main.Shared;
	import Zom.Modules.ModuleBase;

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
		public var _videoModule:VideoPlayerModule = null;
		public var _experienceModule:ExperienceModule = null;
		public var _contentModule:ContentModule = null;
		public var _adModule:AdvertisingModule = null;
		public var _videoStage:Stage;
		protected var _isPlaying:Boolean = false;
		protected var _isBuffering:Boolean = false;
		protected var _isSeeking:Boolean = false;
		protected var _isFullScreen:Boolean = false;
		protected var _adPlaying:Boolean = false;
		protected var _isSafeToDisplayOverlay:Boolean = false;
		protected var _brightCoveInit:Boolean = false;
		protected var _modules:Object = {};
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

		/**
		 * Constructor
		 * @param $name         the name of the module. Used mainly for logs
		 * @param $parentModule in moz, this is supposed to be null.
		 */
		public function Base($name:String='Base',$parentModule:DisplayObjectContainer=null){
			Shared.setSecurity();
			Shared.onReadyInit(this);
			if($name){this.uniqueId = $name;}
			log($name + ' -- initiating',Shared.LOG_LEVEL_VERBOSE);
			if($parentModule){this._parentModule = $parentModule;}
		}


		/**
		 * Returns the canvasSprite, where objects are added, and which is hidden or shown by hide() and show();
		 * @return the canvasSprite defaults to this if none is set.
		 */
		public function get canvasSprite():Sprite{
			if(!this._canvasSprite){this._canvasSprite = this;}
			return this._canvasSprite;
		}

		public function set canvasSprite($s:Sprite):void{
			this._canvasSprite = $s;
		}

		/**
		 * Returns the maskSprite, used for invisible overlay and set clicks
		 * @return the maskSprite. if no maskSprite is set, it will default to this
		 */
		public function get maskSprite():Sprite{
			if(!this._maskSprite){this._maskSprite = this;}
			return this._maskSprite;
		}

		public function set maskSprite($s:Sprite):void{
			this._maskSprite = $s;
		}

		/**
		 * Called when the module has been added to stage, which might be before, or after brightcove initializes
		 * Loads the parameters by calling loadParams();
		 */
		public function onAddedToStage():void{
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
			if(this._experienceModule){
				this._experienceModule.debug(this.uniqueId + ':' + str);
			}
		}

		/**
		 * Logs an error and returns an Error object
		 * @param  $err String the message
		 * @return      Error
		 */
		protected function logError($err:String):Error{
			if(this._experienceModule){
				this._experienceModule.debug(this.uniqueId + ' [ERROR] :' + $err);
			}		
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
		public function module($moduleName:String,$module:Class=null):ModuleBase{
			if($module){
				this._modules[$moduleName] = new $module($moduleName,this);
			}
			if($moduleName in this._modules){
				return this._modules[$moduleName] as ModuleBase;
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
		public function setModules($modulesToSet:Object):void{
			var n:String, c:Class, isOn:String;
			for(n in $modulesToSet){
				c = Shared.classFromName($modulesToSet[n]);
				if(!c is ModuleBase){ throw this.logError($modulesToSet[n] + 'is not a ModuleBase child class');return;}
				isOn = param(n,'off').toLowerCase();
				if(c && (isOn == 'true' || isOn == '1' || isOn == 'on' || isOn == 'yes')){
					log('loading module '+n,Shared.LOG_LEVEL_LOG)
					this.module(n,c);
				}
			}
		}

		/**
		 * Returns a new LoaderMax instance
		 * @return LoaderMax
		 */
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

		/**
		 * Called when all the loaders are done
		 * @param  evt LoaderEvent
		 * @return
		 */
		protected function onAssetsLoaded(evt:LoaderEvent=null):void{
			dispatchEvent(evt);
			_checkIfReady('load');
		}

		/**
		 * Called when any of the loaders gets an error
		 * @param  evt LoaderEvent
		 * @return
		 */
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
				onAssetsLoaded();
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
		 * Returns a rectangle defining the visible bounds of a passed DisplayObject.
		 * the DisplayObject is not passed, then maskSprite will be used (which itself defaults to 'this' if not set)
		 * @param  $sprite any DisplayObject or maskSprite
		 * @return         [description]
		 */
		public function getVisibleArea($sprite:DisplayObject=null):Rectangle{
			if(!$sprite){$sprite = this.maskSprite;}
			return Shared.getVisibleArea($sprite);
		}

		/**
		 * Creates an invisible overlay of the size of the visible area in maskSprite.
		 * This is useful to use maskSprite as an invisible hit area.
		 * Does absolutely nothing if maskSprite is not set (or if maskSprite == this)
		 * @return
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
		 * Sets onMouseOver() and onMouseOut() to work on hover.
		 * Sets the events on maskSprite (which is == 'this' if not set)
		 */
		protected function setHover($object:EventDispatcher=null):void{
			if(!$object){$object = this.maskSprite;}
			$object.addEventListener(MouseEvent.MOUSE_OVER,onMouseOver);
			$object.addEventListener(MouseEvent.MOUSE_OUT,onMouseOut);
		}

		/**
		 * Called when the mouse is over maskSprite
		 * (maskSprite is 'this' if not explicitely set)
		 * @param  evt MouseEvent
		 * @return
		 */
		protected function onMouseOver(evt:MouseEvent):void{
			dispatchEvent(evt);
		}

		/**
		 * Called when the mouse goes out of maskSprite
		 * (maskSprite is 'this' if not explicitely set)
		 * @param  evt mouseEvent
		 * @return
		 */
		protected function onMouseOut(evt:MouseEvent):void{
			dispatchEvent(evt);
		}

		/**
		 * Called to get and set all the brightcove modules, to say: video module, experience module, content module and ad module.
		 * Throws an error if brightcove is not set yet
		 * @param $andAddToStage if True, adds the module to the stage. Defaults to false
		 */
		public function setBrightcoveModules($andAddToStage:Boolean = false):void{
			if(!this._brightCoveInit){throw this.logError('cannot set brightcove modules before brightcove init;')}
			this.videoModule;
			this.experienceModule;
			this.contentModule;
			this.adModule;
			if($andAddToStage){
				this.videoStage.addChild(this);
			}
		}

		/**
		 * Returns the video module, or throws an error if brightcove is not init
		 * @return the video player module
		 */
		public function get videoModule():VideoPlayerModule{
			if(!this._videoModule){setVideoModule();}
			return this._videoModule;
		}

		/**
		 * Returns the experience module, or throws an error if brightcove is not init
		 * @return the experience module
		 */
		public function get experienceModule():ExperienceModule{
			if(!this._experienceModule){setExperienceModule();}
			return this._experienceModule
		}

		/**
		 * Returns the video's stage (equivalent to experienceModule.getStage()) or throws an error if brightcove is not init.
		 * Will fail if experience module is not set before.
		 * @return the video's stage
		 */
		public function get videoStage():Stage{
			if(!this._experienceModule){
				setVideoStage();
			}
			return this._videoStage;
		}

		/**
		 * Returns the content module of throws an error if brightcove is not init
		 * @return the content module
		 */
		public function get contentModule():ContentModule{
			if(!this._contentModule){setContentModule();}
			return this._contentModule;
		}

		/**
		 * Returns the ad module or throws an error if brightcove is not init
		 * @return the ad module
		 */
		public function get adModule():AdvertisingModule{
			if(!this._adModule){setAdModule();}
			return this._adModule;
		}

		/**
		 * Sets the video module and adds the relevant listeners
		 */
		protected function setVideoModule():void{
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

		/**
		 * Sets the experience module and videoStage, and adds the relevant listeners
		 */
		protected function setExperienceModule():void{
			if(!this._brightCoveInit){throw this.logError('cannot set experienceModule before brightcove init;')}
			this._experienceModule = player.getModule(APIModules.EXPERIENCE) as ExperienceModule;
			if(!this._parentModule){this._parentModule = this._videoStage;}
		}

		/**
		 * Sets the video stage and adds the relevant listeners
		 */
		protected function setVideoStage():void{
			if(!this._brightCoveInit){throw this.logError('cannot set playerStage before brightcove init;')}
			if(!this._experienceModule){
				try{
					this.experienceModule;
				}catch(e:Error){
					throw this.logError('Experience Module is not set yet');
				}
			}
			this._videoStage = this._experienceModule.getStage();
			this._videoStage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreenToggle);
			this._videoStage.addEventListener(Event.RESIZE, onVideoResize);
		}

		/**
		 * Sets the content module and adds the relevant listeners.
		 */
		protected function setContentModule():void{
			if(!this._brightCoveInit){throw this.logError('cannot set adModule before brightcove init;')}
			this._contentModule = player.getModule(APIModules.CONTENT) as ContentModule;
		}

		/**
		 * Sets the ad module and adds the relevant listeners
		 */
		protected function setAdModule():void{
			if(!this._brightCoveInit){throw this.logError('cannot set contentModule before brightcove init;')}
			this._adModule = player.getModule(APIModules.ADVERTISING) as AdvertisingModule;
			this._adModule.addEventListener(AdEvent.AD_START, onAdBegin);
			this._adModule.addEventListener(AdEvent.AD_COMPLETE, onAdComplete);
		}

		/**
		 * Called whrn media is playing
		 * @param  evt the event
		 * @return
		 */
		protected function onMediaPlay(evt:MediaEvent):void{
			log('Media plays',Shared.LOG_LEVEL_VERBOSE);
			_isPlaying = true;
			_isSafeToDisplayOverlay = true;
			this.dispatchEvent(new ZomEvent(ZomEvent.MEDIA_PLAY));
			this.dispatchEvent(evt);
		}

		/**
		 * Called when media begins playing.
		 * @param  evt the event
		 * @return
		 */
		protected function onMediaBegin(evt:MediaEvent):void{
			log('Media begins',Shared.LOG_LEVEL_VERBOSE);
			_isPlaying = true;
			_isSafeToDisplayOverlay = true;
			this.dispatchEvent(new ZomEvent(ZomEvent.MEDIA_PLAY));
			this.dispatchEvent(evt);
		}

		/**
		 * Called when media is stopped or paused
		 * @param  evt the event
		 * @return
		 */
		protected function onMediaStop(evt:MediaEvent):void{
			log('Media stopped',Shared.LOG_LEVEL_VERBOSE);
			_isPlaying = false;
			this.dispatchEvent(new ZomEvent(ZomEvent.MEDIA_STOP));
			this.dispatchEvent(evt);
		}

		/**
		 * Called when the player begins buffering
		 * @param  evt the event
		 * @return
		 */
		protected function onBufferBegin(evt:MediaEvent = null):void{
			log('Buffering...',Shared.LOG_LEVEL_VERBOSE);
			_isBuffering = true;
			_isSafeToDisplayOverlay = false;
			this.dispatchEvent(new ZomEvent(ZomEvent.MEDIA_STOP));
			this.dispatchEvent(evt);
		}

		/**
		 * Called when the buffer completes and playing resumes.
		 * @param  evt the event
		 * @return
		 */
		protected function onBufferComplete(evt:MediaEvent = null):void{
			log('Buffering complete, resuming state',Shared.LOG_LEVEL_VERBOSE);
			_isBuffering = false;
			this.dispatchEvent(new ZomEvent(ZomEvent.MEDIA_PLAY));
			this.dispatchEvent(evt);
		}

		/**
		 * Called when the player initiates a seek
		 * @param  evt the event
		 * @return
		 */
		protected function onSeekBegin(evt:MediaEvent = null):void{
			log('Seek initiated',Shared.LOG_LEVEL_VERBOSE);
			_isSeeking = true;
			_isSafeToDisplayOverlay = false;
			this.dispatchEvent(new ZomEvent(ZomEvent.MEDIA_STOP));
			this.dispatchEvent(evt);
		}

		/**
		 * Called when seek has complete and the player has reached where it should
		 * @param  evt the event
		 * @return
		 */
		protected function onSeekComplete(evt:MediaEvent = null):void{
			log('Seek complete, resuming state',Shared.LOG_LEVEL_VERBOSE);
			_isSeeking = false;
			this.dispatchEvent(new ZomEvent(ZomEvent.MEDIA_PLAY));
			this.dispatchEvent(evt);
		}

		/**
		 * Called when an ad begins playing
		 * @param  evt the event
		 * @return
		 */
		protected function onAdBegin(evt:AdEvent):void {
			log('ad begins',Shared.LOG_LEVEL_VERBOSE)
			_adPlaying = true;
			_isSafeToDisplayOverlay = false;
			this.dispatchEvent(evt);
		}

		/**
		 * Called when an ad has finished playing
		 * @param  evt the event
		 * @return
		 */
		protected function onAdComplete(evt:AdEvent):void {
			log('ad completed, resuming movie',Shared.LOG_LEVEL_VERBOSE)
			_adPlaying = false;
			this.dispatchEvent(evt);
		}

		/**
		 * Called when the player changes from fullscreen to normal or from normal to fullscreen
		 * @param  evt the event
		 * @return
		 */
		protected function onFullScreenToggle(evt:FullScreenEvent):void{
			log('fullscreen event',Shared.LOG_LEVEL_VERBOSE)
			if(evt.fullScreen){this.onFullScreen(evt);}
			else{this.onNormalScreen(evt);}
			this.dispatchEvent(evt);
			this.onVideoResize(evt);
		}

		/**
		 * Called when the player changes to fullscreen
		 * @param  evt the event
		 * @return
		 */
		protected function onFullScreen(evt:Event):void{
			_isFullScreen = true;
			dispatchEvent(evt);
		}

		/**
		 * Called when the player goes off from fullscreen
		 * @param  evt the event
		 * @return
		 */
		protected function onNormalScreen(evt:Event):void{
			_isFullScreen = false;
			dispatchEvent(evt);
		}

		/**
		 * Called when the player is resized, or fullscreen is toggled on or off
		 * @param  evt the event
		 * @return
		 */
		protected function onVideoResize(evt:Event=null):void{
			log('video resize event',Shared.LOG_LEVEL_VERBOSE)
			dispatchEvent(evt);
			place();
		}

		/**
		 * Sets a click url on maskSprite.
		 * the maskSprite defaults to 'this' if not explicitely set.
		 * @param $url    the url
		 * @param $object the object to set the url on. Defaults to maskSprite
		 */
		public function setClickUrl($url:String = '', $object:Sprite=null):void{
			if(!$object){$object = this.maskSprite;}
			if(!$url){$url = this._params['click_url'];}
			this._click_url = $url;
			$object.useHandCursor = true;
			$object.buttonMode = true;
			$object.mouseChildren = false;
			$object.addEventListener(MouseEvent.CLICK,onClickLoadUrl);
		}

		/**
		 * Event called when maskSprite is clicked (if setClickUrl has been called).
		 * Opens a new window with this._click_url
		 * @param  evt the event
		 * @return
		 */
		protected function onClickLoadUrl(evt:MouseEvent=null):void{
			if(this._click_url){
				openWindow(this._click_url);
			}
		}

		/**
		 * Returns true if the movie is playing
		 * @return
		 */
		public function get isPlaying():Boolean{
			return this._isPlaying;
		}

		/**
		 * Returns true if the movie is not playing
		 * @return
		 */
		public function get isPaused():Boolean{
			return !this._isPlaying;
		}

		/**
		 * Returns true if an ad is playing
		 * @return
		 */
		public function get adPlaying():Boolean{
			return this._adPlaying;
		}

		/**
		 * Returns true if the player is buffering
		 * @return
		 */
		public function get isBuffering():Boolean{
			return this._isBuffering;
		}

		/**
		 * Returns true if the player is seeking
		 * @return
		 */
		public function get isSeeking():Boolean{
			return this._isSeeking;
		}

		/**
		 * Returns true if the player is in a state where it is safe to display something, aka, it is not buffering, or seeking.
		 * This value becomes false when: buffer begins, seek begins, ad begins.
		 * It is set to true when: media begins, or media plays
		 * @return true if it is safe to display an overlay
		 */
		public function get isSafeToDisplayOverlay():Boolean{
			return this._isSafeToDisplayOverlay;
		}

		/**
		 * Adds the object to it's parent, and hides it (sets alpha to 0).
		 * the parent is: experience.getStage() if it is a root object, and
		 * the parent set in the constructor if it is a child module
		 */
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