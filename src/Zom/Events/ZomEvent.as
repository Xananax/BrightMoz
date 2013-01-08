package Zom.Events{
	
	import flash.events.Event;

	public class ZomEvent extends Event{

		public static const MEDIA_PLAY:String = 'zom_media_plays';
		public static const MEDIA_STOP:String = 'zom_media_stops';

		public function ZomEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false){
			super(type,bubbles,cancelable);
		}

		override public function clone():Event {
			return new ZomEvent(type, bubbles, cancelable);
		}

	}

}