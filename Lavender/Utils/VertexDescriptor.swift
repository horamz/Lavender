import MetalKit

extension MDLVertexDescriptor {
    static var forwardPassDescriptor: MDLVertexDescriptor {
        let vertexDescriptor = MDLVertexDescriptor()
        var offset = 0
        
        vertexDescriptor.attributes[Position.index] = MDLVertexAttribute(
            name: MDLVertexAttributePosition,
            format: .float3,
            offset: 0,
            bufferIndex: 0)
        offset += MemoryLayout<SIMD3<Float>>.stride
        
        
        vertexDescriptor.attributes[Normal.index] = MDLVertexAttribute(
            name: MDLVertexAttributeNormal,
            format: .float3,
            offset: offset,
            bufferIndex: 0
        )
        offset += MemoryLayout<SIMD3<Float>>.stride
        
        vertexDescriptor.attributes[UV.index] = MDLVertexAttribute(
            name: MDLVertexAttributeTextureCoordinate,
            format: .float2,
            offset: offset,
            bufferIndex: 0)
        offset += MemoryLayout<SIMD2<Float>>.stride
        
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
        
        return vertexDescriptor
    }
}

extension MTLVertexDescriptor {
    static var forwardPassDescriptor: MTLVertexDescriptor? {
        MTKMetalVertexDescriptorFromModelIO(.forwardPassDescriptor)
    }
}

