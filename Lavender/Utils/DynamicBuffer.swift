import MetalKit

class DynamicBuffer<T> {
    let buffer: MTLBuffer
    let alignedSize: Int
    
    init?(maxBuffersInFlight: Int) {
        self.alignedSize = Self.alignedSize(T.self)
        let bufferSize = self.alignedSize * maxBuffersInFlight
        guard let buffer = Renderer.device.makeBuffer(
            length: bufferSize,
            options: [MTLResourceOptions.storageModeShared]) else {
            return nil
        }
        self.buffer = buffer
    }
    
    func gpuAddressBy(offsetIndex: Int) -> UInt64 {
        let offset = alignedSize * offsetIndex
        return buffer.gpuAddress + UInt64(offset)
    }
    
    func bindAt(offsetIndex: Int) -> UnsafeMutablePointer<T> {
        let offset = alignedSize * offsetIndex
        let unsafePointer = (buffer.contents() + offset).bindMemory(to: T.self, capacity: 1)
        return unsafePointer
    }
    
    static func alignedSize(_ type: T.Type, alignment: Int = 256) -> Int {
        let size = MemoryLayout<T>.stride
        return (size + alignment - 1) & ~(alignment - 1)
    }
    
    
}
