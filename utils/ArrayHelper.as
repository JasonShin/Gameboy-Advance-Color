package utils {
	
	public class ArrayHelper {

		public function ArrayHelper() {
			// constructor code
		}
		
		public static function buildArray(size) {
			var ar:Array = new Array(size);
			for(var i = 0; i < ar.length; i++){
				ar[i] = 0;
			}
			return ar;
			
		}

	}
	
}
