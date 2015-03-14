package  {
	import flash.system.MessageChannel;
	import flash.display.Sprite;
	import flash.system.Worker;
	import flash.events.Event;
	
	public class BackWorker extends Sprite{
		
		private var b2m:MessageChannel;
		private var m2b:MessageChannel;
		
		public function BackWorker() {
			// constructor code
			b2m = Worker.current.getSharedProperty("b2m");
			m2b = Worker.current.getSharedProperty("m2b");
			
			m2b.addEventListener(Event.CHANNEL_MESSAGE, onMainToBack);
			
		}
		
		protected function onMainToBack(event:Event){
			
		}

	}
	
}
