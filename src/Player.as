package{

	import Zom.Moz;
	import flash.system.Security;
	
	public class Player extends Moz{

		public function Player():void{
			Security.allowDomain('*');
			Security.allowInsecureDomain('*');
			super();
		}

	}
}