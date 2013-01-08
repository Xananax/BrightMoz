package Zom.Plugin{

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
	import com.brightcove.api.events.MediaEvent;
	import com.brightcove.api.events.AdEvent;

	import flash.net.*;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.system.LoaderContext;
	import flash.net.URLRequest;
	import flash.display.Sprite;
	import flash.display.Stage;

	import flash.external.ExternalInterface;
	import flash.system.Security;
	import org.osflash.thunderbolt.Logger;
	import Zom.Main.Utils;

	public class Base extends CustomModule{

		// Statics and variables
		protected var _params:Object;
		protected var _video:VideoPlayerModule = null;
		protected var _experience:ExperienceModule = null;
		protected var _content:ContentModule = null;
		protected var _adModule:AdvertisingModule = null;
		protected var _stage:Stage;
		protected var _initLoops:Number = 0;
		protected var _initLoopsNeeded:Number = 2;
		protected static var _jsCallbacks:Object = {};
		protected var _jsNameSpace:String = '';
		protected var _isPlaying:Boolean = false;
		protected var _isBuffering:Boolean = false;
		protected var _isSeeking:Boolean = false;
		protected var _isFullScreen:Boolean = false;
		protected var _adPlaying:Boolean = false;

		public function log(...args):void{
			CONFIG::debug{
				Logger.info.apply(null, args);
			}
		}

		protected function debug(obj:*):String{
			CONFIG::debug{
				return Utils.debug(obj);
			}
			return '';
		}
	
		protected function fnToStr(fn:Function):String{
			CONFIG::debug{
				return Utils.fnToStr(this,fn);
			}
			return '';
		}

		// constructor
		public function Base(){
			Security.allowDomain('*');
			Security.allowInsecureDomain('*');
			//log('id:'+ExternalInterface.objectID+' | available:'+ExternalInterface.available);
			ExternalInterface.marshallExceptions = true;
			registerJs('domReady');
			this.mouseChildren = true;
			addEventListener(Event.ADDED_TO_STAGE,_onAddedToStage);
		}

		protected function _loadParams():void{
			_jsNameSpace = String(_param('jsNameSpace','FlashCommunicator'));
			log('javascript namespace set to '+_jsNameSpace)
			if(_jsNameSpace){_jsNameSpace+='.';}
		}

		protected function _param($param:String=null,$default:*=null):*{
			if(!_params){
				log('loading params');
				_params = LoaderInfo(_stage.loaderInfo).parameters;
			}
			if($param==null){return _params;}
			if(_params[$param]){return _params[$param];}
			return $default;
		}

		public function js_onDomReady(...args):void{
			log('from javascript: Dom is ready');
		}

		public function logChildren(parent:DisplayObjectContainer,parentName:String):void{
			var newName:String;
			var name:String;
			var i:int = 0;
			log(parentName+' children: '+parent.numChildren);
			for(i = 0; i < parent.numChildren; i++){
				name =  (parent.getChildAt(i).name) ? parent.getChildAt(i).name : '['+String(parent.getChildAt(i)).replace('object ','').replace('[','').replace(']','')+']';
				newName = parentName+'.'+ name;
				log(newName);
				if(parent.getChildAt(i) is DisplayObjectContainer){
					logChildren(parent.getChildAt(i) as DisplayObjectContainer, newName);
				}
			}
		}

		// called by BC API
		override protected function initialize():void{
			log('Brightcove Initialize')
			_experience = player.getModule(APIModules.EXPERIENCE) as ExperienceModule;
			_video = player.getModule(APIModules.VIDEO_PLAYER) as VideoPlayerModule;
			_content = player.getModule(APIModules.CONTENT) as ContentModule;
			_adModule = player.getModule(APIModules.ADVERTISING) as AdvertisingModule;
			_stage = _experience.getStage();
			_stage.addEventListener(FullScreenEvent.FULL_SCREEN, _onFullScreenToggle);
			_stage.addEventListener(Event.RESIZE, _onChangeSize);
			_setBrightCoveEvents();
			_stage.addChild(this);
			//this.parent.setChildIndex(this,this.parent.numChildren-1);
		}

		protected function registerJs(...funcs):void{

			var fn:Function;
			var jsName:String;
			var asName:String;
			var callBack:Function;

			for(var i:int=0; i<funcs.length;i++){

				jsName = funcs[i];
				if(!_jsCallbacks[jsName]){_jsCallbacks[jsName] = new Array();}
				asName = 'js_on'+jsName.substr(0,1).toUpperCase()+jsName.substr(1, jsName.length);
				log('registering javascript function '+jsName+' maps to AS3 function '+asName);
				fn = this[asName];

				_jsCallbacks[jsName].push(fn);

				callBack = (function(jsName:String):Function{
					return function(...args):void{
						log('callback '+jsName);
						fromJs(jsName,args);
					};
				})(jsName);

				ExternalInterface.addCallback(jsName,callBack);
			}
		}

		protected function fromJs(fnName:String,args:Array):void{
			if(fnName in _jsCallbacks){
				for(var i:int = 0;i<_jsCallbacks[fnName].length;i++){
					log('calling '+fnName+' which maps to '+fnToStr(_jsCallbacks[fnName][i])+' with args: '+debug(args[0])); 
					_jsCallbacks[fnName][i].apply(null,args);
				}
			}else{
				log(fnName+' not found')
			}
		}

		protected function runJs(fnName:String,arg1:*=null,arg2:*=null,arg3:*=null,arg4:*=null):*{
			return ExternalInterface.call(_jsNameSpace+fnName,arg1,arg2,arg3,arg4);
		}
 
		// called when the object has been added to stage
		protected function _onAddedToStage(evt:Event=null):void{
			removeEventListener(Event.ADDED_TO_STAGE,_onAddedToStage);
			log('added to stage');
			_init();
		}

		protected function _setBrightCoveEvents():void{
			_video.addEventListener(MediaEvent.PLAY,_onMediaPlay);
			_video.addEventListener(MediaEvent.BEGIN,_onMediaBegin);
			_video.addEventListener(MediaEvent.STOP,_onMediaStop);
			_video.addEventListener(MediaEvent.BUFFER_BEGIN,_onBufferBegin);
			_video.addEventListener(MediaEvent.BUFFER_COMPLETE,_onBufferComplete);
			_video.addEventListener(MediaEvent.SEEK,_onSeek);
			_video.addEventListener(MediaEvent.SEEK_NOTIFY,_onSeekComplete);
			_adModule.addEventListener(AdEvent.AD_START, adStartHandler);
			_adModule.addEventListener(AdEvent.AD_COMPLETE, adCompleteHandler);
		}

		protected function _init():void{
			_loadParams();
		}
		
		protected function _onMediaPlay(evt:MediaEvent):void{
			log('Media plays');
			_isPlaying = true;
			dispatchEvent(new ZomEvent(ZomEvent.MEDIA_PLAY));
			dispatchEvent(evt);
		}

		protected function _onMediaBegin(evt:MediaEvent):void{
			log('Media begins');
			_isPlaying = true;
			dispatchEvent(new ZomEvent(ZomEvent.MEDIA_PLAY));
			dispatchEvent(evt);
		}

		protected function _onMediaStop(evt:MediaEvent):void{
			log('Media stopped');
			_isPlaying = false;
			dispatchEvent(new ZomEvent(ZomEvent.MEDIA_STOP));
			dispatchEvent(evt);
		}

		protected function _onBufferBegin(evt:MediaEvent = null):void{
			log('Buffering...');
			_isBuffering = true;
			dispatchEvent(new ZomEvent(ZomEvent.MEDIA_STOP));
			dispatchEvent(evt);
		}

		protected function _onBufferComplete(evt:MediaEvent = null):void{
			log('Buffering complete, resuming state');
			_isBuffering = false;
			dispatchEvent(new ZomEvent(ZomEvent.MEDIA_PLAY));
			dispatchEvent(evt);
		}

		protected function _onSeek(evt:MediaEvent = null):void{
			log('Seek initiated');
			_isSeeking = true;
			dispatchEvent(new ZomEvent(ZomEvent.MEDIA_STOP));
			dispatchEvent(evt);
		}

		protected function _onSeekComplete(evt:MediaEvent = null):void{
			log('Seek complete, resuming state');
			_isSeeking = false;
			dispatchEvent(new ZomEvent(ZomEvent.MEDIA_PLAY));
			dispatchEvent(evt);
		}


		protected function _onFullScreenToggle(evt:FullScreenEvent):void{
			log('fullscreen event')
			if(evt.fullScreen){_onFullScreen(evt);}
			else{_onNormalScreen(evt);}
			dispatchEvent(evt);
			_onResize(evt);
		}

		protected function _onFullScreen(evt:Event):void{_isFullScreen = true;dispatchEvent(evt);}
		protected function _onNormalScreen(evt:Event):void{_isFullScreen = false;dispatchEvent(evt);}
		protected function _onChangeSize(evt:Event):void{_onResize(evt);dispatchEvent(evt);}
		protected function _onResize(evt:Event=null):void{dispatchEvent(evt);}

		protected function _addLoaderEvents(mod:String, loader:Loader):Loader{
			var cont:LoaderInfo = loader.contentLoaderInfo;

			cont.addEventListener(Event.COMPLETE, _onLoaderLoaded);
			cont.addEventListener(Event.INIT, _onLoaderInit);
			cont.addEventListener(IOErrorEvent.IO_ERROR, _onLoaderIOError);
			cont.addEventListener(HTTPStatusEvent.HTTP_STATUS, _onLoaderHttpStatus);
			cont.addEventListener(ProgressEvent.PROGRESS, _onLoaderProgress);

			return loader;
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
			log(mod+' loaded');
		}

		protected function _onLoaderInit(evt:Event):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
			log(mod+' init');
		}

		protected function _onLoaderIOError(evt:IOErrorEvent):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
			log(mod+' failed',evt);
		}

		protected function _onLoaderHttpStatus(evt:HTTPStatusEvent):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
			log(mod+' http status:'+evt.status);
		}

		protected function _onLoaderProgress(evt:ProgressEvent):void{
			var loader:Loader = Loader(LoaderInfo(evt.target).loader);
			var mod:String = loader.name;
			log(mod+' progress');
		}

		protected static function parseDimension(val:*,objDimension:Number,containerDimension:Number):Number{
			if (!isNaN(Number(val))) {
				val = Number(val);
				if(val>0){return val;}
				return containerDimension - val - objDimension;
			}
			switch(val.toLowerCase()){
				case'top':
				case 'left':
					return 0;
					break;
				case 'bottom':
				case 'right':
					return containerDimension - objDimension;
					break;
				case 'center':
				case 'middle':
				case null:
				case false:
				default:
					return Math.round((containerDimension - objDimension) / 2);
					break;
			}
			return 0;
		}

		public function get isPlaying():Boolean{
			return this._isPlaying;
		}

		protected function adStartHandler(evt:AdEvent):void {
			_adPlaying = true;
			dispatchEvent(evt);
		}

		protected function adCompleteHandler(evt:AdEvent):void {
			_adPlaying = false;
			dispatchEvent(evt);
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

	}

}