package  {
	import utils.MathsHelper;
	
	public class GameBoyAdvanceTimer {

		
		public var timer0Counter = 0;
		public var timer0Reload = 0;
		public var timer0Control = 0;
		public var timer0Enabled = false;
		public var timer0IRQ = false;
		public var timer0Precounter = 0;
		public var timer0Prescalar = 1;
		public var timer1Counter = 0;
		public var timer1Reload = 0;
		public var timer1Control = 0;
		public var timer1Enabled = false;
		public var timer1IRQ = false;
		public var timer1Precounter = 0;
		public var timer1Prescalar = 1;
		public var timer1CountUp = false;
		public var timer2Counter = 0;
		public var timer2Reload = 0;
		public var timer2Control = 0;
		public var timer2Enabled = false;
		public var timer2IRQ = false;
		public var timer2Precounter = 0;
		public var timer2Prescalar = 1;
		public var timer2CountUp = false;
		public var timer3Counter = 0;
		public var timer3Reload = 0;
		public var timer3Control = 0;
		public var timer3Enabled = false;
		public var timer3IRQ = false;
		public var timer3Precounter = 0;
		public var timer3Prescalar = 1;
		public var timer3CountUp = false;
		public var timer1UseMainClocks = false;
		public var timer1UseChainedClocks = false;
		public var timer2UseMainClocks = false;
		public var timer2UseChainedClocks = false;
		public var timer3UseMainClocks = false;
		public var timer3UseChainedClocks = false;
		
		public var nextTimer0Overflow;
		public var nextTimer0OverflowAudio;
		public var nextTimer1Overflow;
		public var nextTimer1OverflowAudio;
		public var nextTimer2Overflow;
		public var nextTimer3Overflow;
		
		public var IOCore;

		public function GameBoyAdvanceTimer(IOCore) {
			// constructor code
			this.IOCore = IOCore;
			this.initialize();
		}
				
				
		public var prescalarLookup = [
			0x1,
			0x40,
			0x100,
			0x400
		];
		public function initialize() {
			this.nextTimer0Overflow = (MathsHelper.imul != null) ? this.nextTimer0OverflowFast : this.nextTimer0OverflowSlow;
			this.nextTimer0OverflowAudio = (MathsHelper.imul != null) ? this.nextTimer0OverflowAudioFast : this.nextTimer0OverflowAudioSlow;
			this.nextTimer1Overflow = (MathsHelper.imul != null) ? this.nextTimer1OverflowFast : this.nextTimer1OverflowSlow;
			this.nextTimer1OverflowAudio = (MathsHelper.imul != null) ? this.nextTimer1OverflowAudioFast : this.nextTimer1OverflowAudioSlow;
			this.nextTimer2Overflow = (MathsHelper.imul != null) ? this.nextTimer2OverflowFast : this.nextTimer2OverflowSlow;
			this.nextTimer3Overflow = (MathsHelper.imul != null) ? this.nextTimer3OverflowFast : this.nextTimer3OverflowSlow;
			
			/*this.nextTimer0Overflow = this.nextTimer0OverflowSlow;
			this.nextTimer0OverflowAudio = this.nextTimer0OverflowAudioSlow;
			this.nextTimer1Overflow = this.nextTimer1OverflowSlow;
			this.nextTimer1OverflowAudio = this.nextTimer1OverflowAudioSlow;
			this.nextTimer2Overflow = this.nextTimer2OverflowSlow;
			this.nextTimer3Overflow = this.nextTimer3OverflowSlow;*/
			this.initializeTimers();
		}
		public function initializeTimers() {
			this.timer0Counter = 0;
			this.timer0Reload = 0;
			this.timer0Control = 0;
			this.timer0Enabled = false;
			this.timer0IRQ = false;
			this.timer0Precounter = 0;
			this.timer0Prescalar = 1;
			this.timer1Counter = 0;
			this.timer1Reload = 0;
			this.timer1Control = 0;
			this.timer1Enabled = false;
			this.timer1IRQ = false;
			this.timer1Precounter = 0;
			this.timer1Prescalar = 1;
			this.timer1CountUp = false;
			this.timer2Counter = 0;
			this.timer2Reload = 0;
			this.timer2Control = 0;
			this.timer2Enabled = false;
			this.timer2IRQ = false;
			this.timer2Precounter = 0;
			this.timer2Prescalar = 1;
			this.timer2CountUp = false;
			this.timer3Counter = 0;
			this.timer3Reload = 0;
			this.timer3Control = 0;
			this.timer3Enabled = false;
			this.timer3IRQ = false;
			this.timer3Precounter = 0;
			this.timer3Prescalar = 1;
			this.timer3CountUp = false;
			this.timer1UseMainClocks = false;
			this.timer1UseChainedClocks = false;
			this.timer2UseMainClocks = false;
			this.timer2UseChainedClocks = false;
			this.timer3UseMainClocks = false;
			this.timer3UseChainedClocks = false;
		}
		public function addClocks(clocks) {
			clocks = clocks | 0;
			//See if timer channels 0 and 1 are enabled:
			this.clockSoundTimers(clocks | 0);
			//See if timer channel 2 is enabled:
			this.clockTimer2(clocks | 0);
			//See if timer channel 3 is enabled:
			this.clockTimer3(clocks | 0);
		}
		public function clockSoundTimers(clocks) {
			clocks = clocks | 0;
			for (var audioClocks = clocks | 0; (audioClocks | 0) > 0; audioClocks = ((audioClocks | 0) - (predictedClocks | 0)) | 0) {
				var overflowClocks = this.nextAudioTimerOverflow(audioClocks | 0) | 0;
				var predictedClocks = Math.min(audioClocks | 0, overflowClocks | 0) | 0;
				//See if timer channel 0 is enabled:
				this.clockTimer0(predictedClocks | 0);
				//See if timer channel 1 is enabled:
				this.clockTimer1(predictedClocks | 0);
				//Clock audio system up to latest timer:
				this.IOCore.sound.addClocks(predictedClocks | 0);
				//Only jit if overflow was seen:
				if ((overflowClocks | 0) == (predictedClocks | 0)) {
					this.IOCore.sound.audioJIT();
				}
			}
		}
		public function clockTimer0(clocks) {
			clocks = clocks | 0;
			if (this.timer0Enabled) {
				this.timer0Precounter = ((this.timer0Precounter | 0) + (clocks | 0)) | 0;
				while ((this.timer0Precounter | 0) >= (this.timer0Prescalar | 0)) {
					this.timer0Precounter = ((this.timer0Precounter | 0) - (this.timer0Prescalar | 0)) | 0;
					this.timer0Counter = ((this.timer0Counter | 0) + 1) | 0;
					if ((this.timer0Counter | 0) > 0xFFFF) {
						this.timer0Counter = this.timer0Reload | 0;
						this.timer0ExternalTriggerCheck();
						this.timer1ClockUpTickCheck();
					}
				}
			}
		}
		public function clockTimer1(clocks) {
			clocks = clocks | 0;
			if (this.timer1UseMainClocks) {
				this.timer1Precounter = ((this.timer1Precounter | 0) + (clocks | 0)) | 0;
				while ((this.timer1Precounter | 0) >= (this.timer1Prescalar | 0)) {
					this.timer1Precounter = ((this.timer1Precounter | 0) - (this.timer1Prescalar | 0)) | 0;
					this.timer1Counter = ((this.timer1Counter | 0) + 1) | 0;
					if ((this.timer1Counter | 0) > 0xFFFF) {
						this.timer1Counter = this.timer1Reload | 0;
						this.timer1ExternalTriggerCheck();
						this.timer2ClockUpTickCheck();
					}
				}
			}
		}
		public function clockTimer2(clocks) {
			clocks = clocks | 0;
			if (this.timer2UseMainClocks) {
				this.timer2Precounter = ((this.timer2Precounter | 0) + (clocks | 0)) | 0;
				while ((this.timer2Precounter | 0) >= (this.timer2Prescalar | 0)) {
					this.timer2Precounter = ((this.timer2Precounter | 0) - (this.timer2Prescalar | 0)) | 0;
					this.timer2Counter = ((this.timer2Counter | 0) + 1) | 0;
					if ((this.timer2Counter | 0) > 0xFFFF) {
						this.timer2Counter = this.timer2Reload | 0;
						this.timer2ExternalTriggerCheck();
						this.timer3ClockUpTickCheck();
					}
				}
			}
		}
		public function clockTimer3(clocks) {
			clocks = clocks | 0;
			if (this.timer3UseMainClocks) {
				this.timer3Precounter = ((this.timer3Precounter | 0) + (clocks | 0)) | 0;
				while ((this.timer3Precounter | 0) >= (this.timer3Prescalar | 0)) {
					this.timer3Precounter = ((this.timer3Precounter | 0) - (this.timer3Prescalar | 0)) | 0;
					this.timer3Counter = ((this.timer3Counter | 0) + 1) | 0;
					if ((this.timer3Counter | 0) > 0xFFFF) {
						this.timer3Counter = this.timer3Reload | 0;
						this.timer3ExternalTriggerCheck();
					}
				}
			}
		}
		public function timer1ClockUpTickCheck() {
			if (this.timer1UseChainedClocks) {
				this.timer1Counter = ((this.timer1Counter | 0) + 1) | 0;
				if ((this.timer1Counter | 0) > 0xFFFF) {
					this.timer1Counter = this.timer1Reload | 0;
					this.timer1ExternalTriggerCheck();
					this.timer2ClockUpTickCheck();
				}
			}
		}
		public function timer2ClockUpTickCheck() {
			if (this.timer2UseChainedClocks) {
				this.timer2Counter = ((this.timer2Counter | 0) + 1) | 0;
				if ((this.timer2Counter | 0) > 0xFFFF) {
					this.timer2Counter = this.timer2Reload | 0;
					this.timer2ExternalTriggerCheck();
					this.timer3ClockUpTickCheck();
				}
			}
		}
		public function timer3ClockUpTickCheck() {
			if (this.timer3UseChainedClocks) {
				this.timer3Counter = ((this.timer3Counter | 0) + 1) | 0;
				if ((this.timer3Counter | 0) > 0xFFFF) {
					this.timer3Counter = this.timer3Reload | 0;
					this.timer3ExternalTriggerCheck();
				}
			}
		}
		public function timer0ExternalTriggerCheck() {
			if (this.timer0IRQ) {
				this.IOCore.irq.requestIRQ(0x08);
			}
			this.IOCore.sound.AGBDirectSoundTimer0ClockTick();
		}
		public function timer1ExternalTriggerCheck() {
			if (this.timer1IRQ) {
				this.IOCore.irq.requestIRQ(0x10);
			}
			this.IOCore.sound.AGBDirectSoundTimer1ClockTick();
		}
		public function timer2ExternalTriggerCheck() {
			if (this.timer2IRQ) {
				this.IOCore.irq.requestIRQ(0x20);
			}
		}
		public function timer3ExternalTriggerCheck() {
			if (this.timer3IRQ) {
				this.IOCore.irq.requestIRQ(0x40);
			}
		}
		public function writeTM0CNT_L0(data) {
			this.IOCore.sound.audioJIT();
			this.timer0Reload &= 0xFF00;
			this.timer0Reload |= data;
		}
		public function writeTM0CNT_L1(data) {
			this.IOCore.sound.audioJIT();
			this.timer0Reload &= 0xFF;
			this.timer0Reload |= data << 8;
		}
		public function writeTM0CNT_H(data) {
			this.IOCore.sound.audioJIT();
			this.timer0Control = data;
			if (data > 0x7F) {
				if (!this.timer0Enabled) {
					this.timer0Counter = this.timer0Reload | 0;
					this.timer0Enabled = true;
				}
			}
			else {
				this.timer0Enabled = false;
			}
			this.timer0IRQ = ((data & 0x40) == 0x40);
			this.timer0Prescalar = this.prescalarLookup[data & 0x03];
		}
		public function readTM0CNT_L0() {
			return this.timer0Counter & 0xFF;
		}
		public function readTM0CNT_L1() {
			return (this.timer0Counter & 0xFF00) >> 8;
		}
		public function readTM0CNT_H() {
			return 0x38 | this.timer0Control;
		}
		public function writeTM1CNT_L0(data) {
			this.IOCore.sound.audioJIT();
			this.timer1Reload &= 0xFF00;
			this.timer1Reload |= data;
		}
		public function writeTM1CNT_L1(data) {
			this.IOCore.sound.audioJIT();
			this.timer1Reload &= 0xFF;
			this.timer1Reload |= data << 8;
		}
		public function writeTM1CNT_H(data) {
			this.IOCore.sound.audioJIT();
			this.timer1Control = data;
			if (data > 0x7F) {
				if (!this.timer1Enabled) {
					this.timer1Counter = this.timer1Reload | 0;
					this.timer1Enabled = true;
				}
			}
			else {
				this.timer1Enabled = false;
			}
			this.timer1IRQ = ((data & 0x40) == 0x40);
			this.timer1CountUp = ((data & 0x4) == 0x4);
			this.timer1Prescalar = this.prescalarLookup[data & 0x03];
			this.preprocessTimer1();
		}
		public function readTM1CNT_L0() {
			return this.timer1Counter & 0xFF;
		}
		public function readTM1CNT_L1() {
			return (this.timer1Counter & 0xFF00) >> 8;
		}
		public function readTM1CNT_H() {
			return 0x38 | this.timer1Control;
		}
		public function writeTM2CNT_L0(data) {
			this.timer2Reload &= 0xFF00;
			this.timer2Reload |= data;
		}
		public function writeTM2CNT_L1(data) {
			this.timer2Reload &= 0xFF;
			this.timer2Reload |= data << 8;
		}
		public function writeTM2CNT_H(data) {
			this.timer2Control = data;
			if (data > 0x7F) {
				if (!this.timer2Enabled) {
					this.timer2Counter = this.timer2Reload | 0;
					this.timer2Enabled = true;
				}
			}
			else {
				this.timer2Enabled = false;
			}
			this.timer2IRQ = ((data & 0x40) == 0x40);
			this.timer2CountUp = ((data & 0x4) == 0x4);
			this.timer2Prescalar = this.prescalarLookup[data & 0x03];
			this.preprocessTimer2();
		}
		public function readTM2CNT_L0() {
			return this.timer2Counter & 0xFF;
		}
		public function readTM2CNT_L1() {
			return (this.timer2Counter & 0xFF00) >> 8;
		}
		public function readTM2CNT_H() {
			return 0x38 | this.timer2Control;
		}
		public function writeTM3CNT_L0(data) {
			this.timer3Reload &= 0xFF00;
			this.timer3Reload |= data;
		}
		public function writeTM3CNT_L1(data) {
			this.timer3Reload &= 0xFF;
			this.timer3Reload |= data << 8;
		}
		public function writeTM3CNT_H(data) {
			this.timer3Control = data;
			if (data > 0x7F) {
				if (!this.timer3Enabled) {
					this.timer3Counter = this.timer3Reload | 0;
					this.timer3Enabled = true;
				}
			}
			else {
				this.timer3Enabled = false;
			}
			this.timer3IRQ = ((data & 0x40) == 0x40);
			this.timer3CountUp = ((data & 0x4) == 0x4);
			this.timer3Prescalar = this.prescalarLookup[data & 0x03];
			this.preprocessTimer3();
		}
		public function readTM3CNT_L0() {
			return this.timer3Counter & 0xFF;
		}
		public function readTM3CNT_L1() {
			return (this.timer3Counter & 0xFF00) >> 8;
		}
		public function readTM3CNT_H() {
			return 0x38 | this.timer3Control;
		}
		public function preprocessTimer1() {
			this.timer1UseMainClocks = (this.timer1Enabled && !this.timer1CountUp);
			this.timer1UseChainedClocks = (this.timer1Enabled && this.timer1CountUp);
		}
		public function preprocessTimer2() {
			this.timer2UseMainClocks = (this.timer2Enabled && !this.timer2CountUp);
			this.timer2UseChainedClocks = (this.timer2Enabled && this.timer2CountUp);
		}
		public function preprocessTimer3() {
			this.timer3UseMainClocks = (this.timer3Enabled && !this.timer3CountUp);
			this.timer3UseChainedClocks = (this.timer3Enabled && this.timer3CountUp);
		}
		public function nextTimer0OverflowSlow(numOverflows) {
			--numOverflows;
			if (this.timer0Enabled) {
				return (((0x10000 - this.timer0Counter) * this.timer0Prescalar) - this.timer0Precounter) + (((0x10000 - this.timer0Reload) * this.timer0Prescalar) * numOverflows);
			}
			return -1;
		}
		public function nextTimer0OverflowFast(numOverflows) {
			numOverflows = ((numOverflows | 0) - 1) | 0;
			if (this.timer0Enabled) {
				return ((MathsHelper.imul((0x10000 - (this.timer0Counter | 0)), (this.timer0Prescalar | 0)) - (this.timer0Precounter | 0)) + MathsHelper.imul(MathsHelper.imul((0x10000 - (this.timer0Reload | 0)) | 0, (this.timer0Prescalar | 0)), (numOverflows | 0))) | 0;
			}
			return -1;
		}
		public function nextTimer0OverflowAudioSlow() {
			if (this.timer0Enabled) {
				return ((0x10000 - this.timer0Counter) * this.timer0Prescalar) - this.timer0Precounter;
			}
			return -1;
		}
		public function nextTimer0OverflowAudioFast() {
			if (this.timer0Enabled) {
				return (MathsHelper.imul((0x10000 - (this.timer0Counter | 0)) | 0, (this.timer0Prescalar | 0)) - (this.timer0Precounter | 0)) | 0;
			}
			return -1;
		}
		public function nextTimer1OverflowSlow(numOverflows) {
			--numOverflows;
			if (this.timer1Enabled) {
				if (this.timer1CountUp) {
					return this.nextTimer0Overflow(0x10000 - this.timer1Counter + (numOverflows * (0x10000 - this.timer1Reload)));
				}
				else {
					return (((0x10000 - this.timer1Counter) * this.timer1Prescalar) - this.timer1Precounter) + (((0x10000 - this.timer1Reload) * this.timer1Prescalar) * numOverflows);
				}
			}
			return -1;
		}
		public function nextTimer1OverflowFast(numOverflows) {
			numOverflows = ((numOverflows | 0) - 1) | 0;
			if (this.timer1Enabled) {
				if (this.timer1CountUp) {
					return this.nextTimer0Overflow((0x10000 - (this.timer1Counter | 0) + MathsHelper.imul(numOverflows | 0, (0x10000 - (this.timer1Reload | 0)) | 0)) | 0) | 0;
				}
				else {
					return ((MathsHelper.imul((0x10000 - (this.timer1Counter | 0)) | 0, this.timer1Prescalar | 0) - (this.timer1Precounter | 0)) + MathsHelper.imul(MathsHelper.imul((0x10000 - (this.timer1Reload | 0)) | 0, this.timer1Prescalar | 0), numOverflows | 0)) | 0;
				}
			}
			return -1;
		}
		public function nextTimer1OverflowAudioSlow() {
			if (this.timer1Enabled) {
				if (this.timer1CountUp) {
					return this.nextTimer0Overflow(0x10000 - this.timer1Counter);
				}
				else {
					return (((0x10000 - this.timer1Counter) * this.timer1Prescalar) - this.timer1Precounter);
				}
			}
			return -1;
		}
		public function nextTimer1OverflowAudioFast() {
			if (this.timer1Enabled) {
				if (this.timer1CountUp) {
					return this.nextTimer0Overflow((0x10000 - (this.timer1Counter | 0)) | 0) | 0;
				}
				else {
					return (MathsHelper.imul((0x10000 - (this.timer1Counter | 0)) | 0, this.timer1Prescalar | 0) - (this.timer1Precounter | 0)) | 0;
				}
			}
			return -1;
		}
		public function nextTimer2OverflowSlow(numOverflows) {
			--numOverflows;
			if (this.timer2Enabled) {
				if (this.timer2CountUp) {
					return this.nextTimer1Overflow(0x10000 - this.timer2Counter + (numOverflows * (0x10000 - this.timer2Reload)));
				}
				else {
					return (((0x10000 - this.timer2Counter) * this.timer2Prescalar) - this.timer2Precounter) + (((0x10000 - this.timer2Reload) * this.timer2Prescalar) * numOverflows);
				}
			}
			return -1;
		}
		public function nextTimer2OverflowFast(numOverflows) {
			numOverflows = ((numOverflows | 0) - 1) | 0;
			if (this.timer2Enabled) {
				if (this.timer2CountUp) {
					return this.nextTimer1Overflow((0x10000 - (this.timer2Counter | 0) + MathsHelper.imul(numOverflows | 0, (0x10000 - (this.timer2Reload | 0)) | 0)) | 0) | 0;
				}
				else {
					return ((MathsHelper.imul((0x10000 - (this.timer2Counter | 0)) | 0, this.timer2Prescalar | 0) - (this.timer2Precounter | 0)) + MathsHelper.imul(MathsHelper.imul((0x10000 - (this.timer2Reload | 0)) | 0, this.timer2Prescalar | 0), numOverflows | 0)) | 0;
				}
			}
			return -1;
		}
		public function nextTimer3OverflowSlow(numOverflows) {
			--numOverflows;
			if (this.timer3Enabled) {
				if (this.timer3CountUp) {
					return this.nextTimer2Overflow(0x10000 - this.timer3Counter + (numOverflows * (0x10000 - this.timer3Reload)));
				}
				else {
					return (((0x10000 - this.timer3Counter) * this.timer3Prescalar) - this.timer3Precounter) + (((0x10000 - this.timer3Reload) * this.timer3Prescalar) * numOverflows);
				}
			}
			return -1;
		}
		public function nextTimer3OverflowFast(numOverflows) {
			numOverflows = ((numOverflows | 0) - 1) | 0;
			if (this.timer3Enabled) {
				if (this.timer3CountUp) {
					return this.nextTimer2Overflow((0x10000 - (this.timer3Counter | 0) + MathsHelper.imul(numOverflows | 0, (0x10000 - (this.timer3Reload | 0)) | 0)) | 0) | 0;
				}
				else {
					return ((MathsHelper.imul((0x10000 - (this.timer3Counter | 0)) | 0, this.timer3Prescalar | 0) - (this.timer3Precounter | 0)) + MathsHelper.imul(MathsHelper.imul((0x10000 - (this.timer3Reload | 0)) | 0, this.timer3Prescalar | 0), numOverflows | 0)) | 0;
				}
			}
			return -1;
		}
		public function nextAudioTimerOverflow(clocks) {
			clocks = clocks | 0;
			var timer0 = this.nextTimer0OverflowAudio() | 0;
			if ((timer0 | 0) == -1) {
				timer0 = ((clocks | 0) + 1) | 0;
			}
			var timer1 = this.nextTimer1OverflowAudio() | 0;
			if ((timer1 | 0) == -1) {
				timer1 = ((clocks | 0) + 1) | 0;
			}
			return Math.min(timer0 | 0, timer1 | 0) | 0;
		}
		public function nextTimer0IRQEventTime() {
			return (this.timer0Enabled && this.timer0IRQ) ? this.nextTimer0Overflow(1) : -1;
		}
		public function nextTimer1IRQEventTime() {
			return (this.timer1Enabled && this.timer1IRQ) ? this.nextTimer1Overflow(1) : -1;
		}
		public function nextTimer2IRQEventTime() {
			return (this.timer2Enabled && this.timer2IRQ) ? this.nextTimer2Overflow(1) : -1;
		}
		public function nextTimer3IRQEventTime() {
			return (this.timer3Enabled && this.timer3IRQ) ? this.nextTimer3Overflow(1) : -1;
		}
		
		

	}
	
}
