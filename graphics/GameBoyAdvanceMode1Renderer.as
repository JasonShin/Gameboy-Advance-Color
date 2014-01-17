package graphics {
	
	public class GameBoyAdvanceMode1Renderer {
		
		public var gfx;
		
		public function GameBoyAdvanceMode1Renderer(gfx) {
			// constructor code
			this.gfx = gfx;
		}
		public function renderScanLine(line) {
			var BG0Buffer = (this.gfx.displayBG0) ? this.gfx.bg0Renderer.renderScanLine(line) : null;
			var BG1Buffer = (this.gfx.displayBG1) ? this.gfx.bg1Renderer.renderScanLine(line) : null;
			var BG2Buffer = (this.gfx.displayBG2) ? this.gfx.bg2MatrixRenderer.renderScanLine(line) : null;
			var OBJBuffer = (this.gfx.displayOBJ) ? this.gfx.objRenderer.renderScanLine(line) : null;
			this.gfx.compositeLayers(OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, null);
			if (this.gfx.displayObjectWindowFlag) {
				this.gfx.objWindowRenderer.renderScanLine(line, this.gfx.lineBuffer, OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, null);
			}
			if (this.gfx.displayWindow1Flag) {
				this.gfx.window1Renderer.renderScanLine(line, this.gfx.lineBuffer, OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, null);
			}
			if (this.gfx.displayWindow0Flag) {
				this.gfx.window0Renderer.renderScanLine(line, this.gfx.lineBuffer, OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, null);
			}
			this.gfx.copyLineToFrameBuffer(line);
		}
				
		
		

	}
	
}
