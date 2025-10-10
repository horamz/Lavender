import Spatial
import SwiftUI

class OrthographicCamera: Camera, OrientationVectors {
    var origin: simd_float3 = .zero
    var orientation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    
    var orthoHeight: Float = 10.0
    var aspectRatio: Float = 1.0
    
    var nearZ: Float = 0.1
    var farZ:  Float = 1000.0
    

    var viewMatrix: simd_float4x4 {
        let f = orientation.act(SIMD3<Float>(0, 0, 1))
        let u = orientation.act(SIMD3<Float>(0, 1, 0))
        return lookAtLH(eye: origin, target: origin + f, up: u)
    }
    
    
    var projectionMatrix: simd_float4x4 {
        orthographicTransformLH(
            orthoHeight: orthoHeight,
            aspectRatio: aspectRatio,
            nearZ: nearZ,
            farZ: farZ)
    }
    
    func processViewportResize(size: CGSize) {
        aspectRatio = Float(size.width / size.height)
    }
}

class OrthographicResponsiveCamera: OrthographicCamera, ResponsiveCamera {
    // Tunables
    var minHeight: Double = 0.01
    var maxHeight: Double = 10000
    

    func processMouseScroll(deltaY: Float) {
        let z = InputHandler.Settings.scrollSensitivity
        let factor = pow(z, deltaY * 0.1)
        orthoHeight = Float(simd_clamp(Double(orthoHeight / factor), minHeight, maxHeight))
    }
    
    func processMovement(movementDirections: [MovementDirection], deltaTime: Double) {
        
        var dir = simd_float3.zero
        let translationAmount: Float =  Float(deltaTime) * InputHandler.Settings.translationSpeed
        
        for movementDir in movementDirections {
            switch movementDir {
            case .forward: dir.y += 1
            case .backward: dir.y -= 1
            case .left: dir.x -= 1
            case .right: dir.x += 1
            }
        }
        
        if dir != .zero {
            dir = normalize(dir)
            origin += (dir.y * upVector + dir.x * rightVector) * translationAmount
        }
    }
    
    func processMouseMovement(deltaX: Float, deltaY: Float) { }
}


