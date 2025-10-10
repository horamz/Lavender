import MetalKit

class AssetLoader {
    static var textureAssets: [String: MTLTexture] = [:]
    
    static func loadModel(url: URL, device: MTLDevice) throws -> Model {
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: url, vertexDescriptor: .forwardPassDescriptor, bufferAllocator: bufferAllocator)
        asset.loadTextures()
        
        let (mdlMeshes, mtkMeshes) = try! MTKMesh.newMeshes(
            asset: asset,
            device: device)
        
        let meshes = zip(mdlMeshes, mtkMeshes).map {mdlMesh, mtkMesh in
            Mesh(mdlMesh: mdlMesh, mtkMesh: mtkMesh)
        }
        
        return Model(meshes: meshes)
    }
    
    static func loadTexture(texture: MDLTexture, name: String) -> MTLTexture? {
      if let texture = textureAssets[name] {
        return texture
      }
      let textureLoader = MTKTextureLoader(device: Renderer.device)
      let textureLoaderOptions: [MTKTextureLoader.Option: Any] =
        [.origin: MTKTextureLoader.Origin.bottomLeft,
         .generateMipmaps: true]
      let texture = try? textureLoader.newTexture(
        texture: texture,
        options: textureLoaderOptions)
      textureAssets[name] = texture
      return texture
    }

    static func loadTexture(sourceName: String) -> MTLTexture? {
      if let texture = textureAssets[sourceName] {
        return texture
      }
      let textureLoader = MTKTextureLoader(device: Renderer.device)
      let texture: MTLTexture?
      texture = try? textureLoader.newTexture(
        name: sourceName,
        scaleFactor: 1.0,
        bundle: Bundle.main,
        options: nil)
      if texture != nil {
        print("Loaded texture: \(sourceName)")
        textureAssets[sourceName] = texture
      }
      return texture
    }
}

extension MDLMaterial {
    func extractMaterial() -> Material {
        var material = Material()
        
        if let baseColorTexture = extractMaterialTexture(type: .baseColor) {
            material.baseColor = .texture(baseColorTexture)
        } else if let baseColorFactor = extractMaterialFactorFloat3(type: .baseColor) {
            material.baseColor = .factor(baseColorFactor)
        }
        
        return material
    }
    
    private func extractMaterialTexture(type semantic: MDLMaterialSemantic) -> MTLTexture? {
        if let property = property(with: semantic),
           property.type == .texture,
           let mdlTexture = property.textureSamplerValue?.texture {
                let defaultName = "Material Texture " + UUID().uuidString.prefix(8)
                return AssetLoader.loadTexture(
                    texture: mdlTexture,
                    name: property.stringValue ?? defaultName)
        }
        return nil
    }
    
    private func extractMaterialFactorFloat(type semantic: MDLMaterialSemantic) -> Float? {
        if let factor = property(with: semantic),
           factor.type == .float {
            return factor.floatValue
        }
        return nil
    }
    
    private func extractMaterialFactorFloat3(type semantic: MDLMaterialSemantic) -> SIMD3<Float>? {
        if let factor = property(with: semantic),
           factor.type == .float {
            return factor.float3Value
        }
        return nil
    }
}

