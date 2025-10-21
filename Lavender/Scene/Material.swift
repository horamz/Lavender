import MetalKit

class Material {

    struct Parameter<Factor> {
        var factor: Factor
        var texture: MTLTexture? = nil
        var uvSet: UInt8 = 0
        var isSRGB: Bool = true
    }
    
    typealias ParameterFloat = Parameter<Float>
    typealias ParameterFloat3 = Parameter<SIMD3<Float>>

    var baseColor: ParameterFloat3 = .init(factor: ([0, 0, 0]))
    var roughness: ParameterFloat = .init(factor: 1.0)
    var metalness: ParameterFloat = .init(factor: 0.0)
    var normal: ParameterFloat = .init(factor: 1.0)
    var occlusion: ParameterFloat = .init(factor: 1.0)
    var opacity: ParameterFloat = .init(factor: 0)
    var emissive: ParameterFloat3 = .init(factor: [0, 0, 0])
    
    var bufferView: ImmutableBufferView<MaterialArguments>?
    
    
    init() {}
    init(baseColor: ParameterFloat3) { self.baseColor = baseColor }
    
}

extension Material: Resident {
    private static let textureAccessors: [(Material) -> MTLTexture?] = [
        { $0.baseColor.texture },
        { $0.normal.texture    },
        { $0.roughness.texture },
        { $0.metalness.texture },
        { $0.occlusion.texture },
        { $0.opacity.texture   },
        { $0.emissive.texture  }
    ]

    func resources() -> [any MTLResource] {
        Self.textureAccessors.compactMap { $0(self) }
    }
}



extension Material {
    func asShaderArguments() -> MaterialArguments {
        var materialFactors = MaterialFactors()
        materialFactors.baseColorFactor = simd_float4(self.baseColor.factor, 1.0)
        materialFactors.roughnessFactor = self.roughness.factor
        materialFactors.metallicFactor = self.metalness.factor
        materialFactors.normalScale = self.normal.factor
        materialFactors.occlusionStrength = self.occlusion.factor
        materialFactors.emissiveFactor = self.emissive.factor
        
        let noResource = MTLResourceID()
        var materialArguments = MaterialArguments()
        
        materialArguments.factors = materialFactors
        materialArguments.baseColorTexture = self.baseColor.texture?.gpuResourceID ?? noResource
        materialArguments.roughnessTexture = self.roughness.texture?.gpuResourceID ?? noResource
        materialArguments.metalnessTexture = self.metalness.texture?.gpuResourceID ?? noResource
        materialArguments.normalTexture = self.normal.texture?.gpuResourceID ?? noResource
        materialArguments.occlusionTexture = self.occlusion.texture?.gpuResourceID ?? noResource
        materialArguments.emissiveTexture = self.emissive.texture?.gpuResourceID ?? noResource
        materialArguments.opacityTexture = self.opacity.texture?.gpuResourceID ?? noResource
        
    
        return materialArguments
    }
}

