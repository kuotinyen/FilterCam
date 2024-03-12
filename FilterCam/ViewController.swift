//
//  ViewController.swift
//  FilterCam
//
//  Created by TING YEN KUO on 2024/3/11.
//

import UIKit
import SnapKit
import Photos
import CoreImage.CIFilterBuiltins

// <Goal>
// 1.Capture Photo and setup
// 2.CIFilter basic

class ViewController: UIViewController {
    private let previewPhotoImageView = UIImageView()
    private let captureButton = UIButton()
    private let cameraService = CameraService.shared
    
    private var temperatureVC = TemperatureNeutralViewController()
    private var vignetteVC = VignetteViewController()
    private var highlightShadowVC = HighlightShadowViewController()
    private var colorControlsVC = ColorControlsViewController()
    
    private let temperatureVector = CIVector(x: 8000, y: 10) // 默认值
    
    @objc func tapCaptureButton() {
        guard let image = previewPhotoImageView.image else { return }
        try? PHPhotoLibrary.shared().performChangesAndWait {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
    
    @objc func tapFilter() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(.init(title: "Temperature", style: .default, handler: { action in
            self.temperatureVC.imageView.image = self.previewPhotoImageView.image
            self.temperatureVC.view.backgroundColor = .white
            self.present(self.temperatureVC, animated: true)
        }))
        
        alertController.addAction(.init(title: "Vignette", style: .default, handler: { action in
            self.vignetteVC.imageView.image = self.previewPhotoImageView.image
            self.vignetteVC.view.backgroundColor = .white
            self.present(self.vignetteVC, animated: true)
        }))
        
        alertController.addAction(.init(title: "Highlight Shadow", style: .default, handler: { action in
            self.highlightShadowVC.imageView.image = self.previewPhotoImageView.image
            self.highlightShadowVC.view.backgroundColor = .white
            self.present(self.highlightShadowVC, animated: true)
        }))
        
        alertController.addAction(.init(title: "Color Controls", style: .default, handler: { action in
            self.colorControlsVC.imageView.image = self.previewPhotoImageView.image
            self.colorControlsVC.view.backgroundColor = .white
            self.present(self.colorControlsVC, animated: true)
        }))
        
        present(alertController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Service
        
        cameraService.delegate = self
        do {
            try cameraService.setupDevice()
        } catch {
            print(error)
        }
        
        cameraService.setupInputOutput()
        
        // UIs
        
        let navigationItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(tapFilter))
        self.navigationItem.rightBarButtonItem = navigationItem
        
        view.backgroundColor = .black
        
        previewPhotoImageView.backgroundColor = .gray
        captureButton.addTarget(self, action: #selector(tapCaptureButton), for: .touchUpInside)
        
        captureButton.snp.makeConstraints { make in
            make.size.equalTo(62)
        }
        captureButton.setImage(
            UIImage(named: "camera icon"),
            for: .normal
        )
        
        let stackView = UIStackView(arrangedSubviews: [previewPhotoImageView, captureButton])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 12
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.bottom.equalTo(view.layoutMarginsGuide)
            make.leading.trailing.equalToSuperview()
        }
    }
}

// MARK: - PhotoFilterPreviewDelegate

extension ViewController: PhotoFilterPreviewDelegate {
    func previewFilteredImage(image: UIImage) {
        DispatchQueue.main.async {
            self.previewPhotoImageView.image = image
            self.temperatureVC.imageView.image = image
            self.vignetteVC.imageView.image = image
            self.highlightShadowVC.imageView.image = image
            self.colorControlsVC.imageView.image = image
        }
    }
}

// MARK: - TemperatureNeutralViewController

class TemperatureNeutralViewController: UIViewController {
    var imageView = UIImageView()
    var temperatureNeutralXSlider: UISlider = .init(frame: .zero)
    var temperatureNeutralYSlider: UISlider = .init(frame: .zero)
    
    @objc private func dragX() {
        PhotoFilterManager.shared.temperatureAndTint.neutral = .init(
            x: CGFloat(temperatureNeutralXSlider.value),
            y: CGFloat(temperatureNeutralYSlider.value)
        )
        print(self.temperatureNeutralXSlider.value)
    }
    
