package graphics {
	
	public class GameBoyAdvanceMode2Renderer {
		
		public var gfx;
		
		public function GameBoyAdvanceMode2Renderer(gfx) {
			// constructor code
			this.gfx = gfx;
		}
		
		public function renderScanLine(line) {
			
			
			var BG2Buffer = (this.gfx.displayBG2) ? this.gfx.bg2MatrixRenderer.renderScanLine(line) : null;
			var BG3Buffer = (this.gfx.displayBG3) ? this.gfx.bg3MatrixRenderer.renderScanLine(line) : null;
			var OBJBuffer = (this.gfx.displayOBJ) ? this.gfx.objRenderer.renderScanLine(line) : null;
			this.gfx.compositeLayers(OBJBuffer, null, null, BG2Buffer, BG3Buffer);
			if (this.gfx.displayObjectWindowFlag) {
				this.gfx.objWindowRenderer.renderScanLine(line, this.gfx.lineBuffer, OBJBuffer, null, null, BG2Buffer, BG3Buffer);
			}
			if (this.gfx.displayWindow1Flag) {
				this.gfx.window1Renderer.renderScanLine(line, this.gfx.lineBuffer, OBJBuffer, null, null, BG2Buffer, BG3Buffer);
			}
			if (this.gfx.displayWindow0Flag) {
				this.gfx.window0Renderer.renderScanLine(line, this.gfx.lineBuffer, OBJBuffer, null, null, BG2Buffer, BG3Buffer);
			}
			this.gfx.copyLineToFrameBuffer(line);
			
		}
		
		

	}
	
}
