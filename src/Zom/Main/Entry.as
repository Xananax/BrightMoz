package Zom.Main{

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.Security;

	public class Entry extends Sprite{

		public function Entry():void{
            Security.allowDomain("*");
			if (stage){_isAddedToStage();}
			else addEventListener(Event.ADDED_TO_STAGE, _isAddedToStage);
		}
		
		private function _isAddedToStage(e:Event = null):void{
			removeEventListener(Event.ADDED_TO_STAGE, _isAddedToStage);
			init();
		}

		protected function init():void{
		}		

		
	}
}
