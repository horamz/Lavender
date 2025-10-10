import Spatial
import SwiftUI

class PerspectiveCamera: Camera, OrientationVectors {
    var origin: simd_float3 = .zero
    var orientation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    
    var aspectRatio: Float = 1.0
    var fieldOfView: Float = 70.0
    var nearZ: Float = 0.1
    var farZ: Float = 1000.0
    
    var viewMatrix: simd_float4x4 {
        let upWorld: simd_float3 = [0, 1, 0]
        return lookAtLH(
            eye: origin,
            target: origin + orientation.act(SIMD3<Float>(0, 0, 1)),
            up: upWorld)
    }
    
    var projectionMatrix: simd_float4x4 {
        projectionTransformLH(
            fieldOfView: fieldOfView,
            near: nearZ,
            far: farZ,
            aspect: aspectRatio)
    }
    
    
    func processViewportResize(size: CGSize) {
        aspectRatio = Float(size.width / size.height)
    }
}

class PerspectiveResponsiveCamera: PerspectiveCamera, ResponsiveCamera {
    
    func processMovement(movementDirections: [MovementDirection], deltaTime: Double) {
        
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
    
    func processMouseMovement(deltaX: Float, deltaY: Float) {
        guard InputHandler.Shared.leftMouseDown else {
            return
        }
        
        let s = InputHandler.Settings.mouseSensitivity
        
        // Intuitive controls: mouse right => yaw right; mouse up => pitch up
        let yawDelta   =  deltaX * s
        let pitchInput = -deltaY * s
        
        // Clamp pitch using current forward.y
        let fwd = normalize(orientation.act(SIMD3<Float>(0, 0, 1))) // LH forward
        let currentPitch = asin(simd_clamp(fwd.y, -1, 1))
        let maxPitch: Float = .pi * 0.5 - 0.001
        let desiredPitch = simd_clamp(currentPitch + pitchInput, -maxPitch, maxPitch)
        let pitchDelta = desiredPitch - currentPitch
        
        // Apply yaw about world +Y, then pitch about camera right (after yaw)
        let qYaw  = simd_quatf(angle: yawDelta, axis: SIMD3<Float>(0, 1, 0))
        let yawed = simd_normalize(qYaw * orientation)
        
        let forwardAfterYaw = normalize(yawed.act(SIMD3<Float>(0, 0, 1)))           // LH forward
        let rightAfterYaw   = normalize(cross(SIMD3<Float>(0, 1, 0), forwardAfterYaw)) // LH: up × f
        let qPitch = simd_quatf(angle: pitchDelta, axis: rightAfterYaw)
        
        orientation = simd_normalize(qPitch * yawed)
    }
    
    
    func processMouseScroll(deltaY: Float) {
        
    }
}

