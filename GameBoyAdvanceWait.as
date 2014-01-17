package  {
	import memory.GameBoyAdvanceMemoryCache;
	
	public class GameBoyAdvanceWait {
		
		public var WRAMConfiguration = [0xD, 0x20];	//WRAM configuration control register current data.
		public var WRAMWaitState = 3;					//External WRAM wait state.
		public var SRAMWaitState = 5;
		public var CARTWaitState0First = 5;
		public var CARTWaitState0Second = 3;
		public var CARTWaitState1First = 5;
		public var CARTWaitState1Second = 5;
		public var CARTWaitState2First = 5;
		public var CARTWaitState2Second = 9;
		public var POSTBOOT = 0;
		public var width = 8;
		public var nonSequential = true;
		public var ROMPrebuffer = 0;
		public var prefetchEnabled = true;
		public var WAITCNT0 = 0;
		public var WAITCNT1 = 0;
		public var getROMRead16;
		public var getROMRead32;
		public var opcodeCache;
		
		
		public var IOCore;
		public var memory;
		
		public function GameBoyAdvanceWait(IOCore) {
			// constructor code
			this.IOCore = IOCore;
			this.memory = this.IOCore.memory;
			this.initialize();
		}
		
		public var GAMEPAKWaitStateTable = [
			5, 4, 3, 9
		];
		public function initialize() {
			this.WRAMConfiguration = [0xD, 0x20];	//WRAM configuration control register current data.
			this.WRAMWaitState = 3;					//External WRAM wait state.
			this.SRAMWaitState = 5;
			this.CARTWaitState0First = 5;
			this.CARTWaitState0Second = 3;
			this.CARTWaitState1First = 5;
			this.CARTWaitState1Second = 5;
			this.CARTWaitState2First = 5;
			this.CARTWaitState2Second = 9;
			this.POSTBOOT = 0;
			this.width = 8;
			this.nonSequential = true;
			this.ROMPrebuffer = 0;
			this.prefetchEnabled = true;
			this.WAITCNT0 = 0;
			this.WAITCNT1 = 0;
			this.getROMRead16 = this.getROMRead16Prefetch;
			this.getROMRead32 = this.getROMRead32Prefetch;
			this.opcodeCache = new GameBoyAdvanceMemoryCache(this.memory);
		}
		public function writeWAITCNT0(data) {
			this.SRAMWaitState = this.GAMEPAKWaitStateTable[data & 0x3];
			this.CARTWaitState0First = this.GAMEPAKWaitStateTable[(data >> 2) & 0x3];
			this.CARTWaitState0Second = ((data & 0x10) == 0x10) ? 0x2 : 0x3;
			this.CARTWaitState1First = this.GAMEPAKWaitStateTable[(data >> 5) & 0x3];
			this.CARTWaitState1Second = (data > 0x7F) ? 0x2 : 0x5;
			this.WAITCNT0 = data;
			//this.IOCore.cpu.dynarec.invalidateCaches();
		}
		public function readWAITCNT0() {
			return this.WAITCNT0;
		}
		public function writeWAITCNT1(data) {
			this.CARTWaitState2First = this.GAMEPAKWaitStateTable[data & 0x3];
			this.CARTWaitState2Second = ((data & 0x8) == 0x8) ? 0x2 : 0x9;
			this.prefetchEnabled = ((data & 0x40) == 0x40);
			if (!this.prefetchEnabled) {
				this.ROMPrebuffer = 0;
				this.getROMRead16 = this.getROMRead16NoPrefetch;
				this.getROMRead32 = this.getROMRead32NoPrefetch;
			}
			else {
				this.getROMRead16 = this.getROMRead16Prefetch;
				this.getROMRead32 = this.getROMRead32Prefetch;
			}
			this.WAITCNT1 = data;
			//this.IOCore.cpu.dynarec.invalidateCaches();
		}
		public function readWAITCNT1() {
			return this.WAITCNT1 | 0x20;
		}
		public function writePOSTBOOT(data) {
			this.POSTBOOT = data;
		}
		public function readPOSTBOOT() {
			return this.POSTBOOT;
		}
		public function writeHALTCNT(data) {
			//HALT/STOP mode entrance:
			this.IOCore.flagStepper((data < 0x80) ? 2 : 4);
		}
		public function writeConfigureWRAM(address, data) {
			switch (address & 0x3) {
				case 3:
					this.WRAMConfiguration[1] = data & 0x2F;
					this.IOCore.remapWRAM(data);
					break;
				case 0:
					this.WRAMWaitState = 0x10 - (data & 0xF);
					this.WRAMConfiguration[0] = data;
			}
		}
		public function readConfigureWRAM(address) {
			switch (address & 0x3) {
				case 3:
					return this.WRAMConfiguration[1];
					break;
				case 0:
					return this.WRAMConfiguration[0];
					break;
				default:
					return 0;
			}
		}
		public function CPUInternalCyclePrefetch(address, clocks) {
			address = address | 0;
			clocks = clocks | 0;
			//Clock for idle CPU time:
			this.IOCore.updateCore(clocks | 0);
			//Check for ROM prefetching:
			if (this.prefetchEnabled) {
				//We were already in ROM, so if prefetch do so as sequential:
				//Only case for non-sequential ROM prefetch is invalid anyways:
				switch ((address >>> 24) & 0xF) {
					case 0x8:
					case 0x9:
						while (clocks >= this.CARTWaitState0Second) {
							clocks -= this.CARTWaitState0Second;
							++this.ROMPrebuffer;
						}
						break;
					case 0xA:
					case 0xB:
						while (clocks >= this.CARTWaitState1Second) {
							clocks -= this.CARTWaitState1Second;
							++this.ROMPrebuffer;
						}
						break;
					case 0xC:
					case 0xD:
						while (clocks >= this.CARTWaitState1Second) {
							clocks -= this.CARTWaitState1Second;
							++this.ROMPrebuffer;
						}
				}
				//ROM buffer caps out at 8 x 16 bit:
				if (this.ROMPrebuffer > 8) {
					this.ROMPrebuffer = 8;
				}
			}
		}
		public function CPUGetOpcode16(address) {
			address = address | 0;
			var data = 0;
			if (address >= 0x8000000 && address < 0xE000000) {
				data = this.getROMRead16(address | 0) | 0;
			}
			else {
				data = this.opcodeCache.memoryReadFast16(address >>> 0) | 0;
			}
			return data | 0;
		}
		public function getROMRead16Prefetch(address) {
			//Caching enabled:
			address = address | 0;
			var clocks = 0;
			var data = 0;
			if (this.ROMPrebuffer == 0) {
				//Cache is empty:
				if (address < 0xA000000) {
					clocks = ((this.nonSequential) ? (this.CARTWaitState0First | 0) : (this.CARTWaitState0Second | 0)) | 0;
				}
				else if (address < 0xC000000) {
					clocks = ((this.nonSequential) ? (this.CARTWaitState1First | 0) : (this.CARTWaitState1Second | 0)) | 0;
				}
				else {
					clocks = ((this.nonSequential) ? (this.CARTWaitState2First | 0) : (this.CARTWaitState2Second | 0)) | 0;
				}
				this.IOCore.updateCore(clocks | 0);
				this.nonSequential = false;
				data = this.IOCore.cartridge.readROM16(address & 0x1FFFFFF) | 0;
			}
			else {
				//Cache hit:
				--this.ROMPrebuffer;
				this.FASTAccess2();
				data = this.IOCore.cartridge.readROM16(address & 0x1FFFFFF) | 0;
			}
			return data;
		}
		public function getROMRead16NoPrefetch(address) {
			//Caching disabled:
			address = address | 0;
			var clocks = 0;
			if (address < 0xA000000) {
				clocks = this.CARTWaitState0First | 0;
			}
			else if (address < 0xC000000) {
				clocks = this.CARTWaitState1First | 0;
			}
			else {
				clocks = this.CARTWaitState2First | 0;
			}
			this.IOCore.updateCore(clocks | 0);
			this.nonSequential = false;
			return this.IOCore.cartridge.readROM16(address & 0x1FFFFFF) | 0;
		}
		public function CPUGetOpcode32(address) {
			address = address | 0;
			var data = 0;
			if ((address | 0) >= 0x8000000 && (address | 0) < 0xE000000) {
				data = this.getROMRead32(address);
			}
			else {
				data = this.opcodeCache.memoryReadFast32(address >>> 0) | 0;
			}
			return data | 0;
		}
		public function getROMRead32Prefetch(address) {
			//Caching enabled:
			address = address | 0;
			var clocks = 0;
			var data = 0;
			if (this.ROMPrebuffer == 0) {
				//Cache hit:
				if (address < 0xA000000) {
					clocks = (((this.nonSequential) ? (this.CARTWaitState0First | 0) : (this.CARTWaitState0Second | 0)) + (this.CARTWaitState0Second | 0)) | 0;
				}
				else if (address < 0xC000000) {
					clocks = (((this.nonSequential) ? (this.CARTWaitState1First | 0) : (this.CARTWaitState1Second | 0)) + (this.CARTWaitState1Second | 0)) | 0;
				}
				else {
					clocks = (((this.nonSequential) ? (this.CARTWaitState2First | 0) : (this.CARTWaitState2Second | 0)) + (this.CARTWaitState2Second | 0)) | 0;
				}
				
				this.IOCore.updateCore(clocks | 0);
				this.nonSequential = false;
				data = this.IOCore.cartridge.readROM32(address & 0x1FFFFFF) | 0;
				
			}
			else {
				if (this.ROMPrebuffer > 1) {
					//Cache hit:
					this.ROMPrebuffer -= 2;
					this.FASTAccess2();
					data = this.IOCore.cartridge.readROM32(address & 0x1FFFFFF) | 0;
				}
				else {
					//Cache miss if only 16 bits out of 32 bits stored:
					this.ROMPrebuffer = 0;
					if (address < 0xA000000) {
						clocks = (((this.nonSequential) ? (this.CARTWaitState0First | 0) : (this.CARTWaitState0Second | 0)) + (this.CARTWaitState0Second | 0)) | 0;
					}
					else if (address < 0xC000000) {
						clocks = (((this.nonSequential) ? (this.CARTWaitState1First | 0) : (this.CARTWaitState1Second | 0)) + (this.CARTWaitState1Second | 0)) | 0;
					}
					else {
						clocks = (((this.nonSequential) ? (this.CARTWaitState2First | 0) : (this.CARTWaitState2Second | 0)) + (this.CARTWaitState2Second | 0)) | 0;
					}
					this.IOCore.updateCore(clocks | 0);
					this.nonSequential = false;
					data = this.IOCore.cartridge.readROM32(address & 0x1FFFFFF) | 0;
				}
			}
			return data | 0;
		}
		public function getROMRead32NoPrefetch(address) {
			//Caching disabled:
			address = address | 0;
			var clocks = 0;
			if (address < 0xA000000) {
				clocks = ((this.CARTWaitState0First | 0) + (this.CARTWaitState0Second | 0)) | 0;
			}
			else if (address < 0xC000000) {
				clocks = ((this.CARTWaitState1First | 0) + (this.CARTWaitState1Second | 0)) | 0;
			}
			else {
				clocks = ((this.CARTWaitState2First | 0) + (this.CARTWaitState2Second | 0)) | 0;
			}
			this.IOCore.updateCore(clocks | 0);
			this.nonSequential = false;
			return this.IOCore.cartridge.readROM32(address & 0x1FFFFFF) | 0;
		}
		public function NonSequentialBroadcast() {
			this.nonSequential = true;
			this.ROMPrebuffer = 0;
		}
		public function FASTAccess(reqByteNumber) {
			if ((reqByteNumber & 0x1) == 0x1 || this.width == 8) {
				this.IOCore.updateCore(1);
				this.nonSequential = false;
			}
		}
		public function FASTAccess2() {
			this.IOCore.updateCore(1);
			this.nonSequential = false;
		}
		public function WRAMAccess(reqByteNumber) {
			if ((reqByteNumber & 0x1) == 0x1 || this.width == 8) {
				this.IOCore.updateCore(this.WRAMWaitState | 0);
			}
			this.nonSequential = false;
		}
		public function WRAMAccess8() {
			this.IOCore.updateCore(this.WRAMWaitState | 0);
			this.nonSequential = false;
		}
		public function WRAMAccess16() {
			this.IOCore.updateCore(this.WRAMWaitState | 0);
			this.nonSequential = false;
		}
		public function WRAMAccess32() {
			this.IOCore.updateCore(this.WRAMWaitState << 1);
			this.nonSequential = false;
		}
		public function ROM0Access(reqByteNumber) {
			if ((reqByteNumber & 0x1) == 0x1 || this.width == 8) {
				if (this.nonSequential) {
					this.IOCore.updateCore(this.CARTWaitState0First | 0);
					this.nonSequential = false;
				}
				else {
					this.IOCore.updateCore(this.CARTWaitState0Second | 0);
				}
			}
		}
		public function ROM0Access8() {
			if (this.nonSequential) {
				this.IOCore.updateCore(this.CARTWaitState0First | 0);
				this.nonSequential = false;
			}
			else {
				this.IOCore.updateCore(this.CARTWaitState0Second | 0);
			}
		}
		public function ROM0Access16() {
			if (this.nonSequential) {
				this.IOCore.updateCore(this.CARTWaitState0First | 0);
				this.nonSequential = false;
			}
			else {
				this.IOCore.updateCore(this.CARTWaitState0Second | 0);
			}
		}
		public function ROM0Access32() {
			if (this.nonSequential) {
				this.IOCore.updateCore(((this.CARTWaitState0First | 0) + (this.CARTWaitState0Second | 0)));
				this.nonSequential = false;
			}
			else {
				this.IOCore.updateCore(this.CARTWaitState0Second << 1);
			}
		}
		public function ROM1Access(reqByteNumber) {
			if ((reqByteNumber & 0x1) == 0x1 || this.width == 8) {
				if (this.nonSequential) {
					this.IOCore.updateCore(this.CARTWaitState1First | 0);
					this.nonSequential = false;
				}
				else {
					this.IOCore.updateCore(this.CARTWaitState1Second | 0);
				}
			}
		}
		public function ROM1Access8() {
			if (this.nonSequential) {
				this.IOCore.updateCore(this.CARTWaitState1First | 0);
				this.nonSequential = false;
			}
			else {
				this.IOCore.updateCore(this.CARTWaitState1Second | 0);
			}
		}
		public function ROM1Access16() {
			if (this.nonSequential) {
				this.IOCore.updateCore(this.CARTWaitState1First | 0);
				this.nonSequential = false;
			}
			else {
				this.IOCore.updateCore(this.CARTWaitState1Second | 0);
			}
		}
		public function ROM1Access32() {
			if (this.nonSequential) {
				this.IOCore.updateCore(((this.CARTWaitState1First | 0) + (this.CARTWaitState1Second | 0)));
				this.nonSequential = false;
			}
			else {
				this.IOCore.updateCore(this.CARTWaitState1Second << 1);
			}
		}
		public function ROM2Access(reqByteNumber) {
			if ((reqByteNumber & 0x1) == 0x1 || this.width == 8) {
				if (this.nonSequential) {
					this.IOCore.updateCore(this.CARTWaitState2First | 0);
					this.nonSequential = false;
				}
				else {
					this.IOCore.updateCore(this.CARTWaitState2Second | 0);
				}
			}
		}
		public function ROM2Access8() {
			if (this.nonSequential) {
				this.IOCore.updateCore(this.CARTWaitState2First | 0);
				this.nonSequential = false;
			}
			else {
				this.IOCore.updateCore(this.CARTWaitState2Second | 0);
			}
		}
		public function ROM2Access16() {
			if (this.nonSequential) {
				this.IOCore.updateCore(this.CARTWaitState2First | 0);
				this.nonSequential = false;
			}
			else {
				this.IOCore.updateCore(this.CARTWaitState2Second | 0);
			}
		}
		public function ROM2Access32() {
			if (this.nonSequential) {
				this.IOCore.updateCore(((this.CARTWaitState2First | 0) + (this.CARTWaitState2Second | 0)));
				this.nonSequential = false;
			}
			else {
				this.IOCore.updateCore(this.CARTWaitState2Second << 1);
			}
		}
		public function SRAMAccess() {
			this.IOCore.updateCore(this.SRAMWaitState | 0);
			this.nonSequential = false;
		}
		public function VRAMAccess(reqByteNumber) {
			if ((reqByteNumber & 0x1) == 0x1 || this.width == 8) {
				this.IOCore.updateCore((this.IOCore.gfx.isRendering()) ? 2 : 1);
			}
			this.nonSequential = false;
		}
		public function VRAMAccess8() {
			this.IOCore.updateCore((this.IOCore.gfx.isRendering()) ? 2 : 1);
			this.nonSequential = false;
		}
		public function VRAMAccess16() {
			this.IOCore.updateCore((this.IOCore.gfx.isRendering()) ? 2 : 1);
			this.nonSequential = false;
		}
		public function VRAMAccess32() {
			this.IOCore.updateCore((this.IOCore.gfx.isRendering()) ? 4 : 2);
			this.nonSequential = false;
		}
		public function OAMAccess(reqByteNumber) {
			switch (reqByteNumber | 0) {
				case 0:
					if (this.width != 8) {
						return;
					}
				case 1:
					if (this.width != 16) {
						return;
					}
				case 3:
					this.IOCore.updateCore(this.IOCore.gfx.OAMLockedCycles() + 1);
			}
			this.nonSequential = false;
		}
		public function OAMAccess8() {
			this.IOCore.updateCore(((this.IOCore.gfx.OAMLockedCycles() | 0) + 1) | 0);
			this.nonSequential = false;
		}
		public function OAMAccess16() {
			this.IOCore.updateCore(((this.IOCore.gfx.OAMLockedCycles() | 0) + 1) | 0);
			this.nonSequential = false;
		}
		public function OAMAccess32() {
			this.IOCore.updateCore(((this.IOCore.gfx.OAMLockedCycles() | 0) + 1) | 0);
			this.nonSequential = false;
		}
				
		

	}
	
}
