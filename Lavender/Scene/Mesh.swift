import Spatial
import MetalKit


class Mesh: Transformable, Renderable {
    var affineTransform: AffineTransform3D = .identity
    var name: String = "Unnamed Mesh " + UUID().uuidString.prefix(8)
    let vertexBuffers: [MTLBuffer]
    let vertexDescriptor: MDLVertexDescriptor
    let vertexCount: Int
    var submeshes: [Submesh]
    var materials: [Material]
    
    init(vertexBuffers: [MTLBuffer],
         vertexDescriptor: MDLVertexDescriptor,
         vertexCount: Int,
         submeshes: [Submesh],
         materials: [Material])
    {
        self.vertexBuffers = vertexBuffers
        self.vertexDescriptor = vertexDescriptor
        self.vertexCount = vertexCount
        self.submeshes = submeshes
        self.materials = materials
    }
    
    convenience init(mdlMesh: MDLMesh, mtkMesh: MTKMesh) {
        let vertexBuffers = mtkMesh.vertexBuffers.map {$0.buffer}
        let mdlSubmeshes = mdlMesh.submeshes!.map {$0 as! MDLSubmesh}
        let submeshes
        = zip(mdlSubmeshes, mtkMesh.submeshes.enumerated()).map {(mdlSub, mtkSubEnumerated) in
            let (materialIndex, mtkSub) = mtkSubEnumerated
            return Submesh(mdlSubmesh: mdlSub, mtkSubmesh: mtkSub, materialIndex: materialIndex)
        }
        
        let materials = mdlSubmeshes.compactMap {$0.material?.extractMaterial()}
        
        self.init(
            vertexBuffers: vertexBuffers,
            vertexDescriptor: mdlMesh.vertexDescriptor,
            vertexCount: mtkMesh.vertexCount,
            submeshes: submeshes,
            materials: materials)
    }
    
    func drawCalls() -> [DrawCall] {
        [DrawCall(mesh: self,
            modelMatrix: simd_float4x4(affineTransform))]
    }
    
    func resources() -> [any MTLResource] {
        vertexBuffers + submeshes.flatMap { submesh in [submesh.indexBuffer] }
        + materials.flatMap {$0.resources()}
    }
}












