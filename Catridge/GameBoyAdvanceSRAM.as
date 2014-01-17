package Catridge {
	
	public class GameBoyAdvanceSRAM {
		
		public var IOCore;
		public var SRAM;
		
		
		public function GameBoyAdvanceSRAM(IOCore) {
			// constructor code
			this.IOCore = IOCore;
			this.initialize();
		}
		public function initialize() {
			this.SRAM = new Array(0x8000);
		}
		public function load(existingData) {
			var sramLength = existingData.length;
			for (var sramIndex = 0, sramIndex2; sramIndex < 0x8000; ++sramIndex) {
				this.SRAM[sramIndex] = existingData[sramIndex2++];
				sramIndex2 %= sramLength;
			}
		}
		public function read(address) {
			return this.SRAM[address & 0x7FFF];
		}
		public function write(address, data) {
			this.SRAM[address & 0x7FFF] = data | 0;
		}
		
		
		

	}
	
}
