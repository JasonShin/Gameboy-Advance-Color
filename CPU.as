package  {
	import CPU.ARMInstructionSet;
	import CPU.THUMBInstructionSet;
	import CPU.GameBoyAdvanceSWICore;
	import CPU.dynarec.DynarecBranchListenerCore;
	import memory.GameBoyAdvanceMemoryCache;
	import utils.MathsHelper;
	import utils.ArrayHelper;
	
	
	public class CPU {
		
		public var ARM;
		public var THUMB;
		public var swi;
		public var dynarec;
		public var instructionHandle;
		public var calculateMUL32;
		public var randomMemoryCache;
		
		
		public var IOCore;
		public var memoryCore:GameBoyAdvanceMemory;
		public var emulatorCore;
		public var wait;
		public var mul64ResultHigh;
		public var mul64ResultLow;
		
		public var registers:Array;
			//Used to copy back the R8-R14 state for normal operations:
		public var registersUSR:Array;
		//Fast IRQ mode registers (R8-R14):
		public var registersFIQ:Array;
		//Supervisor mode registers (R13-R14):
		public var registersSVC:Array;
		//Abort mode registers (R13-R14):
		public var registersABT:Array;
		//IRQ mode registers (R13-R14):
		public var registersIRQ:Array;
		//Undefined mode registers (R13-R14):
		public var registersUND:Array;
		//CPSR Register:
		public var CPSRNegative:Boolean;
		public var CPSRZero:Boolean;
		public var CPSROverflow:Boolean;
		public var CPSRCarry:Boolean;
		public var IRQDisabled:Boolean;
		public var FIQDisabled:Boolean;
		public var InTHUMB:Boolean;
		public var MODEBits:int;
		//Banked SPSR Registers:
		public var SPSRFIQ:Array;
		public var SPSRIRQ:Array;
		public var SPSRSVC:Array;
		public var SPSRABT:Array;
		public var SPSRUND:Array;
		public var triggeredIRQ:Boolean;		//Pending IRQ found.
		public var pipelineInvalid:int;		//Mark pipeline as invalid.
		
		public var spsr;
		
		public function CPU(IOCore) {
			// constructor code
			this.IOCore = IOCore;
			this.memoryCore = this.IOCore.memory;
			this.emulatorCore = this.IOCore.emulatorCore;
			this.wait = this.IOCore.wait;
			this.mul64ResultHigh = 0;	//Scratch MUL64.
			this.mul64ResultLow = 0;	//Scratch MUL64.
			this.initialize();
		}
		
		public function initialize() {
			this.initializeRegisters();
			this.ARM = new ARMInstructionSet(this);
			this.THUMB = new THUMBInstructionSet(this);
			this.swi = new GameBoyAdvanceSWICore(this);
			this.dynarec = new DynarecBranchListenerCore(this);
			this.instructionHandle = this.ARM;
			
			this.calculateMUL32 = (MathsHelper.imul != null) ? this.calculateMUL32Fast : this.calculateMUL32Slow;
			//this.calculateMUL32 = this.calculateMUL32Slow;
			this.randomMemoryCache = new GameBoyAdvanceMemoryCache(this.memoryCore);
		}
		
		public function initializeRegisters() {
			/*
				R0-R7 Are known as the low registers.
				R8-R12 Are the high registers.
				R13 is the stack pointer.
				R14 is the link register.
				R15 is the program counter.
				CPSR is the program status register.
				SPSR is the saved program status register.
			*/
			//Normal R0-R15 Registers:
			this.registers =  ArrayHelper.buildArray(16);
			//Used to copy back the R8-R14 state for normal operations:
			this.registersUSR =  ArrayHelper.buildArray(7);
			//Fast IRQ mode registers (R8-R14):
			this.registersFIQ = ArrayHelper.buildArray(7);
			//Supervisor mode registers (R13-R14):
			this.registersSVC = ArrayHelper.buildArray(2);
			//Abort mode registers (R13-R14):
			this.registersABT = ArrayHelper.buildArray(2);
			//IRQ mode registers (R13-R14):
			this.registersIRQ = ArrayHelper.buildArray(2);
			//Undefined mode registers (R13-R14):
			this.registersUND = ArrayHelper.buildArray(2);
			//CPSR Register:
			this.CPSRNegative = false;		//N Bit
			this.CPSRZero = false;			//Z Bit
			this.CPSROverflow = false;		//V Bit
			this.CPSRCarry = false;			//C Bit
			this.IRQDisabled = true;		//I Bit
			this.FIQDisabled = true;		//F Bit
			this.InTHUMB = false;			//T Bit
			this.MODEBits = 0x13;			//M0 thru M4 Bits
			//Banked SPSR Registers:
			this.SPSRFIQ = [false, false, false, false, true, true, false, 0x13];	//FIQ
			this.SPSRIRQ = [false, false, false, false, true, true, false, 0x13];	//IRQ
			this.SPSRSVC = [false, false, false, false, true, true, false, 0x13];	//Supervisor
			this.SPSRABT = [false, false, false, false, true, true, false, 0x13];	//Abort
			this.SPSRUND = [false, false, false, false, true, true, false, 0x13];	//Undefined
			this.triggeredIRQ = false;		//Pending IRQ found.
			this.pipelineInvalid = 0x4;		//Mark pipeline as invalid.
			//Pre-initialize stack pointers if no BIOS loaded:
			if (!this.IOCore.BIOSFound || this.IOCore.emulatorCore.SKIPBoot) {
				this.registersSVC[0] = 0x3007FE0;
				this.registersIRQ[0] = 0x3007FA0;
				this.registers[13] = 0x3007F00;
				this.registers[15] = 0x8000000;
				this.MODEBits = 0x1F;
			}
		}
		
		
		public function executeIteration() {
			//Check for pending IRQ:
			this.checkPendingIRQ();
			//Tick the pipeline and bubble out invalidity:
			this.pipelineInvalid >>= 1;
			//Tick the pipeline of the selected instruction set:
			this.instructionHandle.executeIteration();
			//Increment the program counter if we didn't just branch:
			
			if ((this.pipelineInvalid | 0) < 0x4) {
				this.instructionHandle.incrementProgramCounter();
			}
			
			
		}
		public function branch(branchTo) {
			branchTo = branchTo | 0;
			if (branchTo > 0x3FFF || this.IOCore.BIOSFound) {
				//Tell the JIT information on the state before branch:
				 if (this.emulatorCore.dynarecEnabled) {
					this.dynarec.listen(this.registers[15] | 0, branchTo | 0, this.InTHUMB, this.MODEBits | 0);
				}
				//Branch to new address:
				this.registers[15] = branchTo | 0;
				//Mark pipeline as invalid:
				this.pipelineInvalid = 0x4;
				//Next PC fetch has to update the address bus:
				this.wait.NonSequentialBroadcast();
			}
			else {
				//We're branching into BIOS, handle specially:
				if (branchTo == 0x130) {
					//IRQ mode exit handling:
					//ROM IRQ handling returns back from its own subroutine back to BIOS at this address.
					this.HLEIRQExit();
				}
				else {
					//Illegal to branch directly into BIOS (Except for return from IRQ), only SWIs can:
					throw(new Error("Could not handle branch to: " + branchTo.toString(16)));
				}
			}
		}
		public function checkPendingIRQ() {
			if (this.triggeredIRQ && !this.IRQDisabled) {
				//Branch for IRQ now:
				this.IRQ();
			}
		}
		public function triggerIRQ(didFire) {
			this.triggeredIRQ = !!didFire;
		}
		public function getCurrentFetchValue() {
			return this.instructionHandle.fetch | 0;
		}
		public function enterARM() {
			this.THUMBBitModify(false);
		}
		public function enterTHUMB() {
			this.THUMBBitModify(true);
		}
		public function getLR() {
			//Get the previous instruction address:
			return this.instructionHandle.getLR() | 0;
		}
		public function getIRQLR() {
			//Get the previous instruction address:
			var lr = this.instructionHandle.getIRQLR();
			var modeOffset = (this.InTHUMB) ? 2 : 4;
			if (this.pipelineInvalid > 1) {
				while (this.pipelineInvalid > 1) {
					lr = (lr + modeOffset) | 0;
					this.pipelineInvalid >>= 1;
				}
			}
			return lr | 0;
		}
		public function THUMBBitModify(isThumb) {
			this.InTHUMB = isThumb;
			if (isThumb) {
				this.instructionHandle = this.THUMB;
			}
			else {
				this.instructionHandle = this.ARM;
			}
		}
		public function IRQ() {
			//Mode bits are set to IRQ:
			this.switchMode(0x12);
			//Save link register:
			this.registers[14] = this.getIRQLR() | 0;
			//Disable IRQ:
			this.IRQDisabled = true;
			if (this.IOCore.BIOSFound) {
				//Exception always enter ARM mode:
				this.enterARM();
				//IRQ exception vector:
				this.branch(0x18);
			}
			else {
				//HLE the IRQ entrance:
				this.HLEIRQEnter();
			}
		}
		public function HLEIRQEnter() {
			//Exception always enter ARM mode:
			this.enterARM();
			//Get the base address:
			var currentAddress = this.registers[0xD] | 0;
			//Updating the address bus away from PC fetch:
			this.wait.NonSequentialBroadcast();
			//Push register(s) into memory:
			for (var rListPosition = 0xF; rListPosition > -1; rListPosition = (rListPosition - 1) | 0) {
					if ((0x500F & (1 << rListPosition)) != 0) {
						//Push a register into memory:
						currentAddress = (currentAddress - 4) | 0;
						this.randomMemoryCache.memoryWrite32(currentAddress >>> 0, this.registers[rListPosition >>> 0] | 0);
					}
			}
			//Store the updated base address back into register:
			this.registers[0xD] = currentAddress | 0;
			//Updating the address bus back to PC fetch:
			this.wait.NonSequentialBroadcast();
			this.registers[0] = 0x4000000;
			//Save link register:
			this.registers[14] = 0x130;
			//Skip BIOS ROM processing:
			this.branch(this.read32(0x3FFFFFC) & -0x4);
		}
		public function HLEIRQExit() {
			//Get the base address:
			var currentAddress = this.registers[0xD] | 0;
			//Updating the address bus away from PC fetch:
			this.wait.NonSequentialBroadcast();
			//Load register(s) from memory:
			for (var rListPosition = 0; rListPosition < 0x10;  rListPosition = (rListPosition + 1) | 0) {
				if ((0x500F & (1 << rListPosition)) != 0) {
					//Load a register from memory:
					this.registers[rListPosition & 0xF] = this.randomMemoryCache.memoryRead32(currentAddress >>> 0) | 0;
					currentAddress = (currentAddress + 4) | 0;
				}
			}
			//Store the updated base address back into register:
			this.registers[0xD] = currentAddress | 0;
			//Updating the address bus back to PC fetch:
			this.wait.NonSequentialBroadcast();
			//Return from an exception mode:
			var data = this.setSUBFlags(this.registers[0xE] | 0, 4) | 0;
			//Restore SPSR to CPSR:
			this.SPSRtoCPSR();
			data &= (!this.InTHUMB) ? -4 : -2;
			//We performed a branch:
			this.branch(data | 0);
		}
		public function SWI() {
			if (this.IOCore.BIOSFound) {
				//Mode bits are set to SWI:
				this.switchMode(0x13);
				//Save link register:
				this.registers[14] = this.getLR() | 0;
				//Disable IRQ:
				this.IRQDisabled = true;
				//Exception always enter ARM mode:
				this.enterARM();
				//SWI exception vector:
				this.branch(0x8);
			}
			else {
				//HLE the SWI command:
				this.swi.execute(this.read8((this.getLR() - 2) | 0));
			}
		}
		public function UNDEFINED() {
			//Only process undefined instruction if BIOS loaded:
			if (this.IOCore.BIOSFound) {
				//Mode bits are set to SWI:
				this.switchMode(0x1B);
				//Save link register:
				this.registers[14] = this.getLR() | 0;
				//Disable IRQ:
				this.IRQDisabled = true;
				//Exception always enter ARM mode:
				this.enterARM();
				//Undefined exception vector:
				this.branch(0x4);
			}
		}
		public function SPSRtoCPSR() {
			//Used for leaving an exception and returning to the previous state:
			switch (this.MODEBits | 0) {
				case 0x11:	//FIQ
					spsr = this.SPSRFIQ;
					break;
				case 0x12:	//IRQ
					spsr = this.SPSRIRQ;
					break;
				case 0x13:	//Supervisor
					spsr = this.SPSRSVC;
					break;
				case 0x17:	//Abort
					spsr = this.SPSRABT;
					break;
				case 0x1B:	//Undefined
					spsr = this.SPSRUND;
					break;
				default:
					return;
			}
			this.CPSRNegative = spsr[0];
			this.CPSRZero = spsr[1];
			this.CPSROverflow = spsr[2];
			this.CPSRCarry = spsr[3];
			this.IRQDisabled = spsr[4];
			this.FIQDisabled = spsr[5];
			this.THUMBBitModify(spsr[6]);
			this.switchRegisterBank(spsr[7]);
		}
		public function switchMode(newMode) {
			newMode = newMode | 0;
			this.CPSRtoSPSR(newMode | 0);
			this.switchRegisterBank(newMode | 0);
		}
		public function CPSRtoSPSR(newMode) {
			//Used for leaving an exception and returning to the previous state:
			switch (newMode | 0) {
				case 0x11:	//FIQ
					spsr = this.SPSRFIQ;
					break;
				case 0x12:	//IRQ
					spsr = this.SPSRIRQ;
					break;
				case 0x13:	//Supervisor
					spsr = this.SPSRSVC;
					break;
				case 0x17:	//Abort
					spsr = this.SPSRABT;
					break;
				case 0x1B:	//Undefined
					spsr = this.SPSRUND;
				default:	//Any other mode does not have access here.
					return;
			}
			spsr[0] = this.CPSRNegative;
			spsr[1] = this.CPSRZero;
			spsr[2] = this.CPSROverflow;
			spsr[3] = this.CPSRCarry;
			spsr[4] = this.IRQDisabled;
			spsr[5] = this.FIQDisabled;
			spsr[6] = this.InTHUMB;
			spsr[7] = this.MODEBits;
		}
		public function switchRegisterBank(newMode) {
			newMode = newMode | 0;
			switch (this.MODEBits | 0) {
				case 0x10:
				case 0x1F:
					this.registersUSR[0] = this.registers[8];
					this.registersUSR[1] = this.registers[9];
					this.registersUSR[2] = this.registers[10];
					this.registersUSR[3] = this.registers[11];
					this.registersUSR[4] = this.registers[12];
					this.registersUSR[5] = this.registers[13];
					this.registersUSR[6] = this.registers[14];
					break;
				case 0x11:
					this.registersFIQ[0] = this.registers[8];
					this.registersFIQ[1] = this.registers[9];
					this.registersFIQ[2] = this.registers[10];
					this.registersFIQ[3] = this.registers[11];
					this.registersFIQ[4] = this.registers[12];
					this.registersFIQ[5] = this.registers[13];
					this.registersFIQ[6] = this.registers[14];
					break;
				case 0x12:
					this.registersUSR[0] = this.registers[8];
					this.registersUSR[1] = this.registers[9];
					this.registersUSR[2] = this.registers[10];
					this.registersUSR[3] = this.registers[11];
					this.registersUSR[4] = this.registers[12];
					this.registersIRQ[0] = this.registers[13];
					this.registersIRQ[1] = this.registers[14];
					break;
				case 0x13:
					this.registersUSR[0] = this.registers[8];
					this.registersUSR[1] = this.registers[9];
					this.registersUSR[2] = this.registers[10];
					this.registersUSR[3] = this.registers[11];
					this.registersUSR[4] = this.registers[12];
					this.registersSVC[0] = this.registers[13];
					this.registersSVC[1] = this.registers[14];
					break;
				case 0x17:
					this.registersUSR[0] = this.registers[8];
					this.registersUSR[1] = this.registers[9];
					this.registersUSR[2] = this.registers[10];
					this.registersUSR[3] = this.registers[11];
					this.registersUSR[4] = this.registers[12];
					this.registersABT[0] = this.registers[13];
					this.registersABT[1] = this.registers[14];
					break;
				case 0x1B:
					this.registersUSR[0] = this.registers[8];
					this.registersUSR[1] = this.registers[9];
					this.registersUSR[2] = this.registers[10];
					this.registersUSR[3] = this.registers[11];
					this.registersUSR[4] = this.registers[12];
					this.registersUND[0] = this.registers[13];
					this.registersUND[1] = this.registers[14];
			}
			switch (newMode | 0) {
				case 0x10:
				case 0x1F:
					this.registers[8] = this.registersUSR[0];
					this.registers[9] = this.registersUSR[1];
					this.registers[10] = this.registersUSR[2];
					this.registers[11] = this.registersUSR[3];
					this.registers[12] = this.registersUSR[4];
					this.registers[13] = this.registersUSR[5];
					this.registers[14] = this.registersUSR[6];
					break;
				case 0x11:
					this.registers[8] = this.registersFIQ[0];
					this.registers[9] = this.registersFIQ[1];
					this.registers[10] = this.registersFIQ[2];
					this.registers[11] = this.registersFIQ[3];
					this.registers[12] = this.registersFIQ[4];
					this.registers[13] = this.registersFIQ[5];
					this.registers[14] = this.registersFIQ[6];
					break;
				case 0x12:
					this.registers[8] = this.registersUSR[0];
					this.registers[9] = this.registersUSR[1];
					this.registers[10] = this.registersUSR[2];
					this.registers[11] = this.registersUSR[3];
					this.registers[12] = this.registersUSR[4];
					this.registers[13] = this.registersIRQ[0];
					this.registers[14] = this.registersIRQ[1];
					break;
				case 0x13:
					this.registers[8] = this.registersUSR[0];
					this.registers[9] = this.registersUSR[1];
					this.registers[10] = this.registersUSR[2];
					this.registers[11] = this.registersUSR[3];
					this.registers[12] = this.registersUSR[4];
					this.registers[13] = this.registersSVC[0];
					this.registers[14] = this.registersSVC[1];
					break;
				case 0x17:
					this.registers[8] = this.registersUSR[0];
					this.registers[9] = this.registersUSR[1];
					this.registers[10] = this.registersUSR[2];
					this.registers[11] = this.registersUSR[3];
					this.registers[12] = this.registersUSR[4];
					this.registers[13] = this.registersABT[0];
					this.registers[14] = this.registersABT[1];
					break;
				case 0x1B:
					this.registers[8] = this.registersUSR[0];
					this.registers[9] = this.registersUSR[1];
					this.registers[10] = this.registersUSR[2];
					this.registers[11] = this.registersUSR[3];
					this.registers[12] = this.registersUSR[4];
					this.registers[13] = this.registersUND[0];
					this.registers[14] = this.registersUND[1];
			}
			this.MODEBits = newMode | 0;
		}
		public function setADDFlags(operand1, operand2) {
			//Update flags for an addition operation:
			operand1 >>>= 0;
			operand2 >>>= 0;
			var unsignedResult = operand1 + operand2;
			var result = unsignedResult | 0;
			this.setVFlagForADD(operand1 | 0, operand2 | 0, result | 0);
			this.CPSRCarry = (unsignedResult > 0xFFFFFFFF);
			this.CPSRNegative = (result < 0);
			this.CPSRZero = (result == 0);
			return result | 0;
		}
		public function setADCFlags(operand1, operand2) {
			//Update flags for an addition operation:
			operand1 >>>= 0;
			operand2 >>>= 0;
			var unsignedResult = operand1 + operand2 + ((this.CPSRCarry) ? 1 : 0);
			var result = unsignedResult | 0;
			this.setVFlagForADD(operand1 | 0, operand2 | 0, result | 0);
			this.CPSRCarry = (unsignedResult > 0xFFFFFFFF);
			this.CPSRNegative = (result < 0);
			this.CPSRZero = (result == 0);
			return result | 0;
		}
		public function setSUBFlags(operand1, operand2) {
			//Update flags for a subtraction operation:
			operand1 >>>= 0;
			operand2 >>>= 0;
			var result = ((operand1 | 0) - (operand2 | 0)) | 0;
			this.setVFlagForSUB(operand1 | 0, operand2 | 0, result | 0);
			this.CPSRCarry = (operand1 >= operand2);
			this.CPSRNegative = (result < 0);
			this.CPSRZero = (result == 0);
			return result | 0;
		}
		public function setSBCFlags(operand1, operand2) {
			//Update flags for a subtraction operation:
			operand1 >>>= 0;
			operand2 >>>= 0;
			var unsignedResult = operand1 - operand2 - ((this.CPSRCarry) ? 0 : 1);
			var result = unsignedResult | 0;
			this.setVFlagForSUB(operand1 | 0, operand2 | 0, result | 0);
			this.CPSRCarry = (unsignedResult >= 0);
			this.CPSRNegative = (result < 0);
			this.CPSRZero = (result == 0);
			return result | 0;
		}
		public function setCMPFlags(operand1, operand2) {
			//Update flags for a subtraction operation:
			operand1 >>>= 0;
			operand2 >>>= 0;
			var result = ((operand1 | 0) - (operand2 | 0)) | 0;
			this.setVFlagForSUB(operand1 | 0, operand2 | 0, result | 0);
			this.CPSRCarry = (operand1 >= operand2);
			this.CPSRNegative = (result < 0);
			this.CPSRZero = (result == 0);
		}
		public function setCMNFlags(operand1, operand2) {
			//Update flags for an addition operation:
			operand1 >>>= 0;
			operand2 >>>= 0;
			var unsignedResult = operand1 + operand2;
			var result = unsignedResult | 0;
			this.setVFlagForADD(operand1 | 0, operand2 | 0, result | 0);
			this.CPSRCarry = (unsignedResult > 0xFFFFFFFF);
			this.CPSRNegative = (result < 0);
			this.CPSRZero = (result == 0);
		}
		public function setVFlagForADD(operand1, operand2, result) {
			operand1 = operand1 | 0;
			operand2 = operand2 | 0;
			result = result | 0;
			this.CPSROverflow = ((operand1 ^ operand2) >= 0 && (operand1 ^ result) < 0);
		}
		public function setVFlagForSUB(operand1, operand2, result) {
			operand1 = operand1 | 0;
			operand2 = operand2 | 0;
			result = result | 0;
			this.CPSROverflow = ((operand1 ^ operand2) < 0 && (operand1 ^ result) < 0);
		}
		public function calculateMUL32Slow(rs, rd) {
			rs = rs | 0;
			rd = rd | 0;
			/*
			 We have to split up the 32 bit multiplication,
			 as JavaScript does multiplication on the FPU
			 as double floats, which drops the low bits
			 rather than the high bits.
			 */
			var lowMul = (rs & 0xFFFF) * rd;
			var highMul = (rs >> 16) * rd;
			//Cut off bits above bit 31 and return with proper sign:
			return ((highMul << 16) + lowMul) | 0;
		}
		public function calculateMUL32Fast(rs:int, rd:int):int {
			rs = rs | 0;
			rd = rd | 0;
			//Used a proposed non-legacy extension that can do 32 bit signed multiplication:
			return MathsHelper.imul(rs | 0, rd | 0) | 0;
		}
		public function performMUL32(rs, rd, MLAClocks) {
			rs = rs | 0;
			rd = rd | 0;
			MLAClocks = MLAClocks | 0;
			//Predict the internal cycle time:
			if ((rd >>> 8) == 0 || (rd >>> 8) == 0xFFFFFF) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, (1 + (MLAClocks | 0)) | 0);
			}
			else if ((rd >>> 16) == 0 || (rd >>> 16) == 0xFFFF) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, (2 + (MLAClocks | 0)) | 0);
			}
			else if ((rd >>> 24) == 0 || (rd >>> 24) == 0xFF) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, (3 + (MLAClocks | 0)) | 0);
			}
			else {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, (4 + (MLAClocks | 0)) | 0);
			}
			return this.calculateMUL32(rs | 0, rd | 0) | 0;
		}
		public function performMUL64(rs, rd) {
			rs = rs | 0;
			rd = rd | 0;
			//Predict the internal cycle time:
			if ((rd >>> 8) == 0 || (rd >>> 8) == 0xFFFFFF) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 2);
			}
			else if ((rd >>> 16) == 0 || (rd >>> 16) == 0xFFFF) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 3);
			}
			else if ((rd >>> 24) == 0 || (rd >>> 24) == 0xFF) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 4);
			}
			else {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 5);
			}
			//Solve for the high word (Do FPU double divide to bring down high word into the low word):
			this.mul64ResultHigh = ((rs * rd) / 0x100000000) | 0;
			this.mul64ResultLow = this.calculateMUL32(rs | 0, rd | 0) | 0;
		}
		public function performMLA64(rs, rd, mlaHigh, mlaLow) {
			rs = rs | 0;
			rd = rd | 0;
			mlaHigh = mlaHigh | 0;
			mlaLow = mlaLow | 0;
			//Predict the internal cycle time:
			if ((rd >>> 8) == 0 || (rd >>> 8) == 0xFFFFFF) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 3);
			}
			else if ((rd >>> 16) == 0 || (rd >>> 16) == 0xFFFF) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 4);
			}
			else if ((rd >>> 24) == 0 || (rd >>> 24) == 0xFF) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 5);
			}
			else {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 6);
			}
			//Solve for the high word (Do FPU double divide to bring down high word into the low word):
			this.mul64ResultHigh = ((((rs * rd) + (mlaLow >>> 0)) / 0x100000000) + (mlaHigh >>> 0)) | 0;
			/*
				We have to split up the 64 bit multiplication,
				as JavaScript does multiplication on the FPU
				as double floats, which drops the low bits
				rather than the high bits.
			*/
			var lowMul = (rs & 0xFFFF) * rd;
			var highMul = (rs >> 16) * rd;
			//Cut off bits above bit 31 and return with proper sign:
			this.mul64ResultLow = (((highMul << 16) >>> 0) + (lowMul >>> 0) + (mlaLow >>> 0)) | 0;
		}
		public function performUMUL64(rs, rd) {
			rs = rs | 0;
			rd = rd | 0;
			//Predict the internal cycle time:
			if ((rd >>> 8) == 0) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 2);
			}
			else if ((rd >>> 16) == 0) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 3);
			}
			else if ((rd >>> 24) == 0) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 4);
			}
			else {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 5);
			}
			//Type convert to uint32:
			rs >>>= 0;
			rd >>>= 0;
			//Solve for the high word (Do FPU double divide to bring down high word into the low word):
			this.mul64ResultHigh = ((rs * rd) / 0x100000000) | 0;
			/*
				We have to split up the 64 bit multiplication,
				as JavaScript does multiplication on the FPU
				as double floats, which drops the low bits
				rather than the high bits.
			*/
			var lowMul = (rs & 0xFFFF) * rd;
			var highMul = (rs >> 16) * rd;
			//Cut off bits above bit 31 and return with proper sign:
			this.mul64ResultLow = ((highMul << 16) + lowMul) | 0;
		}
		public function performUMLA64(rs, rd, mlaHigh, mlaLow) {
			rs = rs | 0;
			rd = rd | 0;
			mlaHigh = mlaHigh | 0;
			mlaLow = mlaLow | 0;
			//Predict the internal cycle time:
			if ((rd >>> 8) == 0) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 3);
			}
			else if ((rd >>> 16) == 0) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 4);
			}
			else if ((rd >>> 24) == 0) {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 5);
			}
			else {
				this.IOCore.wait.CPUInternalCyclePrefetch(this.instructionHandle.fetch | 0, 6);
			}
			//Type convert to uint32:
			rs >>>= 0;
			rd >>>= 0;
			//Solve for the high word (Do FPU double divide to bring down high word into the low word):
			this.mul64ResultHigh = ((((rs * rd) + mlaLow) / 0x100000000) + mlaHigh) | 0;
			/*
				We have to split up the 64 bit multiplication,
				as JavaScript does multiplication on the FPU
				as double floats, which drops the low bits
				rather than the high bits.
			*/
			var lowMul = (rs & 0xFFFF) * rd;
			var highMul = (rs >> 16) * rd;
			//Cut off bits above bit 31 and return with proper sign:
			this.mul64ResultLow = ((highMul << 16) + lowMul + mlaLow) | 0;
		}
		public function write32(address, data) {
			address = address | 0;
			data = data | 0;
			//Updating the address bus away from PC fetch:
			this.IOCore.wait.NonSequentialBroadcast();
			this.memoryCore.memoryWriteFast32((address & -4) >>> 0, data | 0);
			//Updating the address bus back to PC fetch:
			this.IOCore.wait.NonSequentialBroadcast();
		}
		public function write16(address, data) {
			address = address | 0;
			data = data | 0;
			//Updating the address bus away from PC fetch:
			this.IOCore.wait.NonSequentialBroadcast();
			
			this.memoryCore.memoryWriteFast16((address & -2) >>> 0, data | 0);
			//Updating the address bus back to PC fetch:
			this.IOCore.wait.NonSequentialBroadcast();
		}
		public function write8(address, data) {
			address = address | 0;
			data = data | 0;
			//Updating the address bus away from PC fetch:
			this.IOCore.wait.NonSequentialBroadcast();
			this.memoryCore.memoryWrite8(address >>> 0, data | 0);
			//Updating the address bus back to PC fetch:
			this.IOCore.wait.NonSequentialBroadcast();
		}
		public function read32(address) {
			address = address | 0;
			//Updating the address bus away from PC fetch:
			this.IOCore.wait.NonSequentialBroadcast();
			var data = this.memoryCore.memoryReadFast32((address & -4) >>> 0) | 0;
			var real_output = ((address & 0x3) == 0) ? data : ((data << ((4 - (address & 0x3)) << 3)) | (data >>> ((address & 0x3) << 3)));
			//Updating the address bus back to PC fetch:
			this.IOCore.wait.NonSequentialBroadcast();
			return real_output | 0;
		}
		public function read16(address) {
			address = address | 0;
			//Updating the address bus away from PC fetch:
			this.IOCore.wait.NonSequentialBroadcast();
			var data = this.memoryCore.memoryReadFast16((address & -2) >>> 0) | 0;
			//Updating the address bus back to PC fetch:
			this.IOCore.wait.NonSequentialBroadcast();
			return data | 0;
		}
		public function read8(address) {
			address = address | 0;
			//Updating the address bus away from PC fetch:
			this.IOCore.wait.NonSequentialBroadcast();
			var data = this.memoryCore.memoryRead8(address >>> 0) | 0;
			//Updating the address bus back to PC fetch:
			this.IOCore.wait.NonSequentialBroadcast();
			return data | 0;
		}
				
		

	}
	
}
