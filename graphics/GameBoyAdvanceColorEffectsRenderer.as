package graphics {
	import utils.MathsHelper;
	
	public class GameBoyAdvanceColorEffectsRenderer {
		
		public var alphaBlendAmountTarget1;
		public var alphaBlendAmountTarget2;
		public var effectsTarget1;
		public var colorEffectsType;
		public var effectsTarget2;
		public var brightnessEffectAmount;
		public var alphaBlend;
		public var brightnessIncrease;
		public var brightnessDecrease;
		
		public function GameBoyAdvanceColorEffectsRenderer() {
			// constructor code
			this.alphaBlendAmountTarget1 = 0;
			this.alphaBlendAmountTarget2 = 0;
			this.effectsTarget1 = 0;
			this.colorEffectsType = 0;
			this.effectsTarget2 = 0;
			this.brightnessEffectAmount = 0;
			this.alphaBlend = (MathsHelper.imul != null) ? this.alphaBlendFast : this.alphaBlendSlow;
			this.brightnessIncrease = (MathsHelper.imul != null) ? this.brightnessIncreaseFast : this.brightnessIncreaseSlow;
			this.brightnessDecrease = (MathsHelper.imul != null) ? this.brightnessDecreaseFast : this.brightnessDecreaseSlow;
		}
		
		public function processOAMSemiTransparent(lowerPixel, topPixel) {
			lowerPixel = lowerPixel | 0;
			topPixel = topPixel | 0;
			if (((lowerPixel | 0) & (this.effectsTarget2 | 0)) != 0) {
				return this.alphaBlend(topPixel | 0, lowerPixel | 0) | 0;
			}
			else if (((topPixel | 0) & (this.effectsTarget1 | 0)) != 0) {
				switch (this.colorEffectsType | 0) {
					case 2:
						return this.brightnessIncrease(topPixel | 0) | 0;
					case 3:
						return this.brightnessDecrease(topPixel | 0) | 0;
				}
			}
			return topPixel | 0;
		}
		public function process(lowerPixel, topPixel) {
			lowerPixel = lowerPixel | 0;
			topPixel = topPixel | 0;
			if (((topPixel | 0) & (this.effectsTarget1 | 0)) != 0) {
				switch (this.colorEffectsType | 0) {
					case 1:
						if (((lowerPixel | 0) & (this.effectsTarget2 | 0)) != 0 && (topPixel | 0) != (lowerPixel | 0)) {
							return this.alphaBlend(topPixel | 0, lowerPixel | 0) | 0;
						}
						break;
					case 2:
						return this.brightnessIncrease(topPixel | 0) | 0;
					case 3:
						return this.brightnessDecrease(topPixel | 0) | 0;
				}
			}
			return topPixel | 0;
		}
		public function alphaBlendSlow(topPixel, lowerPixel) {
			topPixel = topPixel | 0;
			lowerPixel = lowerPixel | 0;
			var b1 = (topPixel >> 10) & 0x1F;
			var g1 = (topPixel >> 5) & 0x1F;
			var r1 = (topPixel & 0x1F);
			var b2 = (lowerPixel >> 10) & 0x1F;
			var g2 = (lowerPixel >> 5) & 0x1F;
			var r2 = lowerPixel & 0x1F;
			b1 = b1 * this.alphaBlendAmountTarget1;
			g1 = g1 * this.alphaBlendAmountTarget1;
			r1 = r1 * this.alphaBlendAmountTarget1;
			b2 = b2 * this.alphaBlendAmountTarget2;
			g2 = g2 * this.alphaBlendAmountTarget2;
			r2 = r2 * this.alphaBlendAmountTarget2;
			return (Math.min((b1 + b2) >> 4, 0x1F) << 10) | (Math.min((g1 + g2) >> 4, 0x1F) << 5) | Math.min((r1 + r2) >> 4, 0x1F);
		}
		public function alphaBlendFast(topPixel, lowerPixel) {
			topPixel = topPixel | 0;
			lowerPixel = lowerPixel | 0;
			var b1 = (topPixel >> 10) & 0x1F;
			var g1 = (topPixel >> 5) & 0x1F;
			var r1 = topPixel & 0x1F;
			var b2 = (lowerPixel >> 10) & 0x1F;
			var g2 = (lowerPixel >> 5) & 0x1F;
			var r2 = lowerPixel & 0x1F;
			b1 = MathsHelper.imul(b1 | 0, this.alphaBlendAmountTarget1 | 0) | 0;
			g1 = MathsHelper.imul(g1 | 0, this.alphaBlendAmountTarget1 | 0) | 0;
			r1 = MathsHelper.imul(r1 | 0, this.alphaBlendAmountTarget1 | 0) | 0;
			b2 = MathsHelper.imul(b2 | 0, this.alphaBlendAmountTarget2 | 0) | 0;
			g2 = MathsHelper.imul(g2 | 0, this.alphaBlendAmountTarget2 | 0) | 0;
			r2 = MathsHelper.imul(r2 | 0, this.alphaBlendAmountTarget2 | 0) | 0;
			//Keep this not inlined in the return, firefox 22 grinds on it:
			var b = Math.min(((b1 | 0) + (b2 | 0)) >> 4, 0x1F) | 0;
			var g = Math.min(((g1 | 0) + (g2 | 0)) >> 4, 0x1F) | 0;
			var r = Math.min(((r1 | 0) + (r2 | 0)) >> 4, 0x1F) | 0;
			return (b << 10) | (g << 5) | r;
		}
		public function brightnessIncreaseSlow(topPixel) {
			topPixel = topPixel | 0;
			var b1 = (topPixel >> 10) & 0x1F;
			var g1 = (topPixel >> 5) & 0x1F;
			var r1 = topPixel & 0x1F;
			b1 += ((0x1F - b1) * this.brightnessEffectAmount) >> 4;
			g1 += ((0x1F - g1) * this.brightnessEffectAmount) >> 4;
			r1 += ((0x1F - r1) * this.brightnessEffectAmount) >> 4;
			return (b1 << 10) | (g1 << 5) | r1;
		}
		public function brightnessIncreaseFast(topPixel) {
			topPixel = topPixel | 0;
			var b1 = (topPixel >> 10) & 0x1F;
			var g1 = (topPixel >> 5) & 0x1F;
			var r1 = topPixel & 0x1F;
			b1 = ((b1 | 0) + (MathsHelper.imul((0x1F - (b1 | 0)) | 0, this.brightnessEffectAmount | 0) >> 4)) | 0;
			g1 = ((g1 | 0) + (MathsHelper.imul((0x1F - (g1 | 0)) | 0, this.brightnessEffectAmount | 0) >> 4)) | 0;
			r1 = ((r1 | 0) + (MathsHelper.imul((0x1F - (r1 | 0)) | 0, this.brightnessEffectAmount | 0) >> 4)) | 0;
			return (b1 << 10) | (g1 << 5) | r1;
		}
		public function brightnessDecreaseSlow(topPixel) {
			topPixel = topPixel | 0;
			var b1 = (topPixel >> 10) & 0x1F;
			var g1 = (topPixel >> 5) & 0x1F;
			var r1 = topPixel & 0x1F;
			var decreaseMultiplier = 0x10 - this.brightnessEffectAmount;
			b1 = (b1 * decreaseMultiplier) >> 4;
			g1 = (g1 * decreaseMultiplier) >> 4;
			r1 = (r1 * decreaseMultiplier) >> 4;
			return (b1 << 10) | (g1 << 5) | r1;
		}
		public function brightnessDecreaseFast(topPixel) {
			topPixel = topPixel | 0;
			var b1 = (topPixel >> 10) & 0x1F;
			var g1 = (topPixel >> 5) & 0x1F;
			var r1 = topPixel & 0x1F;
			var decreaseMultiplier = (0x10 - (this.brightnessEffectAmount | 0)) | 0;
			b1 = MathsHelper.imul(b1 | 0, decreaseMultiplier | 0) >> 4;
			g1 = MathsHelper.imul(g1 | 0, decreaseMultiplier | 0) >> 4;
			r1 = MathsHelper.imul(r1 | 0, decreaseMultiplier | 0) >> 4;
			return (b1 << 10) | (g1 << 5) | r1;
		}
		public function writeBLDCNT0(data) {
			//Select target 1 and color effects mode:
			this.effectsTarget1 = (data & 0x3F) << 16;
			this.colorEffectsType = data >> 6;
		}
		public function readBLDCNT0(data) {
			return (this.colorEffectsType << 6) | (this.effectsTarget1 >> 16);
		}
		public function writeBLDCNT1(data) {
			//Select target 2:
			this.effectsTarget2 = (data & 0x3F) << 16;
		}
		public function readBLDCNT1(data) {
			return this.effectsTarget2 >> 16;
		}
		public function writeBLDALPHA0(data) {
			this.alphaBlendAmountTarget1 = Math.min(data & 0x1F, 0x10) | 0;
		}
		public function writeBLDALPHA1(data) {
			this.alphaBlendAmountTarget2 = Math.min(data & 0x1F, 0x10) | 0;
		}
		public function writeBLDY(data) {
			this.brightnessEffectAmount = Math.min(data & 0x1F, 0x10) | 0;
		}
		
		

	}
	
}
