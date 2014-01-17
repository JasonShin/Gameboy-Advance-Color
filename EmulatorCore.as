package  {
	import flash.display.Stage;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import graphics.GameBoyAdvanceCanvas;
	import FileLoader.LocalLoader;
	import utils.ArrayHelper;
	import flash.utils.ByteArray;
	import flash.geom.Rectangle;
	import flash.display.MovieClip;
	
	public class EmulatorCore extends MovieClip{
			
		public var SKIPBoot:Boolean;
		public var dynarecEnabled:Boolean;
		public var dynarecTHUMB:Boolean;
		public var dynarecARM:Boolean;
		public var emulatorSpeed:int;
		public var timerIntervalRate:int;
		public var graphicsFound:Boolean;
		public var audioFound:Boolean;
		public var romFound:Boolean;
		public var faultFound:Boolean;
		public var paused:Boolean;
		public var audioVolume:int;
		public var audioBufferUnderrunLimit:int;
		public var audioBufferSize:int;
		public var offscreenWidth:int;
		public var offscreenHeight:int;
		public var BIOS:Array;
		public var offscreenRGBCount:int;
		public var offscreenRGBACount:int;
		public var frameBuffer:Array;
		public var swizzledFrame:Array;
		public var drewFrame:Boolean;
		public var audioUpdateState:Boolean;
		
		//Cycles - these were not included in clear function
		public var clockCyclesSinceStart:int;
		public var CPUCyclesPerIteration:int;
		public var CPUCyclesTotal:int;
		public var clocksPerSecond:int;
		
		//TIMER
		public var metricStart:Date;
		public var mainTimer:Timer;
			
		//Peripherals
		public var IOCore;
		public var ROM;
		public var fr:LocalLoader;
		
		//Canvas data
		public var canvas:GameBoyAdvanceCanvas;
		
		public var canvasLastWidth;
		public var canvasLastHeight;
		
		public var onscreenWidth;
		public var onscreenHeight;
		
		
		
		
		public function EmulatorCore() {
			// constructor code
			this.SKIPBoot = false;					//Skip the BIOS boot screen.
			this.dynarecEnabled = false;            //Use the dynarec engine?
			this.dynarecTHUMB = true;               //Enable THUMB compiling.
			this.dynarecARM = false;                //Enable ARM compiling.
			this.emulatorSpeed = 1;					//Speed multiplier of the emulator.
			this.timerIntervalRate = 16;			//How often the emulator core is called into (in milliseconds).
			this.graphicsFound = false;				//Do we have graphics output sink found yet?
			this.audioFound = false;				//Do we have audio output sink found yet?
			this.romFound = false;					//Do we have a ROM loaded in?
			this.faultFound = false;				//Did we run into a fatal error?
			this.paused = true;						//Are we paused?
			this.audioVolume = 1;					//Starting audio volume.
			this.audioBufferUnderrunLimit = 8;		//Audio buffer minimum span amount over x interpreter iterations.
			this.audioBufferSize = 20;				//Audio buffer maximum span amount over x interpreter iterations.
			this.offscreenWidth = 240;				//Width of the GBA screen.
			this.offscreenHeight = 160;				//Height of the GBA screen.
			this.BIOS = [];							//Initialize BIOS as not existing.
			//Cache some frame buffer lengths:
			this.offscreenRGBCount = this.offscreenWidth * this.offscreenHeight * 3;
			this.offscreenRGBACount = this.offscreenWidth * this.offscreenHeight * 4;
			//Graphics buffers to generate in advance:
			this.frameBuffer = ArrayHelper.buildArray(this.offscreenRGBCount);
			this.swizzledFrame = ArrayHelper.buildArray(this.offscreenRGBCount);		//The swizzled output buffer that syncs to the internal framebuffer on v-blank.
			this.initializeGraphicsBuffer();								//Pre-set the swizzled buffer for first frame.
			this.drewFrame = false;					//Did we draw the last iteration?
			this.audioUpdateState = false;			//Do we need to update the sound core with new info?
			//Calculate some multipliers against the core emulator timer:
			
			clockCyclesSinceStart = 0;
			CPUCyclesTotal = 0;
			this.calculateTimings();
			
		}
		
		//First to be called after constructor
		public function init(){
			this.canvas = new GameBoyAdvanceCanvas(offscreenWidth, offscreenHeight);
			addChild(this.canvas);
			fr = new LocalLoader();
			fr.loadROM(romLoadComplete);
		}
		
		public function romLoadComplete(dat:ByteArray){
			attachCanvas();
			attachROM(dat);
			startTimer();
		}
		
		public function playEmulator():void {
			if (this.paused) {
				this.startTimer();
				this.paused = false;
			}
		}
		public function pauseEmulator():void {
			if (!this.paused) {
				this.clearTimer();
				this.save();
				this.paused = true;
			}
		}
		public function stopEmulator():void {
			this.faultFound = false;
			this.romFound = false;
			this.pauseEmulator();
		}
		public function statusClear():void {
			this.faultFound = false;
			this.pauseEmulator();
		}
		public function restart():void {
			this.faultFound = false;
			this.pauseEmulator();
			this.initializeCore();
			this.resetMetrics();
			this.reinitializeAudio();
		}
		public function clearTimer():void {
			//clearInterval(this.timer);
			if(mainTimer == null)
				return;
				
			mainTimer.removeEventListener(TimerEvent.TIMER, this.timerCallback);
			this.resetMetrics();
			
		}
		public function startTimer():void {
			this.clearTimer();
			var parentObj = this;

			mainTimer = new Timer(this.timerIntervalRate);
			mainTimer.start();
			mainTimer.addEventListener(TimerEvent.TIMER, this.timerCallback);
		}
		public function timerCallback(event:TimerEvent):void {
			//Check to see if web view is not hidden, if hidden don't run due to JS timers being inaccurate on page hide:
			if (!this.faultFound && this.romFound) {						//Any error pending or no ROM loaded is a show-stopper!
				this.iterationStartSequence();								//Run start of iteration stuff.
				this.IOCore.iterate();										//Step through the emulation core loop.
				this.iterationEndSequence();								//Run end of iteration stuff.
			}
			else {
				this.pauseEmulator();												//Some pending error is preventing execution, so pause.
			}
		}
		
		public function iterationStartSequence():void {
			this.faultFound = true;                                             //If the end routine doesn't unset this, then we are marked as having crashed.
			this.drewFrame = false;                                             //Graphics has not drawn yet for this iteration block.
			this.audioUnderrunAdjustment();                                     //If audio is enabled, look to see how much we should overclock by to maintain the audio buffer.
			this.audioPushNewState();                                           //Check to see if we need to update the audio core for any output changes.
		}
		public function iterationEndSequence():void {
			this.requestDraw();                                                 //If drewFrame is true, blit buffered frame out.
			this.faultFound = false;                                            //If core did not throw while running, unset the fatal error flag.
			this.clockCyclesSinceStart += this.CPUCyclesTotal;                  //Accumulate tracking.
		}
		public function attachROM(ROM):void {
			this.stop();
			this.ROM = ROM;
			this.initializeCore();
			this.romFound = true;
		}
		public function attachBIOS(BIOS):void {
			this.statusClear();
			this.BIOS = BIOS;
		}
		public function save():void {
			//Nothing yet...
		}
		public function setSpeed(speed):void {
			
			this.emulatorSpeed = Math.min(Math.max(parseFloat(speed), 0.01), 10);
			this.calculateTimings();
			this.reinitializeAudio();
		}
		public function changeCoreTimer(newTimerIntervalRate):void {
			this.timerIntervalRate = Math.max(parseInt(newTimerIntervalRate), 1);
			if (!this.paused) {						//Set up the timer again if running.
				this.clearTimer();
				this.startTimer();
			}
			this.calculateTimings();
			this.reinitializeAudio();
		}
		public function resetMetrics():void {
			this.clockCyclesSinceStart = 0;
			this.metricStart = new Date();
		}
		public function calculateTimings():void {
			this.clocksPerSecond = this.emulatorSpeed * 0x1000000;
			this.CPUCyclesTotal = this.CPUCyclesPerIteration = Math.min(this.clocksPerSecond / 1000 * this.timerIntervalRate, 0x7FFFFFFF) | 0;
		}
		public function getSpeedPercentage():String {
			var metricEnd = new Date();
			return (((this.timerIntervalRate * this.clockCyclesSinceStart / (metricEnd.getTime() - this.metricStart.getTime())) / this.CPUCyclesPerIteration) * 100) + "%";
		}
		public function initializeCore():void {
			//Setup a new instance of the i/o core:
			this.IOCore = new GameBoyAdvanceIO(this);
		}
		public function keyDown(keyPressed):void {
			if (!this.paused) {
				this.IOCore.joypad.keyPress(keyPressed);
			}
		}
		public function keyUp(keyReleased):void {
			if (!this.paused) {
				this.IOCore.joypad.keyRelease(keyReleased);
			}
		}
		public function attachCanvas():void {
			
			this.graphicsFound = true;
			this.initializeCanvasTarget();
		}
		public function recomputeDimension():void {
			//Cache some dimension info:
			/*this.canvasLastWidth = this.canvas.canvasWidth;
			this.canvasLastHeight = this.canvas.canvasHeight;
			
			//Set target canvas as scaled:
			this.onscreenWidth = this.canvas.canvasWidth;
			this.onscreenHeight = this.canvas.canvasHeight;*/
			
		}
		public function initializeCanvasTarget() {
	
			//Obtain dimensional information:
			this.recomputeDimension();
			//Initialising buffer 
			
			//this.canvasBuffer = new ByteArray();
			
			
			//Get handles on the canvases:
			//this.canvasOffscreen.width = this.offscreenWidth;
			//this.canvasOffscreen.height = this.offscreenHeight;
			/*for (var indexGFXIterate = 3; indexGFXIterate < this.offscreenRGBACount; indexGFXIterate += 4) {
				canvasBuffer[indexGFXIterate] = 0xFF;
				//this.canvasBuffer.data[indexGFXIterate] = 0xFF;
			}*/
			
			/*for(var indexGFXIterate = 0; indexGFXIterate < this.offscreenRGBACount;){
				this.canvas.setSeg(indexGFXIterate,255);	//a
				this.canvas.setSeg(indexGFXIterate++, 0xFF);	//r
				this.canvas.setSeg(indexGFXIterate++, 0xFF);	//g
				this.canvas.setSeg(indexGFXIterate++, 0xFF);	//b
			}*/
			//Initialize Alpha Channel:
			/*for (var indexGFXIterate = 3; indexGFXIterate < this.offscreenRGBACount; indexGFXIterate += 4) {
				this.canvasBuffer.data[indexGFXIterate] = 0xFF;
			}*/
			//Draw swizzled buffer out as a test:
			this.drewFrame = true;
			this.requestDraw();
		}
		public function initializeGraphicsBuffer():void {
			//Initialize the first frame to a white screen:
			var bufferIndex = 0;
			while (bufferIndex < this.offscreenRGBCount) {
				this.swizzledFrame[bufferIndex++] = 0xF8;
			}
		}
		public function swizzleFrameBuffer():void {
			//Convert our dirty 15-bit (15-bit, with internal render flags above it) framebuffer to an 8-bit buffer with separate indices for the RGB channels:
			var bufferIndex = 0;
			for (var canvasIndex = 0; canvasIndex < this.offscreenRGBCount;) {
				this.swizzledFrame[canvasIndex++] = (this.frameBuffer[bufferIndex] & 0x1F) << 3;			//Red
				this.swizzledFrame[canvasIndex++] = (this.frameBuffer[bufferIndex] & 0x3E0) >> 2;			//Green
				this.swizzledFrame[canvasIndex++] = (this.frameBuffer[bufferIndex++] & 0x7C00) >> 7;		//Blue
			}
			
		}
		
		public function prepareFrame():void {
			//Copy the internal frame buffer to the output buffer:
			this.swizzleFrameBuffer();
			this.drewFrame = true;
		}
		
		public var zero = 0;
		public var undef = 0;
		
		public function requestDraw():void {
			if(this.drewFrame){
				var bufferIndex = 0;
				for (var canvasIndex = 0; canvasIndex < this.offscreenRGBACount;) {
					var r = this.swizzledFrame[bufferIndex++];
					var g = this.swizzledFrame[bufferIndex++];
					var b = this.swizzledFrame[bufferIndex++];
					canvas.setSeg(canvasIndex++, 255);
					canvas.setSeg(canvasIndex++, r);
					canvas.setSeg(canvasIndex++, g);
					canvas.setSeg(canvasIndex++, b);
					
				}
				
				this.graphicsBlit();
			}
		}
		public function graphicsBlit():void {
			this.canvas.refresh();
			
		}
		public function enableAudio():void {
			/*if (!this.audioFound) {
				//Calculate the variables for the preliminary downsampler first:
				this.audioResamplerFirstPassFactor = Math.max(Math.min(Math.floor(this.clocksPerSecond / 44100), Math.floor(0x7FFFFFFF / 0x3FF)), 1);
				this.audioDownSampleInputDivider = (2 / 0x3FF) / this.audioResamplerFirstPassFactor;
				this.audioSetState(true);	//Set audio to 'found' by default.
				//Attempt to enable audio:
				var parentObj = this;
				this.audio = new XAudioServer(2, this.clocksPerSecond / this.audioResamplerFirstPassFactor, 0, Math.max(this.CPUCyclesPerIteration * this.audioBufferSize / this.audioResamplerFirstPassFactor, 8192) << 1, null, this.audioVolume, function () {
					//Disable audio in the callback here:
					parentObj.disableAudio();
				});
				if (this.audioFound) {
					//Only run this if audio was found to save memory on disabled output:
					this.initializeAudioBuffering();
				}
			}*/
		}
		public function disableAudio():void {
			/*if (this.audioFound) {
				this.audio.changeVolume(0);
				this.audioSetState(false);
			}*/
		}
		public function initializeAudioBuffering():void {
			/*this.audioDestinationPosition = 0;
			this.audioBufferContainAmount = Math.max(this.CPUCyclesPerIteration * this.audioBufferUnderrunLimit / this.audioResamplerFirstPassFactor, 4096) << 1;
			this.audioNumSamplesTotal = (this.CPUCyclesPerIteration / this.audioResamplerFirstPassFactor) << 1;
			this.audioBuffer = getFloat32Array(this.audioNumSamplesTotal);*/
		}
		public function changeVolume(newVolume):void {
			/*this.audioVolume = Math.min(Math.max(parseFloat(newVolume), 0), 1);
			if (this.audioFound) {
				this.audio.changeVolume(this.audioVolume);
			}*/
		}
		public function outputAudio(downsampleInputLeft, downsampleInputRight):void {
			/*downsampleInputLeft = downsampleInputLeft | 0;
			downsampleInputRight = downsampleInputRight | 0;
			this.audioBuffer[this.audioDestinationPosition++] = (downsampleInputLeft * this.audioDownSampleInputDivider) - 1;
			this.audioBuffer[this.audioDestinationPosition++] = (downsampleInputRight * this.audioDownSampleInputDivider) - 1;
			if (this.audioDestinationPosition == this.audioNumSamplesTotal) {
				this.audio.writeAudioNoCallback(this.audioBuffer);
				this.audioDestinationPosition = 0;
			}*/
		}
		public function audioUnderrunAdjustment():void {
			/*this.CPUCyclesTotal = this.CPUCyclesPerIteration | 0;
			if (this.audioFound) {
				var underrunAmount = this.audio.remainingBuffer();
				if (typeof underrunAmount == "number") {
					underrunAmount = this.audioBufferContainAmount - Math.max(underrunAmount, 0);
					if (underrunAmount > 0) {
						this.CPUCyclesTotal = Math.min((this.CPUCyclesTotal | 0) + (Math.min((underrunAmount >> 1) * this.audioResamplerFirstPassFactor, 0x7FFFFFFF) | 0), 0x7FFFFFFF) | 0;
					}
				}
			}*/
		}
		public function audioPushNewState():void {
			/*if (this.audioUpdateState) {
				this.IOCore.sound.initializeOutput(this.audioFound, this.audioResamplerFirstPassFactor);
				this.audioUpdateState = false;
			}*/
		}
		public function audioSetState(audioFound):void {
			if (this.audioFound != audioFound) {
				this.audioFound = audioFound;
				this.audioUpdateState = true;
			}
		}
		public function reinitializeAudio():void {
			if (this.audioFound) {					//Set up the audio again if enabled.
				this.disableAudio();
				this.enableAudio();
			}
		}
		public function toggleSkipBootROM(skipBoot):void {
			this.SKIPBoot = !!skipBoot;
			if (this.romFound && this.paused) {
				this.initializeCore();
			}
		}
		public function toggleDynarec(dynarecEnabled):void {
			//Keep disabled by force until we rewrite the jit:
			//this.dynarecEnabled = !!dynarecEnabled;
		}





	}
	
}
