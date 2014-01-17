package FileLoader{
	import flash.utils.ByteArray;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.FileReference;
	import flash.net.FileFilter;
	import FileLoader.ROMLoader;

	public class LocalLoader implements ROMLoader {
		
		private var currentCallback:Function;
		private var fr:FileReference;
		private var fileFilter:Array;

		public function LocalLoader() {
			// constructor code
			fr = new FileReference();
			fileFilter = [new FileFilter("GBA Files","*.gba;*.gb")];
			fr.addEventListener(Event.SELECT, onFileSelect);
			fr.addEventListener(Event.CANCEL,onCancel);
		}

		public static function saveFile(msg){
			var bytes:ByteArray = new ByteArray();
			var fileRef:FileReference = new FileReference();
			fileRef.save(msg, "fileName");
		}

		public function loadROM(callback:Function):void {
			currentCallback = callback;
			fr.browse(fileFilter);
			
		}


		//called when the user selects a file from the browse dialog
		private function onFileSelect(e:Event):void {
			//listen for when the file has loaded
			fr.addEventListener(Event.COMPLETE, onLoadComplete);

			//listen for any errors reading the file
			fr.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);

			//load the content of the file
			fr.load();
		}

		private function onCancel(e:Event):void {
			trace("File Browse Canceled");
			fr = null;
		}


		/************ Select Event Handlers **************/

		//called when the file has completed loading
		private function onLoadComplete(e:Event):void {
			//get the data from the file as a ByteArray
			currentCallback(fr.data);	//Byte Array
			
			//clean up the FileReference instance
			fr = null;
		}

		//called if an error occurs while loading the file contents
		private function onLoadError(e:IOErrorEvent):void {
			trace("Error loading file : " + e.text);
		}


	}

}