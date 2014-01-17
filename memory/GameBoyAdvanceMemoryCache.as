package memory {
	
	public class GameBoyAdvanceMemoryCache {
		
		public var memoryCore:GameBoyAdvanceMemory;
		public var addressRead16;
		public var addressRead32;
		public var addressWrite16;
		public var addressWrite32;
		public var cacheRead16;
		public var cacheRead32;
		public var cacheWrite16;
		public var cacheWrite32;
		
		public function GameBoyAdvanceMemoryCache(mem:GameBoyAdvanceMemory) {
			//Build references:
			this.memoryCore = mem;
			this.addressRead16 = 0xFF;
			this.addressRead32 = 0xFF;
			this.addressWrite16 = 0xFF;
			this.addressWrite32 = 0xFF;
			
			this.cacheRead16 = this.memoryCore.readUnused16;
			this.cacheRead32 = this.memoryCore.readUnused32;
			this.cacheWrite16 = this.memoryCore.writeUnused16;
			this.cacheWrite32 = this.memoryCore.writeUnused32;
			
		}
		
		public function memoryReadFast16(address) {
			address = address >>> 0;
			if ((address >>> 24) != (this.addressRead16 >>> 0)) {
				this.addressRead16 = address >>> 24;
				this.cacheRead16 = this.memoryCore.memoryReader16[address >>> 24];
			}
			return this.cacheRead16(this.memoryCore, address >>> 0) | 0;
		}
		public function memoryReadFast32(address) {
			address = address >>> 0;
			if ((address >>> 24) != (this.addressRead32 >>> 0)) {
				this.addressRead32 = address >>> 24;
				this.cacheRead32 = this.memoryCore.memoryReader32[address >>> 24];
			}
			return this.cacheRead32(this.memoryCore, address >>> 0) | 0;
		}
		public function memoryWriteFast16(address, data) {
			address = address >>> 0;
			data = data | 0;
			if ((address >>> 24) != (this.addressWrite16 >>> 0)) {
				this.addressWrite16 = address >>> 24;
				this.cacheWrite16 = this.memoryCore.memoryWriter16[address >>> 24];
			}
			this.cacheWrite16(this.memoryCore, address >>> 0, data | 0);
		}
		public function memoryWriteFast32(address, data) {
			address = address >>> 0;
			data = data | 0;
			if ((address >>> 24) != (this.addressWrite32 >>> 0)) {
				this.addressWrite32 = address >>> 24;
				this.cacheWrite32 = this.memoryCore.memoryWriter32[address >>> 24];
			}
			this.cacheWrite32(this.memoryCore, address >>> 0, data | 0);
		}
		public function memoryRead16(address) {
			address = address >>> 0;
			//Half-Word Read:
			if ((address & 0x1) == 0) {
				//Use optimized path for aligned:
				return this.memoryReadFast16(address >>> 0) | 0;
			}
			else {
				return this.memoryCore.memoryRead16Unaligned(address >>> 0) | 0;
			}
		}
		public function memoryRead32(address) {
			address = address >>> 0;
			//Word Read:
			if ((address & 0x3) == 0) {
				//Use optimized path for aligned:
				return this.memoryReadFast32(address >>> 0) | 0;
			}
			else {
				return this.memoryCore.memoryRead32Unaligned(address >>> 0) | 0;
			}
		}
		public function memoryWrite16(address, data) {
			address = address >>> 0;
			data = data | 0;
			//Half-Word Write:
			if ((address & 0x1) == 0) {
				//Use optimized path for aligned:
				this.memoryWriteFast16(address >>> 0, data | 0);
			}
			else {
				this.memoryCore.memoryWrite16Unaligned(address >>> 0, data | 0);
			}
		}
		public function memoryWrite32(address, data) {
			address = address >>> 0;
			data = data | 0;
			//Word Write:
			if ((address & 0x3) == 0) {
				//Use optimized path for aligned:
				this.memoryWriteFast32(address >>> 0, data | 0);
			}
			else {
				this.memoryCore.memoryWrite32Unaligned(address >>> 0, data | 0);
			}
		}
		

	}
	
}
