func projectionTransformLH(
    fieldOfView: Float,
    near: Float,
    far: Float,
    aspect: Float,
    lhs: Bool = true) -> simd_float4x4
{
    let y = 1 / tan(fieldOfView * 0.5)
    let x = y / aspect
    let z = lhs ? far / (far - near) : far / (near - far)
    let X = SIMD4<Float>( x,  0,  0,  0)
    let Y = SIMD4<Float>( 0,  y,  0,  0)
    let Z = lhs ? SIMD4<Float>( 0,  0,  z, 1) : SIMD4<Float>( 0,  0,  z, -1)
    let W = lhs ? SIMD4<Float>( 0,  0,  z * -near,  0) : SIMD4<Float>( 0,  0,  z * near,  0)
    
    return simd_float4x4(columns: (X, Y, Z, W))
    
}

func lookAtLH(eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
    let z = normalize(target - eye)
    let x = normalize(cross(up, z))
    let y = cross(z, x)
    
    let X = SIMD4<Float>(x.x, y.x, z.x, 0)
    let Y = SIMD4<Float>(x.y, y.y, z.y, 0)
    let Z = SIMD4<Float>(x.z, y.z, z.z, 0)
    let W = SIMD4<Float>(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)
    
    return simd_float4x4(columns: (X, Y, Z, W))
}

@inline(__always)
func orthoLH(l: Float, r: Float, b: Float, t: Float, n: Float, f: Float) -> simd_float4x4 {
    let sx = 2.0 / (r - l)
    let sy = 2.0 / (t - b)
    let sz = 1.0 / (f - n)          // LH -> positive
    let tx = (l + r) / (l - r)
    let ty = (t + b) / (b - t)
    let tz = n / (n - f)            // == -n/(f - n)
    
    return simd_float4x4(
        SIMD4<Float>( sx,  0,  0,  0),
        SIMD4<Float>(  0, sy,  0,  0),
        SIMD4<Float>(  0,  0, sz,  0),
        SIMD4<Float>(tx, ty, tz,  1)
    )
}

import SwiftUI

func ortho1(orthographic rect: CGRect, near: Float, far: Float) -> simd_float4x4 {
    let left = Float(rect.origin.x)
    let right = Float(rect.origin.x + rect.width)
    let top = Float(rect.origin.y)
    let bottom = Float(rect.origin.y - rect.height)
    let X = SIMD4<Float>(2 / (right - left), 0, 0, 0)
    let Y = SIMD4<Float>(0, 2 / (top - bottom), 0, 0)
    let Z = SIMD4<Float>(0, 0, 1 / (far - near), 0)
    let W = SIMD4<Float>(
        (left + right) / (left - right),
        (top + bottom) / (bottom - top),
        near / (near - far),
        1)
    return simd_float4x4(columns: (X, Y, Z, W))
}
