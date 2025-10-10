import simd
import SwiftUI
import Spatial

enum MovementDirection {
    case forward, backward, left, right
}

protocol Camera {
    var origin: simd_float3 {get set}
    var orientation: simd_quatf {get set}
    
    var viewMatrix: simd_float4x4 {get}
    var projectionMatrix: simd_float4x4 {get}
    
    mutating func processViewportResize(size: CGSize)
}

protocol ResponsiveCamera: Camera {
    mutating func processMovement(movementDirections: [MovementDirection], deltaTime: Double)
    mutating func processMouseMovement(deltaX: Float, deltaY: Float)
    mutating func processMouseScroll(deltaY: Float)
}

protocol OrientationVectors where Self: Camera { }

extension OrientationVectors {
    var forwardVector: SIMD3<Float> {
        normalize(orientation.act(SIMD3<Float>(0, 0, 1)))
    }
    
    var rightVector: SIMD3<Float> {
        let upWorld = SIMD3<Float>(0, 1, 0)
        return normalize(cross(upWorld, forwardVector))
    }

    var upVector: SIMD3<Float> {
        normalize(cross(forwardVector, rightVector))
    }
}
