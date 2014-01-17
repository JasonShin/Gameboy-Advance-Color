package graphics {
	
	public class GameBoyAdvanceModeFrameBufferRenderer {
		
		public var gfx;
		
		public function GameBoyAdvanceModeFrameBufferRenderer(gfx) {
			// constructor code
			this.gfx = gfx;
		}
		
		public function renderScanLine(line) {
			var BG2Buffer = (this.gfx.displayBG2) ? this.gfx.bg2FrameBufferRenderer.renderScanLine(line) : null;
			var OBJBuffer = (this.gfx.displayOBJ) ? this.gfx.objRenderer.renderScanLine(line) : null;
			this.gfx.compositeLayers(OBJBuffer, null, null, BG2Buffer, null);
			if (this.gfx.displayObjectWindowFlag) {
				this.gfx.objWindowRenderer.renderScanLine(line, this.gfx.lineBuffer, OBJBuffer, null, null, BG2Buffer, null);
			}
			if (this.gfx.displayWindow1Flag) {
				this.gfx.window1Renderer.renderScanLine(line, this.gfx.lineBuffer, OBJBuffer, null, null, BG2Buffer, null);
			}
			if (this.gfx.displayWindow0Flag) {
				this.gfx.window0Renderer.renderScanLine(line, this.gfx.lineBuffer, OBJBuffer, null, null, BG2Buffer, null);
			}
			this.gfx.copyLineToFrameBuffer(line);
		}
		public function preprocess(BGMode) {
			//Set up pixel fetcher ahead of time:
			this.gfx.bg2FrameBufferRenderer.selectMode(BGMode | 0);
		}
				
		

	}
	
}
