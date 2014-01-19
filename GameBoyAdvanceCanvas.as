package {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	import flash.geom.Rectangle;
	
	public class GameBoyAdvanceCanvas extends Bitmap {
		//PUBLIC:
		public var bm:Bitmap;
		public var bmData:BitmapData;
		public var canvasX;
		public var canvasY;
		public var canvasWidth:int;
		public var canvasHeight:int;
		
		//PRIVATE
		private var rect:Rectangle;
		/*
			RULE: 4 segments per pixel
			0 = Alpha
			1 = Red
			2 = Green
			3 = Blue
		*/
		private var bitmapBuffer:ByteArray;
		
		public function GameBoyAdvanceCanvas(w,h) {
			// constructor code
			this.canvasWidth = w;
			this.canvasHeight = h;
			bmData = new BitmapData(canvasWidth, canvasHeight, true, 0xFFCCCCCC);
			rect = new Rectangle(0,0,canvasWidth,canvasHeight);
			bitmapBuffer = bmData.getPixels(rect);
			this.bitmapData = bmData;
			bitmapBuffer.position = 0;
		}
		
		public function setPixel(xVal,val){
			this.bitmapBuffer[xVal] = val;
		}
		
		public function getBufferLength(){
			return bitmapBuffer.length;
		}
		
		public function setSeg(i,v){
			bitmapBuffer[i] = v;
		}
		
		public function refresh(){
			bitmapBuffer.position = 0;
			bmData.setPixels(rect, bitmapBuffer);
			this.bitmapData = bmData;
		}
		
		public function setPixels(buf:ByteArray){
			
			buf.position = 0;
			bmData.setPixels(rect, buf);
			this.bitmapData = bmData;
		}
		
		public function getBuffer():ByteArray{
			
			return bitmapBuffer;
		}
		

	}
	
}
