package graphics {
	
	public class GameBoyAdvanceMosaicRenderer {

		public var transparency;
		public var BGMosaicHSize;
		public var BGMosaicVSize;
		public var OBJMosaicHSize;
		public var OBJMosaicVSize;

		public function GameBoyAdvanceMosaicRenderer(gfx) {
			// constructor code
			this.transparency = gfx.transparency | 0;
			this.BGMosaicHSize = 0;
			this.BGMosaicVSize = 0;
			this.OBJMosaicHSize = 0;
			this.OBJMosaicVSize = 0;
		}
		
		public function renderMosaicHorizontal(layer) {
			var currentPixel = 0;
			var mosaicBlur = ((this.BGMosaicHSize | 0) + 1) | 0;
			if (mosaicBlur > 1) {	//Don't perform a useless loop.
				for (var position = 0; (position | 0) < 240; position = ((position | 0) + 1) | 0) {
					if ((((position | 0) % (mosaicBlur | 0)) | 0) == 0) {
						currentPixel = layer[position | 0] | 0;
					}
					else {
						layer[position | 0] = currentPixel | 0;
					}
				}
			}
		}
		public function renderOBJMosaicHorizontal(layer, xOffset, xSize) {
			var xOffset = xOffset | 0;
			var xSize = xSize | 0;
			var currentPixel = this.transparency | 0;
			var mosaicBlur = ((this.OBJMosaicHSize | 0) + 1) | 0;
			if (mosaicBlur > 1) {	//Don't perform a useless loop.
				for (var position = ((xOffset | 0) % (mosaicBlur | 0)) | 0; (position | 0) < (xSize | 0); position = ((position | 0) + 1) | 0) {
					if ((((position | 0) % (mosaicBlur | 0)) | 0) == 0) {
						currentPixel = layer[position | 0] | 0;
					}
					layer[position | 0] = currentPixel | 0;
				}
			}
		}
		public function getMosaicYOffset(line) {
			line = line | 0;
			return ((line | 0) % (((this.BGMosaicVSize | 0) + 1) | 0)) | 0;
		}
		public function getOBJMosaicYOffset(line) {
			line = line | 0;
			return ((line | 0) % (((this.OBJMosaicVSize | 0) + 1) | 0)) | 0;
		}
		public function writeMOSAIC0(data) {
			data = data | 0;
			this.BGMosaicHSize = data & 0xF;
			this.BGMosaicVSize = data >> 4;
		}
		public function writeMOSAIC1(data) {
			data = data | 0;
			this.OBJMosaicHSize = data & 0xF;
			this.OBJMosaicVSize = data >> 4;
		}
		
		

	}
	
}
