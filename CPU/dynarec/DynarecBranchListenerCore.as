package CPU.dynarec {
	
	public class DynarecBranchListenerCore {
		
		public var CPUCore:CPU;
		
		public var lastBranch:int;
		public var lastTHUMB = false;
		public var lastCPUMode:int;
		public var caches:Object;
		public var readyCaches:Object;
		public var currentCache = null;
		public var compiling:int;
		public var backEdge = false;
		
		
		public function DynarecBranchListenerCore(cpu:CPU) {
			// constructor code
			this.CPUCore = cpu;
 			this.initialize();
		}
		
		public function initialize() {
			this.lastBranch = 0;
			this.lastTHUMB = false;
			this.lastCPUMode = 0x10;
			this.caches = {};
			this.readyCaches = {};
			this.currentCache = null;
			this.compiling = 0;
			this.backEdge = false;
		}
		public function listen(oldPC, newPC, instructionmode, cpumode) {
			if ((this.CPUCore.emulatorCore.dynarecTHUMB && instructionmode) || (this.CPUCore.emulatorCore.dynarecARM && !instructionmode)) {
				this.analyzePast(oldPC >>> 0, instructionmode, cpumode);
				this.handleNext(newPC >>> 0, instructionmode, cpumode);
			}
			else {
				this.backEdge = false;
			}
		}
		public function analyzePast(endPC, instructionmode, cpumode) {
			if (this.backEdge && cpumode == this.lastCPUMode) {
				var cache = this.findCache(this.lastBranch);
				if (!cache) {
					cache = new DynarecCacheManagerCore(this.CPUCore, this.lastBranch >>> 0, (endPC - ((this.lastTHUMB) ? 0x6 : 0xC)) >>> 0, this.lastTHUMB, this.lastCPUMode);
					this.cacheAppend(cache);
				}
				cache.tickHotness();
			}
			this.backEdge = true;
		}
		public function handleNext(newPC, instructionmode, cpumode) {
			this.lastBranch = newPC;
			this.lastTHUMB = instructionmode;
			this.lastCPUMode = cpumode;
			if (this.isAddressSafe(newPC)) {
				var cache = this.findCacheReady(newPC);
				if (cache) {
					this.CPUCore.IOCore.executeDynarec = true;
					this.currentCache = cache;
				}
			}
			else {
				this.backEdge = false;
			}
		}
		public function enter() {
		   if (this.CPUCore.emulatorCore.dynarecEnabled) {
			   //Execute our compiled code:
			   return !!this.currentCache(this.CPUCore);
		   }
			return false;
		}
		public function isAddressSafe(address) {
			if (address < 0xE000000) {
				if (address < 0x4000000) {
					if (address >= 0x2000000) {
						return true;
					}
					else if (this.CPUCore.IOCore.BIOSFound && address >= 0x20 && address < 0x4000) {
						return true;
					}
				}
				else if (address >= 0x8000000) {
					return true;
				}
			}
			return false;
		}
		public function cacheAppend(cache) {
			this.caches["c_" + (cache.start >>> 0)] = cache;
		}
		public function cacheAppendReady(address, cache) {
			this.readyCaches["c_" + (address >>> 0)] = cache;
		}
		public function findCache(address) {
			return this.caches["c_" + (address >>> 0)];
		}
		public function findCacheReady(address) {
			return this.readyCaches["c_" + (address >>> 0)];
		}
		public function invalidateCaches() {
			this.readyCaches = {};
		}
		
		
		

	}
	
}
