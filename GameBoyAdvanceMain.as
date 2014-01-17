package  {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import graphics.GameBoyAdvanceCanvas;
	import flash.utils.ByteArray;
	import FileLoader.LocalLoader;
	
	public class GameBoyAdvanceMain extends MovieClip {
		
		var core:EmulatorCore;
		var canvas:GameBoyAdvanceCanvas;
		var fr:LocalLoader;
		
		public function GameBoyAdvanceMain() {
			// constructor code
		}
		
		
		public function init(){
			core = new EmulatorCore();
			canvas = new GameBoyAdvanceCanvas(core.offscreenWidth, core.offscreenHeight);
			core.attachCanvas(canvas);
			fr = new LocalLoader();
			fr.loadROM(romLoadComplete);
		}
		
		
		public function romLoadComplete(dat:ByteArray){
			core.attachROM(dat);
			core.startTimer();
		}
		
	}
	
}
