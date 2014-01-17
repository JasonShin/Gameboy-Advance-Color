package CPU {
	import utils.Logger;
	
	public class THUMBInstructionSet {
		
		public var CPUCore:CPU;
		public var IOCore;
		public var memory;
		public var wait;
		public var registers;
		public var fetch;
		public var decode;
		public var execute;
		
		public var instructionMap:Array;
		
		
		public function THUMBInstructionSet(cpu:CPU) {
			// constructor code
			CPUCore = cpu;
			initialize();
		}
		
		public function initialize() {
			this.IOCore = this.CPUCore.IOCore;
			this.memory = this.IOCore.memory;
			this.wait = this.IOCore.wait;
			this.registers = this.CPUCore.registers;
			this.fetch = 0;
			this.decode = 0;
			this.execute = 0;
			this.compileInstructionMap();
		}
		
		public function guardHighRegisterWrite(data) {
			var address = 0x8 | (this.execute & 0x7);
			if (address == 15) {
				//We performed a branch:
				this.CPUCore.branch(data & -2);
			}
			else {
				//Regular Data Write:
				this.registers[address | 0] = data | 0;
			}
		}
		
		public function writePC(data) {
			//We performed a branch:
			//Update the program counter to branch address:
			this.CPUCore.branch(data & -2);
		}
		public function offsetPC(data) {
			//We performed a branch:
			//Update the program counter to branch address:
			this.CPUCore.branch((this.registers[15] + ((data << 24) >> 23)) | 0);
		}
		public function getLR() {
			return (this.registers[15] - 2) | 0;
		}
		public function getIRQLR() {
			return this.registers[15] | 0;
		}
		public function executeIteration() {
			//Push the new fetch access:
			this.fetch = this.wait.CPUGetOpcode16(this.registers[15] | 0) | 0;
			//Execute Instruction:
			this.executeTHUMB();
			//Update the pipelining state:
			this.execute = this.decode | 0;
			this.decode = this.fetch | 0;
		}
		public function executeTHUMB() {
			if (this.CPUCore.pipelineInvalid == 0) {
				//No condition code:
				this.instructionMap[this.execute >> 6](this);
			}
		}
		public function incrementProgramCounter() {
			//Increment The Program Counter:
			this.registers[15] = ((this.registers[15] | 0) + 2) | 0;
		}
		public function LSLimm(parentObj) {
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var offset = (parentObj.execute >> 6) & 0x1F;
			if (offset > 0) {
				//CPSR Carry is set by the last bit shifted out:
				parentObj.CPUCore.CPSRCarry = ((source << (offset - 1)) < 0);
				//Perform shift:
				source <<= offset;
			}
			//Perform CPSR updates for N and Z (But not V):
			parentObj.CPUCore.CPSRNegative = (source < 0);
			parentObj.CPUCore.CPSRZero = (source == 0);
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = source | 0;
		}
		public function LSRimm(parentObj) {
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var offset = (parentObj.execute >> 6) & 0x1F;
			if (offset > 0) {
				//CPSR Carry is set by the last bit shifted out:
				parentObj.CPUCore.CPSRCarry = (((source >> (offset - 1)) & 0x1) != 0);
				//Perform shift:
				source = (source >>> offset) | 0;
			}
			else {
				parentObj.CPUCore.CPSRCarry = (source < 0);
				source = 0;
			}
			//Perform CPSR updates for N and Z (But not V):
			parentObj.CPUCore.CPSRNegative = (source < 0);
			parentObj.CPUCore.CPSRZero = (source == 0);
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = source | 0;
		}
		public function ASRimm(parentObj) {
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var offset = (parentObj.execute >> 6) & 0x1F;
			if (offset > 0) {
				//CPSR Carry is set by the last bit shifted out:
				parentObj.CPUCore.CPSRCarry = (((source >> (offset - 1)) & 0x1) != 0);
				//Perform shift:
				source >>= offset;
			}
			else {
				parentObj.CPUCore.CPSRCarry = (source < 0);
				source >>= 0x1F;
			}
			//Perform CPSR updates for N and Z (But not V):
			parentObj.CPUCore.CPSRNegative = (source < 0);
			parentObj.CPUCore.CPSRZero = (source == 0);
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = source | 0;
		}
		public function ADDreg(parentObj) {
			var operand1 = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var operand2 = parentObj.registers[(parentObj.execute >> 6) & 0x7] | 0;
		
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = parentObj.CPUCore.setADDFlags(operand1 | 0, operand2 | 0) | 0;
		}
		public function SUBreg(parentObj) {
			var operand1 = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var operand2 = parentObj.registers[(parentObj.execute >> 6) & 0x7] | 0;
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = parentObj.CPUCore.setSUBFlags(operand1 | 0, operand2 | 0) | 0;
		}
		public function ADDimm3(parentObj) {
			var operand1 = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var operand2 = (parentObj.execute >> 6) & 0x7;
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = parentObj.CPUCore.setADDFlags(operand1 | 0, operand2 | 0) | 0;
		}
		public function SUBimm3(parentObj) {
			var operand1 = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var operand2 = (parentObj.execute >> 6) & 0x7;
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = parentObj.CPUCore.setSUBFlags(operand1 | 0, operand2 | 0) | 0;
		}
		public function MOVimm8(parentObj) {
			//Get the 8-bit value to move into the register:
			var result = parentObj.execute & 0xFF;
			parentObj.CPUCore.CPSRNegative = false;
			parentObj.CPUCore.CPSRZero = (result == 0);
			//Update destination register:
			parentObj.registers[(parentObj.execute >> 8) & 0x7] = result | 0;
		}
		public function CMPimm8(parentObj) {
			//Compare an 8-bit immediate value with a register:
			var operand1 = parentObj.registers[(parentObj.execute >> 8) & 0x7] | 0;
			var operand2 = parentObj.execute & 0xFF;
			parentObj.CPUCore.setCMPFlags(operand1 | 0, operand2 | 0);
		}
		public function ADDimm8(parentObj) {
			//Add an 8-bit immediate value with a register:
			var operand1 = parentObj.registers[(parentObj.execute >> 8) & 0x7] | 0;
			var operand2 = parentObj.execute & 0xFF;
			parentObj.registers[(parentObj.execute >> 8) & 0x7] = parentObj.CPUCore.setADDFlags(operand1 | 0, operand2 | 0) | 0;
		}
		public function SUBimm8(parentObj) {
			//Subtract an 8-bit immediate value from a register:
			var operand1 = parentObj.registers[(parentObj.execute >> 8) & 0x7] | 0;
			var operand2 = parentObj.execute & 0xFF;
			parentObj.registers[(parentObj.execute >> 8) & 0x7] = parentObj.CPUCore.setSUBFlags(operand1 | 0, operand2 | 0) | 0;
		}
		public function AND(parentObj) {
			Logger.logTHUMB("THUMB AND");
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var destination = parentObj.registers[parentObj.execute & 0x7] | 0;
			//Perform bitwise AND:
			var result = source & destination;
			parentObj.CPUCore.CPSRNegative = (result < 0);
			parentObj.CPUCore.CPSRZero = (result == 0);
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = result | 0;
		}
		public function EOR(parentObj) {
			Logger.logTHUMB("THUMB EOR");
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var destination = parentObj.registers[parentObj.execute & 0x7] | 0;
			//Perform bitwise EOR:
			var result = source ^ destination;
			parentObj.CPUCore.CPSRNegative = (result < 0);
			parentObj.CPUCore.CPSRZero = (result == 0);
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = result | 0;
		}
		public function LSL(parentObj) {
			Logger.logTHUMB("THUMB LSL");
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] & 0xFF;
			var destination = parentObj.registers[parentObj.execute & 0x7] | 0;
			//Check to see if we need to update CPSR:
			if (source > 0) {
				if (source < 32) {
					//Shift the register data left:
					parentObj.CPUCore.CPSRCarry = ((destination << (source - 1)) < 0);
					destination <<= source;
				}
				else if (source == 32) {
					//Shift bit 0 into carry:
					parentObj.CPUCore.CPSRCarry = ((destination & 0x1) == 0x1);
					destination = 0;
		
				}
				else {
					//Everything Zero'd:
					parentObj.CPUCore.CPSRCarry = false;
					destination = 0;
				}
			}
			//Perform CPSR updates for N and Z (But not V):
			parentObj.CPUCore.CPSRNegative = (destination < 0);
			parentObj.CPUCore.CPSRZero = (destination == 0);
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = destination | 0;
		}
		public function LSR(parentObj) {
			Logger.logTHUMB("THUMB LSR");
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] & 0xFF;
			var destination = parentObj.registers[parentObj.execute & 0x7] | 0;
			//Check to see if we need to update CPSR:
			if (source > 0) {
				if (source < 32) {
					//Shift the register data right logically:
					parentObj.CPUCore.CPSRCarry = (((destination >> (source - 1)) & 0x1) == 0x1);
					destination = (destination >>> source) | 0;
				}
				else if (source == 32) {
					//Shift bit 31 into carry:
					parentObj.CPUCore.CPSRCarry = (destination < 0);
					destination = 0;
				}
				else {
					//Everything Zero'd:
					parentObj.CPUCore.CPSRCarry = false;
					destination = 0;
				}
			}
			//Perform CPSR updates for N and Z (But not V):
			parentObj.CPUCore.CPSRNegative = (destination < 0);
			parentObj.CPUCore.CPSRZero = (destination == 0);
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = destination | 0;
		}
		public function ASR(parentObj) {
			Logger.logTHUMB("THUMB ASR");
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] & 0xFF;
			var destination = parentObj.registers[parentObj.execute & 0x7] | 0;
			//Check to see if we need to update CPSR:
			if (source > 0) {
				if (source < 0x20) {
					//Shift the register data right arithmetically:
					parentObj.CPUCore.CPSRCarry = (((destination >> (source - 1)) & 0x1) == 0x1);
					destination >>= source;
				}
				else {
					//Set all bits with bit 31:
					parentObj.CPUCore.CPSRCarry = (destination < 0);
					destination >>= 0x1F;
				}
			}
			//Perform CPSR updates for N and Z (But not V):
			parentObj.CPUCore.CPSRNegative = (destination < 0);
			parentObj.CPUCore.CPSRZero = (destination == 0);
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = destination | 0;
		}
		public function ADC(parentObj) {
			Logger.logTHUMB("THUMB ADC");
			var operand1 = parentObj.registers[parentObj.execute & 0x7] | 0;
			var operand2 = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = parentObj.CPUCore.setADCFlags(operand1 | 0, operand2 | 0) | 0;
		}
		public function SBC(parentObj) {
			Logger.logTHUMB("THUMB SBC");
			var operand1 = parentObj.registers[parentObj.execute & 0x7] | 0;
			var operand2 = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = parentObj.CPUCore.setSBCFlags(operand1 | 0, operand2 | 0) | 0;
		}
		public function ROR(parentObj) {
			Logger.logTHUMB("THUMB ROR");
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] & 0xFF;
			var destination = parentObj.registers[parentObj.execute & 0x7] | 0;
			if (source > 0) {
				source &= 0x1F;
				if (source > 0) {
					//CPSR Carry is set by the last bit shifted out:
					parentObj.CPUCore.CPSRCarry = (((destination >>> (source - 1)) & 0x1) != 0);
					//Perform rotate:
					destination = (destination << (0x20 - source)) | (destination >>> source);
				}
				else {
					parentObj.CPUCore.CPSRCarry = (destination < 0);
				}
			}
			//Perform CPSR updates for N and Z (But not V):
			parentObj.CPUCore.CPSRNegative = (destination < 0);
			parentObj.CPUCore.CPSRZero = (destination == 0);
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = destination | 0;
		}
		public function TST(parentObj) {
			Logger.logTHUMB("THUMB TST");
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var destination = parentObj.registers[parentObj.execute & 0x7] | 0;
			//Perform bitwise AND:
			var result = source & destination;
			parentObj.CPUCore.CPSRNegative = (result < 0);
			parentObj.CPUCore.CPSRZero = (result == 0);
		}
		public function NEG(parentObj) {
			Logger.logTHUMB("THUMB NEG");
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			parentObj.CPUCore.CPSROverflow = ((source ^ (-source)) == 0);
			//Perform Subtraction:
			source = (-source) | 0;
			parentObj.CPUCore.CPSRNegative = (source < 0);
			parentObj.CPUCore.CPSRZero = (source == 0);
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = source | 0;
		}
		public function CMP(parentObj) {
			Logger.logTHUMB("THUMB CMP");
			//Compare two registers:
			var operand1 = parentObj.registers[parentObj.execute & 0x7] | 0;
			var operand2 = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			parentObj.CPUCore.setCMPFlags(operand1 | 0, operand2 | 0);
		}
		public function CMN(parentObj) {
			Logger.logTHUMB("THUMB CMN");
			//Compare two registers:
			var operand1 = parentObj.registers[parentObj.execute & 0x7] | 0;
			var operand2 = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			parentObj.CPUCore.setCMNFlags(operand1 | 0, operand2 | 0);
		}
		public function ORR(parentObj) {
			Logger.logTHUMB("THUMB ORR");
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var destination = parentObj.registers[parentObj.execute & 0x7] | 0;
			//Perform bitwise ORR:
			var result = source | destination;
			parentObj.CPUCore.CPSRNegative = (result < 0);
			parentObj.CPUCore.CPSRZero = (result == 0);
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = result | 0;
		}
		public function MUL(parentObj) {
			Logger.logTHUMB("THUMB MUL");
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var destination = parentObj.registers[parentObj.execute & 0x7] | 0;
			//Perform MUL32:
			var result = parentObj.CPUCore.performMUL32(source | 0, destination | 0, 0);
			parentObj.CPUCore.CPSRCarry = false;
			parentObj.CPUCore.CPSRNegative = (result < 0);
			parentObj.CPUCore.CPSRZero = (result == 0);
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = result | 0;
		}
		public function BIC(parentObj) {
			Logger.logTHUMB("THUMB BIC");
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var destination = parentObj.registers[parentObj.execute & 0x7] | 0;
			//Perform bitwise AND with a bitwise NOT on source:
			var result = (~source) & destination;
			parentObj.CPUCore.CPSRNegative = (result < 0);
			parentObj.CPUCore.CPSRZero = (result == 0);
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = result | 0;
		}
		public function MVN(parentObj) {
			Logger.logTHUMB("THUMB MVN");
			//Perform bitwise NOT on source:
			var source = ~parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			parentObj.CPUCore.CPSRNegative = (source < 0);
			parentObj.CPUCore.CPSRZero = (source == 0);
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = source | 0;
		}
		public function ADDH_LL(parentObj) {
			Logger.logTHUMB("THUMB ADDH_LL");
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var destination = parentObj.registers[parentObj.execute & 0x7] | 0;
			//Perform Addition:
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = (source + destination) | 0;
		}
		public function ADDH_LH(parentObj) {
			Logger.logTHUMB("THUMB ADDH_LH");
			var source = parentObj.registers[0x8 | ((parentObj.execute >> 3) & 0x7)] | 0;
			var destination = parentObj.registers[parentObj.execute & 0x7] | 0;
			//Perform Addition:
			//Update destination register:
			parentObj.registers[parentObj.execute & 0x7] = (source + destination) | 0;
		}
		public function ADDH_HL(parentObj) {
			Logger.logTHUMB("THUMB ADDH_HL");
			var source = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			var destination = parentObj.registers[0x8 | (parentObj.execute & 0x7)] | 0;
			//Perform Addition:
			//Update destination register:
			parentObj.guardHighRegisterWrite((source + destination) | 0);
		}
		public function ADDH_HH(parentObj) {
			Logger.logTHUMB("THUMB ADDH_HH");
			var source = parentObj.registers[0x8 | ((parentObj.execute >> 3) & 0x7)] | 0;
			var destination = parentObj.registers[0x8 | (parentObj.execute & 0x7)] | 0;
			//Perform Addition:
			//Update destination register:
			parentObj.guardHighRegisterWrite((source + destination) | 0);
		}
		public function CMPH_LL(parentObj) {
			Logger.logTHUMB("THUMB CMPH_LL");
			//Compare two registers:
			var operand1 = parentObj.registers[parentObj.execute & 0x7] | 0;
			var operand2 = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			parentObj.CPUCore.setCMPFlags(operand1 | 0, operand2 | 0);
		}
		public function CMPH_LH(parentObj) {
			Logger.logTHUMB("THUMB CMPH_LH");
			//Compare two registers:
			var operand1 = parentObj.registers[parentObj.execute & 0x7] | 0;
			var operand2 = parentObj.registers[0x8 | ((parentObj.execute >> 3) & 0x7)] | 0;
			parentObj.CPUCore.setCMPFlags(operand1 | 0, operand2 | 0);
		}
		public function CMPH_HL(parentObj) {
			Logger.logTHUMB("THUMB CMPH_HL");
			//Compare two registers:
			var operand1 = parentObj.registers[0x8 | (parentObj.execute & 0x7)] | 0;
			var operand2 = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			parentObj.CPUCore.setCMPFlags(operand1 | 0, operand2 | 0);
		}
		public function CMPH_HH(parentObj) {
			Logger.logTHUMB("THUMB CMPH_HH");
			//Compare two registers:
			var operand1 = parentObj.registers[0x8 | (parentObj.execute & 0x7)] | 0;
			var operand2 = parentObj.registers[0x8 | ((parentObj.execute >> 3) & 0x7)] | 0;
			parentObj.CPUCore.setCMPFlags(operand1 | 0, operand2 | 0);
		}
		public function MOVH_LL(parentObj) {
			Logger.logTHUMB("THUMB MOVH_LL");
			//Move a register to another register:
			parentObj.registers[parentObj.execute & 0x7] = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
		}
		public function MOVH_LH(parentObj) {
			Logger.logTHUMB("THUMB MOVH_LH");
			//Move a register to another register:
			parentObj.registers[parentObj.execute & 0x7] = parentObj.registers[0x8 | ((parentObj.execute >> 3) & 0x7)] | 0;
		}
		public function MOVH_HL(parentObj) {
			Logger.logTHUMB("THUMB MOVH_HL");
			//Move a register to another register:
			parentObj.guardHighRegisterWrite(parentObj.registers[(parentObj.execute >> 3) & 0x7]);
		}
		public function MOVH_HH(parentObj) {
			Logger.logTHUMB("THUMB MOVH_HH");
			//Move a register to another register:
			parentObj.guardHighRegisterWrite(parentObj.registers[0x8 | ((parentObj.execute >> 3) & 0x7)]);
		}
		public function BX_L(parentObj) {
			Logger.logTHUMB("THUMB BX_L");
			//Branch & eXchange:
			var address = parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0;
			if ((address & 0x1) == 0) {
				//Enter ARM mode:
				parentObj.CPUCore.enterARM();
				parentObj.CPUCore.branch(address & -0x4);
			}
			else {
				//Stay in THUMB mode:
				parentObj.CPUCore.branch(address & -0x2);
			}
		}
		public function BX_H(parentObj) {
			Logger.logTHUMB("THUMB BX_H");
			//Branch & eXchange:
			var address = parentObj.registers[0x8 | ((parentObj.execute >> 3) & 0x7)] | 0;
			if ((address & 0x1) == 0) {
				//Enter ARM mode:
				parentObj.CPUCore.enterARM();
				parentObj.CPUCore.branch(address & -0x4);
			}
			else {
				//Stay in THUMB mode:
				parentObj.CPUCore.branch(address & -0x2);
			}
		}
		public function LDRPC(parentObj) {
			Logger.logTHUMB("THUMB LDRPC");
			//PC-Relative Load
			var result = parentObj.CPUCore.read32(((parentObj.registers[15] & -3) + ((parentObj.execute & 0xFF) << 2)) | 0) | 0;
			parentObj.registers[(parentObj.execute >> 8) & 0x7] = result | 0;
		}
		public function STRreg(parentObj) {
			Logger.logTHUMB("THUMB STRreg");
			//Store Word From Register
			parentObj.CPUCore.write32(((parentObj.registers[(parentObj.execute >> 6) & 0x7] | 0) + (parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0)) | 0, parentObj.registers[parentObj.execute & 0x7] | 0);
		}
		public function STRHreg(parentObj) {
			Logger.logTHUMB("THUMB STRHreg");
			//Store Hald-Word From Register
			parentObj.CPUCore.write16(((parentObj.registers[(parentObj.execute >> 6) & 0x7] | 0) + (parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0)) | 0, parentObj.registers[parentObj.execute & 0x7] | 0);
		}
		public function STRBreg(parentObj) {
			Logger.logTHUMB("THUMB STRBreg");
			//Store Byte From Register
			parentObj.CPUCore.write8(((parentObj.registers[(parentObj.execute >> 6) & 0x7] | 0) + (parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0)) | 0, parentObj.registers[parentObj.execute & 0x7] | 0);
		}
		public function LDRSBreg(parentObj) {
			Logger.logTHUMB("THUMB LDRSBreg");
			//Load Signed Byte Into Register
			parentObj.registers[parentObj.execute & 0x7] = (parentObj.CPUCore.read8(((parentObj.registers[(parentObj.execute >> 6) & 0x7] | 0) + (parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0)) | 0) << 24) >> 24;
		}
		public function LDRreg(parentObj) {
			Logger.logTHUMB("THUMB LDRreg");
			//Load Word Into Register
			parentObj.registers[parentObj.execute & 0x7] = parentObj.CPUCore.read32(((parentObj.registers[(parentObj.execute >> 6) & 0x7] | 0) + (parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0)) | 0) | 0;
		}
		public function LDRHreg(parentObj) {
			Logger.logTHUMB("THUMB LDRHreg");
			//Load Half-Word Into Register
			parentObj.registers[parentObj.execute & 0x7] = parentObj.CPUCore.read16(((parentObj.registers[(parentObj.execute >> 6) & 0x7] | 0) + (parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0)) | 0) | 0;
		}
		public function LDRBreg(parentObj) {
			Logger.logTHUMB("THUMB LDRBreg");
			//Load Byte Into Register
			parentObj.registers[parentObj.execute & 0x7] = parentObj.CPUCore.read8(((parentObj.registers[(parentObj.execute >> 6) & 0x7] | 0) + (parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0)) | 0) | 0;
		}
		public function LDRSHreg(parentObj) {
			Logger.logTHUMB("THUMB LDRSHreg");
			//Load Signed Half-Word Into Register
			parentObj.registers[parentObj.execute & 0x7] = (parentObj.CPUCore.read16(((parentObj.registers[(parentObj.execute >> 6) & 0x7] | 0) + (parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0)) | 0) << 16) >> 16;
		}
		public function STRimm5(parentObj) {
			Logger.logTHUMB("THUMB STRimm5");
			//Store Word From Register
			parentObj.CPUCore.write32(((((parentObj.execute >> 6) & 0x1F) << 2) + (parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0)) | 0, parentObj.registers[parentObj.execute & 0x7] | 0);
		}
		public function LDRimm5(parentObj) {
			Logger.logTHUMB("THUMB LDRimm5");
			//Load Word Into Register
			parentObj.registers[parentObj.execute & 0x7] = parentObj.CPUCore.read32(((((parentObj.execute >> 6) & 0x1F) << 2) + (parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0)) | 0) | 0;
		}
		public function STRBimm5(parentObj) {
			Logger.logTHUMB("THUMB STRBimm5");
			//Store Byte From Register
			parentObj.CPUCore.write8((((parentObj.execute >> 6) & 0x1F) + (parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0)) | 0, parentObj.registers[parentObj.execute & 0x7] | 0);
		}
		public function LDRBimm5(parentObj) {
			Logger.logTHUMB("THUMB LDRBimm5");
			//Load Byte Into Register
			parentObj.registers[parentObj.execute & 0x7] = parentObj.CPUCore.read8((((parentObj.execute >> 6) & 0x1F) + (parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0)) | 0) | 0;
		}
		public function STRHimm5(parentObj) {
			Logger.logTHUMB("THUMB STRHimm5");
			//Store Half-Word From Register
			parentObj.CPUCore.write16(((((parentObj.execute >> 6) & 0x1F) << 1) + (parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0)) | 0, parentObj.registers[parentObj.execute & 0x7] | 0);
		}
		public function LDRHimm5(parentObj) {
			Logger.logTHUMB("THUMB LDRHimm5");
			//Load Half-Word Into Register
			parentObj.registers[parentObj.execute & 0x7] = parentObj.CPUCore.read16(((((parentObj.execute >> 6) & 0x1F) << 1) + (parentObj.registers[(parentObj.execute >> 3) & 0x7] | 0)) | 0) | 0;
		}
		public function STRSP(parentObj) {
			Logger.logTHUMB("THUMB STRSP");
			//Store Word From Register
			parentObj.CPUCore.write32((((parentObj.execute & 0xFF) << 2) + (parentObj.registers[13] | 0)) | 0, parentObj.registers[(parentObj.execute >> 8) & 0x7] | 0);
		}
		public function LDRSP(parentObj) {
			Logger.logTHUMB("THUMB LDRSP");
			//Load Word Into Register
			parentObj.registers[(parentObj.execute >> 8) & 0x7] = parentObj.CPUCore.read32(((parentObj.execute & 0xFF) << 2) + (parentObj.registers[13] | 0)) | 0;
		}
		public function ADDPC(parentObj) {
			Logger.logTHUMB("THUMB ADDPC");
			//Add PC With Offset Into Register
			parentObj.registers[(parentObj.execute >> 8) & 0x7] = ((parentObj.registers[15] & -3) + ((parentObj.execute & 0xFF) << 2)) | 0;
		}
		public function ADDSP(parentObj) {
			Logger.logTHUMB("THUMB ADDSP");
			//Add SP With Offset Into Register
			parentObj.registers[(parentObj.execute >> 8) & 0x7] = (((parentObj.execute & 0xFF) << 2) + (parentObj.registers[13] | 0)) | 0;
		}
		public function ADDSPimm7(parentObj) {
			Logger.logTHUMB("THUMB ADDSPimm7");
			//Add Signed Offset Into SP
			if ((parentObj.execute & 0x80) != 0) {
				parentObj.registers[13] = ((parentObj.registers[13] | 0) - ((parentObj.execute & 0x7F) << 2)) | 0;
			}
			else {
				parentObj.registers[13] = ((parentObj.registers[13] | 0) + ((parentObj.execute & 0x7F) << 2)) | 0;
			}
		}
		public function PUSH(parentObj) {
			Logger.logTHUMB("THUMB PUSH");
			//Only initialize the PUSH sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFF) > 0) {
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Push register(s) onto the stack:
				for (var rListPosition = 7; (rListPosition | 0) > -1; rListPosition = (rListPosition - 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Push register onto the stack:
						parentObj.registers[13] = (parentObj.registers[13] - 4) | 0;
						parentObj.memory.memoryWrite32(parentObj.registers[13] >>> 0, parentObj.registers[rListPosition | 0] | 0);
					}
				}
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function PUSHlr(parentObj) {
			Logger.logTHUMB("THUMB PUSHlr");
			//Updating the address bus away from PC fetch:
			parentObj.wait.NonSequentialBroadcast();
			//Push link register onto the stack:
			parentObj.registers[13] = (parentObj.registers[13] - 4) | 0;
			parentObj.IOCore.memory.memoryWrite32(parentObj.registers[13] >>> 0, parentObj.registers[14] | 0);
			//Push register(s) onto the stack:
			for (var rListPosition = 7; (rListPosition | 0) > -1; rListPosition = (rListPosition - 1) | 0) {
				if ((parentObj.execute & (1 << rListPosition)) != 0) {
					//Push register onto the stack:
					parentObj.registers[13] = (parentObj.registers[13] - 4) | 0;
					parentObj.memory.memoryWrite32(parentObj.registers[13] >>> 0, parentObj.registers[rListPosition | 0] | 0);
				}
			}
			//Updating the address bus back to PC fetch:
			parentObj.wait.NonSequentialBroadcast();
		}
		public function POP(parentObj) {
			Logger.logTHUMB("THUMB POP");
			//Only initialize the POP sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFF) > 0) {
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//POP stack into register(s):
				for (var rListPosition = 0; (rListPosition | 0) < 8; rListPosition = (rListPosition + 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//POP stack into a register:
						parentObj.registers[rListPosition | 0] = parentObj.memory.memoryRead32(parentObj.registers[13] >>> 0) | 0;
						parentObj.registers[13] = (parentObj.registers[13] + 4) | 0;
					}
				}
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function POPpc(parentObj) {
			Logger.logTHUMB("THUMB POPpc");
			//Updating the address bus away from PC fetch:
			parentObj.wait.NonSequentialBroadcast();
			//POP stack into register(s):
			for (var rListPosition = 0; (rListPosition | 0) < 8; rListPosition = (rListPosition + 1) | 0) {
				if ((parentObj.execute & (1 << rListPosition)) != 0) {
					//POP stack into a register:
					parentObj.registers[rListPosition | 0] = parentObj.memory.memoryRead32(parentObj.registers[13] >>> 0) | 0;
					parentObj.registers[13] = (parentObj.registers[13] + 4) | 0;
				}
			}
			//POP stack into the program counter (r15):
			parentObj.writePC(parentObj.memory.memoryRead32(parentObj.registers[13] >>> 0) | 0);
			parentObj.registers[13] = (parentObj.registers[13] + 4) | 0;
			//Updating the address bus back to PC fetch:
			parentObj.wait.NonSequentialBroadcast();
		}
		public function STMIA(parentObj) {
			Logger.logTHUMB("THUMB STMIA");
			//Only initialize the STMIA sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.registers[(parentObj.execute >> 8) & 0x7] | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Push register(s) into memory:
				for (var rListPosition = 0; (rListPosition | 0) < 8; rListPosition = (rListPosition + 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Push a register into memory:
						parentObj.memory.memoryWrite32(currentAddress >>> 0, parentObj.registers[rListPosition | 0] | 0);
						currentAddress = (currentAddress + 4) | 0;
					}
				}
				//Store the updated base address back into register:
				parentObj.registers[(parentObj.execute >> 8) & 0x7] = currentAddress | 0;
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function LDMIA(parentObj) {
			Logger.logTHUMB("THUMB LDMIA");
			//Only initialize the LDMIA sequence if the register list is non-empty:
			if ((parentObj.execute & 0xFF) > 0) {
				//Get the base address:
				var currentAddress = parentObj.registers[(parentObj.execute >> 8) & 0x7] | 0;
				//Updating the address bus away from PC fetch:
				parentObj.wait.NonSequentialBroadcast();
				//Load  register(s) from memory:
				for (var rListPosition = 0; (rListPosition | 0) < 8; rListPosition = (rListPosition + 1) | 0) {
					if ((parentObj.execute & (1 << rListPosition)) != 0) {
						//Load a register from memory:
						parentObj.registers[rListPosition | 0] = parentObj.memory.memoryRead32(currentAddress >>> 0) | 0;
						currentAddress = (currentAddress + 4) | 0;
					}
				}
				//Store the updated base address back into register:
				parentObj.registers[(parentObj.execute >> 8) & 0x7] = currentAddress | 0;
				//Updating the address bus back to PC fetch:
				parentObj.wait.NonSequentialBroadcast();
			}
		}
		public function BEQ(parentObj) {
			Logger.logTHUMB("THUMB BEQ");
			//Branch if EQual:
			if (parentObj.CPUCore.CPSRZero) {
				parentObj.offsetPC(parentObj.execute | 0);
			}
		}
		public function BNE(parentObj) {
			Logger.logTHUMB("THUMB BNE");
			//Branch if Not Equal:
			if (!parentObj.CPUCore.CPSRZero) {
				parentObj.offsetPC(parentObj.execute | 0);
			}
		}
		public function BCS(parentObj) {
			Logger.logTHUMB("THUMB BCS");
			//Branch if Carry Set:
			if (parentObj.CPUCore.CPSRCarry) {
				parentObj.offsetPC(parentObj.execute | 0);
			}
		}
		public function BCC(parentObj) {
			Logger.logTHUMB("THUMB BCC");
			//Branch if Carry Clear:
			if (!parentObj.CPUCore.CPSRCarry) {
				parentObj.offsetPC(parentObj.execute | 0);
			}
		}
		public function BMI(parentObj) {
			Logger.logTHUMB("THUMB BMI");
			//Branch if Negative Set:
			if (parentObj.CPUCore.CPSRNegative) {
				parentObj.offsetPC(parentObj.execute | 0);
			}
		}
		public function BPL(parentObj) {
			Logger.logTHUMB("THUMB BPL");
			//Branch if Negative Clear:
			if (!parentObj.CPUCore.CPSRNegative) {
				parentObj.offsetPC(parentObj.execute | 0);
			}
		}
		public function BVS(parentObj) {
			Logger.logTHUMB("THUMB BVS");
			//Branch if Overflow Set:
			if (parentObj.CPUCore.CPSROverflow) {
				parentObj.offsetPC(parentObj.execute | 0);
			}
		}
		public function BVC(parentObj) {
			Logger.logTHUMB("THUMB BVC");
			//Branch if Overflow Clear:
			if (!parentObj.CPUCore.CPSROverflow) {
				parentObj.offsetPC(parentObj.execute | 0);
			}
		}
		public function BHI(parentObj) {
			Logger.logTHUMB("THUMB BHI");
			//Branch if Carry & Non-Zero:
			if (parentObj.CPUCore.CPSRCarry && !parentObj.CPUCore.CPSRZero) {
				parentObj.offsetPC(parentObj.execute | 0);
			}
		}
		public function BLS(parentObj) {
			Logger.logTHUMB("THUMB BLS");
			//Branch if Carry Clear or is Zero Set:
			if (!parentObj.CPUCore.CPSRCarry || parentObj.CPUCore.CPSRZero) {
				parentObj.offsetPC(parentObj.execute | 0);
			}
		}
		public function BGE(parentObj) {
			Logger.logTHUMB("THUMB BGE");
			//Branch if Negative equal to Overflow
			if (parentObj.CPUCore.CPSRNegative == parentObj.CPUCore.CPSROverflow) {
				parentObj.offsetPC(parentObj.execute | 0);
			}
		}
		public function BLT(parentObj) {
			Logger.logTHUMB("THUMB BLT");
			//Branch if Negative NOT equal to Overflow
			if (parentObj.CPUCore.CPSRNegative != parentObj.CPUCore.CPSROverflow) {
				parentObj.offsetPC(parentObj.execute | 0);
			}
		}
		public function BGT(parentObj) {
			Logger.logTHUMB("THUMB BGT");
			//Branch if Zero Clear and Negative equal to Overflow
			if (!parentObj.CPUCore.CPSRZero && parentObj.CPUCore.CPSRNegative == parentObj.CPUCore.CPSROverflow) {
				parentObj.offsetPC(parentObj.execute | 0);
			}
		}
		public function BLE(parentObj) {
			Logger.logTHUMB("THUMB BLE");
			//Branch if Zero Set or Negative NOT equal to Overflow
			if (parentObj.CPUCore.CPSRZero || parentObj.CPUCore.CPSRNegative != parentObj.CPUCore.CPSROverflow) {
				parentObj.offsetPC(parentObj.execute | 0);
			}
		}
		public function SWI(parentObj) {
			Logger.logTHUMB("THUMB SWI");
			//Software Interrupt:
			parentObj.CPUCore.SWI();
		}
		public function B(parentObj) {
			Logger.logTHUMB("THUMB B");
			//Unconditional Branch:
			//Update the program counter to branch address:
			parentObj.CPUCore.branch((parentObj.registers[15] + ((parentObj.execute << 21) >> 20)) | 0);
		}
		public function BLsetup(parentObj) {
			//Brank with Link (High offset)
			//Update the link register to branch address:
			parentObj.registers[14] = (parentObj.registers[15] + (((parentObj.execute & 0x7FF) << 21) >> 9)) | 0;
		}
		public function BLoff(parentObj) {
			//Brank with Link (Low offset)
			//Update the link register to branch address:
			parentObj.registers[14] = (parentObj.registers[14] + ((parentObj.execute & 0x7FF) << 1)) | 0;
			//Copy LR to PC:
			var oldPC = parentObj.registers[15] | 0;
			//Flush Pipeline & Block PC Increment:
			parentObj.CPUCore.branch(parentObj.registers[14] & -0x2);
			//Set bit 0 of LR high:
			parentObj.registers[14] = (oldPC - 0x2) | 0x1;
		}
		public function UNDEFINED(parentObj) {
			Logger.logTHUMB("THUMB UNDEFINED");
			//Undefined Exception:
			parentObj.CPUCore.UNDEFINED();
		}
		public function compileInstructionMap() {
			this.instructionMap = [];
			//0-7
			this.generateLowMap(this.LSLimm);
			//8-F
			this.generateLowMap(this.LSRimm);
			//10-17
			this.generateLowMap(this.ASRimm);
			//18-19
			this.generateLowMap2(this.ADDreg);
			//1A-1B
			this.generateLowMap2(this.SUBreg);
			//1C-1D
			this.generateLowMap2(this.ADDimm3);
			//1E-1F
			this.generateLowMap2(this.SUBimm3);
			//20-27
			this.generateLowMap(this.MOVimm8);
			//28-2F
			this.generateLowMap(this.CMPimm8);
			//30-37
			this.generateLowMap(this.ADDimm8);
			//38-3F
			this.generateLowMap(this.SUBimm8);
			//40
			this.generateLowMap4(this.AND, this.EOR, this.LSL, this.LSR);
			//41
			this.generateLowMap4(this.ASR, this.ADC, this.SBC, this.ROR);
			//42
			this.generateLowMap4(this.TST, this.NEG, this.CMP, this.CMN);
			//43
			this.generateLowMap4(this.ORR, this.MUL, this.BIC, this.MVN);
			//44
			this.generateLowMap4(this.ADDH_LL, this.ADDH_LH, this.ADDH_HL, this.ADDH_HH);
			//45
			this.generateLowMap4(this.CMPH_LL, this.CMPH_LH, this.CMPH_HL, this.CMPH_HH);
			//46
			this.generateLowMap4(this.MOVH_LL, this.MOVH_LH, this.MOVH_HL, this.MOVH_HH);
			//47
			this.generateLowMap4(this.BX_L, this.BX_H, this.BX_L, this.BX_H);
			//48-4F
			this.generateLowMap(this.LDRPC);
			//50-51
			this.generateLowMap2(this.STRreg);
			//52-53
			this.generateLowMap2(this.STRHreg);
			//54-55
			this.generateLowMap2(this.STRBreg);
			//56-57
			this.generateLowMap2(this.LDRSBreg);
			//58-59
			this.generateLowMap2(this.LDRreg);
			//5A-5B
			this.generateLowMap2(this.LDRHreg);
			//5C-5D
			this.generateLowMap2(this.LDRBreg);
			//5E-5F
			this.generateLowMap2(this.LDRSHreg);
			//60-67
			this.generateLowMap(this.STRimm5);
			//68-6F
			this.generateLowMap(this.LDRimm5);
			//70-77
			this.generateLowMap(this.STRBimm5);
			//78-7F
			this.generateLowMap(this.LDRBimm5);
			//80-87
			this.generateLowMap(this.STRHimm5);
			//88-8F
			this.generateLowMap(this.LDRHimm5);
			//90-97
			this.generateLowMap(this.STRSP);
			//98-9F
			this.generateLowMap(this.LDRSP);
			//A0-A7
			this.generateLowMap(this.ADDPC);
			//A8-AF
			this.generateLowMap(this.ADDSP);
			//B0
			this.generateLowMap3(this.ADDSPimm7);
			//B1
			this.generateLowMap3(this.UNDEFINED);
			//B2
			this.generateLowMap3(this.UNDEFINED);
			//B3
			this.generateLowMap3(this.UNDEFINED);
			//B4
			this.generateLowMap3(this.PUSH);
			//B5
			this.generateLowMap3(this.PUSHlr);
			//B6
			this.generateLowMap3(this.UNDEFINED);
			//B7
			this.generateLowMap3(this.UNDEFINED);
			//B8
			this.generateLowMap3(this.UNDEFINED);
			//B9
			this.generateLowMap3(this.UNDEFINED);
			//BA
			this.generateLowMap3(this.UNDEFINED);
			//BB
			this.generateLowMap3(this.UNDEFINED);
			//BC
			this.generateLowMap3(this.POP);
			//BD
			this.generateLowMap3(this.POPpc);
			//BE
			this.generateLowMap3(this.UNDEFINED);
			//BF
			this.generateLowMap3(this.UNDEFINED);
			//C0-C7
			this.generateLowMap(this.STMIA);
			//C8-CF
			this.generateLowMap(this.LDMIA);
			//D0
			this.generateLowMap3(this.BEQ);
			//D1
			this.generateLowMap3(this.BNE);
			//D2
			this.generateLowMap3(this.BCS);
			//D3
			this.generateLowMap3(this.BCC);
			//D4
			this.generateLowMap3(this.BMI);
			//D5
			this.generateLowMap3(this.BPL);
			//D6
			this.generateLowMap3(this.BVS);
			//D7
			this.generateLowMap3(this.BVC);
			//D8
			this.generateLowMap3(this.BHI);
			//D9
			this.generateLowMap3(this.BLS);
			//DA
			this.generateLowMap3(this.BGE);
			//DB
			this.generateLowMap3(this.BLT);
			//DC
			this.generateLowMap3(this.BGT);
			//DD
			this.generateLowMap3(this.BLE);
			//DE
			this.generateLowMap3(this.UNDEFINED);
			//DF
			this.generateLowMap3(this.SWI);
			//E0-E7
			this.generateLowMap(this.B);
			//E8-EF
			this.generateLowMap(this.UNDEFINED);
			//F0-F7
			this.generateLowMap(this.BLsetup);
			//F8-FF
			this.generateLowMap(this.BLoff);
		}
		public function generateLowMap(instruction) {
			for (var index = 0; index < 0x20; ++index) {
				this.instructionMap.push(instruction);
			}
		}
		public function generateLowMap2(instruction) {
			for (var index = 0; index < 0x8; ++index) {
				this.instructionMap.push(instruction);
			}
		}
		public function generateLowMap3(instruction) {
			for (var index = 0; index < 0x4; ++index) {
				this.instructionMap.push(instruction);
			}
		}
		public function generateLowMap4(instruction1, instruction2, instruction3, instruction4) {
			this.instructionMap.push(instruction1);
			this.instructionMap.push(instruction2);
			this.instructionMap.push(instruction3);
			this.instructionMap.push(instruction4);
		}
		
		
		
		
		
	}
	
}
