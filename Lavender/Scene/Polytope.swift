import MetalKit

enum Polytope {
    case box, icosahedron, cone
    
    fileprivate func createMesh() -> MDLMesh {
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        switch self {
        case .box:
            return MDLMesh(
                boxWithExtent: [1,1,1],
                segments: [4,4,4],
                inwardNormals: false,
                geometryType: .triangles,
                allocator: allocator)
        case .icosahedron:
            return MDLMesh(
                icosahedronWithExtent: [1,1,1],
                inwardNormals: false,
                geometryType: .triangles,
                allocator: allocator)
        case .cone:
            return MDLMesh(
                coneWithExtent: [1,1,1],
                segments: [8,8],
                inwardNormals: false,
                cap: false,
                geometryType: .triangles,
                allocator: allocator)
        }
       
    }
}

extension Mesh {
    convenience init(polytope: Polytope, vertexDescriptor: MDLVertexDescriptor) {
        let mdlMesh = polytope.createMesh()
        mdlMesh.vertexDescriptor = vertexDescriptor
        let mtkMesh = try! MTKMesh(mesh: mdlMesh, device: Renderer.device)
        self.init(mdlMesh: mdlMesh, mtkMesh: mtkMesh)
    }
}
