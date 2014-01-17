package graphics {
	import utils.ArrayHelper;
	
	public class GameBoyAdvanceAffineBGRenderer {

		public var scratchBuffer;
		public var BGdx = 0x100;
		public var BGdmx = 0;
		public var BGdy = 0;
		public var BGdmy = 0x100;
		public var actualBGdx = 0x100;
		public var actualBGdmx = 0;
		public var actualBGdy = 0;
		public var actualBGdmy = 0x100;
		public var BGReferenceX = 0;
		public var BGReferenceY = 0;
		public var actualBGReferenceX = 0;
		public var actualBGReferenceY = 0;
		public var pb = 0;
		public var pd = 0;
		
		public var priorityFlag;
		
		public var gfx;
  	 	public var BGLayer;
		
		public function GameBoyAdvanceAffineBGRenderer(gfx, BGLayer) {
			// constructor code
			this.gfx = gfx;
  	 		this.BGLayer = BGLayer;
			this.initialize();
		}
		
		public function initialize() {
			this.scratchBuffer = ArrayHelper.buildArray(240);
			this.BGdx = 0x100;
			this.BGdmx = 0;
			this.BGdy = 0;
			this.BGdmy = 0x100;
			this.actualBGdx = 0x100;
			this.actualBGdmx = 0;
			this.actualBGdy = 0;
			this.actualBGdmy = 0x100;
			this.BGReferenceX = 0;
			this.BGReferenceY = 0;
			this.actualBGReferenceX = 0;
			this.actualBGReferenceY = 0;
			this.pb = 0;
			this.pd = 0;
			this.priorityPreprocess();
		}
		public function renderScanLine(line, BGObject) {
			line = line | 0;
			var x = this.pb | 0;
			var y = this.pd | 0;
			if (this.gfx.BGMosaic[this.BGLayer | 0]) {
				//Correct line number for mosaic:
				var mosaicY = this.gfx.mosaicRenderer.getMosaicYOffset(line | 0) | 0;
				x = ((x | 0) - ((this.actualBGdmx | 0) * (mosaicY | 0))) | 0;
				y = ((y | 0) - ((this.actualBGdmy | 0) * (mosaicY | 0))) | 0;
			}
			for (var position = 0; position < 240; position = (position + 1) | 0, x = ((x | 0) + (this.actualBGdx | 0)) | 0, y = ((y | 0) + (this.actualBGdy | 0)) | 0) {
				//Fetch pixel:
				this.scratchBuffer[position | 0] = (this.priorityFlag | 0) | (BGObject.fetchPixel(x >> 8, y >> 8) | 0);
			}
			if (this.gfx.BGMosaic[this.BGLayer | 0]) {
				//Pixelize the line horizontally:
				this.gfx.mosaicRenderer.renderMosaicHorizontal(this.scratchBuffer);
			}
			this.incrementReferenceCounters();
			return this.scratchBuffer;
		}
		public function incrementReferenceCounters() {
			this.pb = ((this.pb | 0) + (this.actualBGdmx | 0)) | 0;
			this.pd = ((this.pd | 0) + (this.actualBGdmy | 0)) | 0;
		}
		public function resetReferenceCounters() {
			this.pb = this.actualBGReferenceX | 0;
			this.pd = this.actualBGReferenceY | 0;
		}
		public function priorityPreprocess() {
			this.priorityFlag = (this.gfx.BGPriority[this.BGLayer] << 23) | (1 << (this.BGLayer + 0x10));
		}
		public function writeBGPA0(data) {
			data = data | 0;
			this.BGdx = (this.BGdx & 0xFF00) | data;
			this.actualBGdx = (this.BGdx << 16) >> 16;
		}
		public function writeBGPA1(data) {
			data = data | 0;
			this.BGdx = (data << 8) | (this.BGdx & 0xFF);
			this.actualBGdx = (this.BGdx << 16) >> 16;
		}
		public function writeBGPB0(data) {
			data = data | 0;
			this.BGdmx = (this.BGdmx & 0xFF00) | data;
			this.actualBGdmx = (this.BGdmx << 16) >> 16;
		}
		public function writeBGPB1(data) {
			data = data | 0;
			this.BGdmx = (data << 8) | (this.BGdmx & 0xFF);
			this.actualBGdmx = (this.BGdmx << 16) >> 16;
		}
		public function writeBGPC0(data) {
			data = data | 0;
			this.BGdy = (this.BGdy & 0xFF00) | data;
			this.actualBGdy = (this.BGdy << 16) >> 16;
		}
		public function writeBGPC1(data) {
			data = data | 0;
			this.BGdy = (data << 8) | (this.BGdy & 0xFF);
			this.actualBGdy = (this.BGdy << 16) >> 16;
		}
		public function writeBGPD0(data) {
			data = data | 0;
			this.BGdmy = (this.BGdmy & 0xFF00) | data;
			this.actualBGdmy = (this.BGdmy << 16) >> 16;
		}
		public function writeBGPD1(data) {
			data = data | 0;
			this.BGdmy = (data << 8) | (this.BGdmy & 0xFF);
			this.actualBGdmy = (this.BGdmy << 16) >> 16;
		}
		public function writeBGX_L0(data) {
			data = data | 0;
			this.BGReferenceX = (this.BGReferenceX & 0xFFFFF00) | data;
			this.actualBGReferenceX = (this.BGReferenceX << 4) >> 4;
			this.resetReferenceCounters();
		}
		public function writeBGX_L1(data) {
			data = data | 0;
			this.BGReferenceX = (data << 8) | (this.BGReferenceX & 0xFFF00FF);
			this.actualBGReferenceX = (this.BGReferenceX << 4) >> 4;
			this.resetReferenceCounters();
		}
		public function writeBGX_H0(data) {
			data = data | 0;
			this.BGReferenceX = (data << 16) | (this.BGReferenceX & 0xF00FFFF);
			this.actualBGReferenceX = (this.BGReferenceX << 4) >> 4;
			this.resetReferenceCounters();
		}
		public function writeBGX_H1(data) {
			data = data | 0;
			this.BGReferenceX = ((data & 0xF) << 24) | (this.BGReferenceX & 0xFFFFFF);
			this.actualBGReferenceX = (this.BGReferenceX << 4) >> 4;
			this.resetReferenceCounters();
		}
		public function writeBGY_L0(data) {
			data = data | 0;
			this.BGReferenceY = (this.BGReferenceY & 0xFFFFF00) | data;
			this.actualBGReferenceY = (this.BGReferenceY << 4) >> 4;
			this.resetReferenceCounters();
		}
		public function writeBGY_L1(data) {
			data = data | 0;
			this.BGReferenceY = (data << 8) | (this.BGReferenceY & 0xFFF00FF);
			this.actualBGReferenceY = (this.BGReferenceY << 4) >> 4;
			this.resetReferenceCounters();
		}
		public function writeBGY_H0(data) {
			data = data | 0;
			this.BGReferenceY = (data << 16) | (this.BGReferenceY & 0xF00FFFF);
			this.actualBGReferenceY = (this.BGReferenceY << 4) >> 4;
			this.resetReferenceCounters();
		}
		public function writeBGY_H1(data) {
			data = data | 0;
			this.BGReferenceY = ((data & 0xF) << 24) | (this.BGReferenceY & 0xFFFFFF);
			this.actualBGReferenceY = (this.BGReferenceY << 4) >> 4;
			this.resetReferenceCounters();
		}





	}
	
}
