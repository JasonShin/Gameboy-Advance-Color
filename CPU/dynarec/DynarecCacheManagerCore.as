package CPU.dynarec {
	import flash.display.MovieClip;
	import flash.events.Event;
	
	public class DynarecCacheManagerCore extends MovieClip{

		public var CPUCore:CPU;
		public var start;
		public var end;
		public var InTHUMB;
		public var CPUMode;
		public var badCount;
		public var hotCount;
		public var worker;
		public var compiling;
		public var compiled;
		
		public var MAGIC_HOT_COUNT = 100;
		public var MAGIC_BAD_COUNT = 2;
		public var MAX_WORKERS = 5;
		
		public var record;
		
		public var enterEvent;

		public function DynarecCacheManagerCore(cpu, start, end, InTHUMB, CPUMode) {
			// constructor code
			this.CPUCore = cpu;
			this.start = start | 0;
			this.end = end | 0;
			this.InTHUMB = InTHUMB;
			this.CPUMode = CPUMode;
			this.badCount = 0;
			this.hotCount = 0;
			this.worker = null;
			this.compiling = false;
			this.compiled = false;
		}

		public function tickHotness() {
			if (this.start >= this.end) {
				//Don't let sub-routines too small through:
				return;
			}
			if (!this.compiled) {
				if (this.badCount < this.MAGIC_BAD_COUNT) {
					++this.hotCount;
					if (this.hotCount >= this.MAGIC_HOT_COUNT) {
						this.compile();
					}
				}
			}
		}
		public function bailout() {
			this.compiled = false;
			++this.badCount;
		}
		public function read(address) {
			if (this.InTHUMB) {
				return this.read16(address);
			}
			else {
				return this.read32(address);
			}
		}
		public function read16(address) {
			if (address >= 0x8000000 && address < 0xE000000) {
				return this.CPUCore.IOCore.cartridge.readROM16(address & 0x1FFFFFF);
			}
			else if (address >= 0x3000000 && address < 0x4000000) {
				return this.CPUCore.IOCore.memory.externalRAM[address & 0x3FFFF] | (this.CPUCore.IOCore.memory.externalRAM[(address & 0x3FFFF) | 1] << 8);
			}
			else if (address >= 0x2000000 && address < 0x3000000) {
				return this.CPUCore.IOCore.memory.internalRAM[address & 0x7FFF] | (this.CPUCore.IOCore.memory.internalRAM[(address & 0x7FFF) | 1] << 8);
			}
			else if (address >= 0x20 && address < 0x4000) {
				return this.CPUCore.IOCore.memory.BIOS[address] | (this.CPUCore.IOCore.memory.BIOS[address | 1] << 8);
			}
		}
		public function read32(address) {
			if (address >= 0x8000000 && address < 0xE000000) {
				return this.CPUCore.IOCore.cartridge.readROM32(address & 0x1FFFFFF);
			}
			else if (address >= 0x3000000 && address < 0x4000000) {
				return this.CPUCore.IOCore.memory.externalRAM[address & 0x3FFFF] | (this.CPUCore.IOCore.memory.externalRAM[(address & 0x3FFFF) | 1] << 8) | (this.CPUCore.IOCore.memory.externalRAM[(address & 0x3FFFF) | 2] << 16)  | (this.CPUCore.IOCore.memory.externalRAM[(address & 0x3FFFF) | 3] << 24);
			}
			else if (address >= 0x2000000 && address < 0x3000000) {
				return this.CPUCore.IOCore.memory.internalRAM[address & 0x7FFF] | (this.CPUCore.IOCore.memory.internalRAM[(address & 0x7FFF) | 1] << 8) | (this.CPUCore.IOCore.memory.internalRAM[(address & 0x7FFF) | 2] << 16)  | (this.CPUCore.IOCore.memory.internalRAM[(address & 0x7FFF) | 3] << 24);
			}
			else if (address >= 0x20 && address < 0x4000) {
				return this.CPUCore.IOCore.memory.BIOS[address] | (this.CPUCore.IOCore.memory.BIOS[address | 1] << 8) | (this.CPUCore.IOCore.memory.BIOS[address | 2] << 16)  | (this.CPUCore.IOCore.memory.BIOS[address | 3] << 24);
			}
		}
		
		public function postMessage(parentObj, command){
			
		}
		
		public function messageEvent(parentObj, command){
			var message = command;
			var code = message[0];
			switch (code) {
				//Got the code block back:
				case 0:
					//parentObj.CPUCore.dynarec.cacheAppendReady(parentObj.start, new Function("cpu", message[1]));
					break;
				//Compiler returned an error:
				case 1:
					parentObj.bailout();
			}
			//Destroy the worker:
			parentObj.worker = null;
			parentObj.CPUCore.dynarec.compiling--;
			parentObj.compiling = false;
			parentObj.compiled = true;
			enterEvent.removeEventListener(Event.ENTER_FRAME);
		}
		
		
		public function compile() {
			//Make sure there isn't another worker compiling:
			if (!this.compiling && this.CPUCore.dynarec.compiling < this.MAX_WORKERS) {
				this.record = [];
				var start = this.start;
				var end = this.end + ((this.InTHUMB) ? 0x4 : 0x8);
				while (start <= end) {
					//Build up a record of bytecode to pass to the worker to compile:
					this.record.push(this.read(start));
					start += (this.InTHUMB) ? 0x2 : 0x4;
				}

				//Put a lock on the compiler:
				this.CPUCore.dynarec.compiling++;
				this.compiling = true;
				
				//Pass the record memory and state:
				/*this.postMessage(this, [this.start, this.record, this.InTHUMB, this.CPUMode, (this.start >= 0x8000000 || this.end < 0x4000), [
															this.CPUCore.IOCore.wait.WRAMWaitState,
															this.CPUCore.IOCore.wait.SRAMWaitState,
															this.CPUCore.IOCore.wait.CARTWaitState0First,
															this.CPUCore.IOCore.wait.CARTWaitState0Second,
															this.CPUCore.IOCore.wait.CARTWaitState1First,
															this.CPUCore.IOCore.wait.CARTWaitState1Second,
															this.CPUCore.IOCore.wait.CARTWaitState2First,
															this.CPUCore.IOCore.wait.CARTWaitState2Second]]);
																																					
			*/}
		}


	}
	
}
