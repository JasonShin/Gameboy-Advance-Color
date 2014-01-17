package  {
	import Catridge.GameBoyAdvanceFlash;
	import Catridge.GameBoyAdvanceSRAM;
	import utils.ArrayHelper;

	public class GameBoyAdvanceCartridge {
		
		public var ROM;
		public var ROM16;
		public var ROM32;
		public var saveType;
		public var saveSize;
		public var saveRTC;
		public var rtc;
		public var sram;
		public var gameID;
		
		public var IOCore;
		
		public var ROMLength;
		public var readROM16;
		public var readROM32;
		
		public function GameBoyAdvanceCartridge(IOCore) {
			// constructor code
			this.IOCore = IOCore;
			this.initialize();
		}
		
		
		public function initialize() {
			this.ROM = this.getROMArray(this.IOCore.emulatorCore.ROM);
			this.ROM16 = ROM;
			this.ROM32 = ROM;
			this.preprocessROMAccess();
			this.saveType = 0;
			this.saveSize = 0;
			this.saveRTC = false;
			this.lookupCartridgeType();
		}
		public function getROMArray(old_array) {
			this.ROMLength = (old_array.length >> 2) << 2;
			var newArray = ArrayHelper.buildArray(this.ROMLength);
			for (var index = 0; index < this.ROMLength; ++index) {
				newArray[index] = old_array[index];
			}
			return newArray;
		}
		public function preprocessROMAccess() {
			//this.readROM16 = (this.ROM16) ? this.readROM16Optimized : this.readROM16Slow;
			//this.readROM32 = (this.ROM32) ? this.readROM32Optimized : this.readROM32Slow;
			this.readROM16 = readROM16Slow;
			this.readROM32 = readROM32Slow;
		}
		public function readROM(address) {
			if ((address | 0) >= (this.ROMLength | 0)) {
				return 0;
			}
			return this.ROM[address & 0x1FFFFFF] | 0;
			/*if (!this.saveRTC) {
				return this.ROM[address & 0x1FFFFFF] | 0;
			}
			else {
				//GPIO Chip (RTC):
				switch (address) {
					case 0xC4:
						return this.rtc.read0();
					case 0xC5:
						return 0;
					case 0xC6:
						return this.rtc.read1();
					case 0xC7:
						return 0;
					case 0xC8:
						return this.rtc.read2();
					case 0xC9:
						return 0;
					default:
						return this.ROM[address & 0x1FFFFFF] | 0;
				}
			}*/
		}
		public function readROM16Slow(address) {
			if ((address | 0) >= (this.ROMLength | 0)) {
				return 0;
			}
			return (this.ROM[address] | (this.ROM[address | 1] << 8)) >>> 0;
		}
		public function readROM16Optimized(address) {
			if ((address | 0) >= (this.ROMLength | 0)) {
				return 0;
			}
			return this.ROM16[(address >> 1) & 0xFFFFFF] | 0;
		}
		public function readROM32Slow(address) {
			if ((address | 0) >= (this.ROMLength | 0)) {
				return 0;
			}
			return (this.ROM[address] | (this.ROM[address | 1] << 8) | (this.ROM[address | 2] << 16)  | (this.ROM[address | 3] << 24)) >>> 0;
		}
		public function readROM32Optimized(address) {
			if ((address | 0) >= (this.ROMLength | 0)) {
				return 0;
			}
			return this.ROM32[(address >> 2) & 0x7FFFFF] | 0;
		}
		
		public function writeROM(address, data) {
			if (this.saveRTC) {
				//GPIO Chip (RTC):
				switch (address) {
					case 0xC4:
						this.rtc.write0(data);
					case 0xC6:
						this.rtc.write1(data);
					case 0xC8:
						this.rtc.write2(data);
				}
			}
		}
		public function readSRAM(address) {
			address = address | 0;
			return (this.saveType > 0) ? this.sram.read(address | 0) : 0;
		}
		public function writeSRAM(address, data) {
			address = address | 0;
			data = data | 0;
			if (this.saveType > 0) {
				this.sram.write(address | 0, data | 0);
			}
		}
		public function lookupCartridgeType() {
			this.gameID = ([
				String.fromCharCode(this.ROM[0xAC]),
				String.fromCharCode(this.ROM[0xAD]),
				String.fromCharCode(this.ROM[0xAE]),
				String.fromCharCode(this.ROM[0xAF])
			]).join("");
			
			this.IDLookup();
			//Initialize the SRAM:
			this.mapSRAM();
			//Initialize the RTC:
			//this.mapRTC();
		}
		public function mapSRAM() {
			switch (this.saveType) {
				//Flash
				case 1:
					this.sram = new GameBoyAdvanceFlash(this, this.saveSize);
					this.loadExisting();
					break;
				//SRAM
				case 2:
					this.sram = new GameBoyAdvanceSRAM(this);
					this.loadExisting();
					break;
				//EEPROM
				/*case 3:
					this.sram = new GameBoyAdvanceEEPROM(this, this.saveSize);
					this.loadExisting();*/
				default:
					this.saveType = 0;
			}
		}
		public function mapRTC() {
			if (this.saveRTC) {
				//this.rtc = new GameBoyAdvanceRTC(this);
				var data = this.IOCore.emulatorCore.loadRTC(this.gameID);
				if (data && data.length) {
					this.rtc.load(data);
				}
			}
		}
		public function IDLookup() {
			var found = 0;
			var length = this.ROM.length - 6;
			for (var index = 0; index < length; ++index) {
				switch (this.ROM[index]) {
					/*case 0x45:	//E
						if (this.isEEPROMCart(index)) {
							found |= 2;
							if (found == 3) {
								return;
							}
						}
						break;*/
					case 0x46:	//F
						if (this.isFLASHCart(index)) {
							found |= 2;
							if (found == 3) {
								return;
							}
						}
						break;
					case 0x52:	//R
						if (this.isRTCCart(index)) {
							found |= 1;
							if (found == 3) {
								return;
							}
						}
						break;
					case 0x53:	//S
						if (this.isSRAMCart(index)) {
							found |= 2;
							if (found == 3) {
								return;
							}
						}
				}
			}
		}
		public function isFLASHCart(index) {
			if (String.fromCharCode(this.ROM[++index]) == "L") {
				if (String.fromCharCode(this.ROM[++index]) == "A") {
					if (String.fromCharCode(this.ROM[++index]) == "S") {
						if (String.fromCharCode(this.ROM[++index]) == "H") {
							switch (String.fromCharCode(this.ROM[index])) {
								case "_":
								case "5":
									this.saveType = 1;
									this.saveSize = 0x10000;
									return true;
								case "1":
									this.saveType = 1;
									this.saveSize = 0x20000;
									return true;
							}
						}
					}
				}
			}
			return false;
		}
		public function isRTCCart(index) {
			if (String.fromCharCode(this.ROM[++index]) == "T") {
				if (String.fromCharCode(this.ROM[++index]) == "C") {
					if (String.fromCharCode(this.ROM[++index]) == "_") {
						if (String.fromCharCode(this.ROM[index]) == "V") {
							this.saveRTC = true;
							return true;
						}
					}
				}
			}
			return false;
		}
		public function isSRAMCart(index) {
			if (String.fromCharCode(this.ROM[++index]) == "R") {
				if (String.fromCharCode(this.ROM[++index]) == "A") {
					if (String.fromCharCode(this.ROM[++index]) == "M") {
						if (String.fromCharCode(this.ROM[++index]) == "_") {
							if (String.fromCharCode(this.ROM[index]) == "V") {
								this.saveType = 2;
								this.saveSize = 0x8000;
								return true;
							}
						}
					}
				}
			}
			return false;
		}
		public function loadExisting() {
			var data = this.IOCore.emulatorCore.loadSRAM(this.gameID);
			if (data && data.length) {
				this.sram.load(data);
			}
		}
		public function nextIRQEventTime() {
			//Nothing yet implement that would fire an IRQ:
			return -1;
		}
		
		

	}
	
}
