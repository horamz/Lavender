import MetalKit

class AssetLoader {
    enum TextureSemantic {
        case raw, color
    }
    static let dataTextureOptions: [MTKTextureLoader.Option : Any] = [
        .SRGB : NSNumber(value: false),
        .origin : MTKTextureLoader.Origin.bottomLeft,
        .generateMipmaps : NSNumber(value: true),
        .textureStorageMode : NSNumber(value: MTLStorageMode.private.rawValue)
    ]
    static let colorTextureOptions: [MTKTextureLoader.Option : Any] = [
        .SRGB : NSNumber(value: true),
        .origin : MTKTextureLoader.Origin.bottomLeft,
        .generateMipmaps : NSNumber(value: true),
        .textureStorageMode : NSNumber(value: MTLStorageMode.private.rawValue)
    ]
    
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
    
    static func loadTexture(
        texture: MDLTexture,
        semantic: TextureSemantic,
        name: String) -> MTLTexture?
    {
        if let texture = textureAssets[name] {
            return texture
        }
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        var texture = try? textureLoader.newTexture(
            texture: texture,
            options: semantic == .raw ? dataTextureOptions : colorTextureOptions)
        
        /*
        if semantic == .color && texture?.pixelFormat != .rgba8Unorm_srgb {
            texture = texture?.makeTextureView(pixelFormat: .rgba8Unorm_srgb)!
        }
         */
        textureAssets[name] = texture
        print("Loaded Texture: \(name)")
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
        let material = Material()
        
        material.baseColor.texture = extractMaterialTexture(type: .baseColor)
        if let baseColorFactor = extractMaterialFactorFloat3(type: .baseColor) {
            material.baseColor.factor = baseColorFactor
        }
        
        material.roughness.texture = extractMaterialTexture(type: .roughness)
        if let roughnessFactor = extractMaterialFactorFloat(type: .roughness) {
            material.roughness.factor = roughnessFactor
        }
        
        material.metalness.texture = extractMaterialTexture(type: .metallic)
        if let metallicFactor = extractMaterialFactorFloat(type: .metallic) {
            material.metalness.factor = metallicFactor
        }
        
        material.normal.texture = extractMaterialTexture(type: .tangentSpaceNormal)
        
        material.emissive.texture = extractMaterialTexture(type: .emission)
        if let emissiveFactor = extractMaterialFactorFloat3(type: .emission) {
            material.emissive.factor = emissiveFactor
        }
        
        material.occlusion.texture = extractMaterialTexture(type: .ambientOcclusion)
        if let aoScaleFactor = extractMaterialFactorFloat(type: .ambientOcclusionScale) {
            material.occlusion.factor = aoScaleFactor
        }
        
        material.opacity.texture = extractMaterialTexture(type: .opacity)
        
        return material
    }
    
    private func extractMaterialTexture(type semantic: MDLMaterialSemantic) -> MTLTexture? {
        if let property = property(with: semantic),
           property.type == .texture,
           let mdlTexture = property.textureSamplerValue?.texture {
            let defaultName = self.name + UUID().uuidString
            return AssetLoader.loadTexture(
                texture: mdlTexture,
                semantic:
                    (semantic == .baseColor ||
                     semantic == .emission) ?
                    .color : .raw,
                name: defaultName)
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
           factor.type == .float3 {
            return factor.float3Value
        }
        return nil
    }
}

