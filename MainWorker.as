package  {
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	
	public class MainWorker extends Sprite{


		public function MainWorker() {
			// constructor code
			trace("Worker.current.isPrimordial: " + Worker.current.isPrimordial);
			if(Worker.current.isPrimordial){
				
				var worker:Worker = WorkerDomain.current.createWorker(this.loaderInfo.bytes);
				var b2m:MessageChannel = worker.createMessageChannel(Worker.current);
				var m2b:MessageChannel = Worker.current.createMessageChannel(worker);
				worker.setSharedProperty("b2m", b2m);
				worker.setSharedProperty("m2b", m2b);
				
				b2m.addEventListener(Event.CHANNEL_MESSAGE, onBackToMain);
				
				worker.start();
			
			} else {
				trace("Something is wrong!");
			}

		}
		
		protected function onBackToMain(event:Event){
	
		}

	}
	
}
