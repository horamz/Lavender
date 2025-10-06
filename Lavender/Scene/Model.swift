import Metal
import Spatial

class Model: Transformable, Renderable {
    var affineTransform: AffineTransform3D = .identity
    var meshes: [Mesh] = []
    
    init(meshes: [Mesh]) {
        self.meshes = meshes
    }
    
    func resources() -> [any MTLResource] {
        meshes.flatMap {$0.resources()}
    }
    
    func drawCalls() -> [DrawCall] {
        meshes.map {DrawCall(
            mesh: $0,
            modelMatrix: simd_float4x4(
                affineTransform * $0.affineTransform))}
    }
}
