import MetalKit
import Spatial

class Renderer: NSObject {
    static var device: MTLDevice!
    static var library: MTLLibrary!
    
    static let kMaxFramesInFlight = 3
    
    let commandQueue: MTL4CommandQueue
    let commandAllocators: [MTL4CommandAllocator]
    let commandBuffer: MTL4CommandBuffer
    
    let pipelineState: MTLRenderPipelineState
    let depthStencilState: MTLDepthStencilState
    
    let vertexArgumentTable: MTL4ArgumentTable
    let fragmentArgumentTable: MTL4ArgumentTable
    
    let residencySet: MTLResidencySet
    let sharedEvent: MTLSharedEvent
    
    var frameNumber: UInt64 = 0
    
    var frameConstantsBuffer: DynamicBuffer<FrameConstants>
    var instanceConstantsBuffer: DynamicBuffer<InstanceConstants>
    
    var materialsBuffer: StaticBuffer<MaterialArguments>
    
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
        self.depthStencilState = Self.createDepthStencilState()!
        
        self.vertexArgumentTable = Self.createArgumentTable()
        self.fragmentArgumentTable = Self.createArgumentTable()
        
        self.residencySet = Self.createResidencySet()
        
        self.commandAllocators = Self.createCommandAllocators()
        self.sharedEvent = Self.createSharedEvent(signaledValue: frameNumber)
        
        self.frameConstantsBuffer = DynamicBuffer(maxBuffersInFlight: Self.kMaxFramesInFlight, scope: .perFrame, count: 1)!
        
        // TODO: Make per instance buffer resizable based on draw calls
        self.instanceConstantsBuffer = DynamicBuffer(
            maxBuffersInFlight: Self.kMaxFramesInFlight,
            scope:.perInstance(kMaxDrawsPerFrame: 128 * 1_024),
            count: 1)!
        
        self.materialsBuffer = StaticBuffer(count: 128)
        
        super.init()
        
        configureResidencySet(view: metalView)
        
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
        renderPipelineDescriptor.vertexDescriptor = .forwardPassDescriptor
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
    
    static func createDepthStencilState() -> MTLDepthStencilState? {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilDescriptor.depthCompareFunction = .less
        return Renderer.device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
    static func createArgumentTable() -> MTL4ArgumentTable {
        // TODO: This is ughhhhhhhh so unclean
        let argumentTableDescriptor = MTL4ArgumentTableDescriptor()
        argumentTableDescriptor.maxBufferBindCount = max(VertexBindPointCount.index, FragmentBindPointCount.index)
        argumentTableDescriptor.maxTextureBindCount = 10
        
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
        
        residencySet.addAllocations(frameConstantsBuffer.buffers)
        residencySet.addAllocations(instanceConstantsBuffer.buffers)
        residencySet.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
    
    func draw(
        scene: LScene,
        camera: Camera,
        in view: MTKView)
    {
        guard let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentMTL4RenderPassDescriptor else {
            return
        }

        frameNumber &+= 1
        
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
        renderEncoder.setDepthStencilState(depthStencilState)
    
        renderEncoder.setArgumentTable(vertexArgumentTable, stages: .vertex)
        renderEncoder.setArgumentTable(fragmentArgumentTable, stages: .fragment)
        renderEncoder.setTriangleFillMode(.fill)
        

        let frameConstantsPtr = frameConstantsBuffer.bindAt(slice: .init(frameIndex: frameIndex), offsetIndex: 0)
      
        frameConstantsPtr.pointee.viewMatrix = camera.viewMatrix
        frameConstantsPtr.pointee.projectionMatrix = camera.projectionMatrix
        
        vertexArgumentTable.setAddress(
            frameConstantsBuffer.gpuAddressAt(slice: .init(frameIndex: frameIndex), offsetIndex: 0),
            index: FrameConstantsBuffer.index)
        
        let drawCalls = scene.renderableEntities.flatMap {$0.drawCalls()}
        
        for (instanceIndex, drawCall) in drawCalls.enumerated() {
            
            let instanceConstantsPtr = instanceConstantsBuffer.bindAt(
                slice: .init(frameIndex: frameIndex, instanceIndex: instanceIndex), offsetIndex: 0)
            
            instanceConstantsPtr.pointee.modelMatrix = drawCall.modelMatrix
            
            vertexArgumentTable.setAddress(
                instanceConstantsBuffer.gpuAddressAt(slice: .init(frameIndex: frameIndex, instanceIndex: instanceIndex), offsetIndex: 0), index: InstanceConstantsBuffer.index)
            
            for (bufferIndex, vertexBuffer) in drawCall.mesh.vertexBuffers.enumerated() {
                vertexArgumentTable.setAddress(vertexBuffer.gpuAddress, index: bufferIndex)
            }
            
   
            for submesh in drawCall.mesh.submeshes {
                
                if let materialView = drawCall.mesh
                    .materials[submesh.materialIndex].bufferView {
                    fragmentArgumentTable.setAddress(
                        materialView.gpuAddress,
                        index: MaterialBuffer.index)
                }
                
                renderEncoder.drawIndexedPrimitives(
                    primitiveType: .triangle,
                    indexCount: submesh.indexCount,
                    indexType: submesh.indexType,
                    indexBuffer: submesh.indexBuffer.gpuAddress,
                    indexBufferLength: submesh.indexBuffer.length)
            }
            
        }
        
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
