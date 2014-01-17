package CPU {
	
	public class GameBoyAdvanceSWICore {
		
		public var CPUCore:CPU;
		public var IOCore;
		public var address;
		
		public function GameBoyAdvanceSWICore(cpu:CPU) {
			// constructor code
			this.CPUCore = cpu;
			this.IOCore = this.CPUCore.IOCore;
		}
		
		public function execute(command) {
			switch (command) {
				//Soft Reset:
				case 0:
					this.SoftReset();
					break;
				//Register Ram Reset:
				case 0x01:
					this.RegisterRAMReset();
					break;
				//Halt:
				case 0x02:
					this.Halt();
					break;
				//Stop:
				case 0x03:
					this.Stop();
					break;
				//Interrupt Wait:
				case 0x04:
					this.IntrWait();
					break;
				//VBlank Interrupt Wait:
				case 0x05:
					this.VBlankIntrWait();
					break;
				//Division:
				case 0x06:
					this.Div();
					break;
				//Division (Reversed Parameters):
				case 0x07:
					this.DivArm();
					break;
				//Square Root:
				case 0x08:
					this.Sqrt();
					break;
				//Arc Tangent:
				case 0x09:
					this.ArcTan();
					break;
				//Arc Tangent Corrected:
				case 0x0A:
					this.ArcTan2();
					break;
				//CPU Set (Memory Copy + Fill):
				case 0x0B:
					this.CpuSet();
					break;
				//CPU Fast Set (Memory Copy + Fill):
				case 0x0C:
					this.CpuFastSet();
					break;
				//Calculate BIOS Checksum:
				case 0x0D:
					this.GetBiosChecksum();
					break;
				//Calculate BG Rotation/Scaling Parameters:
				case 0x0E:
					this.BgAffineSet();
					break;
				//Calculate OBJ Rotation/Scaling Parameters:
				case 0x0F:
					this.ObjAffineSet();
					break;
				//Bit Unpack Tile Data:
				case 0x10:
					this.BitUnPack();
					break;
				//Uncompress LZ77 Compressed Data (WRAM):
				case 0x11:
					this.LZ77UnCompWram();
					break;
				//Uncompress LZ77 Compressed Data (VRAM):
				case 0x12:
					this.LZ77UnCompVram();
					break;
				//Uncompress Huffman Compressed Data:
				case 0x13:
					this.HuffUnComp();
					break;
				//Uncompress Run-Length Compressed Data (WRAM):
				case 0x14:
					this.RLUnCompWram();
					break;
				//Uncompress Run-Length Compressed Data (VRAM):
				case 0x15:
					this.RLUnCompVram();
					break;
				//Filter Out Difference In Data (8-bit/WRAM):
				case 0x16:
					this.Diff8bitUnFilterWram();
					break;
				//Filter Out Difference In Data (8-bit/VRAM):
				case 0x17:
					this.Diff8bitUnFilterVram();
					break;
				//Filter Out Difference In Data (16-bit):
				case 0x18:
					this.Diff16bitUnFilter();
					break;
				//Update Sound Bias:
				case 0x19:
					this.SoundBias();
					break;
				//Sound Driver Initialization:
				case 0x1A:
					this.SoundDriverInit();
					break;
				//Set Sound Driver Mode:
				case 0x1B:
					this.SoundDriverMode();
					break;
				//Call Sound Driver Main:
				case 0x1C:
					this.SoundDriverMain();
					break;
				//Call Sound Driver VSync Iteration Handler:
				case 0x1D:
					this.SoundDriverVSync();
					break;
				//Clear Direct Sound And Stop Audio:
				case 0x1E:
					this.SoundChannelClear();
					break;
				//Convert MIDI To Frequency:
				case 0x1F:
					this.MidiKey2Freq();
					break;
				//Unknown Sound Driver Functions:
				case 0x20:
				case 0x21:
				case 0x22:
				case 0x23:
				case 0x24:
					this.SoundDriverUnknown();
					break;
				//Multi-Boot:
				case 0x25:
					this.MultiBoot();
					break;
				//Hard Reset:
				case 0x26:
					this.HardReset();
					break;
				//Custom Halt:
				case 0x27:
					this.CustomHalt();
					break;
				//Call Sound Driver VSync Stop Handler:
				case 0x28:
					this.SoundDriverVSyncOff();
					break;
				//Call Sound Driver VSync Start Handler:
				case 0x29:
					this.SoundDriverVSyncOn();
					break;
				//Obtain 36 Sound Driver Pointers:
				case 0x2A:
					this.SoundGetJumpList();
					break;
				//Undefined:
				default:
					//Don't do anything if we get here, although a real device errors.
			}
		}
		
		public function SoftReset() {
			
		}
		
		public function RegisterRAMReset() {
			var control = this.CPUCore.registers[0];
			if ((control & 0x1) == 0x1) {
				//Clear 256K on-board WRAM
				for (address = 0x2000000; address < 0x2040000; address += 4) {
					this.IOCore.memory.memoryWrite32(address >>> 0, 0);
				}
			}
			if ((control & 0x2) == 0x2) {
				//Clear 32K in-chip WRAM
				for (address = 0x3000000; address < 0x3008000; address += 4) {
					this.IOCore.memory.memoryWrite32(address >>> 0, 0);
				}
			}
			if ((control & 0x4) == 0x4) {
				//Clear Palette
				for (address = 0x5000000; address < 0x5000400; address += 4) {
					this.IOCore.memory.memoryWrite32(address >>> 0, 0);
				}
			}
			if ((control & 0x8) == 0x8) {
				//Clear VRAM
				for (address = 0x6000000; address < 0x6018000; address += 4) {
					this.IOCore.memory.memoryWrite32(address >>> 0, 0);
				}
			}
			if ((control & 0x10) == 0x10) {
				//Clear OAM
				for (address = 0x7000000; address < 0x7000400; address += 4) {
					this.IOCore.memory.memoryWrite32(address >>> 0, 0);
				}
			}
			if ((control & 0x20) == 0x20) {
				//Reset SIO registers
				for (address = 0x4000120; address < 0x4000130; address += 4) {
					this.IOCore.memory.memoryWrite32(address >>> 0, 0);
				}
			}
			if ((control & 0x40) == 0x40) {
				//Reset Sound registers
				for (address = 0x4000060; address < 0x40000A8; address += 4) {
					this.IOCore.memory.memoryWrite32(address >>> 0, 0);
				}
			}
			if ((control & 0x80) == 0x80) {
				//Reset all other registers
				for (address = 0x4000000; address < 0x4000060; address += 4) {
					this.IOCore.memory.memoryWrite32(address >>> 0, 0);
				}
				for (address = 0x4000100; address < 0x4000120; address += 4) {
					this.IOCore.memory.memoryWrite32(address >>> 0, 0);
				}
				for (address = 0x4000130; address < 0x4000300; address += 4) {
					this.IOCore.memory.memoryWrite32(address >>> 0, 0);
				}
			}
		}
		public function Halt() {
			this.IOCore.flagStepper(2);
		}
		public function Stop() {
			this.IOCore.flagStepper(4);
		}
		public function IntrWait() {
			this.IOCore.irq.IME = true;
			if ((this.CPUCore.registers[0] & 0x1) == 0x1) {
				this.IOCore.irq.interruptsRequested = 0;
			}
			this.IOCore.irq.interruptsEnabled = this.CPUCore.registers[1] & 0x3FFF;
			this.Halt();
		}
		public function VBlankIntrWait() {
			this.IOCore.irq.IME = true;
			this.IOCore.irq.interruptsRequested = 0;
			this.IOCore.irq.interruptsEnabled = 0x1;
			this.Halt();
		}
		public function Div() {
			var numerator = this.CPUCore.registers[0];
			var denominator = this.CPUCore.registers[1];
			if (denominator == 0) {
				throw(new Error("Division by 0 called."));
			}
			var result = (numerator / denominator) | 0;
			this.CPUCore.registers[0] = result;
			this.CPUCore.registers[1] = (numerator % denominator) | 0;
			this.CPUCore.registers[3] = Math.abs(result) | 0;
		}
		public function DivArm() {
			var numerator = this.CPUCore.registers[1];
			var denominator = this.CPUCore.registers[0];
			if (denominator == 0) {
				throw(new Error("Division by 0 called."));
			}
			var result = (numerator / denominator) | 0;
			this.CPUCore.registers[0] = result;
			this.CPUCore.registers[1] = (numerator % denominator) | 0;
			this.CPUCore.registers[3] = Math.abs(result) | 0;
		}
		public function Sqrt() {
			this.CPUCore.registers[0] = Math.sqrt(this.CPUCore.registers[0] >>> 0) | 0;
		}
		public function ArcTan() {
			var a = (-(this.CPUCore.performMUL32(this.CPUCore.registers[0], this.CPUCore.registers[0], 0) >> 14)) | 0;
			var b = ((this.CPUCore.performMUL32(0xA9, a, 0) >> 14) + 0x390) | 0;
			b = ((this.CPUCore.performMUL32(b, a, 0) >> 14) + 0x91C) | 0;
			b = ((this.CPUCore.performMUL32(b, a, 0) >> 14) + 0xFB6) | 0;
			b = ((this.CPUCore.performMUL32(b, a, 0) >> 14) + 0x16AA) | 0;
			b = ((this.CPUCore.performMUL32(b, a, 0) >> 14) + 0x2081) | 0;
			b = ((this.CPUCore.performMUL32(b, a, 0) >> 14) + 0x3651) | 0;
			b = ((this.CPUCore.performMUL32(b, a, 0) >> 14) + 0xA2F9) | 0;
			a = this.CPUCore.performMUL32(this.CPUCore.registers[0], b, 0) >> 16;
			this.CPUCore.registers[0] = a;
		}
		public function ArcTan2() {
			var x = this.CPUCore.registers[0];
			var y = this.CPUCore.registers[1];
			var result = 0;
			if (y == 0) {
				result = (x >> 16) & 0x8000;
			}
			else {
				if (x == 0) {
					result = ((y >> 16) & 0x8000) + 0x4000;
				}
				else {
					if ((Math.abs(x) > Math.abs(y)) || (Math.abs(x) == Math.abs(y) && (x >= 0 || y >= 0))) {
						this.CPUCore.registers[1] = x;
						this.CPUCore.registers[0] = y << 14;
						this.Div();
						this.ArcTan();
						if (x < 0) {
							result = 0x8000 + this.CPUCore.registers[0];
						}
						else {
							result = (((y >> 16) & 0x8000) << 1) + this.CPUCore.registers[0];
						}
					}
					else {
						this.CPUCore.registers[0] = x << 14;
						this.Div();
						this.ArcTan();
						result = (0x4000 + ((y >> 16) & 0x8000)) - this.CPUCore.registers[0];
					}
				}
			}
			this.CPUCore.registers[0] = result | 0;
		}
		public function CpuSet() {
			var source = this.CPUCore.registers[0];
			var destination = this.CPUCore.registers[1];
			var control = this.CPUCore.registers[2];
			var count = control & 0x1FFFFF;
			var isFixed = ((control & 0x1000000) != 0);
			var is32 = ((control & 0x4000000) != 0);
			if (is32) {
				while (count-- > 0) {
					if (source >= 0x4000 && destination >= 0x4000) {
						this.IOCore.memory.memoryWrite32(destination >>> 0, this.IOCore.memory.memoryRead32(source >>> 0) | 0);
					}
					if (!isFixed) {
						source += 0x4;
					}
					destination += 0x4;
				}
			}
			else {
				while (count-- > 0) {
					if (source >= 0x4000 && destination >= 0x4000) {
						this.IOCore.memory.memoryWrite16(destination >>> 0, this.IOCore.memory.memoryRead16(source >>> 0) | 0);
					}
					if (!isFixed) {
						source += 0x2;
					}
					destination += 0x2;
				}
			}
		}
		public function CpuFastSet() {
			var source = this.CPUCore.registers[0];
			var destination = this.CPUCore.registers[1];
			var control = this.CPUCore.registers[2];
			var count = control & 0x1FFFFF;
			var isFixed = ((control & 0x1000000) != 0);
			var currentRead = 0;
			while (count-- > 0) {
				if (source >= 0x4000) {
					currentRead = this.IOCore.memory.memoryRead32(source >>> 0) | 0;
					for (var i = 0; i < 0x8; ++i) {
						if (destination >= 0x4000) {
							this.IOCore.memory.memoryWrite32(destination >>> 0, currentRead | 0);
						}
						destination += 0x4;
					}
				}
				if (!isFixed) {
					source += 0x4;
				}
			}
		}
		public function GetBiosChecksum() {
			this.CPUCore.registers[0] = 0xBAAE187F;
		}
		public function BgAffineSet() {
			var source = this.CPUCore.registers[0];
			var destination = this.CPUCore.registers[1];
			var numberCalculations = this.CPUCore.registers[2];
			while (numberCalculations-- > 0) {
				var cx = this.IOCore.memory.memoryRead32(source >>> 0);
				source += 0x4;
				var cy = this.IOCore.memory.memoryRead32(source >>> 0);
				source += 0x4;
				var dispx = (this.IOCore.memory.memoryRead16(source >>> 0) << 16) >> 16;
				source += 0x2;
				var dispy = (this.IOCore.memory.memoryRead16(source >>> 0) << 16) >> 16;
				source += 0x2;
				var rx = (this.IOCore.memory.memoryRead16(source >>> 0) << 16) >> 16;
				source += 0x2;
				var ry = (this.IOCore.memory.memoryRead16(source >>> 0) << 16) >> 16;
				source += 0x2;
				var theta = (this.IOCore.memory.memoryRead16(source >>> 0) >> 8) / 0x80 * Math.PI;
				source += 0x4;
				var cosAngle = Math.cos(theta);
				var sineAngle = Math.sin(theta);
				var dx = rx * cosAngle;
				var dmx = rx * sineAngle;
				var dy = ry * sineAngle;
				var dmy = ry * cosAngle;
				this.IOCore.memory.memoryWrite16(destination >>> 0, dx | 0);
				destination += 2;
				this.IOCore.memory.memoryWrite16(destination >>> 0, (-dmx) | 0);
				destination += 2;
				this.IOCore.memory.memoryWrite16(destination >>> 0, dy | 0);
				destination += 2;
				this.IOCore.memory.memoryWrite16(destination >>> 0, dmy | 0);
				destination += 2;
				this.IOCore.memory.memoryWrite32(destination >>> 0, (cx - dx * dispx + dmx * dispy) | 0);
				destination += 4;
				this.IOCore.memory.memoryWrite32(destination >>> 0, (cy - dy * dispx + dmy * dispy) | 0);
				destination += 4;
			}
		}
		public function ObjAffineSet() {
			var source = this.CPUCore.registers[0];
			var destination = this.CPUCore.registers[1];
			var numberCalculations = this.CPUCore.registers[2];
			var offset = this.CPUCore.registers[3];
			while (numberCalculations-- > 0) {
				var rx = (this.IOCore.memory.memoryRead16(source >>> 0) << 16) >> 16;
				source += 0x2;
				var ry = (this.IOCore.memory.memoryRead16(source >>> 0) << 16) >> 16;
				source += 0x2;
				var theta = (this.IOCore.memory.memoryRead16(source >>> 0) >> 8) / 0x80 * Math.PI;
				source += 0x4;
				var cosAngle = Math.cos(theta);
				var sineAngle = Math.sin(theta);
				var dx = rx * cosAngle;
				var dmx = rx * sineAngle;
				var dy = ry * sineAngle;
				var dmy = ry * cosAngle;
				this.IOCore.memory.memoryWrite16(destination >>> 0, dx | 0);
				destination += offset;
				this.IOCore.memory.memoryWrite16(destination >>> 0, (-dmx) | 0);
				destination += offset;
				this.IOCore.memory.memoryWrite16(destination >>> 0, dy | 0);
				destination += offset;
				this.IOCore.memory.memoryWrite16(destination >>> 0, dmy | 0);
				destination += offset;
			}
		}
		public function BitUnPack() {
			var source = this.CPUCore.registers[0];
			var destination = this.CPUCore.registers[1];
			var unpackSource = this.CPUCore.registers[2];
			var length = this.IOCore.memory.memoryRead16(unpackSource >>> 0);
			unpackSource += 0x2;
			var widthSource = this.IOCore.memory.memoryRead16(unpackSource >>> 0);
			unpackSource += 0x1;
			var widthDestination = this.IOCore.memory.memoryRead8(unpackSource >>> 0);
			unpackSource += 0x1;
			var offset = this.IOCore.memory.memoryRead32(unpackSource >>> 0);
			var dataOffset = offset & 0x7FFFFFFF;
			var zeroData = (offset < 0);
			var bitDiff = widthDestination - widthSource;
			if (bitDiff >= 0) {
				var resultWidth = 0;
				while (length > 0) {
					var result = 0;
					var readByte = this.IOCore.memory.memoryRead8((source++) >>> 0);
					for (var index = 0, widthIndex = 0; index < 8; index += widthSource, widthIndex += widthDestination) {
						var temp = (readByte >> index) & ((widthSource << 1) - 1);
						if (temp > 0 || zeroData) {
							temp += dataOffset;
						}
						temp <<= widthIndex;
						result |= temp;
					}
					resultWidth += widthIndex;
					if (resultWidth == 32) {
						resultWidth = 0;
						this.IOCore.memory.memoryWrite32(destination >>> 0, result | 0);
						destination += 4;
						length -= 4;
					}
				}
				if (resultWidth > 0) {
					this.IOCore.memory.memoryWrite32(destination >>> 0, result | 0);
				}
			}
		}
		public function LZ77UnCompWram() {
			
		}
		public function LZ77UnCompVram() {
			
		}
		public function HuffUnComp() {
			
		}
		public function RLUnCompWram() {
			
		}
		public function RLUnCompVram() {
			
		}
		public function Diff8bitUnFilterWram() {
			
		}
		public function Diff8bitUnFilterVram() {
			
		}
		public function Diff16bitUnFilter() {
			
		}
		public function SoundBias() {
			if (this.CPUCore.registers[0] == 0) {
				this.IOCore.memory.memoryWrite16(0x4000088, 0);
			}
			else {
				this.IOCore.memory.memoryWrite16(0x4000088, 0x200);
			}
		}
		public function SoundDriverInit() {
			
		}
		public function SoundDriverMode() {
			
		}
		public function SoundDriverMain() {
			
		}
		public function SoundDriverVSync() {
			
		}
		public function SoundChannelClear() {
			
		}
		public function MidiKey2Freq() {
			//var frequency = this.CPUCore.memoryRead32((this.CPUCore.registers[0] + 4) >>> 0);
			var frequency = 0;
			var temp = (180 - this.CPUCore.registers[1]) - (this.CPUCore.registers[2] / 0x100);
			temp = Math.pow(2, temp / 12);
			this.CPUCore.registers[0] = (frequency / temp) | 0;
		}
		public function SoundDriverUnknown() {
			
		}
		public function MultiBoot() {
			
		}
		public function HardReset() {
			
		}
		public function CustomHalt() {
			this.IOCore.wait.writeHALTCNT(this.CPUCore.registers[2]);
		}
		public function SoundDriverVSyncOff() {
			
		}
		public function SoundDriverVSyncOn() {
			
		}
		public function SoundGetJumpList() {
			
		}

	}
	
}
