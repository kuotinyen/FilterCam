//
//  PhotoFilterManager.swift
//  FilterCam
//
//  Created by TING YEN KUO on 2024/3/11.
//

import CoreImage

class PhotoFilterManager {
    static let shared = PhotoFilterManager()
    private init() { }
    
    let colorControls = CIFilter.colorControls()
    let highlightShadowAdjust = CIFilter.highlightShadowAdjust()
    let temperatureAndTint = CIFilter.temperatureAndTint()
    let vignette = CIFilter.vignette()
    
    func dummy() {
        colorControls.saturation = 0.7 // 增艷
//        colorControls.brightness = 0.1 // 亮度
        colorControls.contrast = 1.2 // 對比
        
        highlightShadowAdjust.highlightAmount = 1.1 // 亮部
//        highlightShadowAdjust.shadowAmount = -0.15 // 陰影
        
        temperatureAndTint.neutral = CIVector(x: 6555, y: 7)
        
        vignette.intensity = 0.4 // 暈邊强度
        vignette.radius = 0.6 // 暈邊半径
    }
    
    func filtered(ciImage: CIImage) -> CIImage? {
        // Color Controls
        colorControls.inputImage = ciImage
        guard let intermediateImage = colorControls.outputImage else { return nil }
        
        // Highlight Shadow
        highlightShadowAdjust.inputImage = intermediateImage
        guard let shadowHighlightOutput = highlightShadowAdjust.outputImage else { return nil }

        // Temperature and Tint
        temperatureAndTint.inputImage = shadowHighlightOutput
        guard let temperatureOutput = temperatureAndTint.outputImage else { return nil }

        // Vignette
        vignette.inputImage = temperatureOutput
        guard let vignetteOutput = vignette.outputImage else { return nil }
        
        //        return vignetteOutput
        
        let photoEffect = CIFilter.photoEffectFade()
        photoEffect.inputImage = vignetteOutput

        return photoEffect.outputImage
    }
}
