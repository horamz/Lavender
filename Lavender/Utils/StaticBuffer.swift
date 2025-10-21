import Metal

struct ImmutableBufferView<T> {
    let buffer: StaticBuffer<T>
    let offsetIndex: Int
    
    var gpuAddress: UInt64 {
        buffer.gpuAddressAt(offsetIndex: offsetIndex)
    }
}


struct StridedMutableBufferView<T> {
    private let viewPtr: (Int) -> UnsafeMutablePointer<T>
    
    init(viewPtr: @escaping (Int) -> UnsafeMutablePointer<T>) {
        self.viewPtr = viewPtr
    }
    
    subscript(position: Int) -> UnsafeMutablePointer<T> {
        viewPtr(position)
    }
}


final class StaticBuffer<T> {
    let buffer: MTLBuffer
    let options: MTLResourceOptions
    let count: Int
    
    /// Alignment for each element start (power of two, typically 256 for argument tables / bindless schemes)
    let alignment: Int
    
    /// The final, per-element stride after alignment (>= MemoryLayout<T>.stride, aligned up to `alignment`)
    let alignedStride: Int
    
    /// Optional base byte offset (handy for per-frame ring-buffering)
    let baseOffset: Int
    
    /// Create a strided buffer of `count` elements.
    /// - Parameters:
    ///   - alignment: element-start alignment (power of two). Defaults to 256.
    ///   - elementStrideOverride: if your encoded element size differs from `MemoryLayout<T>.stride`
    ///     (e.g., `alignUp(argumentEncoder.encodedLength, argumentEncoder.alignment)`), pass it here.
    ///   - baseOffset: extra offset added to all computed element offsets (e.g., per-frame region).
    init(
        count: Int,
        alignment: Int = 256,
        elementStrideOverride: Int? = nil,
        baseOffset: Int = 0,
        options: MTLResourceOptions = [.storageModeShared]
    ) {
        precondition(alignment > 0 && (alignment & (alignment - 1)) == 0, "Alignment must be a power of two.")
        
        self.count = count
        self.alignment = alignment
        self.options = options
        self.baseOffset = baseOffset
        
        // Choose the raw stride, then align it up once and reuse as a CONSTANT stride.
        let rawStride = elementStrideOverride ?? MemoryLayout<T>.stride
        self.alignedStride = StaticBuffer.alignUp(rawStride, to: alignment)
        
        // Allocate total length as N * alignedStride, aligned up (nice-to-have).
        let totalBytes = StaticBuffer.alignUp(alignedStride * max(count, 1), to: alignment)
        
        guard let mtlBuffer = Renderer.device.makeBuffer(length: totalBytes + baseOffset, options: options) else {
            fatalError("Failed to create StaticBuffer (bytes=\(totalBytes + baseOffset))")
        }
        self.buffer = mtlBuffer
    }
    
    // MARK: - Offsets & addresses
    
    @inline(__always)
    func byteOffset(for index: Int) -> Int {
        precondition(index >= 0 && index < count, "Index out of range")
        return baseOffset + index * alignedStride
    }
    
    @inline(__always)
    func gpuAddressAt(offsetIndex: Int) -> UInt64 {
        UInt64(byteOffset(for: offsetIndex)) &+ buffer.gpuAddress
    }
    
    // MARK: - CPU writes
    
    /// Unsafe mutable pointer to the T at `index`.
    func bindAt(offsetIndex: Int) -> UnsafeMutablePointer<T> {
        precondition(!options.contains(.storageModePrivate), "Cannot map .private buffer")
        let ptr = buffer.contents().advanced(by: byteOffset(for: offsetIndex))
        return ptr.assumingMemoryBound(to: T.self)
    }
    
    /// Convenience write.
    func write(_ value: T, at offsetIndex: Int) -> ImmutableBufferView<T> {
        bindAt(offsetIndex: offsetIndex).pointee = value
        return ImmutableBufferView(buffer: self, offsetIndex: offsetIndex)
    }
    
    func withStridedMutableView<R>(
        _ body: (StridedMutableBufferView<T>) throws -> R)
    rethrows -> R {
        precondition(!options.contains(.storageModePrivate))
        let view = StridedMutableBufferView<T>(viewPtr: {self.bindAt(offsetIndex: $0)})
        return try body(view)
    }
    
    @inline(__always)
    static func alignUp(_ size: Int, to alignment: Int) -> Int {
        (size + alignment - 1) & ~(alignment - 1)
    }
}

