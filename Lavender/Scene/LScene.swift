import MetalKit
import Spatial

class LScene {
    private(set) var renderableEntities: [any Renderable] = []
    
    var resources: [any MTLAllocation] {
        renderableEntities.flatMap {$0.resources()}
    }
    
 
    init(renderables: [any Renderable], renderer: Renderer) {
        self.renderableEntities = renderables
        makeResourcesResident(
            residencySet: renderer.residencySet,
            materialsBuffer: renderer.materialsBuffer)
    }
    
    func makeResourcesResident(
        residencySet: MTLResidencySet,
        materialsBuffer: StaticBuffer<MaterialArguments>)
    {
        residencySet.addAllocations(resources)
        
        renderableEntities
            .flatMap {$0.drawCalls()}
            .map(\.mesh)
            .flatMap(\.materials)
            .enumerated()
            .forEach {(matIndex, material) in
                let materialArgs = material.asShaderArguments()
                material.bufferView = materialsBuffer.write(materialArgs, at: matIndex)
            }
        residencySet.addAllocation(materialsBuffer.buffer)
        residencySet.commit()
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

protocol Resident {
    func resources() -> [any MTLResource]
}

protocol Renderable: Resident {
    func drawCalls() -> [DrawCall]
    
}
