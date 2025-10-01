import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    static var device: MTLDevice!
    static var library: MTLLibrary!
    
    static let kMaxFramesInFlight = 3
    
    let commandQueue: MTL4CommandQueue
    let commandAllocators: [MTL4CommandAllocator]
    let commandBuffer: MTL4CommandBuffer
    
    let pipelineState: MTLRenderPipelineState
    
    let argumentTable: MTL4ArgumentTable
    let residencySet: MTLResidencySet
    let sharedEvent: MTLSharedEvent
    
    let triangleBuffer: MTLBuffer
    let colorBuffer: MTLBuffer
    
    var frameNumber: UInt64 = 0
    
    
    init(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("No GPU Found.")
        }
        
        Self.device = device
        metalView.device = device
        
        
        guard let commandQueue = device.makeMTL4CommandQueue(),
              let commandBuffer = device.makeCommandBuffer() else {
            fatalError("Failed to create Metal 4 CommandQueue/CommandBuffer.")
        }
        
        self.commandQueue = commandQueue
        self.commandBuffer = commandBuffer
        
        guard let lib = Renderer.device.makeDefaultLibrary() else {
            fatalError("Failed to create Metal Shader Library.")
        }
        Self.library = lib
        
        self.pipelineState = Self.createRenderPipelineState(withFormat: metalView.colorPixelFormat)
        
        self.triangleBuffer = Self.createVertexBuffer()
        self.colorBuffer = Self.createColorBuffer()
        
        self.argumentTable = Self.createArgumentTable()
        self.residencySet = Self.createResidencySet()
        
        self.commandAllocators = Self.createCommandAllocators()
        self.sharedEvent = Self.createSharedEvent(signaledValue: frameNumber)
        
        super.init()
        
        configureResidencySet(view: metalView)
        
        metalView.delegate = self
        metalView.clearColor =
        MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
    }
    
    static func createRenderPipelineState(withFormat pixelFormat: MTLPixelFormat) -> MTLRenderPipelineState {
        let compiler = try! device.makeCompiler(descriptor: MTL4CompilerDescriptor())
        
        let vertexFunctionDescriptor = MTL4LibraryFunctionDescriptor()
        vertexFunctionDescriptor.library = library
        vertexFunctionDescriptor.name = "vertex_main"
        
        let fragmentFunctionDescriptor = MTL4LibraryFunctionDescriptor()
        fragmentFunctionDescriptor.library = library
        fragmentFunctionDescriptor.name = "fragment_main"
        
        let renderPipelineDescriptor = MTL4RenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunctionDescriptor = vertexFunctionDescriptor
        renderPipelineDescriptor.fragmentFunctionDescriptor = fragmentFunctionDescriptor
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        
        do {
            let renderPipelineState = try compiler.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
            return renderPipelineState
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    static func createVertexBuffer() -> MTLBuffer {
        var vertices: [SIMD3<Float>] = [
            SIMD3<Float>(0, 0.5, 0),
            SIMD3<Float>(-0.5, -0.5, 0),
            SIMD3<Float>(0.5, -0.5, 0),
        ]
        let buffer = device.makeBuffer(
            bytes: &vertices,
            length: MemoryLayout<SIMD3<Float>>.stride * vertices.count,
            options: [])!
        return buffer
    }
    
    static func createColorBuffer() -> MTLBuffer {
        var colors: [SIMD3<Float>] = [
            SIMD3<Float>(1.0, 0.0, 0.0),
            SIMD3<Float>(0.0, 1.0, 0.0),
            SIMD3<Float>(0.0, 0.0, 1.0),
        ]
        let buffer = device.makeBuffer(
            bytes: &colors,
            length: MemoryLayout<SIMD3<Float>>.stride * colors.count,
            options: [])!
        return buffer
    }
    
    static func createArgumentTable() -> MTL4ArgumentTable {
        let argumentTableDescriptor = MTL4ArgumentTableDescriptor()
        argumentTableDescriptor.maxBufferBindCount = 2
        
        let argumentTable = try! device.makeArgumentTable(descriptor: argumentTableDescriptor)
        
        return argumentTable
    }
    
    static func createResidencySet() -> MTLResidencySet {
        let residencySetDescriptor = MTLResidencySetDescriptor()
        let residencySet = try! device.makeResidencySet(descriptor: residencySetDescriptor)
        
        return residencySet
    }
    
    static func createCommandAllocators() -> [MTL4CommandAllocator] {
        (0..<kMaxFramesInFlight).map {_ in
            device.makeCommandAllocator()!
        }
    }
    
    static func createSharedEvent(signaledValue: UInt64) -> MTLSharedEvent {
        let sharedEvent = device.makeSharedEvent()!
        sharedEvent.signaledValue = signaledValue
        return sharedEvent
    }
    
    func configureResidencySet(view: MTKView) {
        commandQueue.addResidencySet(residencySet)
        let viewResidency = (view.layer as? CAMetalLayer)?.residencySet
        commandQueue.addResidencySet(viewResidency!)
        
        residencySet.addAllocation(triangleBuffer)
        residencySet.addAllocation(colorBuffer)
        residencySet.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentMTL4RenderPassDescriptor else {
            return
        }

        frameNumber += 1
        
        if (frameNumber >= Renderer.kMaxFramesInFlight) {
            let previousValueToWaitFor = frameNumber - UInt64(Renderer.kMaxFramesInFlight)
            sharedEvent.wait(untilSignaledValue: previousValueToWaitFor, timeoutMS: 10)
        }
        
        let frameIndex = Int(frameNumber % UInt64(Renderer.kMaxFramesInFlight))
        let frameAllocator = commandAllocators[frameIndex]
        
        frameAllocator.reset()
        
        commandBuffer.beginCommandBuffer(allocator: frameAllocator)
        
        guard let renderEncoder =
                commandBuffer
            .makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            print("Unable to create render encoder from command buffer.")
            return
        }
        
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setArgumentTable(argumentTable, stages: .vertex)
        
        argumentTable.setAddress(triangleBuffer.gpuAddress, index: 0)
        argumentTable.setAddress(colorBuffer.gpuAddress, index: 1)
        
        
        renderEncoder.drawPrimitives(
            primitiveType: .triangle,
            vertexStart: 0,
            vertexCount: 3)
        
        renderEncoder.endEncoding()
        
        commandBuffer.endCommandBuffer()
        
        commandQueue.waitForDrawable(drawable)
        commandQueue.commit([commandBuffer])
        commandQueue.signalDrawable(drawable)
        drawable.present()
        
        let futureValueToWaitFor = frameNumber
        commandQueue.signalEvent(sharedEvent, value: futureValueToWaitFor)
    }
}
