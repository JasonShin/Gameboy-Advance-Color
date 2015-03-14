package CPU {
	import memory.GameBoyAdvanceMemoryCache;
	import utils.Logger;
	
	public class ARMInstructionSet {
		
		public var CPUCore:CPU;
		public var IOCore;
		public var memory;
		public var wait;
		public var registers;
		public var registersUSR;
		public var fetch;
		public var decode;
		public var execute;
		public var stackMemoryCache;
		public var instructionMapReduced;
		public var instructionMap;
		public var spsr;

		public function ARMInstructionSet(cpu:CPU) {
			// constructor code
			this.CPUCore = cpu;
			initialize();
		}
		
		public function initialize():void {
			this.IOCore = this.CPUCore.IOCore;
			this.memory = this.IOCore.memory;
			this.wait = this.IOCore.wait;
			this.registers = this.CPUCore.registers;
			this.registersUSR = this.CPUCore.registersUSR;
			this.fetch = 0;
			this.decode = 0;
			this.execute = 0;
			this.stackMemoryCache = new GameBoyAdvanceMemoryCache(this.memory);
			this.compileInstructionMap();
			this.compileReducedInstructionMap();
		}
		
		public function executeIteration() {
			//Push the new fetch access:
			
			this.fetch = this.wait.CPUGetOpcode32(this.registers[15]);
			
			//Execute Conditional Instruction:
			
			this.executeARM();
			
			//Update the pipelining state:
			this.execute = this.decode | 0;
			this.decode = this.fetch | 0;
		}
		public function executeARM() {
			//Don't execute if the pipeline is still invalid:
			
			if ((this.CPUCore.pipelineInvalid | 0) == 0) {
				//Check the condition code:
				if (this.conditionCodeTest()) {
					var inst:Function = this.instructionMapReduced[((this.execute >> 16) & 0xFF0) | ((this.execute >> 4) & 0xF)];
					inst();
					
				}
			}
		}
		
		public function incrementProgramCounter() {
			//Increment The Program Counter:
			this.registers[15] = ((this.registers[15] | 0) + 4) | 0;
		}
		public function conditionCodeTest() {
			switch (this.execute >>> 28) {
				case 0xE:		//AL (always)
								//Put this case first, since it's the most common!
					return true;
				case 0x0:		//EQ (equal)
					return this.CPUCore.CPSRZero;
				case 0x1:		//NE (not equal)
					return !this.CPUCore.CPSRZero;
				case 0x2:		//CS (unsigned higher or same)
					return this.CPUCore.CPSRCarry;
				case 0x3:		//CC (unsigned lower)
					return !this.CPUCore.CPSRCarry;
				case 0x4:		//MI (negative)
					return this.CPUCore.CPSRNegative;
				case 0x5:		//PL (positive or zero)
					return !this.CPUCore.CPSRNegative;
				case 0x6:		//VS (overflow)
					return this.CPUCore.CPSROverflow;
				case 0x7:		//VC (no overflow)
					return !this.CPUCore.CPSROverflow;
				case 0x8:		//HI (unsigned higher)
					return this.CPUCore.CPSRCarry && !this.CPUCore.CPSRZero;
				case 0x9:		//LS (unsigned lower or same)
					return !this.CPUCore.CPSRCarry || this.CPUCore.CPSRZero;
				case 0xA:		//GE (greater or equal)
					return this.CPUCore.CPSRNegative == this.CPUCore.CPSROverflow;
				case 0xB:		//LT (less than)
					return this.CPUCore.CPSRNegative != this.CPUCore.CPSROverflow;
				case 0xC:		//GT (greater than)
					return !this.CPUCore.CPSRZero && this.CPUCore.CPSRNegative == this.CPUCore.CPSROverflow;
				case 0xD:		//LE (less than or equal)
					return this.CPUCore.CPSRZero || this.CPUCore.CPSRNegative != this.CPUCore.CPSROverflow;
				//case 0xF:		//Reserved (Never Execute)
				default:
					return false;
			}
		}
		public function getLR() {
			return ((this.readRegister(15) | 0) - 4) | 0;
		}
		public function getIRQLR() {
			return this.getLR() | 0;
		}
		public function writeRegister(address, data) {
			//Unguarded non-pc register write:
			address = address | 0;
			data = data | 0;
			this.registers[address & 0xF] = data | 0;
		}
		public function writeUserRegister(address, data) {
			//Unguarded non-pc user mode register write:
			address = address | 0;
			data = data | 0;
			this.registersUSR[address & 0x7] = data | 0;
		}
		public function guardRegisterWrite(address, data) {
			//Guarded register write:
			address = address | 0;
			data = data | 0;
			if ((address | 0) < 0xF) {
				//Non-PC Write:
				this.writeRegister(address | 0, data | 0);
			}
			else {
				//We performed a branch:
				this.CPUCore.branch(data & -4);
			}
		}
		public function guardProgramCounterRegisterWriteCPSR(data) {
			data = data | 0;
			//Restore SPSR to CPSR:
			this.CPUCore.SPSRtoCPSR();
			data &= (!this.CPUCore.InTHUMB) ? -4 : -2;
			//We performed a branch:
			this.CPUCore.branch(data | 0);
		}
		public function guardRegisterWriteCPSR(address, data) {
			//Guard for possible pc write with cpsr update:
			address = address | 0;
			data = data | 0;
			if ((address | 0) < 0xF) {
				//Non-PC Write:
				this.writeRegister(address | 0, data | 0);
			}
			else {
				//Restore SPSR to CPSR:
				this.guardProgramCounterRegisterWriteCPSR(data | 0);
			}
		}
		public function guardUserRegisterWrite(address, data) {
			//Guard only on user access, not PC!:
			address = address | 0;
			data = data | 0;
			switch (this.CPUCore.MODEBits | 0) {
				case 0x10:
				case 0x1F:
					this.writeRegister(address | 0, data | 0);
					break;
				case 0x11:
					if ((address | 0) < 8) {
						this.writeRegister(address | 0, data | 0);
					}
					else {
						//User-Mode Register Write Inside Non-User-Mode:
						this.writeUserRegister(address | 0, data | 0);
					}
					break;
				default:
					if ((address | 0) < 13) {
						this.writeRegister(address | 0, data | 0);
					}
					else {
						//User-Mode Register Write Inside Non-User-Mode:
						this.writeUserRegister(address | 0, data | 0);
					}
			}
		}
		public function guardRegisterWriteLDM(parentObj, address, data) {
			//Proxy guarded register write for LDM:
			address = address | 0;
			data = data | 0;
			parentObj.guardRegisterWrite(address | 0, data | 0);
		}
		public function guardUserRegisterWriteLDM(parentObj, address, data) {
			//Proxy guarded user mode register write with PC guard for LDM:
			address = address | 0;
			data = data | 0;
			if ((address | 0) < 0xF) {
				parentObj.guardUserRegisterWrite(address | 0, data | 0);
			}
			else {
				parentObj.guardProgramCounterRegisterWriteCPSR(data | 0);
			}
		}
		public function baseRegisterWrite(address, data, userMode) {
			//Update writeback for offset+base modes:
			address = address | 0;
			data = data | 0;
			if (!userMode || (address | 0) == 0xF) {
				this.guardRegisterWrite(address | 0, data | 0);
			}
			else {
				this.guardUserRegisterWrite(address | 0, data | 0);
			}
		}
		public function readRegister(address) {
			//Unguarded register read:
			address = address | 0;
			return this.registers[address & 0xF] | 0;
		}
		public function readUserRegister(address) {
			//Unguarded user mode register read:
			address = address | 0;
			return this.registersUSR[address & 0x7] | 0;
		}
		public function readDelayedPCRegister() {
			//Get the PC register data clocked 4 exta:
			var register = this.registers[0xF] | 0;
			register = (register + 4) | 0;
			return register | 0;
		}
		public function guardRegisterRead(address) {
			//Guarded register read:
			address = address | 0;
			if ((address | 0) < 0xF) {
				return this.readRegister(address | 0) | 0;
			}
			//Get Special Case PC Read:
			return this.readDelayedPCRegister() | 0;
		}
		public function guardUserRegisterRead(address) {
			//Guard only on user access, not PC!:
			address = address | 0;
			switch (this.CPUCore.MODEBits | 0) {
				case 0x10:
				case 0x1F:
					return this.readRegister(address | 0) | 0;
				case 0x11:
					if ((address | 0) < 8) {
						return this.readRegister(address | 0) | 0;
					}
					else {
						//User-Mode Register Read Inside Non-User-Mode:
						return this.readUserRegister(address | 0) | 0;
					}
					break;
				default:
					if ((address | 0) < 13) {
						return this.readRegister(address | 0) | 0;
					}
					else {
						//User-Mode Register Read Inside Non-User-Mode:
						return this.readUserRegister(address | 0) | 0;
					}
			}
		}
		public function guardRegisterReadSTM(parentObj, address) {
			//Proxy guarded register read (used by STM*):
			address = address | 0;
			return parentObj.guardRegisterRead(address | 0) | 0;
		}
		public function guardUserRegisterReadSTM(parentObj, address) {
			//Proxy guarded user mode read (used by STM*):
			address = address | 0;
			if ((address | 0) < 0xF) {
				return parentObj.guardUserRegisterRead(address | 0) | 0;
			}
			else {
				//Get Special Case PC Read:
				return parentObj.readDelayedPCRegister() | 0;
			}
		}
		public function baseRegisterRead(address, userMode) {
			//Read specially for offset+base modes:
			address = address | 0;
			if (!userMode || (address | 0) == 0xF) {
				return this.readRegister(address | 0) | 0;
			}
			else {
				return this.guardUserRegisterRead(address | 0) | 0;
			}
		}
		public function updateBasePostDecrement(operand, offset, userMode) {
			operand = operand | 0;
			offset = offset | 0;
			var baseRegisterNumber = (operand >> 16) & 0xF;
			var base = this.baseRegisterRead(baseRegisterNumber | 0, userMode) | 0;
			var result = ((base | 0) - (offset | 0)) | 0;
			this.baseRegisterWrite(baseRegisterNumber | 0, result | 0, userMode);
			return base | 0;
		}
		public function updateBasePostIncrement(operand, offset, userMode) {
			operand = operand | 0;
			offset = offset | 0;
			var baseRegisterNumber = (operand >> 16) & 0xF;
			var base = this.baseRegisterRead(baseRegisterNumber | 0, userMode) | 0;
			var result = ((base | 0) + (offset | 0)) | 0;
			this.baseRegisterWrite(baseRegisterNumber | 0, result | 0, userMode);
			return base | 0;
		}
		public function updateNoBaseDecrement(operand, offset) {
			operand = operand | 0;
			offset = offset | 0;
			var baseRegisterNumber = (operand >> 16) & 0xF;
			var base = this.registers[baseRegisterNumber | 0] | 0;
			var result = ((base | 0) - (offset | 0)) | 0;
			return result | 0;
		}
		public function updateNoBaseIncrement(operand, offset) {
			operand = operand | 0;
			offset = offset | 0;
			var baseRegisterNumber = (operand >> 16) & 0xF;
			var base = this.registers[baseRegisterNumber | 0] | 0;
			var result = ((base | 0) + (offset | 0)) | 0;
			return result | 0;
		}
		public function updateBasePreDecrement(operand, offset) {
			operand = operand | 0;
			offset = offset | 0;
			var baseRegisterNumber = (operand >> 16) & 0xF;
			var base = this.registers[baseRegisterNumber | 0] | 0;
			var result = ((base | 0) - (offset | 0)) | 0;
			this.guardRegisterWrite(baseRegisterNumber | 0, result | 0);
			return result | 0;
		}
		public function updateBasePreIncrement(operand, offset) {
			operand = operand | 0;
			offset = offset | 0;
			var baseRegisterNumber = (operand >> 16) & 0xF;
			var base = this.registers[baseRegisterNumber | 0] | 0;
			var result = ((base | 0) + (offset | 0)) | 0;
			this.guardRegisterWrite(baseRegisterNumber | 0, result | 0);
			return result | 0;
		}
		public function BX(parentObj, operand2OP) {
			//Branch & eXchange:
			Logger.logARM("execute BX");
			var address = parentObj.registers[parentObj.execute & 0xF] | 0;
			if ((address & 0x1) == 0) {
				//Stay in ARM mode:
				parentObj.CPUCore.branch(address & -4);
			}
			else {
				//Enter THUMB mode:
				parentObj.CPUCore.enterTHUMB();
				parentObj.CPUCore.branch(address & -2);
			}
		}
		
		public function B(parentObj, operand2OP = null) {
			//Branch:
			Logger.logARM("execute B");
			parentObj.CPUCore.branch(((parentObj.readRegister(0xF) | 0) + ((parentObj.execute << 8) >> 6)) | 0);
		}
		public function BL(parentObj, operand2OP) {
			//Branch with Link:
			Logger.logARM("execute BL");
			parentObj.writeRegister(0xE, parentObj.getLR() | 0);
			parentObj.B(parentObj);
		}
		public function AND(parentObj, operand2OP) {
			Logger.logARM("execute AND");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform bitwise AND:
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, operand1 & operand2);
		}
		public function ANDS(parentObj, operand2OP) {
			Logger.logARM("execute ANDS");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform bitwise AND:
			var result = operand1 & operand2;
			parentObj.CPUCore.CPSRNegative = (result < 0);
			parentObj.CPUCore.CPSRZero = (result == 0);
			//Update destination register and guard CPSR for PC:
			parentObj.guardRegisterWriteCPSR((parentObj.execute >> 12) & 0xF, result | 0);
		}
		public function EOR(parentObj, operand2OP) {
			Logger.logARM("execute EOR");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform bitwise EOR:
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, operand1 ^ operand2);
		}
		public function EORS(parentObj, operand2OP) {
			Logger.logARM("execute EORS");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform bitwise EOR:
			var result = operand1 ^ operand2;
			parentObj.CPUCore.CPSRNegative = (result < 0);
			parentObj.CPUCore.CPSRZero = (result == 0);
			//Update destination register and guard CPSR for PC:
			parentObj.guardRegisterWriteCPSR((parentObj.execute >> 12) & 0xF, result | 0);
		}
		public function SUB(parentObj, operand2OP) {
			Logger.logARM("execute SUB");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform Subtraction:
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, ((operand1 | 0) - (operand2 | 0)) | 0);
		}
		public function SUBS(parentObj, operand2OP) {
			Logger.logARM("execute SUBS");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Update destination register:
			parentObj.guardRegisterWriteCPSR((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.setSUBFlags(operand1 | 0, operand2 | 0) | 0);
		}
		public function RSB(parentObj, operand2OP) {
			Logger.logARM("execute RSB");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform Subtraction:
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, ((operand2 | 0) - (operand1 | 0)) | 0);
		}
		public function RSBS(parentObj, operand2OP) {
			Logger.logARM("execute RSBS");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Update destination register:
			parentObj.guardRegisterWriteCPSR((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.setSUBFlags(operand2 | 0, operand1 | 0) | 0);
		}
		public function ADD(parentObj, operand2OP) {
			Logger.logARM("execute ADD");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform Addition:
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, ((operand1 | 0) + (operand2 | 0)) | 0);
		}
		public function ADDS(parentObj, operand2OP) {
			Logger.logARM("execute ADDS");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute) | 0;
			//Update destination register:
			parentObj.guardRegisterWriteCPSR((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.setADDFlags(operand1 | 0, operand2 | 0) | 0);
		}
		public function ADC(parentObj, operand2OP) {
			Logger.logARM("execute ADC");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform Addition w/ Carry:
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, ((operand1 | 0) + (operand2 | 0) + ((parentObj.CPUCore.CPSRCarry) ? 1 : 0)) | 0);
		}
		public function ADCS(parentObj, operand2OP) {
			Logger.logARM("execute ADCS");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Update destination register:
			parentObj.guardRegisterWriteCPSR((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.setADCFlags(operand1 | 0, operand2 | 0) | 0);
		}
		public function SBC(parentObj, operand2OP) {
			Logger.logARM("execute SBC");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform Subtraction w/ Carry:
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, ((operand1 | 0) - (operand2 | 0) - ((parentObj.CPUCore.CPSRCarry) ? 0 : 1)) | 0);
		}
		public function SBCS(parentObj, operand2OP) {
			Logger.logARM("execute SBCS");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Update destination register:
			parentObj.guardRegisterWriteCPSR((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.setSBCFlags(operand1 | 0, operand2 | 0) | 0);
		}
		public function RSC(parentObj, operand2OP) {
			Logger.logARM("execute RSC");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform Reverse Subtraction w/ Carry:
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, ((operand2 | 0) - (operand1 | 0) - ((parentObj.CPUCore.CPSRCarry) ? 0 : 1)) | 0);
		}
		public function RSCS(parentObj, operand2OP) {
			Logger.logARM("execute RSCS");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Update destination register:
			parentObj.guardRegisterWriteCPSR((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.setSBCFlags(operand2 | 0, operand1 | 0) | 0);
		}
		public function TSTS(parentObj, operand2OP) {
			Logger.logARM("execute TSTS");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform bitwise AND:
			var result = operand1 & operand2;
			parentObj.CPUCore.CPSRNegative = (result < 0);
			parentObj.CPUCore.CPSRZero = (result == 0);
		}
		public function TEQS(parentObj, operand2OP) {
			Logger.logARM("execute TEQS");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform bitwise EOR:
			var result = operand1 ^ operand2;
			parentObj.CPUCore.CPSRNegative = (result < 0);
			parentObj.CPUCore.CPSRZero = (result == 0);
		}
		public function CMPS(parentObj, operand2OP) {
			Logger.logARM("execute CMPS");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			parentObj.CPUCore.setCMPFlags(operand1 | 0, operand2 | 0);
		}
		public function CMNS(parentObj, operand2OP) {
			Logger.logARM("execute CMNS");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0);
			parentObj.CPUCore.setCMNFlags(operand1 | 0, operand2 | 0);
		}
		public function ORR(parentObj, operand2OP) {
			Logger.logARM("execute ORR");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform bitwise OR:
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, operand1 | operand2);
		}
		public function ORRS(parentObj, operand2OP) {
			Logger.logARM("execute ORRS");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform bitwise OR:
			var result = operand1 | operand2;
			parentObj.CPUCore.CPSRNegative = (result < 0);
			parentObj.CPUCore.CPSRZero = (result == 0);
			//Update destination register and guard CPSR for PC:
			parentObj.guardRegisterWriteCPSR((parentObj.execute >> 12) & 0xF, result | 0);
		}
		public function MOV(parentObj, operand2OP) {
			Logger.logARM("execute MOV");
			//Perform move:
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, operand2OP(parentObj, parentObj.execute | 0) | 0);
		}
		public function MOVS(parentObj, operand2OP) {
			Logger.logARM("execute MOVS");
			var operand2 = operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform move:
			parentObj.CPUCore.CPSRNegative = (operand2 < 0);
			parentObj.CPUCore.CPSRZero = (operand2 == 0);
			//Update destination register and guard CPSR for PC:
			parentObj.guardRegisterWriteCPSR((parentObj.execute >> 12) & 0xF, operand2 | 0);
		}
		public function BIC(parentObj, operand2OP) {
			Logger.logARM("execute BIC");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			//NOT operand 2:
			var operand2 = ~operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform bitwise AND:
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, operand1 & operand2);
		}
		public function BICS(parentObj, operand2OP) {
			Logger.logARM("execute BICS");
			var operand1 = parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0;
			//NOT operand 2:
			var operand2 = ~operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform bitwise AND:
			var result = operand1 & operand2;
			parentObj.CPUCore.CPSRNegative = (result < 0);
			parentObj.CPUCore.CPSRZero = (result == 0);
			//Update destination register and guard CPSR for PC:
			parentObj.guardRegisterWriteCPSR((parentObj.execute >> 12) & 0xF, result | 0);
		}
		public function MVN(parentObj, operand2OP) {
			Logger.logARM("execute MVN");
			//Perform move negative:
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, ~operand2OP(parentObj, parentObj.execute | 0));
		}
		public function MVNS(parentObj, operand2OP) {
			Logger.logARM("execute MVNS");
			var operand2 = ~operand2OP(parentObj, parentObj.execute | 0) | 0;
			//Perform move negative:
			parentObj.CPUCore.CPSRNegative = (operand2 < 0);
			parentObj.CPUCore.CPSRZero = (operand2 == 0);
			//Update destination register and guard CPSR for PC:
			parentObj.guardRegisterWriteCPSR((parentObj.execute >> 12) & 0xF, operand2 | 0);
		}
		public function MRS(parentObj, operand2OP) {
			Logger.logARM("execute MRS");
			//Transfer PSR to Register
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, operand2OP(parentObj) | 0);
		}
		public function MSR(parentObj, operand2OP) {
			Logger.logARM("execute MSR");
			//Transfer Register/Immediate to PSR:
			operand2OP(parentObj, parentObj.execute | 0);
		}
		public function MUL(parentObj, operand2OP) {
			Logger.logARM("execute MUL");
			//Perform multiplication:
			var result = parentObj.CPUCore.performMUL32(parentObj.registers[parentObj.execute & 0xF] | 0, parentObj.registers[(parentObj.execute >> 8) & 0xF] | 0, 0) | 0;
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, result | 0);
		}
		public function MULS(parentObj, operand2OP) {
			Logger.logARM("execute MULS");
			//Perform multiplication:
			var result = parentObj.CPUCore.performMUL32(parentObj.registers[parentObj.execute & 0xF] | 0, parentObj.registers[(parentObj.execute >> 8) & 0xF] | 0, 0) | 0;
			parentObj.CPUCore.CPSRCarry = false;
			parentObj.CPUCore.CPSRNegative = (result < 0);
			parentObj.CPUCore.CPSRZero = (result == 0);
			//Update destination register and guard CPSR for PC:
			parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, result | 0);
		}
		public function MLA(parentObj, operand2OP) {
			Logger.logARM("execute MLA");
			//Perform multiplication:
			var result = parentObj.CPUCore.performMUL32(parentObj.registers[parentObj.execute & 0xF] | 0, parentObj.registers[(parentObj.execute >> 8) & 0xF] | 0, 1) | 0;
			//Perform addition:
			result = ((result | 0) + (parentObj.registers[(parentObj.execute >> 12) & 0xF] | 0));
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, result | 0);
		}
		public function MLAS(parentObj, operand2OP) {
			Logger.logARM("execute MLAS");
			//Perform multiplication:
			var result = parentObj.CPUCore.performMUL32(parentObj.registers[parentObj.execute & 0xF] | 0, parentObj.registers[(parentObj.execute >> 8) & 0xF] | 0, 1) | 0;
			//Perform addition:
			result = ((result | 0) + (parentObj.registers[(parentObj.execute >> 12) & 0xF] | 0)) | 0;
			parentObj.CPUCore.CPSRCarry = false;
			parentObj.CPUCore.CPSRNegative = (result < 0);
			parentObj.CPUCore.CPSRZero = (result == 0);
			//Update destination register and guard CPSR for PC:
			parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, result | 0);
		}
		public function UMULL(parentObj, operand2OP) {
			Logger.logARM("execute UMULL");
			//Perform multiplication:
			parentObj.CPUCore.performUMUL64(parentObj.registers[parentObj.execute & 0xF] | 0, parentObj.registers[(parentObj.execute >> 8) & 0xF] | 0);
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, parentObj.CPUCore.mul64ResultHigh | 0);
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.mul64ResultLow | 0);
		}
		public function UMULLS(parentObj, operand2OP) {
			Logger.logARM("execute UMULLS");
			//Perform multiplication:
			parentObj.CPUCore.performUMUL64(parentObj.registers[parentObj.execute & 0xF] | 0, parentObj.registers[(parentObj.execute >> 8) & 0xF] | 0);
			parentObj.CPUCore.CPSRCarry = false;
			parentObj.CPUCore.CPSRNegative = ((parentObj.CPUCore.mul64ResultHigh | 0) < 0);
			parentObj.CPUCore.CPSRZero = ((parentObj.CPUCore.mul64ResultHigh | 0) == 0 && (parentObj.CPUCore.mul64ResultLow | 0) == 0);
			//Update destination register and guard CPSR for PC:
			parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, parentObj.CPUCore.mul64ResultHigh | 0);
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.mul64ResultLow | 0);
		}
		public function UMLAL(parentObj, operand2OP) {
			Logger.logARM("execute UMLAL");
			//Perform multiplication:
			parentObj.CPUCore.performUMLA64(parentObj.registers[parentObj.execute & 0xF] | 0, parentObj.registers[(parentObj.execute >> 8) & 0xF] | 0, parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0, parentObj.registers[(parentObj.execute >> 12) & 0xF] | 0);
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, parentObj.CPUCore.mul64ResultHigh | 0);
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.mul64ResultLow | 0);
		}
		public function UMLALS(parentObj, operand2OP) {
			Logger.logARM("execute UMLALS");
			//Perform multiplication:
			parentObj.CPUCore.performUMLA64(parentObj.registers[parentObj.execute & 0xF] | 0, parentObj.registers[(parentObj.execute >> 8) & 0xF] | 0, parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0, parentObj.registers[(parentObj.execute >> 12) & 0xF] | 0);
			parentObj.CPUCore.CPSRCarry = false;
			parentObj.CPUCore.CPSRNegative = ((parentObj.CPUCore.mul64ResultHigh | 0) < 0);
			parentObj.CPUCore.CPSRZero = ((parentObj.CPUCore.mul64ResultHigh | 0) == 0 && (parentObj.CPUCore.mul64ResultLow | 0) == 0);
			//Update destination register and guard CPSR for PC:
			parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, parentObj.CPUCore.mul64ResultHigh | 0);
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.mul64ResultLow | 0);
		}
		public function SMULL(parentObj, operand2OP) {
			Logger.logARM("execute SMULL");
			//Perform multiplication:
			parentObj.CPUCore.performMUL64(parentObj.registers[parentObj.execute & 0xF] | 0, parentObj.registers[(parentObj.execute >> 8) & 0xF] | 0);
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, parentObj.CPUCore.mul64ResultHigh | 0);
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.mul64ResultLow | 0);
		}
		public function SMULLS(parentObj, operand2OP) {
			Logger.logARM("execute SMULLS");
			//Perform multiplication:
			parentObj.CPUCore.performMUL64(parentObj.registers[parentObj.execute & 0xF] | 0, parentObj.registers[(parentObj.execute >> 8) & 0xF] | 0);
			parentObj.CPUCore.CPSRCarry = false;
			parentObj.CPUCore.CPSRNegative = ((parentObj.CPUCore.mul64ResultHigh | 0) < 0);
			parentObj.CPUCore.CPSRZero = ((parentObj.CPUCore.mul64ResultHigh | 0) == 0 && (parentObj.CPUCore.mul64ResultLow | 0) == 0);
			//Update destination register and guard CPSR for PC:
			parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, parentObj.CPUCore.mul64ResultHigh | 0);
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.mul64ResultLow | 0);
		}
		public function SMLAL(parentObj, operand2OP) {
			Logger.logARM("execute SMLAL");
			//Perform multiplication:
			parentObj.CPUCore.performMLA64(parentObj.registers[parentObj.execute & 0xF] | 0, parentObj.registers[(parentObj.execute >> 8) & 0xF] | 0, parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0, parentObj.registers[(parentObj.execute >> 12) & 0xF] | 0);
			//Update destination register:
			parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, parentObj.CPUCore.mul64ResultHigh | 0);
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.mul64ResultLow | 0);
		}
		public function SMLALS(parentObj, operand2OP) {
			Logger.logARM("execute SMLALS");
			//Perform multiplication:
			parentObj.CPUCore.performMLA64(parentObj.registers[parentObj.execute & 0xF] | 0, parentObj.registers[(parentObj.execute >> 8) & 0xF] | 0, parentObj.registers[(parentObj.execute >> 16) & 0xF] | 0, parentObj.registers[(parentObj.execute >> 12) & 0xF] | 0);
			parentObj.CPUCore.CPSRCarry = false;
			parentObj.CPUCore.CPSRNegative = ((parentObj.CPUCore.mul64ResultHigh | 0) < 0);
			parentObj.CPUCore.CPSRZero = ((parentObj.CPUCore.mul64ResultHigh | 0) == 0 && (parentObj.CPUCore.mul64ResultLow | 0) == 0);
			//Update destination register and guard CPSR for PC:
			parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, parentObj.CPUCore.mul64ResultHigh | 0);
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.mul64ResultLow | 0);
		}
		public function STRH(parentObj, operand2OP = null) {
			Logger.logARM("execute STRH");
			//Perform halfword store calculations:
			var address = operand2OP(parentObj, parentObj.execute | 0, false) | 0;
			//Write to memory location:
			parentObj.CPUCore.write16(address | 0, parentObj.guardRegisterRead((parentObj.execute >> 12) & 0xF) | 0);
		}
		public function LDRH(parentObj, operand2OP) {
			Logger.logARM("execute LDRH");
			//Perform halfword load calculations:
			var address = operand2OP(parentObj, parentObj.execute | 0, false) | 0;
			//Read from memory location:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.read16(address | 0) | 0);
		}
		public function LDRSH(parentObj, operand2OP) {
			Logger.logARM("execute LDRSH");
			//Perform signed halfword load calculations:
			var address = operand2OP(parentObj, parentObj.execute | 0, false) | 0;
			//Read from memory location:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, (parentObj.CPUCore.read16(address | 0) << 16) >> 16);
		}
		public function LDRSB(parentObj, operand2OP) {
			Logger.logARM("execute LDRSB");
			//Perform signed byte load calculations:
			var address = operand2OP(parentObj, parentObj.execute | 0, false) | 0;
			//Read from memory location:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, (parentObj.CPUCore.read8(address | 0) << 24) >> 24);
		}
		public function STR(parentObj, operand2OP) {
			Logger.logARM("execute STR");
			//Perform word store calculations:
			var address = operand2OP(parentObj, parentObj.execute | 0, false) | 0;
			//Write to memory location:
			parentObj.CPUCore.write32(address | 0, parentObj.guardRegisterRead((parentObj.execute >> 12) & 0xF) | 0);
		}
		public function LDR(parentObj, operand2OP) {
			Logger.logARM("execute LDR");
			//Perform word load calculations:
			var address = operand2OP(parentObj, parentObj.execute | 0, false) | 0;
			//Read from memory location:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.read32(address | 0) | 0);
		}
		public function STRB(parentObj, operand2OP) {
			Logger.logARM("execute STRB");
			//Perform byte store calculations:
			var address = operand2OP(parentObj, parentObj.execute | 0, false) | 0;
			//Write to memory location:
			parentObj.CPUCore.write8(address | 0, parentObj.guardRegisterRead((parentObj.execute >> 12) & 0xF) | 0);
		}
		public function LDRB(parentObj, operand2OP) {
			Logger.logARM("execute LDRB");
			//Perform byte store calculations:
			var address = operand2OP(parentObj, parentObj.execute | 0, false) | 0;
			//Read from memory location:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.read8(address | 0) | 0);
		}
		public function STRHT(parentObj, operand2OP) {
			Logger.logARM("execute STRHT");
			//Perform halfword store calculations (forced user-mode):
			var address = operand2OP(parentObj, parentObj.execute | 0, true) | 0;
			//Write to memory location:
			parentObj.CPUCore.write16(address | 0, parentObj.guardRegisterRead((parentObj.execute >> 12) & 0xF) | 0);
		}
		public function LDRHT(parentObj, operand2OP) {
			Logger.logARM("execute LDRHT");
			//Perform halfword load calculations (forced user-mode):
			var address = operand2OP(parentObj, parentObj.execute | 0, true) | 0;
			//Read from memory location:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.read16(address | 0) | 0);
		}
		public function LDRSHT(parentObj, operand2OP) {
			Logger.logARM("execute LDRSHT");
			//Perform signed halfword load calculations (forced user-mode):
			var address = operand2OP(parentObj, parentObj.execute | 0, true) | 0;
			//Read from memory location:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, (parentObj.CPUCore.read16(address | 0) << 16) >> 16);
		}
		public function LDRSBT(parentObj, operand2OP) {
			Logger.logARM("execute LDRSBT");
			//Perform signed byte load calculations (forced user-mode):
			var address = operand2OP(parentObj, parentObj.execute | 0, true) | 0;
			//Read from memory location:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, (parentObj.CPUCore.read8(address | 0) << 24) >> 24);
		}
		public function STRT(parentObj, operand2OP) {
			Logger.logARM("execute STRT");
			//Perform word store calculations (forced user-mode):
			var address = operand2OP(parentObj, parentObj.execute | 0, true) | 0;
			//Write to memory location:
			parentObj.CPUCore.write32(address | 0, parentObj.guardRegisterRead((parentObj.execute >> 12) & 0xF) | 0);
		}
		public function LDRT(parentObj, operand2OP) {
			Logger.logARM("execute LDRT");
			//Perform word load calculations (forced user-mode):
			var address = operand2OP(parentObj, parentObj.execute | 0, true) | 0;
			//Read from memory location:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.read32(address | 0) | 0);
		}
		public function STRBT(parentObj, operand2OP) {
			Logger.logARM("execute STRBT");
			//Perform byte store calculations (forced user-mode):
			var address = operand2OP(parentObj, parentObj.execute | 0, true) | 0;
			//Write to memory location:
			parentObj.CPUCore.write8(address | 0, parentObj.guardRegisterRead((parentObj.execute >> 12) & 0xF) | 0);
		}
		public function LDRBT(parentObj, operand2OP) {
			Logger.logARM("execute LDRBT");
			//Perform byte load calculations (forced user-mode):
			var address = operand2OP(parentObj, parentObj.execute | 0, true) | 0;
			//Read from memory location:
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, parentObj.CPUCore.read8(address | 0) | 0);
		}
		public function STMIA(parentObj, operand2OP) {
			Logger.logARM("execute STMIA");
			//Only initialize the STMIA sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Push register(s) into memory:
				for (var rListPosition = 0; rListPosition < 0x10; rListPosition = (rListPosition + 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Push a register into memory:
						parentObj.stackMemoryCache.memoryWrite32(currentAddress >>> 0, operand2OP(parentObj, rListPosition | 0) | 0);
						currentAddress = (currentAddress + 4) | 0;
					}
				}
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function STMIAW(parentObj, operand2OP) {
			Logger.logARM("execute STMIAW");
			//Only initialize the STMIA sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Push register(s) into memory:
				for (var rListPosition = 0; rListPosition < 0x10; rListPosition = (rListPosition + 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Push a register into memory:
						parentObj.stackMemoryCache.memoryWrite32(currentAddress >>> 0, operand2OP(parentObj, rListPosition | 0) | 0);
						currentAddress = (currentAddress + 4) | 0;
					}
				}
				//Store the updated base address back into register:
				parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, currentAddress | 0);
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function STMDA(parentObj, operand2OP) {
			Logger.logARM("execute STMDA");
			//Only initialize the STMDA sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Push register(s) into memory:
				for (var rListPosition = 0xF; rListPosition > -1; rListPosition = (rListPosition - 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Push a register into memory:
						parentObj.stackMemoryCache.memoryWrite32(currentAddress >>> 0, operand2OP(parentObj, rListPosition | 0) | 0);
						currentAddress = (currentAddress - 4) | 0;
					}
				}
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function STMDAW(parentObj, operand2OP) {
			Logger.logARM("execute STMDAW");
			//Only initialize the STMDA sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Push register(s) into memory:
				for (var rListPosition = 0xF; rListPosition > -1; rListPosition = (rListPosition - 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Push a register into memory:
						parentObj.stackMemoryCache.memoryWrite32(currentAddress >>> 0, operand2OP(parentObj, rListPosition | 0) | 0);
						currentAddress = (currentAddress - 4) | 0;
					}
				}
				//Store the updated base address back into register:
				parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, currentAddress | 0);
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function STMIB(parentObj, operand2OP) {
			Logger.logARM("execute STMIB");
			//Only initialize the STMIB sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Push register(s) into memory:
				for (var rListPosition = 0; rListPosition < 0x10;  rListPosition = (rListPosition + 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Push a register into memory:
						currentAddress = (currentAddress + 4) | 0;
						parentObj.stackMemoryCache.memoryWrite32(currentAddress >>> 0, operand2OP(parentObj, rListPosition | 0) | 0);
					}
				}
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function STMIBW(parentObj, operand2OP) {
			Logger.logARM("execute STMIBW");
			//Only initialize the STMIB sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Push register(s) into memory:
				for (var rListPosition = 0; rListPosition < 0x10;  rListPosition = (rListPosition + 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Push a register into memory:
						currentAddress = (currentAddress + 4) | 0;
						parentObj.stackMemoryCache.memoryWrite32(currentAddress >>> 0, operand2OP(parentObj, rListPosition | 0) | 0);
					}
				}
				//Store the updated base address back into register:
				parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, currentAddress | 0);
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function STMDB(parentObj, operand2OP) {
			Logger.logARM("execute STMDB");
			//Only initialize the STMDB sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Push register(s) into memory:
				for (var rListPosition = 0xF; rListPosition > -1; rListPosition = (rListPosition - 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Push a register into memory:
						currentAddress = (currentAddress - 4) | 0;
						parentObj.stackMemoryCache.memoryWrite32(currentAddress >>> 0, operand2OP(parentObj, rListPosition | 0) | 0);
					}
				}
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function STMDBW(parentObj, operand2OP) {
			Logger.logARM("execute STMDBW");
			//Only initialize the STMDB sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Push register(s) into memory:
				for (var rListPosition = 0xF; rListPosition > -1; rListPosition = (rListPosition - 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Push a register into memory:
						currentAddress = (currentAddress - 4) | 0;
						parentObj.stackMemoryCache.memoryWrite32(currentAddress >>> 0, operand2OP(parentObj, rListPosition >>> 0) | 0);
					}
				}
				//Store the updated base address back into register:
				parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, currentAddress | 0);
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function LDMIA(parentObj, operand2OP) {
			Logger.logARM("execute LDMIA");
			//Only initialize the LDMIA sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Load register(s) from memory:
				for (var rListPosition = 0; rListPosition < 0x10;  rListPosition = (rListPosition + 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Load a register from memory:
						operand2OP(parentObj, rListPosition | 0, parentObj.stackMemoryCache.memoryRead32(currentAddress >>> 0) | 0);
						currentAddress = (currentAddress + 4) | 0;
					}
				}
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function LDMIAW(parentObj, operand2OP) {
			Logger.logARM("execute LDMIAW");
			//Only initialize the LDMIA sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
		
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Load register(s) from memory:
				for (var rListPosition = 0; rListPosition < 0x10;  rListPosition = (rListPosition + 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Load a register from memory:
						operand2OP(parentObj, rListPosition | 0, parentObj.stackMemoryCache.memoryRead32(currentAddress >>> 0) | 0);
						currentAddress = (currentAddress + 4) | 0;
					}
				}
				//Store the updated base address back into register:
				parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, currentAddress | 0);
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function LDMDA(parentObj, operand2OP) {
			Logger.logARM("execute LDMDA");
			//Only initialize the LDMDA sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Load register(s) from memory:
				for (var rListPosition = 0xF; rListPosition > -1; rListPosition = (rListPosition - 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Load a register from memory:
						operand2OP(parentObj, rListPosition | 0, parentObj.stackMemoryCache.memoryRead32(currentAddress >>> 0) | 0);
						currentAddress = (currentAddress - 4) | 0;
					}
				}
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function LDMDAW(parentObj, operand2OP) {
			Logger.logARM("execute LDMDAW");
			//Only initialize the LDMDA sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Load register(s) from memory:
				for (var rListPosition = 0xF; rListPosition > -1; rListPosition = (rListPosition - 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Load a register from memory:
						operand2OP(parentObj, rListPosition | 0, parentObj.stackMemoryCache.memoryRead32(currentAddress >>> 0) | 0);
						currentAddress = (currentAddress - 4) | 0;
					}
				}
				//Store the updated base address back into register:
				parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, currentAddress | 0);
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function LDMIB(parentObj, operand2OP) {
			Logger.logARM("execute LDMIB");
			//Only initialize the LDMIB sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Load register(s) from memory:
				for (var rListPosition = 0; rListPosition < 0x10;  rListPosition = (rListPosition + 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Load a register from memory:
						currentAddress = (currentAddress + 4) | 0;
						operand2OP(parentObj, rListPosition | 0, parentObj.stackMemoryCache.memoryRead32(currentAddress >>> 0) | 0);
					}
				}
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function LDMIBW(parentObj, operand2OP) {
			Logger.logARM("execute LDMIBW");
			//Only initialize the LDMIB sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Load register(s) from memory:
				for (var rListPosition = 0; rListPosition < 0x10;  rListPosition = (rListPosition + 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Load a register from memory:
						currentAddress = (currentAddress + 4) | 0;
						operand2OP(parentObj, rListPosition | 0, parentObj.stackMemoryCache.memoryRead32(currentAddress >>> 0) | 0);
					}
				}
				//Store the updated base address back into register:
				parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, currentAddress | 0);
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function LDMDB(parentObj, operand2OP) {
			Logger.logARM("execute LDMDB");
			//Only initialize the LDMDB sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Load register(s) from memory:
				for (var rListPosition = 0xF; rListPosition > -1; rListPosition = (rListPosition - 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Load a register from memory:
						currentAddress = (currentAddress - 4) | 0;
						operand2OP(parentObj, rListPosition | 0, parentObj.stackMemoryCache.memoryRead32(currentAddress >>> 0) | 0);
					}
				}
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function LDMDBW(parentObj, operand2OP) {
			Logger.logARM("execute LDMDBW");
			//Only initialize the LDMDB sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFFFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Load register(s) from memory:
				for (var rListPosition = 0xF; rListPosition > -1; rListPosition = (rListPosition - 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Load a register from memory:
						currentAddress = (currentAddress - 4) | 0;
						operand2OP(parentObj, rListPosition | 0, parentObj.stackMemoryCache.memoryRead32(currentAddress >>> 0) | 0);
					}
				}
				//Store the updated base address back into register:
				parentObj.guardRegisterWrite((parentObj.execute >> 16) & 0xF, currentAddress | 0);
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function SWP(parentObj, operand2OP) {
			Logger.logARM("execute SWP");
			var base = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
			var data = parentObj.CPUCore.read32(base | 0) | 0;
			//Clock a cycle for the processing delaying the CPU:
			parentObj.wait.CPUInternalCyclePrefetch(parentObj.fetch | 0, 1);
			parentObj.CPUCore.write32(base, parentObj.readRegister(parentObj.execute & 0xF) | 0);
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, data | 0);
		}
		public function SWPB(parentObj, operand2OP) {
			var base = parentObj.readRegister((parentObj.execute >> 16) & 0xF) | 0;
			var data = parentObj.CPUCore.read8(base | 0) | 0;
			//Clock a cycle for the processing delaying the CPU:
			parentObj.wait.CPUInternalCyclePrefetch(parentObj.fetch | 0, 1);
			parentObj.CPUCore.write8(base, parentObj.readRegister(parentObj.execute & 0xF) | 0);
			parentObj.guardRegisterWrite((parentObj.execute >> 12) & 0xF, data | 0);
		}
		public function SWI(parentObj, operand2OP) {
			Logger.logARM("execute SWI");
			//Software Interrupt:
			parentObj.CPUCore.SWI();
		}
		public function CDP(parentObj, operand2OP) {
			Logger.logARM("execute CDP");
			//No co-processor on GBA, but we really should do the bail properly:
			parentObj.CPUCore.UNDEFINED();
		}
		public function LDC(parentObj, operand2OP) {
			Logger.logARM("execute LDC");
			//No co-processor on GBA, but we really should do the bail properly:
			parentObj.CPUCore.UNDEFINED();
		}
		public function STC(parentObj, operand2OP) {
			Logger.logARM("execute STC");
			//No co-processor on GBA, but we really should do the bail properly:
			parentObj.CPUCore.UNDEFINED();
		}
		public function MRC(parentObj, operand2OP) {
			Logger.logARM("execute MRC");
			//No co-processor on GBA, but we really should do the bail properly:
			parentObj.CPUCore.UNDEFINED();
		}
		public function MCR(parentObj, operand2OP) {
			Logger.logARM("execute MCR");
			//No co-processor on GBA, but we really should do the bail properly:
			parentObj.CPUCore.UNDEFINED();
		}
		public function UNDEFINED(parentObj, operand2OP) {
			Logger.logARM("execute UNDEFINED");
			//Undefined Exception:
			parentObj.CPUCore.UNDEFINED();
		}
		public function lli(parentObj, operand) {
			operand = operand | 0;
			return parentObj.lli2(operand | 0) | 0;
		}
		public function lli2(operand) {
			operand = operand | 0;
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = this.readRegister(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			this.wait.CPUInternalCyclePrefetch(this.fetch | 0, 1);
			//Shift the register data left:
			var shifter = (operand >> 7) & 0x1F;
			return register << shifter;
		}
		public function llis(parentObj, operand) {
			operand = operand | 0;
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = parentObj.readRegister(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			parentObj.wait.CPUInternalCyclePrefetch(parentObj.fetch | 0, 1);
			//Get the shift amount:
			var shifter = (operand >> 7) & 0x1F;
			//Check to see if we need to update CPSR:
			if (shifter > 0) {
				parentObj.CPUCore.CPSRCarry = ((register << (shifter - 1)) < 0); 
			}
			//Shift the register data left:
			return register << shifter;
		}
		public function llr(parentObj, operand) {
			operand = operand | 0;
			//Logical Left Shift with Register:
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = parentObj.guardRegisterRead(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			parentObj.wait.CPUInternalCyclePrefetch(parentObj.fetch | 0, 1);
			//Shift the register data left:
			var shifter = parentObj.guardRegisterRead((operand >> 8) & 0xF) & 0xFF;
			return (shifter < 0x20) ? (register << shifter) : 0;
		}
		public function llrs(parentObj, operand) {
			operand = operand | 0;
			//Logical Left Shift with Register and CPSR:
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = parentObj.guardRegisterRead(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			parentObj.wait.CPUInternalCyclePrefetch(parentObj.fetch | 0, 1);
			//Get the shift amount:
			var shifter = parentObj.guardRegisterRead((operand >> 8) & 0xF) & 0xFF;
			//Check to see if we need to update CPSR:
			if (shifter > 0) {
				if (shifter < 32) {
					//Shift the register data left:
					parentObj.CPUCore.CPSRCarry = ((register << (shifter - 1)) < 0);
					return register << shifter;
				}
				else if (shifter == 32) {
					//Shift bit 0 into carry:
					parentObj.CPUCore.CPSRCarry = ((register & 0x1) == 0x1);
				}
				else {
					//Everything Zero'd:
					parentObj.CPUCore.CPSRCarry = false;
				}
				return 0;
			}
			//If shift is 0, just return the register without mod:
			return register | 0;
		}
		public function lri(parentObj, operand) {
			operand = operand | 0;
			return parentObj.lri2(operand | 0) | 0;
		}
		public function lri2(operand) {
			operand = operand | 0;
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = this.readRegister(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			this.wait.CPUInternalCyclePrefetch(this.fetch, 1);
			//Shift the register data right logically:
			var shifter = (operand >> 7) & 0x1F;
			if (shifter == 0) {
				//Return 0:
				return 0;
			}
			return (register >>> shifter) | 0;
		}
		public function lris(parentObj, operand) {
			operand = operand | 0;
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = parentObj.readRegister(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			parentObj.wait.CPUInternalCyclePrefetch(parentObj.fetch | 0, 1);
			//Get the shift amount:
			var shifter = (operand >> 7) & 0x1F;
			//Check to see if we need to update CPSR:
			if (shifter > 0) {
				parentObj.CPUCore.CPSRCarry = (((register >>> (shifter - 1)) & 0x1) == 0x1); 
				//Shift the register data right logically:
				return register >>> shifter;
			}
			else {
				parentObj.CPUCore.CPSRCarry = (register < 0);
				//Return 0:
				return 0;
			}
		}
		public function lrr(parentObj, operand) {
			operand = operand | 0;
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = parentObj.guardRegisterRead(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			parentObj.wait.CPUInternalCyclePrefetch(parentObj.fetch | 0, 1);
			//Shift the register data right logically:
			var shifter = parentObj.guardRegisterRead((operand >> 8) & 0xF) & 0xFF;
			return (shifter < 0x20) ? ((register >>> shifter) | 0) : 0;
		}
		public function lrrs(parentObj, operand) {
			operand = operand | 0;
			//Logical Right Shift with Register and CPSR:
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = parentObj.guardRegisterRead(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			parentObj.wait.CPUInternalCyclePrefetch(parentObj.fetch | 0, 1);
			//Get the shift amount:
			var shifter = parentObj.guardRegisterRead((operand >> 8) & 0xF) & 0xFF;
			//Check to see if we need to update CPSR:
			if (shifter > 0) {
				if (shifter < 32) {
					//Shift the register data right logically:
					parentObj.CPUCore.CPSRCarry = (((register >> (shifter - 1)) & 0x1) == 0x1);
					return (register >>> shifter) | 0;
				}
				else if (shifter == 32) {
					//Shift bit 31 into carry:
					parentObj.CPUCore.CPSRCarry = (register < 0);
				}
				else {
					//Everything Zero'd:
					parentObj.CPUCore.CPSRCarry = false;
				}
				return 0;
			}
			//If shift is 0, just return the register without mod:
			return register | 0;
		}
		public function ari(parentObj, operand) {
			operand = operand | 0;
			return parentObj.ari2(operand | 0) | 0;
		}
		public function ari2(operand) {
			operand = operand | 0;
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = this.readRegister(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			this.wait.CPUInternalCyclePrefetch(this.fetch | 0, 1);
			//Get the shift amount:
			var shifter = (operand >> 7) & 0x1F;
			if (shifter == 0) {
				//Shift full length if shifter is zero:
				shifter = 0x1F;
			}
			//Shift the register data right:
			return register >> shifter;
		}
		public function aris(parentObj, operand) {
			operand = operand | 0;
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = parentObj.readRegister(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			parentObj.wait.CPUInternalCyclePrefetch(parentObj.fetch | 0, 1);
			//Get the shift amount:
			var shifter = (operand >> 7) & 0x1F;
			//Check to see if we need to update CPSR:
			if (shifter > 0) {
				parentObj.CPUCore.CPSRCarry = (((register >>> (shifter - 1)) & 0x1) == 0x1);
			}
			else {
				//Shift full length if shifter is zero:
				shifter = 0x1F;
				parentObj.CPUCore.CPSRCarry = (register < 0);
			}
			//Shift the register data right:
			return register >> shifter;
		}
		public function arr(parentObj, operand) {
			operand = operand | 0;
			//Arithmetic Right Shift with Register:
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = parentObj.guardRegisterRead(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			parentObj.wait.CPUInternalCyclePrefetch(parentObj.fetch | 0, 1);
			//Shift the register data right:
			return register >> Math.min(parentObj.guardRegisterRead((operand >> 8) & 0xF) & 0xFF, 0x1F);
		}
		public function arrs(parentObj, operand) {
			operand = operand | 0;
			//Arithmetic Right Shift with Register and CPSR:
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = parentObj.guardRegisterRead(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			parentObj.wait.CPUInternalCyclePrefetch(parentObj.fetch | 0, 1);
			//Get the shift amount:
			var shifter = parentObj.guardRegisterRead((operand >> 8) & 0xF) & 0xFF;
			//Check to see if we need to update CPSR:
			if (shifter > 0) {
				if (shifter < 32) {
					//Shift the register data right arithmetically:
					parentObj.CPUCore.CPSRCarry = (((register >> (shifter - 1)) & 0x1) == 0x1);
					return register >> shifter;
				}
				else {
					//Set all bits with bit 31:
					parentObj.CPUCore.CPSRCarry = (register < 0);
					return register >> 0x1F;
				}
			}
			//If shift is 0, just return the register without mod:
			return register | 0;
		}
		public function rri(parentObj, operand) {
			return parentObj.rri2(operand);
		}
		public function rri2(operand) {
			operand = operand | 0;
			//Rotate Right with Immediate:
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = this.readRegister(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			this.wait.CPUInternalCyclePrefetch(this.fetch | 0, 1);
			//Rotate the register right:
			var shifter = (operand >> 7) & 0x1F;
			if (shifter > 0) {
				//ROR
				return (register << (0x20 - shifter)) | (register >>> shifter);
			}
			else {
				//RRX
				return ((this.CPUCore.CPSRCarry) ? 0x80000000 : 0) | (register >>> 0x1);
			}
		}
		public function rris(parentObj, operand) {
			operand = operand | 0;
			//Rotate Right with Immediate and CPSR:
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = parentObj.readRegister(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			parentObj.wait.CPUInternalCyclePrefetch(parentObj.fetch | 0, 1);
			//Rotate the register right:
			var shifter = (operand >> 7) & 0x1F;
			if (shifter > 0) {
				//ROR
				parentObj.CPUCore.CPSRCarry = (((register >>> (shifter - 1)) & 0x1) == 0x1);
				return (register << (0x20 - shifter)) | (register >>> shifter);
			}
			else {
				//RRX
				var rrxValue = ((parentObj.CPUCore.CPSRCarry) ? 0x80000000 : 0) | (register >>> 0x1);
				parentObj.CPUCore.CPSRCarry = ((register & 0x1) != 0);
				return rrxValue | 0;
			}
		}
		public function rrr(parentObj, operand) {
			operand = operand | 0;
			//Rotate Right with Register:
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = parentObj.guardRegisterRead(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			parentObj.wait.CPUInternalCyclePrefetch(parentObj.fetch | 0, 1);
			//Rotate the register right:
			var shifter = parentObj.guardRegisterRead((operand >> 8) & 0xF) & 0x1F;
			if (shifter > 0) {
				//ROR
				return (register << (0x20 - shifter)) | (register >>> shifter);
			}
			//If shift is 0, just return the register without mod:
			return register | 0;
		}
		public function rrrs(parentObj, operand) {
			operand = operand | 0;
			//Rotate Right with Register and CPSR:
			var registerSelected = operand & 0xF;
			//Get the register data to be shifted:
			var register = parentObj.guardRegisterRead(registerSelected | 0) | 0;
			//Clock a cycle for the shift delaying the CPU:
			parentObj.wait.CPUInternalCyclePrefetch(parentObj.fetch | 0, 1);
			//Rotate the register right:
			var shifter = parentObj.guardRegisterRead((operand >> 8) & 0xF) & 0xFF;
			if (shifter > 0) {
				shifter &= 0x1F;
				if (shifter > 0) {
					//ROR
					parentObj.CPUCore.CPSRCarry = (((register >>> (shifter - 1)) & 0x1) == 0x1);
					return (register << (0x20 - shifter)) | (register >>> shifter);
				}
				else {
					//No shift, but make carry set to bit 31:
					parentObj.CPUCore.CPSRCarry = (register < 0);
				}
			}
			//If shift is 0, just return the register without mod:
			return register | 0;
		}
		public function imm(parentObj, operand) {
			//Get the immediate data to be shifted:
			var immediate = operand & 0xFF;
			//Rotate the immediate right:
			var shifter = (operand >> 7) & 0x1E;
			if (shifter > 0) {
				immediate = (immediate << (0x20 - shifter)) | (immediate >>> shifter);
			}
			return immediate | 0;
		}
		public function imms(parentObj, operand) {
			//Get the immediate data to be shifted:
			var immediate = operand & 0xFF;
			//Rotate the immediate right:
			var shifter = (operand >> 7) & 0x1E;
			if (shifter > 0) {
				immediate = (immediate << (0x20 - shifter)) | (immediate >>> shifter);
				//trace("Check here again");
				//parentObj.CPUCore.CPSRCarry = (immediate < 0);
			}
			return immediate | 0;
		}
		public function rc(parentObj) {
			return (
				((parentObj.CPUCore.CPSRNegative) ? 0x80000000 : 0) |
				((parentObj.CPUCore.CPSRZero) ? 0x40000000 : 0) |
				((parentObj.CPUCore.CPSRCarry) ? 0x20000000 : 0) |
				((parentObj.CPUCore.CPSROverflow) ? 0x10000000 : 0) |
				((parentObj.CPUCore.IRQDisabled) ? 0x80 : 0) |
				((parentObj.CPUCore.FIQDisabled) ? 0x40 : 0) |
				0x20 | parentObj.CPUCore.MODEBits
			);
		}
		public function rcs(parentObj, operand) {
			operand = operand | 0;
			var newcpsr = parentObj.readRegister(operand & 0xF) | 0;
			parentObj.CPUCore.CPSRNegative = (newcpsr < 0);
			parentObj.CPUCore.CPSRZero = ((newcpsr & 0x40000000) != 0);
			parentObj.CPUCore.CPSRCarry = ((newcpsr & 0x20000000) != 0);
			parentObj.CPUCore.CPSROverflow = ((newcpsr & 0x10000000) != 0);
			if ((operand & 0x10000) == 0x10000 && parentObj.CPUCore.MODEBits != 0x10) {
				parentObj.CPUCore.IRQDisabled = ((newcpsr & 0x80) != 0);
				parentObj.CPUCore.FIQDisabled = ((newcpsr & 0x40) != 0);
				//parentObj.CPUCore.THUMBBitModify((newcpsr & 0x20) != 0);
				//ARMWrestler test rom triggers THUMB mode, but expects it to remain in ARM mode, so ignore.
				parentObj.CPUCore.switchRegisterBank(newcpsr & 0x1F);
			}
		}
		public function rs(parentObj) {
			switch (parentObj.CPUCore.MODEBits | 0) {
				case 0x11:	//FIQ
					spsr = parentObj.CPUCore.SPSRFIQ;
					break;
				case 0x12:	//IRQ
					spsr = parentObj.CPUCore.SPSRIRQ;
					break;
				case 0x13:	//Supervisor
					spsr = parentObj.CPUCore.SPSRSVC;
					break;
				case 0x17:	//Abort
					spsr = parentObj.CPUCore.SPSRABT;
					break;
				case 0x1B:	//Undefined
					spsr = parentObj.CPUCore.SPSRUND;
					break;
				default:
					//Instruction hit an invalid SPSR request:
					return parentObj.rc(parentObj);
			}
			return (
				((spsr[0]) ? 0x80000000 : 0) |
				((spsr[1]) ? 0x40000000 : 0) |
				((spsr[2]) ? 0x20000000 : 0) |
				((spsr[3]) ? 0x10000000 : 0) |
				((spsr[4]) ? 0x80 : 0) |
				((spsr[5]) ? 0x40 : 0) |
				((spsr[6]) ? 0x20 : 0) |
				spsr[7]
			);
		}
		public function rss(parentObj, operand) {
			operand = operand | 0;
			var newspsr = parentObj.readRegister(operand & 0xF) | 0;
			switch (parentObj.CPUCore.MODEBits | 0) {
				case 0x11:	//FIQ
					spsr = parentObj.CPUCore.SPSRFIQ;
					break;
				case 0x12:	//IRQ
					spsr = parentObj.CPUCore.SPSRIRQ;
					break;
				case 0x13:	//Supervisor
					spsr = parentObj.CPUCore.SPSRSVC;
					break;
				case 0x17:	//Abort
					spsr = parentObj.CPUCore.SPSRABT;
					break;
				case 0x1B:	//Undefined
					spsr = parentObj.CPUCore.SPSRUND;
					break;
				default:
					return;
			}
			spsr[0] = (newspsr < 0);
			spsr[1] = ((newspsr & 0x40000000) != 0);
			spsr[2] = ((newspsr & 0x20000000) != 0);
			spsr[3] = ((newspsr & 0x10000000) != 0);
			if ((operand & 0x10000) == 0x10000) {
				spsr[4] = ((newspsr & 0x80) != 0);
				spsr[5] = ((newspsr & 0x40) != 0);
				spsr[6] = ((newspsr & 0x20) != 0);
				spsr[7] = newspsr & 0x1F;
			}
		}
		public function ic(parentObj, operand) {
			operand = operand | 0;
			operand = parentObj.imm(parentObj, operand | 0) | 0;
			parentObj.CPUCore.CPSRNegative = (operand < 0);
			parentObj.CPUCore.CPSRZero = ((operand & 0x40000000) != 0);
			parentObj.CPUCore.CPSRCarry = ((operand & 0x20000000) != 0);
			parentObj.CPUCore.CPSROverflow = ((operand & 0x10000000) != 0);
		}
		public function _is(parentObj, operand) {
			operand = operand | 0;
			operand = parentObj.imm(parentObj, operand | 0) | 0;
			switch (parentObj.CPUCore.MODEBits | 0) {
				case 0x11:	//FIQ
					var spsr = parentObj.CPUCore.SPSRFIQ;
					break;
				case 0x12:	//IRQ
					spsr = parentObj.CPUCore.SPSRIRQ;
					break;
				case 0x13:	//Supervisor
					spsr = parentObj.CPUCore.SPSRSVC;
					break;
				case 0x17:	//Abort
					spsr = parentObj.CPUCore.SPSRABT;
					break;
				case 0x1B:	//Undefined
					spsr = parentObj.CPUCore.SPSRUND;
					break;
				default:
					return;
			}
			spsr[0] = (operand < 0);
			spsr[1] = ((operand & 0x40000000) != 0);
			spsr[2] = ((operand & 0x20000000) != 0);
			spsr[3] = ((operand & 0x10000000) != 0);
		}
		public function ptrm(parentObj, operand, userMode) {
			operand = operand | 0;
			var offset = parentObj.readRegister(operand & 0xF) | 0;
			return parentObj.updateBasePostDecrement(operand | 0, offset | 0, userMode) | 0;
		}
		public function ptim(parentObj, operand, userMode) {
			operand = operand | 0;
			var offset = ((operand & 0xF00) >> 4) | (operand & 0xF);
			return parentObj.updateBasePostDecrement(operand | 0, offset | 0, userMode) | 0;
		}
		public function ptrp(parentObj, operand, userMode) {
			operand = operand | 0;
			var offset = parentObj.readRegister(operand & 0xF) | 0;
			return parentObj.updateBasePostIncrement(operand | 0, offset | 0, userMode) | 0;
		}
		public function ptip(parentObj, operand, userMode) {
			operand = operand | 0;
			var offset = ((operand & 0xF00) >> 4) | (operand & 0xF);
			return parentObj.updateBasePostIncrement(operand | 0, offset | 0, userMode) | 0;
		}
		public function ofrm(parentObj, operand, fake = null) {
			operand = operand | 0;
			var offset = parentObj.readRegister(operand & 0xF) | 0;
			return parentObj.updateNoBaseDecrement(operand | 0, offset | 0) | 0;
		}
		public function prrm(parentObj, operand, fake = null) {
			operand = operand | 0;
			var offset = parentObj.readRegister(operand & 0xF) | 0;
			return parentObj.updateBasePreDecrement(operand | 0, offset | 0) | 0;
		}
		public function ofim(parentObj, operand, fake = null) {
			operand = operand | 0;
			var offset = ((operand & 0xF00) >> 4) | (operand & 0xF);
			return parentObj.updateNoBaseDecrement(operand | 0, offset | 0) | 0;
		}
		public function prim(parentObj, operand, fake = null) {
			operand = operand | 0;
			var offset = ((operand & 0xF00) >> 4) | (operand & 0xF);
			return parentObj.updateBasePreDecrement(operand | 0, offset | 0) | 0;
		}
		public function ofrp(parentObj, operand, fake = null) {
			operand = operand | 0;
			var offset = parentObj.readRegister(operand & 0xF) | 0;
			return parentObj.updateNoBaseIncrement(operand | 0, offset | 0) | 0;
		}
		public function prrp(parentObj, operand, fake = null) {
			operand = operand | 0;
			var offset = parentObj.readRegister(operand & 0xF) | 0;
			return parentObj.updateBasePreIncrement(operand | 0, offset | 0) | 0;
		}
		public function ofip(parentObj, operand, fake = null) {
			operand = operand | 0;
			var offset = ((operand & 0xF00) >> 4) | (operand & 0xF);
			return parentObj.updateNoBaseIncrement(operand | 0, offset | 0) | 0;
		}
		public function prip(parentObj, operand, fake = null) {
			operand = operand | 0;
			var offset = ((operand & 0xF00) >> 4) | (operand & 0xF);
			return parentObj.updateBasePreIncrement(operand | 0, offset | 0) | 0;
		}
		public function sptim(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = operand & 0xFFF;
			return parentObj.updateBasePostDecrement(operand | 0, offset | 0, userMode | 0);
		}
		public function sptip(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = operand & 0xFFF;
			return parentObj.updateBasePostIncrement(operand | 0, offset | 0, userMode) | 0;
		}
		public function sofim(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = operand & 0xFFF;
			return parentObj.updateNoBaseDecrement(operand | 0, offset | 0) | 0;
		}
		public function sprim(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = operand & 0xFFF;
			return parentObj.updateBasePreDecrement(operand | 0, offset | 0) | 0;
		}
		public function sofip(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = operand & 0xFFF;
			return parentObj.updateNoBaseIncrement(operand | 0, offset | 0) | 0;
		}
		public function sprip(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = operand & 0xFFF;
			return parentObj.updateBasePreIncrement(operand | 0, offset | 0) | 0;
		}
		public function ptrmll(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.lli2(operand | 0) | 0;
			return parentObj.updateBasePostDecrement(operand | 0, offset | 0, userMode) | 0;
		}
		public function ptrmlr(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.lri2(operand | 0) | 0;
			return parentObj.updateBasePostDecrement(operand | 0, offset | 0, userMode) | 0;
		}
		public function ptrmar(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.ari2(operand | 0) | 0;
			return parentObj.updateBasePostDecrement(operand | 0, offset | 0, userMode) | 0;
		}
		public function ptrmrr(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.rri2(operand | 0) | 0;
			return parentObj.updateBasePostDecrement(operand | 0, offset | 0, userMode) | 0;
		}
		public function ptrpll(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.lli2(operand | 0) | 0;
			return parentObj.updateBasePostIncrement(operand | 0, offset | 0, userMode) | 0;
		}
		public function ptrplr(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.lri2(operand | 0) | 0;
			return parentObj.updateBasePostIncrement(operand | 0, offset | 0, userMode) | 0;
		}
		public function ptrpar(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.ari2(operand | 0) | 0;
			return parentObj.updateBasePostIncrement(operand | 0, offset | 0, userMode) | 0;
		}
		public function ptrprr(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.rri2(operand | 0) | 0;
			return parentObj.updateBasePostIncrement(operand | 0, offset | 0, userMode) | 0;
		}
		public function ofrmll(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.lli2(operand | 0) | 0;
			return parentObj.updateNoBaseDecrement(operand | 0, offset | 0) | 0;
		}
		public function ofrmlr(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.lri2(operand | 0) | 0;
			return parentObj.updateNoBaseDecrement(operand | 0, offset | 0) | 0;
		}
		public function ofrmar(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.ari2(operand | 0) | 0;
			return parentObj.updateNoBaseDecrement(operand | 0, offset | 0) | 0;
		}
		public function ofrmrr(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.rri2(operand | 0) | 0;
			return parentObj.updateNoBaseDecrement(operand | 0, offset | 0) | 0;
		}
		public function prrmll(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.lli2(operand | 0) | 0;
			return parentObj.updateBasePreDecrement(operand | 0, offset | 0) | 0;
		}
		public function prrmlr(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.lri2(operand | 0) | 0;
			return parentObj.updateBasePreDecrement(operand | 0, offset | 0) | 0;
		}
		public function prrmar(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.ari2(operand | 0) | 0;
			return parentObj.updateBasePreDecrement(operand | 0, offset | 0) | 0;
		}
		public function prrmrr(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.rri2(operand | 0) | 0;
			return parentObj.updateBasePreDecrement(operand | 0, offset | 0) | 0;
		}
		public function ofrpll(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.lli2(operand | 0) | 0;
			return parentObj.updateNoBaseIncrement(operand | 0, offset | 0) | 0;
		}
		public function ofrplr(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.lri2(operand | 0) | 0;
			return parentObj.updateNoBaseIncrement(operand | 0, offset | 0) | 0;
		}
		public function ofrpar(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.ari2(operand | 0) | 0;
			return parentObj.updateNoBaseIncrement(operand | 0, offset | 0) | 0;
		}
		public function ofrprr(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.rri2(operand | 0) | 0;
			return parentObj.updateNoBaseIncrement(operand | 0, offset | 0) | 0;
		}
		public function prrpll(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.lli2(operand | 0) | 0;
			return parentObj.updateBasePreIncrement(operand | 0, offset | 0) | 0;
		}
		public function prrplr(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.lri2(operand | 0) | 0;
			return parentObj.updateBasePreIncrement(operand | 0, offset | 0) | 0;
		}
		public function prrpar(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.ari2(operand | 0) | 0;
			return parentObj.updateBasePreIncrement(operand | 0, offset | 0) | 0;
		}
		public function prrprr(parentObj, operand, userMode = null) {
			operand = operand | 0;
			var offset = parentObj.rri2(operand | 0) | 0;
			return parentObj.updateBasePreIncrement(operand | 0, offset | 0) | 0;
		}
		
		public function ofm(parentObj, operand) {
			//nothing...
		} 
		public function prm(parentObj, operand) {
			//nothing...
		}
		public function ofp(parentObj, operand) {
			//nothing...
		} 
		public function prp(parentObj, operand) {
			//nothing...
		}
		public function unm (parentObj, operand) {
			//nothing...
		}
		public function unp(parentObj, operand) {
			//nothing...
		}
		public function ptm(parentObj, operand) {
			//nothing...
		}
		public function ptp (parentObj, operand) {
			//nothing...
		}
		public function NOP(parentObj, operand) {
			//nothing...
		}
		
		public function compileInstructionMap() {
			this.instructionMap = [
				//0
				[
					[
						this.AND,
						this.lli
					],
					[
						this.AND,
						this.llr
					],
					[
						this.AND,
						this.lri
					],
					[
						this.AND,
						this.lrr
					],
					[
						this.AND,
						this.ari
					],
					[
						this.AND,
						this.arr
					],
					[
						this.AND,
						this.rri
					],
					[
						this.AND,
						this.rrr
					],
					[
						this.AND,
						this.lli
					],
					[
						this.MUL,
						this.NOP
					],
					[
						this.AND,
						this.lri
					],
					[
						this.STRH,
						this.ptrm
					],
					[
						this.AND,
						this.ari
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.AND,
						this.rri
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//1
				[
					[
						this.ANDS,
						this.llis
					],
					[
						this.ANDS,
						this.llrs
					],
					[
						this.ANDS,
						this.lris
					],
					[
						this.ANDS,
						this.lrrs
					],
					[
						this.ANDS,
						this.aris
					],
					[
						this.ANDS,
						this.arrs
					],
					[
						this.ANDS,
						this.rris
					],
					[
						this.ANDS,
						this.rrrs
					],
					[
						this.ANDS,
						this.llis
					],
					[
						this.MULS,
						this.NOP
					],
					[
						this.ANDS,
						this.lris
					],
					[
						this.LDRH,
						this.ptrm
					],
					[
						this.ANDS,
						this.aris
					],
					[
						this.LDRSB,
						this.ptrm
					],
					[
						this.ANDS,
						this.rris
					],
					[
						this.LDRSH,
						this.ptrm
					]
				],
				//2
				[
					[
						this.EOR,
						this.lli
					],
					[
						this.EOR,
						this.llr
					],
					[
						this.EOR,
						this.lri
					],
					[
						this.EOR,
						this.lrr
					],
					[
						this.EOR,
						this.ari
					],
					[
						this.EOR,
						this.arr
					],
					[
						this.EOR,
						this.rri
					],
					[
						this.EOR,
						this.rrr
					],
					[
						this.EOR,
						this.lli
					],
					[
						this.MLA,
						this.NOP
					],
					[
						this.EOR,
						this.lri
					],
					[
						this.STRHT,
						this.ptrm
					],
					[
						this.EOR,
						this.ari
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.EOR,
						this.rri
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//3
				[
					[
						this.EORS,
						this.llis
					],
					[
						this.EORS,
						this.llrs
					],
					[
						this.EORS,
						this.lris
					],
					[
						this.EORS,
						this.lrrs
					],
					[
						this.EORS,
						this.aris
					],
					[
						this.EORS,
						this.arrs
					],
					[
						this.EORS,
						this.rris
					],
					[
						this.EORS,
						this.rrrs
					],
					[
						this.EORS,
						this.llis
					],
					[
						this.MLAS,
						this.NOP
					],
					[
						this.EORS,
						this.lris
					],
					[
						this.LDRHT,
						this.ptrm
					],
					[
						this.EORS,
						this.aris
					],
					[
						this.LDRSBT,
						this.ptrm
					],
					[
						this.EORS,
						this.rris
					],
					[
						this.LDRSHT,
						this.ptrm
					]
				],
				//4
				[
					[
						this.SUB,
						this.lli
					],
					[
						this.SUB,
						this.llr
					],
					[
						this.SUB,
						this.lri
					],
					[
						this.SUB,
						this.lrr
					],
					[
						this.SUB,
						this.ari
					],
					[
						this.SUB,
						this.arr
					],
					[
						this.SUB,
						this.rri
					],
					[
						this.SUB,
						this.rrr
					],
					[
						this.SUB,
						this.lli
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.SUB,
						this.lri
					],
					[
						this.STRH,
						this.ptim
					],
					[
						this.SUB,
						this.ari
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.SUB,
						this.rri
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//5
				[
					[
						this.SUBS,
						this.lli
					],
					[
						this.SUBS,
						this.llr
					],
					[
						this.SUBS,
						this.lri
					],
					[
						this.SUBS,
						this.lrr
					],
					[
						this.SUBS,
						this.ari
					],
					[
						this.SUBS,
						this.arr
					],
					[
						this.SUBS,
						this.rri
					],
					[
						this.SUBS,
						this.rrr
					],
					[
						this.SUBS,
						this.lli
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.SUBS,
						this.lri
					],
					[
						this.LDRH,
						this.ptim
					],
					[
						this.SUBS,
						this.ari
					],
					[
						this.LDRSB,
						this.ptim
					],
					[
						this.SUBS,
						this.rri
					],
					[
						this.LDRSH,
						this.ptim
					]
				],
				//6
				[
					[
						this.RSB,
						this.lli
					],
					[
						this.RSB,
						this.llr
					],
					[
						this.RSB,
						this.lri
					],
					[
						this.RSB,
						this.lrr
					],
					[
						this.RSB,
						this.ari
					],
					[
						this.RSB,
						this.arr
					],
					[
						this.RSB,
						this.rri
					],
					[
						this.RSB,
						this.rrr
					],
					[
						this.RSB,
						this.lli
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.RSB,
						this.lri
					],
					[
						this.STRHT,
						this.ptim
					],
					[
						this.RSB,
						this.ari
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.RSB,
						this.rri
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//7
				[
					[
						this.RSBS,
						this.lli
					],
					[
						this.RSBS,
						this.llr
					],
					[
						this.RSBS,
						this.lri
					],
					[
						this.RSBS,
						this.lrr
					],
					[
						this.RSBS,
						this.ari
					],
					[
						this.RSBS,
						this.arr
					],
					[
						this.RSBS,
						this.rri
					],
					[
						this.RSBS,
						this.rrr
					],
					[
						this.RSBS,
						this.lli
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.RSBS,
						this.lri
					],
					[
						this.LDRHT,
						this.ptim
					],
					[
						this.RSBS,
						this.ari
					],
					[
						this.LDRSBT,
						this.ptim
					],
					[
						this.RSBS,
						this.rri
					],
					[
						this.LDRSHT,
						this.ptim
					]
				],
				//8
				[
					[
						this.ADD,
						this.lli
					],
					[
						this.ADD,
						this.llr
					],
					[
						this.ADD,
						this.lri
					],
					[
						this.ADD,
						this.lrr
					],
					[
						this.ADD,
						this.ari
					],
					[
						this.ADD,
						this.arr
					],
					[
						this.ADD,
						this.rri
					],
					[
						this.ADD,
						this.rrr
					],
					[
						this.ADD,
						this.lli
					],
					[
						this.UMULL,
						this.NOP
					],
					[
						this.ADD,
						this.lri
					],
					[
						this.STRH,
						this.ptrp
					],
					[
						this.ADD,
						this.ari
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.ADD,
						this.rri
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//9
				[
					[
						this.ADDS,
						this.lli
					],
					[
						this.ADDS,
						this.llr
					],
					[
						this.ADDS,
						this.lri
					],
					[
						this.ADDS,
						this.lrr
					],
					[
						this.ADDS,
						this.ari
					],
					[
						this.ADDS,
						this.arr
					],
					[
						this.ADDS,
						this.rri
					],
					[
						this.ADDS,
						this.rrr
					],
					[
						this.ADDS,
						this.lli
					],
					[
						this.UMULLS,
						this.NOP
					],
					[
						this.ADDS,
						this.lri
					],
					[
						this.LDRH,
						this.ptrp
					],
					[
						this.ADDS,
						this.ari
					],
					[
						this.LDRSB,
						this.ptrp
					],
					[
						this.ADDS,
						this.rri
					],
					[
						this.LDRSH,
						this.ptrp
					]
				],
				//A
				[
					[
						this.ADC,
						this.lli
					],
					[
						this.ADC,
						this.llr
					],
					[
						this.ADC,
						this.lri
					],
					[
						this.ADC,
						this.lrr
					],
					[
						this.ADC,
						this.ari
					],
					[
						this.ADC,
						this.arr
					],
					[
						this.ADC,
						this.rri
					],
					[
						this.ADC,
						this.rrr
					],
					[
						this.ADC,
						this.lli
					],
					[
						this.UMLAL,
						this.NOP
					],
					[
						this.ADC,
						this.lri
					],
					[
						this.STRHT,
						this.ptrp
					],
					[
						this.ADC,
						this.ari
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.ADC,
						this.rri
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//B
				[
					[
						this.ADCS,
						this.lli
					],
					[
						this.ADCS,
						this.llr
					],
					[
						this.ADCS,
						this.lri
					],
					[
						this.ADCS,
						this.lrr
					],
					[
						this.ADCS,
						this.ari
					],
					[
						this.ADCS,
						this.arr
					],
					[
						this.ADCS,
						this.rri
					],
					[
						this.ADCS,
						this.rrr
					],
					[
						this.ADCS,
						this.lli
					],
					[
						this.UMLALS,
						this.NOP
					],
					[
						this.ADCS,
						this.lri
					],
					[
						this.LDRHT,
						this.ptrp
					],
					[
						this.ADCS,
						this.ari
					],
					[
						this.LDRSBT,
						this.ptrp
					],
					[
						this.ADCS,
						this.rri
					],
					[
						this.LDRSHT,
						this.ptrp
					]
				],
				//C
				[
					[
						this.SBC,
						this.lli
					],
					[
						this.SBC,
						this.llr
					],
					[
						this.SBC,
		
						this.lri
					],
					[
						this.SBC,
						this.lrr
					],
					[
						this.SBC,
						this.ari
					],
					[
						this.SBC,
						this.arr
					],
					[
						this.SBC,
						this.rri
					],
					[
						this.SBC,
						this.rrr
					],
					[
						this.SBC,
						this.lli
					],
					[
						this.SMULL,
						this.NOP
					],
					[
						this.SBC,
						this.lri
					],
					[
						this.STRH,
						this.ptip
					],
					[
						this.SBC,
						this.ari
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.SBC,
						this.rri
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//D
				[
					[
						this.SBCS,
						this.lli
					],
					[
						this.SBCS,
						this.llr
					],
					[
						this.SBCS,
						this.lri
					],
					[
						this.SBCS,
						this.lrr
					],
					[
						this.SBCS,
						this.ari
					],
					[
						this.SBCS,
						this.arr
					],
					[
						this.SBCS,
						this.rri
					],
					[
						this.SBCS,
						this.rrr
					],
					[
						this.SBCS,
						this.lli
					],
					[
						this.SMULLS,
						this.NOP
					],
					[
						this.SBCS,
						this.lri
					],
					[
						this.LDRH,
						this.ptip
					],
					[
						this.SBCS,
						this.ari
					],
					[
						this.LDRSB,
						this.ptip
					],
					[
						this.SBCS,
						this.rri
					],
					[
						this.LDRSH,
						this.ptip
					]
				],
				//E
				[
					[
						this.RSC,
						this.lli
					],
					[
						this.RSC,
						this.llr
					],
					[
						this.RSC,
						this.lri
					],
					[
						this.RSC,
						this.lrr
					],
					[
						this.RSC,
						this.ari
					],
					[
						this.RSC,
						this.arr
					],
					[
						this.RSC,
						this.rri
					],
					[
						this.RSC,
						this.rrr
					],
					[
						this.RSC,
						this.lli
					],
					[
						this.SMLAL,
						this.NOP
					],
					[
						this.RSC,
						this.lri
					],
					[
						this.STRHT,
						this.ptip
					],
					[
						this.RSC,
						this.ari
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.RSC,
						this.rri
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//F
				[
					[
						this.RSCS,
						this.lli
					],
					[
						this.RSCS,
						this.llr
					],
					[
						this.RSCS,
						this.lri
					],
					[
						this.RSCS,
						this.lrr
					],
					[
						this.RSCS,
						this.ari
					],
					[
						this.RSCS,
						this.arr
					],
					[
						this.RSCS,
						this.rri
					],
					[
						this.RSCS,
						this.rrr
					],
					[
						this.RSCS,
						this.lli
					],
					[
						this.SMLALS,
						this.NOP
					],
					[
						this.RSCS,
						this.lri
					],
					[
						this.LDRHT,
						this.ptip
					],
					[
						this.RSCS,
						this.ari
					],
					[
						this.LDRSBT,
						this.ptip
					],
					[
						this.RSCS,
						this.rri
					],
					[
						this.LDRSHT,
						this.ptip
					]
				],
				//10
				[
					[
						this.MRS,
						this.rc
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.SWP,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.STRH,
						this.ofrm
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//11
				[
					[
						this.TSTS,
						this.llis
					],
					[
						this.TSTS,
						this.llrs
					],
					[
						this.TSTS,
						this.lris
					],
					[
						this.TSTS,
						this.lrrs
					],
					[
						this.TSTS,
						this.aris
					],
					[
						this.TSTS,
						this.arrs
					],
					[
						this.TSTS,
						this.rris
					],
					[
						this.TSTS,
						this.rrrs
					],
					[
						this.TSTS,
						this.llis
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.TSTS,
						this.lris
					],
					[
						this.LDRH,
						this.ofrm
					],
					[
						this.TSTS,
						this.aris
					],
					[
						this.LDRSB,
						this.ofrm
					],
					[
						this.TSTS,
						this.rris
					],
					[
						this.LDRSH,
						this.ofrm
					]
				],
				//12
				[
					[
						this.MSR,
						this.rcs
					],
					[
						this.BX,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.STRH,
						this.prrm
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//13
				[
					[
						this.TEQS,
						this.llis
					],
					[
						this.TEQS,
						this.llrs
					],
					[
						this.TEQS,
						this.lris
					],
					[
						this.TEQS,
						this.lrrs
					],
					[
						this.TEQS,
						this.aris
					],
					[
						this.TEQS,
						this.arrs
					],
					[
						this.TEQS,
						this.rris
					],
					[
						this.TEQS,
						this.rrrs
					],
					[
						this.TEQS,
						this.llis
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.TEQS,
						this.lris
					],
					[
						this.LDRH,
						this.prrm
					],
					[
						this.TEQS,
						this.aris
					],
					[
						this.LDRSB,
						this.prrm
					],
					[
						this.TEQS,
						this.rris
					],
					[
						this.LDRSH,
						this.prrm
					]
				],
				//14
				[
					[
						this.MRS,
						this.rs
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.SWPB,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.STRH,
						this.ofim
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//15
				[
					[
						this.CMPS,
						this.lli
					],
					[
						this.CMPS,
						this.llr
					],
					[
						this.CMPS,
						this.lri
					],
					[
						this.CMPS,
						this.lrr
					],
					[
						this.CMPS,
						this.ari
					],
					[
						this.CMPS,
						this.arr
					],
					[
						this.CMPS,
						this.rri
					],
					[
						this.CMPS,
						this.rrr
					],
					[
						this.CMPS,
						this.lli
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.CMPS,
						this.lri
					],
					[
						this.LDRH,
						this.ofim
					],
					[
						this.CMPS,
						this.ari
					],
					[
						this.LDRSB,
						this.ofim
					],
					[
						this.CMPS,
						this.rri
					],
					[
						this.LDRSH,
						this.ofim
					]
				],
				//16
				[
					[
						this.MSR,
						this.rss
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.STRH,
						this.prim
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//17
				[
					[
						this.CMNS,
						this.lli
					],
					[
						this.CMNS,
						this.llr
					],
					[
						this.CMNS,
						this.lri
					],
					[
						this.CMNS,
						this.lrr
					],
					[
						this.CMNS,
						this.ari
					],
					[
						this.CMNS,
						this.arr
					],
					[
						this.CMNS,
						this.rri
					],
					[
						this.CMNS,
						this.rrr
					],
					[
						this.CMNS,
						this.lli
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.CMNS,
						this.lri
					],
					[
						this.LDRH,
						this.prim
					],
					[
						this.CMNS,
						this.ari
					],
					[
						this.LDRSB,
						this.prim
					],
					[
						this.CMNS,
						this.rri
					],
					[
						this.LDRSH,
						this.prim
					]
				],
				//18
				[
					[
						this.ORR,
						this.lli
					],
					[
						this.ORR,
						this.llr
					],
					[
						this.ORR,
						this.lri
					],
					[
						this.ORR,
						this.lrr
					],
					[
						this.ORR,
						this.ari
					],
					[
						this.ORR,
						this.arr
					],
					[
						this.ORR,
						this.rri
					],
					[
						this.ORR,
						this.rrr
					],
					[
						this.ORR,
						this.lli
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.ORR,
						this.lri
					],
					[
						this.STRH,
						this.ofrp
					],
					[
						this.ORR,
						this.ari
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.ORR,
						this.rri
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//19
				[
					[
						this.ORRS,
						this.llis
					],
					[
						this.ORRS,
						this.llrs
					],
					[
						this.ORRS,
						this.lris
					],
					[
						this.ORRS,
						this.lrrs
					],
					[
						this.ORRS,
						this.aris
					],
					[
						this.ORRS,
						this.arrs
					],
					[
						this.ORRS,
						this.rris
					],
					[
						this.ORRS,
						this.rrrs
					],
					[
						this.ORRS,
						this.llis
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.ORRS,
						this.lris
					],
					[
						this.LDRH,
						this.ofrp
					],
					[
						this.ORRS,
						this.aris
					],
					[
						this.LDRSB,
						this.ofrp
					],
					[
						this.ORRS,
						this.rris
					],
					[
						this.LDRSH,
						this.ofrp
					]
				],
				//1A
				[
					[
						this.MOV,
						this.lli
					],
					[
						this.MOV,
						this.llr
					],
					[
						this.MOV,
						this.lri
					],
					[
						this.MOV,
						this.lrr
					],
					[
						this.MOV,
						this.ari
					],
					[
						this.MOV,
						this.arr
					],
					[
						this.MOV,
						this.rri
					],
					[
						this.MOV,
						this.rrr
					],
					[
						this.MOV,
						this.lli
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.MOV,
						this.lri
					],
					[
						this.STRH,
						this.prrp
					],
					[
						this.MOV,
						this.ari
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.MOV,
						this.rri
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//1B
				[
					[
						this.MOVS,
						this.llis
					],
					[
						this.MOVS,
						this.llrs
					],
					[
						this.MOVS,
						this.lris
					],
					[
						this.MOVS,
						this.lrrs
					],
					[
						this.MOVS,
						this.aris
					],
					[
						this.MOVS,
						this.arrs
					],
					[
						this.MOVS,
						this.rris
					],
					[
						this.MOVS,
						this.rrrs
					],
					[
						this.MOVS,
						this.llis
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.MOVS,
						this.lris
					],
					[
						this.LDRH,
						this.prrp
					],
					[
						this.MOVS,
						this.aris
					],
					[
						this.LDRSB,
						this.prrp
					],
					[
						this.MOVS,
						this.rris
					],
					[
						this.LDRSH,
						this.prrp
					]
				],
				//1C
				[
					[
						this.BIC,
						this.lli
					],
					[
						this.BIC,
						this.llr
					],
					[
						this.BIC,
						this.lri
					],
					[
						this.BIC,
						this.lrr
					],
					[
						this.BIC,
						this.ari
					],
					[
						this.BIC,
						this.arr
					],
					[
						this.BIC,
						this.rri
					],
					[
						this.BIC,
						this.rrr
					],
					[
						this.BIC,
						this.lli
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.BIC,
						this.lri
					],
					[
						this.STRH,
						this.ofip
					],
					[
						this.BIC,
						this.ari
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.BIC,
						this.rri
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//1D
				[
					[
						this.BICS,
						this.llis
					],
					[
						this.BICS,
						this.llrs
					],
					[
						this.BICS,
						this.lris
					],
					[
						this.BICS,
						this.lrrs
					],
					[
						this.BICS,
						this.aris
					],
					[
						this.BICS,
						this.arrs
					],
					[
						this.BICS,
						this.rris
					],
					[
						this.BICS,
						this.rrrs
					],
					[
						this.BICS,
						this.llis
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.BICS,
						this.lris
					],
					[
						this.LDRH,
						this.ofip
					],
					[
						this.BICS,
						this.aris
					],
					[
						this.LDRSB,
						this.ofip
					],
					[
						this.BICS,
						this.rris
					],
					[
						this.LDRSH,
						this.ofip
					]
				],
				//1E
				[
					[
						this.MVN,
						this.lli
					],
					[
						this.MVN,
						this.llr
					],
					[
						this.MVN,
						this.lri
					],
					[
						this.MVN,
						this.lrr
					],
					[
						this.MVN,
						this.ari
					],
					[
						this.MVN,
						this.arr
					],
					[
						this.MVN,
						this.rri
					],
					[
						this.MVN,
						this.rrr
					],
					[
						this.MVN,
						this.lli
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.MVN,
						this.lri
					],
					[
						this.STRH,
						this.prip
					],
					[
						this.MVN,
						this.ari
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.MVN,
						this.rri
					],
					[
						this.UNDEFINED,
						this.NOP
					]
				],
				//1F
				[
					[
						this.MVNS,
						this.llis
					],
					[
						this.MVNS,
						this.llrs
					],
					[
						this.MVNS,
						this.lris
					],
					[
						this.MVNS,
						this.lrrs
					],
					[
						this.MVNS,
						this.aris
					],
					[
						this.MVNS,
						this.arrs
					],
					[
						this.MVNS,
						this.rris
					],
					[
						this.MVNS,
						this.rrrs
					],
					[
						this.MVNS,
						this.llis
					],
					[
						this.UNDEFINED,
						this.NOP
					],
					[
						this.MVNS,
						this.lris
					],
					[
						this.LDRH,
						this.prip
					],
					[
						this.MVNS,
						this.aris
					],
					[
						this.LDRSB,
						this.prip
					],
					[
						this.MVNS,
						this.rris
					],
					[
						this.LDRSH,
						this.prip
					]
				],
				//20
				this.generateLowMap(this.AND, this.imm),
				//21
				this.generateLowMap(this.ANDS, this.imms),
				//22
				this.generateLowMap(this.EOR, this.imm),
				//23
				this.generateLowMap(this.EORS, this.imms),
				//24
				this.generateLowMap(this.SUB, this.imm),
				//25
				this.generateLowMap(this.SUBS, this.imm),
				//26
				this.generateLowMap(this.RSB, this.imm),
				//27
				this.generateLowMap(this.RSBS, this.imm),
				//28
				this.generateLowMap(this.ADD, this.imm),
				//29
				this.generateLowMap(this.ADDS, this.imm),
				//2A
				this.generateLowMap(this.ADC, this.imm),
				//2B
				this.generateLowMap(this.ADCS, this.imm),
				//2C
				this.generateLowMap(this.SBC, this.imm),
				//2D
				this.generateLowMap(this.SBCS, this.imm),
				//2E
				this.generateLowMap(this.RSC, this.imm),
				//2F
				this.generateLowMap(this.RSCS, this.imm),
				//30
				this.generateLowMap(this.UNDEFINED, this.NOP),
				//31
				this.generateLowMap(this.TSTS, this.imms),
				//32
				this.generateLowMap(this.MSR, this.ic),
				//33
				this.generateLowMap(this.TEQS, this.imms),
				//34
				this.generateLowMap(this.UNDEFINED, this.NOP),
				//35
				this.generateLowMap(this.CMPS, this.imm),
				//36
				this.generateLowMap(this.MSR, this._is),
				//37
				this.generateLowMap(this.CMNS, this.imm),
				//38
				this.generateLowMap(this.ORR, this.imm),
				//39
				this.generateLowMap(this.ORRS, this.imms),
				//3A
				this.generateLowMap(this.MOV, this.imm),
				//3B
				this.generateLowMap(this.MOVS, this.imms),
				//3C
				this.generateLowMap(this.BIC, this.imm),
				//3D
				this.generateLowMap(this.BICS, this.imms),
				//3E
				this.generateLowMap(this.MVN, this.imm),
				//3F
				this.generateLowMap(this.MVNS, this.imms),
				//40
				this.generateLowMap(this.STR, this.sptim),
				//41
				this.generateLowMap(this.LDR, this.sptim),
				//42
				this.generateLowMap(this.STRT, this.sptim),
				//43
				this.generateLowMap(this.LDRT, this.sptim),
				//44
				this.generateLowMap(this.STRB, this.sptim),
				//45
				this.generateLowMap(this.LDRB, this.sptim),
				//46
				this.generateLowMap(this.STRBT, this.sptim),
				//47
				this.generateLowMap(this.LDRBT, this.sptim),
				//48
				this.generateLowMap(this.STR, this.sptip),
				//49
				this.generateLowMap(this.LDR, this.sptip),
				//4A
				this.generateLowMap(this.STRT, this.sptip),
				//4B
				this.generateLowMap(this.LDRT, this.sptip),
				//4C
				this.generateLowMap(this.STRB, this.sptip),
				//4D
				this.generateLowMap(this.LDRB, this.sptip),
				//4E
				this.generateLowMap(this.STRBT, this.sptip),
				//4F
				this.generateLowMap(this.LDRBT, this.sptip),
				//50
				this.generateLowMap(this.STR, this.sofim),
				//51
				this.generateLowMap(this.LDR, this.sofim),
				//52
				this.generateLowMap(this.STR, this.sprim),
				//53
				this.generateLowMap(this.LDR, this.sprim),
				//54
				this.generateLowMap(this.STRB, this.sofim),
				//55
				this.generateLowMap(this.LDRB, this.sofim),
				//56
				this.generateLowMap(this.STRB, this.sprim),
				//57
				this.generateLowMap(this.LDRB, this.sprim),
				//58
				this.generateLowMap(this.STR, this.sofip),
				//59
				this.generateLowMap(this.LDR, this.sofip),
				//5A
				this.generateLowMap(this.STR, this.sprip),
				//5B
				this.generateLowMap(this.LDR, this.sprip),
				//5C
				this.generateLowMap(this.STRB, this.sofip),
				//5D
				this.generateLowMap(this.LDRB, this.sofip),
				//5E
				this.generateLowMap(this.STRB, this.sprip),
				//5F
				this.generateLowMap(this.LDRB, this.sprip),
			];
			//60-6F
			this.generateStoreLoadInstructionSector1();
			//70-7F
			this.generateStoreLoadInstructionSector2();
			this.instructionMap = this.instructionMap.concat([
				//80
				this.generateLowMap(this.STMDA, this.guardRegisterReadSTM),
				//81
				this.generateLowMap(this.LDMDA, this.guardRegisterWriteLDM),
				//82
				this.generateLowMap(this.STMDAW, this.guardRegisterReadSTM),
				//83
				this.generateLowMap(this.LDMDAW, this.guardRegisterWriteLDM),
				//84
				this.generateLowMap(this.STMDA, this.guardUserRegisterReadSTM),
				//85
				this.generateLowMap(this.LDMDA, this.guardUserRegisterWriteLDM),
				//86
				this.generateLowMap(this.STMDAW, this.guardUserRegisterReadSTM),
				//87
				this.generateLowMap(this.LDMDAW, this.guardUserRegisterWriteLDM),
				//88
				this.generateLowMap(this.STMIA, this.guardRegisterReadSTM),
				//89
				this.generateLowMap(this.LDMIA, this.guardRegisterWriteLDM),
				//8A
				this.generateLowMap(this.STMIAW, this.guardRegisterReadSTM),
				//8B
				this.generateLowMap(this.LDMIAW, this.guardRegisterWriteLDM),
				//8C
				this.generateLowMap(this.STMIA, this.guardUserRegisterReadSTM),
				//8D
				this.generateLowMap(this.LDMIA, this.guardUserRegisterWriteLDM),
				//8E
				this.generateLowMap(this.STMIAW, this.guardUserRegisterReadSTM),
				//8F
				this.generateLowMap(this.LDMIAW, this.guardUserRegisterWriteLDM),
				//90
				this.generateLowMap(this.STMDB, this.guardRegisterReadSTM),
				//91
				this.generateLowMap(this.LDMDB, this.guardRegisterWriteLDM),
				//92
				this.generateLowMap(this.STMDBW, this.guardRegisterReadSTM),
				//93
				this.generateLowMap(this.LDMDBW, this.guardRegisterWriteLDM),
				//94
				this.generateLowMap(this.STMDB, this.guardUserRegisterReadSTM),
				//95
				this.generateLowMap(this.LDMDB, this.guardUserRegisterWriteLDM),
				//96
				this.generateLowMap(this.STMDBW, this.guardUserRegisterReadSTM),
				//97
				this.generateLowMap(this.LDMDBW, this.guardUserRegisterWriteLDM),
				//98
				this.generateLowMap(this.STMIB, this.guardRegisterReadSTM),
				//99
				this.generateLowMap(this.LDMIB, this.guardRegisterWriteLDM),
				//9A
				this.generateLowMap(this.STMIBW, this.guardRegisterReadSTM),
				//9B
				this.generateLowMap(this.LDMIBW, this.guardRegisterWriteLDM),
				//9C
				this.generateLowMap(this.STMIB, this.guardUserRegisterReadSTM),
				//9D
				this.generateLowMap(this.LDMIB, this.guardUserRegisterWriteLDM),
				//9E
				this.generateLowMap(this.STMIBW, this.guardUserRegisterReadSTM),
				//9F
				this.generateLowMap(this.LDMIBW, this.guardUserRegisterWriteLDM),
				//A0
				this.generateLowMap(this.B, this.NOP),
				//A1
				this.generateLowMap(this.B, this.NOP),
				//A2
				this.generateLowMap(this.B, this.NOP),
				//A3
				this.generateLowMap(this.B, this.NOP),
				//A4
				this.generateLowMap(this.B, this.NOP),
				//A5
				this.generateLowMap(this.B, this.NOP),
				//A6
				this.generateLowMap(this.B, this.NOP),
				//A7
				this.generateLowMap(this.B, this.NOP),
				//A8
				this.generateLowMap(this.B, this.NOP),
				//A9
				this.generateLowMap(this.B, this.NOP),
				//AA
				this.generateLowMap(this.B, this.NOP),
				//AB
				this.generateLowMap(this.B, this.NOP),
				//AC
				this.generateLowMap(this.B, this.NOP),
				//AD
				this.generateLowMap(this.B, this.NOP),
				//AE
				this.generateLowMap(this.B, this.NOP),
				//AF
				this.generateLowMap(this.B, this.NOP),
				//B0
				this.generateLowMap(this.BL, this.NOP),
				//B1
				this.generateLowMap(this.BL, this.NOP),
				//B2
				this.generateLowMap(this.BL, this.NOP),
				//B3
				this.generateLowMap(this.BL, this.NOP),
				//B4
				this.generateLowMap(this.BL, this.NOP),
				//B5
				this.generateLowMap(this.BL, this.NOP),
				//B6
				this.generateLowMap(this.BL, this.NOP),
				//B7
				this.generateLowMap(this.BL, this.NOP),
				//B8
				this.generateLowMap(this.BL, this.NOP),
				//B9
				this.generateLowMap(this.BL, this.NOP),
				//BA
				this.generateLowMap(this.BL, this.NOP),
				//BB
				this.generateLowMap(this.BL, this.NOP),
				//BC
				this.generateLowMap(this.BL, this.NOP),
				//BD
				this.generateLowMap(this.BL, this.NOP),
				//BE
				this.generateLowMap(this.BL, this.NOP),
				//BF
				this.generateLowMap(this.BL, this.NOP),
				//C0
				this.generateLowMap(this.STC, this.ofm),
				//C1
				this.generateLowMap(this.LDC, this.ofm),
				//C2
				this.generateLowMap(this.STC, this.prm),
				//C3
				this.generateLowMap(this.LDC, this.prm),
				//C4
				this.generateLowMap(this.STC, this.ofm),
				//C5
				this.generateLowMap(this.LDC, this.ofm),
				//C6
				this.generateLowMap(this.STC, this.prm),
				//C7
				this.generateLowMap(this.LDC, this.prm),
				//C8
				this.generateLowMap(this.STC, this.ofp),
				//C9
				this.generateLowMap(this.LDC, this.ofp),
				//CA
				this.generateLowMap(this.STC, this.prp),
				//CB
				this.generateLowMap(this.LDC, this.prp),
				//CC
				this.generateLowMap(this.STC, this.ofp),
				//CD
				this.generateLowMap(this.LDC, this.ofp),
				//CE
				this.generateLowMap(this.STC, this.prp),
				//CF
				this.generateLowMap(this.LDC, this.prp),
				//D0
				this.generateLowMap(this.STC, this.unm),
				//D1
				this.generateLowMap(this.LDC, this.unm),
				//D2
				this.generateLowMap(this.STC, this.ptm),
				//D3
				this.generateLowMap(this.LDC, this.ptm),
				//D4
				this.generateLowMap(this.STC, this.unm),
				//D5
				this.generateLowMap(this.LDC, this.unm),
				//D6
				this.generateLowMap(this.STC, this.ptm),
				//D7
				this.generateLowMap(this.LDC, this.ptm),
				//D8
				this.generateLowMap(this.STC, this.unp),
				//D9
				this.generateLowMap(this.LDC, this.unp),
				//DA
				this.generateLowMap(this.STC, this.ptp),
				//DB
				this.generateLowMap(this.LDC, this.ptp),
				//DC
				this.generateLowMap(this.STC, this.unp),
				//DD
				this.generateLowMap(this.LDC, this.unp),
				//DE
				this.generateLowMap(this.STC, this.ptp),
				//DF
				this.generateLowMap(this.LDC, this.ptp),
				//E0
				this.generateLowMap2(this.CDP, this.MCR),
				//E1
				this.generateLowMap2(this.CDP, this.MRC),
				//E2
				this.generateLowMap2(this.CDP, this.MCR),
				//E3
				this.generateLowMap2(this.CDP, this.MRC),
				//E4
				this.generateLowMap2(this.CDP, this.MCR),
				//E5
				this.generateLowMap2(this.CDP, this.MRC),
				//E6
				this.generateLowMap2(this.CDP, this.MCR),
				//E7
				this.generateLowMap2(this.CDP, this.MRC),
				//E8
				this.generateLowMap2(this.CDP, this.MCR),
				//E9
				this.generateLowMap2(this.CDP, this.MRC),
				//EA
				this.generateLowMap2(this.CDP, this.MCR),
				//EB
				this.generateLowMap2(this.CDP, this.MRC),
				//EC
				this.generateLowMap2(this.CDP, this.MCR),
				//ED
				this.generateLowMap2(this.CDP, this.MRC),
				//EE
				this.generateLowMap2(this.CDP, this.MCR),
				//EF
				this.generateLowMap2(this.CDP, this.MRC),
				//F0
				this.generateLowMap(this.SWI, this.NOP),
				//F1
				this.generateLowMap(this.SWI, this.NOP),
				//F2
				this.generateLowMap(this.SWI, this.NOP),
				//F3
				this.generateLowMap(this.SWI, this.NOP),
				//F4
				this.generateLowMap(this.SWI, this.NOP),
				//F5
				this.generateLowMap(this.SWI, this.NOP),
				//F6
				this.generateLowMap(this.SWI, this.NOP),
				//F7
				this.generateLowMap(this.SWI, this.NOP),
				//F8
				this.generateLowMap(this.SWI, this.NOP),
				//F9
				this.generateLowMap(this.SWI, this.NOP),
				//FA
				this.generateLowMap(this.SWI, this.NOP),
				//FB
				this.generateLowMap(this.SWI, this.NOP),
				//FC
				this.generateLowMap(this.SWI, this.NOP),
				//FD
				this.generateLowMap(this.SWI, this.NOP),
				//FE
				this.generateLowMap(this.SWI, this.NOP),
				//FF
				this.generateLowMap(this.SWI, this.NOP)
			]);
		}
		public function generateLowMap(instructionOpcode, dataOpcode) {
			return [
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				],
				[
					instructionOpcode,
					dataOpcode
				]
			];
		}
		public function generateLowMap2(instructionOpcode, instructionOpcode2) {
			return [
				[
					instructionOpcode,
					this.NOP
				],
				[
					instructionOpcode2,
					this.NOP
				],
				[
					instructionOpcode,
					this.NOP
				],
				[
					instructionOpcode2,
					this.NOP
				],
				[
					instructionOpcode,
					this.NOP
				],
				[
					instructionOpcode2,
					this.NOP
				],
				[
					instructionOpcode,
					this.NOP
				],
				[
					instructionOpcode2,
					this.NOP
				],
				[
					instructionOpcode,
					this.NOP
				],
				[
					instructionOpcode2,
					this.NOP
				],
				[
					instructionOpcode,
					this.NOP
				],
				[
					instructionOpcode2,
					this.NOP
				],
				[
					instructionOpcode,
					this.NOP
				],
				[
					instructionOpcode2,
					this.NOP
				],
				[
					instructionOpcode,
					this.NOP
				],
				[
					instructionOpcode2,
					this.NOP
				]
			];
		}
		public function generateStoreLoadInstructionSector1() {
			var instrMap = [
				this.STR,
				this.LDR,
				this.STRT,
				this.LDRT,
				this.STRB,
				this.LDRB,
				this.STRBT,
				this.LDRBT
			];
			var dataMap = [
				this.ptrmll,
				this.ptrmlr,
				this.ptrmar,
				this.ptrmrr,
				this.ptrpll,
				this.ptrplr,
				this.ptrpar,
				this.ptrprr
			];
			for (var instrIndex = 0; instrIndex < 0x10; ++instrIndex) {
				var lowMap = [];
				for (var dataIndex = 0; dataIndex < 0x10; ++dataIndex) {
					if ((dataIndex & 0x1) == 0) {
						lowMap.push([
							instrMap[instrIndex & 0x7],
							dataMap[((dataIndex >> 1) & 0x3) | ((instrIndex & 0x8) >> 1)]
						]);
					}
					else {
						lowMap.push([
							this.UNDEFINED,
							this.NOP
						]);
					}
				}
				this.instructionMap.push(lowMap);
			}
		}
		public function generateStoreLoadInstructionSector2() {
			var instrMap = [
				this.STR,
				this.LDR,
				this.STRB,
				this.LDRB
			];
			var dataMap = [
				[
					this.ofrmll,
					this.ofrmlr,
					this.ofrmar,
					this.ofrmrr
				],
				[
					this.prrmll,
					this.prrmlr,
					this.prrmar,
					this.prrmrr
				],
				[
					this.ofrpll,
					this.ofrplr,
					this.ofrpar,
					this.ofrprr
				],
				[
					this.prrpll,
					this.prrplr,
					this.prrpar,
					this.prrprr
				]
			];
			for (var instrIndex = 0; instrIndex < 0x10; ++instrIndex) {
				var lowMap = [];
				for (var dataIndex = 0; dataIndex < 0x10; ++dataIndex) {
					if ((dataIndex & 0x1) == 0) {
						lowMap.push([
							instrMap[((instrIndex >> 1) & 0x2) | (instrIndex & 0x1)],
							dataMap[((instrIndex & 0x8) >> 2) | ((instrIndex & 0x2) >> 1)][(dataIndex >> 1) & 0x3]
						]);
					}
					else {
						lowMap.push([
							this.UNDEFINED,
							this.NOP
						]);
					}
				}
				this.instructionMap.push(lowMap);
			}
		}
		public function compileReducedInstructionMap() {
			//Flatten the multi-dimensional decode array:
			var indice = 0;
			this.instructionMapReduced = [];
			for (var range1 = 0; range1 < 0x100; ++range1) {
				var instrDecoded = this.instructionMap[range1];
				for (var range2 = 0; range2 < 0x10; ++range2) {
					var instructionCombo = instrDecoded[range2];
					this.instructionMapReduced.push(this.appendInstrucion(this, instructionCombo[0], instructionCombo[1]));
				}
			}
			//Reduce memory usage by nulling the temporary multi array:
			this.instructionMap = null;
		}
		public function appendInstrucion(parentObj, decodedInstr, decodedOperand) {
			return function () {
				decodedInstr(parentObj, decodedOperand);
			}
		}
		
		

	}
	
}
