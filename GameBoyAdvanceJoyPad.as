package  {
	
	public class GameBoyAdvanceJoyPad {
		
		public var IOCore;
		public var keyInput;
		public var keyInterrupt;
		public var keyIRQType;
		public var keyIRQEnabled;
		
		public function GameBoyAdvanceJoyPad(IOCore) {
			// constructor code
			this.IOCore = IOCore;
			this.initialize();
		}
		
		public function initialize() {
			this.keyInput = 0x3FF;
			this.keyInterrupt = 0;
			this.keyIRQType = false;
			this.keyIRQEnabled = false;
		}
		
		public function keyPress(keyPressed) {
			switch (keyPressed.toUpperCase()) {
				case "A":
					this.keyInput &= ~0x1;
					break;
				case "B":
					this.keyInput &= ~0x2;
					break;
				case "SELECT":
					this.keyInput &= ~0x4;
					break;
				case "START":
					this.keyInput &= ~0x8;
					break;
				case "RIGHT":
					this.keyInput &= ~0x10;
					break;
				case "LEFT":
					this.keyInput &= ~0x20;
					break;
				case "UP":
					this.keyInput &= ~0x40;
					break;
				case "DOWN":
					this.keyInput &= ~0x80;
					break;
				case "R":
					this.keyInput &= ~0x100;
					break;
				case "L":
					this.keyInput &= ~0x200;
					break;
				default:
					return;
			}
			if (this.keyIRQEnabled) {
				this.checkForIRQ();
			}
			this.IOCore.deflagStepper(0x4);
		}
		public function keyRelease(keyReleased) {
			switch (keyReleased.toUpperCase()) {
				case "A":
					this.keyInput |= 0x1;
					break;
				case "B":
					this.keyInput |= 0x2;
					break;
				case "SELECT":
					this.keyInput |= 0x4;
					break;
				case "START":
					this.keyInput |= 0x8;
					break;
				case "RIGHT":
					this.keyInput |= 0x10;
					break;
				case "LEFT":
					this.keyInput |= 0x20;
					break;
				case "UP":
					this.keyInput |= 0x40;
					break;
				case "DOWN":
					this.keyInput |= 0x80;
					break;
				case "R":
					this.keyInput |= 0x100;
					break;
				case "L":
					this.keyInput |= 0x200;
					break;
				default:
					return;
			}
			if (this.keyIRQEnabled) {
				this.checkForIRQ();
			}
		}
		public function checkForIRQ() {
			if (this.keyIRQType) {
				if (((~this.keyInput) & this.keyInterrupt & 0x3FF) == (this.keyInterrupt & 0x3FF)) {
					this.IOCore.irq.requestIRQ(0x1000);
				}
			}
			else if (((~this.keyInput) & this.keyInterrupt & 0x3FF) != 0) {
				this.IOCore.irq.requestIRQ(0x1000);
			}
		}
		/*public function nextIRQEventTime{
			//Always return -1 here, as we don't input joypad updates at the same time we're running the interp loop:
			return -1;
		}*/
		public function readKeyStatus0() {
			return this.keyInput & 0xFF;
		}
		public function readKeyStatus1() {
			return ((this.keyInput >> 8) & 0x3) | 0xFC;
		}
		public function writeKeyControl0(data) {
			this.keyInterrupt &= 0x300;
			this.keyInterrupt |= data;
		}
		public function readKeyControl0() {
			return this.keyInterrupt & 0xFF;
		}
		public function writeKeyControl1(data) {
			this.keyInterrupt &= 0xFF;
			this.keyInterrupt |= data << 8;
			this.keyIRQType = (data > 0x7F);
			this.keyIRQEnabled = ((data & 0x40) == 0x40);
		}
		public function readKeyControl1() {
			return ((this.keyInterrupt >> 8) & 0xC3) | 0x3C;
		}
				
		

	}
	
}
