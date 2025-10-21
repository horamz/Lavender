import MetalKit

enum Polytope {
    case box, icosahedron, cone, plane
    
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
        case .plane:
            return MDLMesh(
                planeWithExtent: [1,1,1],
                segments: [30, 30],
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
    
    enum TextureType {
        case baseColor
    }
    
    func setTexture(name: String, type: TextureType, index: Int) {
    
        guard index >= 0 && index < submeshes.count else {
            fatalError("Supplied index \(index) out of submeshes count \(submeshes.count)")
        }
        
        if let texture = AssetLoader.loadTexture(sourceName: name) {
            switch type {
            case .baseColor:
                materials.append(Material(baseColor: .init(factor: [1, 1, 1], texture: texture)))
                submeshes[0].materialIndex = materials.count - 1
            }
        }
    }
}
