import MetalKit
import Spatial


class LScene {
    private(set) var renderableEntities: [any Renderable] = []
    
    var resources: [any MTLAllocation] {
        renderableEntities.flatMap {$0.resources()}
    }
    
    // quite ugly right now but enforces ResidencySet allocation
    init(renderables: [any Renderable], renderer: Renderer) {
        self.renderableEntities = renderables
        renderer.residencySet.addAllocations(resources)
        renderer.residencySet.commit()
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
