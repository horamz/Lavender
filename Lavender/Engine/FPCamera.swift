import Spatial
import SwiftUI

struct FPCamera: ResponsiveCamera, OrientationVectors {
    var origin: simd_float3 = .zero
    var orientation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    
    var aspectRatio: Double = 1.0
    var fieldOfView: Angle2D = .degrees(60)
    var nearZ: Double = 0.1
    var farZ: Double = 1000.0
    
    var viewMatrix: simd_float4x4 {
        let t = AffineTransform3D(rotation: Rotation3D(orientation),
                                  translation: Vector3D(vector: simd_double3(origin)))
        return simd_float4x4(t.inverse!)
    }
    
    var projectionMatrix: simd_float4x4 {
        let p = ProjectiveTransform3D(fovY: fieldOfView,
                                      aspectRatio: aspectRatio,
                                      nearZ: nearZ,
                                      farZ: farZ)
        return simd_float4x4(p)
    }
    
    
    mutating func processViewportResize(size: CGSize) {
        aspectRatio = size.width / size.height
    }
    
    mutating func processMovement(movementDirections: [MovementDirection], deltaTime: Double) {
        
        var dir = simd_float3.zero
        let translationAmount: Float =  Float(deltaTime) * InputHandler.Settings.translationSpeed
        
        for movementDir in movementDirections {
            switch movementDir {
            case .forward: dir.z += 1
            case .backward: dir.z -= 1
            case .left: dir.x -= 1
            case .right: dir.x += 1
            }
        }
        
        if dir != .zero {
            dir = normalize(dir)
            origin += (dir.z * forwardVector + dir.x * rightVector) * translationAmount
        }
    }
    
    mutating func processMouseMovement(deltaX: Float, deltaY: Float) {
        guard InputHandler.Shared.leftMouseDown else {
            return
        }
        
        let s = InputHandler.Settings.mouseSensitivity
        
        let yawDelta   = -deltaX * s
        let pitchInput = deltaY * s
        
        
        let fwd = forwardVector
        let currentPitch = asin(simd_clamp(fwd.y, -1, 1))
        let maxPitch: Float = .pi * 0.5 - 0.001
        let desiredPitch = simd_clamp(currentPitch + pitchInput, -maxPitch, maxPitch)
        let pitchDelta = desiredPitch - currentPitch
        
        // Apply yaw about world-up, then pitch about camera's right (after yaw)
        let qYaw   = simd_quatf(angle: yawDelta, axis: SIMD3<Float>(0, 1, 0))
        let yawed  = simd_normalize(qYaw * orientation)
        
        let rightAfterYaw = normalize(cross(yawed.act(SIMD3<Float>(0, 0, -1)),
                                            SIMD3<Float>(0, 1, 0)))
        let qPitch = simd_quatf(angle: pitchDelta, axis: rightAfterYaw)
        
        orientation = simd_normalize(qPitch * yawed)
        
    }
    
    
    func processMouseScroll(deltaY: Float) {
        
    }
}

