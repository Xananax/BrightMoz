package Zom.Main{


	import org.osflash.thunderbolt.Logger;

	public class Logger{

		private var _name:String;
		private var _virgin:Boolean = true;

		public function Logger(n:String){
			_name = n;
		}

		public function log(something:*,level:int=0):void{
			CONFIG::debug{
				if(_virgin){
					_virgin = false;
					org.osflash.thunderbolt.Logger.info(' ---- '+_name+' ---- ');
				}
				something = _name+':'+something;
				org.osflash.thunderbolt.Logger.info(something);
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