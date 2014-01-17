package sound {
	import utils.ArrayHelper;
	
	public class GameBoyAdvanceFIFO {

		public var buffer;
		public var count;
		public var position;

		public function GameBoyAdvanceFIFO() {
			// constructor code
			this.initializeFIFO();
		}
		
		
		public function initializeFIFO() {
			this.buffer = ArrayHelper.buildArray(0x20);
			this.count = 0;
			this.position = 0;
		}
		public function push(sample) {
			sample = sample | 0;
			var writePosition = ((this.position | 0) + (this.count | 0)) | 0;
			this.buffer[writePosition & 0x1F] = (sample << 24) >> 24;
			if ((this.count | 0) < 0x20) {
				//Should we cap at 0x20 or overflow back to 0 and reset queue?
				this.count = ((this.count | 0) + 1) | 0;
			}
		}
		public function shift() {
			var output = 0;
			if ((this.count | 0) > 0) {
				this.count = ((this.count | 0) - 1) | 0;
				output = this.buffer[this.position & 0x1F] << 3;
				this.position = ((this.position | 0) + 1) & 0x1F;
			}
			return output | 0;
		}
		public function requestingDMA() {
			return (this.count <= 0x10);
		}
		
		

	}
	
}
