package Zom.Widgets{
	
	import flash.display.Shape;

	public class Pie extends Shape{

		protected var _radius:Number = 0;
		protected var _bc    :int    = 0;
		protected var _fc    :int    = 0;
		protected var _bs    :int    = 0;

		public function Pie($radius:Number = 35, $border_size:int = 2, $border_color:int = 0xffffff, $fill_color:int = 0xffffff){
			_radius = $radius;
			_bs     = $border_size;
			_bc     = $border_color;
			_fc     = $fill_color;
			draw(0);
		}

		public function draw($e:Number):void{
			var $end:Number = 2*Math.PI*$e;

			this.graphics.clear();
			this.graphics.lineStyle(_bs,_bc);
			this.graphics.drawCircle(0,0,_radius);
			if ($end != 0){
				this.graphics.lineStyle(0);
				this.graphics.beginFill(_fc);
				this.graphics.lineTo(_radius,0);
				this.curve(0, 0, 0, $end);
				this.graphics.lineTo(0,0);
				this.graphics.endFill();
			}
		}

		private function curve($x:Number, $y:Number, $start:Number, $end:Number):Pie{
			 var diff:Number = Math.abs($end -$start);
			 var divs:Number = Math.floor(diff/(Math.PI/4))+1;
			 var span:Number = -(diff/(2*divs));
			 var rc:Number   = _radius/Math.cos(span);

			 this.graphics.moveTo(Math.cos($start)*_radius, Math.sin($start)*_radius);

			 for (var i:int=0; i<divs; ++i){
				  $end = $start+span;
				  $start = $end+span;
				  this.graphics.curveTo(Math.cos($end)*rc, Math.sin($end)*rc, Math.cos($start)*_radius, Math.sin($start)*_radius);
			 };

			 return this;
		};
	}
}