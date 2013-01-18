package Zom.Main{


	//import org.osflash.thunderbolt.Logger;
	import flash.display.Stage;
	import flash.display.MovieClip;
	import flash.external.ExternalInterface;
	import Zom.Main.Console;

	public class Logger{

		private var _name:String;
		private var _virgin:Boolean = true;
		private static var _stack:Array = [];
		private static var _stage:Stage;

		public static function setStage($s:Stage):void{
			Logger._stage = $s;
			trace('stage set');
			flushStack();
		}

		public static function getStage():Stage{
			return Logger._stage;
		}

		protected static function logToConsole(something:*,level:int=0):void{
			Console.log(something);
		}

		protected static function flushStack():void{
			trace('flushing stack')
			if(_stack.length){
				while(_stack.length){
					logToConsole(_stack.shift());
				}
			}
		}

		protected static function staticLog(something:*,level:int=0):void{
			if(Logger._stage){
				logToConsole(something);
			}else{
				_stack.push(something);
			}
		}

		public function Logger(n:String){
			_name = n;
		}

		public function log(something:*,level:int=0):void{
			CONFIG::debug{
				if(_virgin){
					_virgin = false;
					staticLog(' ---- '+_name+' ---- ')
				}
				staticLog(_name+':'+something);
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
}