@inline(__always)
func projectionTransformLH(
    fieldOfView: Float,
    nearZ: Float,
    farZ: Float,
    aspectRatio: Float) -> simd_float4x4
{
    let y = 1 / tan(fieldOfView * 0.5)
    let x = y / aspectRatio
    let z = farZ / (farZ - nearZ)
    let X = SIMD4<Float>( x,  0,  0,  0)
    let Y = SIMD4<Float>( 0,  y,  0,  0)
    let Z = SIMD4<Float>( 0,  0,  z, 1)
    let W = SIMD4<Float>( 0,  0,  z * -nearZ,  0)
    
    return simd_float4x4(columns: (X, Y, Z, W))
}

@inline(__always)
func lookAtLH(
    eye: SIMD3<Float>,
    target: SIMD3<Float>,
    up: SIMD3<Float>) -> simd_float4x4
{
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
func orthographicTransformLH(
    orthoHeight: Float,
    aspectRatio: Float,
    nearZ: Float,
    farZ: Float) -> simd_float4x4
{
    let halfH = Float(orthoHeight * 0.5)
    let halfW = halfH * aspectRatio
    
    let l: Float = -halfW
    let r: Float =  halfW
    let b: Float = -halfH
    let t: Float =  halfH
    let n: Float = Float(nearZ)
    let f: Float = Float(farZ)
    
    // DirectX/Metal-style LH ortho with z in [0,1]
    let sx = 2.0 / (r - l)
    let sy = 2.0 / (t - b)
    let sz = 1.0 / (f - n)
    let tx = (l + r) / (l - r)
    let ty = (t + b) / (b - t)
    let tz = n / (n - f)
    
    return simd_float4x4(
        SIMD4<Float>( sx,  0,  0,  0),
        SIMD4<Float>(  0, sy,  0,  0),
        SIMD4<Float>(  0,  0, sz,  0),
        SIMD4<Float>(tx, ty, tz,  1)
    )
}
