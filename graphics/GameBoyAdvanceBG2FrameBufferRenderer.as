package graphics {
	
	public class GameBoyAdvanceBG2FrameBufferRenderer {
		
		public var gfx;
		public var transparency;
		public var palette;
		public var VRAM;
		public var VRAM16;
		public var fetchPixel;
		public var bgAffineRenderer;
		public var frameSelect;
		
		public function GameBoyAdvanceBG2FrameBufferRenderer(gfx) {
			// constructor code
			this.gfx = gfx;
			this.transparency = this.gfx.transparency;
			this.palette = this.gfx.palette256;
			this.VRAM = this.gfx.VRAM;
			this.VRAM16 = this.gfx.VRAM16;
			this.fetchPixel = this.fetchMode3Pixel;
			this.bgAffineRenderer = this.gfx.bgAffineRenderer[0];
			this.frameSelect = 0;
		}
		
		public function selectMode(mode) {
			mode = mode | 0;
			switch (mode | 0) {
				case 3:
					this.fetchPixel = (this.VRAM16) ? this.fetchMode3PixelOptimized : this.fetchMode3Pixel;
					break;
				case 4:
					this.fetchPixel = this.fetchMode4Pixel;
					break;
				case 5:
					this.fetchPixel = (this.VRAM16) ? this.fetchMode5PixelOptimized : this.fetchMode5Pixel;
			}
		}
		public function renderScanLine(line) {
			line = line | 0;
			return this.bgAffineRenderer.renderScanLine(line | 0, this);
		}
		public function fetchMode3Pixel(x, y) {
			//Output pixel:
			if (x > -1 && y > -1 && x < 240 && y < 160) {
				var address = ((y * 240) + x) << 1;
				return ((this.VRAM[address | 1] << 8) | this.VRAM[address]) & 0x7FFF;
			}
			//Out of range, output transparency:
			return this.transparency;
		}
		public function fetchMode3PixelOptimized(x, y) {
			x = x | 0;
			y = y | 0;
			//Output pixel:
			if ((x | 0) > -1 && (y | 0) > -1 && (x | 0) < 240 && (y | 0) < 160) {
				var address = (((y * 240) | 0) + (x | 0)) | 0;
				return this.VRAM16[address & 0xFFFF] & 0x7FFF;
			}
			//Out of range, output transparency:
			return this.transparency | 0;
		}
		public function fetchMode4Pixel(x, y) {
			x = x | 0;
			y = y | 0;
			//Output pixel:
			if ((x | 0) > -1 && (y | 0) > -1 && (x | 0) < 240 && (y | 0) < 160) {
				var address = ((this.frameSelect | 0) + ((y * 240) | 0) + (x | 0)) | 0;
				return this.palette[this.VRAM[address | 0] | 0] | 0;
			}
			//Out of range, output transparency:
			return this.transparency | 0;
		}
		public function fetchMode5Pixel(x, y) {
			//Output pixel:
			if (x > -1 && y > -1 && x < 160 && y < 128) {
				var address = this.frameSelect + (((y * 160) + x) << 1);
				return ((this.VRAM[address | 1] << 8) | this.VRAM[address]) & 0x7FFF;
			}
			//Out of range, output transparency:
			return this.transparency;
		}
		public function fetchMode5PixelOptimized(x, y) {
			x = x | 0;
			y = y | 0;
			//Output pixel:
			if ((x | 0) > -1 && (y | 0) > -1 && (x | 0) < 160 && (y | 0) < 128) {
				var address = ((this.frameSelect | 0) + ((y * 160) | 0) + (x | 0)) | 0;
				return this.VRAM16[address & 0xFFFF] & 0x7FFF;
			}
			//Out of range, output transparency:
			return this.transparency | 0;
		}
		public function writeFrameSelect(frameSelect) {
			frameSelect = frameSelect | 0;
			this.frameSelect = (frameSelect * 0xA000) | 0;
		}
		
		
		

	}
	
}