    @objc private func dragY() {
        PhotoFilterManager.shared.temperatureAndTint.neutral = .init(
            x: CGFloat(temperatureNeutralXSlider.value),
            y: CGFloat(temperatureNeutralYSlider.value)
        )
        print(self.temperatureNeutralYSlider.value)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        temperatureNeutralXSlider.value = Float(PhotoFilterManager.shared.temperatureAndTint.neutral.x)
        temperatureNeutralYSlider.value = Float(PhotoFilterManager.shared.temperatureAndTint.neutral.y)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.snp.makeConstraints { make in
            make.height.equalTo(500)
        }
        
        print("#### \(PhotoFilterManager.shared.temperatureAndTint.attributes)")
        
        temperatureNeutralXSlider.minimumValue = 0
        temperatureNeutralXSlider.maximumValue = 20000
        temperatureNeutralXSlider.addTarget(self, action: #selector(dragX), for: .valueChanged)
        let temperatureNeutralXStack = temperatureNeutralXSlider.labelStack(title: "色溫(藍黃)")

        temperatureNeutralYSlider.minimumValue = -100
        temperatureNeutralYSlider.maximumValue = 100
        temperatureNeutralYSlider.addTarget(self, action: #selector(dragY), for: .valueChanged)
        let temperatureNeutralYStack = temperatureNeutralYSlider.labelStack(title: "色調(綠紅)")
        
        let controlStack = UIStackView(arrangedSubviews: [temperatureNeutralXStack, temperatureNeutralYStack])
        controlStack.axis = .vertical
        controlStack.distribution = .fillEqually
        
        let stackView = UIStackView(arrangedSubviews: [imageView, controlStack])
        stackView.spacing = 12
        stackView.axis = .vertical
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(view.layoutMarginsGuide)
        }
    }
}

class VignetteViewController: UIViewController {
    var imageView = UIImageView()
    var intensitySlider: UISlider = .init(frame: .zero)
    var radiusSlider: UISlider = .init(frame: .zero)
    
    @objc private func dragIntensity() {
        PhotoFilterManager.shared.vignette.intensity = intensitySlider.value
        PhotoFilterManager.shared.vignette.radius = radiusSlider.value
        print(self.intensitySlider.value)
    }
    
    @objc private func dragRadius() {
        PhotoFilterManager.shared.vignette.intensity = intensitySlider.value
        PhotoFilterManager.shared.vignette.radius = radiusSlider.value
        print(self.radiusSlider.value)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        intensitySlider.value = Float(PhotoFilterManager.shared.vignette.intensity)
        radiusSlider.value = Float(PhotoFilterManager.shared.vignette.radius)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.snp.makeConstraints { make in
            make.height.equalTo(500)
        }
        
        intensitySlider.minimumValue = 0
        intensitySlider.maximumValue = 10
        intensitySlider.addTarget(self, action: #selector(dragIntensity), for: .valueChanged)
        let intensityStack = intensitySlider.labelStack(title: "強度")

        radiusSlider.minimumValue = 0
        radiusSlider.maximumValue = 10
        radiusSlider.addTarget(self, action: #selector(dragRadius), for: .valueChanged)
        let radiusStack = radiusSlider.labelStack(title: "範圍")
        
        let controlStack = UIStackView(arrangedSubviews: [intensityStack, radiusStack])
        controlStack.axis = .vertical
        controlStack.distribution = .fillEqually
        
        let stackView = UIStackView(arrangedSubviews: [imageView, controlStack])
        stackView.spacing = 12
        stackView.axis = .vertical
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(view.layoutMarginsGuide)
        }
    }
}

class HighlightShadowViewController: UIViewController {
    var imageView = UIImageView()
    var highlightSlider: UISlider = .init(frame: .zero)
    var shadowSlider: UISlider = .init(frame: .zero)
    
    @objc private func dragHighlight() {
        PhotoFilterManager.shared.highlightShadowAdjust.highlightAmount = highlightSlider.value
        PhotoFilterManager.shared.highlightShadowAdjust.shadowAmount = shadowSlider.value
        print(self.highlightSlider.value)
    }
    
