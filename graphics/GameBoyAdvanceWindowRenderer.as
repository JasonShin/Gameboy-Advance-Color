package graphics {
	
	public class GameBoyAdvanceWindowRenderer {
		
		public var gfx;
		public var WINXCoordRight;
		public var WINXCoordLeft;
		public var WINYCoordBottom;
		public var WINYCoordTop;
		public var WINBG0;
		public var WINBG1;
		public var WINBG2;
		public var WINBG3;
		public var WINOBJ;
		public var WINEffects;
		public var compositor;
		
		
		public function GameBoyAdvanceWindowRenderer(gfx) {
			// constructor code
			this.gfx = gfx;
			this.WINXCoordRight = 0;
			this.WINXCoordLeft = 0;
			this.WINYCoordBottom = 0;
			this.WINYCoordTop = 0;
			this.WINBG0 = false;
			this.WINBG1 = false;
			this.WINBG2 = false;
			this.WINBG3 = false;
			this.WINOBJ = false;
			this.WINEffects = false;
			this.compositor = new GameBoyAdvanceCompositor(this.gfx);
			this.preprocess();
		}
		
		public function renderScanLine(line, lineBuffer, OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, BG3Buffer) {
			//Arrange our layer stack so we can remove disabled and order for correct edge case priority:
			OBJBuffer = (this.WINOBJ) ? OBJBuffer : null;
			BG0Buffer = (this.WINBG0) ? BG0Buffer : null;
			BG1Buffer = (this.WINBG1) ? BG1Buffer : null;
			BG2Buffer = (this.WINBG2) ? BG2Buffer : null;
			BG3Buffer = (this.WINBG3) ? BG3Buffer : null;
			if ((this.WINYCoordTop | 0) <= (line | 0) && (line | 0) < (this.WINYCoordBottom | 0)) {
				this.compositor.renderScanLine(this.WINXCoordLeft | 0, Math.min(this.WINXCoordRight | 0, 240) | 0, lineBuffer, OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, BG3Buffer);
			}
		}
		public function preprocess() {
			this.compositor.preprocess(this.WINEffects);
		}
		public function writeWINH0(data) {
			this.WINXCoordRight = data | 0;		//Window x-coord goes up to this minus 1.
		}
		public function writeWINH1(data) {
			this.WINXCoordLeft = data | 0;
		}
		public function writeWINV0(data) {
			this.WINYCoordBottom = data | 0;	//Window y-coord goes up to this minus 1.
		}
		public function writeWINV1(data) {
			this.WINYCoordTop = data | 0;
		}
		public function writeWININ(data) {
			data = data | 0;
			this.WINBG0 = ((data & 0x01) == 0x01);
			this.WINBG1 = ((data & 0x02) == 0x02);
			this.WINBG2 = ((data & 0x04) == 0x04);
			this.WINBG3 = ((data & 0x08) == 0x08);
			this.WINOBJ = ((data & 0x10) == 0x10);
			this.WINEffects = ((data & 0x20) == 0x20);
			this.preprocess();
		}
		public function readWININ() {
			return ((this.WINBG0 ? 0x1 : 0) |
					(this.WINBG1 ? 0x2 : 0) |
					(this.WINBG2 ? 0x4 : 0) |
					(this.WINBG3 ? 0x8 : 0) |
					(this.WINOBJ ? 0x10 : 0) |
					(this.WINEffects ? 0x20 : 0));
		}
		
		
		

	}
	
}
