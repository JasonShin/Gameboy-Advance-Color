package  {
	import sound.GameBoyAdvanceFIFO;
	import utils.MathsHelper;
	import utils.ArrayHelper;
	
	public class GameBoyAdvanceSound {

		public var channel3PCM;
		public var WAVERAM;
		public var audioTicks;
		public var audioIndex = 0;
		public var downsampleInputLeft = 0;
		public var downsampleInputRight = 0;
		public var LSFR15Table;
		public var LSFR7Table;
		public var nr60 = 0;
		public var nr61 = 0;
		public var nr62;
		public var nr63;
		public var soundMasterEnabled;
		public var mixerSoundBIAS;
		public var channel1currentSampleLeft = 0;
		public var channel1currentSampleLeftSecondary = 0;
		public var channel1currentSampleLeftTrimary = 0;
		public var channel2currentSampleLeft = 0;
		public var channel2currentSampleLeftSecondary = 0;
		public var channel2currentSampleLeftTrimary = 0;
		public var channel3currentSampleLeft = 0;
		public var channel3currentSampleLeftSecondary = 0;
		public var channel4currentSampleLeft = 0;
		public var channel4currentSampleLeftSecondary = 0;
		public var channel1currentSampleRight = 0;
		public var channel1currentSampleRightSecondary = 0;
		public var channel1currentSampleRightTrimary = 0;
		public var channel2currentSampleRight = 0;
		public var channel2currentSampleRightSecondary = 0;
		public var channel2currentSampleRightTrimary = 0;
		public var channel3currentSampleRight = 0;
		public var channel3currentSampleRightSecondary = 0;
		public var channel4currentSampleRight = 0;
		public var channel4currentSampleRightSecondary = 0;
		public var CGBMixerOutputCacheLeft = 0;
		public var CGBMixerOutputCacheLeftFolded = 0;
		public var CGBMixerOutputCacheRight = 0;
		public var CGBMixerOutputCacheRightFolded = 0;
		public var AGBDirectSoundATimer = 0;
		public var AGBDirectSoundBTimer = 0;
		public var AGBDirectSoundA = 0;
		public var AGBDirectSoundAFolded = 0;
		public var AGBDirectSoundB = 0;
		public var AGBDirectSoundBFolded = 0;
		public var AGBDirectSoundAShifter = 0;
		public var AGBDirectSoundBShifter = 0;
		public var AGBDirectSoundALeftCanPlay = false;
		public var AGBDirectSoundBLeftCanPlay = false;
		public var AGBDirectSoundARightCanPlay = false;
		public var AGBDirectSoundBRightCanPlay = false;
		public var CGBOutputRatio = 2;
		public var FIFOABuffer;
		public var FIFOBBuffer;
		
		public var IOCore;
		public var emulatorCore;
		

		public var audioResamplerFirstPassFactor;
		
		
		//Disable
		public var nr10 = 0;
		public var channel1SweepFault = false;
		public var channel1lastTimeSweep = 0;
		public var channel1timeSweep = 0;
		public var channel1frequencySweepDivider = 0;
		public var channel1decreaseSweep = false;
		//Clear NR11:
		public var nr11 = 0;
		public var channel1CachedDuty;
		public var channel1totalLength = 0x40;
		//Clear NR12:
		public var nr12 = 0;
		public var channel1envelopeVolume = 0;
		//Clear NR13:
		public var channel1frequency = 0;
		public var channel1FrequencyTracker = 0x8000;
		//Clear NR14:
		public var nr14 = 0;
		public var channel1consecutive = true;
		public var channel1ShadowFrequency = 0x8000;
		public var channel1canPlay = false;
		public var channel1Enabled = false;
		public var channel1envelopeSweeps = 0;
		public var channel1envelopeSweepsLast = -1;
		//Clear NR21:
		public var nr21 = 0;
		public var channel2CachedDuty;
		public var channel2totalLength = 0x40;
		//Clear NR22:
		public var nr22 = 0;
		public var channel2envelopeVolume = 0;
		//Clear NR23:
		public var nr23 = 0;
		public var channel2frequency = 0;
		public var channel2FrequencyTracker = 0x8000;
		//Clear NR24:
		public var nr24 = 0;
		public var channel2consecutive = true;
		public var channel2canPlay = false;
		public var channel2Enabled = false;
		public var channel2envelopeSweeps = 0;
		public var channel2envelopeSweepsLast = -1;
		//Clear NR30:
		public var nr30 = 0;
		public var channel3lastSampleLookup = 0;
		public var channel3canPlay = false;
		public var channel3WAVERAMBankSpecified = 0x20;
		public var channel3WaveRAMBankSize = 0x1F;
		//Clear NR31:
		public var channel3totalLength = 0x100;
		//Clear NR32:
		public var nr32 = 0;
		public var channel3patternType = 4;
		//Clear NR33:
		public var nr33 = 0;
		public var channel3frequency = 0;
		public var channel3FrequencyPeriod = 0x4000;
		//Clear NR34:
		public var nr34 = 0;
		public var channel3consecutive = true;
		public var channel3Enabled = false;
		//Clear NR41:
		public var channel4totalLength = 0x40;
		//Clear NR42:
		public var nr42 = 0;
		public var channel4envelopeVolume = 0;
		//Clear NR43:
		public var nr43 = 0;
		public var channel4FrequencyPeriod = 32;
		public var channel4lastSampleLookup = 0;
		public var channel4BitRange =  0x7FFF;
		public var channel4VolumeShifter = 15;
		public var channel4currentVolume = 0;
		public var noiseSampleTable;
		//Clear NR44:
		public var nr44 = 0;
		public var channel4consecutive = true;
		public var channel4envelopeSweeps = 0;
		public var channel4envelopeSweepsLast = -1;
		public var channel4canPlay = false;
		public var channel4Enabled = false;
		//Clear NR50:
		public var nr50 = 0;
		public var VinLeftChannelMasterVolume = 1;
		public var VinRightChannelMasterVolume = 1;
		//Clear NR51:
		public var nr51 = 0;
		public var rightChannel1 = false;
		public var rightChannel2 = false;
		public var rightChannel3 = false;
		public var rightChannel4 = false;
		public var leftChannel1 = false;
		public var leftChannel2 = false;
		public var leftChannel3 = false;
		public var leftChannel4 = false;
		//Clear NR52:
		public var nr52 = 0;
		//public var soundMasterEnabled = false;
		public var mixerOutputCacheLeft;
		public var mixerOutputCacheRight;
		public var audioClocksUntilNextEventCounter = 0;
		public var audioClocksUntilNextEvent = 0;
		public var sequencePosition = 0;
		public var sequencerClocks = 0x8000;
		public var channel1FrequencyCounter = 0;
		public var channel1DutyTracker = 0;
		public var channel2FrequencyCounter = 0;
		public var channel2DutyTracker = 0;
		public var channel3Counter = 0;
		public var channel4Counter = 0;
		public var PWMWidth = 0x200;
		public var PWMWidthOld = 0x200;
		public var PWMWidthShadow = 0x200;
		public var PWMBitDepthMask = 0x3FE;
		public var PWMBitDepthMaskShadow = 0x3FE;
		
		//funcs
		public var generateAudio;
		public var audioInitialized;
		public var channel1Swept;
		public var channel1envelopeType;
		public var channel2envelopeType;
		public var channel4envelopeType;
		public var cachedChannel3Sample;
		public var cachedChannel4Sample;

		public function GameBoyAdvanceSound(IOCore) {
			// constructor code
			this.IOCore = IOCore;
			this.emulatorCore = this.IOCore.emulatorCore;
			this.initializePAPU();
		}
		
		public var dutyLookup = [
			[false, false, false, false, false, false, false, true],
			[true, false, false, false, false, false, false, true],
			[true, false, false, false, false, true, true, true],
			[false, true, true, true, true, true, true, false]
		];
		
		public function initializePAPU() {
			//Did the emulator core initialize us for output yet?
			this.preprocessInitialization(false);
			//Initialize start:
			this.channel3PCM = ArrayHelper.buildArray(0x40);
			this.WAVERAM = ArrayHelper.buildArray(0x20);
			this.audioTicks = 0;
			this.intializeWhiteNoise();
			this.initializeAudioStartState();
		}
		public function initializeOutput(enabled, audioResamplerFirstPassFactor) {
			this.preprocessInitialization(enabled);
			this.audioIndex = 0;
			this.downsampleInputLeft = 0;
			this.downsampleInputRight = 0;
			this.audioResamplerFirstPassFactor = audioResamplerFirstPassFactor;
		}
		public function intializeWhiteNoise() {
			//Noise Sample Tables:
			var randomFactor = 1;
			//15-bit LSFR Cache Generation:
			this.LSFR15Table = ArrayHelper.buildArray(0x80000);
			var LSFR = 0x7FFF;	//Seed value has all its bits set.
			var LSFRShifted = 0x3FFF;
			for (var index = 0; index < 0x8000; ++index) {
				//Normalize the last LSFR value for usage:
				randomFactor = 1 - (LSFR & 1);	//Docs say it's the inverse.
				//Cache the different volume level results:
				this.LSFR15Table[0x08000 | index] = randomFactor;
				this.LSFR15Table[0x10000 | index] = randomFactor * 0x2;
				this.LSFR15Table[0x18000 | index] = randomFactor * 0x3;
				this.LSFR15Table[0x20000 | index] = randomFactor * 0x4;
				this.LSFR15Table[0x28000 | index] = randomFactor * 0x5;
				this.LSFR15Table[0x30000 | index] = randomFactor * 0x6;
				this.LSFR15Table[0x38000 | index] = randomFactor * 0x7;
				this.LSFR15Table[0x40000 | index] = randomFactor * 0x8;
				this.LSFR15Table[0x48000 | index] = randomFactor * 0x9;
				this.LSFR15Table[0x50000 | index] = randomFactor * 0xA;
				this.LSFR15Table[0x58000 | index] = randomFactor * 0xB;
				this.LSFR15Table[0x60000 | index] = randomFactor * 0xC;
				this.LSFR15Table[0x68000 | index] = randomFactor * 0xD;
				this.LSFR15Table[0x70000 | index] = randomFactor * 0xE;
				this.LSFR15Table[0x78000 | index] = randomFactor * 0xF;
				//Recompute the LSFR algorithm:
				LSFRShifted = LSFR >> 1;
				LSFR = LSFRShifted | (((LSFRShifted ^ LSFR) & 0x1) << 14);
			}
			//7-bit LSFR Cache Generation:
			this.LSFR7Table = ArrayHelper.buildArray(0x800);
			LSFR = 0x7F;	//Seed value has all its bits set.
			for (index = 0; index < 0x80; ++index) {
				//Normalize the last LSFR value for usage:
				randomFactor = 1 - (LSFR & 1);	//Docs say it's the inverse.
				//Cache the different volume level results:
				this.LSFR7Table[0x080 | index] = randomFactor;
				this.LSFR7Table[0x100 | index] = randomFactor * 0x2;
				this.LSFR7Table[0x180 | index] = randomFactor * 0x3;
				this.LSFR7Table[0x200 | index] = randomFactor * 0x4;
				this.LSFR7Table[0x280 | index] = randomFactor * 0x5;
				this.LSFR7Table[0x300 | index] = randomFactor * 0x6;
				this.LSFR7Table[0x380 | index] = randomFactor * 0x7;
				this.LSFR7Table[0x400 | index] = randomFactor * 0x8;
				this.LSFR7Table[0x480 | index] = randomFactor * 0x9;
				this.LSFR7Table[0x500 | index] = randomFactor * 0xA;
				this.LSFR7Table[0x580 | index] = randomFactor * 0xB;
				this.LSFR7Table[0x600 | index] = randomFactor * 0xC;
				this.LSFR7Table[0x680 | index] = randomFactor * 0xD;
				this.LSFR7Table[0x700 | index] = randomFactor * 0xE;
				this.LSFR7Table[0x780 | index] = randomFactor * 0xF;
				//Recompute the LSFR algorithm:
				LSFRShifted = LSFR >> 1;
				LSFR = LSFRShifted | (((LSFRShifted ^ LSFR) & 0x1) << 6);
			}
		}
		public function initializeAudioStartState() {
			//NOTE: NR 60-63 never get reset in audio halting:
			this.nr60 = 0;
			this.nr61 = 0;
			this.nr62 = (this.IOCore.BIOSFound && !this.emulatorCore.SKIPBoot) ? 0 : 0xFF;
			this.nr63 = (this.IOCore.BIOSFound && !this.emulatorCore.SKIPBoot) ? 0 : 0x2;
			this.soundMasterEnabled = (!this.IOCore.BIOSFound || this.emulatorCore.SKIPBoot);
			this.mixerSoundBIAS = (this.IOCore.BIOSFound && !this.emulatorCore.SKIPBoot) ? 0 : 0x200;
			this.channel1currentSampleLeft = 0;
			this.channel1currentSampleLeftSecondary = 0;
			this.channel1currentSampleLeftTrimary = 0;
			this.channel2currentSampleLeft = 0;
			this.channel2currentSampleLeftSecondary = 0;
			this.channel2currentSampleLeftTrimary = 0;
			this.channel3currentSampleLeft = 0;
			this.channel3currentSampleLeftSecondary = 0;
			this.channel4currentSampleLeft = 0;
			this.channel4currentSampleLeftSecondary = 0;
			this.channel1currentSampleRight = 0;
			this.channel1currentSampleRightSecondary = 0;
			this.channel1currentSampleRightTrimary = 0;
			this.channel2currentSampleRight = 0;
			this.channel2currentSampleRightSecondary = 0;
			this.channel2currentSampleRightTrimary = 0;
			this.channel3currentSampleRight = 0;
			this.channel3currentSampleRightSecondary = 0;
			this.channel4currentSampleRight = 0;
			this.channel4currentSampleRightSecondary = 0;
			this.CGBMixerOutputCacheLeft = 0;
			this.CGBMixerOutputCacheLeftFolded = 0;
			this.CGBMixerOutputCacheRight = 0;
			this.CGBMixerOutputCacheRightFolded = 0;
			this.AGBDirectSoundATimer = 0;
			this.AGBDirectSoundBTimer = 0;
			this.AGBDirectSoundA = 0;
			this.AGBDirectSoundAFolded = 0;
			this.AGBDirectSoundB = 0;
			this.AGBDirectSoundBFolded = 0;
			this.AGBDirectSoundAShifter = 0;
			this.AGBDirectSoundBShifter = 0;
			this.AGBDirectSoundALeftCanPlay = false;
			this.AGBDirectSoundBLeftCanPlay = false;
			this.AGBDirectSoundARightCanPlay = false;
			this.AGBDirectSoundBRightCanPlay = false;
			this.CGBOutputRatio = 2;
			this.FIFOABuffer = new GameBoyAdvanceFIFO();
			this.FIFOBBuffer = new GameBoyAdvanceFIFO();
			this.AGBDirectSoundAFIFOClear();
			this.AGBDirectSoundBFIFOClear();
			this.audioDisabled();       //Clear legacy PAPU registers:
		}
		public function audioDisabled() {
			//Clear NR10:
			this.nr10 = 0;
			this.channel1SweepFault = false;
			this.channel1lastTimeSweep = 0;
			this.channel1timeSweep = 0;
			this.channel1frequencySweepDivider = 0;
			this.channel1decreaseSweep = false;
			//Clear NR11:
			this.nr11 = 0;
			this.channel1CachedDuty = this.dutyLookup[0];
			this.channel1totalLength = 0x40;
			//Clear NR12:
			this.nr12 = 0;
			this.channel1envelopeVolume = 0;
			//Clear NR13:
			this.channel1frequency = 0;
			this.channel1FrequencyTracker = 0x8000;
			//Clear NR14:
			this.nr14 = 0;
			this.channel1consecutive = true;
			this.channel1ShadowFrequency = 0x8000;
			this.channel1canPlay = false;
			this.channel1Enabled = false;
			this.channel1envelopeSweeps = 0;
			this.channel1envelopeSweepsLast = -1;
			//Clear NR21:
			this.nr21 = 0;
			this.channel2CachedDuty = this.dutyLookup[0];
			this.channel2totalLength = 0x40;
			//Clear NR22:
			this.nr22 = 0;
			this.channel2envelopeVolume = 0;
			//Clear NR23:
			this.nr23 = 0;
			this.channel2frequency = 0;
			this.channel2FrequencyTracker = 0x8000;
			//Clear NR24:
			this.nr24 = 0;
			this.channel2consecutive = true;
			this.channel2canPlay = false;
			this.channel2Enabled = false;
			this.channel2envelopeSweeps = 0;
			this.channel2envelopeSweepsLast = -1;
			//Clear NR30:
			this.nr30 = 0;
			this.channel3lastSampleLookup = 0;
			this.channel3canPlay = false;
			this.channel3WAVERAMBankSpecified = 0x20;
			this.channel3WaveRAMBankSize = 0x1F;
			//Clear NR31:
			this.channel3totalLength = 0x100;
			//Clear NR32:
			this.nr32 = 0;
			this.channel3patternType = 4;
			//Clear NR33:
			this.nr33 = 0;
			this.channel3frequency = 0;
			this.channel3FrequencyPeriod = 0x4000;
			//Clear NR34:
			this.nr34 = 0;
			this.channel3consecutive = true;
			this.channel3Enabled = false;
			//Clear NR41:
			this.channel4totalLength = 0x40;
			//Clear NR42:
			this.nr42 = 0;
			this.channel4envelopeVolume = 0;
			//Clear NR43:
			this.nr43 = 0;
			this.channel4FrequencyPeriod = 32;
			this.channel4lastSampleLookup = 0;
			this.channel4BitRange =  0x7FFF;
			this.channel4VolumeShifter = 15;
			this.channel4currentVolume = 0;
			this.noiseSampleTable = this.LSFR15Table;
			//Clear NR44:
			this.nr44 = 0;
			this.channel4consecutive = true;
			this.channel4envelopeSweeps = 0;
			this.channel4envelopeSweepsLast = -1;
			this.channel4canPlay = false;
			this.channel4Enabled = false;
			//Clear NR50:
			this.nr50 = 0;
			this.VinLeftChannelMasterVolume = 1;
			this.VinRightChannelMasterVolume = 1;
			//Clear NR51:
			this.nr51 = 0;
			this.rightChannel1 = false;
			this.rightChannel2 = false;
			this.rightChannel3 = false;
			this.rightChannel4 = false;
			this.leftChannel1 = false;
			this.leftChannel2 = false;
			this.leftChannel3 = false;
			this.leftChannel4 = false;
			//Clear NR52:
			this.nr52 = 0;
			this.soundMasterEnabled = false;
			this.mixerOutputCacheLeft = this.mixerSoundBIAS | 0;
			this.mixerOutputCacheRight = this.mixerSoundBIAS | 0;
			this.audioClocksUntilNextEventCounter = 0;
			this.audioClocksUntilNextEvent = 0;
			this.sequencePosition = 0;
			this.sequencerClocks = 0x8000;
			this.channel1FrequencyCounter = 0;
			this.channel1DutyTracker = 0;
			this.channel2FrequencyCounter = 0;
			this.channel2DutyTracker = 0;
			this.channel3Counter = 0;
			this.channel4Counter = 0;
			this.PWMWidth = 0x200;
			this.PWMWidthOld = 0x200;
			this.PWMWidthShadow = 0x200;
			this.PWMBitDepthMask = 0x3FE;
			this.PWMBitDepthMaskShadow = 0x3FE;
			this.channel1OutputLevelCache();
			this.channel2OutputLevelCache();
			this.channel3UpdateCache();
			this.channel4UpdateCache();
		}
		public function audioEnabled() {
			//Set NR52:
			this.nr52 = 0x80;
			this.soundMasterEnabled = true;
		}
		public function addClocks(clocks) {
			clocks = clocks | 0;
			this.audioTicks = ((this.audioTicks | 0) + (clocks | 0)) | 0;
		}
		public function generateAudioSlow(numSamples) {
			numSamples = numSamples | 0;
			var multiplier = 0;
			if (this.soundMasterEnabled && this.IOCore.systemStatus < 4) {
				for (var clockUpTo = 0; (numSamples | 0) > 0;) {
					clockUpTo = Math.min(this.PWMWidth | 0, numSamples | 0) | 0;
					this.PWMWidth = ((this.PWMWidth | 0) - (clockUpTo | 0)) | 0;
					numSamples = ((numSamples | 0) - (clockUpTo | 0)) | 0;
					while ((clockUpTo | 0) > 0) {
						multiplier = Math.min(clockUpTo | 0, ((this.audioResamplerFirstPassFactor | 0) - (this.audioIndex | 0)) | 0) | 0;
						clockUpTo = ((clockUpTo | 0) - (multiplier | 0)) | 0;
						this.audioIndex = ((this.audioIndex | 0) + (multiplier | 0)) | 0;
						this.downsampleInputLeft = ((this.downsampleInputLeft | 0) + (((this.mixerOutputCacheLeft | 0) * (multiplier | 0)) | 0)) | 0;
						this.downsampleInputRight = ((this.downsampleInputRight | 0) + (((this.mixerOutputCacheRight | 0) * (multiplier | 0)) | 0)) | 0;
						if ((this.audioIndex | 0) == (this.audioResamplerFirstPassFactor | 0)) {
							this.audioIndex = 0;
							this.emulatorCore.outputAudio(this.downsampleInputLeft | 0, this.downsampleInputRight | 0);
							this.downsampleInputLeft = 0;
							this.downsampleInputRight = 0;
						}
					}
					if ((this.PWMWidth | 0) == 0) {
						this.computeNextPWMInterval();
						this.PWMWidthOld = this.PWMWidthShadow | 0;
						this.PWMWidth = this.PWMWidthShadow | 0;
					}
				}
			}
			else {
				//SILENT OUTPUT:
				while ((numSamples | 0) > 0) {
					multiplier = Math.min(numSamples | 0, ((this.audioResamplerFirstPassFactor | 0) - (this.audioIndex | 0)) | 0) | 0;
					numSamples = ((numSamples | 0) - (multiplier | 0)) | 0;
					this.audioIndex = ((this.audioIndex | 0) + (multiplier | 0)) | 0;
					if ((this.audioIndex | 0) == (this.audioResamplerFirstPassFactor | 0)) {
						this.audioIndex = 0;
						this.emulatorCore.outputAudio(this.downsampleInputLeft | 0, this.downsampleInputRight | 0);
						this.downsampleInputLeft = 0;
						this.downsampleInputRight = 0;
					}
				}
			}
		}
		public function generateAudioOptimized(numSamples) {
			trace("audio");
			numSamples = numSamples | 0;
			
			var multiplier = 0;
			if (this.soundMasterEnabled && this.IOCore.systemStatus < 4) {
				for (var clockUpTo = 0; (numSamples | 0) > 0;) {
					clockUpTo = Math.min(this.PWMWidth | 0, numSamples | 0) | 0;
					this.PWMWidth = ((this.PWMWidth | 0) - (clockUpTo | 0)) | 0;
					numSamples = ((numSamples | 0) - (clockUpTo | 0)) | 0;
					while ((clockUpTo | 0) > 0) {
						multiplier = Math.min(clockUpTo | 0, ((this.audioResamplerFirstPassFactor | 0) - (this.audioIndex | 0)) | 0) | 0;
						clockUpTo = ((clockUpTo | 0) - (multiplier | 0)) | 0;
						this.audioIndex = ((this.audioIndex | 0) + (multiplier | 0)) | 0;
						this.downsampleInputLeft = ((this.downsampleInputLeft | 0) + MathsHelper.imul(this.mixerOutputCacheLeft | 0, multiplier | 0)) | 0;
						this.downsampleInputRight = ((this.downsampleInputRight | 0) + MathsHelper.imul(this.mixerOutputCacheRight | 0, multiplier | 0)) | 0;
						if ((this.audioIndex | 0) == (this.audioResamplerFirstPassFactor | 0)) {
							this.audioIndex = 0;
							this.emulatorCore.outputAudio(this.downsampleInputLeft | 0, this.downsampleInputRight | 0);
							this.downsampleInputLeft = 0;
							this.downsampleInputRight = 0;
						}
					}
					if ((this.PWMWidth | 0) == 0) {
						this.computeNextPWMInterval();
						this.PWMWidthOld = this.PWMWidthShadow | 0;
						this.PWMWidth = this.PWMWidthShadow | 0;
					}
				}
			}
			else {
				//SILENT OUTPUT:
				while ((numSamples | 0) > 0) {
					multiplier = Math.min(numSamples | 0, ((this.audioResamplerFirstPassFactor | 0) - (this.audioIndex | 0)) | 0) | 0;
					numSamples = ((numSamples | 0) - (multiplier | 0)) | 0;
					this.audioIndex = ((this.audioIndex | 0) + (multiplier | 0)) | 0;
					if ((this.audioIndex | 0) == (this.audioResamplerFirstPassFactor | 0)) {
						this.audioIndex = 0;
						this.emulatorCore.outputAudio(this.downsampleInputLeft | 0, this.downsampleInputRight | 0);
						this.downsampleInputLeft = 0;
						this.downsampleInputRight = 0;
					}
				}
			}
		}
		//Generate audio, but don't actually output it (Used for when sound is disabled by user/browser):
		public function generateAudioFake(numSamples) {
			numSamples = numSamples | 0;
			if (this.soundMasterEnabled && this.IOCore.systemStatus < 4) {
				for (var clockUpTo = 0; (numSamples | 0) > 0;) {
					clockUpTo = Math.min(this.PWMWidth | 0, numSamples | 0) | 0;
					this.PWMWidth = ((this.PWMWidth | 0) - (clockUpTo | 0)) | 0;
					numSamples = ((numSamples | 0) - (clockUpTo | 0)) | 0;
					if ((this.PWMWidth | 0) == 0) {
						this.computeNextPWMInterval();
						this.PWMWidthOld = this.PWMWidthShadow | 0;
						this.PWMWidth = this.PWMWidthShadow | 0;
					}
				}
			}
		}
		public function preprocessInitialization(audioInitialized) {
			trace("init audio: " + audioInitialized);
			if (audioInitialized) {
				
				this.generateAudio = (MathsHelper.imul != null) ? this.generateAudioOptimized : this.generateAudioSlow;
				this.audioInitialized = true;
			}
			else {
				this.generateAudio = this.generateAudioFake;
				this.audioInitialized = false;
			}
		}
		public function audioJIT() {
			//Audio Sample Generation Timing:
			this.generateAudio(this.audioTicks | 0);
			this.audioTicks = 0;
		}
		public function computeNextPWMInterval() {
			//Clock down the PSG system:
			for (var numSamples = this.PWMWidthOld | 0, clockUpTo = 0; numSamples > 0; numSamples = ((numSamples | 0) - 1) | 0) {
				clockUpTo = Math.min(this.audioClocksUntilNextEventCounter | 0, this.sequencerClocks | 0, numSamples | 0) | 0;
				this.audioClocksUntilNextEventCounter = ((this.audioClocksUntilNextEventCounter | 0) - (clockUpTo | 0)) | 0;
				this.sequencerClocks = ((this.sequencerClocks | 0) - (clockUpTo | 0)) | 0;
				numSamples = ((numSamples | 0) - (clockUpTo | 0)) | 0;
				if ((this.sequencerClocks | 0) == 0) {
					this.audioComputeSequencer();
					this.sequencerClocks = 0x8000;
				}
				if ((this.audioClocksUntilNextEventCounter | 0) == 0) {
					this.computeAudioChannels();
				}
			}
			//Copy the new bit-depth mask for the next counter interval:
			this.PWMBitDepthMask = this.PWMBitDepthMaskShadow | 0;
			//Compute next sample for the PWM output:
			this.channel1OutputLevelCache();
			this.channel2OutputLevelCache();
			this.channel3UpdateCache();
			this.channel4UpdateCache();
			this.CGBMixerOutputLevelCache();
			this.mixerOutputLevelCache();
		}
		public function audioComputeSequencer() {
			switch (this.sequencePosition++) {
				case 0:
					this.clockAudioLength();
					break;
				case 2:
					this.clockAudioLength();
					this.clockAudioSweep();
					break;
				case 4:
					this.clockAudioLength();
					break;
				case 6:
					this.clockAudioLength();
					this.clockAudioSweep();
					break;
				case 7:
					this.clockAudioEnvelope();
					this.sequencePosition = 0;
			}
		}
		public function clockAudioLength() {
			//Channel 1:
			if (this.channel1totalLength > 1) {
				--this.channel1totalLength;
			}
			else if (this.channel1totalLength == 1) {
				this.channel1totalLength = 0;
				this.channel1EnableCheck();
				this.nr52 &= 0xFE;	//Channel #1 On Flag Off
			}
			//Channel 2:
			if (this.channel2totalLength > 1) {
				--this.channel2totalLength;
			}
			else if (this.channel2totalLength == 1) {
				this.channel2totalLength = 0;
				this.channel2EnableCheck();
				this.nr52 &= 0xFD;	//Channel #2 On Flag Off
			}
			//Channel 3:
			if (this.channel3totalLength > 1) {
				--this.channel3totalLength;
			}
			else if (this.channel3totalLength == 1) {
				this.channel3totalLength = 0;
				this.channel3EnableCheck();
				this.nr52 &= 0xFB;	//Channel #3 On Flag Off
			}
			//Channel 4:
			if (this.channel4totalLength > 1) {
				--this.channel4totalLength;
			}
			else if (this.channel4totalLength == 1) {
				this.channel4totalLength = 0;
				this.channel4EnableCheck();
				this.nr52 &= 0xF7;	//Channel #4 On Flag Off
			}
		}
		public function clockAudioSweep() {
			//Channel 1:
			if (!this.channel1SweepFault && this.channel1timeSweep > 0) {
				if (--this.channel1timeSweep == 0) {
					this.runAudioSweep();
				}
			}
		}
		public function runAudioSweep() {
			//Channel 1:
			if (this.channel1lastTimeSweep > 0) {
				if (this.channel1frequencySweepDivider > 0) {
					this.channel1Swept = true;
					if (this.channel1decreaseSweep) {
						this.channel1ShadowFrequency -= this.channel1ShadowFrequency >> this.channel1frequencySweepDivider;
						this.channel1frequency = this.channel1ShadowFrequency & 0x7FF;
						this.channel1FrequencyTracker = (0x800 - this.channel1frequency) << 4;
					}
					else {
						this.channel1ShadowFrequency += this.channel1ShadowFrequency >> this.channel1frequencySweepDivider;
						this.channel1frequency = this.channel1ShadowFrequency;
						if (this.channel1ShadowFrequency <= 0x7FF) {
							this.channel1FrequencyTracker = (0x800 - this.channel1frequency) << 4;
							//Run overflow check twice:
							if ((this.channel1ShadowFrequency + (this.channel1ShadowFrequency >> this.channel1frequencySweepDivider)) > 0x7FF) {
								this.channel1SweepFault = true;
								this.channel1EnableCheck();
								this.nr52 &= 0xFE;	//Channel #1 On Flag Off
							}
						}
						else {
							this.channel1frequency &= 0x7FF;
							this.channel1SweepFault = true;
							this.channel1EnableCheck();
							this.nr52 &= 0xFE;	//Channel #1 On Flag Off
						}
					}
					this.channel1timeSweep = this.channel1lastTimeSweep;
				}
				else {
					//Channel has sweep disabled and timer becomes a length counter:
					this.channel1SweepFault = true;
					this.channel1EnableCheck();
				}
			}
		}
		public function channel1AudioSweepPerformDummy() {
			//Channel 1:
			if (this.channel1frequencySweepDivider > 0) {
				if (!this.channel1decreaseSweep) {
					var channel1ShadowFrequency = this.channel1ShadowFrequency + (this.channel1ShadowFrequency >> this.channel1frequencySweepDivider);
					if (channel1ShadowFrequency <= 0x7FF) {
						//Run overflow check twice:
						if ((channel1ShadowFrequency + (channel1ShadowFrequency >> this.channel1frequencySweepDivider)) > 0x7FF) {
							this.channel1SweepFault = true;
							this.channel1EnableCheck();
							this.nr52 &= 0xFE;	//Channel #1 On Flag Off
						}
					}
					else {
						this.channel1SweepFault = true;
						this.channel1EnableCheck();
						this.nr52 &= 0xFE;	//Channel #1 On Flag Off
					}
				}
			}
		}
		public function clockAudioEnvelope() {
			//Channel 1:
			if (this.channel1envelopeSweepsLast > -1) {
				if (this.channel1envelopeSweeps > 0) {
					--this.channel1envelopeSweeps;
				}
				else {
					if (!this.channel1envelopeType) {
						if (this.channel1envelopeVolume > 0) {
							--this.channel1envelopeVolume;
							this.channel1envelopeSweeps = this.channel1envelopeSweepsLast;
						}
						else {
							this.channel1envelopeSweepsLast = -1;
						}
					}
					else if (this.channel1envelopeVolume < 0xF) {
						++this.channel1envelopeVolume;
						this.channel1envelopeSweeps = this.channel1envelopeSweepsLast;
					}
					else {
						this.channel1envelopeSweepsLast = -1;
					}
				}
			}
			//Channel 2:
			if (this.channel2envelopeSweepsLast > -1) {
				if (this.channel2envelopeSweeps > 0) {
					--this.channel2envelopeSweeps;
				}
				else {
					if (!this.channel2envelopeType) {
						if (this.channel2envelopeVolume > 0) {
							--this.channel2envelopeVolume;
							this.channel2envelopeSweeps = this.channel2envelopeSweepsLast;
						}
						else {
							this.channel2envelopeSweepsLast = -1;
						}
					}
					else if (this.channel2envelopeVolume < 0xF) {
						++this.channel2envelopeVolume;
						this.channel2envelopeSweeps = this.channel2envelopeSweepsLast;
					}
					else {
						this.channel2envelopeSweepsLast = -1;
					}
				}
			}
			//Channel 4:
			if (this.channel4envelopeSweepsLast > -1) {
				if (this.channel4envelopeSweeps > 0) {
					--this.channel4envelopeSweeps;
				}
				else {
					if (!this.channel4envelopeType) {
						if (this.channel4envelopeVolume > 0) {
							this.channel4currentVolume = --this.channel4envelopeVolume << this.channel4VolumeShifter;
							this.channel4envelopeSweeps = this.channel4envelopeSweepsLast;
						}
						else {
							this.channel4envelopeSweepsLast = -1;
						}
					}
					else if (this.channel4envelopeVolume < 0xF) {
						this.channel4currentVolume = ++this.channel4envelopeVolume << this.channel4VolumeShifter;
						this.channel4envelopeSweeps = this.channel4envelopeSweepsLast;
					}
					else {
						this.channel4envelopeSweepsLast = -1;
					}
				}
			}
		}
		public function computeAudioChannels() {
			//Clock down the four audio channels to the next closest audio event:
			this.channel1FrequencyCounter -= this.audioClocksUntilNextEvent;
			this.channel2FrequencyCounter -= this.audioClocksUntilNextEvent;
			this.channel3Counter -= this.audioClocksUntilNextEvent;
			this.channel4Counter -= this.audioClocksUntilNextEvent;
			//Channel 1 counter:
			if (this.channel1FrequencyCounter == 0) {
				this.channel1FrequencyCounter = this.channel1FrequencyTracker;
				this.channel1DutyTracker = (this.channel1DutyTracker + 1) & 0x7;
			}
			//Channel 2 counter:
			if (this.channel2FrequencyCounter == 0) {
				this.channel2FrequencyCounter = this.channel2FrequencyTracker;
				this.channel2DutyTracker = (this.channel2DutyTracker + 1) & 0x7;
			}
			//Channel 3 counter:
			if (this.channel3Counter == 0) {
				if (this.channel3canPlay) {
					this.channel3lastSampleLookup = (this.channel3lastSampleLookup + 1) & this.channel3WaveRAMBankSize;
				}
				this.channel3Counter = this.channel3FrequencyPeriod;
			}
			//Channel 4 counter:
			if (this.channel4Counter == 0) {
				this.channel4lastSampleLookup = (this.channel4lastSampleLookup + 1) & this.channel4BitRange;
				this.channel4Counter = this.channel4FrequencyPeriod;
			}
			//Find the number of clocks to next closest counter event:
			this.audioClocksUntilNextEventCounter = this.audioClocksUntilNextEvent = Math.min(this.channel1FrequencyCounter, this.channel2FrequencyCounter, this.channel3Counter, this.channel4Counter);
		}
		public function channel1EnableCheck() {
			this.channel1Enabled = ((this.channel1consecutive || this.channel1totalLength > 0) && !this.channel1SweepFault && this.channel1canPlay);
		}
		public function channel1VolumeEnableCheck() {
			this.channel1canPlay = (this.nr12 > 7);
			this.channel1EnableCheck();
		}
		public function channel1OutputLevelCache() {
			this.channel1currentSampleLeft = (this.leftChannel1) ? this.channel1envelopeVolume : 0;
			this.channel1currentSampleRight = (this.rightChannel1) ? this.channel1envelopeVolume : 0;
			this.channel1OutputLevelSecondaryCache();
		}
		public function channel1OutputLevelSecondaryCache() {
			if (this.channel1Enabled) {
				this.channel1currentSampleLeftSecondary = this.channel1currentSampleLeft;
				this.channel1currentSampleRightSecondary = this.channel1currentSampleRight;
			}
			else {
				this.channel1currentSampleLeftSecondary = 0;
				this.channel1currentSampleRightSecondary = 0;
			}
			this.channel1OutputLevelTrimaryCache();
		}
		public function channel1OutputLevelTrimaryCache() {
			if (this.channel1CachedDuty[this.channel1DutyTracker]) {
				this.channel1currentSampleLeftTrimary = this.channel1currentSampleLeftSecondary;
				this.channel1currentSampleRightTrimary = this.channel1currentSampleRightSecondary;
			}
			else {
				this.channel1currentSampleLeftTrimary = 0;
				this.channel1currentSampleRightTrimary = 0;
			}
		}
		public function channel2EnableCheck() {
			this.channel2Enabled = ((this.channel2consecutive || this.channel2totalLength > 0) && this.channel2canPlay);
		}
		public function channel2VolumeEnableCheck() {
			this.channel2canPlay = (this.nr22 > 7);
			this.channel2EnableCheck();
		}
		public function channel2OutputLevelCache() {
			this.channel2currentSampleLeft = (this.leftChannel2) ? this.channel2envelopeVolume : 0;
			this.channel2currentSampleRight = (this.rightChannel2) ? this.channel2envelopeVolume : 0;
			this.channel2OutputLevelSecondaryCache();
		}
		public function channel2OutputLevelSecondaryCache() {
			if (this.channel2Enabled) {
				this.channel2currentSampleLeftSecondary = this.channel2currentSampleLeft;
				this.channel2currentSampleRightSecondary = this.channel2currentSampleRight;
			}
			else {
				this.channel2currentSampleLeftSecondary = 0;
				this.channel2currentSampleRightSecondary = 0;
			}
			this.channel2OutputLevelTrimaryCache();
		}
		public function channel2OutputLevelTrimaryCache() {
			if (this.channel2CachedDuty[this.channel2DutyTracker]) {
				this.channel2currentSampleLeftTrimary = this.channel2currentSampleLeftSecondary;
				this.channel2currentSampleRightTrimary = this.channel2currentSampleRightSecondary;
			}
			else {
				this.channel2currentSampleLeftTrimary = 0;
				this.channel2currentSampleRightTrimary = 0;
			}
		}
		public function channel3EnableCheck() {
			this.channel3Enabled = (/*this.channel3canPlay && */(this.channel3consecutive || this.channel3totalLength > 0));
		}
		public function channel3OutputLevelCache() {
			this.channel3currentSampleLeft = (this.leftChannel3) ? this.cachedChannel3Sample : 0;
			this.channel3currentSampleRight = (this.rightChannel3) ? this.cachedChannel3Sample : 0;
			this.channel3OutputLevelSecondaryCache();
		}
		public function channel3OutputLevelSecondaryCache() {
			if (this.channel3Enabled) {
				this.channel3currentSampleLeftSecondary = this.channel3currentSampleLeft;
				this.channel3currentSampleRightSecondary = this.channel3currentSampleRight;
			}
			else {
				this.channel3currentSampleLeftSecondary = 0;
				this.channel3currentSampleRightSecondary = 0;
			}
		}
		public function channel4EnableCheck() {
			this.channel4Enabled = ((this.channel4consecutive || this.channel4totalLength > 0) && this.channel4canPlay);
		}
		public function channel4VolumeEnableCheck() {
			this.channel4canPlay = (this.nr42 > 7);
			this.channel4EnableCheck();
		}
		public function channel4OutputLevelCache() {
			this.channel4currentSampleLeft = (this.leftChannel4) ? this.cachedChannel4Sample : 0;
			this.channel4currentSampleRight = (this.rightChannel4) ? this.cachedChannel4Sample : 0;
			this.channel4OutputLevelSecondaryCache();
		}
		public function channel4OutputLevelSecondaryCache() {
			if (this.channel4Enabled) {
				this.channel4currentSampleLeftSecondary = this.channel4currentSampleLeft;
				this.channel4currentSampleRightSecondary = this.channel4currentSampleRight;
			}
			else {
				this.channel4currentSampleLeftSecondary = 0;
				this.channel4currentSampleRightSecondary = 0;
			}
		}
		public function CGBMixerOutputLevelCache() {
			this.CGBMixerOutputCacheLeft = (this.channel1currentSampleLeftTrimary + this.channel2currentSampleLeftTrimary + this.channel3currentSampleLeftSecondary + this.channel4currentSampleLeftSecondary) * this.VinLeftChannelMasterVolume;
			this.CGBMixerOutputCacheRight = (this.channel1currentSampleRightTrimary + this.channel2currentSampleRightTrimary + this.channel3currentSampleRightSecondary + this.channel4currentSampleRightSecondary) * this.VinRightChannelMasterVolume;
			this.CGBFolder();
		}
		public function channel3UpdateCache() {
			if (this.channel3patternType < 5) {
				this.cachedChannel3Sample = this.channel3PCM[this.channel3lastSampleLookup] >> this.channel3patternType;
			}
			else {
				this.cachedChannel3Sample = (this.channel3PCM[this.channel3lastSampleLookup] * 0.75) | 0;
			}
			this.channel3OutputLevelCache();
		}
		public function writeWAVE(address, data) {
			if (this.channel3canPlay) {
				this.audioJIT();
			}
			address += this.channel3WAVERAMBankSpecified;
			this.WAVERAM[address] = data;
			address <<= 1;
			this.channel3PCM[address] = data >> 4;
			this.channel3PCM[address | 1] = data & 0xF;
		}
		public function readWAVE(address) {
			return this.WAVERAM[address + this.channel3WAVERAMBankSpecified];
		}
		public function channel4UpdateCache() {
			this.cachedChannel4Sample = this.noiseSampleTable[this.channel4currentVolume | this.channel4lastSampleLookup];
			this.channel4OutputLevelCache();
		}
		public function writeFIFOA(data) {
			data = data | 0;
			this.FIFOABuffer.push(data | 0);
			if (this.FIFOABuffer.requestingDMA()) {
				this.IOCore.dma.soundFIFOARequest();
			}
		}
		public function checkFIFOAPendingSignal() {
			if (this.FIFOABuffer.requestingDMA()) {
				this.IOCore.dma.soundFIFOARequest();
			}
		}
		public function checkFIFOBPendingSignal() {
			if (this.FIFOBBuffer.requestingDMA()) {
				this.IOCore.dma.soundFIFOBRequest();
			}
		}
		public function writeFIFOB(data) {
			data = data | 0;
			this.FIFOBBuffer.push(data | 0);
			if (this.FIFOBBuffer.requestingDMA()) {
				this.IOCore.dma.soundFIFOBRequest();
			}
		}
		public function AGBDirectSoundAFIFOClear() {
			this.FIFOABuffer.count = 0;
			this.AGBDirectSoundATimerIncrement();
		}
		public function AGBDirectSoundBFIFOClear() {
			this.FIFOBBuffer.count = 0;
			this.AGBDirectSoundBTimerIncrement();
		}
		public function AGBDirectSoundTimer0ClockTick() {
			this.audioJIT();
			if (this.AGBDirectSoundATimer == 0) {
				this.AGBDirectSoundATimerIncrement();
			}
			if (this.AGBDirectSoundBTimer == 0) {
				this.AGBDirectSoundBTimerIncrement();
			}
		}
		public function AGBDirectSoundTimer1ClockTick() {
			this.audioJIT();
			if (this.AGBDirectSoundATimer == 1) {
				this.AGBDirectSoundATimerIncrement();
			}
			if (this.AGBDirectSoundBTimer == 1) {
				this.AGBDirectSoundBTimerIncrement();
			}
		}
		public function nextFIFOAEventTime() {
			if (!this.FIFOABuffer.requestingDMA()) {
				return this.IOCore.timer.nextTimer0Overflow(this.FIFOABuffer.count - 0x10);
			}
			else {
				return 0;
			}
		}
		public function nextFIFOBEventTime() {
			if (!this.FIFOBBuffer.requestingDMA()) {
				return this.IOCore.timer.nextTimer1Overflow(this.FIFOBBuffer.count - 0x10);
			}
			else {
				return 0;
			}
		}
		public function AGBDirectSoundATimerIncrement() {
			this.AGBDirectSoundA = this.FIFOABuffer.shift() | 0;
			this.checkFIFOAPendingSignal();
			this.AGBFIFOAFolder();
		}
		public function AGBDirectSoundBTimerIncrement() {
			this.AGBDirectSoundB = this.FIFOBBuffer.shift() | 0;
			this.checkFIFOBPendingSignal();
			this.AGBFIFOBFolder();
		}
		public function AGBFIFOAFolder() {
			this.AGBDirectSoundAFolded = this.AGBDirectSoundA >> this.AGBDirectSoundAShifter;
		}
		public function AGBFIFOBFolder() {
			this.AGBDirectSoundBFolded = this.AGBDirectSoundB >> this.AGBDirectSoundBShifter;
		}
		public function CGBFolder() {
			this.CGBMixerOutputCacheLeftFolded = (this.CGBMixerOutputCacheLeft << this.CGBOutputRatio) >> 1;
			this.CGBMixerOutputCacheRightFolded = (this.CGBMixerOutputCacheRight << this.CGBOutputRatio) >> 1;
		}
		public function mixerOutputLevelCache() {
			this.mixerOutputCacheLeft = Math.min(Math.max(((this.AGBDirectSoundALeftCanPlay) ? this.AGBDirectSoundAFolded : 0) +
			((this.AGBDirectSoundBLeftCanPlay) ? this.AGBDirectSoundBFolded : 0) +
			this.CGBMixerOutputCacheLeftFolded + this.mixerSoundBIAS, 0), 0x3FF) & this.PWMBitDepthMask;
			this.mixerOutputCacheRight = Math.min(Math.max(((this.AGBDirectSoundARightCanPlay) ? this.AGBDirectSoundAFolded : 0) +
			((this.AGBDirectSoundBRightCanPlay) ? this.AGBDirectSoundBFolded : 0) +
			this.CGBMixerOutputCacheRightFolded + this.mixerSoundBIAS, 0), 0x3FF) & this.PWMBitDepthMask;
		}
		public function readSOUND1CNT_L() {
			//NR10:
			return 0x80 | this.nr10;
		}
		public function writeSOUND1CNT_L(data) {
			data = data | 0;
			//NR10:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				if (this.channel1decreaseSweep && (data & 0x08) == 0) {
					if (this.channel1Swept) {
						this.channel1SweepFault = true;
					}
				}
				this.channel1lastTimeSweep = (data & 0x70) >> 4;
				this.channel1frequencySweepDivider = data & 0x07;
				this.channel1decreaseSweep = ((data & 0x08) == 0x08);
				this.nr10 = data | 0;
				this.channel1EnableCheck();
			}
		}
		public function readSOUND1CNT_H0() {
			//NR11:
			return 0x3F | this.nr11;
		}
		public function writeSOUND1CNT_H0(data) {
			data = data | 0;
			//NR11:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				this.channel1CachedDuty = this.dutyLookup[data >> 6];
				this.channel1totalLength = 0x40 - (data & 0x3F);
				this.nr11 = data | 0;
				this.channel1EnableCheck();
			}
		}
		public function readSOUND1CNT_H1() {
			//NR12:
			return this.nr12 | 0;
		}
		public function writeSOUND1CNT_H1(data) {
			data = data | 0;
			//NR12:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				if (this.channel1Enabled && this.channel1envelopeSweeps == 0) {
					//Zombie Volume PAPU Bug:
					if (((this.nr12 ^ data) & 0x8) == 0x8) {
						if ((this.nr12 & 0x8) == 0) {
							if ((this.nr12 & 0x7) == 0x7) {
								this.channel1envelopeVolume += 2;
							}
							else {
								++this.channel1envelopeVolume;
							}
						}
						this.channel1envelopeVolume = (16 - this.channel1envelopeVolume) & 0xF;
					}
					else if ((this.nr12 & 0xF) == 0x8) {
						this.channel1envelopeVolume = (1 + this.channel1envelopeVolume) & 0xF;
					}
				}
				this.channel1envelopeType = ((data & 0x08) == 0x08);
				this.nr12 = data | 0;
				this.channel1VolumeEnableCheck();
			}
		}
		public function writeSOUND1CNT_X0(data) {
			data = data | 0;
			//NR13:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				this.channel1frequency = (this.channel1frequency & 0x700) | data;
				this.channel1FrequencyTracker = (0x800 - this.channel1frequency) << 4;
			}
		}
		public function readSOUND1CNT_X() {
			//NR14:
			return 0xBF | this.nr14;
		}
		public function writeSOUND1CNT_X1(data) {
			data = data | 0;
			//NR14:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				this.channel1consecutive = ((data & 0x40) == 0x0);
				this.channel1frequency = ((data & 0x7) << 8) | (this.channel1frequency & 0xFF);
				this.channel1FrequencyTracker = (0x800 - this.channel1frequency) << 4;
				if (data > 0x7F) {
					//Reload nr10:
					this.channel1timeSweep = this.channel1lastTimeSweep;
					this.channel1Swept = false;
					//Reload nr12:
					this.channel1envelopeVolume = this.nr12 >> 4;
					this.channel1envelopeSweepsLast = (this.nr12 & 0x7) - 1;
					if (this.channel1totalLength == 0) {
						this.channel1totalLength = 0x40;
					}
					if (this.channel1lastTimeSweep > 0 || this.channel1frequencySweepDivider > 0) {
						this.nr52 |= 0x1;
					}
					else {
						this.nr52 &= 0xFE;
					}
					if ((data & 0x40) == 0x40) {
						this.nr52 |= 0x1;
					}
					this.channel1ShadowFrequency = this.channel1frequency;
					//Reset frequency overflow check + frequency sweep type check:
					this.channel1SweepFault = false;
					//Supposed to run immediately:
					this.channel1AudioSweepPerformDummy();
				}
				this.channel1EnableCheck();
				this.nr14 = data | 0;
			}
		}
		public function readSOUND2CNT_L0() {
			//NR21:
			return 0x3F | this.nr21;
		}
		public function writeSOUND2CNT_L0(data) {
			data = data | 0;
			//NR21:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				this.channel2CachedDuty = this.dutyLookup[data >> 6];
				this.channel2totalLength = 0x40 - (data & 0x3F);
				this.nr21 = data | 0;
				this.channel2EnableCheck();
			}
		}
		public function readSOUND2CNT_L1() {
			//NR22:
			return this.nr22 | 0;
		}
		public function writeSOUND2CNT_L1(data) {
			//NR22:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				if (this.channel2Enabled && this.channel2envelopeSweeps == 0) {
					//Zombie Volume PAPU Bug:
					if (((this.nr22 ^ data) & 0x8) == 0x8) {
						if ((this.nr22 & 0x8) == 0) {
							if ((this.nr22 & 0x7) == 0x7) {
								this.channel2envelopeVolume += 2;
							}
							else {
								++this.channel2envelopeVolume;
							}
						}
						this.channel2envelopeVolume = (16 - this.channel2envelopeVolume) & 0xF;
					}
					else if ((this.nr12 & 0xF) == 0x8) {
						this.channel2envelopeVolume = (1 + this.channel2envelopeVolume) & 0xF;
					}
				}
				this.channel2envelopeType = ((data & 0x08) == 0x08);
				this.nr22 = data | 0;
				this.channel2VolumeEnableCheck();
			}
		}
		public function writeSOUND2CNT_H0(data) {
			data = data | 0;
			//NR23:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				this.channel2frequency = (this.channel2frequency & 0x700) | data;
				this.channel2FrequencyTracker = (0x800 - this.channel2frequency) << 4;
			}
		}
		public function readSOUND2CNT_H() {
			//NR24:
			return 0xBF | this.nr24;
		}
		public function writeSOUND2CNT_H1(data) {
			data = data | 0;
			//NR24:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				if (data > 0x7F) {
					//Reload nr22:
					this.channel2envelopeVolume = this.nr22 >> 4;
					this.channel2envelopeSweepsLast = (this.nr22 & 0x7) - 1;
					if (this.channel2totalLength == 0) {
						this.channel2totalLength = 0x40;
					}
					if ((data & 0x40) == 0x40) {
						this.nr52 |= 0x2;
					}
				}
				this.channel2consecutive = ((data & 0x40) == 0x0);
				this.channel2frequency = ((data & 0x7) << 8) | (this.channel2frequency & 0xFF);
				this.channel2FrequencyTracker = (0x800 - this.channel2frequency) << 4;
				this.nr24 = data | 0;
				this.channel2EnableCheck();
			}
		}
		public function readSOUND3CNT_L() {
			//NR30:
			return 0x1F | this.nr30;
		}
		public function writeSOUND3CNT_L(data) {
			data = data | 0;
			//NR30:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				if (!this.channel3canPlay && data >= 0x80) {
					this.channel3lastSampleLookup = 0;
				}
				this.channel3canPlay = (data > 0x7F);
				this.channel3WAVERAMBankSpecified = 0x20 ^ ((data & 0x40) >> 1);
				this.channel3WaveRAMBankSize = (data & 0x20) | 0x1F;
				if (this.channel3canPlay && this.nr30 > 0x7F && !this.channel3consecutive) {
					this.nr52 |= 0x4;
				}
				this.nr30 = data | 0;
			}
		}
		public function writeSOUND3CNT_H0(data) {
			data = data | 0;
			//NR31:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				this.channel3totalLength = 0x100 - data;
				this.channel3EnableCheck();
			}
		}
		public function readSOUND3CNT_H() {
			//NR32:
			return 0x1F | this.nr32;
		}
		public function writeSOUND3CNT_H1(data) {
			data = data | 0;
			//NR32:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				this.channel3patternType = (data < 0x20) ? 4 : ((data >> 5) - 1);
				this.nr32 = data | 0;
			}
		}
		public function writeSOUND3CNT_X0(data) {
			data = data | 0;
			//NR33:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				this.channel3frequency = (this.channel3frequency & 0x700) | data;
				this.channel3FrequencyPeriod = (0x800 - this.channel3frequency) << 3;
			}
		}
		public function readSOUND3CNT_X() {
			//NR34:
			return 0xBF | this.nr34;
		}
		public function writeSOUND3CNT_X1(data) {
			data = data | 0;
			//NR34:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				if (data > 0x7F) {
					if (this.channel3totalLength == 0) {
						this.channel3totalLength = 0x100;
					}
					this.channel3lastSampleLookup = 0;
					if ((data & 0x40) == 0x40) {
						this.nr52 |= 0x4;
					}
				}
				this.channel3consecutive = ((data & 0x40) == 0x0);
				this.channel3frequency = ((data & 0x7) << 8) | (this.channel3frequency & 0xFF);
				this.channel3FrequencyPeriod = (0x800 - this.channel3frequency) << 3;
				this.channel3EnableCheck();
				this.nr34 = data | 0;
			}
		}
		public function writeSOUND4CNT_L0(data) {
			//NR41:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				this.channel4totalLength = 0x40 - (data & 0x3F);
				this.channel4EnableCheck();
			}
		}
		public function writeSOUND4CNT_L1(data) {
			data = data | 0;
			//NR42:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				if (this.channel4Enabled && this.channel4envelopeSweeps == 0) {
					//Zombie Volume PAPU Bug:
					if (((this.nr42 ^ data) & 0x8) == 0x8) {
						if ((this.nr42 & 0x8) == 0) {
							if ((this.nr42 & 0x7) == 0x7) {
								this.channel4envelopeVolume += 2;
							}
							else {
								++this.channel4envelopeVolume;
							}
						}
						this.channel4envelopeVolume = (16 - this.channel4envelopeVolume) & 0xF;
					}
					else if ((this.nr42 & 0xF) == 0x8) {
						this.channel4envelopeVolume = (1 + this.channel4envelopeVolume) & 0xF;
					}
					this.channel4currentVolume = this.channel4envelopeVolume << this.channel4VolumeShifter;
				}
				this.channel4envelopeType = ((data & 0x08) == 0x08);
				this.nr42 = data | 0;
				this.channel4VolumeEnableCheck();
			}
		}
		public function readSOUND4CNT_L() {
			//NR42:
			return this.nr42 | 0;
		}
		public function writeSOUND4CNT_H0(data) {
			data = data | 0;
			//NR43:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				this.channel4FrequencyPeriod = Math.max((data & 0x7) << 4, 8) << ((data >> 4) + 2);
				var bitWidth = (data & 0x8);
				if ((bitWidth == 0x8 && this.channel4BitRange == 0x7FFF) || (bitWidth == 0 && this.channel4BitRange == 0x7F)) {
					this.channel4lastSampleLookup = 0;
					this.channel4BitRange = (bitWidth == 0x8) ? 0x7F : 0x7FFF;
					this.channel4VolumeShifter = (bitWidth == 0x8) ? 7 : 15;
					this.channel4currentVolume = this.channel4envelopeVolume << this.channel4VolumeShifter;
					this.noiseSampleTable = (bitWidth == 0x8) ? this.LSFR7Table : this.LSFR15Table;
				}
				this.nr43 = data | 0;
			}
		}
		public function readSOUND4CNT_H0() {
			//NR43:
			return this.nr43 | 0;
		}
		public function writeSOUND4CNT_H1(data) {
			data = data | 0;
			//NR44:
			if (this.soundMasterEnabled) {
				this.audioJIT();
				this.nr44 = data | 0;
				this.channel4consecutive = ((data & 0x40) == 0x0);
				if (data > 0x7F) {
					this.channel4envelopeVolume = this.nr42 >> 4;
					this.channel4currentVolume = this.channel4envelopeVolume << this.channel4VolumeShifter;
					this.channel4envelopeSweepsLast = (this.nr42 & 0x7) - 1;
					if (this.channel4totalLength == 0) {
						this.channel4totalLength = 0x40;
					}
					if ((data & 0x40) == 0x40) {
						this.nr52 |= 0x8;
					}
				}
				this.channel4EnableCheck();
			}
		}
		public function readSOUND4CNT_H1() {
			//NR44:
			return 0xBF | this.nr44;
		}
		public function writeSOUNDCNT_L0(data) {
			data = data | 0;
			//NR50:
			if (this.soundMasterEnabled && this.nr50 != data) {
				this.audioJIT();
				this.nr50 = data | 0;
				this.VinLeftChannelMasterVolume = ((data >> 4) & 0x07) + 1;
				this.VinRightChannelMasterVolume = (data & 0x07) + 1;
			}
		}
		public function readSOUNDCNT_L0() {
			//NR50:
			return 0x88 | this.nr50;
		}
		public function writeSOUNDCNT_L1(data) {
			data = data | 0;
			//NR51:
			if (this.soundMasterEnabled && this.nr51 != data) {
				this.audioJIT();
				this.nr51 = data | 0;
				this.rightChannel1 = ((data & 0x01) == 0x01);
				this.rightChannel2 = ((data & 0x02) == 0x02);
				this.rightChannel3 = ((data & 0x04) == 0x04);
				this.rightChannel4 = ((data & 0x08) == 0x08);
				this.leftChannel1 = ((data & 0x10) == 0x10);
				this.leftChannel2 = ((data & 0x20) == 0x20);
				this.leftChannel3 = ((data & 0x40) == 0x40);
				this.leftChannel4 = (data > 0x7F);
			}
		}
		public function readSOUNDCNT_L1() {
			//NR51:
			return this.nr51 | 0;
		}
		public function writeSOUNDCNT_H0(data) {
			data = data | 0;
			//NR60:
			this.audioJIT();
			this.CGBOutputRatio = data & 0x3;
			this.AGBDirectSoundAShifter = (data & 0x04) >> 2;
			this.AGBDirectSoundBShifter = (data & 0x08) >> 3;
			this.nr60 = data | 0;
		}
		public function readSOUNDCNT_H0() {
			//NR60:
			return 0xF0 | this.nr60;
		}
		public function writeSOUNDCNT_H1(data) {
			data = data | 0;
			//NR61:
			this.audioJIT();
			this.AGBDirectSoundARightCanPlay = ((data & 0x1) == 0x1);
			this.AGBDirectSoundALeftCanPlay = ((data & 0x2) == 0x2);
			this.AGBDirectSoundATimer = (data & 0x4) >> 2;
			if ((data & 0x08) == 0x08) {
				this.AGBDirectSoundAFIFOClear();
			}
			this.AGBDirectSoundBRightCanPlay = ((data & 0x10) == 0x10);
			this.AGBDirectSoundBLeftCanPlay = ((data & 0x20) == 0x20);
			this.AGBDirectSoundBTimer = (data & 0x40) >> 6;
			if ((data & 0x80) == 0x80) {
				this.AGBDirectSoundBFIFOClear();
			}
			this.nr61 = data | 0;
		}
		public function readSOUNDCNT_H1() {
			//NR61:
			return this.nr61 | 0;
		}
		public function writeSOUNDCNT_X(data) {
			data = data | 0;
			//NR52:
			if (!this.soundMasterEnabled && data > 0x7F) {
				this.audioJIT();
				this.audioEnabled();
			}
			else if (this.soundMasterEnabled && data < 0x80) {
				this.audioJIT();
				this.audioDisabled();
			}
		}
		public function readSOUNDCNT_X() {
			//NR52:
			return 0x70 | this.nr52;
		}
		public function writeSOUNDBIAS0(data) {
			data = data | 0;
			//NR62:
			this.audioJIT();
			this.mixerSoundBIAS &= 0x300;
			this.mixerSoundBIAS |= data;
			this.nr62 = data | 0;
		}
		public function readSOUNDBIAS0() {
			//NR62:
			return this.nr62 | 0;
		}
		public function writeSOUNDBIAS1(data) {
			data = data | 0;
			//NR63:
			this.audioJIT();
			this.mixerSoundBIAS &= 0xFF;
			this.mixerSoundBIAS |= (data & 0x3) << 8;
			this.PWMWidthShadow = 0x200 >> ((data & 0xC0) >> 6);
			this.PWMBitDepthMask = (this.PWMWidthShadow - 1) << (1 + ((data & 0xC0) >> 6)); 
			this.nr63 = data | 0;
		}
		public function readSOUNDBIAS1() {
			//NR63:
			return 0x2C | this.nr63;
		}
				
		

	}
	
}
