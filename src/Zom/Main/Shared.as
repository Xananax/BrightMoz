Package Zom.Main{

	import Zom.Plugin.Base;
	import Zom.Moz;
	import Zom.Modules.*;
	import Zom.Main.Utils;
	import Zom.Events.ZomEvent;

	import org.osflash.thunderbolt.Logger;

	import flash.display.Stage;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Bitmap;
	import flash.display.Sprite;

	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import com.greensock.*;
	import com.greensock.loading.*;
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.display.*;

	import com.greensock.easing.*;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.HTTPStatusEvent
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.events.EventDispatcher;

	import fl.transitions.Tween;
	import fl.transitions.easing.*;
	import fl.transitions.TweenEvent;

	import flash.external.ExternalInterface;

	import flash.system.SecurityDomain;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;

	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;

	private class Logger{

		private var _name:String;
		private var _virgin:Boolean = true;

		public function Logger(n:String){
			_name = n;
		}

		public function log(something:*,level:int=0):void{
			CONFIG::debug{
				if(_virgin){
					_virgin = false;
					Logger.info(' ---- '+_name+' ---- ');
				}
				something = _name+':'+something;
				Logger.info(something);
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

	}

	public class Shared{

		protected static var _loggers:Object = {};
		protected static var _ids:int = 0;
		protected static var _loaderContext:LoaderContext;
		protected static var _queue:LoaderMax;
		protected static var _garbage:Object = {};
		protected static var _externalInterfaceSet:Boolean = false;
		protected static var urlVars:URLVariables = new URLVariables();
		protected static const LOG_LEVEL_VERBOSE = 0;
		protected static const LOG_LEVEL_LOG = 1;
		protected static const LOG_LEVEL_IMPORTANT = 2;
		protected static const LOG_LEVEL_WARNING = 4;
		protected static const LOG_LEVEL_ERROR = 8;

		/**
		 * Returns the next available unique Id
		 * @return int the id
		 */
		public static function nextId():int{
			var $id:int = ids;
			ids++;
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
		public static function get queue():LoaderMax{
			if(!_queue){
				LoaderMax.activate([ImageLoader, SWFLoader]);
				_queue = new LoaderMax({
					name:"mainQueue"
				,	onComplete:completeHandler
				,	onError:errorHandler
				,	auditSize:false
				,	autoLoad:true
				,	defaultContext:loaderContext
				});
			}
			return _queue;
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
		 * Will automatically parse the url and try to create an ImageLoader or an SWFLoader accordingly
		 * @param  url                  String the url to load
		 * @param  complete             Function function to call when loading is successful
		 * @param  additionalProperties An object of properties (refer to LoaderMax documentation)
		 * @return                      LoaderMax a LoaderMax Instance
		 */
		public static function load(url:String,complete:Function,additionalProperties:Object=null):LoaderMax{
			var $props = {
				onComplete: complete
			,	name:'loader'+(_ids++)
			,	auditSize:false
			};
			if(additionalProperties){extendObject($props,additionalProperties);}
			var $loader:LoaderMax = new LoaderMax(url,$props);
			queue.append($loader);
			return $loader;
		}

		/**
		 * Loads an image
		 * @param  url                  String the url to load
		 * @param  complete             Function function to call when loading is successful
		 * @param  additionalProperties An object of properties (refer to LoaderMax documentation)
		 * @return                      ImageLoader an ImageLoader instance
		 */
		public static function loadImage(url:String,complete:Function,additionalProperties:Object=null):ImageLoader{
			var $props = {
				onComplete: complete
			,	name:'swf'+(_ids++)
			,	auditSize:false
			};
			if(additionalProperties){extendObject($props,additionalProperties);}
			var $img:ImageLoader = new ImageLoader(url,$props);
			queue.append($img);
			return $img;
		}	

		/**
		 * Loads an SWF
		 * @param  url                  String the url to load
		 * @param  complete             Function function to call when loading is successful
		 * @param  additionalProperties An object of properties (refer to LoaderMax documentation)
		 * @return                      SWFLoader a SWFLoader instance
		 */
		public static function loadSWF(url:String,complete:Function,additionalProperties:Object=null):SWFLoader{
			var $props = {
				onComplete: complete
			,	name:'img'+(_ids++)
			,	auditSize:false
			};
			if(additionalProperties){extendObject($props,additionalProperties);}
			var $swf:ImageLoader = new ImageLoader(url,$props);
			queue.append($swf);
			return $swf;
		}

		/**
		 * returns a loader context
		 * @return LoaderContext a context to use in loaders
		 */
		public static function get loaderContext():LoaderContext{
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

		protected static function _makeHideCallback(fn:Function=null):void{
			return function(alpha:Number,Obj:DisplayObject){
				if(alpha<=0){obj.visible=false;}
				if(fn){fn(alpha,obj);}
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
		protected static function place(values:Object,Obj:DisplayObject, container:DisplayObject):void{
			var $x:*=null,$y:*=null, $type:String = getQualifiedClassName(values);
			if($type == 'String'){
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
					y = values.y;
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
			if(_setExternalInterface){
				var $method = obj['js_'+methodName];
				if(!$method || !($method is Function)){
					$method = obj[methodName];
				}
				if(!$method || !($method is Function)){return;}
				var $callback = function(args:Array){
					try{
						$method.apply(obj,args);
					}catch(e:Error){
						log('error trying to call '+methodName+' from javascript:' + e.message,LOG_LEVEL_ERROR);
					}
				}
				_garbage[nextId()] = $callBack;
				ExternalInterface.addCallback(methodName,$callback);
			}
		}

		public static function callJs(methodName:String,args:Object=null,callBack:function):void{
			if(_setExternalInterface){
				try{
					ExternalInterface.call(methodName,args,callBack)
				}catch(e:Error){
					log('error trying to call javascript function '+methodName+':'+e.message,LOG_LEVEL_ERROR);
				}
			}
		}

	}

}