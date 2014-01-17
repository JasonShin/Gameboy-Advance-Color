package graphics {
	import utils.MathsHelper;
	
	public class GameBoyAdvanceBGMatrixRenderer {

		public var gfx;
		public var BGLayer;
		public var VRAM;
		public var palette;
		public var transparency;
		public var bgAffineRenderer;
		public var fetchTile;
		public var BGScreenBaseBlock;
		public var mapSize;
		public var mapSizeComparer;
		public var BGCharacterBaseBlock;
		public var BGDisplayOverflow;
		
		public function GameBoyAdvanceBGMatrixRenderer(gfx, BGLayer) {
			// constructor code
			this.gfx = gfx;
			this.BGLayer = BGLayer | 0;
			this.VRAM = this.gfx.VRAM;
			this.palette = this.gfx.palette256;
			this.transparency = this.gfx.transparency | 0;
			this.bgAffineRenderer = this.gfx.bgAffineRenderer[BGLayer & 0x1];
			this.fetchTile = (MathsHelper.imul != null) ? this.fetchTileOptimized : this.fetchTileSlow;
			//this.fetchTile = this.fetchTileSlow;
			this.screenSizePreprocess();
			this.screenBaseBlockPreprocess();
			this.characterBaseBlockPreprocess();
			this.displayOverflowPreprocess();
		}
		
		public function renderScanLine(line) {
			line = line | 0;
			return this.bgAffineRenderer.renderScanLine(line | 0, this);
		}
		public function fetchTileSlow(x, y, mapSize) {
			//Compute address for tile VRAM to address:
			var tileNumber = x + (y * mapSize);
			return this.VRAM[((tileNumber | 0) + (this.BGScreenBaseBlock | 0)) & 0xFFFF];
		}
		public function fetchTileOptimized(x, y, mapSize) {
			//Compute address for tile VRAM to address:
			x = x | 0;
			y = y | 0;
			mapSize = mapSize | 0;
			var tileNumber = ((x | 0) + MathsHelper.imul(y | 0, mapSize | 0)) | 0;
			return this.VRAM[((tileNumber | 0) + (this.BGScreenBaseBlock | 0)) & 0xFFFF] | 0;
		}
		public function computeScreenAddress(x, y) {
			//Compute address for character VRAM to address:
			x = x | 0;
			y = y | 0;
			var address = this.fetchTile(x >> 3, y >> 3, this.mapSize | 0) << 6;
			address = ((address | 0) + (this.BGCharacterBaseBlock | 0)) | 0;
			address = ((address | 0) + ((y & 0x7) << 3)) | 0;
			address = ((address | 0) + (x & 0x7)) | 0;
			return address | 0;
		}
		public function fetchPixel(x, y) {
			//Fetch the pixel:
			x = x | 0;
			y = y | 0;
			var mapSizeComparer = this.mapSizeComparer | 0;
			var overflowX = x & mapSizeComparer;
			var overflowY = y & mapSizeComparer;
			//Output pixel:
			if ((x | 0) != (overflowX | 0) || (y | 0) != (overflowY | 0)) {
				//Overflow Handling:
				if (this.BGDisplayOverflow) {
					//Overflow Back:
					x = overflowX | 0;
					y = overflowY | 0;
				}
				else {
					//Out of bounds with no overflow allowed:
					return this.transparency | 0;
				}
			}
			var address = this.computeScreenAddress(x | 0, y | 0) | 0;
			return this.palette[this.VRAM[address & 0xFFFF] | 0] | 0;
		}
		public function screenSizePreprocess() {
			this.mapSize = 0x10 << (this.gfx.BGScreenSize[this.BGLayer | 0] | 0);
			this.mapSizeComparer = ((this.mapSize << 3) - 1) | 0;
		}
		public function screenBaseBlockPreprocess() {
			this.BGScreenBaseBlock = this.gfx.BGScreenBaseBlock[this.BGLayer | 0] << 11;
		}
		public function characterBaseBlockPreprocess() {
			this.BGCharacterBaseBlock = this.gfx.BGCharacterBaseBlock[this.BGLayer | 0] << 14;
		}
		public function displayOverflowPreprocess() {
			this.BGDisplayOverflow = this.gfx.BGDisplayOverflow[this.BGLayer | 0];
		}
		
		

	}
	
}
