package Zom.Main{

	import Zom.Plugin.Base;
	import Zom.Moz;
	import Zom.Modules.*;
	import Zom.Main.Utils;
	import Zom.Main.Logger;
	import Zom.Events.ZomEvent;

	import flash.display.Stage;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Graphics;

	import flash.geom.Rectangle;

	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import com.greensock.*;
	import com.greensock.loading.*;
	import com.greensock.loading.core.*;
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.display.*;

	import com.greensock.easing.*;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;

	import flash.external.ExternalInterface;

	import flash.system.SecurityDomain;
	import flash.system.Security;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;

	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getDefinitionByName;
	import flash.net.navigateToURL;

	public class Shared{

		protected static var _loggers:Object = {};
		protected static var _ids:int = 0;
		protected static var _loaderContext:LoaderContext;
		protected static var _queue:LoaderMax;
		protected static var _garbage:Object = {};
		protected static var _externalInterfaceSet:Boolean = false;
		protected static var _params:Object = null;
		protected static var _on_load_complete:Array = [];
		protected static var _on_load_error:Array = [];
		protected static var _bitmap:BitmapData;
		public static const LOG_LEVEL_VERBOSE:int = 0;
		public static const LOG_LEVEL_LOG:int = 1;
		public static const LOG_LEVEL_IMPORTANT:int = 2;
		public static const LOG_LEVEL_WARNING:int = 4;
		public static const LOG_LEVEL_ERROR:int = 8;

		/**
		 * Returns the next available unique Id
		 * @return int the id
		 */
		public static function nextId():int{
			var $id:int = _ids;
			_ids++;
			return $id;
		}

		/**
		 * Logs to 'root' level
		 * @param  n:*   anything
		 * @param  level integer, one of LOG_LEVEL_VERBOSE, LOG_LEVEL_LOG, LOG_LEVEL_IMPORTANT, LOG_LEVEL_WARNING or LOG_LEVEL_ERROR
		 */
		public static function log(n:*,level:int=0):void{
			getLogger('root')(n,int);
		}

		/**
		 * Logs an error and returns an error to throw
		 * @param  n        String the name of the logger
		 * @param  $message String the error message
		 * @return          Error
		 */
		public static function error(n:String,$message:String):Error{
			var err:Error = new Error($message)
			getLogger(n)($message,Shared.LOG_LEVEL_ERROR);
			return err;
		}

		/**
		 * Returns the logger at n, or creates a new one
		 * @param  n String the name of the logger
		 * @return Function the log function
		 */
		public static function getLogger(n:String):Function{
			if(!n in _loggers){_loggers[n] = new Logger(n);}
			return _loggers[n].log;
		}

		/**
		 * Returns the loading queue
		 * @return LoaderMax
		 */
		public static function getQueue():LoaderMax{
			if(!_queue){
				LoaderMax.activate([ImageLoader, SWFLoader]);
				_queue = new LoaderMax({
					name:"mainQueue"
				,	onComplete:Shared.onLoaderComplete
				,	onError:Shared.onLoaderError
				,	auditSize:false
				,	autoLoad:false
				,	defaultContext:Shared.getLoaderContext()
				});
			}
			return _queue;
		}

		/**
		 * Returns the length of the queue of assets to load
		 * @return the length
		 */
		public static function queueLength():int{
			return Shared.getQueue().numChildren;
		}

		/**
		 * Begins the general loading of assets
		 */
		public static function beginLoading():void{
			Shared.getQueue().load();
		}

		/**
		 * Called when all assets in the loader queue have loaded
		 * @param  e the event
		 */
		protected static function onLoaderComplete(e:LoaderEvent):void{
			for(var i:int=0;i<_on_load_complete.length;i++){
				_on_load_complete[i](e);
			}
		}

		/**
		 * Called when an asset in the loader queue has an error
		 * @param  e the event
		 */
		protected static function onLoaderError(e:LoaderEvent):void{
			for(var i:int=0;i<_on_load_error.length;i++){
				_on_load_error[i](e);
			}
		}

		/**
		 * TODO: wtf is going on
		 * @param  fn     [description]
		 * @param  remove [description]
		 * @return        [description]
		 */
		public static function onLoadComplete(fn:Function,remove:Boolean = false):Boolean{
			if(remove){
				var $i:int = _on_load_complete.indexOf(remove);
				if($i>=0){
					_on_load_complete.splice($i,1);
					return true;
				}
				return false;
			}
			_on_load_complete.push(fn);
			return true;
		}

		/**
		 * TODO: wtf is going on
		 * @param  fn     [description]
		 * @param  remove [description]
		 * @return        [description]
		 */
		public function onLoadError(fn:Function,remove:Boolean = false):Boolean{
			if(remove){
				var $i:int = _on_load_error.indexOf(remove);
				if($i>=0){
					_on_load_error.splice($i,1);
					return true;
				}
				return false;
			}
			_on_load_error.push(fn);
			return true;
		}

		/**
		 * Sets security to allow all domains
		 */
		public static function setSecurity():void{
			Security.allowDomain('*');
			Security.allowInsecureDomain('*');
		}

		/**
		 * Utility function to overwrite dynamic properties of an object with another
		 * @param  obj1 Object the object to write over
		 * @param  obj2 Object the object to write from
		 * @return       Object returns obj1
		 */
		public static function extendObject(obj1:Object,obj2:Object):Object{
			for(var n:String in obj2){
				obj1[n] = obj2[n];
			}
			return obj1;
		}

		/**
		 * Creates a new LoaderMax instance and appends it to the default queue
		 * @param  name       String
		 * @param  properties Object
		 * @return            LoaderMax
		 */
		public static function getLoader(name:String='',properties:Object = null):LoaderMax{
			var $props:Object = {
					name:name
				,	auditSize:false
				,	autoLoad:false
				,	defaultContext:Shared.getLoaderContext()
			}
			if(properties){
				extendObject($props,properties);
			}
			var $loader:LoaderMax = new LoaderMax($props);
			Shared.getQueue().append($loader);
			return $loader;
		}

		/**
		 * Will automatically parse the url and try to create an ImageLoader or an SWFLoader accordingly
		 * @param  url                  String the url to load
		 * @param  complete             Function function to call when loading is successful
		 * @param  additionalProperties An object of properties (refer to LoaderMax documentation)
		 * @param  $queue               LoaderMax an instance of LoaderMax to append the loader to. If none provided, the default one will be used
		 * @return                      LoaderMax a LoaderMax Instance
		 */
		public static function load(url:String,complete:Function=null,additionalProperties:Object=null,$queue:LoaderMax=null):LoaderCore{
			var $props:Object = {
				onComplete: complete
			,	name:'loader'+(_ids++)
			,	auditSize:false
			};
			if(!$queue){$queue = Shared.getQueue();}
			if(additionalProperties){extendObject($props,additionalProperties);}
			var $loader:LoaderCore = LoaderMax.parse(url,$props);
			$queue.append($loader);
			return $loader;
		}

		/**
		 * Loads an image
		 * @param  url                  String the url to load
		 * @param  complete             Function function to call when loading is successful
		 * @param  additionalProperties An object of properties (refer to LoaderMax documentation)
		 * @param  $queue               LoaderMax an instance of LoaderMax to append the loader to. If none provided, the default one will be used
		 * @return                      ImageLoader an ImageLoader instance
		 */
		public static function loadImage(url:String,complete:Function=null,additionalProperties:Object=null,$queue:LoaderMax=null):ImageLoader{
			var $props:Object = {
				onComplete: complete
			,	name:'swf'+(_ids++)
			,	auditSize:false
			};
			if(!$queue){$queue = Shared.getQueue();}
			if(additionalProperties){extendObject($props,additionalProperties);}
			var $img:ImageLoader = new ImageLoader(url,$props);
			$queue.append($img);
			return $img;
		}	

		/**
		 * Loads an SWF
		 * @param  url                  String the url to load
		 * @param  complete             Function function to call when loading is successful
		 * @param  additionalProperties An object of properties (refer to LoaderMax documentation)
		 * @param  $queue               LoaderMax an instance of LoaderMax to append the loader to. If none provided, the default one will be used
		 * @return                      SWFLoader a SWFLoader instance
		 */
		public static function loadSWF(url:String,complete:Function=null,additionalProperties:Object=null,$queue:LoaderMax=null):SWFLoader{
			var $props:Object = {
				onComplete: complete
			,	name:'img'+(_ids++)
			,	auditSize:false
			};
			if(!$queue){$queue = Shared.getQueue();}
			if(additionalProperties){extendObject($props,additionalProperties);}
			var $swf:SWFLoader = new SWFLoader(url,$props);
			$queue.append($swf);
			return $swf;
		}

		/**
		 * returns a loader context
		 * @return LoaderContext a context to use in loaders
		 */
		public static function getLoaderContext():LoaderContext{
			if(!_loaderContext){
				_loaderContext = new LoaderContext();
				_loaderContext.applicationDomain = ApplicationDomain.currentDomain;
				_loaderContext.securityDomain = SecurityDomain.currentDomain;
			}
			return _loaderContext;
		}

		/**
		 * Tweens one or several properties of an object over time
		 * @param  obj   DisplayObject
		 * @param  time  Number time in seconds
		 * @param  props Object an object of properties (refer to TweenLite documentation)
		 * @return       TweenLite a TweenLite Instance
		 */
		public static function tween(obj:DisplayObject,time:Number,props:Object):TweenLite{
			var $tween:TweenLite = new TweenLite(obj,time,props);
			return $tween; 
		}

		/**
		 * Changes an object's opacity
		 * @param  obj                  DisplayObject
		 * @param  to                   Number final alpha value
		 * @param  time                 Number time in seconds
		 * @param  removeIfInvisible    Boolean if true, will set "visible = false" at the end of the tween if the final valus is 0. Defaults to true
		 * @param  additionalProperties Object an object of properties (refer to Tweenlite documentation)
		 * @return                      TweenLite a TweenLite Instance
		 */
		public static function opacity(obj:DisplayObject,to:int,time:Number=0.3,removeIfInvisible:Boolean = true,additionalProperties:Object = null):TweenLite{
			var $props:Object = {
				alpha:to
			};
			if(to>=0 && obj.visible == false){obj.visible = true;}
			if(additionalProperties){extendObject($props,additionalProperties);}
			else if(removeIfInvisible && to <=0){
				$props.onComplete = _makeHideCallback($props.onComplete || null);
			}
			return tween(obj,time,$props);
		}

		protected static function _makeHideCallback(fn:Function=null):Function{
			return function(alpha:Number,obj:DisplayObject):void{
				if(alpha<=0){obj.visible=false;}
				if(fn !== null){fn(alpha,obj);}
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
		public static function hide(obj:DisplayObject,time:Number=0.3,delay:Number=0, removeIfInvisible:Boolean = true):TweenLite{
			return opacity(obj,0,time,removeIfInvisible, {delay:delay});
		}

		/**
		 * Shows an object. If "visible" was set to false, it sets it to true before
		 * @param  obj               DisplayObject
		 * @param  time              Number the time in seconds
		 * @param  delay             Number a delay time in seconds before showing the object
		 * @return                   TweenLite a TweenLite Instance
		 */
		public static function show(obj:DisplayObject,time:int=0.3,delay:Number=0):TweenLite{
			return opacity(obj,1,time,false,{delay:delay});
		}

		/**
		 * Parses a string into a value
		 * @param  val:*              the value. Might be one of "top", "left", "bottom", "right", "center", "middle", a percentage, or a number
		 *                            note: when using percents, the object's middle will be considered as registration point
		 * @param  objDimension       The object's relevant dimension (width or height)
		 * @param  containerDimension The object's container relevant dimension (width or height)
		 * @return                    Number the number you should set
		 */
		protected static function parseDimension(val:*,objDimension:Number,containerDimension:Number):Number{
			if (!isNaN(Number(val))) {
				val = Number(val);
				if(val>0){return val;}
				return containerDimension - val - objDimension;
			}
			if(val.indexOf('%')>=0){
				val = Number(val.replace('%',''));
				if(isNaN(val)){return 0;}
				return Math.round(((val/100) * containerDimension) - objDimension/2);
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

		/**
		 * Places an object in another according to x and y values. Values can be a number, a percentage, or a string such
		 * as "top", "left", "bottom", "right", "center", or "middle"
		 * @param  values    * a param string ('x=center&y=50'), an array ['20%','top'], or an object {x:150,y:'bottom'}
		 * @param  Obj       DisplayObject the object to place
		 * @param  container DisplayObject the object to place into
		 * @return           void
		 */
		public static function place(values:Object,obj:DisplayObject, container:DisplayObject):void{
			var $x:*=null,$y:*=null, $type:String = getQualifiedClassName(values);
			if($type == 'String'){
				var urlVars:URLVariables = new URLVariables();
				urlVars.decode(values as String);
				$x = urlVars.x;
				$y = urlVars.y;
			}
			else if($type == 'Array'){
				$x = values[0];
				if(values.length>1){
					$y = values[1];
				}
			}
			else{
				if('x' in values){
					$x = values.x;
				}
				if('y' in values){
					$y = values.y;
				}
			}
			if($x!==null){
				obj.x = parseDimension($x,obj.width,container.width);
			}
			if($y!==null){
				obj.y = parseDimension($y,obj.height,container.height);
			}
		}

		/**
		 * Used internally to check if ExternalInterface is available and set it to marshall exceptions
		 */
		protected static function _setExternalInterface():Boolean{
			if(ExternalInterface.available){
				if(!_externalInterfaceSet){
					ExternalInterface.marshallExceptions = true;
					_externalInterfaceSet = true;
				}
			}
			return ExternalInterface.available;
		}

		/**
		 * Makes a method available to javascript.
		 * @param  obj        Object The object containing the method
		 * @param  methodName String the method name. If a method with a similar name but beginning with "js_" is found in the object
		 *                    it will be used instead
		 * @return            void
		 */
		public static function exportMethod(obj:Object,methodName:String):void{
			if(_setExternalInterface()){
				var $method:* = obj['js_'+methodName];
				if(!$method || !($method is Function)){
					$method = obj[methodName];
				}
				if(!$method || !($method is Function)){return;}
				var $callback:Function = function(args:Array):void{
					try{
						($method as Function).apply(obj,args);
					}catch(e:Error){
						log('error trying to call '+methodName+' from javascript:' + e.message,LOG_LEVEL_ERROR);
					}
				}
				_garbage[nextId()] = $callback;
				ExternalInterface.addCallback(methodName,$callback);
			}
		}

		/**
		 * Calls a Js method
		 * @param  methodName String the name of the method
		 * @param  args       Array an array of arguments
		 * @param  callBack   Function  function to call when the method returns
		 * @return            * the returning value from the call, or an Error if the call failed
		 */
		public static function callJs(methodName:String,args:Object=null,callBack:Function=null):*{
			var $ret:*;
			if(_setExternalInterface()){
				try{
					$ret = ExternalInterface.call(methodName,args,callBack)
				}catch(e:Error){
					log('error trying to call javascript function '+methodName+':'+e.message,LOG_LEVEL_ERROR);
					$ret = e;
				}
			}
			return $ret;
		}

		/**
		 * Loads a parameter from the flashvars
		 * @param  stage      Stage main stage to load the parameters from
		 * @param  param      String the param name
		 * @param  def:*=null * Default value of the parameter
		 * @return            returns the param, if found, or the default value
		 */
		public static function param(stage:Stage, param:String=null,def:*=null):*{
			if(!_params){
				_params = LoaderInfo(stage.loaderInfo).parameters;
			}
			if(param==null){return _params;}
			if(_params[param]){return _params[param];}
			return def;
		}

		/**
		 * Loads a set of parameters from the flashvars, optionally adding a namespace to them (so parameter 'x' is loaded from flashvar 'movie_x' for example)
		 * @param  stage     Stage the stage to load the parameters from
		 * @param  params    Object an object of properties
		 * @param  namespace String an optional namespace. Don't include the trailing "_", as it will be added
		 * @return           void
		 */
		public static function loadParams(stage:Stage, params:Object, $namespace:String=''):void{
			var parameter:String;
			if($namespace){$namespace+='_';}
			for(parameter in params){
				if(parameter.indexOf('_') == 0){continue;}
				params[parameter] = param(stage,$namespace+parameter,params[parameter]);
			}
		}

		/**
		 * Runs the specified function when the object is added to stage
		 * @param  Obj    EventDispatcher the object to listen to
		 * @param  func:* String|Function a function or the name of a function (in which case it will be assumed to be public and found in Obj)
		 * @return        void
		 */
		public static function onReadyInit(obj:EventDispatcher,func:*='onAddedToStage'):void{
			var $func:Function = (func is Function)?
				$func = func
				:(func is String && obj[func] && obj[func] is Function)?
					obj[func]
					:null
			;
			if(!($func is Function)){
				log('Error: could not set onReady callback '+func+' for '+obj);
				return;
			}
			var $onAddedToStage:Function = function(e:Event):void{
				obj.removeEventListener(Event.ADDED_TO_STAGE,$onAddedToStage)
				$func();
			}
			obj.addEventListener(Event.ADDED_TO_STAGE,$onAddedToStage);
		}

		/**
		 * Opens a browser window with the specified url
		 * @param  url        String the url to go to
		 * @param  target     String defaults to "_blank"
		 */
		public static function openWindow(url:String,target:String="_blank"):void{
			if(url!==''){
				//var req:URLRequest = new URLRequest(url);
				//navigateToURL(req, '_blank');
				var jscommand:String = "window.open('"+url+"','_blank');"; 
				var req:URLRequest = new URLRequest("javascript:" + jscommand + " void(0);"); 
				navigateToURL(req, "_self");
			}
		}

		/**
		 * Returns a Class object from a string
		 * @param  $str the name of the class
		 * @return      the Class object
		 */
		public static function classFromName($str:String):Class{
			try{
				return getDefinitionByName($str) as Class;
			}catch(e:Error){
				error('root','no class exists by the name '+$str);
			}
			return null;
		}

		/**
		 * Splits a string by a delimiter, cleaning up the resulting array (removing empty values)
		 * @param  $str      String the string to split
		 * @param  $splitter String the delimiter
		 * @return           Array the cleaned up array
		 */
		public static function splitString($str:String,$splitter:String='||'):Array{
			return $str.split($splitter).filter(splitStringFilter);
		}

		/**
		 * Used internally as the filter of splitString()
		 * @param  item:* anything
		 * @param  index  the current index in the loop
		 * @param  array  the current array being processed
		 * @return        
		 */
		protected static function splitStringFilter(item:*, index:int, array:Array):Boolean{
			return item != "";
		}

		/**
		 * Creates a rectangle according to the size of the visible area of the display object provided
		 * @param  $canvas DisplayObject
		 * @return         Rectangle the bounding box of the visible area
		 */
		public static function getVisibleArea($canvas:DisplayObject):Rectangle{
			_bitmap = new BitmapData($canvas.width,$canvas.height,true,0);
			_bitmap.draw($canvas);
			var rect:Rectangle = _bitmap.getColorBoundsRect(0xff000000,0xff000000,false);
			rect.x = $canvas.x;
			rect.y = $canvas.y;
			return rect;
		}

	}

}