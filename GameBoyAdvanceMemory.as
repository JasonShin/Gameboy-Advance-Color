package  {
	import utils.Logger;
	import utils.ArrayHelper;
	
	public class GameBoyAdvanceMemory {
		
		public var IOCore;
		public var emulatorCore;
		//Load the BIOS:
		public var BIOS;
		public var BIOS16;
		public var BIOS32;
		
		public var externalRAM;
		public var externalRAM16;
		public var externalRAM32;
		public var internalRAM;
		public var internalRAM16;
		public var internalRAM32;
		public var lastBIOSREAD;
		public var lastBIOSREAD16;
		public var lastBIOSREAD32;
		
		public var dma;
		public var gfx;
		public var sound;
		public var timer;
		public var irq;
		public var serial;
		public var joypad;
		public var cartridge;
		public var wait;
		public var cpu;
		
		public var memoryWriter;
		public var memoryWriter8;
		public var memoryWriter16;
		public var memoryWriter32;
		public var memoryReader;
		public var memoryReader8;
		public var memoryReader16;
		public var memoryReader32;
		public var writeIO;
		public var readIO;
		
		public function GameBoyAdvanceMemory(IOCore) {
			// constructor code
			this.IOCore = IOCore;
			this.emulatorCore = this.IOCore.emulatorCore;
			//Load the BIOS:
			this.BIOS = ArrayHelper.buildArray(0x4000);
			//this.BIOS16 = ArrayHelper.buildArray(this.BIOS);
			//this.BIOS32 = ArrayHelper.buildArray(this.BIOS);
			this.loadBIOS();
			//Initialize Some RAM:
			this.externalRAM = ArrayHelper.buildArray(0x40000);
			//this.externalRAM16 = ArrayHelper.buildArray(this.externalRAM);
			//this.externalRAM32 = ArrayHelper.buildArray(this.externalRAM);
			this.internalRAM = ArrayHelper.buildArray(0x8000);
			//this.internalRAM16 = ArrayHelper.buildArray(this.internalRAM);
			//this.internalRAM32 = ArrayHelper.buildArray(this.internalRAM);
			this.lastBIOSREAD = ArrayHelper.buildArray(0x4);		//BIOS read bus last.
			//this.lastBIOSREAD16 = ArrayHelper.buildArray(this.lastBIOSREAD);
			//this.lastBIOSREAD32 = ArrayHelper.buildArray(this.lastBIOSREAD);
			//After all sub-objects initialized, initialize dispatches:
			this.compileMemoryDispatches();
			this.compileIOWriteDispatch();
			this.compileIOReadDispatch();
		}
		
				
				
		public function loadReferences () {
			//Initialize the various handler objects:
			this.dma = this.IOCore.dma;
			this.gfx = this.IOCore.gfx;
			this.sound = this.IOCore.sound;
			this.timer = this.IOCore.timer;
			this.irq = this.IOCore.irq;
			this.serial = this.IOCore.serial;
			this.joypad = this.IOCore.joypad;
			this.cartridge = this.IOCore.cartridge;
			this.wait = this.IOCore.wait;
			this.cpu = this.IOCore.cpu;
		}
		public function memoryWrite8 (address, data) {
			address = address >>> 0;
			data = data | 0;
			//Byte Write:
			//this.memoryWriteFast8(address >>> 0, data & 0xFF, 0);
			this.memoryWriteFast8(address >>> 0, data & 0xFF);
		}
		public function memoryWrite16 (address, data) {
			address = address >>> 0;
			data = data | 0;
			//Half-Word Write:
			if ((address & 0x1) == 0) {
				//Use optimized path for aligned:
				this.memoryWriteFast16(address >>> 0, data | 0);
			}
			else {
				this.memoryWrite16Unaligned(address >>> 0, data | 0);
			}
		}
		public function memoryWrite16Unaligned (address, data) {
			address = address >>> 0;
			data = data | 0;
			//Half-Word Write:
			this.wait.width = 16;
			this.memoryWrite(address >>> 0, data & 0xFF, 0);
			this.memoryWrite((address + 1) >>> 0, (data >> 8) & 0xFF, 1);
		}
		public function memoryWrite32 (address, data) {
			address = address >>> 0;
			data = data | 0;
			//Word Write:
			if ((address & 0x3) == 0) {
				//Use optimized path for aligned:
				this.memoryWriteFast32(address >>> 0, data | 0);
			}
			else {
				this.memoryWrite32Unaligned(address >>> 0, data | 0);
			}
		}
		public function memoryWrite32Unaligned (address, data) {
			address = address >>> 0;
			data = data | 0;
			this.wait.width = 32;
			this.memoryWrite(address >>> 0, data & 0xFF, 0);
			this.memoryWrite((address + 1) >>> 0, (data >> 8) & 0xFF, 1);
			this.memoryWrite((address + 2) >>> 0, (data >> 16) & 0xFF, 2);
			this.memoryWrite((address + 3) >>> 0, data >>> 24, 3);
		}
		public function memoryWrite (address, data, busReqNumber) {
			address = address >>> 0;
			data = data | 0;
			busReqNumber = busReqNumber | 0;
			this.memoryWriter[address >>> 24](this, address >>> 0, data | 0, busReqNumber | 0);
		}
		public function memoryWriteFast8 (address, data) {
			address = address >>> 0;
			data = data | 0;
			this.memoryWriter8[address >>> 24](this, address >>> 0, data | 0);
		}
		public function memoryWriteFast16 (address, data):void {
			address = address >>> 0;
			data = data | 0;
			this.memoryWriter16[address >>> 24](this, address >>> 0, data | 0);
		}
		public function memoryWriteFast32 (address, data) {
			address = address >>> 0;
			data = data | 0;
			this.memoryWriter32[address >>> 24](this, address >>> 0, data | 0);
		}
		public function memoryRead8 (address) {
			//Byte Read:
			//return this.memoryReadFast8(address >>> 0, 0) | 0;
			return this.memoryReadFast8(address >>> 0) | 0;
		}
		public function memoryRead16 (address) {
			address = address >>> 0;
			//Half-Word Read:
			if ((address & 0x1) == 0) {
				//Use optimized path for aligned:
				return this.memoryReadFast16(address >>> 0) | 0;
			}
			else {
				return this.memoryRead16Unaligned(address >>> 0) | 0;
			}
		}
		public function memoryRead16Unaligned (address) {
			address = address >>> 0;
			//Half-Word Read:
			this.wait.width = 16;
			var data16 = this.memoryRead(address >>> 0, 0) | 0;
			data16 |= this.memoryRead((address + 1) >>> 0, 1) << 8;
			return data16 | 0;
		}
		public function memoryRead32 (address) {
			address = address >>> 0;
			//Word Read:
			if ((address & 0x3) == 0) {
				//Use optimized path for aligned:
				return this.memoryReadFast32(address >>> 0) | 0;
			}
			else {
				return this.memoryRead32Unaligned(address >>> 0) | 0;
			}
		
		}
		public function memoryRead32Unaligned (address) {
			address = address >>> 0;
			//Word Read:
			this.wait.width = 32;
			var data32 = this.memoryRead(address >>> 0, 0) | 0;
			data32 |= this.memoryRead((address + 1) >>> 0, 1) << 8;
			data32 |= this.memoryRead((address + 2) >>> 0, 2) << 16;
			data32 |= this.memoryRead((address + 3) >>> 0, 3) << 24;
			return data32 | 0;
		}
		public function memoryRead (address, busReqNumber) {
			address = address >>> 0;
			return this.memoryReader[address >>> 24](this, address >>> 0, busReqNumber | 0) | 0;
		}
		public function memoryReadFast8 (address) {
			address = address >>> 0;
			return this.memoryReader8[address >>> 24](this, address >>> 0) | 0;
		}
		public function memoryReadFast16 (address) {
			address = address >>> 0;
			return this.memoryReader16[address >>> 24](this, address >>> 0) | 0;
		}
		public function memoryReadFast32 (address) {
			address = address >>> 0;
			return this.memoryReader32[address >>> 24](this, address >>> 0) | 0;
		}
		public function compileMemoryDispatches () {
			var writeCalls8slow = [
								   this.writeUnused,
								   this.writeExternalWRAM,
								   this.writeInternalWRAM,
								   this.writeIODispatch,
								   this.writePalette,
								   this.writeVRAM,
								   this.writeOAM,
								   this.writeROM0,
								   this.writeROM1,
								   this.writeROM2,
								   this.writeSRAM
								   ];
			var readCalls8slow = [
								  this.readUnused,
								  this.readExternalWRAM,
								  this.readInternalWRAM,
								  this.readIODispatch,
								  this.readPalette,
								  this.readVRAM,
								  this.readOAM,
								  this.readROM0,
								  this.readROM1,
								  this.readROM2,
								  this.readSRAM,
								  (this.IOCore.BIOSFound) ? this.readBIOS : this.readUnused
								  ];
			var bus8slow = this.compileMemoryDispatch(writeCalls8slow, readCalls8slow);
			this.memoryWriter = bus8slow[0];
			this.memoryReader = bus8slow[1];
			var writeCalls8 = [
							   this.writeUnused8,
							   this.writeExternalWRAM8,
							   this.writeInternalWRAM8,
							   this.writeIODispatch8,
							   this.writePalette8,
							   this.writeVRAM8,
							   this.writeOAM8,
							   this.writeROM08,
							   this.writeROM18,
							   this.writeROM28,
							   this.writeSRAM8
							   ];
			var readCalls8 = [
							  this.readUnused8,
							  this.readExternalWRAM8,
							  this.readInternalWRAM8,
							  this.readIODispatch8,
							  this.readPalette8,
							  this.readVRAM8,
							  this.readOAM8,
							  this.readROM08,
							  this.readROM18,
							  this.readROM28,
							  this.readSRAM8,
							  (this.IOCore.BIOSFound) ? this.readBIOS8 : this.readUnused8
							  ];
			var bus8 = this.compileMemoryDispatch(writeCalls8, readCalls8);
			this.memoryWriter8 = bus8[0];
			this.memoryReader8 = bus8[1];
			var writeCalls16 = [
								this.writeUnused16,
								//(this.externalRAM16) ? this.writeExternalWRAM16Optimized : this.writeExternalWRAM16Slow,
								//(this.internalRAM16) ? this.writeInternalWRAM16Optimized : this.writeInternalWRAM16Slow,
								this.writeExternalWRAM16Slow,
								this.writeInternalWRAM16Slow,
								this.writeIODispatch16,
								this.writePalette16,
								this.writeVRAM16,
								this.writeOAM16,
								this.writeROM016,
								this.writeROM116,
								this.writeROM216,
								this.writeSRAM16
								];
			var readCalls16 = [
							   this.readUnused16,
							   //(this.externalRAM16) ? this.readExternalWRAM16Optimized : this.readExternalWRAM16Slow,
							   //(this.internalRAM16) ? this.readInternalWRAM16Optimized : this.readInternalWRAM16Slow,
							   this.readExternalWRAM16Slow,
							   this.readInternalWRAM16Slow,
							   this.readIODispatch16,
							   this.readPalette16,
							   this.readVRAM16,
							   this.readOAM16,
							   this.readROM016,
							   this.readROM116,
							   this.readROM216,
							   this.readSRAM16,
							  // (this.IOCore.BIOSFound) ? ((this.BIOS16) ? this.readBIOS16Optimized : this.readBIOS16Slow) : this.readUnused16
							  	 (this.IOCore.BIOSFound) ? this.readBIOS16Slow : this.readUnused16
							   ];
			var bus16 = this.compileMemoryDispatch(writeCalls16, readCalls16);
			this.memoryWriter16 = bus16[0];
			this.memoryReader16 = bus16[1];
			var writeCalls32 = [
								this.writeUnused32,
								//(this.externalRAM32) ? this.writeExternalWRAM32Optimized : this.writeExternalWRAM32Slow,
								//(this.internalRAM32) ? this.writeInternalWRAM32Optimized : this.writeInternalWRAM32Slow,
								this.writeExternalWRAM32Slow,
								this.writeInternalWRAM32Slow,
								this.writeIODispatch32,
								this.writePalette32,
								this.writeVRAM32,
								this.writeOAM32,
								this.writeROM032,
								this.writeROM132,
								this.writeROM232,
								this.writeSRAM32
								];
			var readCalls32 = [
							   this.readUnused32,
							  // (this.externalRAM32) ? this.readExternalWRAM32Optimized : this.readExternalWRAM32Slow,
							   //(this.internalRAM32) ? this.readInternalWRAM32Optimized : this.readInternalWRAM32Slow,
							   this.readExternalWRAM32Slow,
							   this.readInternalWRAM32Slow,
							   this.readIODispatch32,
							   this.readPalette32,
							   this.readVRAM32,
							   this.readOAM32,
							   this.readROM032,
							   this.readROM132,
							   this.readROM232,
							   this.readSRAM32,
							 //  (this.IOCore.BIOSFound) ? ((this.BIOS32) ? this.readBIOS32Optimized : this.readBIOS32Slow) : this.readUnused32
							   (this.IOCore.BIOSFound) ? this.readBIOS32Slow : this.readUnused32
							   ];
			var bus32 = this.compileMemoryDispatch(writeCalls32, readCalls32);
			this.memoryWriter32 = bus32[0];
			this.memoryReader32 = bus32[1];
		}
		public function compileMemoryDispatch (writeCalls, readCalls) {
			var writeUnused = writeCalls[0];
			var writeExternalWRAM = writeCalls[1];
			var writeInternalWRAM = writeCalls[2];
			var writeIODispatch = writeCalls[3];
			var writePalette = writeCalls[4];
			var writeVRAM = writeCalls[5];
			var writeOAM = writeCalls[6];
			var writeROM0 = writeCalls[7];
			var writeROM1 = writeCalls[8];
			var writeROM2 = writeCalls[9];
			var writeSRAM = writeCalls[10];
			var readUnused = readCalls[0];
			var readExternalWRAM = readCalls[1];
			var readInternalWRAM = readCalls[2];
			var readIODispatch = readCalls[3];
			var readPalette = readCalls[4];
			var readVRAM = readCalls[5];
			var readOAM = readCalls[6];
			var readROM0 = readCalls[7];
			var readROM1 = readCalls[8];
			var readROM2 = readCalls[9];
			var readSRAM = readCalls[10];
			var readBIOS = readCalls[11];
			/*
			 Decoder for the nibble at bits 24-27
			 (Top 4 bits of the address is not used,
			 so the next nibble down is used for dispatch.):
			 */
			var memoryWriter = [
								/*
								 BIOS Area (00000000-00003FFF)
								 Unused (00004000-01FFFFFF)
								 */
								writeUnused,
								/*
								 Unused (00004000-01FFFFFF)
								 */
								writeUnused,
								/*
								 WRAM - On-board Work RAM (02000000-0203FFFF)
								 Unused (02040000-02FFFFFF)
								 */
								writeExternalWRAM,
								/*
								 WRAM - In-Chip Work RAM (03000000-03007FFF)
								 Unused (03008000-03FFFFFF)
								 */
								writeInternalWRAM,
								/*
								 I/O Registers (04000000-040003FE)
								 Unused (04000400-04FFFFFF)
								 */
								writeIODispatch,
								/*
								 BG/OBJ Palette RAM (05000000-050003FF)
								 Unused (05000400-05FFFFFF)
								 */
								writePalette,
								/*
								 VRAM - Video RAM (06000000-06017FFF)
								 Unused (06018000-06FFFFFF)
								 */
								writeVRAM,
								/*
								 OAM - OBJ Attributes (07000000-070003FF)
								 Unused (07000400-07FFFFFF)
								 */
								writeOAM,
								/*
								 Game Pak ROM (max 16MB) - Wait State 0 (08000000-08FFFFFF)
								 */
								writeROM0,
								/*
								 Game Pak ROM/FlashROM (max 16MB) - Wait State 0 (09000000-09FFFFFF)
								 */
								writeROM0,
								/*
								 Game Pak ROM (max 16MB) - Wait State 1 (0A000000-0AFFFFFF)
								 */
								writeROM1,
								/*
								 Game Pak ROM/FlashROM (max 16MB) - Wait State 1 (0B000000-0BFFFFFF)
								 */
								writeROM1,
								/*
								 Game Pak ROM (max 16MB) - Wait State 2 (0C000000-0CFFFFFF)
								 */
								writeROM2,
								/*
								 Game Pak ROM/FlashROM (max 16MB) - Wait State 2 (0D000000-0DFFFFFF)
								 */
								writeROM2,
								/*
								 Game Pak SRAM  (max 64 KBytes) - 8bit Bus width (0E000000-0E00FFFF)
								 */
								writeSRAM,
								/*
								 Unused (0E010000-FFFFFFFF)
								 */
								writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused,
								writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused, writeUnused
								];
			var memoryReader = [
								/*
								 BIOS Area (00000000-00003FFF)
								 Unused (00004000-01FFFFFF)
								 */
								readBIOS,
								/*
								 Unused (00004000-01FFFFFF)
								 */
								readUnused,
								/*
								 WRAM - On-board Work RAM (02000000-0203FFFF)
								 Unused (02040000-02FFFFFF)
								 */
								readExternalWRAM,
								/*
								 WRAM - In-Chip Work RAM (03000000-03007FFF)
								 Unused (03008000-03FFFFFF)
								 */
								readInternalWRAM,
								/*
								 I/O Registers (04000000-040003FE)
								 Unused (04000400-04FFFFFF)
								 */
								readIODispatch,
								/*
								 BG/OBJ Palette RAM (05000000-050003FF)
								 Unused (05000400-05FFFFFF)
								 */
								readPalette,
								/*
								 VRAM - Video RAM (06000000-06017FFF)
								 Unused (06018000-06FFFFFF)
								 */
								readVRAM,
								/*
								 OAM - OBJ Attributes (07000000-070003FF)
								 Unused (07000400-07FFFFFF)
								 */
								readOAM,
								/*
								 Game Pak ROM (max 16MB) - Wait State 0 (08000000-08FFFFFF)
								 */
								readROM0,
								/*
								 Game Pak ROM/FlashROM (max 16MB) - Wait State 0 (09000000-09FFFFFF)
								 */
								readROM0,
								/*
								 Game Pak ROM (max 16MB) - Wait State 1 (0A000000-0AFFFFFF)
								 */
								readROM1,
								/*
								 Game Pak ROM/FlashROM (max 16MB) - Wait State 1 (0B000000-0BFFFFFF)
								 */
								readROM1,
								/*
								 Game Pak ROM (max 16MB) - Wait State 2 (0C000000-0CFFFFFF)
								 */
								readROM2,
								/*
								 Game Pak ROM/FlashROM (max 16MB) - Wait State 2 (0D000000-0DFFFFFF)
								 */
								readROM2,
								/*
								 Game Pak SRAM  (max 64 KBytes) - 8bit Bus width (0E000000-0E00FFFF)
								 */
								readSRAM,
								/*
								 Unused (0E010000-FFFFFFFF)
								 */
								readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused,
								readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused, readUnused
								];
			return [memoryWriter, memoryReader];
		}
		public function compileIOWriteDispatch () {
			this.writeIO = [];
			//4000000h - DISPCNT - LCD Control (Read/Write)
			this.writeIO[0] = function (parentObj, data) {
				parentObj.gfx.writeDISPCNT0(data | 0);
			}
			//4000001h - DISPCNT - LCD Control (Read/Write)
			this.writeIO[0x1] = function (parentObj, data) {
				parentObj.gfx.writeDISPCNT1(data | 0);
			}
			//4000002h - Undocumented - Green Swap (R/W)
			this.writeIO[0x2] = function (parentObj, data) {
				parentObj.gfx.writeGreenSwap(data | 0);
			}
			//4000003h - Undocumented - Green Swap (R/W)
			this.writeIO[0x3] = this.NOP;
			//4000004h - DISPSTAT - General LCD Status (Read/Write)
			this.writeIO[0x4] = function (parentObj, data) {
				parentObj.gfx.writeDISPSTAT0(data | 0);
			}
			//4000005h - DISPSTAT - General LCD Status (Read/Write)
			this.writeIO[0x5] = function (parentObj, data) {
				parentObj.gfx.writeDISPSTAT1(data | 0);
			}
			//4000006h - VCOUNT - Vertical Counter (Read only)
			this.writeIO[0x6] = this.NOP;
			//4000007h - VCOUNT - Vertical Counter (Read only)
			this.writeIO[0x7] = this.NOP;
			//4000008h - BG0CNT - BG0 Control (R/W) (BG Modes 0,1 only)
			this.writeIO[0x8] = function (parentObj, data) {
				parentObj.gfx.writeBG0CNT0(data | 0);
			}
			//4000009h - BG0CNT - BG0 Control (R/W) (BG Modes 0,1 only)
			this.writeIO[0x9] = function (parentObj, data) {
				parentObj.gfx.writeBG0CNT1(data | 0);
			}
			//400000Ah - BG1CNT - BG1 Control (R/W) (BG Modes 0,1 only)
			this.writeIO[0xA] = function (parentObj, data) {
				parentObj.gfx.writeBG1CNT0(data | 0);
			}
			//400000Bh - BG1CNT - BG1 Control (R/W) (BG Modes 0,1 only)
			this.writeIO[0xB] = function (parentObj, data) {
				parentObj.gfx.writeBG1CNT1(data | 0);
			}
			//400000Ch - BG2CNT - BG2 Control (R/W) (BG Modes 0,1,2 only)
			this.writeIO[0xC] = function (parentObj, data) {
				parentObj.gfx.writeBG2CNT0(data | 0);
			}
			//400000Dh - BG2CNT - BG2 Control (R/W) (BG Modes 0,1,2 only)
			this.writeIO[0xD] = function (parentObj, data) {
				parentObj.gfx.writeBG2CNT1(data | 0);
			}
			//400000Eh - BG3CNT - BG3 Control (R/W) (BG Modes 0,2 only)
			this.writeIO[0xE] = function (parentObj, data) {
				parentObj.gfx.writeBG3CNT0(data | 0);
			}
			//400000Fh - BG3CNT - BG3 Control (R/W) (BG Modes 0,2 only)
			this.writeIO[0xF] = function (parentObj, data) {
				parentObj.gfx.writeBG3CNT1(data | 0);
			}
			//4000010h - BG0HOFS - BG0 X-Offset (W)
			this.writeIO[0x10] = function (parentObj, data) {
				parentObj.gfx.writeBG0HOFS0(data | 0);
			}
			//4000011h - BG0HOFS - BG0 X-Offset (W)
			this.writeIO[0x11] = function (parentObj, data) {
				parentObj.gfx.writeBG0HOFS1(data | 0);
			}
			//4000012h - BG0VOFS - BG0 Y-Offset (W)
			this.writeIO[0x12] = function (parentObj, data) {
				parentObj.gfx.writeBG0VOFS0(data | 0);
			}
			//4000013h - BG0VOFS - BG0 Y-Offset (W)
			this.writeIO[0x13] = function (parentObj, data) {
				parentObj.gfx.writeBG0VOFS1(data | 0);
			}
			//4000014h - BG1HOFS - BG1 X-Offset (W)
			this.writeIO[0x14] = function (parentObj, data) {
				parentObj.gfx.writeBG1HOFS0(data | 0);
			}
			//4000015h - BG1HOFS - BG1 X-Offset (W)
			this.writeIO[0x15] = function (parentObj, data) {
				parentObj.gfx.writeBG1HOFS1(data | 0);
			}
			//4000016h - BG1VOFS - BG1 Y-Offset (W)
			this.writeIO[0x16] = function (parentObj, data) {
				parentObj.gfx.writeBG1VOFS0(data | 0);
			}
			//4000017h - BG1VOFS - BG1 Y-Offset (W)
			this.writeIO[0x17] = function (parentObj, data) {
				parentObj.gfx.writeBG1VOFS1(data | 0);
			}
			//4000018h - BG2HOFS - BG2 X-Offset (W)
			this.writeIO[0x18] = function (parentObj, data) {
				parentObj.gfx.writeBG2HOFS0(data | 0);
			}
			//4000019h - BG2HOFS - BG2 X-Offset (W)
			this.writeIO[0x19] = function (parentObj, data) {
				parentObj.gfx.writeBG2HOFS1(data | 0);
			}
			//400001Ah - BG2VOFS - BG2 Y-Offset (W)
			this.writeIO[0x1A] = function (parentObj, data) {
				parentObj.gfx.writeBG2VOFS0(data | 0);
			}
			//400001Bh - BG2VOFS - BG2 Y-Offset (W)
			this.writeIO[0x1B] = function (parentObj, data) {
				parentObj.gfx.writeBG2VOFS1(data | 0);
			}
			//400001Ch - BG3HOFS - BG3 X-Offset (W)
			this.writeIO[0x1C] = function (parentObj, data) {
				parentObj.gfx.writeBG3HOFS0(data | 0);
			}
			//400001Dh - BG3HOFS - BG3 X-Offset (W)
			this.writeIO[0x1D] = function (parentObj, data) {
				parentObj.gfx.writeBG3HOFS1(data | 0);
			}
			//400001Eh - BG3VOFS - BG3 Y-Offset (W)
			this.writeIO[0x1E] = function (parentObj, data) {
				parentObj.gfx.writeBG3VOFS0(data | 0);
			}
			//400001Fh - BG3VOFS - BG3 Y-Offset (W)
			this.writeIO[0x1F] = function (parentObj, data) {
				parentObj.gfx.writeBG3VOFS1(data | 0);
			}
			//4000020h - BG2PA - BG2 Rotation/Scaling Parameter A (alias dx) (W)
			this.writeIO[0x20] = function (parentObj, data) {
				parentObj.gfx.writeBG2PA0(data | 0);
			}
			//4000021h - BG2PA - BG2 Rotation/Scaling Parameter A (alias dx) (W)
			this.writeIO[0x21] = function (parentObj, data) {
				parentObj.gfx.writeBG2PA1(data | 0);
			}
			//4000022h - BG2PB - BG2 Rotation/Scaling Parameter B (alias dmx) (W)
			this.writeIO[0x22] = function (parentObj, data) {
				parentObj.gfx.writeBG2PB0(data | 0);
			}
			//4000023h - BG2PB - BG2 Rotation/Scaling Parameter B (alias dmx) (W)
			this.writeIO[0x23] = function (parentObj, data) {
				parentObj.gfx.writeBG2PB1(data | 0);
			}
			//4000024h - BG2PC - BG2 Rotation/Scaling Parameter C (alias dy) (W)
			this.writeIO[0x24] = function (parentObj, data) {
				parentObj.gfx.writeBG2PC0(data | 0);
			}
			//4000025h - BG2PC - BG2 Rotation/Scaling Parameter C (alias dy) (W)
			this.writeIO[0x25] = function (parentObj, data) {
				parentObj.gfx.writeBG2PC1(data | 0);
			}
			//4000026h - BG2PD - BG2 Rotation/Scaling Parameter D (alias dmy) (W)
			this.writeIO[0x26] = function (parentObj, data) {
				parentObj.gfx.writeBG2PD0(data | 0);
			}
			//4000027h - BG2PD - BG2 Rotation/Scaling Parameter D (alias dmy) (W)
			this.writeIO[0x27] = function (parentObj, data) {
				parentObj.gfx.writeBG2PD1(data | 0);
			}
			//4000028h - BG2X_L - BG2 Reference Point X-Coordinate, lower 16 bit (W)
			this.writeIO[0x28] = function (parentObj, data) {
				parentObj.gfx.writeBG2X_L0(data | 0);
			}
			//4000029h - BG2X_L - BG2 Reference Point X-Coordinate, lower 16 bit (W)
			this.writeIO[0x29] = function (parentObj, data) {
				parentObj.gfx.writeBG2X_L1(data | 0);
			}
			//400002Ah - BG2X_H - BG2 Reference Point X-Coordinate, upper 12 bit (W)
			this.writeIO[0x2A] = function (parentObj, data) {
				parentObj.gfx.writeBG2X_H0(data | 0);
			}
			//400002Bh - BG2X_H - BG2 Reference Point X-Coordinate, upper 12 bit (W)
			this.writeIO[0x2B] = function (parentObj, data) {
				parentObj.gfx.writeBG2X_H1(data | 0);
			}
			//400002Ch - BG2Y_L - BG2 Reference Point Y-Coordinate, lower 16 bit (W)
			this.writeIO[0x2C] = function (parentObj, data) {
				parentObj.gfx.writeBG2Y_L0(data | 0);
			}
			//400002Dh - BG2Y_L - BG2 Reference Point Y-Coordinate, lower 16 bit (W)
			this.writeIO[0x2D] = function (parentObj, data) {
				parentObj.gfx.writeBG2Y_L1(data | 0);
			}
			//400002Eh - BG2Y_H - BG2 Reference Point Y-Coordinate, upper 12 bit (W)
			this.writeIO[0x2E] = function (parentObj, data) {
				parentObj.gfx.writeBG2Y_H0(data | 0);
			}
			//400002Fh - BG2Y_H - BG2 Reference Point Y-Coordinate, upper 12 bit (W)
			this.writeIO[0x2F] = function (parentObj, data) {
				parentObj.gfx.writeBG2Y_H1(data | 0);
			}
			//4000030h - BG3PA - BG3 Rotation/Scaling Parameter A (alias dx) (W)
			this.writeIO[0x30] = function (parentObj, data) {
				parentObj.gfx.writeBG3PA0(data | 0);
			}
			//4000031h - BG3PA - BG3 Rotation/Scaling Parameter A (alias dx) (W)
			this.writeIO[0x31] = function (parentObj, data) {
				parentObj.gfx.writeBG3PA1(data | 0);
			}
			//4000032h - BG3PB - BG3 Rotation/Scaling Parameter B (alias dmx) (W)
			this.writeIO[0x32] = function (parentObj, data) {
				parentObj.gfx.writeBG3PB0(data | 0);
			}
			//4000033h - BG3PB - BG3 Rotation/Scaling Parameter B (alias dmx) (W)
			this.writeIO[0x33] = function (parentObj, data) {
				parentObj.gfx.writeBG3PB1(data | 0);
			}
			//4000034h - BG3PC - BG3 Rotation/Scaling Parameter C (alias dy) (W)
			this.writeIO[0x34] = function (parentObj, data) {
				parentObj.gfx.writeBG3PC0(data | 0);
			}
			//4000035h - BG3PC - BG3 Rotation/Scaling Parameter C (alias dy) (W)
			this.writeIO[0x35] = function (parentObj, data) {
				parentObj.gfx.writeBG3PC1(data | 0);
			}
			//4000036h - BG3PD - BG3 Rotation/Scaling Parameter D (alias dmy) (W)
			this.writeIO[0x36] = function (parentObj, data) {
				parentObj.gfx.writeBG3PD0(data | 0);
			}
			//4000037h - BG3PD - BG3 Rotation/Scaling Parameter D (alias dmy) (W)
			this.writeIO[0x37] = function (parentObj, data) {
				parentObj.gfx.writeBG3PD1(data | 0);
			}
			//4000038h - BG3X_L - BG3 Reference Point X-Coordinate, lower 16 bit (W)
			this.writeIO[0x38] = function (parentObj, data) {
				parentObj.gfx.writeBG3X_L0(data | 0);
			}
			//4000039h - BG3X_L - BG3 Reference Point X-Coordinate, lower 16 bit (W)
			this.writeIO[0x39] = function (parentObj, data) {
				parentObj.gfx.writeBG3X_L1(data | 0);
			}
			//400003Ah - BG3X_H - BG3 Reference Point X-Coordinate, upper 12 bit (W)
			this.writeIO[0x3A] = function (parentObj, data) {
				parentObj.gfx.writeBG3X_H0(data | 0);
			}
			//400003Bh - BG3X_H - BG3 Reference Point X-Coordinate, upper 12 bit (W)
			this.writeIO[0x3B] = function (parentObj, data) {
				parentObj.gfx.writeBG3X_H1(data | 0);
			}
			//400003Ch - BG3Y_L - BG3 Reference Point Y-Coordinate, lower 16 bit (W)
			this.writeIO[0x3C] = function (parentObj, data) {
				parentObj.gfx.writeBG3Y_L0(data | 0);
			}
			//400003Dh - BGY_L - BG3 Reference Point Y-Coordinate, lower 16 bit (W)
			this.writeIO[0x3D] = function (parentObj, data) {
				parentObj.gfx.writeBG3Y_L1(data | 0);
			}
			//400003Eh - BG3Y_H - BG3 Reference Point Y-Coordinate, upper 12 bit (W)
			this.writeIO[0x3E] = function (parentObj, data) {
				parentObj.gfx.writeBG3Y_H0(data | 0);
			}
			//400003Fh - BG3Y_H - BG3 Reference Point Y-Coordinate, upper 12 bit (W)
			this.writeIO[0x3F] = function (parentObj, data) {
				parentObj.gfx.writeBG3Y_H1(data | 0);
			}
			//4000040h - WIN0H - Window 0 Horizontal Dimensions (W)
			this.writeIO[0x40] = function (parentObj, data) {
				parentObj.gfx.writeWIN0H0(data | 0);
			}
			//4000041h - WIN0H - Window 0 Horizontal Dimensions (W)
			this.writeIO[0x41] = function (parentObj, data) {
				parentObj.gfx.writeWIN0H1(data | 0);
			}
			//4000042h - WIN1H - Window 1 Horizontal Dimensions (W)
			this.writeIO[0x42] = function (parentObj, data) {
				parentObj.gfx.writeWIN1H0(data | 0);
			}
			//4000043h - WIN1H - Window 1 Horizontal Dimensions (W)
			this.writeIO[0x43] = function (parentObj, data) {
				parentObj.gfx.writeWIN1H1(data | 0);
			}
			//4000044h - WIN0V - Window 0 Vertical Dimensions (W)
			this.writeIO[0x44] = function (parentObj, data) {
				parentObj.gfx.writeWIN0V0(data | 0);
			}
			//4000045h - WIN0V - Window 0 Vertical Dimensions (W)
			this.writeIO[0x45] = function (parentObj, data) {
				parentObj.gfx.writeWIN0V1(data | 0);
			}
			//4000046h - WIN1V - Window 1 Vertical Dimensions (W)
			this.writeIO[0x46] = function (parentObj, data) {
				parentObj.gfx.writeWIN1V0(data | 0);
			}
			//4000047h - WIN1V - Window 1 Vertical Dimensions (W)
			this.writeIO[0x47] = function (parentObj, data) {
				parentObj.gfx.writeWIN1V1(data | 0);
			}
			//4000048h - WININ - Control of Inside of Window(s) (R/W)
			this.writeIO[0x48] = function (parentObj, data) {
				parentObj.gfx.writeWININ0(data | 0);
			}
			//4000049h - WININ - Control of Inside of Window(s) (R/W)
			this.writeIO[0x49] = function (parentObj, data) {
				parentObj.gfx.writeWININ1(data | 0);
			}
			//400004Ah- WINOUT - Control of Outside of Windows & Inside of OBJ Window (R/W)
			this.writeIO[0x4A] = function (parentObj, data) {
				parentObj.gfx.writeWINOUT0(data | 0);
			}
			//400004AB- WINOUT - Control of Outside of Windows & Inside of OBJ Window (R/W)
			this.writeIO[0x4B] = function (parentObj, data) {
				parentObj.gfx.writeWINOUT1(data | 0);
			}
			//400004Ch - MOSAIC - Mosaic Size (W)
			this.writeIO[0x4C] = function (parentObj, data) {
				parentObj.gfx.writeMOSAIC0(data | 0);
			}
			//400004Dh - MOSAIC - Mosaic Size (W)
			this.writeIO[0x4D] = function (parentObj, data) {
				parentObj.gfx.writeMOSAIC1(data | 0);
			}
			//400004Eh - NOT USED - ZERO
			this.writeIO[0x4E] = this.NOP;
			//400004Fh - NOT USED - ZERO
			this.writeIO[0x4F] = this.NOP;
			//4000050h - BLDCNT - Color Special Effects Selection (R/W)
			this.writeIO[0x50] = function (parentObj, data) {
				parentObj.gfx.writeBLDCNT0(data | 0);
			}
			//4000051h - BLDCNT - Color Special Effects Selection (R/W)
			this.writeIO[0x51] = function (parentObj, data) {
				parentObj.gfx.writeBLDCNT1(data | 0);
			}
			//4000052h - BLDALPHA - Alpha Blending Coefficients (W)
			this.writeIO[0x52] = function (parentObj, data) {
				parentObj.gfx.writeBLDALPHA0(data | 0);
			}
			//4000053h - BLDALPHA - Alpha Blending Coefficients (W)
			this.writeIO[0x53] = function (parentObj, data) {
				parentObj.gfx.writeBLDALPHA1(data | 0);
			}
			//4000054h - BLDY - Brightness (Fade-In/Out) Coefficient (W)
			this.writeIO[0x54] = function (parentObj, data) {
				parentObj.gfx.writeBLDY(data | 0);
			}
			//4000055h through 400005Fh - NOT USED - ZERO/GLITCHED
			this.fillWriteTableNOP(0x55, 0x5F);
			//4000060h - SOUND1CNT_L (NR10) - Channel 1 Sweep register (R/W)
			this.writeIO[0x60] = function (parentObj, data) {
				//NR10:
				parentObj.sound.writeSOUND1CNT_L(data | 0);
			}
			//4000061h - NOT USED - ZERO
			this.writeIO[0x61] = this.NOP;
			//4000062h - SOUND1CNT_H (NR11, NR12) - Channel 1 Duty/Len/Envelope (R/W)
			this.writeIO[0x62] = function (parentObj, data) {
				//NR11:
				parentObj.sound.writeSOUND1CNT_H0(data | 0);
			}
			//4000063h - SOUND1CNT_H (NR11, NR12) - Channel 1 Duty/Len/Envelope (R/W)
			this.writeIO[0x63] = function (parentObj, data) {
				//NR12:
				parentObj.sound.writeSOUND1CNT_H1(data | 0);
			}
			//4000064h - SOUND1CNT_X (NR13, NR14) - Channel 1 Frequency/Control (R/W)
			this.writeIO[0x64] = function (parentObj, data) {
				//NR13:
				parentObj.sound.writeSOUND1CNT_X0(data | 0);
			}
			//4000065h - SOUND1CNT_X (NR13, NR14) - Channel 1 Frequency/Control (R/W)
			this.writeIO[0x65] = function (parentObj, data) {
				//NR14:
				parentObj.sound.writeSOUND1CNT_X1(data | 0);
			}
			//4000066h - NOT USED - ZERO
			this.writeIO[0x66] = this.NOP;
			//4000067h - NOT USED - ZERO
			this.writeIO[0x67] = this.NOP;
			//4000068h - SOUND2CNT_L (NR21, NR22) - Channel 2 Duty/Length/Envelope (R/W)
			this.writeIO[0x68] = function (parentObj, data) {
				//NR21:
				parentObj.sound.writeSOUND2CNT_L0(data | 0);
			}
			//4000069h - SOUND2CNT_L (NR21, NR22) - Channel 2 Duty/Length/Envelope (R/W)
			this.writeIO[0x69] = function (parentObj, data) {
				//NR22:
				parentObj.sound.writeSOUND2CNT_L1(data | 0);
			}
			//400006Ah - NOT USED - ZERO
			this.writeIO[0x6A] = this.NOP;
			//400006Bh - NOT USED - ZERO
			this.writeIO[0x6B] = this.NOP;
			//400006Ch - SOUND2CNT_H (NR23, NR24) - Channel 2 Frequency/Control (R/W)
			this.writeIO[0x6C] = function (parentObj, data) {
				//NR23:
				parentObj.sound.writeSOUND2CNT_H0(data | 0);
			}
			//400006Dh - SOUND2CNT_H (NR23, NR24) - Channel 2 Frequency/Control (R/W)
			this.writeIO[0x6D] = function (parentObj, data) {
				//NR24:
				parentObj.sound.writeSOUND2CNT_H1(data | 0);
			}
			//400006Eh - NOT USED - ZERO
			this.writeIO[0x6E] = this.NOP;
			//400006Fh - NOT USED - ZERO
			this.writeIO[0x6F] = this.NOP;
			//4000070h - SOUND3CNT_L (NR30) - Channel 3 Stop/Wave RAM select (R/W)
			this.writeIO[0x70] = function (parentObj, data) {
				//NR30:
				parentObj.sound.writeSOUND3CNT_L(data | 0);
			}
			//4000071h - SOUND3CNT_L (NR30) - Channel 3 Stop/Wave RAM select (R/W)
			this.writeIO[0x71] = this.NOP;
			//4000072h - SOUND3CNT_H (NR31, NR32) - Channel 3 Length/Volume (R/W)
			this.writeIO[0x72] = function (parentObj, data) {
				//NR31:
				parentObj.sound.writeSOUND3CNT_H0(data | 0);
			}
			//4000073h - SOUND3CNT_H (NR31, NR32) - Channel 3 Length/Volume (R/W)
			this.writeIO[0x73] = function (parentObj, data) {
				//NR32:
				parentObj.sound.writeSOUND3CNT_H1(data | 0);
			}
			//4000074h - SOUND3CNT_X (NR33, NR34) - Channel 3 Frequency/Control (R/W)
			this.writeIO[0x74] = function (parentObj, data) {
				//NR33:
				parentObj.sound.writeSOUND3CNT_X0(data | 0);
			}
			//4000075h - SOUND3CNT_X (NR33, NR34) - Channel 3 Frequency/Control (R/W)
			this.writeIO[0x75] = function (parentObj, data) {
				//NR34:
				parentObj.sound.writeSOUND3CNT_X1(data | 0);
			}
			//4000076h - NOT USED - ZERO
			this.writeIO[0x76] = this.NOP;
			//4000077h - NOT USED - ZERO
			this.writeIO[0x77] = this.NOP;
			//4000078h - SOUND4CNT_L (NR41, NR42) - Channel 4 Length/Envelope (R/W)
			this.writeIO[0x78] = function (parentObj, data) {
				//NR41:
				parentObj.sound.writeSOUND4CNT_L0(data | 0);
			}
			//4000079h - SOUND4CNT_L (NR41, NR42) - Channel 4 Length/Envelope (R/W)
			this.writeIO[0x79] = function (parentObj, data) {
				//NR42:
				parentObj.sound.writeSOUND4CNT_L1(data | 0);
			}
			//400007Ah - NOT USED - ZERO
			this.writeIO[0x7A] = this.NOP;
			//400007Bh - NOT USED - ZERO
			this.writeIO[0x7B] = this.NOP;
			//400007Ch - SOUND4CNT_H (NR43, NR44) - Channel 4 Frequency/Control (R/W)
			this.writeIO[0x7C] = function (parentObj, data) {
				//NR43:
				parentObj.sound.writeSOUND4CNT_H0(data | 0);
			}
			//400007Dh - SOUND4CNT_H (NR43, NR44) - Channel 4 Frequency/Control (R/W)
			this.writeIO[0x7D] = function (parentObj, data) {
				//NR44:
				parentObj.sound.writeSOUND4CNT_H1(data | 0);
			}
			//400007Eh - NOT USED - ZERO
			this.writeIO[0x7E] = this.NOP;
			//400007Fh - NOT USED - ZERO
			this.writeIO[0x7F] = this.NOP;
			//4000080h - SOUNDCNT_L (NR50, NR51) - Channel L/R Volume/Enable (R/W)
			this.writeIO[0x80] = function (parentObj, data) {
				//NR50:
				parentObj.sound.writeSOUNDCNT_L0(data | 0);
			}
			//4000081h - SOUNDCNT_L (NR50, NR51) - Channel L/R Volume/Enable (R/W)
			this.writeIO[0x81] = function (parentObj, data) {
				//NR51:
				parentObj.sound.writeSOUNDCNT_L1(data | 0);
			}
			//4000082h - SOUNDCNT_H (GBA only) - DMA Sound Control/Mixing (R/W)
			this.writeIO[0x82] = function (parentObj, data) {
				parentObj.sound.writeSOUNDCNT_H0(data | 0);
			}
			//4000083h - SOUNDCNT_H (GBA only) - DMA Sound Control/Mixing (R/W)
			this.writeIO[0x83] = function (parentObj, data) {
				parentObj.sound.writeSOUNDCNT_H1(data | 0);
			}
			//4000084h - SOUNDCNT_X (NR52) - Sound on/off (R/W)
			this.writeIO[0x84] = function (parentObj, data) {
				parentObj.sound.writeSOUNDCNT_X(data | 0);
			}
			//4000085h - NOT USED - ZERO
			this.writeIO[0x85] = this.NOP;
			//4000086h - NOT USED - ZERO
			this.writeIO[0x86] = this.NOP;
			//4000087h - NOT USED - ZERO
			this.writeIO[0x87] = this.NOP;
			//4000088h - SOUNDBIAS - Sound PWM Control (R/W)
			this.writeIO[0x88] = function (parentObj, data) {
				parentObj.sound.writeSOUNDBIAS0(data | 0);
			}
			//4000089h - SOUNDBIAS - Sound PWM Control (R/W)
			this.writeIO[0x89] = function (parentObj, data) {
				parentObj.sound.writeSOUNDBIAS1(data | 0);
			}
			//400008Ah through 400008Fh - NOT USED - ZERO/GLITCHED
			this.fillWriteTableNOP(0x8A, 0x8F);
			//4000090h - WAVE_RAM0_L - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x90] = function (parentObj, data) {
				parentObj.sound.writeWAVE(0, data | 0);
			}
			//4000091h - WAVE_RAM0_L - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x91] = function (parentObj, data) {
				parentObj.sound.writeWAVE(2, data | 0);
			}
			//4000092h - WAVE_RAM0_H - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x92] = function (parentObj, data) {
				parentObj.sound.writeWAVE(4, data | 0);
			}
			//4000093h - WAVE_RAM0_H - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x93] = function (parentObj, data) {
				parentObj.sound.writeWAVE(6, data | 0);
			}
			//4000094h - WAVE_RAM1_L - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x94] = function (parentObj, data) {
				parentObj.sound.writeWAVE(8, data | 0);
			}
			//4000095h - WAVE_RAM1_L - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x95] = function (parentObj, data) {
				parentObj.sound.writeWAVE(10, data | 0);
			}
			//4000096h - WAVE_RAM1_H - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x96] = function (parentObj, data) {
				parentObj.sound.writeWAVE(12, data | 0);
			}
			//4000097h - WAVE_RAM1_H - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x97] = function (parentObj, data) {
				parentObj.sound.writeWAVE(14, data | 0);
			}
			//4000098h - WAVE_RAM2_L - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x98] = function (parentObj, data) {
				parentObj.sound.writeWAVE(16, data | 0);
			}
			//4000099h - WAVE_RAM2_L - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x99] = function (parentObj, data) {
				parentObj.sound.writeWAVE(18, data | 0);
			}
			//400009Ah - WAVE_RAM2_H - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x9A] = function (parentObj, data) {
				parentObj.sound.writeWAVE(20, data | 0);
			}
			//400009Bh - WAVE_RAM2_H - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x9B] = function (parentObj, data) {
				parentObj.sound.writeWAVE(22, data | 0);
			}
			//400009Ch - WAVE_RAM3_L - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x9C] = function (parentObj, data) {
				parentObj.sound.writeWAVE(24, data | 0);
			}
			//400009Dh - WAVE_RAM3_L - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x9D] = function (parentObj, data) {
				parentObj.sound.writeWAVE(26, data | 0);
			}
			//400009Eh - WAVE_RAM3_H - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x9E] = function (parentObj, data) {
				parentObj.sound.writeWAVE(28, data | 0);
			}
			//400009Fh - WAVE_RAM3_H - Channel 3 Wave Pattern RAM (W/R)
			this.writeIO[0x9F] = function (parentObj, data) {
				parentObj.sound.writeWAVE(30, data | 0);
			}
			//40000A0h - FIFO_A_L - FIFO Channel A First Word (W)
			this.writeIO[0xA0] = function (parentObj, data) {
				parentObj.sound.writeFIFOA(data | 0);
			}
			//40000A1h - FIFO_A_L - FIFO Channel A First Word (W)
			this.writeIO[0xA1] = function (parentObj, data) {
				parentObj.sound.writeFIFOA(data | 0);
			}
			//40000A2h - FIFO_A_H - FIFO Channel A Second Word (W)
			this.writeIO[0xA2] = function (parentObj, data) {
				parentObj.sound.writeFIFOA(data | 0);
			}
			//40000A3h - FIFO_A_H - FIFO Channel A Second Word (W)
			this.writeIO[0xA3] = function (parentObj, data) {
				parentObj.sound.writeFIFOA(data | 0);
			}
			//40000A4h - FIFO_B_L - FIFO Channel B First Word (W)
			this.writeIO[0xA4] = function (parentObj, data) {
				parentObj.sound.writeFIFOB(data | 0);
			}
			//40000A5h - FIFO_B_L - FIFO Channel B First Word (W)
			this.writeIO[0xA5] = function (parentObj, data) {
				parentObj.sound.writeFIFOB(data | 0);
			}
			//40000A6h - FIFO_B_H - FIFO Channel B Second Word (W)
			this.writeIO[0xA6] = function (parentObj, data) {
				parentObj.sound.writeFIFOB(data | 0);
			}
			//40000A7h - FIFO_B_H - FIFO Channel B Second Word (W)
			this.writeIO[0xA7] = function (parentObj, data) {
				parentObj.sound.writeFIFOB(data | 0);
			}
			//40000A8h through 40000AFh - NOT USED - GLITCHED
			this.fillWriteTableNOP(0xA8, 0xAF);
			//40000B0h - DMA0SAD - DMA 0 Source Address (W) (internal memory)
			this.writeIO[0xB0] = function (parentObj, data) {
				parentObj.dma.writeDMASource(0, 0, data | 0);
		
			}
			//40000B1h - DMA0SAD - DMA 0 Source Address (W) (internal memory)
			this.writeIO[0xB1] = function (parentObj, data) {
				parentObj.dma.writeDMASource(0, 1, data | 0);
			}
			//40000B2h - DMA0SAH - DMA 0 Source Address (W) (internal memory)
			this.writeIO[0xB2] = function (parentObj, data) {
				parentObj.dma.writeDMASource(0, 2, data | 0);
			}
			//40000B3h - DMA0SAH - DMA 0 Source Address (W) (internal memory)
			this.writeIO[0xB3] = function (parentObj, data) {
				parentObj.dma.writeDMASource(0, 3, data & 0x7);	//Mask out the unused bits.
			}
			//40000B4h - DMA0DAD - DMA 0 Destination Address (W) (internal memory)
			this.writeIO[0xB4] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(0, 0, data | 0);
			}
			//40000B5h - DMA0DAD - DMA 0 Destination Address (W) (internal memory)
			this.writeIO[0xB5] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(0, 1, data | 0);
			}
			//40000B6h - DMA0DAH - DMA 0 Destination Address (W) (internal memory)
			this.writeIO[0xB6] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(0, 2, data | 0);
			}
			//40000B7h - DMA0DAH - DMA 0 Destination Address (W) (internal memory)
			this.writeIO[0xB7] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(0, 3, data & 0x7);
			}
			//40000B8h - DMA0CNT_L - DMA 0 Word Count (W) (14 bit, 1..4000h)
			this.writeIO[0xB8] = function (parentObj, data) {
				parentObj.dma.writeDMAWordCount0(0, data | 0);
			}
			//40000B9h - DMA0CNT_L - DMA 0 Word Count (W) (14 bit, 1..4000h)
			this.writeIO[0xB9] = function (parentObj, data) {
				parentObj.dma.writeDMAWordCount1(0, data & 0x3F);
			}
			//40000BAh - DMA0CNT_H - DMA 0 Control (R/W)
			this.writeIO[0xBA] = function (parentObj, data) {
				parentObj.dma.writeDMAControl0(0, data | 0);
			}
			//40000BBh - DMA0CNT_H - DMA 0 Control (R/W)
			this.writeIO[0xBB] = function (parentObj, data) {
				parentObj.dma.writeDMAControl1(0, data | 0);
			}
			//40000BCh - DMA1SAD - DMA 1 Source Address (W) (internal memory)
			this.writeIO[0xBC] = function (parentObj, data) {
				parentObj.dma.writeDMASource(1, 0, data | 0);
			}
			//40000BDh - DMA1SAD - DMA 1 Source Address (W) (internal memory)
			this.writeIO[0xBD] = function (parentObj, data) {
				parentObj.dma.writeDMASource(1, 1, data | 0);
			}
			//40000BEh - DMA1SAH - DMA 1 Source Address (W) (internal memory)
			this.writeIO[0xBE] = function (parentObj, data) {
				parentObj.dma.writeDMASource(1, 2, data | 0);
			}
			//40000BFh - DMA1SAH - DMA 1 Source Address (W) (internal memory)
			this.writeIO[0xBF] = function (parentObj, data) {
				parentObj.dma.writeDMASource(1, 3, data & 0xF);	//Mask out the unused bits.
			}
			//40000C0h - DMA1DAD - DMA 1 Destination Address (W) (internal memory)
			this.writeIO[0xC0] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(1, 0, data | 0);
			}
			//40000C1h - DMA1DAD - DMA 1 Destination Address (W) (internal memory)
			this.writeIO[0xC1] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(1, 1, data | 0);
			}
			//40000C2h - DMA1DAH - DMA 1 Destination Address (W) (internal memory)
			this.writeIO[0xC2] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(1, 2, data | 0);
			}
			//40000C3h - DMA1DAH - DMA 1 Destination Address (W) (internal memory)
			this.writeIO[0xC3] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(1, 3, data & 0x7);
			}
			//40000C4h - DMA1CNT_L - DMA 1 Word Count (W) (14 bit, 1..4000h)
			this.writeIO[0xC4] = function (parentObj, data) {
				parentObj.dma.writeDMAWordCount0(1, data | 0);
			}
			//40000C5h - DMA1CNT_L - DMA 1 Word Count (W) (14 bit, 1..4000h)
			this.writeIO[0xC5] = function (parentObj, data) {
				parentObj.dma.writeDMAWordCount1(1, data & 0x3F);
			}
			//40000C6h - DMA1CNT_H - DMA 1 Control (R/W)
			this.writeIO[0xC6] = function (parentObj, data) {
				parentObj.dma.writeDMAControl0(1, data | 0);
			}
			//40000C7h - DMA1CNT_H - DMA 1 Control (R/W)
			this.writeIO[0xC7] = function (parentObj, data) {
				parentObj.dma.writeDMAControl1(1, data | 0);
			}
			//40000C8h - DMA2SAD - DMA 2 Source Address (W) (internal memory)
			this.writeIO[0xC8] = function (parentObj, data) {
				parentObj.dma.writeDMASource(2, 0, data | 0);
			}
			//40000C9h - DMA2SAD - DMA 2 Source Address (W) (internal memory)
			this.writeIO[0xC9] = function (parentObj, data) {
				parentObj.dma.writeDMASource(2, 1, data | 0);
			}
			//40000CAh - DMA2SAH - DMA 2 Source Address (W) (internal memory)
			this.writeIO[0xCA] = function (parentObj, data) {
				parentObj.dma.writeDMASource(2, 2, data | 0);
			}
			//40000CBh - DMA2SAH - DMA 2 Source Address (W) (internal memory)
			this.writeIO[0xCB] = function (parentObj, data) {
				parentObj.dma.writeDMASource(2, 3, data & 0xF);	//Mask out the unused bits.
			}
			//40000CCh - DMA2DAD - DMA 2 Destination Address (W) (internal memory)
			this.writeIO[0xCC] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(2, 0, data | 0);
			}
			//40000CDh - DMA2DAD - DMA 2 Destination Address (W) (internal memory)
			this.writeIO[0xCD] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(2, 1, data | 0);
			}
			//40000CEh - DMA2DAH - DMA 2 Destination Address (W) (internal memory)
			this.writeIO[0xCE] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(2, 2, data | 0);
			}
			//40000CFh - DMA2DAH - DMA 2 Destination Address (W) (internal memory)
			this.writeIO[0xCF] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(2, 3, data & 0x7);
			}
			//40000D0h - DMA2CNT_L - DMA 2 Word Count (W) (14 bit, 1..4000h)
			this.writeIO[0xD0] = function (parentObj, data) {
				parentObj.dma.writeDMAWordCount0(2, data | 0);
			}
			//40000D1h - DMA2CNT_L - DMA 2 Word Count (W) (14 bit, 1..4000h)
			this.writeIO[0xD1] = function (parentObj, data) {
				parentObj.dma.writeDMAWordCount1(2, data & 0x3F);
			}
			//40000D2h - DMA2CNT_H - DMA 2 Control (R/W)
			this.writeIO[0xD2] = function (parentObj, data) {
				parentObj.dma.writeDMAControl0(2, data | 0);
			}
			//40000D3h - DMA2CNT_H - DMA 2 Control (R/W)
			this.writeIO[0xD3] = function (parentObj, data) {
				parentObj.dma.writeDMAControl1(2, data | 0);
			}
			//40000D4h - DMA3SAD - DMA 3 Source Address (W) (internal memory)
			this.writeIO[0xD4] = function (parentObj, data) {
				parentObj.dma.writeDMASource(3, 0, data | 0);
			}
			//40000D5h - DMA3SAD - DMA 3 Source Address (W) (internal memory)
			this.writeIO[0xD5] = function (parentObj, data) {
				parentObj.dma.writeDMASource(3, 1, data | 0);
			}
			//40000D6h - DMA3SAH - DMA 3 Source Address (W) (internal memory)
			this.writeIO[0xD6] = function (parentObj, data) {
				parentObj.dma.writeDMASource(3, 2, data | 0);
			}
			//40000D7h - DMA3SAH - DMA 3 Source Address (W) (internal memory)
			this.writeIO[0xD7] = function (parentObj, data) {
				parentObj.dma.writeDMASource(3, 3, data & 0xF);	//Mask out the unused bits.
			}
			//40000D8h - DMA3DAD - DMA 3 Destination Address (W) (internal memory)
			this.writeIO[0xD8] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(3, 0, data | 0);
			}
			//40000D9h - DMA3DAD - DMA 3 Destination Address (W) (internal memory)
			this.writeIO[0xD9] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(3, 1, data | 0);
			}
			//40000DAh - DMA3DAH - DMA 3 Destination Address (W) (internal memory)
			this.writeIO[0xDA] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(3, 2, data | 0);
			}
			//40000DBh - DMA3DAH - DMA 3 Destination Address (W) (internal memory)
			this.writeIO[0xDB] = function (parentObj, data) {
				parentObj.dma.writeDMADestination(3, 3, data & 0xF);
			}
			//40000DCh - DMA3CNT_L - DMA 3 Word Count (W) (16 bit, 1..10000h)
			this.writeIO[0xDC] = function (parentObj, data) {
				parentObj.dma.writeDMAWordCount0(3, data | 0);
			}
			//40000DDh - DMA3CNT_L - DMA 3 Word Count (W) (16 bit, 1..10000h)
			this.writeIO[0xDD] = function (parentObj, data) {
				parentObj.dma.writeDMAWordCount1(3, data | 0);
			}
			//40000DEh - DMA3CNT_H - DMA 3 Control (R/W)
			this.writeIO[0xDE] = function (parentObj, data) {
				parentObj.dma.writeDMAControl0(3, data | 0);
			}
			//40000DFh - DMA3CNT_H - DMA 3 Control (R/W)
			this.writeIO[0xDF] = function (parentObj, data) {
				parentObj.dma.writeDMAControl1(3, data | 0);
			}
			//40000E0h through 40000FFh - NOT USED - GLITCHED
			this.fillWriteTableNOP(0xE0, 0xFF);
			//4000100h - TM0CNT_L - Timer 0 Counter/Reload (R/W)
			this.writeIO[0x100] = function (parentObj, data) {
				parentObj.timer.writeTM0CNT_L0(data | 0);
			}
			//4000101h - TM0CNT_L - Timer 0 Counter/Reload (R/W)
			this.writeIO[0x101] = function (parentObj, data) {
				parentObj.timer.writeTM0CNT_L1(data | 0);
			}
			//4000102h - TM0CNT_H - Timer 0 Control (R/W)
			this.writeIO[0x102] = function (parentObj, data) {
				parentObj.timer.writeTM0CNT_H(data | 0);
			}
			//4000103h - TM0CNT_H - Timer 0 Control (R/W)
			this.writeIO[0x103] = this.NOP;
			//4000104h - TM1CNT_L - Timer 1 Counter/Reload (R/W)
			this.writeIO[0x104] = function (parentObj, data) {
				parentObj.timer.writeTM1CNT_L0(data | 0);
			}
			//4000105h - TM1CNT_L - Timer 1 Counter/Reload (R/W)
			this.writeIO[0x105] = function (parentObj, data) {
				parentObj.timer.writeTM1CNT_L1(data | 0);
			}
			//4000106h - TM1CNT_H - Timer 1 Control (R/W)
			this.writeIO[0x106] = function (parentObj, data) {
				parentObj.timer.writeTM1CNT_H(data | 0);
			}
			//4000107h - TM1CNT_H - Timer 1 Control (R/W)
			this.writeIO[0x107] = this.NOP;
			//4000108h - TM2CNT_L - Timer 2 Counter/Reload (R/W)
			this.writeIO[0x108] = function (parentObj, data) {
				parentObj.timer.writeTM2CNT_L0(data | 0);
			}
			//4000109h - TM2CNT_L - Timer 2 Counter/Reload (R/W)
			this.writeIO[0x109] = function (parentObj, data) {
				parentObj.timer.writeTM2CNT_L1(data | 0);
			}
			//400010Ah - TM2CNT_H - Timer 2 Control (R/W)
			this.writeIO[0x10A] = function (parentObj, data) {
				parentObj.timer.writeTM2CNT_H(data | 0);
			}
			//400010Bh - TM2CNT_H - Timer 2 Control (R/W)
			this.writeIO[0x10B] = this.NOP;
			//400010Ch - TM3CNT_L - Timer 3 Counter/Reload (R/W)
			this.writeIO[0x10C] = function (parentObj, data) {
				parentObj.timer.writeTM3CNT_L0(data | 0);
			}
			//400010Dh - TM3CNT_L - Timer 3 Counter/Reload (R/W)
			this.writeIO[0x10D] = function (parentObj, data) {
				parentObj.timer.writeTM3CNT_L1(data | 0);
			}
			//400010Eh - TM3CNT_H - Timer 3 Control (R/W)
			this.writeIO[0x10E] = function (parentObj, data) {
				parentObj.timer.writeTM3CNT_H(data | 0);
			}
			//400010Fh - TM3CNT_H - Timer 3 Control (R/W)
			this.writeIO[0x10F] = this.NOP;
			//4000110h through 400011Fh - NOT USED - GLITCHED
			this.fillWriteTableNOP(0x110, 0x11F);
			//4000120h - Serial Data A (R/W)
			this.writeIO[0x120] = function (parentObj, data) {
				parentObj.serial.writeSIODATA_A0(data | 0);
			}
			//4000121h - Serial Data A (R/W)
			this.writeIO[0x121] = function (parentObj, data) {
				parentObj.serial.writeSIODATA_A1(data | 0);
			}
			//4000122h - Serial Data B (R/W)
			this.writeIO[0x122] = function (parentObj, data) {
				parentObj.serial.writeSIODATA_B0(data | 0);
			}
			//4000123h - Serial Data B (R/W)
			this.writeIO[0x123] = function (parentObj, data) {
				parentObj.serial.writeSIODATA_B1(data | 0);
			}
			//4000124h - Serial Data C (R/W)
			this.writeIO[0x124] = function (parentObj, data) {
				parentObj.serial.writeSIODATA_C0(data | 0);
			}
			//4000125h - Serial Data C (R/W)
			this.writeIO[0x125] = function (parentObj, data) {
				parentObj.serial.writeSIODATA_C1(data | 0);
			}
			//4000126h - Serial Data D (R/W)
			this.writeIO[0x126] = function (parentObj, data) {
				parentObj.serial.writeSIODATA_D0(data | 0);
			}
			//4000127h - Serial Data D (R/W)
			this.writeIO[0x127] = function (parentObj, data) {
				parentObj.serial.writeSIODATA_D1(data | 0);
			}
			//4000128h - SIOCNT - SIO Sub Mode Control (R/W)
			this.writeIO[0x128] = function (parentObj, data) {
				parentObj.serial.writeSIOCNT0(data | 0);
			}
			//4000129h - SIOCNT - SIO Sub Mode Control (R/W)
			this.writeIO[0x129] = function (parentObj, data) {
				parentObj.serial.writeSIOCNT1(data | 0);
			}
			//400012Ah - SIOMLT_SEND - Data Send Register (R/W)
			this.writeIO[0x12A] = function (parentObj, data) {
				parentObj.serial.writeSIODATA8_0(data | 0);
			}
			//400012Bh - SIOMLT_SEND - Data Send Register (R/W)
			this.writeIO[0x12B] = function (parentObj, data) {
				parentObj.serial.writeSIODATA8_1(data | 0);
			}
			//400012Ch through 400012Fh - NOT USED - GLITCHED
			this.fillWriteTableNOP(0x12C, 0x12F);
			//4000130h - KEYINPUT - Key Status (R)
			this.writeIO[0x130] = this.NOP;
			//4000131h - KEYINPUT - Key Status (R)
			this.writeIO[0x131] = this.NOP;
			//4000132h - KEYCNT - Key Interrupt Control (R/W)
			this.writeIO[0x132] = function (parentObj, data) {
				parentObj.joypad.writeKeyControl0(data | 0);
			}
			//4000133h - KEYCNT - Key Interrupt Control (R/W)
			this.writeIO[0x133] = function (parentObj, data) {
				parentObj.joypad.writeKeyControl1(data | 0);
			}
			//4000134h - RCNT (R/W) - Mode Selection
			this.writeIO[0x134] = function (parentObj, data) {
				parentObj.serial.writeRCNT0(data | 0);
			}
			//4000135h - RCNT (R/W) - Mode Selection
			this.writeIO[0x135] = function (parentObj, data) {
				parentObj.serial.writeRCNT1(data | 0);
			}
			//4000136h through 400013Fh - NOT USED - GLITCHED
			this.fillWriteTableNOP(0x136, 0x13F);
			//4000140h - JOYCNT - JOY BUS Control Register (R/W)
			this.writeIO[0x140] = function (parentObj, data) {
				parentObj.serial.writeJOYCNT(data | 0);
			}
			//4000141h - JOYCNT - JOY BUS Control Register (R/W)
			this.writeIO[0x141] = this.NOP;
			//4000142h through 400014Fh - NOT USED - GLITCHED
			this.fillWriteTableNOP(0x142, 0x14F);
			//4000150h - JoyBus Receive (R/W)
			this.writeIO[0x150] = function (parentObj, data) {
				parentObj.serial.writeJOYBUS_RECV0(data | 0);
			}
			//4000151h - JoyBus Receive (R/W)
			this.writeIO[0x151] = function (parentObj, data) {
				parentObj.serial.writeJOYBUS_RECV1(data | 0);
			}
			//4000152h - JoyBus Receive (R/W)
			this.writeIO[0x152] = function (parentObj, data) {
				parentObj.serial.writeJOYBUS_RECV2(data | 0);
			}
			//4000153h - JoyBus Receive (R/W)
			this.writeIO[0x153] = function (parentObj, data) {
				parentObj.serial.writeJOYBUS_RECV3(data | 0);
			}
			//4000154h - JoyBus Send (R/W)
			this.writeIO[0x154] = function (parentObj, data) {
				parentObj.serial.writeJOYBUS_SEND0(data | 0);
			}
			//4000155h - JoyBus Send (R/W)
			this.writeIO[0x155] = function (parentObj, data) {
				parentObj.serial.writeJOYBUS_SEND1(data | 0);
			}
			//4000156h - JoyBus Send (R/W)
			this.writeIO[0x156] = function (parentObj, data) {
				parentObj.serial.writeJOYBUS_SEND2(data | 0);
			}
			//4000157h - JoyBus Send (R/W)
			this.writeIO[0x157] = function (parentObj, data) {
				parentObj.serial.writeJOYBUS_SEND3(data | 0);
			}
			//4000158h - JoyBus Stat (R/W)
			this.writeIO[0x158] = function (parentObj, data) {
				parentObj.serial.writeJOYBUS_STAT(data | 0);
			}
			//4000159h through 40001FFh - NOT USED - GLITCHED
			this.fillWriteTableNOP(0x159, 0x1FF);
			//4000200h - IE - Interrupt Enable Register (R/W)
			this.writeIO[0x200] = function (parentObj, data) {
				parentObj.irq.writeIE0(data | 0);
			}
			//4000201h - IE - Interrupt Enable Register (R/W)
			this.writeIO[0x201] = function (parentObj, data) {
				parentObj.irq.writeIE1(data | 0);
			}
			//4000202h - IF - Interrupt Request Flags / IRQ Acknowledge
			this.writeIO[0x202] = function (parentObj, data) {
				parentObj.irq.writeIF0(data | 0);
			}
			//4000203h - IF - Interrupt Request Flags / IRQ Acknowledge
			this.writeIO[0x203] = function (parentObj, data) {
				parentObj.irq.writeIF1(data | 0);
			}
			//4000204h - WAITCNT - Waitstate Control (R/W)
			this.writeIO[0x204] = function (parentObj, data) {
				parentObj.wait.writeWAITCNT0(data | 0);
			}
			//4000205h - WAITCNT - Waitstate Control (R/W)
			this.writeIO[0x205] = function (parentObj, data) {
				parentObj.wait.writeWAITCNT1(data | 0);
			}
			//4000206h - WAITCNT - Waitstate Control (R/W)
			this.writeIO[0x206] = this.NOP;
			//4000207h - WAITCNT - Waitstate Control (R/W)
			this.writeIO[0x207] = this.NOP;
			//4000208h - IME - Interrupt Master Enable Register (R/W)
			this.writeIO[0x208] = function (parentObj, data) {
				parentObj.irq.writeIME(data | 0);
			}
			//4000209h through 40002FFh - NOT USED - GLITCHED
			this.fillWriteTableNOP(0x209, 0x2FF);
			//4000300h - POSTFLG - BYTE - Undocumented - Post Boot / Debug Control (R/W)
			this.writeIO[0x300] = function (parentObj, data) {
				parentObj.wait.writePOSTBOOT(data | 0);
			}
			//4000301h - HALTCNT - BYTE - Undocumented - Low Power Mode Control (W)
			this.writeIO[0x301] = function (parentObj, data) {
				parentObj.wait.writeHALTCNT(data | 0);
			}
			//4000302h - NOT USED - ZERO
			this.writeIO[0x302] = this.NOP;
			//4000303h - NOT USED - ZERO
			this.writeIO[0x303] = this.NOP;
		}
		public function fillWriteTableNOP (from, to) {
			//Fill in slots of the i/o write table:
			while (from <= to) {
				this.writeIO[from++] = this.NOP;
			}
		}
		public function compileIOReadDispatch () {
			this.readIO = [];
			//4000000h - DISPCNT - LCD Control (Read/Write)
			this.readIO[0] = function (parentObj) {
				return parentObj.gfx.readDISPCNT0() | 0;
			}
			//4000001h - DISPCNT - LCD Control (Read/Write)
			this.readIO[0x1] = function (parentObj) {
				return parentObj.gfx.readDISPCNT1() | 0;
			}
			//4000002h - Undocumented - Green Swap (R/W)
			this.readIO[0x2] = function (parentObj) {
				return parentObj.gfx.readGreenSwap() | 0;
			}
			//4000003h - Undocumented - Green Swap (R/W)
			this.readIO[0x3] = this.readWriteOnly;
			//4000004h - DISPSTAT - General LCD Status (Read/Write)
			this.readIO[0x4] = function (parentObj) {
				return parentObj.gfx.readDISPSTAT0() | 0;
			}
			//4000005h - DISPSTAT - General LCD Status (Read/Write)
			this.readIO[0x5] = function (parentObj) {
				return parentObj.gfx.readDISPSTAT1() | 0;
			}
			//4000006h - VCOUNT - Vertical Counter (Read only)
			this.readIO[0x6] = function (parentObj) {
				return parentObj.gfx.readVCOUNT() | 0;
			}
			//4000007h - VCOUNT - Vertical Counter (Read only)
			this.readIO[0x7] = this.readWriteOnly;
			//4000008h - BG0CNT - BG0 Control (R/W) (BG Modes 0,1 only)
			this.readIO[0x8] = function (parentObj) {
				return parentObj.gfx.readBG0CNT0() | 0;
			}
			//4000009h - BG0CNT - BG0 Control (R/W) (BG Modes 0,1 only)
			this.readIO[0x9] = function (parentObj) {
				return parentObj.gfx.readBG0CNT1() | 0;
			}
			//400000Ah - BG1CNT - BG1 Control (R/W) (BG Modes 0,1 only)
			this.readIO[0xA] = function (parentObj) {
				return parentObj.gfx.readBG1CNT0() | 0;
			}
			//400000Bh - BG1CNT - BG1 Control (R/W) (BG Modes 0,1 only)
			this.readIO[0xB] = function (parentObj) {
				return parentObj.gfx.readBG1CNT1() | 0;
			}
			//400000Ch - BG2CNT - BG2 Control (R/W) (BG Modes 0,1,2 only)
			this.readIO[0xC] = function (parentObj) {
				return parentObj.gfx.readBG2CNT0() | 0;
			}
			//400000Dh - BG2CNT - BG2 Control (R/W) (BG Modes 0,1,2 only)
			this.readIO[0xD] = function (parentObj) {
				return parentObj.gfx.readBG2CNT1() | 0;
			}
			//400000Eh - BG3CNT - BG3 Control (R/W) (BG Modes 0,2 only)
			this.readIO[0xE] = function (parentObj) {
				return parentObj.gfx.readBG3CNT0() | 0;
			}
			//400000Fh - BG3CNT - BG3 Control (R/W) (BG Modes 0,2 only)
			this.readIO[0xF] = function (parentObj) {
				return parentObj.gfx.readBG3CNT1() | 0;
			}
			//4000010h through 4000047h - WRITE ONLY
			this.fillReadTableUnused(0x10, 0x47);
			//4000048h - WININ - Control of Inside of Window(s) (R/W)
			this.readIO[0x48] = function (parentObj) {
				return parentObj.gfx.readWININ0() | 0;
			}
			//4000049h - WININ - Control of Inside of Window(s) (R/W)
			this.readIO[0x49] = function (parentObj) {
				return parentObj.gfx.readWININ1() | 0;
			}
			//400004Ah- WINOUT - Control of Outside of Windows & Inside of OBJ Window (R/W)
			this.readIO[0x4A] = function (parentObj) {
				return parentObj.gfx.readWINOUT0() | 0;
			}
			//400004AB- WINOUT - Control of Outside of Windows & Inside of OBJ Window (R/W)
			this.readIO[0x4B] = function (parentObj) {
				return parentObj.gfx.readWINOUT1() | 0;
			}
			//400004Ch - MOSAIC - Mosaic Size (W)
			this.readIO[0x4C] = this.readUnused0;
			//400004Dh - MOSAIC - Mosaic Size (W)
			this.readIO[0x4D] = this.readUnused1;
			//400004Eh - NOT USED - ZERO
			this.readIO[0x4E] = this.readUnused2;
			//400004Fh - NOT USED - ZERO
			this.readIO[0x4F] = this.readUnused3;
			//4000050h - BLDCNT - Color Special Effects Selection (R/W)
			this.readIO[0x50] = function (parentObj) {
				return parentObj.gfx.readBLDCNT0() | 0;
			}
			//4000051h - BLDCNT - Color Special Effects Selection (R/W)
			this.readIO[0x51] = function (parentObj) {
				return parentObj.gfx.readBLDCNT1() | 0;
			}
			//4000052h - BLDALPHA - Alpha Blending Coefficients (W)
			this.readIO[0x52] = this.readZero;
			//4000053h - BLDALPHA - Alpha Blending Coefficients (W)
			this.readIO[0x53] = this.readZero;
			//4000054h through 400005Fh - NOT USED - GLITCHED
			this.fillReadTableUnused(0x54, 0x5F);
			//4000060h - SOUND1CNT_L (NR10) - Channel 1 Sweep register (R/W)
			this.readIO[0x60] = function (parentObj) {
				//NR10:
				return parentObj.sound.readSOUND1CNT_L() | 0;
			}
			//4000061h - NOT USED - ZERO
			this.readIO[0x61] = this.readWriteOnly;
			//4000062h - SOUND1CNT_H (NR11, NR12) - Channel 1 Duty/Len/Envelope (R/W)
			this.readIO[0x62] = function (parentObj) {
				//NR11:
				return parentObj.sound.readSOUND1CNT_H0() | 0;
			}
			//4000063h - SOUND1CNT_H (NR11, NR12) - Channel 1 Duty/Len/Envelope (R/W)
			this.readIO[0x63] = function (parentObj) {
				//NR12:
				return parentObj.sound.readSOUND1CNT_H1() | 0;
			}
			//4000064h - SOUND1CNT_X (NR13, NR14) - Channel 1 Frequency/Control (R/W)
			this.readIO[0x64] = this.readWriteOnly;
			//4000065h - SOUND1CNT_X (NR13, NR14) - Channel 1 Frequency/Control (R/W)
			this.readIO[0x65] = function (parentObj) {
				//NR14:
				return parentObj.sound.readSOUND1CNT_X() | 0;
			}
			//4000066h - NOT USED - ZERO
			this.readIO[0x66] = this.readZero;
			//4000067h - NOT USED - ZERO
			this.readIO[0x67] = this.readZero;
			//4000068h - SOUND2CNT_L (NR21, NR22) - Channel 2 Duty/Length/Envelope (R/W)
			this.readIO[0x68] = function (parentObj) {
				//NR21:
				return parentObj.sound.readSOUND2CNT_L0() | 0;
			}
			//4000069h - SOUND2CNT_L (NR21, NR22) - Channel 2 Duty/Length/Envelope (R/W)
			this.readIO[0x69] = function (parentObj) {
				//NR22:
				return parentObj.sound.readSOUND2CNT_L1() | 0;
			}
			//400006Ah - NOT USED - ZERO
			this.readIO[0x6A] = this.readZero;
			//400006Bh - NOT USED - ZERO
			this.readIO[0x6B] = this.readZero;
			//400006Ch - SOUND2CNT_H (NR23, NR24) - Channel 2 Frequency/Control (R/W)
			this.readIO[0x6C] = this.readWriteOnly;
			//400006Dh - SOUND2CNT_H (NR23, NR24) - Channel 2 Frequency/Control (R/W)
			this.readIO[0x6D] = function (parentObj) {
				//NR24:
				return parentObj.sound.readSOUND2CNT_H() | 0;
			}
			//400006Eh - NOT USED - ZERO
			this.readIO[0x6E] = this.readZero;
			//400006Fh - NOT USED - ZERO
			this.readIO[0x6F] = this.readZero;
			//4000070h - SOUND3CNT_L (NR30) - Channel 3 Stop/Wave RAM select (R/W)
			this.readIO[0x70] = function (parentObj) {
				//NR30:
				return parentObj.sound.readSOUND3CNT_L() | 0;
			}
			//4000071h - SOUND3CNT_L (NR30) - Channel 3 Stop/Wave RAM select (R/W)
			this.readIO[0x71] = this.readWriteOnly;
			//4000072h - SOUND3CNT_H (NR31, NR32) - Channel 3 Length/Volume (R/W)
			this.readIO[0x72] = this.readWriteOnly;
			//4000073h - SOUND3CNT_H (NR31, NR32) - Channel 3 Length/Volume (R/W)
			this.readIO[0x73] = function (parentObj) {
				//NR32:
				return parentObj.sound.readSOUND3CNT_H() | 0;
			}
			//4000074h - SOUND3CNT_X (NR33, NR34) - Channel 3 Frequency/Control (R/W)
			this.readIO[0x74] = this.readWriteOnly;
			//4000075h - SOUND3CNT_X (NR33, NR34) - Channel 3 Frequency/Control (R/W)
			this.readIO[0x75] = function (parentObj) {
				//NR34:
				return parentObj.sound.readSOUND3CNT_X() | 0;
			}
			//4000076h - NOT USED - ZERO
			this.readIO[0x76] = this.readZero;
			//4000077h - NOT USED - ZERO
			this.readIO[0x77] = this.readZero;
			//4000078h - SOUND4CNT_L (NR41, NR42) - Channel 4 Length/Envelope (R/W)
			this.readIO[0x78] = this.readWriteOnly;
			//4000079h - SOUND4CNT_L (NR41, NR42) - Channel 4 Length/Envelope (R/W)
			this.readIO[0x79] = function (parentObj) {
				//NR42:
				return parentObj.sound.readSOUND4CNT_L() | 0;
			}
			//400007Ah - NOT USED - ZERO
			this.readIO[0x7A] = this.readZero;
			//400007Bh - NOT USED - ZERO
			this.readIO[0x7B] = this.readZero;
			//400007Ch - SOUND4CNT_H (NR43, NR44) - Channel 4 Frequency/Control (R/W)
			this.readIO[0x7C] = function (parentObj) {
				//NR43:
				return parentObj.sound.readSOUND4CNT_H0() | 0;
			}
			//400007Dh - SOUND4CNT_H (NR43, NR44) - Channel 4 Frequency/Control (R/W)
			this.readIO[0x7D] = function (parentObj) {
				//NR44:
				return parentObj.sound.readSOUND4CNT_H1() | 0;
			}
			//400007Eh - NOT USED - ZERO
			this.readIO[0x7E] = this.readZero;
			//400007Fh - NOT USED - ZERO
			this.readIO[0x7F] = this.readZero;
			//4000080h - SOUNDCNT_L (NR50, NR51) - Channel L/R Volume/Enable (R/W)
			this.readIO[0x80] = function (parentObj) {
				//NR50:
				return parentObj.sound.readSOUNDCNT_L0() | 0;
			}
			//4000081h - SOUNDCNT_L (NR50, NR51) - Channel L/R Volume/Enable (R/W)
			this.readIO[0x81] = function (parentObj) {
				//NR51:
				return parentObj.sound.readSOUNDCNT_L1() | 0;
			}
			//4000082h - SOUNDCNT_H (GBA only) - DMA Sound Control/Mixing (R/W)
			this.readIO[0x82] = function (parentObj) {
				return parentObj.sound.readSOUNDCNT_H0() | 0;
			}
			//4000083h - SOUNDCNT_H (GBA only) - DMA Sound Control/Mixing (R/W)
			this.readIO[0x83] = function (parentObj) {
				return parentObj.sound.readSOUNDCNT_H1() | 0;
			}
			//4000084h - SOUNDCNT_X (NR52) - Sound on/off (R/W)
			this.readIO[0x84] = function (parentObj) {
				return parentObj.sound.readSOUNDCNT_X() | 0;
			}
			//4000085h - NOT USED - ZERO
			this.readIO[0x85] = this.readWriteOnly;
			//4000086h - NOT USED - ZERO
			this.readIO[0x86] = this.readZero;
			//4000087h - NOT USED - ZERO
			this.readIO[0x87] = this.readZero;
			//4000088h - SOUNDBIAS - Sound PWM Control (R/W, see below)
			this.readIO[0x88] = function (parentObj) {
				return parentObj.sound.readSOUNDBIAS0() | 0;
			}
			//4000089h - SOUNDBIAS - Sound PWM Control (R/W, see below)
			this.readIO[0x89] = function (parentObj) {
				return parentObj.sound.readSOUNDBIAS1() | 0;
			}
			//400008Ah - NOT USED - ZERO
			this.readIO[0x8A] = this.readZero;
			//400008Bh - NOT USED - ZERO
			this.readIO[0x8B] = this.readZero;
			//400008Ch - NOT USED - GLITCHED
			this.readIO[0x8C] = this.readUnused0;
			//400008Dh - NOT USED - GLITCHED
			this.readIO[0x8D] = this.readUnused1;
			//400008Eh - NOT USED - GLITCHED
			this.readIO[0x8E] = this.readUnused2;
			//400008Fh - NOT USED - GLITCHED
			this.readIO[0x8F] = this.readUnused3;
			//4000090h - WAVE_RAM0_L - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x90] = function (parentObj) {
				return parentObj.sound.readWAVE(0);
			}
			//4000091h - WAVE_RAM0_L - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x91] = function (parentObj) {
				return parentObj.sound.readWAVE(1);
			}
			//4000092h - WAVE_RAM0_H - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x92] = function (parentObj) {
				return parentObj.sound.readWAVE(2);
			}
			//4000093h - WAVE_RAM0_H - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x93] = function (parentObj) {
				return parentObj.sound.readWAVE(3);
			}
			//4000094h - WAVE_RAM1_L - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x94] = function (parentObj) {
				return parentObj.sound.readWAVE(4);
			}
			//4000095h - WAVE_RAM1_L - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x95] = function (parentObj) {
				return parentObj.sound.readWAVE(5);
			}
			//4000096h - WAVE_RAM1_H - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x96] = function (parentObj) {
				return parentObj.sound.readWAVE(6);
			}
			//4000097h - WAVE_RAM1_H - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x97] = function (parentObj) {
				return parentObj.sound.readWAVE(7);
			}
			//4000098h - WAVE_RAM2_L - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x98] = function (parentObj) {
				return parentObj.sound.readWAVE(8);
			}
			//4000099h - WAVE_RAM2_L - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x99] = function (parentObj) {
				return parentObj.sound.readWAVE(9);
			}
			//400009Ah - WAVE_RAM2_H - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x9A] = function (parentObj) {
				return parentObj.sound.readWAVE(10);
			}
			//400009Bh - WAVE_RAM2_H - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x9B] = function (parentObj) {
				return parentObj.sound.readWAVE(11);
			}
			//400009Ch - WAVE_RAM3_L - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x9C] = function (parentObj) {
				return parentObj.sound.readWAVE(12);
			}
			//400009Dh - WAVE_RAM3_L - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x9D] = function (parentObj) {
				return parentObj.sound.readWAVE(13);
			}
			//400009Eh - WAVE_RAM3_H - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x9E] = function (parentObj) {
				return parentObj.sound.readWAVE(14);
			}
			//400009Fh - WAVE_RAM3_H - Channel 3 Wave Pattern RAM (W/R)
			this.readIO[0x9F] = function (parentObj) {
				return parentObj.sound.readWAVE(15);
			}
			//40000A0h through 40000B9h - WRITE ONLY
			this.fillReadTableUnused(0xA0, 0xB9);
			//40000BAh - DMA0CNT_H - DMA 0 Control (R/W)
			this.readIO[0xBA] = function (parentObj) {
				return parentObj.dma.readDMAControl0(0);
			}
			//40000BBh - DMA0CNT_H - DMA 0 Control (R/W)
			this.readIO[0xBB] = function (parentObj) {
				return parentObj.dma.readDMAControl1(0);
			}
			//40000BCh through 40000C5h - WRITE ONLY
			this.fillReadTableUnused(0xBC, 0xC5);
			//40000C6h - DMA1CNT_H - DMA 1 Control (R/W)
			this.readIO[0xC6] = function (parentObj) {
				return parentObj.dma.readDMAControl0(1);
			}
			//40000C7h - DMA1CNT_H - DMA 1 Control (R/W)
			this.readIO[0xC7] = function (parentObj) {
				return parentObj.dma.readDMAControl1(1);
			}
			//40000C8h through 40000D1h - WRITE ONLY
			this.fillReadTableUnused(0xC8, 0xD1);
			//40000D2h - DMA2CNT_H - DMA 2 Control (R/W)
			this.readIO[0xD2] = function (parentObj) {
				return parentObj.dma.readDMAControl0(2);
			}
			//40000D3h - DMA2CNT_H - DMA 2 Control (R/W)
			this.readIO[0xD3] = function (parentObj) {
				return parentObj.dma.readDMAControl1(2);
			}
			//40000D4h through 40000DDh - WRITE ONLY
			this.fillReadTableUnused(0xD4, 0xDD);
			//40000DEh - DMA3CNT_H - DMA 3 Control (R/W)
			this.readIO[0xDE] = function (parentObj) {
				return parentObj.dma.readDMAControl0(3);
			}
			//40000DFh - DMA3CNT_H - DMA 3 Control (R/W)
			this.readIO[0xDF] = function (parentObj) {
				return parentObj.dma.readDMAControl1(3);
			}
			//40000E0h through 40000FFh - NOT USED - GLITCHED
			this.fillReadTableUnused(0xE0, 0xFF);
			//4000100h - TM0CNT_L - Timer 0 Counter/Reload (R/W)
			this.readIO[0x100] = function (parentObj) {
				return parentObj.timer.readTM0CNT_L0() | 0;
			}
			//4000101h - TM0CNT_L - Timer 0 Counter/Reload (R/W)
			this.readIO[0x101] = function (parentObj) {
				return parentObj.timer.readTM0CNT_L1() | 0;
			}
			//4000102h - TM0CNT_H - Timer 0 Control (R/W)
			this.readIO[0x102] = function (parentObj) {
				return parentObj.timer.readTM0CNT_H() | 0;
			}
			//4000103h - TM0CNT_H - Timer 0 Control (R/W)
			this.readIO[0x103] = this.readWriteOnly;
			//4000104h - TM1CNT_L - Timer 1 Counter/Reload (R/W)
			this.readIO[0x104] = function (parentObj) {
				return parentObj.timer.readTM1CNT_L0() | 0;
			}
			//4000105h - TM1CNT_L - Timer 1 Counter/Reload (R/W)
			this.readIO[0x105] = function (parentObj) {
				return parentObj.timer.readTM1CNT_L1() | 0;
			}
			//4000106h - TM1CNT_H - Timer 1 Control (R/W)
			this.readIO[0x106] = function (parentObj) {
				return parentObj.timer.readTM1CNT_H() | 0;
			}
			//4000107h - TM1CNT_H - Timer 1 Control (R/W)
			this.readIO[0x107] = this.readWriteOnly;
			//4000108h - TM2CNT_L - Timer 2 Counter/Reload (R/W)
			this.readIO[0x108] = function (parentObj) {
				return parentObj.timer.readTM2CNT_L0() | 0;
			}
			//4000109h - TM2CNT_L - Timer 2 Counter/Reload (R/W)
			this.readIO[0x109] = function (parentObj) {
				return parentObj.timer.readTM2CNT_L1() | 0;
			}
			//400010Ah - TM2CNT_H - Timer 2 Control (R/W)
			this.readIO[0x10A] = function (parentObj) {
				return parentObj.timer.readTM2CNT_H() | 0;
			}
			//400010Bh - TM2CNT_H - Timer 2 Control (R/W)
			this.readIO[0x10B] = this.readWriteOnly;
			//400010Ch - TM3CNT_L - Timer 3 Counter/Reload (R/W)
			this.readIO[0x10C] = function (parentObj) {
				return parentObj.timer.readTM3CNT_L0() | 0;
			}
			//400010Dh - TM3CNT_L - Timer 3 Counter/Reload (R/W)
			this.readIO[0x10D] = function (parentObj) {
				return parentObj.timer.readTM3CNT_L1() | 0;
			}
			//400010Eh - TM3CNT_H - Timer 3 Control (R/W)
			this.readIO[0x10E] = function (parentObj) {
				return parentObj.timer.readTM3CNT_H() | 0;
			}
			//400010Fh - TM3CNT_H - Timer 3 Control (R/W)
			this.readIO[0x10F] = this.readWriteOnly;
			//4000110h through 400011Fh - NOT USED - GLITCHED
			this.fillReadTableUnused(0x110, 0x11F);
			//4000120h - Serial Data A (R/W)
			this.readIO[0x120] = function (parentObj) {
				return parentObj.serial.readSIODATA_A0() | 0;
			}
			//4000121h - Serial Data A (R/W)
			this.readIO[0x121] = function (parentObj) {
				return parentObj.serial.readSIODATA_A1() | 0;
			}
			//4000122h - Serial Data B (R/W)
			this.readIO[0x122] = function (parentObj) {
				return parentObj.serial.readSIODATA_B0() | 0;
			}
			//4000123h - Serial Data B (R/W)
			this.readIO[0x123] = function (parentObj) {
				return parentObj.serial.readSIODATA_B1() | 0;
			}
			//4000124h - Serial Data C (R/W)
			this.readIO[0x124] = function (parentObj) {
				return parentObj.serial.readSIODATA_C0() | 0;
			}
			//4000125h - Serial Data C (R/W)
			this.readIO[0x125] = function (parentObj) {
				return parentObj.serial.readSIODATA_C1() | 0;
			}
			//4000126h - Serial Data D (R/W)
			this.readIO[0x126] = function (parentObj) {
				return parentObj.serial.readSIODATA_D0() | 0;
			}
			//4000127h - Serial Data D (R/W)
			this.readIO[0x127] = function (parentObj) {
				return parentObj.serial.readSIODATA_D1() | 0;
			}
			//4000128h - SIOCNT - SIO Sub Mode Control (R/W)
			this.readIO[0x128] = function (parentObj) {
				return parentObj.serial.readSIOCNT0() | 0;
			}
			//4000129h - SIOCNT - SIO Sub Mode Control (R/W)
			this.readIO[0x129] = function (parentObj) {
				return parentObj.serial.readSIOCNT1() | 0;
			}
			//400012Ah - SIOMLT_SEND - Data Send Register (R/W)
			this.readIO[0x12A] = function (parentObj) {
				return parentObj.serial.readSIODATA8_0() | 0;
			}
			//400012Bh - SIOMLT_SEND - Data Send Register (R/W)
			this.readIO[0x12B] = function (parentObj) {
				return parentObj.serial.readSIODATA8_1() | 0;
			}
			//400012Ch through 400012Fh - NOT USED - GLITCHED
			this.fillReadTableUnused(0x12C, 0x12F);
			//4000130h - KEYINPUT - Key Status (R)
			this.readIO[0x130] = function (parentObj) {
				return parentObj.joypad.readKeyStatus0() | 0;
			}
			//4000131h - KEYINPUT - Key Status (R)
			this.readIO[0x131] = function (parentObj) {
				return parentObj.joypad.readKeyStatus1() | 0;
			}
			//4000132h - KEYCNT - Key Interrupt Control (R/W)
			this.readIO[0x132] = function (parentObj) {
				return parentObj.joypad.readKeyControl0() | 0;
			}
			//4000133h - KEYCNT - Key Interrupt Control (R/W)
			this.readIO[0x133] = function (parentObj) {
				return parentObj.joypad.readKeyControl1() | 0;
			}
			//4000134h - RCNT (R/W) - Mode Selection
			this.readIO[0x134] = function (parentObj) {
				return parentObj.serial.readRCNT0() | 0;
			}
			//4000135h - RCNT (R/W) - Mode Selection
			this.readIO[0x135] = function (parentObj) {
				return parentObj.serial.readRCNT1() | 0;
			}
			//4000136h - NOT USED - ZERO
			this.readIO[0x136] = this.readZero;
			//4000137h - NOT USED - ZERO
			this.readIO[0x137] = this.readZero;
			//4000138h through 400013Fh - NOT USED - GLITCHED
			this.fillReadTableUnused(0x138, 0x13F);
			//4000140h - JOYCNT - JOY BUS Control Register (R/W)
			this.readIO[0x140] = function (parentObj) {
				return parentObj.serial.readJOYCNT() | 0;
			}
			//4000141h - JOYCNT - JOY BUS Control Register (R/W)
			this.readIO[0x141] = this.readWriteOnly;
			//4000142h - NOT USED - ZERO
			this.readIO[0x142] = this.readZero;
			//4000143h - NOT USED - ZERO
			this.readIO[0x143] = this.readZero;
			//4000144h through 400014Fh - NOT USED - GLITCHED
			this.fillReadTableUnused(0x144, 0x14F);
			//4000150h - JoyBus Receive (R/W)
			this.readIO[0x150] = function (parentObj) {
				return parentObj.serial.readJOYBUS_RECV0() | 0;
			}
			//4000151h - JoyBus Receive (R/W)
			this.readIO[0x151] = function (parentObj) {
				return parentObj.serial.readJOYBUS_RECV1() | 0;
			}
			//4000152h - JoyBus Receive (R/W)
			this.readIO[0x152] = function (parentObj) {
				return parentObj.serial.readJOYBUS_RECV2() | 0;
			}
			//4000153h - JoyBus Receive (R/W)
			this.readIO[0x153] = function (parentObj) {
				return parentObj.serial.readJOYBUS_RECV3() | 0;
			}
			//4000154h - JoyBus Send (R/W)
			this.readIO[0x154] = function (parentObj) {
				return parentObj.serial.readJOYBUS_SEND0() | 0;
			}
			//4000155h - JoyBus Send (R/W)
			this.readIO[0x155] = function (parentObj) {
				return parentObj.serial.readJOYBUS_SEND1() | 0;
			}
			//4000156h - JoyBus Send (R/W)
			this.readIO[0x156] = function (parentObj) {
				return parentObj.serial.readJOYBUS_SEND2() | 0;
			}
			//4000157h - JoyBus Send (R/W)
			this.readIO[0x157] = function (parentObj) {
				return parentObj.serial.readJOYBUS_SEND3() | 0;
			}
			//4000158h - JoyBus Stat (R/W)
			this.readIO[0x158] = function (parentObj) {
				return parentObj.serial.readJOYBUS_STAT() | 0;
			}
			//4000159h - JoyBus Stat (R/W)
			this.readIO[0x159] = this.readWriteOnly;
			//400015Ah - NOT USED - ZERO
			this.readIO[0x15A] = this.readZero;
			//400015Bh - NOT USED - ZERO
			this.readIO[0x15B] = this.readZero;
			//400015Ch through 40001FFh - NOT USED - GLITCHED
			this.fillReadTableUnused(0x15C, 0x1FF);
			//4000200h - IE - Interrupt Enable Register (R/W)
			this.readIO[0x200] = function (parentObj) {
				return parentObj.irq.readIE0() | 0;
			}
			//4000201h - IE - Interrupt Enable Register (R/W)
			this.readIO[0x201] = function (parentObj) {
				return parentObj.irq.readIE1() | 0;
			}
			//4000202h - IF - Interrupt Request Flags / IRQ Acknowledge
			this.readIO[0x202] = function (parentObj) {
				return parentObj.irq.readIF0() | 0;
			}
			//4000203h - IF - Interrupt Request Flags / IRQ Acknowledge
			this.readIO[0x203] = function (parentObj) {
				return parentObj.irq.readIF1() | 0;
			}
			//4000204h - WAITCNT - Waitstate Control (R/W)
			this.readIO[0x204] = function (parentObj) {
				return parentObj.wait.readWAITCNT0() | 0;
			}
			//4000205h - WAITCNT - Waitstate Control (R/W)
			this.readIO[0x205] = function (parentObj) {
				return parentObj.wait.readWAITCNT1() | 0;
			}
			//4000206h - NOT USED - ZERO
			this.readIO[0x206] = this.readZero;
			//4000207h - NOT USED - ZERO
			this.readIO[0x207] = this.readZero;
			//4000208h - IME - Interrupt Master Enable Register (R/W)
			this.readIO[0x208] = function (parentObj) {
				return parentObj.irq.readIME() | 0;
			}
			//4000209h - IME - Interrupt Master Enable Register (R/W)
			this.readIO[0x209] = this.readWriteOnly;
			//400020Ah - NOT USED - ZERO
			this.readIO[0x20A] = this.readZero;
			//400020Bh - NOT USED - ZERO
			this.readIO[0x20B] = this.readZero;
			//400020Ch through 40002FFh - NOT USED - GLITCHED
			this.fillReadTableUnused(0x20C, 0x2FF);
			//4000300h - POSTFLG - BYTE - Undocumented - Post Boot / Debug Control (R/W)
			this.readIO[0x300] = function (parentObj) {
				return parentObj.wait.readPOSTBOOT() | 0;
			}
			//4000301h - HALTCNT - BYTE - Undocumented - Low Power Mode Control (W)
			this.readIO[0x301] = this.readWriteOnly;
			//4000302h - NOT USED - ZERO
			this.readIO[0x302] = this.readZero;
			//4000303h - NOT USED - ZERO
			this.readIO[0x303] = this.readZero;
		}
		public function fillReadTableUnused (from, to) {
			//Fill in slots of the i/o read table:
			while (from <= to) {
				this.readIO[from++] = this.readUnused0;
				this.readIO[from++] = this.readUnused1;
				this.readIO[from++] = this.readUnused2;
				this.readIO[from++] = this.readUnused3;
			}
		}
		public function writeExternalWRAM (parentObj, address, data, busReqNumber) {
			address = address | 0;
			data = data | 0;
			busReqNumber = busReqNumber | 0;
			//External WRAM:
			parentObj.wait.WRAMAccess(busReqNumber | 0);
			parentObj.externalRAM[address & 0x3FFFF] = data | 0;
			//Logger.logMemory("Wrt WRAM " + this.IOCore);
		}
		public function writeExternalWRAM8 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			//External WRAM:
			parentObj.wait.WRAMAccess8();
			parentObj.externalRAM[address & 0x3FFFF] = data | 0;
		}
		public function writeExternalWRAM16Slow (parentObj, address, data) {
			//External WRAM:
			parentObj.wait.WRAMAccess16();
			parentObj.externalRAM[address & 0x3FFFF] = data & 0xFF;
			parentObj.externalRAM[(address + 1) & 0x3FFFF] = data >> 8;
		}
		public function writeExternalWRAM16Optimized (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			//External WRAM:
			parentObj.wait.WRAMAccess16();
			parentObj.externalRAM16[(address & 0x3FFFF) >> 1] = data | 0;
		}
		public function writeExternalWRAM32Slow (parentObj, address, data) {
			//External WRAM:
			parentObj.wait.WRAMAccess32();
			parentObj.externalRAM[address & 0x3FFFF] = data & 0xFF;
			parentObj.externalRAM[(address + 1) & 0x3FFFF] = (data >> 8) & 0xFF;
			parentObj.externalRAM[(address + 2) & 0x3FFFF] = (data >> 16) & 0xFF;
			parentObj.externalRAM[(address + 3) & 0x3FFFF] = (data >> 24) & 0xFF;
		}
		public function writeExternalWRAM32Optimized (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			//External WRAM:
			parentObj.wait.WRAMAccess32();
			parentObj.externalRAM32[(address & 0x3FFFF) >> 2] = data | 0;
		}
		public function writeInternalWRAM (parentObj, address, data, busReqNumber) {
			address = address | 0;
			data = data | 0;
			busReqNumber = busReqNumber | 0;
			//Internal WRAM:
			parentObj.wait.FASTAccess(busReqNumber | 0);
			parentObj.internalRAM[address & 0x7FFF] = data | 0;
		}
		public function writeInternalWRAM8 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			//Internal WRAM:
			parentObj.wait.FASTAccess2();
			parentObj.internalRAM[address & 0x7FFF] = data | 0;
		}
		public function writeInternalWRAM16Slow (parentObj, address, data) {
			//Internal WRAM:
			parentObj.wait.FASTAccess2();
			parentObj.internalRAM[address & 0x7FFF] = data & 0xFF;
			parentObj.internalRAM[(address + 1) & 0x7FFF] = data >> 8;
		}
		public function writeInternalWRAM16Optimized (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			//Internal WRAM:
			parentObj.wait.FASTAccess2();
			parentObj.internalRAM16[(address & 0x7FFF) >> 1] = data | 0;
		}
		public function writeInternalWRAM32Slow (parentObj, address, data) {
			//Internal WRAM:
			parentObj.wait.FASTAccess2();
			parentObj.internalRAM[address & 0x7FFF] = data & 0xFF;
			parentObj.internalRAM[(address + 1) & 0x7FFF] = (data >> 8) & 0xFF;
			parentObj.internalRAM[(address + 2) & 0x7FFF] = (data >> 16) & 0xFF;
			parentObj.internalRAM[(address + 3) & 0x7FFF] = (data >> 24) & 0xFF;
		}
		public function writeInternalWRAM32Optimized (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			//Internal WRAM:
			parentObj.wait.FASTAccess2();
			parentObj.internalRAM32[(address & 0x7FFF) >> 2] = data | 0;
		}
		public function writeIODispatch (parentObj, address, data, busReqNumber) {
			address = address | 0;
			data = data | 0;
			busReqNumber = busReqNumber | 0;
			parentObj.wait.FASTAccess(busReqNumber | 0);
			if (address < 0x4000304) {
				//IO Write:
				parentObj.IOCore.updateCoreClocking();
				parentObj.writeIO[address & 0x3FF](parentObj, data | 0);
				parentObj.IOCore.updateCoreEventTime();
			}
			else if ((address & 0x4FF0800) == 0x4000800) {
				//WRAM wait state control:
				parentObj.wait.writeConfigureWRAM(address, data | 0);
			}
		}
		public function writeIODispatch8 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.FASTAccess2();
			if (address < 0x4000304) {
				//IO Write:
				parentObj.IOCore.updateCoreClocking();
				parentObj.writeIO[address & 0x3FF](parentObj, data | 0);
				parentObj.IOCore.updateCoreEventTime();
			}
			else if ((address & 0x4FF0800) == 0x4000800) {
				//WRAM wait state control:
				parentObj.wait.writeConfigureWRAM(address, data | 0);
			}
		}
		public function writeIODispatch16 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.FASTAccess2();
			if (address < 0x4000304) {
				//IO Write:
				parentObj.IOCore.updateCoreClocking();
				parentObj.writeIO[address & 0x3FF](parentObj, data & 0xFF);
				parentObj.writeIO[(address + 1) & 0x3FF](parentObj, (data >> 8) & 0xFF);
				parentObj.IOCore.updateCoreEventTime();
			}
			else if ((address & 0x4FF0800) == 0x4000800) {
				//WRAM wait state control:
				parentObj.wait.writeConfigureWRAM(address | 0, data & 0xFF);
			}
		}
		public function writeIODispatch32 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.FASTAccess2();
			if (address < 0x4000304) {
				//IO Write:
				parentObj.IOCore.updateCoreClocking();
				parentObj.writeIO[address & 0x3FF](parentObj, data & 0xFF);
				parentObj.writeIO[(address + 1) & 0x3FF](parentObj, (data >> 8) & 0xFF);
				parentObj.writeIO[(address + 2) & 0x3FF](parentObj, (data >> 16) & 0xFF);
				parentObj.writeIO[(address + 3) & 0x3FF](parentObj, (data >> 24) & 0xFF);
				parentObj.IOCore.updateCoreEventTime();
			}
			else if ((address & 0x4FF0800) == 0x4000800) {
				//WRAM wait state control:
				parentObj.wait.writeConfigureWRAM(address | 0, data & 0xFF);
			}
		}
		public function writeVRAM (parentObj, address, data, busReqNumber) {
			address = address | 0;
			data = data | 0;
			busReqNumber = busReqNumber | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess(busReqNumber | 0);
			if ((address & 0x10000) != 0) {
				parentObj.gfx.writeVRAM(address & 0x17FFF, data | 0);
			}
			else {
				parentObj.gfx.writeVRAM(address & 0xFFFF, data | 0);
			}
		}
		public function writeVRAM8 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess8();
			if ((address & 0x10000) != 0) {
				parentObj.gfx.writeVRAM(address & 0x17FFF, data | 0);
			}
			else {
				parentObj.gfx.writeVRAM(address & 0xFFFF, data | 0);
			}
		}
		public function writeVRAM16 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess16();
			if ((address & 0x10000) != 0) {
				parentObj.gfx.writeVRAM16(address & 0x17FFF, data | 0);
			}
			else {
				parentObj.gfx.writeVRAM16(address & 0xFFFF, data | 0);
			}
		}
		public function writeVRAM32 (parentObj, address, data) {
			
			address = address | 0;
			data = data | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess32();
			if ((address & 0x10000) != 0) {
				parentObj.gfx.writeVRAM32(address & 0x17FFF, data | 0);
			}
			else {
				parentObj.gfx.writeVRAM32(address & 0xFFFF, data | 0);
			}
		}
		public function writeOAM (parentObj, address, data, busReqNumber) {
			address = address | 0;
			data = data | 0;
			busReqNumber = busReqNumber | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.OAMAccess(busReqNumber | 0);
			parentObj.gfx.writeOAM(address & 0x3FF, data | 0);
		}
		public function writeOAM8 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.OAMAccess8();
			parentObj.gfx.writeOAM(address & 0x3FF, data | 0);
		}
		public function writeOAM16 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.OAMAccess16();
			parentObj.gfx.writeOAM(address & 0x3FF, data & 0xFF);
			parentObj.gfx.writeOAM((address + 1) & 0x3FF, data >> 8);
		}
		public function writeOAM32 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.OAMAccess32();
			parentObj.gfx.writeOAM(address & 0x3FF, data & 0xFF);
			parentObj.gfx.writeOAM((address + 1) & 0x3FF, (data >> 8) & 0xFF);
			parentObj.gfx.writeOAM((address + 2) & 0x3FF, (data >> 16) & 0xFF);
			parentObj.gfx.writeOAM((address + 3) & 0x3FF, (data >> 24) & 0xFF);
		}
		public function writePalette (parentObj, address, data, busReqNumber) {
			address = address | 0;
			data = data | 0;
			busReqNumber = busReqNumber | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess(busReqNumber | 0);
			parentObj.gfx.writePalette(address & 0x3FF, data | 0);
		}
		public function writePalette8 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess8();
			parentObj.gfx.writePalette(address & 0x3FF, data | 0);
		}
		public function writePalette16 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess16();
			parentObj.gfx.writePalette(address & 0x3FF, data & 0xFF);
			parentObj.gfx.writePalette((address + 1) & 0x3FF, data >> 8);
		}
		public function writePalette32 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess32();
			parentObj.gfx.writePalette(address & 0x3FF, data & 0xFF);
			parentObj.gfx.writePalette((address + 1) & 0x3FF, (data >> 8) & 0xFF);
			parentObj.gfx.writePalette((address + 2) & 0x3FF, (data >> 16) & 0xFF);
			parentObj.gfx.writePalette((address + 3) & 0x3FF, (data >> 24) & 0xFF);
		}
		public function writeROM0 (parentObj, address, data, busReqNumber) {
			address = address | 0;
			data = data | 0;
			busReqNumber = busReqNumber | 0;
			parentObj.wait.ROM0Access(busReqNumber | 0);
			parentObj.cartridge.writeROM(address & 0x1FFFFFF, data | 0);
		}
		public function writeROM08 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.ROM0Access8();
			parentObj.cartridge.writeROM(address & 0x1FFFFFF, data | 0);
		}
		public function writeROM016 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.ROM0Access16();
			parentObj.cartridge.writeROM(address & 0x1FFFFFF, data & 0xFF);
			parentObj.cartridge.writeROM((address + 1) & 0x1FFFFFF, data >> 8);
		}
		public function writeROM032 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.ROM0Access32();
			parentObj.cartridge.writeROM(address & 0x1FFFFFF, data & 0xFF);
			parentObj.cartridge.writeROM((address + 1) & 0x1FFFFFF, (data >> 8) & 0xFF);
			parentObj.cartridge.writeROM((address + 2) & 0x1FFFFFF, (data >> 16) & 0xFF);
			parentObj.cartridge.writeROM((address + 3) & 0x1FFFFFF, (data >> 24) & 0xFF);
		}
		public function writeROM1 (parentObj, address, data, busReqNumber) {
			address = address | 0;
			data = data | 0;
			busReqNumber = busReqNumber | 0;
			parentObj.wait.ROM1Access(busReqNumber | 0);
			parentObj.cartridge.writeROM(address & 0x1FFFFFF, data | 0);
		}
		public function writeROM18 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.ROM1Access8();
			parentObj.cartridge.writeROM(address & 0x1FFFFFF, data | 0);
		}
		public function writeROM116 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.ROM1Access16();
			parentObj.cartridge.writeROM(address & 0x1FFFFFF, data & 0xFF);
			parentObj.cartridge.writeROM((address + 1) & 0x1FFFFFF, data >> 8);
		}
		public function writeROM132 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.ROM1Access32();
			parentObj.cartridge.writeROM(address & 0x1FFFFFF, data & 0xFF);
			parentObj.cartridge.writeROM((address + 1) & 0x1FFFFFF, (data >> 8) & 0xFF);
			parentObj.cartridge.writeROM((address + 2) & 0x1FFFFFF, (data >> 16) & 0xFF);
			parentObj.cartridge.writeROM((address + 3) & 0x1FFFFFF, (data >> 24) & 0xFF);
		}
		public function writeROM2 (parentObj, address, data, busReqNumber) {
			address = address | 0;
			data = data | 0;
			busReqNumber = busReqNumber | 0;
			parentObj.wait.ROM2Access(busReqNumber | 0);
			parentObj.cartridge.writeROM(address & 0x1FFFFFF, data | 0);
		}
		public function writeROM28 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.ROM2Access8();
			parentObj.cartridge.writeROM(address & 0x1FFFFFF, data | 0);
		}
		public function writeROM216 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.ROM2Access16();
			parentObj.cartridge.writeROM(address & 0x1FFFFFF, data & 0xFF);
			parentObj.cartridge.writeROM((address + 1) & 0x1FFFFFF, data >> 8);
		}
		public function writeROM232 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.ROM2Access32();
			parentObj.cartridge.writeROM(address & 0x1FFFFFF, data & 0xFF);
			parentObj.cartridge.writeROM((address + 1) & 0x1FFFFFF, (data >> 8) & 0xFF);
			parentObj.cartridge.writeROM((address + 2) & 0x1FFFFFF, (data >> 16) & 0xFF);
			parentObj.cartridge.writeROM((address + 3) & 0x1FFFFFF, (data >> 24) & 0xFF);
		}
		public function writeSRAM (parentObj, address, data, busReqNumber) {
			address = address | 0;
			data = data | 0;
			busReqNumber = busReqNumber | 0;
			if ((address & 0x3) == busReqNumber) {
				parentObj.wait.SRAMAccess();
				parentObj.cartridge.writeSRAM(address & 0xFFFF, data & 0xFF);
			}
		}
		public function writeSRAM8 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.SRAMAccess();
			parentObj.cartridge.writeSRAM(address & 0xFFFF, data & 0xFF);
		}
		public function writeSRAM16 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.SRAMAccess();
			parentObj.cartridge.writeSRAM(address & 0xFFFF, (data >> ((address & 0x1) << 3)) & 0xFF);
		}
		public function writeSRAM32 (parentObj, address, data) {
			address = address | 0;
			data = data | 0;
			parentObj.wait.SRAMAccess();
			parentObj.cartridge.writeSRAM(address & 0xFFFF, (data >> ((address & 0x3) << 3)) & 0xFF);
		}
		public function NOP (parentObj, data) {
			//Ignore the data write...
		}
		public function writeUnused (parentObj, address, data, busReqNumber) {
			//Ignore the data write...
			parentObj.wait.FASTAccess(busReqNumber | 0);
		}
		public function writeUnused8 (parentObj, address, data) {
			//Ignore the data write...
			parentObj.wait.FASTAccess2();
		}
		public function writeUnused16 (parentObj, address, data) {
			//Ignore the data write...
			parentObj.wait.FASTAccess2();
		}
		public function writeUnused32 (parentObj, address, data) {
			//Ignore the data write...
			parentObj.wait.FASTAccess2();
		}
		public function remapWRAM (data) {
			data = data | 0;
			if ((data & 0x01) == 0) {
				this.memoryWriter[2] = ((data & 0x20) == 0x20) ? this.writeExternalWRAM : this.writeInternalWRAM;
				this.memoryReader[2] = ((data & 0x20) == 0x20) ? this.readExternalWRAM : this.readInternalWRAM;
				this.memoryWriter[3] = this.writeInternalWRAM;
				this.memoryReader[3] = this.readInternalWRAM;
			}
			else {
				this.memoryWriter[2] = this.memoryWriter[3] = this.writeUnused;
				this.memoryReader[2] = this.memoryReader[3] = this.readUnused;
			}
		}
		public function readBIOS (parentObj, address, busReqNumber) {
			address = address | 0;
			busReqNumber = busReqNumber | 0;
			parentObj.wait.FASTAccess(busReqNumber | 0);
			if (address < 0x4000) {
				if (parentObj.cpu.registers[15] < 0x4000) {
					//If reading from BIOS while executing it:
					parentObj.lastBIOSREAD[address & 0x3] = (parentObj.cpu.registers[15] >> ((address & 0x3) << 3)) & 0xFF;
					return parentObj.BIOS[address | 0] | 0;
				}
				else {
					//Not allowed to read from BIOS while executing outside of it:
					return parentObj.lastBIOSREAD[address & 0x3] | 0;
				}
			}
			else {
				return parentObj.readUnused(parentObj, address | 0) | 0;
			}
		}
		public function readBIOS8 (parentObj, address) {
			address = address | 0;
			parentObj.wait.FASTAccess2();
			if (address < 0x4000) {
				if (parentObj.cpu.registers[15] < 0x4000) {
					//If reading from BIOS while executing it:
					parentObj.lastBIOSREAD[address & 0x3] = (parentObj.cpu.registers[15] >> ((address & 0x3) << 3)) & 0xFF;
					return parentObj.BIOS[address | 0] | 0;
				}
				else {
					//Not allowed to read from BIOS while executing outside of it:
					return parentObj.lastBIOSREAD[address & 0x3] | 0;
				}
			}
			else {
				return parentObj.readUnused(parentObj, address | 0) | 0;
			}
		}
		public function readBIOS16Slow (parentObj, address) {
			address = address | 0;
			parentObj.wait.FASTAccess2();
			if (address < 0x4000) {
				if (parentObj.cpu.registers[15] < 0x4000) {
					//If reading from BIOS while executing it:
					parentObj.lastBIOSREAD[address & 0x3] = (parentObj.cpu.registers[15] >> ((address & 0x3) << 3)) & 0xFF;
					parentObj.lastBIOSREAD[(address + 1) & 0x3] = (parentObj.cpu.registers[15] >> (((address + 1) & 0x3) << 3)) & 0xFF;
					return parentObj.BIOS[address] | (parentObj.BIOS[address | 1] << 8);
				}
				else {
					//Not allowed to read from BIOS while executing outside of it:
					return parentObj.lastBIOSREAD[address & 0x2] | (parentObj.lastBIOSREAD[(address & 0x2) | 1] << 8);
				}
			}
			else {
				return parentObj.readUnused16(parentObj, address) | 0;
			}
		}
		public function readBIOS16Optimized (parentObj, address) {
			address = address | 0;
			parentObj.wait.FASTAccess2();
			if (address < 0x4000) {
				address >>= 1;
				if (parentObj.cpu.registers[15] < 0x4000) {
					//If reading from BIOS while executing it:
					parentObj.lastBIOSREAD16[address & 0x1] = (parentObj.cpu.registers[15] >> ((address & 0x1) << 16)) & 0xFFFF;
					return parentObj.BIOS16[address & 0x1FFF] | 0;
				}
				else {
					//Not allowed to read from BIOS while executing outside of it:
					return parentObj.lastBIOSREAD16[address & 0x1] | 0;
				}
			}
			else {
				return parentObj.readUnused16(parentObj, address | 0) | 0;
			}
		}
		public function readBIOS32Slow (parentObj, address) {
			address = address | 0;
			parentObj.wait.FASTAccess2();
			if (address < 0x4000) {
				if (parentObj.cpu.registers[15] < 0x4000) {
					//If reading from BIOS while executing it:
					parentObj.lastBIOSREAD[0] = parentObj.cpu.registers[15] & 0xFF;
					parentObj.lastBIOSREAD[1] = (parentObj.cpu.registers[15] >> 8) & 0xFF;
					parentObj.lastBIOSREAD[2] = (parentObj.cpu.registers[15] >> 16) & 0xFF;
					parentObj.lastBIOSREAD[3] = (parentObj.cpu.registers[15] >> 32) & 0xFF;
					return parentObj.BIOS[address] | (parentObj.BIOS[address | 1] << 8) | (parentObj.BIOS[address | 2] << 16)  | (parentObj.BIOS[address | 3] << 24);
				}
				else {
					//Not allowed to read from BIOS while executing outside of it:
					return parentObj.lastBIOSREAD[0] | (parentObj.lastBIOSREAD[1] << 8) | (parentObj.lastBIOSREAD[2] << 16) | (parentObj.lastBIOSREAD[3] << 24);
				}
			}
			else {
				return parentObj.readUnused32(parentObj, address) | 0;
			}
		}
		public function readBIOS32Optimized (parentObj, address) {
			address = address | 0;
			parentObj.wait.FASTAccess2();
			if (address < 0x4000) {
				address >>= 2;
				if (parentObj.cpu.registers[15] < 0x4000) {
					//If reading from BIOS while executing it:
					parentObj.lastBIOSREAD32[0] = parentObj.cpu.registers[15] | 0;
					return parentObj.BIOS32[address & 0xFFF] | 0;
				}
				else {
					//Not allowed to read from BIOS while executing outside of it:
					return parentObj.lastBIOSREAD32[0] | 0;
				}
			}
			else {
				return parentObj.readUnused16(parentObj, address | 0) | 0;
			}
		}
		public function readExternalWRAM (parentObj, address, busReqNumber) {
			address = address | 0;
			busReqNumber = busReqNumber | 0;
			//External WRAM:
			parentObj.wait.WRAMAccess(busReqNumber | 0);
			return parentObj.externalRAM[address & 0x3FFFF] | 0;
		}
		public function readExternalWRAM8 (parentObj, address) {
			address = address | 0;
			//External WRAM:
			parentObj.wait.WRAMAccess8();
			return parentObj.externalRAM[address & 0x3FFFF] | 0;
		}
		public function readExternalWRAM16Slow (parentObj, address) {
			//External WRAM:
			parentObj.wait.WRAMAccess16();
			return parentObj.externalRAM[address & 0x3FFFF] | (parentObj.externalRAM[(address + 1) & 0x3FFFF] << 8);
		}
		public function readExternalWRAM16Optimized (parentObj, address) {
			address = address | 0;
			//External WRAM:
			parentObj.wait.WRAMAccess16();
			return parentObj.externalRAM16[(address & 0x3FFFF) >> 1] | 0;
		}
		public function readExternalWRAM32Slow (parentObj, address) {
			//External WRAM:
			parentObj.wait.WRAMAccess32();
			return parentObj.externalRAM[address & 0x3FFFF] | (parentObj.externalRAM[(address + 1) & 0x3FFFF] << 8) | (parentObj.externalRAM[(address + 2) & 0x3FFFF] << 16) | (parentObj.externalRAM[(address + 3) & 0x3FFFF] << 24);
		}
		public function readExternalWRAM32Optimized (parentObj, address) {
			address = address | 0;
			//External WRAM:
			parentObj.wait.WRAMAccess32();
			return parentObj.externalRAM32[(address & 0x3FFFF) >> 2] | 0;
		}
		public function readInternalWRAM (parentObj, address, busReqNumber) {
			address = address | 0;
			busReqNumber = busReqNumber | 0;
			//Internal WRAM:
			parentObj.wait.FASTAccess(busReqNumber | 0);
			return parentObj.internalRAM[address & 0x7FFF] | 0;
		}
		public function readInternalWRAM8 (parentObj, address) {
			address = address | 0;
			//Internal WRAM:
			parentObj.wait.FASTAccess2();
			return parentObj.internalRAM[address & 0x7FFF] | 0;
		}
		public function readInternalWRAM16Slow (parentObj, address) {
			//Internal WRAM:
			parentObj.wait.FASTAccess2();
			return parentObj.internalRAM[address & 0x7FFF] | (parentObj.internalRAM[(address + 1) & 0x7FFF] << 8);
		}
		public function readInternalWRAM16Optimized (parentObj, address) {
			address = address | 0;
			//Internal WRAM:
			parentObj.wait.FASTAccess2();
			return parentObj.internalRAM16[(address & 0x7FFF) >> 1] | 0;
		}
		public function readInternalWRAM32Slow (parentObj, address) {
			//Internal WRAM:
			parentObj.wait.FASTAccess2();
			return parentObj.internalRAM[address & 0x7FFF] | (parentObj.internalRAM[(address + 1) & 0x7FFF] << 8) | (parentObj.internalRAM[(address + 2) & 0x7FFF] << 16) | (parentObj.internalRAM[(address + 3) & 0x7FFF] << 24);
		}
		public function readInternalWRAM32Optimized (parentObj, address) {
			address = address | 0;
			//Internal WRAM:
			parentObj.wait.FASTAccess2();
			return parentObj.internalRAM32[(address & 0x7FFF) >> 2] | 0;
		}
		public function readIODispatch (parentObj, address, busReqNumber) {
			address = address | 0;
			busReqNumber = busReqNumber | 0;
			if (address < 0x4000304) {
				//IO Read:
				parentObj.wait.FASTAccess(busReqNumber | 0);
				parentObj.IOCore.updateCoreSpill();
				return parentObj.readIO[address & 0x3FF](parentObj) | 0;
			}
			else if ((address & 0x4FF0800) == 0x4000800) {
				//WRAM wait state control:
				parentObj.wait.FASTAccess(busReqNumber | 0);
				return parentObj.wait.readConfigureWRAM(address | 0) | 0;
			}
			else {
				return parentObj.readUnused(parentObj, address | 0, busReqNumber | 0) | 0;
			}
		}
		public function readIODispatch8 (parentObj, address) {
			address = address | 0;
			if (address < 0x4000304) {
				//IO Read:
				parentObj.wait.FASTAccess2();
				parentObj.IOCore.updateCoreSpill();
				return parentObj.readIO[address & 0x3FF](parentObj) | 0;
			}
			else if ((address & 0x4FF0800) == 0x4000800) {
				//WRAM wait state control:
				parentObj.wait.FASTAccess2();
				return parentObj.wait.readConfigureWRAM(address | 0) | 0;
			}
			else {
				return parentObj.readUnused8(parentObj, address | 0) | 0;
			}
		}
		public function readIODispatch16 (parentObj, address) {
			address = address | 0;
			if (address < 0x4000304) {
				//IO Read:
				parentObj.wait.FASTAccess2();
				parentObj.IOCore.updateCoreSpill();
				return parentObj.readIO[address & 0x3FF](parentObj) | (parentObj.readIO[(address + 1) & 0x3FF](parentObj) << 8);
			}
			else if ((address & 0x4FF0800) == 0x4000800) {
				//WRAM wait state control:
				parentObj.wait.FASTAccess2();
				return parentObj.wait.readConfigureWRAM(0) | (parentObj.wait.readConfigureWRAM(1) << 8);
			}
			else {
				return parentObj.readUnused16(parentObj, address | 0) | 0;
			}
		}
		public function readIODispatch32 (parentObj, address) {
			address = address | 0;
			if (address < 0x4000304) {
				//IO Read:
				parentObj.wait.FASTAccess2();
				parentObj.IOCore.updateCoreSpill();
				return parentObj.readIO[address & 0x3FF](parentObj) | (parentObj.readIO[(address + 1) & 0x3FF](parentObj) << 8) | (parentObj.readIO[(address + 2) & 0x3FF](parentObj) << 16) | (parentObj.readIO[(address + 3) & 0x3FF](parentObj) << 24);
			}
			else if ((address & 0x4FF0800) == 0x4000800) {
				//WRAM wait state control:
				parentObj.wait.FASTAccess2();
				return parentObj.wait.readConfigureWRAM(0) | (parentObj.wait.readConfigureWRAM(1) << 8) | (parentObj.wait.readConfigureWRAM(2) << 16)  | (parentObj.wait.readConfigureWRAM(3) << 24);
			}
			else {
				return parentObj.readUnused32(parentObj, address | 0) | 0;
			}
		}
		public function readVRAM (parentObj, address, busReqNumber) {
			address = address | 0;
			busReqNumber = busReqNumber | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess(busReqNumber | 0);
			if ((address & 0x10000) != 0) {
				return parentObj.gfx.readVRAM(address & 0x17FFF) | 0;
			}
			else {
				return parentObj.gfx.readVRAM(address & 0xFFFF) | 0;
			}
		}
		public function readVRAM8 (parentObj, address) {
			address = address | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess8();
			if ((address & 0x10000) != 0) {
				return parentObj.gfx.readVRAM(address & 0x17FFF) | 0;
			}
			else {
				return parentObj.gfx.readVRAM(address & 0xFFFF) | 0;
			}
		}
		public function readVRAM16 (parentObj, address) {
			address = address | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess16();
			if ((address & 0x10000) != 0) {
				return parentObj.gfx.readVRAM16(address & 0x17FFF) | 0;
			}
			else {
				return parentObj.gfx.readVRAM16(address & 0xFFFF) | 0;
			}
		}
		public function readVRAM32 (parentObj, address) {
			address = address | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess32();
			if ((address & 0x10000) != 0) {
				return parentObj.gfx.readVRAM32(address & 0x17FFF) | 0;
			}
			else {
				return parentObj.gfx.readVRAM32(address & 0xFFFF) | 0;
			}
		}
		public function readOAM (parentObj, address, busReqNumber) {
			address = address | 0;
			busReqNumber = busReqNumber | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.OAMAccess(busReqNumber | 0);
			return parentObj.gfx.readOAM(address & 0x3FF) | 0;
		}
		public function readOAM8 (parentObj, address) {
			address = address | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.OAMAccess8();
			return parentObj.gfx.readOAM(address & 0x3FF) | 0;
		}
		public function readOAM16 (parentObj, address) {
			address = address | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.OAMAccess16();
			return parentObj.gfx.readOAM16(address & 0x3FF) | 0;
		}
		public function readOAM32 (parentObj, address) {
			address = address | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.OAMAccess32();
			return parentObj.gfx.readOAM32(address & 0x3FF) | 0;
		}
		public function readPalette (parentObj, address, busReqNumber) {
			address = address | 0;
			busReqNumber = busReqNumber | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess(busReqNumber | 0);
			return parentObj.gfx.readPalette(address & 0x3FF) | 0;
		}
		public function readPalette8 (parentObj, address) {
			address = address | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess8();
			return parentObj.gfx.readPalette(address & 0x3FF);
		}
		public function readPalette16 (parentObj, address) {
			address = address | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess16();
			return parentObj.gfx.readPalette16(address & 0x3FF);
		}
		public function readPalette32 (parentObj, address) {
			address = address | 0;
			parentObj.IOCore.updateCoreSpill();
			parentObj.wait.VRAMAccess32();
			return parentObj.gfx.readPalette32(address & 0x3FF);
		}
		public function readROM0 (parentObj, address, busReqNumber) {
			address = address | 0;
			busReqNumber = busReqNumber | 0;
			parentObj.wait.ROM0Access(busReqNumber | 0);
			return parentObj.cartridge.readROM(address & 0x1FFFFFF) | 0;
		}
		public function readROM08 (parentObj, address) {
			address = address | 0;
			parentObj.wait.ROM0Access8();
			return parentObj.cartridge.readROM(address & 0x1FFFFFF) | 0;
		}
		public function readROM016 (parentObj, address) {
			address = address | 0;
			parentObj.wait.ROM0Access16();
			return parentObj.cartridge.readROM16(address & 0x1FFFFFF) | 0;
		}
		public function readROM032 (parentObj, address) {
			address = address | 0;
			parentObj.wait.ROM0Access32();
			return parentObj.cartridge.readROM32(address & 0x1FFFFFF) | 0;
		}
		public function readROM1 (parentObj, address, busReqNumber) {
			address = address | 0;
			busReqNumber = busReqNumber | 0;
			parentObj.wait.ROM1Access(busReqNumber | 0);
			return parentObj.cartridge.readROM(address & 0x1FFFFFF) | 0;
		}
		public function readROM18 (parentObj, address) {
			address = address | 0;
			parentObj.wait.ROM1Access8();
			return parentObj.cartridge.readROM(address & 0x1FFFFFF) | 0;
		}
		public function readROM116 (parentObj, address) {
			address = address | 0;
			parentObj.wait.ROM1Access16();
			return parentObj.cartridge.readROM16(address & 0x1FFFFFF) | 0;
		}
		public function readROM132 (parentObj, address) {
			address = address | 0;
			parentObj.wait.ROM1Access32();
			return parentObj.cartridge.readROM32(address & 0x1FFFFFF) | 0;
		}
		public function readROM2 (parentObj, address, busReqNumber) {
			address = address | 0;
			busReqNumber = busReqNumber | 0;
			parentObj.wait.ROM2Access(busReqNumber | 0);
			return parentObj.cartridge.readROM(address & 0x1FFFFFF) | 0;
		}
		public function readROM28 (parentObj, address) {
			address = address | 0;
			parentObj.wait.ROM2Access8();
			return parentObj.cartridge.readROM(address & 0x1FFFFFF) | 0;
		}
		public function readROM216 (parentObj, address) {
			address = address | 0;
			parentObj.wait.ROM2Access16();
			return parentObj.cartridge.readROM16(address & 0x1FFFFFF) | 0;
		}
		public function readROM232 (parentObj, address) {
			address = address | 0;
			parentObj.wait.ROM2Access32();
			return parentObj.cartridge.readROM32(address & 0x1FFFFFF) | 0;
		}
		public function readSRAM (parentObj, address, busReqNumber) {
			address = address | 0;
			parentObj.wait.SRAMAccess();
			return parentObj.cartridge.readSRAM(address & 0xFFFF) | 0;
		}
		public function readSRAM8 (parentObj, address) {
			address = address | 0;
			parentObj.wait.SRAMAccess();
			return parentObj.cartridge.readSRAM(address & 0xFFFF) | 0;
		}
		public function readSRAM16 (parentObj, address) {
			address = address | 0;
			parentObj.wait.SRAMAccess();
			return ((parentObj.cartridge.readSRAM(address & 0xFFFF) | 0) * 0x101) | 0;
		}
		public function readSRAM32 (parentObj, address) {
			address = address | 0;
			parentObj.wait.SRAMAccess();
			return ((parentObj.cartridge.readSRAM(address & 0xFFFF) | 0) * 0x1010101) | 0;
		}
		public function readZero (parentObj) {
			return 0;
		}
		public function readWriteOnly (parentObj) {
			return 0xFF;
		}
		public function readUnused (parentObj, address, busReqNumber) {
			address = address | 0;
			parentObj.wait.FASTAccess(busReqNumber);
			return (parentObj.cpu.getCurrentFetchValue() >> ((address & 0x3) << 3)) & 0xFF;
		}
		public function readUnused8 (parentObj, address) {
			address = address | 0;
			parentObj.wait.FASTAccess2();
			return (parentObj.cpu.getCurrentFetchValue() >> ((address & 0x3) << 3)) & 0xFF;
		}
		
		public function readUnused16 (parentObj, address) {
			address = address | 0;
			parentObj.wait.FASTAccess2();
			return (parentObj.cpu.getCurrentFetchValue() >> ((address & 0x2) << 3)) & 0xFFFF;
		}
		public function readUnused32 (parentObj, address) {
			parentObj.wait.FASTAccess2();
			return parentObj.cpu.getCurrentFetchValue() | 0;
		}
		public function readUnused0 (parentObj) {
			return parentObj.cpu.getCurrentFetchValue() & 0xFF;
		}
		public function readUnused1 (parentObj) {
			return (parentObj.cpu.getCurrentFetchValue() >> 8) & 0xFF;
		}
		public function readUnused2 (parentObj) {
			return (parentObj.cpu.getCurrentFetchValue() >> 16) & 0xFF;
		}
		public function readUnused3 (parentObj) {
			return (parentObj.cpu.getCurrentFetchValue() >> 24) & 0xFF;
		}
		public function loadBIOS () {
			//Ensure BIOS is of correct length:
			if (this.emulatorCore.BIOS.length == 0x4000) {
				this.IOCore.BIOSFound = true;
				for (var index = 0; index < 0x4000; ++index) {
					this.BIOS[index] = this.emulatorCore.BIOS[index];
				}
			}
			else {
				this.IOCore.BIOSFound = false;
			}
		}
		
		

	}
	
}
