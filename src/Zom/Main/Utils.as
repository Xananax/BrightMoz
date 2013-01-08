package Zom.Main{

	import flash.utils.describeType;

	public class Utils{

		public static function debug(_obj:Object):String{
            if(_obj){
                var description:XML = describeType(_obj);
                var properties:Array = []; 
                for each(var a:XML in description.accessor){
                    properties.push(a.@name.toString());
                }
 
                for each(var v:XML in description.variable){
                    properties.push(v.@name.toString());
                }
 
                if(description.@isDynamic == "true"){
                    for(var p:String in _obj){
                        properties.push(p);
                    }
                }
                properties.sort(); 
                var desName : String = description.@name;
                var str:String = "[";
 
                str += (desName.search("::") == -1) ? desName : desName.slice(desName.search("::") + 2, desName.length);
                var pL : int = properties.length;
                for(var i : int = 0;i < pL;i++){
                    str += " | " + properties[i] + "=" + _obj[properties[i]];
                }
                str += "]";
 
                return str;
            }
 
            return "";
        }

	public static function fnToStr(target:*, f:Function):String{
		var functionName:String = "error!";
		var type:XML = describeType(target); 
		for each (var node:XML in type..method) {
			if (target[node.@name] == f) {
				functionName = node.@name;
				break;
			}
		}
		return functionName;
	}


    }
}
