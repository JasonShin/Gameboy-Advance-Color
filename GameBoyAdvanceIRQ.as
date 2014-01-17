package  {
	
	public class GameBoyAdvanceIRQ {
		
		public var IOCore;
		
		public var interruptsEnabled;
		public var interruptsRequested;
		public var IME;
		
		public function GameBoyAdvanceIRQ(IOCore) {
			// constructor code
			this.IOCore = IOCore;
			this.initializeIRQState();
		}
		
		public function initializeIRQState() {
			this.interruptsEnabled = 0;
			this.interruptsRequested = 0;
			this.IME = false;
		}
		public function IRQMatch() {
			//Used to exit HALT:
			return ((this.interruptsEnabled & this.interruptsRequested) != 0);
		}
		public function checkForIRQFire() {
			//Tell the CPU core when the emulated hardware is triggering an IRQ:
			this.IOCore.cpu.triggerIRQ((this.interruptsEnabled & this.interruptsRequested) != 0 && this.IME);
		}
		public function requestIRQ(irqLineToSet) {
			irqLineToSet = irqLineToSet | 0;
			this.interruptsRequested |= irqLineToSet | 0;
			this.checkForIRQFire();
		}
		public function writeIME(data) {
			data = data | 0;
			this.IME = ((data & 0x1) == 0x1);
			this.checkForIRQFire();
		}
		public function readIME() {
			return (this.IME ? 0xFF : 0xFE);
		}
		public function writeIE0(data) {
			data = data | 0;
			this.interruptsEnabled &= 0x3F00;
			this.interruptsEnabled |= data | 0;
			this.checkForIRQFire();
		}
		public function readIE0() {
			return this.interruptsEnabled & 0xFF;
		}
		public function writeIE1(data) {
			data = data | 0;
			this.interruptsEnabled &= 0xFF;
			this.interruptsEnabled |= (data << 8) & 0x3F00;
			this.checkForIRQFire();
		}
		public function readIE1() {
			return this.interruptsEnabled >> 8;
		}
		public function writeIF0(data) {
			data = data | 0;
			this.interruptsRequested &= ~data;
			this.checkForIRQFire();
		}
		public function readIF0() {
			return this.interruptsRequested & 0xFF;
		}
		public function writeIF1(data) {
			data = data | 0;
			this.interruptsRequested &= ~(data << 8);
			this.checkForIRQFire();
		}
		public function readIF1() {
			return this.interruptsRequested >> 8;
		}
		public function nextEventTime() {
			var clocks = -1;
			clocks = this.findClosestEvent(clocks | 0, this.IOCore.gfx.nextVBlankIRQEventTime() | 0, 0x1) | 0;
			clocks = this.findClosestEvent(clocks | 0, this.IOCore.gfx.nextHBlankIRQEventTime() | 0, 0x2) | 0;
			clocks = this.findClosestEvent(clocks | 0, this.IOCore.gfx.nextVCounterIRQEventTime() | 0, 0x4) | 0;
			clocks = this.findClosestEvent(clocks | 0, this.IOCore.timer.nextTimer0IRQEventTime() | 0, 0x8) | 0;
			clocks = this.findClosestEvent(clocks | 0, this.IOCore.timer.nextTimer1IRQEventTime() | 0, 0x10) | 0;
			clocks = this.findClosestEvent(clocks | 0, this.IOCore.timer.nextTimer2IRQEventTime() | 0, 0x20) | 0;
			clocks = this.findClosestEvent(clocks | 0, this.IOCore.timer.nextTimer3IRQEventTime() | 0, 0x40) | 0;
			clocks = this.findClosestEvent(clocks | 0, this.IOCore.serial.nextIRQEventTime(0) | 0, 0x80) | 0;
			clocks = this.findClosestEvent(clocks | 0, this.IOCore.dma.nextDMA0IRQEventTime() | 0, 0x100) | 0;
			clocks = this.findClosestEvent(clocks | 0, this.IOCore.dma.nextDMA1IRQEventTime() | 0, 0x200) | 0;
			clocks = this.findClosestEvent(clocks | 0, this.IOCore.dma.nextDMA2IRQEventTime() | 0, 0x400) | 0;
			clocks = this.findClosestEvent(clocks | 0, this.IOCore.dma.nextDMA3IRQEventTime() | 0, 0x800) | 0;
			//JoyPad input state should never update while we're in halt:
			//clocks = this.findClosestEvent(clocks | 0, this.IOCore.joypad.nextIRQEventTime() | 0, 0x1000) | 0;
			//clocks = this.findClosestEvent(clocks | 0, this.IOCore.cartridge.nextIRQEventTime() | 0, 0x2000) | 0;
			return clocks | 0;
		}
		public function findClosestEvent(oldClocks, newClocks, flagID) {
			oldClocks = oldClocks | 0;
			newClocks = newClocks | 0;
			flagID = flagID | 0;
			if ((this.interruptsEnabled & flagID) == 0) {
				return oldClocks | 0;
			}
			if (oldClocks > -1) {
				if (newClocks > -1) {
					return Math.min(oldClocks | 0, newClocks | 0) | 0;
				}
				return oldClocks | 0;
			}
			return newClocks | 0;
		}
		
		

	}
	
}
