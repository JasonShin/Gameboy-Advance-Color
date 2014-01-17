package graphics {
	import utils.ArrayHelper;
	
	public class GameBoyAdvanceBGTEXTRenderer {

		public var gfx;
		public var VRAM;
		public var VRAM16;
		public var fetchTile;
		public var BGLayer;
		public var scratchBuffer;
		public var BGXCoord;
		public var BGYCoord;
		public var priorityFlag;
		public var tileMode;
		public var BGScreenBaseBlock8;
		public var BGScreenBaseBlock16;
		public var BGCharacterBaseBlock;
		public var palette;
		
		//Function
		public var fetchVRAM;

		public function GameBoyAdvanceBGTEXTRenderer(gfx, BGLayer) {
			// constructor code
			this.gfx = gfx;
			this.VRAM = this.gfx.VRAM;
			this.VRAM16 = this.gfx.VRAM16;
			this.fetchTile = (this.VRAM16) ? this.fetchTileOptimized : this.fetchTileNormal;
			this.BGLayer = BGLayer | 0;
			this.initialize();
		}
		
		
		public function initialize() {
			this.scratchBuffer = ArrayHelper.buildArray(248);
			this.BGXCoord = 0;
			this.BGYCoord = 0;
			this.palettePreprocess();
			this.screenSizePreprocess();
			this.priorityPreprocess();
			this.screenBaseBlockPreprocess();
			this.characterBaseBlockPreprocess();
		}
		public function renderScanLine(line) {
			line = line | 0;
			if (this.gfx.BGMosaic[this.BGLayer | 0]) {
				//Correct line number for mosaic:
				line = ((line | 0) - (this.gfx.mosaicRenderer.getMosaicYOffset(line | 0) | 0)) | 0;
			}
			var yTileOffset = ((line | 0) + (this.BGYCoord | 0)) & 0x7;
			var pixelPipelinePosition = this.BGXCoord & 0x7;
			var yTileStart = ((line | 0) + (this.BGYCoord | 0)) >> 3;
			var xTileStart = this.BGXCoord >> 3;
			for (var position = 0, chrData = 0; (position | 0) < 240;) {
				chrData = this.fetchTile(yTileStart | 0, xTileStart | 0) | 0;
				xTileStart = ((xTileStart | 0) + 1) | 0;
				while ((pixelPipelinePosition | 0) < 0x8) {
					this.scratchBuffer[position | 0] = this.priorityFlag | this.fetchVRAM(chrData | 0, pixelPipelinePosition | 0, yTileOffset | 0);
					pixelPipelinePosition = ((pixelPipelinePosition | 0) + 1) | 0;
					position = ((position | 0) + 1) | 0;
				}
				pixelPipelinePosition &= 0x7;
			}
			if (this.gfx.BGMosaic[this.BGLayer | 0]) {
				//Pixelize the line horizontally:
				this.gfx.mosaicRenderer.renderMosaicHorizontal(this.scratchBuffer);
			}
			return this.scratchBuffer;
		}
		public function fetchTileNormal(yTileStart, xTileStart) {
			//Find the tile code to locate the tile block:
			var address = this.computeScreenMapAddress8(this.computeTileNumber(yTileStart | 0, xTileStart | 0) | 0) | 0;
			return (this.VRAM[address | 1] << 8) | this.VRAM[address];
		}
		public function fetchTileOptimized(yTileStart, xTileStart) {
			yTileStart = yTileStart | 0;
			xTileStart = xTileStart | 0;
			//Find the tile code to locate the tile block:
			var address = this.computeScreenMapAddress16(this.computeTileNumber(yTileStart | 0, xTileStart | 0) | 0) | 0;
			return this.VRAM16[address & 0x7FFF] | 0;
		}
		public function computeTileNumber(yTile, xTile) {
			//Return the true tile number:
			yTile = yTile | 0;
			xTile = xTile | 0;
			//Compute sub-super-tile offsets:
			var tile = xTile & 0x1F;
			tile = (tile | 0) | ((yTile & 0x1F) << 5);
			//Add super tile offsets:
			switch (this.tileMode | 0) {
				case 2:
					//1x2
					tile = ((tile | 0) + ((yTile & 0x20) << 5)) | 0;
					break;
				case 3:
					//2x2
					tile = ((tile | 0) + ((yTile & 0x20) << 6)) | 0;
				case 1:
					//2x1, 2x2
					tile = ((tile | 0) + ((xTile & 0x20) << 5)) | 0;
					
			}
			return tile | 0;
		}
		public function computeScreenMapAddress8(tileNumber) {
			tileNumber = tileNumber | 0;
			return ((tileNumber << 1) | this.BGScreenBaseBlock8) & 0xFFFF;
		}
		public function computeScreenMapAddress16(tileNumber) {
			tileNumber = tileNumber | 0;
			return (tileNumber | this.BGScreenBaseBlock16) & 0x7FFF;
		}
		public function fetch4BitVRAM(chrData, xOffset, yOffset) {
			//16 color tile mode:
			chrData = chrData | 0;
			xOffset = xOffset | 0;
			yOffset = yOffset | 0;
			//Parse flip attributes, grab palette, and then output pixel:
			var address = (chrData & 0x3FF) << 5;
			address = ((address | 0) + (this.BGCharacterBaseBlock | 0)) | 0;
			address = ((address | 0) + ((((chrData & 0x800) == 0x800) ? (0x7 - (yOffset | 0)) : (yOffset | 0)) << 2));
			address = ((address | 0) + ((((chrData & 0x400) == 0x400) ? (0x7 - (xOffset | 0)) : (xOffset | 0)) >> 1));
			if ((xOffset & 0x1) == ((chrData & 0x400) >> 10)) {
				return this.palette[chrData >>> 12][this.VRAM[address & 0xFFFF] & 0xF] | 0;
			}
			return this.palette[chrData >>> 12][this.VRAM[address & 0xFFFF] >> 4] | 0;
		}
		public function fetch8BitVRAM(chrData, xOffset, yOffset) {
			//256 color tile mode:
			chrData = chrData | 0;
			xOffset = xOffset | 0;
			yOffset = yOffset | 0;
			//Parse flip attributes and output pixel:
			var address = (chrData & 0x3FF) << 6;
			address = ((address | 0) + (this.BGCharacterBaseBlock | 0)) | 0;
			address = ((address | 0) + ((((chrData & 0x800) == 0x800) ? (0x7 - (yOffset | 0)) : (yOffset | 0)) << 3)) | 0;
			address = ((address | 0) + ((((chrData & 0x400) == 0x400) ? (0x7 - (xOffset | 0)) : (xOffset | 0)) | 0)) | 0;
			return this.palette[this.VRAM[address & 0xFFFF] | 0] | 0;
		}
		public function palettePreprocess() {
			//Make references:
			if (this.gfx.BGPalette256[this.BGLayer | 0]) {
				this.palette = this.gfx.palette256;
				this.fetchVRAM = this.fetch8BitVRAM;
			}
			else {
				this.palette = this.gfx.palette16;
				this.fetchVRAM = this.fetch4BitVRAM;
			}
		}
		public function screenSizePreprocess() {
			this.tileMode = this.gfx.BGScreenSize[this.BGLayer | 0] | 0;
		}
		public function priorityPreprocess() {
			this.priorityFlag = (this.gfx.BGPriority[this.BGLayer | 0] << 23) | (1 << ((this.BGLayer | 0) + 0x10));
		}
		public function screenBaseBlockPreprocess() {
			this.BGScreenBaseBlock8 = this.gfx.BGScreenBaseBlock[this.BGLayer | 0] << 11;
			this.BGScreenBaseBlock16 = this.BGScreenBaseBlock8 >> 1;
		}
		public function characterBaseBlockPreprocess() {
			this.BGCharacterBaseBlock = this.gfx.BGCharacterBaseBlock[this.BGLayer | 0] << 14;
		}
		public function writeBGHOFS0(data) {
			data = data | 0;
			this.BGXCoord = (this.BGXCoord & 0x100) | data;
		}
		public function writeBGHOFS1(data) {
			data = data | 0;
			this.BGXCoord = ((data & 0x01) << 8) | (this.BGXCoord & 0xFF);
		}
		public function writeBGVOFS0(data) {
			data = data | 0;
			this.BGYCoord = (this.BGYCoord & 0x100) | data;
		}
		public function writeBGVOFS1(data) {
			data = data | 0;
			this.BGYCoord = ((data & 0x01) << 8) | (this.BGYCoord & 0xFF);
		}
				
		

	}
	
}
