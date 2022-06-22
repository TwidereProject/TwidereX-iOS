//
//  NonARDemoViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2022-6-22.
//  Copyright © 2022 Twidere. All rights reserved.
//

import os.log
import UIKit
import ARKit
import RealityKit

final class NonARDemoViewController: UIViewController, NeedsDependency {
    
    let logger = Logger(subsystem: "NonARDemoViewController", category: "ViewController")
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }

    private(set) lazy var sceneView = ARView()
    private(set) lazy var baseEntity = ModelEntity()
    private(set) lazy var camera = PerspectiveCamera()

    let cameraPositionFinal = SIMD3<Float>(
        x: 0,
        y: 1,
        z: 1
    )
    
    var current_X_Angle: Float = 0.0
    var current_Y_Angle: Float = 0.0
}

extension NonARDemoViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sceneView)
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        // Set debug options
        #if DEBUG
        sceneView.debugOptions = [.showWorldOrigin, .showAnchorOrigins, .showAnchorGeometry]
        #endif

        // setup ARView
        sceneView.cameraMode = .nonAR
        sceneView.environment.background = .color(.green)

        // base entity
        let anchor = AnchorEntity()
        sceneView.scene.addAnchor(anchor)
        anchor.addChild(baseEntity)
        
        // Add light
        let pointLight = PointLight()
        pointLight.light.intensity = 10000    // 10K
        let lightAnchor = AnchorEntity(world: [1, 1, 1])
        lightAnchor.addChild(pointLight)
        sceneView.scene.addAnchor(lightAnchor)
        
        // Add plane
        let planeMesh = MeshResource.generatePlane(width: 1, depth: 1)
        let planeMaterial = SimpleMaterial(color: .white, roughness: 0.5, isMetallic: true)
        let planeEntity = ModelEntity(mesh: planeMesh, materials: [planeMaterial])
        baseEntity.addChild(planeEntity)

        let boxSize: Float = 0.2
        let box = MeshResource.generateBox(size: boxSize)
        let boxMaterial = SimpleMaterial(color: UIColor.blue, roughness: 0, isMetallic: true)
        let boxEntity = ModelEntity(mesh: box, materials: [boxMaterial])
        boxEntity.transform = Transform(scale: .one, rotation: simd_quatf(), translation: SIMD3<Float>(x: 0, y: boxSize, z: 0))
        baseEntity.addChild(boxEntity)

        let text = MeshResource.generateText(
            "Hello",
            extrusionDepth: 0.1,
            font: .systemFont(ofSize: 17),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        let textMaterial = SimpleMaterial(color: UIColor.white.withAlphaComponent(0.25), roughness: 0, isMetallic: true)
        let textEntity = ModelEntity(mesh: text, materials: [textMaterial])
        textEntity.transform = Transform(scale: .one, rotation: simd_quatf(), translation: SIMD3<Float>(x: 0, y: 0, z: boxSize))
        baseEntity.addChild(textEntity)

        let cameraAnchor = AnchorEntity(world: .zero)
        cameraAnchor.addChild(camera)
        sceneView.scene.addAnchor(cameraAnchor)
        camera.look(at: .zero, from: cameraPositionFinal, relativeTo: baseEntity)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
}

extension NonARDemoViewController {
    
    func gestureRecognizer() {
        for gestureRecognizer in [UIPanGestureRecognizer.self,
                                  UIPinchGestureRecognizer.self] {
            if gestureRecognizer == UIPinchGestureRecognizer.self {
                let r = UIPinchGestureRecognizer(target: self,
                               action: #selector(allowCameraControl_01))
                sceneView.addGestureRecognizer(r)
            }
            if gestureRecognizer == UIPanGestureRecognizer.self {
                let r = UIPanGestureRecognizer(target: self,
                               action: #selector(allowCameraControl_02))
                sceneView.addGestureRecognizer(r)
            }
        }
    }
    @objc func allowCameraControl_01(recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
            case .changed, .ended:
                self.camera.position.z *= 1 / Float(recognizer.scale)
                recognizer.scale = 1.0
            default: break
        }
    }
    @objc func allowCameraControl_02(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
            case .changed, .ended:
                let translate = recognizer.translation(in: recognizer.view)
                let angle_X = Float(translate.y / 300) * .pi / 180.0
                let angle_Y = Float(translate.x / 100) * .pi / 180.0
                self.current_X_Angle += angle_X
                self.current_Y_Angle += angle_Y
                camera.setOrientation(Transform(pitch: current_X_Angle,
                                                  yaw: current_Y_Angle,
                                                 roll: .zero).rotation,
                                      relativeTo: baseEntity)
            default: break
        }
    }

}

// MARK: - UIAdaptivePresentationControllerDelegate
extension NonARDemoViewController: UIAdaptivePresentationControllerDelegate {
 
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }
    
}
