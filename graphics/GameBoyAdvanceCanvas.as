package graphics {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	public class GameBoyAdvanceCanvas extends Bitmap {
		public var canvas:Bitmap;
		public var canvasBuffer:BitmapData;
		public var canvasX;
		public var canvasY;
		public var canvasWidth:int;
		public var canvasHeight:int;
		
		public function GameBoyAdvanceCanvas(w,h) {
			// constructor code
			this.canvasWidth = w;
			this.canvasHeight = h;
			canvasBuffer = new BitmapData(canvasWidth, canvasHeight, false);
			this.bitmapData = canvasBuffer;
		}
		
		public function setPixel(xVal,yVal,colour){
			canvasBuffer.lock();
			canvasBuffer.setPixel(xVal,yVal,colour);
			canvasBuffer.unlock();
		}

	}
	
}
