import MetalKit


enum DynamicScope {
    case perFrame
    case perInstance(kMaxDrawsPerFrame: Int)
}

class DynamicBuffer<T> {
    let buffer: MTLBuffer
    let scope: DynamicScope
    let alignedSize: Int
    private var nextOffset: Int = 0
    
    struct Slice {
        var frameIndex: Int
        var instanceIndex: Int = 0
    }
    
    init?(maxBuffersInFlight: Int, scope: DynamicScope) {
        self.alignedSize = Self.alignedSize(T.self)
        self.scope = scope
        let bufferSize = switch scope {
            case .perFrame: self.alignedSize * maxBuffersInFlight
            case .perInstance(let maxDraws): self.alignedSize * maxBuffersInFlight * maxDraws
        }
        guard let buffer = Renderer.device.makeBuffer(
            length: bufferSize,
            options: [MTLResourceOptions.storageModeShared]) else {
            return nil
        }
        self.buffer = buffer
    }
    
    func gpuAddressAt(slice: Slice) -> UInt64 {
        let offset = switch scope {
            case .perFrame: alignedSize * slice.frameIndex
            case .perInstance(let maxDraws):
                alignedSize * (slice.frameIndex * maxDraws + slice.instanceIndex)
        }
        return buffer.gpuAddress + UInt64(offset)
    }
    
    func bindAt(slice: Slice) -> UnsafeMutablePointer<T> {
        let offset = switch scope {
            case .perFrame: alignedSize * slice.frameIndex
            case .perInstance(let maxDraws):
                alignedSize * (slice.frameIndex * maxDraws + slice.instanceIndex)
        }
        let unsafePointer = buffer.contents().advanced(by: offset).bindMemory(to: T.self, capacity: 1)
        return unsafePointer
    }
    
    @inline(__always)
    static func alignedSize(_ type: T.Type, alignment: Int = 256) -> Int {
        let size = MemoryLayout<T>.stride
        return (size + alignment - 1) & ~(alignment - 1)
    }
    
    
}
