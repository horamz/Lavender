import MetalKit
import Spatial

final class ArcballCamera: ResponsiveCamera, OrientationVectors {
    var origin: SIMD3<Float> = .zero
    var orientation = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
    
    var target: SIMD3<Float> = .zero
    var distance: Float = 5.0
    
    var aspectRatio: Float = 1.0
    var mouseSensitivity: Float = 0.002
    var zoomSensitivity: Float  = 1.1
    var minDistance: Float = 0.2
    var maxDistance: Float = 1000
    
    var fieldOfView: Float = 70.0
    var nearZ: Float = 0.1
    var farZ:  Float = 1000.0
    
    
    var viewMatrix: simd_float4x4 {
        origin = target - forwardVector * distance
        return lookAtLH(eye: origin, target: target, up: SIMD3<Float>(0, 1, 0))
    }
    
    var projectionMatrix: simd_float4x4 {
        projectionTransformLH(fieldOfView: fieldOfView,
                              near: nearZ,
                              far:  farZ,
                              aspect: aspectRatio)
    }
    
    func processViewportResize(size: CGSize) {
        aspectRatio = Float(size.width / size.height)
    }
    
    func processMovement(movementDirections: [MovementDirection], deltaTime: Double) {}
    
    // --- Arcball orbit (LH): yaw about +Y (world), pitch about camera right (after yaw) ---
    func processMouseMovement(deltaX: Float, deltaY: Float) {
        guard InputHandler.Shared.leftMouseDown else { return }
        
        let s = mouseSensitivity
        
        // Arcball signs (LH): mouse right -> orbit right ; mouse up -> orbit up
        let yawDelta   = deltaX * s
        let pitchInput = -deltaY * s
        
        // 1) world-up yaw (pre-multiply)
        let qYaw  = simd_quatf(angle: yawDelta, axis: SIMD3<Float>(0, 1, 0))
        let yawed = simd_normalize(qYaw * orientation)
        
        // 2) current forward after yaw (LH forward = act(0,0,1))
        let fwdAfterYaw = normalize(yawed.act(SIMD3<Float>(0, 0, 1)))
        
        // clamp pitch to avoid pole flip
        let currentPitch = asin(simd_clamp(fwdAfterYaw.y, -1, 1))
        let maxPitch: Float = .pi * 0.5 - 0.001
        let desiredPitch = simd_clamp(currentPitch + pitchInput, -maxPitch, maxPitch)
        let pitchDelta = desiredPitch - currentPitch
        
        // 3) pitch about camera RIGHT (LH: right = up × forward)
        let rightAfterYaw = normalize(cross(SIMD3<Float>(0, 1, 0), fwdAfterYaw))
        let qPitch = simd_quatf(angle: pitchDelta, axis: rightAfterYaw)
        
        orientation = simd_normalize(qPitch * yawed)
        
        // stay on orbit sphere
        origin = target - forwardVector * distance
    }
    
    func processMouseScroll(deltaY: Float) {
    }
}
