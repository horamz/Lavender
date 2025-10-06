import MetalKit

struct Material {
    
    enum Parameter<Factor> {
        case texture(MTLTexture)
        case factor(Factor)

        var textureValue: MTLTexture? {
            if case let .texture(mtlTexture) = self {
                return mtlTexture
            } else {
                return nil
            }
        }
    }
    
    
    typealias ParameterFloat = Parameter<Float>
    typealias ParameterFloat3 = Parameter<SIMD3<Float>>

    var baseColor: ParameterFloat3 = .factor([0, 0, 0])
}