    @objc private func dragShadow() {
        PhotoFilterManager.shared.highlightShadowAdjust.highlightAmount = highlightSlider.value
        PhotoFilterManager.shared.highlightShadowAdjust.shadowAmount = shadowSlider.value
        print(self.shadowSlider.value)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        highlightSlider.value = Float(PhotoFilterManager.shared.highlightShadowAdjust.highlightAmount)
        shadowSlider.value = Float(PhotoFilterManager.shared.highlightShadowAdjust.shadowAmount)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.snp.makeConstraints { make in
            make.height.equalTo(500)
        }
        
        highlightSlider.minimumValue = 0
        highlightSlider.maximumValue = 10
        highlightSlider.addTarget(self, action: #selector(dragHighlight), for: .valueChanged)
        let highlightStack = highlightSlider.labelStack(title: "亮部")

        shadowSlider.minimumValue = 0
        shadowSlider.maximumValue = 10
        shadowSlider.addTarget(self, action: #selector(dragShadow), for: .valueChanged)
        let shadowStack = shadowSlider.labelStack(title: "暗部")
        
        let controlStack = UIStackView(arrangedSubviews: [highlightStack, shadowStack])
        controlStack.axis = .vertical
        controlStack.distribution = .fillEqually
        
        let stackView = UIStackView(arrangedSubviews: [imageView, controlStack])
        stackView.spacing = 12
        stackView.axis = .vertical
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(view.layoutMarginsGuide)
        }
    }
}

class ColorControlsViewController: UIViewController {
    var imageView = UIImageView()
    var saturationSlider: UISlider = .init(frame: .zero)
    var brightnessSlider: UISlider = .init(frame: .zero)
    var contrastSlider: UISlider = .init(frame: .zero)
    
    @objc private func dragSaturation() {
        PhotoFilterManager.shared.colorControls.saturation = saturationSlider.value
        PhotoFilterManager.shared.colorControls.brightness = brightnessSlider.value
        PhotoFilterManager.shared.colorControls.contrast = contrastSlider.value
        print(self.saturationSlider.value)
    }
    
    @objc private func dragBrightness() {
        PhotoFilterManager.shared.colorControls.saturation = saturationSlider.value
        PhotoFilterManager.shared.colorControls.brightness = brightnessSlider.value
        PhotoFilterManager.shared.colorControls.contrast = contrastSlider.value
        print(self.brightnessSlider.value)
    }
    
    @objc private func dragContrast() {
        PhotoFilterManager.shared.colorControls.saturation = saturationSlider.value
        PhotoFilterManager.shared.colorControls.brightness = brightnessSlider.value
        PhotoFilterManager.shared.colorControls.contrast = contrastSlider.value
        print(self.contrastSlider.value)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        saturationSlider.value = Float(PhotoFilterManager.shared.colorControls.saturation)
        brightnessSlider.value = Float(PhotoFilterManager.shared.colorControls.brightness)
        contrastSlider.value = Float(PhotoFilterManager.shared.colorControls.contrast)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.snp.makeConstraints { make in
            make.height.equalTo(500)
        }
        
        saturationSlider.minimumValue = 0
        saturationSlider.maximumValue = 10
        saturationSlider.addTarget(self, action: #selector(dragSaturation), for: .valueChanged)
        let saturationStack = saturationSlider.labelStack(title: "飽和度")

        brightnessSlider.minimumValue = 0
        brightnessSlider.maximumValue = 10
        brightnessSlider.addTarget(self, action: #selector(dragBrightness), for: .valueChanged)
        let brightnessStack = brightnessSlider.labelStack(title: "亮度")
        
        contrastSlider.minimumValue = 0
        contrastSlider.maximumValue = 10
        contrastSlider.addTarget(self, action: #selector(dragContrast), for: .valueChanged)
        let contrastStack = contrastSlider.labelStack(title: "對比度")
        
        let controlStack = UIStackView(arrangedSubviews: [saturationStack, brightnessStack, contrastStack])
        controlStack.axis = .vertical
        controlStack.distribution = .fillEqually
        
        let stackView = UIStackView(arrangedSubviews: [imageView, controlStack])
        stackView.spacing = 12
        stackView.axis = .vertical
        
        view.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(view.layoutMarginsGuide)
        }
    }
}

extension UISlider {
    func labelStack(title: String) -> UIStackView {
        let saturationLabel = UILabel()
        saturationLabel.text = title
        
        let stackView = UIStackView(arrangedSubviews: [saturationLabel, self])
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }
}
