package graphics {
	import utils.ArrayHelper;
	
	public class GameBoyAdvanceOBJRenderer {
		
		public var gfx;
		public var transparency;
		
		public var OAMRAM;
		public var OAMRAM16;
		public var readOAM16;
		public var OAMRAM32;
		public var readOAM32;
		public var scratchBuffer;
		public var scratchWindowBuffer;
		public var scratchOBJBuffer;
		public var targetBuffer;
		
		public var OBJMatrixParametersRaw;
		public var OBJMatrixParameters;
		public var OAMTable;
		public var palette;
		public var xSource;
		public var pixel;

		public function GameBoyAdvanceOBJRenderer(gfx) {
			// constructor code
			this.gfx = gfx;
			this.transparency = this.gfx.transparency;
			this.initialize(0);
		}
		
		public var lookupXSize = [
			//Square:
			8,  16, 32, 64,
			//Vertical Rectangle:
			16, 32, 32, 64,
			//Horizontal Rectangle:
			8,   8, 16, 32
		];
		public var lookupYSize = [
			//Square:
			8,  16, 32, 64,
			//Vertical Rectangle:
			8,   8, 16, 32,
			//Horizontal Rectangle:
			16, 32, 32, 64
		];
		
		public function initialize(line) {
			this.OAMRAM = ArrayHelper.buildArray(0x400);
			this.OAMRAM16 = ArrayHelper.buildArray(this.OAMRAM);
			this.readOAM16 = (this.OAMRAM16 != null) ? this.readOAM16Optimized : this.readOAM16Slow;
			this.OAMRAM32 = ArrayHelper.buildArray(this.OAMRAM);
			this.readOAM32 = (this.OAMRAM32 != null) ? this.readOAM32Optimized : this.readOAM32Slow;
			this.scratchBuffer = ArrayHelper.buildArray(240);
			this.scratchWindowBuffer = ArrayHelper.buildArray(240);
			this.scratchOBJBuffer = ArrayHelper.buildArray(128);
			this.targetBuffer = null;
			this.initializeMatrixStorage();
			this.initializeOAMTable();
		}
		public function initializeMatrixStorage() {
			this.OBJMatrixParametersRaw = [];
			this.OBJMatrixParameters = [];
			for (var index = 0; index < 0x20;) {
				this.OBJMatrixParametersRaw[index] = ArrayHelper.buildArray(0x4);
				this.OBJMatrixParameters[index++] = ArrayHelper.buildArray(0x4);
			}
		}
		public function initializeOAMTable() {
			this.OAMTable = [];
			for (var spriteNumber = 0; spriteNumber < 128; spriteNumber = (spriteNumber + 1) | 0) {
				this.OAMTable[spriteNumber | 0] = new GameBoyAdvanceOAMAttributeTable();
			}
		}
		public function renderScanLine(line) {
			this.targetBuffer = this.scratchBuffer;
			this.performRenderLoop(line, false);
			return this.scratchBuffer;
		}
		public function renderWindowScanLine(line) {
			this.targetBuffer = this.scratchWindowBuffer;
			this.performRenderLoop(line, true);
			return this.scratchWindowBuffer;
		}
		public function performRenderLoop(line, isOBJWindow) {
			this.clearScratch();
			for (var objNumber = 0; objNumber < 0x80; ++objNumber) {
				this.renderSprite(line, this.OAMTable[objNumber], isOBJWindow);
			}
		}
		public function clearScratch() {
			for (var position = 0; position < 240; ++position) {
				this.targetBuffer[position] = this.transparency;
			}
		}
		public function renderSprite(line, sprite, isOBJWindow) {
			if (this.isDrawable(sprite, isOBJWindow)) {
				if (sprite.mosaic) {
					//Correct line number for mosaic:
					line -= this.gfx.mosaicRenderer.getOBJMosaicYOffset(line);
				}
				//Obtain horizontal size info:
				var xSize = this.lookupXSize[(sprite.shape << 2) | sprite.size] << ((sprite.doubleSizeOrDisabled) ? 1 : 0);
				//Obtain vertical size info:
				var ySize = this.lookupYSize[(sprite.shape << 2) | sprite.size] << ((sprite.doubleSizeOrDisabled) ? 1 : 0);
				//Obtain some offsets:
				var ycoord = sprite.ycoord;
				var yOffset = line - ycoord;
				//Overflow Correction:
				if (ycoord + ySize > 0x1FF) {
					yOffset -= 0x200;
				}
				else if (yOffset < 0) {
					yOffset += 0x100;
				}
				//Make a sprite line:
				if ((yOffset & --ySize) == yOffset) {
					if (sprite.matrix2D) {
						//Scale & Rotation:
						this.renderMatrixSprite(sprite, xSize, ySize + 1, yOffset);
					}
					else {
						//Regular Scrolling:
						this.renderNormalSprite(sprite, xSize, ySize, yOffset);
					}
					//Mark for semi-transparent:
					if (sprite.mode == 1) {
						this.markSemiTransparent(xSize);
					}
					//Copy OBJ scratch buffer to scratch line buffer:
					this.outputSpriteToScratch(sprite, xSize);
				}
			}
		}
		public function renderMatrixSprite(sprite, xSize, ySize, yOffset) {
			xSize = xSize | 0;
			ySize = ySize | 0;
			yOffset = yOffset | 0;
			var xDiff = (-((xSize | 0) >> 1)) | 0;
		
			var yDiff = ((yOffset | 0) - (ySize >> 1)) | 0;
			var xSizeOriginal = ((xSize | 0) >> ((sprite.doubleSizeOrDisabled) ? 1 : 0)) | 0;
			var xSizeFixed = xSizeOriginal << 8;
			var ySizeOriginal = ((ySize | 0) >> ((sprite.doubleSizeOrDisabled) ? 1 : 0)) | 0;
			var ySizeFixed = ySizeOriginal << 8;
			var params = this.OBJMatrixParameters[sprite.matrixParameters | 0];
			var dx = params[0] | 0;
			var dmx = params[1] | 0;
			var dy = params[2] | 0;
			var dmy = params[3] | 0;
			var pa = ((dx | 0) * (xDiff | 0)) | 0;
			var pb = ((dmx | 0) * (yDiff | 0)) | 0;
			var pc = ((dy | 0) * (xDiff | 0)) | 0;
			var pd = ((dmy | 0) * (yDiff | 0)) | 0;
			var x = ((pa | 0) + (pb | 0) + ((xSizeFixed | 0) >> 1)) | 0;
			var y = ((pc | 0) + (pd | 0) + ((ySizeFixed | 0) >> 1)) | 0;
			var tileNumber = sprite.tileNumber | 0;
			for (var position = 0; (position | 0) < (xSize | 0); position = (position + 1) | 0, x = ((x | 0) + (dx | 0)) | 0, y = ((y | 0) + (dy | 0)) | 0) {
				if ((x | 0) >= 0 && (y | 0) >= 0 && (x | 0) < (xSizeFixed | 0) && (y | 0) < (ySizeFixed | 0)) {
					//Coordinates in range, fetch pixel:
					this.scratchOBJBuffer[position | 0] = this.fetchMatrixPixel(sprite, tileNumber | 0, x >> 8, y >> 8, xSizeOriginal | 0) | 0;
				}
				else {
					//Coordinates outside of range, transparency defaulted:
					this.scratchOBJBuffer[position | 0] = this.transparency | 0;
				}
			}
		}
		public function fetchMatrixPixel(sprite, tileNumber, x, y, xSize) {
			tileNumber = tileNumber | 0;
			x = x | 0;
			y = y | 0;
			xSize = xSize | 0;
			var address = this.tileNumberToAddress(sprite, tileNumber | 0, xSize | 0, y | 0) | 0;
			if (sprite.monolithicPalette) {
				//256 Colors / 1 Palette:
				address = (address | 0) + (this.tileRelativeAddressOffset(x | 0, y | 0) | 0);
				return this.gfx.paletteOBJ256[this.gfx.VRAM[address | 0] | 0] | 0;
			}
			else {
				//16 Colors / 16 palettes:
				address = ((address | 0) + ((this.tileRelativeAddressOffset(x | 0, y | 0) >> 1) | 0));
				if ((x & 0x1) == 0) {
					return this.gfx.paletteOBJ16[sprite.paletteNumber | 0][this.gfx.VRAM[address | 0] & 0xF] | 0;
				}
				else {
					return this.gfx.paletteOBJ16[sprite.paletteNumber | 0][this.gfx.VRAM[address | 0] >> 4] | 0;
				}
			}
		}
		public function tileRelativeAddressOffset(x, y) {
			var x = x | 0;
			var y = y | 0;
			return ((((y & 7) + (x & -8)) << 3) + (x & 0x7)) | 0;
		}
		public function renderNormalSprite(sprite, xSize, ySize, yOffset) {
			xSize = xSize | 0;
			ySize = ySize | 0;
			yOffset = yOffset | 0;
			if (sprite.verticalFlip) {
				//Flip y-coordinate offset:
				yOffset = (ySize - yOffset) | 0;
			}
			var address = this.tileNumberToAddress(sprite, sprite.tileNumber, xSize, yOffset) | 0;
			var vram = this.gfx.VRAM;
			var data = 0;
			var objBufferPosition = 0;
			if (sprite.monolithicPalette) {
				//256 Colors / 1 Palette:
				address += (yOffset & 7) << 3;
				var palette = this.gfx.paletteOBJ256;
				while (objBufferPosition < xSize) {
					this.scratchOBJBuffer[objBufferPosition++] = palette[vram[address++] | 0] | 0;
					this.scratchOBJBuffer[objBufferPosition++] = palette[vram[address++] | 0] | 0;
					this.scratchOBJBuffer[objBufferPosition++] = palette[vram[address++] | 0] | 0;
					this.scratchOBJBuffer[objBufferPosition++] = palette[vram[address++] | 0] | 0;
					this.scratchOBJBuffer[objBufferPosition++] = palette[vram[address++] | 0] | 0;
					this.scratchOBJBuffer[objBufferPosition++] = palette[vram[address++] | 0] | 0;
					this.scratchOBJBuffer[objBufferPosition++] = palette[vram[address++] | 0] | 0;
					this.scratchOBJBuffer[objBufferPosition++] = palette[vram[address] | 0] | 0;
					address += 0x39;
				}
			}
			else {
				//16 Colors / 16 palettes:
				address += (yOffset & 7) << 2;
				palette = this.gfx.paletteOBJ16[sprite.paletteNumber];
				while (objBufferPosition < xSize) {
					data = vram[address++];
					this.scratchOBJBuffer[objBufferPosition++] = palette[data & 0xF] | 0;
					this.scratchOBJBuffer[objBufferPosition++] = palette[data >> 4] | 0;
					data = vram[address++];
					this.scratchOBJBuffer[objBufferPosition++] = palette[data & 0xF] | 0;
					this.scratchOBJBuffer[objBufferPosition++] = palette[data >> 4] | 0;
					data = vram[address++];
					this.scratchOBJBuffer[objBufferPosition++] = palette[data & 0xF] | 0;
					this.scratchOBJBuffer[objBufferPosition++] = palette[data >> 4] | 0;
					data = vram[address];
					this.scratchOBJBuffer[objBufferPosition++] = palette[data & 0xF] | 0;
					this.scratchOBJBuffer[objBufferPosition++] = palette[data >> 4] | 0;
					address += 0x1D;
				}
			}
		}
		public function tileNumberToAddress(sprite, tileNumber, xSize, yOffset) {
			tileNumber = tileNumber | 0;
			xSize = xSize | 0;
			yOffset = yOffset | 0;
			if (!this.gfx.VRAMOneDimensional) {
				//2D Mapping (32 8x8 tiles by 32 8x8 tiles):
				if (sprite.monolithicPalette) {
					//Hardware ignores the LSB in this case:
					tileNumber &= -2;
				}
				tileNumber += (yOffset >> 3) * 0x20;
			}
			else {
				//1D Mapping:
				tileNumber += (yOffset >> 3) * (xSize >> ((sprite.monolithicPalette) ? 2 : 3));
			}
			//Starting address of currently drawing sprite line:
			return ((tileNumber << 5) + 0x10000) | 0;
		}
		public function markSemiTransparent(xSize) {
			//Mark sprite pixels as semi-transparent:
			while (--xSize > -1) {
				this.scratchOBJBuffer[xSize | 0] |= 0x400000;
			}
		}
		public function outputSpriteToScratch(sprite, xSize) {
			xSize = xSize | 0;
			//Simulate x-coord wrap around logic:
			var xcoord = sprite.xcoord | 0;
			if (xcoord > (0x200 - xSize)) {
				xcoord -= 0x200;
			}
			//Perform the mosaic transform:
			if (sprite.mosaic) {
				this.gfx.mosaicRenderer.renderOBJMosaicHorizontal(this.scratchOBJBuffer, xcoord, xSize);
			}
			//Resolve end point:
			var xcoordEnd = Math.min(xcoord + xSize, 240) | 0;
			//Flag for compositor to ID the pixels as OBJ:
			var bitFlags = (sprite.priority << 23) | 0x100000;
			if (!sprite.horizontalFlip || sprite.matrix2D) {
				//Normal:
				for (xSource = 0; xcoord < xcoordEnd; ++xcoord, ++xSource) {
					pixel = (bitFlags | this.scratchOBJBuffer[xSource | 0]) | 0;
					//Overwrite by priority:
					if (xcoord > -1 && (pixel & 0x3800000) < (this.targetBuffer[xcoord | 0] & 0x3800000)) {
						this.targetBuffer[xcoord | 0] = pixel | 0;
					}
				}
			}
			else {
				//Flipped Horizontally:
				for (xSource = xSize - 1; xcoord < xcoordEnd; ++xcoord, --xSource) {
					pixel = (bitFlags | this.scratchOBJBuffer[xSource | 0]) | 0;
					//Overwrite by priority:
					if (xcoord > -1 && (pixel & 0x3800000) < (this.targetBuffer[xcoord | 0] & 0x3800000)) {
						this.targetBuffer[xcoord | 0] = pixel | 0;
					}
				}
			}
		}
		public function isDrawable(sprite, doWindowOBJ) {
			//Make sure we pass some checks that real hardware does:
			if ((sprite.mode < 2 && !doWindowOBJ) || (doWindowOBJ && sprite.mode == 2)) {
				if (!sprite.doubleSizeOrDisabled || sprite.matrix2D) {
					if (sprite.shape < 3) {
						if (this.gfx.BGMode < 3 || sprite.tileNumber >= 0x200) {
							return true;
						}
					}
				}
			}
			return false;
		}
		public function writeOAM(address, data) {
			address = address | 0;
			data = data | 0;
			var OAMTable = this.OAMTable[address >> 3];
			switch (address & 0x7) {
					//Attrib 0:
				case 0:
					OAMTable.ycoord = data;
					break;
				case 1:
					OAMTable.matrix2D = ((data & 0x1) == 0x1);
					OAMTable.doubleSizeOrDisabled = ((data & 0x2) == 0x2);
					OAMTable.mode = (data >> 2) & 0x3;
					OAMTable.mosaic = ((data & 0x10) == 0x10);
					OAMTable.monolithicPalette = ((data & 0x20) == 0x20);
					OAMTable.shape = data >> 6;
					break;
					//Attrib 1:
				case 2:
					OAMTable.xcoord = (OAMTable.xcoord & 0x100) | data;
					break;
				case 3:
					OAMTable.xcoord = ((data & 0x1) << 8) | (OAMTable.xcoord & 0xFF);
					OAMTable.matrixParameters = (data >> 1) & 0x1F;
					OAMTable.horizontalFlip = ((data & 0x10) == 0x10);
					OAMTable.verticalFlip = ((data & 0x20) == 0x20);
					OAMTable.size = data >> 6;
					break;
					//Attrib 2:
				case 4:
					OAMTable.tileNumber = (OAMTable.tileNumber & 0x300) | data;
					break;
				case 5:
					OAMTable.tileNumber = ((data & 0x3) << 8) | (OAMTable.tileNumber & 0xFF);
					OAMTable.priority = (data >> 2) & 0x3;
					OAMTable.paletteNumber = data >> 4;
					break;
					//Scaling/Rotation Parameter:
				case 6:
					this.OBJMatrixParametersRaw[address >> 5][(address >> 3) & 0x3] &= 0xFF00;
					this.OBJMatrixParametersRaw[address >> 5][(address >> 3) & 0x3] |= data;
					this.OBJMatrixParameters[address >> 5][(address >> 3) & 0x3] = (this.OBJMatrixParametersRaw[address >> 5][(address >> 3) & 0x3] << 16) >> 16;
					break;
				default:
					this.OBJMatrixParametersRaw[address >> 5][(address >> 3) & 0x3] &= 0x00FF;
					this.OBJMatrixParametersRaw[address >> 5][(address >> 3) & 0x3] |= data << 8;
					this.OBJMatrixParameters[address >> 5][(address >> 3) & 0x3] = (this.OBJMatrixParametersRaw[address >> 5][(address >> 3) & 0x3] << 16) >> 16;
			}
			this.OAMRAM[address & 0x3FF] = data | 0;
		}
		public function readOAM(address) {
			return this.OAMRAM[address & 0x3FF] | 0;
		}
		public function readOAM16Slow(address) {
			return this.OAMRAM[address] | (this.OAMRAM[address | 1] << 8);
		}
		public function readOAM16Optimized(address) {
			address = address | 0;
			return this.OAMRAM16[(address >> 1) & 0x1FF] | 0;
		}
		public function readOAM32Slow(address) {
			return this.OAMRAM[address] | (this.OAMRAM[address | 1] << 8) | (this.OAMRAM[address | 2] << 16)  | (this.OAMRAM[address | 3] << 24);
		}
		public function readOAM32Optimized(address) {
			address = address | 0;
			return this.OAMRAM32[(address >> 2) & 0xFF] | 0;
		}
		
		

	}
	
}
