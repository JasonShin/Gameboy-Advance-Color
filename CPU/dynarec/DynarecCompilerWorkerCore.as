package CPU.dynarec {
	
	public class DynarecCompilerWorkerCore {

		public function DynarecCompilerWorkerCore() {
			// constructor code
			this.instructionsToJoin = [];
			this.startPC = startPC;
			this.record = record;
			this.InTHUMB = InTHUMB;
			this.CPUMode = CPUMode;
			this.isROM = isROM;
			this.forceSyncGuard = false;
			if (this.InTHUMB) {
				this.compiler = new DynarecTHUMBAssemblerCore(this, startPC, waitstates);
			}
			else {
				bailout();
				this.compiler = null;
			}
			this.compile();
			this.finish(false);
			
		}
		
		public function compile() {
			var length = Math.max(this.record.length - 1, 0);
			for (this.currentRecordOffset = 0; this.currentRecordOffset < length; ++this.currentRecordOffset) {
				this.execute = this.record[this.currentRecordOffset];
				this.decode = this.record[this.currentRecordOffset + 1];
				this.appendCompiledInstruction(this.compiler.generate(this.execute));
			}
			this.execute = this.record[this.currentRecordOffset];
			this.decode = this.record[this.currentRecordOffset + 1];
		}
		
		public function appendCompiledInstruction(instruction) {
			this.instructionsToJoin.push(instruction);
			if (this.forceSyncGuard) {
				//guard reads and writes due to their unknown timing:
				this.finish(true);
			}
		}
		
		public function read16(address) {
			if (address >= 0x8000000 && address < 0xE000000) {
				return "this.CPUCore.IOCore.cartridge.readROM16(" + (address & 0x1FFFFFF) + ") | 0";
			}
			else if (address >= 0x3000000 && address < 0x4000000) {
				return "this.CPUCore.IOCore.memory.externalRAM[" + (address & 0x3FFFF) + "] | (this.CPUCore.IOCore.memory.externalRAM[" + ((address & 0x3FFFF) | 1) + "] << 8)";
			}
			else if (address >= 0x2000000 && address < 0x3000000) {
				return "this.CPUCore.IOCore.memory.internalRAM[" + (address & 0x7FFF) + "] | (this.CPUCore.IOCore.memory.internalRAM[" + ((address & 0x7FFF) | 1) + "] << 8)";
			}
			else if (address >= 0x20 && address < 0x4000) {
				return "this.CPUCore.IOCore.memory.BIOS[" + address + "] | (this.CPUCore.IOCore.memory.BIOS[" + (address | 1) + "] << 8)";
			}
			else {
				bailout();
			}
		}
		
		public function read32(address) {
			if (address >= 0x8000000 && address < 0xE000000) {
				return "this.CPUCore.IOCore.cartridge.readROM32(" + (address & 0x1FFFFFF) + ") | 0";
			}
			else if (address >= 0x3000000 && address < 0x4000000) {
				return "this.CPUCore.IOCore.memory.externalRAM[" + (address & 0x3FFFF) + "] | (this.CPUCore.IOCore.memory.externalRAM[" + ((address & 0x3FFFF) | 1) + "] << 8) | (this.CPUCore.IOCore.memory.externalRAM[" + ((address & 0x3FFFF) | 2) + "] << 16)  | (this.CPUCore.IOCore.memory.externalRAM[" + ((address & 0x3FFFF) | 3) + "] << 24)";
			}
			else if (address >= 0x2000000 && address < 0x3000000) {
				return "this.CPUCore.IOCore.memory.internalRAM[" + (address & 0x7FFF) + "] | (this.CPUCore.IOCore.memory.internalRAM[" + ((address & 0x7FFF) | 1) + "] << 8) | (this.CPUCore.IOCore.memory.internalRAM[" + ((address & 0x7FFF) | 2) + "] << 16)  | (this.CPUCore.IOCore.memory.internalRAM[" + ((address & 0x7FFF) | 3) + "] << 24)";
			}
			else if (address >= 0x20 && address < 0x4000) {
				return "this.CPUCore.IOCore.memory.BIOS[" + address + "] | (this.CPUCore.IOCore.memory.BIOS[" + (address | 1) + "] << 8) | (this.CPUCore.IOCore.memory.BIOS[" + (address | 2) + "] << 16)  | (this.CPUCore.IOCore.memory.BIOS[" + (address | 3) + "] << 24)";
			}
			else {
				bailout();
			}
		}
		public function addMemoryRead(pc) {
			if (this.InTHUMB) {
				return this.read16(pc);
			}
			else {
				return this.read32(pc);
			}
		}
		public function addRAMGuards(instructionValue, instructionCode) {
			if (this.isROM) {
				return instructionCode;
			}
			var guardText = "/*RAM guard check*/\n";
			guardText += "cpu.instructionHandle.fetch = " +  this.addMemoryRead(this.compiler.getPipelinePC()) + ";\n";
			guardText += "if (cpu.instructionHandle.execute != " + instructionValue + ") {\n";
			guardText += "\tcpu.pipelineInvalid = 0;\n";
			guardText += "\tcpu.IOCore.updateCore(" + this.compiler.clocks + ");\n";
			guardText += "\treturn false;\n";
			guardText += "}\n";
			guardText += instructionCode;
			guardText += "cpu.instructionHandle.execute = cpu.instructionHandle.decode | 0;\n";
			guardText += "cpu.instructionHandle.decode = cpu.instructionHandle.fetch | 0;\n";
			return guardText;
		}
		public function addClockChecks() {
			return "if (cpu.triggeredIRQ || cpu.IOCore.cyclesUntilNextEvent() < " + this.compiler.clocks + ") {\n\treturn false;\n}\n";
		}
		public function finish(didBranch) {
			var code = this.addClockChecks();
			code += this.instructionsToJoin.join("");
			code += "\tcpu.pipelineInvalid = 0;\n";
			code += "\tcpu.IOCore.updateCore(" + this.compiler.clocks + ");\n";
			if (didBranch) {
				code += "\treturn true;\n";
			}
			else {
				code += "\tcpu.registers[15] = " + this.compiler.getPipelinePC() + " | 0;\n";
				if (this.isROM) {
					code += "\tcpu.instructionHandle.execute = " + this.execute + " | 0;\n";
					code += "\tcpu.instructionHandle.decode = " + this.decode + " | 0;\n";
				}
				code += "\treturn false;\n";
			}
			
			done(code);
		}
		
		

	}
	
}
