import MetalKit

enum DynamicScope {
    case perFrame
    case perInstance(kMaxDrawsPerFrame: Int)
}

final class DynamicBuffer<T> {
    private var backings: [StaticBuffer<T>] = []
    
    var buffers: [MTLBuffer] {
        backings.map(\.buffer)
    }
    
    let scope: DynamicScope
    let count: Int
    let alignment: Int

    struct Slice {
        var frameIndex: Int
        var instanceIndex: Int = 0
    }
    
    init?(maxBuffersInFlight: Int,
          scope: DynamicScope,
          count: Int,
          alignment: Int = 256,
          options: MTLResourceOptions = [.storageModeShared])
    {
        self.count = count
        
        let allocCount = switch scope {
            case .perFrame: count
            case .perInstance(let maxDraws): count * maxDraws
        }
        
        backings = (0..<maxBuffersInFlight).map {_ in
            StaticBuffer(
                count: allocCount,
                alignment: alignment,
                options: options
            )
        }
 
        self.alignment = alignment
        self.scope = scope
    }
    
    
    func gpuAddressAt(slice: Slice, offsetIndex: Int) -> UInt64 {
        let adjustedIndex = slice.instanceIndex * count + offsetIndex
        return backings[slice.frameIndex].gpuAddressAt(offsetIndex: adjustedIndex)
    }
    
    func bindAt(slice: Slice, offsetIndex: Int) -> UnsafeMutablePointer<T> {
        let adjustedIndex = slice.instanceIndex * count + offsetIndex
        return backings[slice.frameIndex].bindAt(offsetIndex: adjustedIndex)
    }
}
