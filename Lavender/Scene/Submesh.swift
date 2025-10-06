import MetalKit

struct Submesh {
    let indexCount: Int
    let indexBuffer: MTLBuffer
    let indexType: MTLIndexType
    let primitiveType: MTLPrimitiveType
    
    let material: Material?
    
    init(indexCount: Int,
         indexBuffer: MTLBuffer,
         indexType: MTLIndexType,
         primitiveType: MTLPrimitiveType)
    {
        self.indexCount = indexCount
        self.indexBuffer = indexBuffer
        self.indexType = indexType
        self.primitiveType = primitiveType
        self.material = nil
    }
    
    init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh) {
        self.indexBuffer = mtkSubmesh.indexBuffer.buffer
        self.indexCount = mtkSubmesh.indexCount
        self.indexType = mtkSubmesh.indexType
        self.primitiveType = mtkSubmesh.primitiveType
        self.material = mdlSubmesh.material?.extractMaterial()
    }
}
