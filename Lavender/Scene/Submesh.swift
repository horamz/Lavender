import MetalKit

struct Submesh {
    let indexCount: Int
    let indexBuffer: MTLBuffer
    let indexType: MTLIndexType
    let primitiveType: MTLPrimitiveType
    var materialIndex: Int
    
    init(indexCount: Int,
         indexBuffer: MTLBuffer,
         indexType: MTLIndexType,
         primitiveType: MTLPrimitiveType,
         materialIndex: Int)
    {
        self.indexCount = indexCount
        self.indexBuffer = indexBuffer
        self.indexType = indexType
        self.primitiveType = primitiveType
        self.materialIndex = materialIndex
    }
    
    init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh, materialIndex: Int) {
        self.indexBuffer = mtkSubmesh.indexBuffer.buffer
        self.indexCount = mtkSubmesh.indexCount
        self.indexType = mtkSubmesh.indexType
        self.primitiveType = mtkSubmesh.primitiveType
        self.materialIndex = materialIndex
    }
}
