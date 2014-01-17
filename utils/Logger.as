package utils {
	import flash.utils.describeType;
	
	public class Logger {

		public static var arm = false;
		public static var thumb = false;
		public static var loggable = false;
		public static var memory = false;
		private static var accumLog:String = "";

		public function Logger() {
			// constructor code
		}
		
		public static function functionToString(target:*, f:Function):String
		{
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

		
		public static function logARM(msg){
			if(arm)
				log(msg);
		}
		
		public static function logTHUMB(msg) {
			if(thumb)
				log(msg);
		}
		
		
		public static function logMemory(msg) {
			if(memory)
				log(msg + "\n");
		}
		
		private static function log(msg){
			/*if(loggable)
				trace(msg);*/
			//log to file
		}

	}
	
}
