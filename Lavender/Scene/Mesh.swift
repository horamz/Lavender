import Spatial
import MetalKit


class Mesh: Transformable, Renderable {
    var affineTransform: AffineTransform3D = .identity
    var name: String = "Unnamed Mesh " + UUID().uuidString.prefix(8)
    let vertexBuffers: [MTLBuffer]
    let vertexCount: Int
    let submeshes: [Submesh]
    
    init(vertexBuffers: [MTLBuffer],
         vertexCount: Int,
         submeshes: [Submesh])
    {
        self.vertexBuffers = vertexBuffers
        self.vertexCount = vertexCount
        self.submeshes = submeshes
    }
    
    convenience init(mdlMesh: MDLMesh, mtkMesh: MTKMesh) {
        let vertexBuffers = mtkMesh.vertexBuffers.map {$0.buffer}
        let submeshes
            = zip(mdlMesh.submeshes!.map {$0 as! MDLSubmesh},
                mtkMesh.submeshes).map {mesh in
                    Submesh(mdlSubmesh: mesh.0, mtkSubmesh: mesh.1)
                }
        self.init(vertexBuffers: vertexBuffers, vertexCount: mtkMesh.vertexCount, submeshes: submeshes)
    }
    
    func drawCalls() -> [DrawCall] {
        [DrawCall(mesh: self,
            modelMatrix: simd_float4x4(affineTransform))]
    }
    
    func resources() -> [any MTLResource] {
        vertexBuffers + submeshes.flatMap { submesh -> [any MTLResource] in
            [submesh.indexBuffer] +
            [submesh.material?.baseColor.textureValue].compactMap { $0 }
        }
    }
}










