﻿package graphics {
	
	public class GameBoyAdvanceCompositor {

		public var gfx;
		public var renderScanLine;

		public function GameBoyAdvanceCompositor(gfx) {
			// constructor code
			this.gfx = gfx;
			this.preprocess(false);
		}
		
		public function preprocess(doEffects) {
			this.renderScanLine = (doEffects) ? this.renderScanLineWithEffects : this.renderNormalScanLine;
		}
		public function cleanLayerStack(OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, BG3Buffer) {
			//Clear out disabled layers from our stack:
			var layerStack = [];
			if (BG3Buffer) {
				layerStack.push(BG3Buffer);
			}
			if (BG2Buffer) {
				layerStack.push(BG2Buffer);
			}
			if (BG1Buffer) {
				layerStack.push(BG1Buffer);
			}
			if (BG0Buffer) {
				layerStack.push(BG0Buffer);
			}
			if (OBJBuffer) {
				layerStack.push(OBJBuffer);
			}
			return layerStack;
		}
		public function renderNormalScanLine(xStart, xEnd, lineBuffer, OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, BG3Buffer) {
			xStart = xStart | 0;
			xEnd = xEnd | 0;
			var layerStack = this.cleanLayerStack(OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, BG3Buffer);
			switch (layerStack.length) {
				case 0:
					this.fillWithBackdrop(xStart | 0, xEnd | 0, lineBuffer);
					break;
				case 1:
					this.composite1Layer(xStart | 0, xEnd | 0, lineBuffer, layerStack[0]);
					break;
				case 2:
					this.composite2Layer(xStart | 0, xEnd | 0, lineBuffer, layerStack[0], layerStack[1]);
					break;
				case 3:
					this.composite3Layer(xStart | 0, xEnd | 0, lineBuffer, layerStack[0], layerStack[1], layerStack[2]);
					break;
				case 4:
					this.composite4Layer(xStart | 0, xEnd | 0, lineBuffer, layerStack[0], layerStack[1], layerStack[2], layerStack[3]);
					break;
				case 5:
					this.composite5Layer(xStart | 0, xEnd | 0, lineBuffer, layerStack[0], layerStack[1], layerStack[2], layerStack[3], layerStack[4]);
			}
		}
		public function renderScanLineWithEffects(xStart, xEnd, lineBuffer, OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, BG3Buffer) {
			xStart = xStart | 0;
			xEnd = xEnd | 0;
			var layerStack = this.cleanLayerStack(OBJBuffer, BG0Buffer, BG1Buffer, BG2Buffer, BG3Buffer);
			switch (layerStack.length) {
				case 0:
					this.fillWithBackdropSpecial(xStart | 0, xEnd | 0, lineBuffer);
					break;
				case 1:
					this.composite1LayerSpecial(xStart | 0, xEnd | 0, lineBuffer, layerStack[0]);
					break;
				case 2:
					this.composite2LayerSpecial(xStart | 0, xEnd | 0, lineBuffer, layerStack[0], layerStack[1]);
					break;
				case 3:
					this.composite3LayerSpecial(xStart | 0, xEnd | 0, lineBuffer, layerStack[0], layerStack[1], layerStack[2]);
					break;
				case 4:
					this.composite4LayerSpecial(xStart | 0, xEnd | 0, lineBuffer, layerStack[0], layerStack[1], layerStack[2], layerStack[3]);
					break;
				case 5:
					this.composite5LayerSpecial(xStart | 0, xEnd | 0, lineBuffer, layerStack[0], layerStack[1], layerStack[2], layerStack[3], layerStack[4]);
			}
		}
		public function fillWithBackdrop(xStart, xEnd, lineBuffer) {
			xStart = xStart | 0;
			xEnd = xEnd | 0;
			while ((xStart | 0) < (xEnd | 0)) {
				lineBuffer[xStart | 0] = this.gfx.backdrop | 0;
				xStart = ((xStart | 0) + 1) | 0;
			}
		}
		public function fillWithBackdropSpecial(xStart, xEnd, lineBuffer) {
			xStart = xStart | 0;
			xEnd = xEnd | 0;
			while ((xStart | 0) < (xEnd | 0)) {
				lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.process(0, this.gfx.backdrop | 0) | 0;
				xStart = ((xStart | 0) + 1) | 0;
			}
		}
		public function composite1Layer(xStart, xEnd, lineBuffer, layer0) {
			xStart = xStart | 0;
			xEnd = xEnd | 0;
			var currentPixel = 0;
			var lowerPixel = 0;
			var workingPixel = 0;
			while ((xStart | 0) < (xEnd | 0)) {
				lowerPixel = currentPixel = this.gfx.backdrop | 0;
				workingPixel = layer0[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				if ((currentPixel & 0x400000) == 0) {
					//Normal Pixel:
					lineBuffer[xStart | 0] = currentPixel | 0;
				}
				else {
					//OAM Pixel Processing:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.processOAMSemiTransparent(lowerPixel | 0, currentPixel | 0) | 0;
				}
				xStart = ((xStart | 0) + 1) | 0;
			}
		}
		public function composite2Layer(xStart, xEnd, lineBuffer, layer0, layer1) {
			xStart = xStart | 0;
			xEnd = xEnd | 0;
			var currentPixel = 0;
			var lowerPixel = 0;
			var workingPixel = 0;
			while ((xStart | 0) < (xEnd | 0)) {
				lowerPixel = currentPixel = this.gfx.backdrop | 0;
				workingPixel = layer0[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer1[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				if ((currentPixel & 0x400000) == 0) {
					//Normal Pixel:
					lineBuffer[xStart | 0] = currentPixel | 0;
				}
				else {
					//OAM Pixel Processing:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.processOAMSemiTransparent(lowerPixel | 0, currentPixel | 0) | 0;
				}
				xStart = ((xStart | 0) + 1) | 0;
			}
		}
		public function composite3Layer(xStart, xEnd, lineBuffer, layer0, layer1, layer2) {
			xStart = xStart | 0;
			xEnd = xEnd | 0;
			var currentPixel = 0;
			var lowerPixel = 0;
			var workingPixel = 0;
			while ((xStart | 0) < (xEnd | 0)) {
				lowerPixel = currentPixel = this.gfx.backdrop | 0;
				workingPixel = layer0[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer1[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer2[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				if ((currentPixel & 0x400000) == 0) {
					//Normal Pixel:
					lineBuffer[xStart | 0] = currentPixel | 0;
				}
				else {
					//OAM Pixel Processing:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.processOAMSemiTransparent(lowerPixel | 0, currentPixel | 0) | 0;
				}
				xStart = ((xStart | 0) + 1) | 0;
			}
		}
		public function composite4Layer(xStart, xEnd, lineBuffer, layer0, layer1, layer2, layer3) {
			xStart = xStart | 0;
			xEnd = xEnd | 0;
			var currentPixel = 0;
			var lowerPixel = 0;
			var workingPixel = 0;
			while ((xStart | 0) < (xEnd | 0)) {
				lowerPixel = currentPixel = this.gfx.backdrop | 0;
				workingPixel = layer0[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer1[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer2[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer3[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				if ((currentPixel & 0x400000) == 0) {
					//Normal Pixel:
					lineBuffer[xStart | 0] = currentPixel | 0;
				}
				else {
					//OAM Pixel Processing:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.processOAMSemiTransparent(lowerPixel | 0, currentPixel | 0) | 0;
				}
				xStart = ((xStart | 0) + 1) | 0;
			}
		}
		public function composite5Layer(xStart, xEnd, lineBuffer, layer0, layer1, layer2, layer3, layer4) {
			xStart = xStart | 0;
			xEnd = xEnd | 0;
			var currentPixel = 0;
			var lowerPixel = 0;
			var workingPixel = 0;
			while ((xStart | 0) < (xEnd | 0)) {
				lowerPixel = currentPixel = this.gfx.backdrop | 0;
				workingPixel = layer0[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer1[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer2[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer3[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer4[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				if ((currentPixel & 0x400000) == 0) {
					//Normal Pixel:
					lineBuffer[xStart | 0] = currentPixel | 0;
				}
				else {
					//OAM Pixel Processing:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.processOAMSemiTransparent(lowerPixel | 0, currentPixel | 0) | 0;
				}
				xStart = ((xStart | 0) + 1) | 0;
			}
		}
		public function composite1LayerSpecial(xStart, xEnd, lineBuffer, layer0) {
			xStart = xStart | 0;
			xEnd = xEnd | 0;
			var currentPixel = 0;
			var lowerPixel = 0;
			var workingPixel = 0;
			while ((xStart | 0) < (xEnd | 0)) {
				lowerPixel = currentPixel = this.gfx.backdrop | 0;
				workingPixel = layer0[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				if ((currentPixel & 0x400000) == 0) {
					//Normal Pixel:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.process(lowerPixel | 0, currentPixel | 0) | 0;
				}
				else {
					//OAM Pixel Processing:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.processOAMSemiTransparent(lowerPixel | 0, currentPixel | 0) | 0;
				}
				xStart = ((xStart | 0) + 1) | 0;
			}
		}
		public function composite2LayerSpecial(xStart, xEnd, lineBuffer, layer0, layer1) {
			xStart = xStart | 0;
			xEnd = xEnd | 0;
			var currentPixel = 0;
			var lowerPixel = 0;
			var workingPixel = 0;
			while ((xStart | 0) < (xEnd | 0)) {
				lowerPixel = currentPixel = this.gfx.backdrop | 0;
				workingPixel = layer0[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer1[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				if ((currentPixel & 0x400000) == 0) {
					//Normal Pixel:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.process(lowerPixel | 0, currentPixel | 0) | 0;
				}
				else {
					//OAM Pixel Processing:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.processOAMSemiTransparent(lowerPixel | 0, currentPixel | 0) | 0;
				}
				xStart = ((xStart | 0) + 1) | 0;
			}
		}
		public function composite3LayerSpecial(xStart, xEnd, lineBuffer, layer0, layer1, layer2) {
			xStart = xStart | 0;
			xEnd = xEnd | 0;
			var currentPixel = 0;
			var lowerPixel = 0;
			var workingPixel = 0;
			while ((xStart | 0) < (xEnd | 0)) {
				lowerPixel = currentPixel = this.gfx.backdrop | 0;
				workingPixel = layer0[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer1[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer2[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				if ((currentPixel & 0x400000) == 0) {
					//Normal Pixel:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.process(lowerPixel | 0, currentPixel | 0) | 0;
				}
				else {
					//OAM Pixel Processing:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.processOAMSemiTransparent(lowerPixel | 0, currentPixel | 0) | 0;
				}
				xStart = ((xStart | 0) + 1) | 0;
			}
		}
		public function composite4LayerSpecial(xStart, xEnd, lineBuffer, layer0, layer1, layer2, layer3) {
			xStart = xStart | 0;
			xEnd = xEnd | 0;
			var currentPixel = 0;
			var lowerPixel = 0;
			var workingPixel = 0;
			while ((xStart | 0) < (xEnd | 0)) {
				lowerPixel = currentPixel = this.gfx.backdrop | 0;
				workingPixel = layer0[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer1[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer2[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer3[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				if ((currentPixel & 0x400000) == 0) {
					//Normal Pixel:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.process(lowerPixel | 0, currentPixel | 0) | 0;
				}
				else {
					//OAM Pixel Processing:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.processOAMSemiTransparent(lowerPixel | 0, currentPixel | 0) | 0;
				}
				xStart = ((xStart | 0) + 1) | 0;
			}
		}
		public function composite5LayerSpecial(xStart, xEnd, lineBuffer, layer0, layer1, layer2, layer3, layer4) {
			xStart = xStart | 0;
			xEnd = xEnd | 0;
			var currentPixel = 0;
			var lowerPixel = 0;
			var workingPixel = 0;
			while ((xStart | 0) < (xEnd | 0)) {
				lowerPixel = currentPixel = this.gfx.backdrop | 0;
				workingPixel = layer0[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer1[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer2[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer3[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				workingPixel = layer4[xStart | 0] | 0;
				if ((workingPixel & 0x3800000) <= (currentPixel & 0x1800000)) {
					lowerPixel = currentPixel | 0;
					currentPixel = workingPixel | 0;
				}
				else if ((workingPixel & 0x3800000) <= (lowerPixel & 0x1800000)) {
					lowerPixel = workingPixel | 0;
				}
				if ((currentPixel & 0x400000) == 0) {
					//Normal Pixel:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.process(lowerPixel | 0, currentPixel | 0) | 0;
				}
				else {
					//OAM Pixel Processing:
					//Pass the highest two pixels to be arbitrated in the color effects processing:
					lineBuffer[xStart | 0] = this.gfx.colorEffectsRenderer.processOAMSemiTransparent(lowerPixel | 0, currentPixel | 0) | 0;
				}
				xStart = ((xStart | 0) + 1) | 0;
			}
		}
		
		
		

	}
	
}
