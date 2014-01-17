package  {
	import utils.Logger;
	
	public class GameBoyAdvanceIO {

		public var emulatorCore = emulatorCore;
			
		//State Machine Tracking:
		public var systemStatus = 0;
		public var executeDynarec = false;
		public var cyclesToIterate = 0;
		public var cyclesIteratedPreviously = 0;
		public var accumulatedClocks = 0;
		public var nextEventClocks = 0;
		public var BIOSFound = false;
		//Initialize the various handler objects:
		public var memory;
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
		
		public var stepHandle;
		
		public var test:String = "";

		public function GameBoyAdvanceIO(emulatorCore:EmulatorCore) {
			// constructor code
			this.emulatorCore = emulatorCore;
			
			//State Machine Tracking:
			this.systemStatus = 0;
			this.executeDynarec = false;
			this.cyclesToIterate = 0;
			this.cyclesIteratedPreviously = 0;
			this.accumulatedClocks = 0;
			this.nextEventClocks = 0;
			this.BIOSFound = false;
			//Initialize the various handler objects:
			this.memory = new GameBoyAdvanceMemory(this);
			this.dma = new GameBoyAdvanceDMA(this);
			this.gfx = new GameBoyAdvanceGraphics(this);
			this.sound = new GameBoyAdvanceSound(this);
			this.timer = new GameBoyAdvanceTimer(this);
			this.irq = new GameBoyAdvanceIRQ(this);
			this.serial = new GameBoyAdvanceSerial(this);
			this.joypad = new GameBoyAdvanceJoyPad(this);
			this.cartridge = new GameBoyAdvanceCartridge(this);
			this.wait = new GameBoyAdvanceWait(this);
			this.cpu = new CPU(this);
			this.memory.loadReferences();
			this.preprocessSystemStepper();
		}
		
		public function iterate() {
			//Find out how many clocks to iterate through this run:
			trace("iterating");
			this.cyclesToIterate = ((this.emulatorCore.CPUCyclesTotal | 0) - (this.cyclesIteratedPreviously | 0)) | 0;
			//Update our core event prediction:
			this.updateCoreEventTime();
			//If clocks remaining, run iterator:
			this.runIterator();
			//Spill our core event clocking:
			this.updateCoreClocking();
			//Ensure audio buffers at least once per iteration:
			this.sound.audioJIT();
			//If we clocked just a little too much, subtract the extra from the next run:
			this.cyclesIteratedPreviously = this.cyclesToIterate | 0;
		}
		
		public var numCount:uint = 0;
		public var stopO:Boolean = true;
		
		public function runIterator() {
			//Clock through the state machine:
			while ((this.cyclesToIterate | 0) > 0) {
				//Handle the current system state selected:
				if(stopO){
					numCount++;
				}
				this.stepHandle();
				
			}
		}
		
		
		
		public function updateCore(clocks) {
			clocks = clocks | 0;
			//This is used during normal/dma modes of operation:
			this.accumulatedClocks = ((this.accumulatedClocks | 0) + (clocks | 0)) | 0;
			
			if ((this.accumulatedClocks | 0) >= (this.nextEventClocks | 0)) {
				this.updateCoreSpill();
			}
		}
		public function updateCoreSpill() {
			this.updateCoreClocking();
			this.updateCoreEventTime();
		}
		public function updateCoreClocking() {
			var clocks = this.accumulatedClocks | 0;
			//Decrement the clocks per iteration counter:
			this.cyclesToIterate = ((this.cyclesToIterate | 0) - (clocks | 0)) | 0;
			//Clock all components:
			this.gfx.addClocks(clocks | 0);
			this.timer.addClocks(clocks | 0);
			this.serial.addClocks(clocks | 0);
			this.accumulatedClocks = 0;
		}
		public function updateCoreEventTime() {
			this.nextEventClocks = this.cyclesUntilNextEvent() | 0;
		}
		public function preprocessSystemStepper() {
			switch (this.systemStatus | 0) {
				case 0: //CPU Handle State
					this.stepHandle = this.handleCPU;
					break;
				case 1:	//DMA Handle State
					this.stepHandle = this.handleDMA;
					break;
				case 2: //Handle Halt State
					this.stepHandle = this.handleHalt;
					break;
				case 3: //DMA Inside Halt State
					this.stepHandle = this.handleDMA;
					break;
				case 4: //Handle Stop State
					this.stepHandle = this.handleStop;
					break;
				default:
					throw(new Error("Invalid state selected."));
			}
		}
		public function handleCPU() {
			//Execute next instruction:
			if (!this.executeDynarec) {
				//Interpreter:
				this.cpu.executeIteration();
			}
			else {
				//LLE Dynarec JIT
				this.executeDynarec = !!this.cpu.dynarec.enter();
			}
		}
		public function handleDMA() {
			if (this.dma.perform()) {
				//If DMA is done, exit it:
				this.deflagStepper(0x1);
			}
		}
		public function handleHalt() {
			if (!this.irq.IRQMatch()) {
				//Clock up to next IRQ match or DMA:
				this.updateCore(this.cyclesUntilNextEvent() | 0);
			}
			else {
				//Exit HALT promptly:
				this.deflagStepper(0x2);
			}
		}
		public function handleStop() {
			//Update sound system to add silence to buffer:
			this.sound.addClocks(this.cyclesToIterate | 0);
			this.cyclesToIterate = 0;
			//Exits when user presses joypad or from an external irq outside of GBA internal.
		}
		public function cyclesUntilNextEvent() {
			//Find the clocks to the next event:
			var clocks = this.irq.nextEventTime() | 0;
			var dmaClocks = this.dma.nextEventTime() | 0;
			clocks = ((clocks > -1) ? ((dmaClocks > -1) ? Math.min(clocks | 0, dmaClocks | 0) : (clocks | 0)) : (dmaClocks | 0)) | 0;
			clocks = ((clocks == -1 || clocks > this.cyclesToIterate) ? (this.cyclesToIterate | 0) : (clocks | 0)) | 0;
			return clocks | 0;
		}
		public function deflagStepper(statusFlag) {
			//Deflag a system event to step through:
			statusFlag = statusFlag | 0;
			this.systemStatus = ((this.systemStatus | 0) & (~statusFlag)) | 0;
			this.preprocessSystemStepper();
		}
		public function flagStepper(statusFlag) {
			//Flag a system event to step through:
			statusFlag = statusFlag | 0;
			this.systemStatus = ((this.systemStatus | 0) | (statusFlag | 0)) | 0;
			this.preprocessSystemStepper();
		}
		
		
		
	}
	
}
