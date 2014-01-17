package graphics {
	
	public class GameBoyAdvanceOBJWindowRenderer {
		
		public var gfx;
		public var transparency;
		public var renderScanLine;
		
		public function GameBoyAdvanceOBJWindowRenderer(gfx) {
			// constructor code
			this.gfx = gfx;
			this.transparency = this.gfx.transparency | 0;
			this.preprocess();
		}
		
		public function renderNormalScanLine(line, lineBuffer, OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, BG3Buffer) {
			//Arrange our layer stack so we can remove disabled and order for correct edge case priority:
			OBJBuffer = (this.gfx.WINOBJOBJOutside) ? OBJBuffer : null;
			BG0Buffer = (this.gfx.WINOBJBG0Outside) ? BG0Buffer: null;
			BG1Buffer = (this.gfx.WINOBJBG1Outside) ? BG1Buffer: null;
			BG2Buffer = (this.gfx.WINOBJBG2Outside) ? BG2Buffer: null;
			BG3Buffer = (this.gfx.WINOBJBG3Outside) ? BG3Buffer: null;
			var layerStack = this.gfx.compositor.cleanLayerStack(OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, BG3Buffer);
			var stackDepth = layerStack.length | 0;
			var stackIndex = 0;
			var OBJWindowBuffer = this.gfx.objRenderer.renderWindowScanLine(line | 0);
			//Loop through each pixel on the line:
			for (var pixelPosition = 0, currentPixel = 0, workingPixel = 0, lowerPixel = 0; (pixelPosition | 0) < 240; pixelPosition = ((pixelPosition | 0) + 1) | 0) {
				//If non-transparent OBJ (Marked for OBJ WIN) pixel detected:
				if ((OBJWindowBuffer[pixelPosition] | 0) < (this.transparency | 0)) {
					//Start with backdrop color:
					lowerPixel = currentPixel = this.gfx.backdrop | 0;
					//Loop through all layers each pixel to resolve priority:
					for (stackIndex = 0; (stackIndex | 0) < (stackDepth | 0); stackIndex = ((stackIndex | 0) + 1) | 0) {
						workingPixel = layerStack[stackIndex | 0][pixelPosition | 0] | 0;
						if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
							/*
								If higher priority than last pixel and not transparent.
								Also clear any plane layer bits other than backplane for
								transparency.
								
								Keep a copy of the previous pixel (backdrop or non-transparent) for the color effects:
							*/
							lowerPixel = currentPixel | 0;
							currentPixel = workingPixel | 0;
						}
						else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
							/*
							 If higher priority than last pixel and not transparent.
							 Also clear any plane layer bits other than backplane for
							 transparency.
							 
							 Keep a copy of the previous pixel (backdrop or non-transparent) for the color effects:
							 */
							lowerPixel = workingPixel | 0;
						}
					}
					if ((currentPixel & 0x400000) == 0) {
						//Normal Pixel:
						lineBuffer[pixelPosition | 0] = currentPixel | 0;
					}
					else {
						//OAM Pixel Processing:
						//Pass the highest two pixels to be arbitrated in the color effects processing:
						lineBuffer[pixelPosition | 0] = this.gfx.colorEffectsRenderer.processOAMSemiTransparent(lowerPixel | 0, currentPixel | 0) | 0;
					}
				}
			}
		}
		public function renderScanLineWithEffects(line, lineBuffer, OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, BG3Buffer) {
			//Arrange our layer stack so we can remove disabled and order for correct edge case priority:
			if (this.gfx.displayObjectWindowFlag || this.gfx.displayWindow1Flag || this.gfx.displayWindow0Flag) {
				//Window registers can further disable background layers if one or more window layers enabled:
				OBJBuffer = (this.gfx.WINOBJOBJOutside) ? OBJBuffer : null;
				BG0Buffer = (this.gfx.WINOBJBG0Outside) ? BG0Buffer: null;
				BG1Buffer = (this.gfx.WINOBJBG1Outside) ? BG1Buffer: null;
				BG2Buffer = (this.gfx.WINOBJBG2Outside) ? BG2Buffer: null;
				BG3Buffer = (this.gfx.WINOBJBG3Outside) ? BG3Buffer: null;
			}
			var layerStack = this.gfx.compositor.cleanLayerStack(OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, BG3Buffer);
			var stackDepth = layerStack.length | 0;
			var stackIndex = 0;
			var OBJWindowBuffer = this.gfx.objRenderer.renderWindowScanLine(line | 0);
			//Loop through each pixel on the line:
			for (var pixelPosition = 0, currentPixel = 0, workingPixel = 0, lowerPixel = 0; (pixelPosition | 0) < 240; pixelPosition = ((pixelPosition | 0) + 1) | 0) {
				//If non-transparent OBJ (Marked for OBJ WIN) pixel detected:
				if ((OBJWindowBuffer[pixelPosition | 0] | 0) < (this.transparency | 0)) {
					//Start with backdrop color:
					lowerPixel = currentPixel = this.gfx.backdrop | 0;
					//Loop through all layers each pixel to resolve priority:
					for (stackIndex = 0; (stackIndex | 0) < (stackDepth | 0); stackIndex = ((stackIndex | 0) + 1) | 0) {
						workingPixel = layerStack[stackIndex | 0][pixelPosition | 0] | 0;
						if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
							/*
								If higher priority than last pixel and not transparent.
								Also clear any plane layer bits other than backplane for
								transparency.
								
								Keep a copy of the previous pixel (backdrop or non-transparent) for the color effects:
							*/
							lowerPixel = currentPixel | 0;
							currentPixel = workingPixel | 0;
						}
						else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
							/*
							 If higher priority than last pixel and not transparent.
							 Also clear any plane layer bits other than backplane for
							 transparency.
							 
							 Keep a copy of the previous pixel (backdrop or non-transparent) for the color effects:
							 */
							lowerPixel = workingPixel | 0;
						}
					}
					if ((currentPixel & 0x400000) == 0) {
						//Normal Pixel:
						//Pass the highest two pixels to be arbitrated in the color effects processing:
						lineBuffer[pixelPosition | 0] = this.gfx.colorEffectsRenderer.process(lowerPixel | 0, currentPixel | 0) | 0;
					}
					else {
						//OAM Pixel Processing:
						//Pass the highest two pixels to be arbitrated in the color effects processing:
						lineBuffer[pixelPosition | 0] = this.gfx.colorEffectsRenderer.processOAMSemiTransparent(lowerPixel | 0, currentPixel | 0) | 0;
					}
				}
			}
		}
		public function preprocess() {
			this.renderScanLine = (this.gfx.WINOBJEffectsOutside) ? this.renderScanLineWithEffects : this.renderNormalScanLine;
		}
		
		

	}
	
}
