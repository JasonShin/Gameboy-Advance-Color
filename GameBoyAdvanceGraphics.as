package  {
	import graphics.GameBoyAdvanceCompositor;
	import graphics.GameBoyAdvanceBGTEXTRenderer;
	import graphics.GameBoyAdvanceAffineBGRenderer;
	import graphics.GameBoyAdvanceBGMatrixRenderer;
	import graphics.GameBoyAdvanceBG2FrameBufferRenderer;
	import graphics.GameBoyAdvanceOBJRenderer;
	import graphics.GameBoyAdvanceWindowRenderer;
	import graphics.GameBoyAdvanceOBJWindowRenderer;
	import graphics.GameBoyAdvanceMosaicRenderer;
	import graphics.GameBoyAdvanceColorEffectsRenderer;
	import graphics.GameBoyAdvanceMode0Renderer;
	import graphics.GameBoyAdvanceMode1Renderer;
	import graphics.GameBoyAdvanceMode2Renderer;
	import graphics.GameBoyAdvanceModeFrameBufferRenderer;
	import utils.ArrayHelper;
	
	public class GameBoyAdvanceGraphics {

		public var BGMode = 0;
		public var HBlankIntervalFree = false;
		public var VRAMOneDimensional = false;
		public var forcedBlank = false;
		public var displayBG0 = false;
		public var displayBG1 = false;
		public var displayBG2 = false;
		public var displayBG3 = false;
		public var displayOBJ = false;
		public var displayWindow0Flag = false;
		public var displayWindow1Flag = false;
		public var displayObjectWindowFlag = false;
		public var greenSwap = false;
		public var inVBlank = false;
		public var inHBlank = false;
		public var VCounterMatch = false;
		public var IRQVBlank = false;
		public var IRQHBlank = false;
		public var IRQVCounter = false;
		public var VCounter = 0;
		public var currentScanLine = 0;
		public var BGPriority;
		public var BGCharacterBaseBlock;
		public var BGMosaic = [false, false, false, false];
		public var BGPalette256 = [false, false, false, false];
		public var BGScreenBaseBlock;
		public var BGDisplayOverflow = [false, false, false, false];
		public var BGScreenSize;
		public var WINBG0Outside = false;
		public var WINBG1Outside = false;
		public var WINBG2Outside = false;
		public var WINBG3Outside = false;
		public var WINOBJOutside = false;
		public var WINEffectsOutside = false;
		public var WINOBJBG0Outside = false;
		public var WINOBJBG1Outside = false;
		public var WINOBJBG2Outside = false;
		public var WINOBJBG3Outside = false;
		public var WINOBJOBJOutside = false;
		public var WINOBJEffectsOutside = false;
		public var paletteRAM;
		public var VRAM;
		public var VRAM16;
		public var readVRAM16;
		public var writeVRAM16;
		public var VRAM32;
		public var readVRAM3;
		public var writeVRAM32;
		public var paletteRAM16;
		public var readPalette16;
		public var paletteRAM32;
		public var readPalette32;
		public var lineBuffer;
		public var frameBuffer;
		public var LCDTicks = 0;
		public var totalLinesPassed = 0;
		public var queuedScanLines = 0;
		public var lastUnrenderedLine = 0;
		public var transparency = 0x3800000;
		public var backdrop;
		//
		public var readVRAM32;
		
		
		//Initialising renderer
		public var compositor;
		public var bg0Renderer;
		public var bg1Renderer;
		public var bg2TextRenderer;
		public var bg3TextRenderer;
		public var bgAffineRenderer;
		public var bg2MatrixRenderer;
		public var bg3MatrixRenderer;
		public var bg2FrameBufferRenderer;
		public var objRenderer;
		public var window0Renderer;
		public var window1Renderer;
		public var objWindowRenderer;
		public var mosaicRenderer;
		public var colorEffectsRenderer;
		public var mode0Renderer;
		public var mode1Renderer;
		public var mode2Renderer;
		public var modeFrameBufferRenderer;
	
		public var renderer;
		
		public var IOCore;
		public var emulatorCore;
		
		public var palette256;
		public var paletteOBJ256;
		public var palette16;
		public var paletteOBJ16;
		
		public function GameBoyAdvanceGraphics(IOCore) {
			// constructor code
			this.IOCore = IOCore;
			this.emulatorCore = IOCore.emulatorCore;
			this.initializeIO();
			this.initializeRenderer();
		}
		
		public function initializeIO() {
			//Initialize Pre-Boot:
			this.BGMode = 0;
			this.HBlankIntervalFree = false;
			this.VRAMOneDimensional = false;
			this.forcedBlank = false;
			this.displayBG0 = false;
			this.displayBG1 = false;
			this.displayBG2 = false;
			this.displayBG3 = false;
			this.displayOBJ = false;
			this.displayWindow0Flag = false;
			this.displayWindow1Flag = false;
			this.displayObjectWindowFlag = false;
			this.greenSwap = false;
			this.inVBlank = false;
			this.inHBlank = false;
			this.VCounterMatch = false;
			this.IRQVBlank = false;
			this.IRQHBlank = false;
			this.IRQVCounter = false;
			this.VCounter = 0;
			this.currentScanLine = 0;
			this.BGPriority = ArrayHelper.buildArray(0x4);
			this.BGCharacterBaseBlock = ArrayHelper.buildArray(0x4);
			this.BGMosaic = [false, false, false, false];
			this.BGPalette256 = [false, false, false, false];
			this.BGScreenBaseBlock = ArrayHelper.buildArray(0x4);
			this.BGDisplayOverflow = [false, false, false, false];
			this.BGScreenSize = ArrayHelper.buildArray(0x4);
			this.WINBG0Outside = false;
			this.WINBG1Outside = false;
			this.WINBG2Outside = false;
			this.WINBG3Outside = false;
			this.WINOBJOutside = false;
			this.WINEffectsOutside = false;
			this.WINOBJBG0Outside = false;
			this.WINOBJBG1Outside = false;
			this.WINOBJBG2Outside = false;
			this.WINOBJBG3Outside = false;
			this.WINOBJOBJOutside = false;
			this.WINOBJEffectsOutside = false;
			this.paletteRAM = ArrayHelper.buildArray(0x400);
			this.VRAM = ArrayHelper.buildArray(0x18000);
			//this.VRAM16 = ArrayHelper.buildArray(this.VRAM);
			//this.readVRAM16 = (this.VRAM16) ? this.readVRAM16Optimized : this.readVRAM16Slow;
			//this.writeVRAM16 = (this.VRAM16) ? this.writeVRAM16Optimized : this.writeVRAM16Slow;
			this.readVRAM16 = this.readVRAM16Slow;
			this.writeVRAM16 = this.writeVRAM16Slow;
			//this.VRAM32 = ArrayHelper.buildArray(this.VRAM);
			//this.readVRAM32 = (this.VRAM32) ? this.readVRAM32Optimized : this.readVRAM32Slow;
			//this.writeVRAM32 = (this.VRAM32) ? this.writeVRAM32Optimized : this.writeVRAM32Slow;
			this.readVRAM32 = this.readVRAM32Slow;
			this.writeVRAM32 = this.writeVRAM32Slow;
			//this.paletteRAM16 = ArrayHelper.buildArray(this.paletteRAM);
			//this.readPalette16 = (this.paletteRAM16) ? this.readPalette16Optimized : this.readPalette16Slow;
			this.readPalette16 = this.readPalette16Slow;
			//this.paletteRAM32 = ArrayHelper.buildArray(this.paletteRAM);
			//this.readPalette32 = (this.paletteRAM32) ? this.readPalette32Optimized : this.readPalette32Slow;
			this.readPalette32 = this.readPalette32Slow;
			this.lineBuffer = ArrayHelper.buildArray(240);
			this.frameBuffer = this.emulatorCore.frameBuffer;
			this.LCDTicks = 0;
			this.totalLinesPassed = 0;
			this.queuedScanLines = 0;
			this.lastUnrenderedLine = 0;
			this.transparency = 0x3800000;
			this.backdrop = this.transparency | 0x200000;
		}
		
		public function initializeRenderer() {
			this.initializePaletteStorage();
			this.compositor = new GameBoyAdvanceCompositor(this);
			this.bg0Renderer = new GameBoyAdvanceBGTEXTRenderer(this, 0);
			this.bg1Renderer = new GameBoyAdvanceBGTEXTRenderer(this, 1);
			this.bg2TextRenderer = new GameBoyAdvanceBGTEXTRenderer(this, 2);
			this.bg3TextRenderer = new GameBoyAdvanceBGTEXTRenderer(this, 3);
			this.bgAffineRenderer = [
									 new GameBoyAdvanceAffineBGRenderer(this, 2),
									 new GameBoyAdvanceAffineBGRenderer(this, 3)
									 ];
			this.bg2MatrixRenderer = new GameBoyAdvanceBGMatrixRenderer(this, 2);
			this.bg3MatrixRenderer = new GameBoyAdvanceBGMatrixRenderer(this, 3);
			this.bg2FrameBufferRenderer = new GameBoyAdvanceBG2FrameBufferRenderer(this);
			this.objRenderer = new GameBoyAdvanceOBJRenderer(this);
			this.window0Renderer = new GameBoyAdvanceWindowRenderer(this);
			this.window1Renderer = new GameBoyAdvanceWindowRenderer(this);
			this.objWindowRenderer = new GameBoyAdvanceOBJWindowRenderer(this);
			this.mosaicRenderer = new GameBoyAdvanceMosaicRenderer(this);
			this.colorEffectsRenderer = new GameBoyAdvanceColorEffectsRenderer();
			this.mode0Renderer = new GameBoyAdvanceMode0Renderer(this);
			this.mode1Renderer = new GameBoyAdvanceMode1Renderer(this);
			this.mode2Renderer = new GameBoyAdvanceMode2Renderer(this);
			this.modeFrameBufferRenderer = new GameBoyAdvanceModeFrameBufferRenderer(this);
		
			this.renderer = this.mode0Renderer;
			this.compositorPreprocess();
		}
		public function initializePaletteStorage() {
			//Both BG and OAM in unified storage:
			this.palette256 = ArrayHelper.buildArray(0x100);
			this.palette256[0] |= this.transparency;
			this.paletteOBJ256 = ArrayHelper.buildArray(0x100);
			this.paletteOBJ256[0] |= this.transparency;
			this.palette16 = [];
			this.paletteOBJ16 = [];
			for (var index = 0; index < 0x10; ++index) {
				this.palette16[index] = ArrayHelper.buildArray(0x10);
				this.palette16[index][0] = this.transparency;
				this.paletteOBJ16[index] = ArrayHelper.buildArray(0x10);
				this.paletteOBJ16[index][0] = this.transparency;
			}
		}
		public function addClocks(clocks) {
			clocks = clocks | 0;
			//Call this when clocking the state some more:
			this.LCDTicks = ((this.LCDTicks | 0) + (clocks | 0)) | 0;
			trace("LCDTicks: " + this.LCDTicks);
			this.clockLCDState();
		}
		public function clockLCDState() {
			if ((this.LCDTicks | 0) >= 1006) {
				//HBlank Event Occurred:
				this.updateHBlank();
				if ((this.LCDTicks | 0) >= 1232) {
					/*We've now overflowed the LCD scan line state machine counter,
					 which tells us we need to be on a new scan-line and refresh over.*/
					this.inHBlank = false;                                        //Un-mark HBlank.
					//De-clock for starting on new scan-line:
					this.LCDTicks = ((this.LCDTicks | 0) - 1232) | 0;             //We start out at the beginning of the next line.
					//Increment scanline counter:
					this.currentScanLine = (this.currentScanLine + 1) | 0;        //Increment to the next scan line.
					//Handle switching in/out of vblank:
					if ((this.currentScanLine | 0) >= 160) {
						//Handle special case scan lines of vblank:
						switch (this.currentScanLine | 0) {
							case 160:
								this.updateVBlankStart();                           //Update state for start of vblank.
							case 161:
								this.checkDisplaySync();                            //Check for display sync.
								break;
							case 162:
								this.IOCore.dma.gfxDisplaySyncKillRequest();		//Display Sync. DMA reset on start of line 162.
								break;
							case 227:
								this.inVBlank = false;								//Un-mark VBlank on start of last vblank line.
								break;
							case 228:
								this.currentScanLine = 0;							//Reset scan-line to zero (First line of draw).
						}
					}
					else {
						 this.checkDisplaySync();                                   //Check for display sync.
					}
					this.checkDisplaySync();                                        //Check for display sync.
					this.checkVCounter();                                           //We're on a new scan line, so check the VCounter for match.
					//Recursive clocking of the LCD state:
					this.clockLCDState();
				}
			}
		}
		public function updateHBlank() {
			if (!this.inHBlank) {											//If we were last in HBlank, don't run this again.
				this.inHBlank = true;										//Mark HBlank.
				if (this.IRQHBlank) {
					this.IOCore.irq.requestIRQ(0x2);                        //Check for IRQ.
				}
				if (this.currentScanLine < 160) {
					this.incrementScanLineQueue();                          //Tell the gfx JIT to queue another line to draw.
					this.IOCore.dma.gfxHBlankRequest();                     //Check for HDMA Trigger.
				}
			}
		}
		public function checkDisplaySync() {
			if ((this.currentScanLine | 0) > 1) {
				this.IOCore.dma.gfxDisplaySyncRequest();					//Display Sync. DMA trigger.
			}
		}
		public function checkVCounter() {
			if ((this.currentScanLine | 0) == (this.VCounter | 0)) {		//Check for VCounter match.
				this.VCounterMatch = true;
				if (this.IRQVCounter) {										//Check for VCounter IRQ.
					this.IOCore.irq.requestIRQ(0x4);
				}
			}
			else {
				this.VCounterMatch = false;
			}
		}
		public function nextVBlankEventTime() {
			return ((((1 + ((387 - (this.currentScanLine | 0)) % 228)) * 1232) | 0) - (this.LCDTicks | 0));
		}
		public function nextVBlankIRQEventTime() {
			return (this.IRQVBlank) ? (this.nextVBlankEventTime() | 0) : -1;
		}
		public function nextHBlankEventTime() {
			return ((2238 - (this.LCDTicks | 0)) % 1232) | 0;
		}
		public function nextHBlankIRQEventTime() {
			return (this.IRQHBlank) ? this.nextHBlankEventTime() : -1;
		}
		public function nextHBlankDMAEventTime() {
			//Go to next HBlank time inside screen draw:
			if ((this.currentScanLine | 0) < 159 || (!this.inHBlank && (this.currentScanLine | 0) == 159)) {
				return this.nextHBlankEventTime() | 0;
			}
			//No HBlank DMA in VBlank:
			return ((((((228 - (this.currentScanLine | 0)) * 1232) | 0) + 1006) | 0) - (this.LCDTicks | 0)) | 0;
		}
		public function nextVCounterEventTime() {
			if (this.VCounter > 227) {
				//Never will match:
				return -1;
			}
			return (((((1 + (((227 + (this.VCounter | 0) - (this.currentScanLine | 0)) | 0) % 228)) | 0) * 1232) | 0) - (this.LCDTicks | 0)) | 0;
		}
		public function nextVCounterIRQEventTime() {
			return (this.IRQVCounter) ? (this.nextVCounterEventTime() | 0) : -1;
		}
		public function nextDisplaySyncEventTime() {
			if (this.currentScanLine < 2) {
				//Doesn't start until line 2:
				return ((((2 - (this.currentScanLine | 0)) * 1232) | 0) - (this.LCDTicks | 0)) | 0;
			}
			else if (this.currentScanLine < 161) {
				//Line 2 through line 161:
				return (1232 - (this.LCDTicks | 0)) | 0;
			}
			else {
				//Skip to line 2 metrics:
				return ((((230 - (this.currentScanLine | 0)) * 1232) | 0) - (this.LCDTicks | 0)) | 0;
			}
		}
		public function updateVBlankStart() {
			this.inVBlank = true;								//Mark VBlank.
			if (this.IRQVBlank) {								//Check for VBlank IRQ.
				this.IOCore.irq.requestIRQ(0x1);
			}
			//Ensure JIT framing alignment:
			if (this.totalLinesPassed < 160) {
				//Make sure our gfx are up-to-date:
				this.graphicsJITVBlank();
				//Draw the frame:
				this.emulatorCore.prepareFrame();
			}
			this.bgAffineRenderer[0].resetReferenceCounters();
			this.bgAffineRenderer[1].resetReferenceCounters();
			this.IOCore.dma.gfxVBlankRequest();
		}
		public function graphicsJIT() {
			this.totalLinesPassed = 0;			//Mark frame for ensuring a JIT pass for the next framebuffer output.
			this.graphicsJITScanlineGroup();
		}
		public function graphicsJITVBlank() {
			//JIT the graphics to v-blank framing:
			this.totalLinesPassed += this.queuedScanLines;
			this.graphicsJITScanlineGroup();
		}
		public function graphicsJITScanlineGroup() {
			//Normal rendering JIT, where we try to do groups of scanlines at once:
			while (this.queuedScanLines > 0) {
				this.renderer.renderScanLine(this.lastUnrenderedLine);
				if (this.lastUnrenderedLine < 159) {
					++this.lastUnrenderedLine;
				}
				else {
					this.lastUnrenderedLine = 0;
				}
				--this.queuedScanLines;
			}
		}
		public function incrementScanLineQueue() {
			if (this.queuedScanLines < 160) {
				++this.queuedScanLines;
			}
			else {
				if (this.lastUnrenderedLine < 159) {
					++this.lastUnrenderedLine;
				}
				else {
					this.lastUnrenderedLine = 0;
				}
			}
		}
		public function isRendering() {
			return (!this.forcedBlank && this.currentScanLine < 160 && !this.inHBlank);
		}
		public function OAMLockedCycles() {
			if (!this.forcedBlank && this.currentScanLine < 160) {
				if (this.HBlankIntervalFree) {
					//Delay OAM access until horizontal blank:
					return this.nextHBlankEventTime();
				}
				else {
					//Delay OAM access until vertical blank:
					return this.nextVBlankEventTime();
				}
			}
			return 0;
		}
		public function compositorPreprocess() {
			this.compositor.preprocess(this.WINEffectsOutside || (!this.displayObjectWindowFlag && !this.displayWindow1Flag && !this.displayWindow0Flag));
		}
		public function compositeLayers(OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, BG3Buffer) {
			//Arrange our layer stack so we can remove disabled and order for correct edge case priority:
			if (this.displayObjectWindowFlag || this.displayWindow1Flag || this.displayWindow0Flag) {
				//Window registers can further disable background layers if one or more window layers enabled:
				OBJBuffer = (this.WINOBJOutside) ? OBJBuffer : null;
				BG0Buffer = (this.WINBG0Outside) ? BG0Buffer : null;
				BG1Buffer = (this.WINBG1Outside) ? BG1Buffer : null;
				BG2Buffer = (this.WINBG2Outside) ? BG2Buffer : null;
				BG3Buffer = (this.WINBG3Outside) ? BG3Buffer : null;
			}
			this.compositor.renderScanLine(0, 240, this.lineBuffer, OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, BG3Buffer);
		}
		public function copyLineToFrameBuffer(line) {
			var a;
			line = line | 0;
			var offsetStart = ((line | 0) * 240) | 0;
			var position = 0;
			if (this.forcedBlank) {
				for (; (position | 0) < 240; offsetStart = ((offsetStart | 0) + 1) | 0, position = ((position | 0) + 1) | 0) {
					this.frameBuffer[offsetStart | 0] = 0x7FFF;
				}
			}
			else {
				if (!this.greenSwap) {
					for (; (position | 0) < 240; offsetStart = ((offsetStart | 0) + 1) | 0, position = ((position | 0) + 1) | 0) {
						this.frameBuffer[offsetStart | 0] = this.lineBuffer[position | 0] | 0;
					}
				}
				else {
					var pixel0 = 0;
					var pixel1 = 0;
					while (position < 240) {
						pixel0 = this.lineBuffer[position | 0] | 0;
						position = ((position | 0) + 1) | 0;
						pixel1 = this.lineBuffer[position | 0] | 0;
						position = ((position | 0) + 1) | 0;
						this.frameBuffer[offsetStart | 0] = (pixel0 & 0x7C1F) | (pixel1 & 0x3E0);
					
						offsetStart = ((offsetStart | 0) + 1) | 0;
						this.frameBuffer[offsetStart | 0] = (pixel1 & 0x7C1F) | (pixel0 & 0x3E0);
						
						offsetStart = ((offsetStart | 0) + 1) | 0;
						
					}
				}
			}
			
		}
		public function writeDISPCNT0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.BGMode = data & 0x07;
			this.bg2FrameBufferRenderer.writeFrameSelect((data & 0x10) >> 4);
			this.HBlankIntervalFree = ((data & 0x20) == 0x20);
			this.VRAMOneDimensional = ((data & 0x40) == 0x40);
			this.forcedBlank = ((data & 0x80) == 0x80);
			switch (this.BGMode) {
				case 0:
					this.renderer = this.mode0Renderer;
					break;
				case 1:
					this.renderer = this.mode1Renderer;
					break;
				case 2:
					this.renderer = this.mode2Renderer;
					break;
				default:
					this.renderer = this.modeFrameBufferRenderer;
					this.renderer.preprocess(Math.min(this.BGMode, 5));
			}
		}
		public function readDISPCNT0() {
			return (this.BGMode |
			((this.bg2FrameBufferRenderer.frameSelect > 0) ? 0x10 : 0) |
			(this.HBlankIntervalFree ? 0x20 : 0) | 
			(this.VRAMOneDimensional ? 0x40 : 0) |
			(this.forcedBlank ? 0x80 : 0));
		}
		public function writeDISPCNT1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.displayBG0 = ((data & 0x01) == 0x01);
			this.displayBG1 = ((data & 0x02) == 0x02);
			this.displayBG2 = ((data & 0x04) == 0x04);
			this.displayBG3 = ((data & 0x08) == 0x08);
			this.displayOBJ = ((data & 0x10) == 0x10);
			this.displayWindow0Flag = ((data & 0x20) == 0x20);
			this.displayWindow1Flag = ((data & 0x40) == 0x40);
			this.displayObjectWindowFlag = ((data & 0x80) == 0x80);
			this.compositorPreprocess();
		}
		public function readDISPCNT1() {
			return ((this.displayBG0 ? 0x1 : 0) |
			(this.displayBG1 ? 0x2 : 0) |
			(this.displayBG2 ? 0x4 : 0) |
			(this.displayBG3 ? 0x8 : 0) |
			(this.displayOBJ ? 0x10 : 0) |
			(this.displayWindow0Flag ? 0x20 : 0) |
			(this.displayWindow1Flag ? 0x40 : 0) |
			(this.displayObjectWindowFlag ? 0x80 : 0));
		}
		public function writeGreenSwap(data) {
			data = data | 0;
			this.graphicsJIT();
			this.greenSwap = ((data & 0x01) == 0x01);
		}
		public function readGreenSwap() {
			return (this.greenSwap ? 0x1 : 0);
		}
		public function writeDISPSTAT0(data) {
			data = data | 0;
			//VBlank flag read only.
			//HBlank flag read only.
			//V-Counter flag read only.
			//Only LCD IRQ generation enablers can be set here:
			this.IRQVBlank = ((data & 0x08) == 0x08);
			this.IRQHBlank = ((data & 0x10) == 0x10);
			this.IRQVCounter = ((data & 0x20) == 0x20);
		}
		public function readDISPSTAT0() {
			return ((this.inVBlank ? 0x1 : 0) |
			(this.inHBlank ? 0x2 : 0) |
			(this.VCounterMatch ? 0x4 : 0) |
			(this.IRQVBlank ? 0x8 : 0) |
			(this.IRQHBlank ? 0x10 : 0) |
			(this.IRQVCounter ? 0x20 : 0));
		}
		public function writeDISPSTAT1(data) {
			data = data | 0;
			//V-Counter match value:
			this.VCounter = data | 0;
			this.checkVCounter();
		}
		public function readDISPSTAT1() {
			return this.VCounter | 0;
		}
		public function readVCOUNT() {
			return this.currentScanLine | 0;
		}
		public function writeBG0CNT0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.BGPriority[0] = data & 0x3;
			this.BGCharacterBaseBlock[0] = (data & 0xC) >> 2;
			//Bits 5-6 always 0.
			this.BGMosaic[0] = ((data & 0x40) == 0x40);
			this.BGPalette256[0] = ((data & 0x80) == 0x80);
			this.bg0Renderer.palettePreprocess();
			this.bg0Renderer.priorityPreprocess();
			this.bg0Renderer.characterBaseBlockPreprocess();
		}
		public function readBG0CNT0() {
			return (this.BGPriority[0] |
			(this.BGCharacterBaseBlock[0] << 2) |
			(this.BGMosaic[0] ? 0x40 : 0) |
			(this.BGPalette256[0] ? 0x80 : 0));
		}
		public function writeBG0CNT1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.BGScreenBaseBlock[0] = data & 0x1F;
			this.BGDisplayOverflow[0] = ((data & 0x20) == 0x20);	//Note: Only applies to BG2/3 supposedly.
			this.BGScreenSize[0] = (data & 0xC0) >> 6;
			this.bg0Renderer.screenSizePreprocess();
			this.bg0Renderer.screenBaseBlockPreprocess();
		}
		public function readBG0CNT1() {
			return (this.BGScreenBaseBlock[0] |
			(this.BGDisplayOverflow[0] ? 0x20 : 0) |
			(this.BGScreenSize[0] << 6));
		}
		public function writeBG1CNT0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.BGPriority[1] = data & 0x3;
			this.BGCharacterBaseBlock[1] = (data & 0xC) >> 2;
			//Bits 5-6 always 0.
			this.BGMosaic[1] = ((data & 0x40) == 0x40);
			this.BGPalette256[1] = ((data & 0x80) == 0x80);
			this.bg1Renderer.palettePreprocess();
			this.bg1Renderer.priorityPreprocess();
			this.bg1Renderer.characterBaseBlockPreprocess();
		}
		public function readBG1CNT0() {
			return (this.BGPriority[1] |
			(this.BGCharacterBaseBlock[1] << 2) |
			(this.BGMosaic[1] ? 0x40 : 0) |
			(this.BGPalette256[1] ? 0x80 : 0));
		}
		public function writeBG1CNT1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.BGScreenBaseBlock[1] = data & 0x1F;
			this.BGDisplayOverflow[1] = ((data & 0x20) == 0x20);	//Note: Only applies to BG2/3 supposedly.
			this.BGScreenSize[1] = (data & 0xC0) >> 6;
			this.bg1Renderer.screenSizePreprocess();
			this.bg1Renderer.screenBaseBlockPreprocess();
		}
		public function readBG1CNT1() {
			return (this.BGScreenBaseBlock[1] |
			(this.BGDisplayOverflow[1] ? 0x20 : 0) |
			(this.BGScreenSize[1] << 6));
		}
		public function writeBG2CNT0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.BGPriority[2] = data & 0x3;
			this.BGCharacterBaseBlock[2] = (data & 0xC) >> 2;
			//Bits 5-6 always 0.
			this.BGMosaic[2] = ((data & 0x40) == 0x40);
			this.BGPalette256[2] = ((data & 0x80) == 0x80);
			this.bg2TextRenderer.palettePreprocess();
			this.bg2TextRenderer.priorityPreprocess();
			this.bgAffineRenderer[0].priorityPreprocess();
			this.bg2TextRenderer.characterBaseBlockPreprocess();
			this.bg2MatrixRenderer.characterBaseBlockPreprocess();
		}
		public function readBG2CNT0() {
			return (this.BGPriority[2] |
			(this.BGCharacterBaseBlock[2] << 2) |
			(this.BGMosaic[2] ? 0x40 : 0) |
			(this.BGPalette256[2] ? 0x80 : 0));
		}
		public function writeBG2CNT1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.BGScreenBaseBlock[2] = data & 0x1F;
			this.BGDisplayOverflow[2] = ((data & 0x20) == 0x20);
			this.BGScreenSize[2] = (data & 0xC0) >> 6;
			this.bg2TextRenderer.screenSizePreprocess();
			this.bg2MatrixRenderer.screenSizePreprocess();
			this.bg2TextRenderer.screenBaseBlockPreprocess();
			this.bg2MatrixRenderer.screenBaseBlockPreprocess();
			this.bg2MatrixRenderer.displayOverflowPreprocess();
		}
		public function readBG2CNT1() {
			return (this.BGScreenBaseBlock[2] |
			(this.BGDisplayOverflow[2] ? 0x20 : 0) |
			(this.BGScreenSize[2] << 6));
		}
		public function writeBG3CNT0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.BGPriority[3] = data & 0x3;
			this.BGCharacterBaseBlock[3] = (data & 0xC) >> 2;
			//Bits 5-6 always 0.
			this.BGMosaic[3] = ((data & 0x40) == 0x40);
			this.BGPalette256[3] = ((data & 0x80) == 0x80);
			this.bg3TextRenderer.palettePreprocess();
			this.bg3TextRenderer.priorityPreprocess();
			this.bgAffineRenderer[1].priorityPreprocess();
			this.bg3TextRenderer.characterBaseBlockPreprocess();
			this.bg3MatrixRenderer.characterBaseBlockPreprocess();
		}
		public function readBG3CNT0() {
			return (this.BGPriority[3] |
			(this.BGCharacterBaseBlock[3] << 2) |
			(this.BGMosaic[3] ? 0x40 : 0) |
			(this.BGPalette256[3] ? 0x80 : 0));
		}
		public function writeBG3CNT1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.BGScreenBaseBlock[3] = data & 0x1F;
			this.BGDisplayOverflow[3] = ((data & 0x20) == 0x20);
			this.BGScreenSize[3] = (data & 0xC0) >> 6;
			this.bg3TextRenderer.screenSizePreprocess();
			this.bg3MatrixRenderer.screenSizePreprocess();
			this.bg3TextRenderer.screenBaseBlockPreprocess();
			this.bg3MatrixRenderer.screenBaseBlockPreprocess();
			this.bg3MatrixRenderer.displayOverflowPreprocess();
		}
		public function readBG3CNT1() {
			return (this.BGScreenBaseBlock[3] |
			(this.BGDisplayOverflow[3] ? 0x20 : 0) |
			(this.BGScreenSize[3] << 6));
		}
		public function writeBG0HOFS0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg0Renderer.writeBGHOFS0(data | 0);
		}
		public function writeBG0HOFS1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg0Renderer.writeBGHOFS1(data | 0);
		}
		public function writeBG0VOFS0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg0Renderer.writeBGVOFS0(data | 0);
		}
		public function writeBG0VOFS1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg0Renderer.writeBGVOFS1(data | 0);
		}
		public function writeBG1HOFS0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg1Renderer.writeBGHOFS0(data | 0);
		}
		public function writeBG1HOFS1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg1Renderer.writeBGHOFS1(data | 0);
		}
		public function writeBG1VOFS0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg1Renderer.writeBGVOFS0(data | 0);
		}
		public function writeBG1VOFS1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg1Renderer.writeBGVOFS1(data | 0);
		}
		public function writeBG2HOFS0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg2TextRenderer.writeBGHOFS0(data | 0);
		}
		public function writeBG2HOFS1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg2TextRenderer.writeBGHOFS1(data | 0);
		}
		public function writeBG2VOFS0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg2TextRenderer.writeBGVOFS0(data | 0);
		}
		public function writeBG2VOFS1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg2TextRenderer.writeBGVOFS1(data | 0);
		}
		public function writeBG3HOFS0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg3TextRenderer.writeBGHOFS0(data | 0);
		}
		public function writeBG3HOFS1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg3TextRenderer.writeBGHOFS1(data | 0);
		}
		public function writeBG3VOFS0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg3TextRenderer.writeBGVOFS0(data | 0);
		}
		public function writeBG3VOFS1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bg3TextRenderer.writeBGVOFS1(data | 0);
		}
		public function writeBG2PA0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGPA0(data | 0);
		}
		public function writeBG2PA1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGPA1(data | 0);
		}
		public function writeBG2PB0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGPB0(data | 0);
		}
		public function writeBG2PB1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGPB1(data | 0);
		}
		public function writeBG2PC0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGPC0(data | 0);
		}
		public function writeBG2PC1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGPC1(data | 0);
		}
		public function writeBG2PD0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGPD0(data | 0);
		}
		public function writeBG2PD1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGPD1(data | 0);
		}
		public function writeBG3PA0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGPA0(data | 0);
		}
		public function writeBG3PA1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGPA1(data | 0);
		}
		public function writeBG3PB0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGPB0(data | 0);
		}
		public function writeBG3PB1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGPB1(data | 0);
		}
		public function writeBG3PC0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGPC0(data | 0);
		}
		public function writeBG3PC1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGPC1(data | 0);
		}
		public function writeBG3PD0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGPD0(data | 0);
		}
		public function writeBG3PD1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGPD1(data | 0);
		}
		public function writeBG2X_L0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGX_L0(data | 0);
		}
		public function writeBG2X_L1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGX_L1(data | 0);
		}
		public function writeBG2X_H0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGX_H0(data | 0);
		}
		public function writeBG2X_H1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGX_H1(data | 0);
		}
		public function writeBG2Y_L0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGY_L0(data | 0);
		}
		public function writeBG2Y_L1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGY_L1(data | 0);
		}
		public function writeBG2Y_H0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGY_H0(data | 0);
		}
		public function writeBG2Y_H1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[0].writeBGY_H1(data | 0);
		}
		public function writeBG3X_L0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGX_L0(data | 0);
		}
		public function writeBG3X_L1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGX_L1(data | 0);
		}
		public function writeBG3X_H0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGX_H0(data | 0);
		}
		public function writeBG3X_H1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGX_H1(data | 0);
		}
		public function writeBG3Y_L0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGY_L0(data | 0);
		}
		public function writeBG3Y_L1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGY_L1(data | 0);
		}
		public function writeBG3Y_H0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGY_H0(data | 0);
		}
		public function writeBG3Y_H1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.bgAffineRenderer[1].writeBGY_H1(data | 0);
		}
		public function writeWIN0H0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.window0Renderer.writeWINH0(data | 0);		//Window x-coord goes up to this minus 1.
		}
		public function writeWIN0H1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.window0Renderer.writeWINH1(data | 0);
		}
		public function writeWIN1H0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.window1Renderer.writeWINH0(data | 0);		//Window x-coord goes up to this minus 1.
		}
		public function writeWIN1H1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.window1Renderer.writeWINH1(data | 0);
		}
		public function writeWIN0V0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.window0Renderer.writeWINV0(data | 0);		//Window y-coord goes up to this minus 1.
		}
		public function writeWIN0V1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.window0Renderer.writeWINV1(data | 0);
		}
		public function writeWIN1V0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.window1Renderer.writeWINV0(data | 0);		//Window y-coord goes up to this minus 1.
		}
		public function writeWIN1V1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.window1Renderer.writeWINV1(data | 0);
		}
		public function writeWININ0(data) {
			data = data | 0;
			//Window 0:
			this.graphicsJIT();
			this.window0Renderer.writeWININ(data | 0);
		}
		public function readWININ0() {
			//Window 0:
			return this.window0Renderer.readWININ() | 0;
		}
		public function writeWININ1(data) {
			data = data | 0;
			//Window 1:
			this.graphicsJIT();
			this.window1Renderer.writeWININ(data | 0);
		}
		public function readWININ1() {
			//Window 1:
			return this.window1Renderer.readWININ() | 0;
		}
		public function writeWINOUT0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.WINBG0Outside = ((data & 0x01) == 0x01);
			this.WINBG1Outside = ((data & 0x02) == 0x02);
			this.WINBG2Outside = ((data & 0x04) == 0x04);
			this.WINBG3Outside = ((data & 0x08) == 0x08);
			this.WINOBJOutside = ((data & 0x10) == 0x10);
			this.WINEffectsOutside = ((data & 0x20) == 0x20);
			this.compositorPreprocess();
		}
		public function readWINOUT0() {
			return ((this.WINBG0Outside ? 0x1 : 0) |
			(this.WINBG1Outside ? 0x2 : 0) |
			(this.WINBG2Outside ? 0x4 : 0) |
			(this.WINBG3Outside ? 0x8 : 0) |
			(this.WINOBJOutside ? 0x10 : 0) |
			(this.WINEffectsOutside ? 0x20 : 0));
		}
		public function writeWINOUT1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.WINOBJBG0Outside = ((data & 0x01) == 0x01);
			this.WINOBJBG1Outside = ((data & 0x02) == 0x02);
			this.WINOBJBG2Outside = ((data & 0x04) == 0x04);
			this.WINOBJBG3Outside = ((data & 0x08) == 0x08);
			this.WINOBJOBJOutside = ((data & 0x10) == 0x10);
			this.WINOBJEffectsOutside = ((data & 0x20) == 0x20);
			this.objWindowRenderer.preprocess();
		}
		public function readWINOUT1() {
			return ((this.WINOBJBG0Outside ? 0x1 : 0) |
			(this.WINOBJBG1Outside ? 0x2 : 0) |
			(this.WINOBJBG2Outside ? 0x4 : 0) |
			(this.WINOBJBG3Outside ? 0x8 : 0) |
			(this.WINOBJOBJOutside ? 0x10 : 0) |
			(this.WINOBJEffectsOutside ? 0x20 : 0));
		}
		public function writeMOSAIC0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.mosaicRenderer.writeMOSAIC0(data | 0);
		}
		public function writeMOSAIC1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.mosaicRenderer.writeMOSAIC1(data | 0);
		}
		public function writeBLDCNT0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.colorEffectsRenderer.writeBLDCNT0(data | 0);
		}
		public function readBLDCNT0() {
			return this.colorEffectsRenderer.readBLDCNT0();
		}
		public function writeBLDCNT1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.colorEffectsRenderer.writeBLDCNT1(data | 0);
		}
		public function readBLDCNT1() {
			return this.colorEffectsRenderer.readBLDCNT1();
		}
		public function writeBLDALPHA0(data) {
			data = data | 0;
			this.graphicsJIT();
			this.colorEffectsRenderer.writeBLDALPHA0(data | 0);
		}
		public function writeBLDALPHA1(data) {
			data = data | 0;
			this.graphicsJIT();
			this.colorEffectsRenderer.writeBLDALPHA1(data | 0);
		}
		public function writeBLDY(data) {
			data = data | 0;
			this.graphicsJIT();
			this.colorEffectsRenderer.writeBLDY(data | 0);
		}
		public function writeVRAM(address, data) {
			this.graphicsJIT();
			this.VRAM[address | 0] = data | 0;
		}
		public function writeVRAM16Slow(address, data) {
			this.graphicsJIT();
			this.VRAM[address] = data & 0xFF;
			this.VRAM[address | 1] = data >> 8;
		}
		public function writeVRAM16Optimized(address, data) {
			this.graphicsJIT();
			this.VRAM16[address >> 1] = data | 0;
		}
		public function writeVRAM32Slow(address, data) {
			this.graphicsJIT();
			this.VRAM[address | 0] = data & 0xFF;
			this.VRAM[address | 1] = (data >> 8) & 0xFF;
			this.VRAM[address | 2] = (data >> 16) & 0xFF;
			this.VRAM[address | 3] = (data >> 24) & 0xFF;
		}
		public function writeVRAM32Optimized(address, data) {
			this.graphicsJIT();
			this.VRAM32[address >> 2] = data | 0;
		}
		public function readVRAM(address) {
			return this.VRAM[address | 0] | 0;
		}
		public function readVRAM16Slow(address) {
			return this.VRAM[address | 0] | (this.VRAM[address | 1] << 8);
		}
		public function readVRAM16Optimized(address) {
			return this.VRAM16[address >> 1] | 0;
		}
		public function readVRAM32Slow(address) {
			return this.VRAM[address | 0] | (this.VRAM[address | 1] << 8) | (this.VRAM[address | 2] << 16) | (this.VRAM[address | 3] << 24);
		}
		public function readVRAM32Optimized(address) {
			return this.VRAM32[address >> 2] | 0;
		}
		public function writeOAM(address, data) {
			address = address | 0;
			data = data | 0;
			this.graphicsJIT();
			this.objRenderer.writeOAM(address | 0, data | 0);
		}
		public function readOAM(address) {
			return this.objRenderer.readOAM(address | 0) | 0;
		}
		public function readOAM16(address) {
			return this.objRenderer.readOAM16(address | 0) | 0;
		}
		public function readOAM32(address) {
			return this.objRenderer.readOAM32(address | 0) | 0;
		}
		public function writePalette(address, data) {
			this.graphicsJIT();
			this.paletteRAM[address] = data;
			var palette = ((this.paletteRAM[address | 1] << 8) | this.paletteRAM[address & 0x3FE]) & 0x7FFF;
			address >>= 1;
			if ((address & 0xFF) == 0) {
				palette |= this.transparency;
				if (address == 0) {
					this.backdrop = palette | 0x200000;
				}
			}
			if (address < 0x100) {
				this.palette256[address] = palette;
			}
			else {
				this.paletteOBJ256[address & 0xFF] = palette;
			}
			if ((address & 0xF) == 0) {
				palette |= this.transparency;
			}
			if (address < 0x100) {
				this.palette16[address >> 4][address & 0xF] = palette;
			}
			else {
				this.paletteOBJ16[(address >> 4) & 0xF][address & 0xF] = palette;
			}
		}
		public function readPalette(address) {
			return this.paletteRAM[address & 0x3FF] | 0;
		}
		public function readPalette16Slow(address) {
			return this.paletteRAM[address] | (this.paletteRAM[address | 1] << 8);
		}
		public function readPalette16Optimized(address) {
			address = address | 0;
			return this.paletteRAM16[(address >> 1) & 0x1FF] | 0;
		}
		public function readPalette32Slow(address) {
			return this.paletteRAM[address] | (this.paletteRAM[address | 1] << 8) | (this.paletteRAM[address | 2] << 16)  | (this.paletteRAM[address | 3] << 24);
		}
		public function readPalette32Optimized(address) {
			address = address | 0;
			return this.paletteRAM32[(address >> 2) & 0xFF] | 0;
		}
		
		
		

	}
	
}
