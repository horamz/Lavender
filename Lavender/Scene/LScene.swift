import MetalKit
import Spatial


class LScene {
    private(set) var resources = [any MTLResource]()
    private(set) var renderableEntities: [any Renderable] = []
    
    func addEntity(_ renderable: any Renderable) {
        renderableEntities.append(renderable)
        resources += renderable.resources()
    }
    
}

protocol Transformable {
    var affineTransform: AffineTransform3D {get set}
}

extension Transformable {
    var modelMatrix: simd_float4x4 {
        simd_float4x4(affineTransform)
    }
}

struct DrawCall {
    var mesh: Mesh
    var modelMatrix: simd_float4x4
}

protocol Renderable {
    func drawCalls() -> [DrawCall]
    func resources() -> [any MTLResource]
}
