import MetalKit
import Spatial
class Renderer: NSObject, MTKViewDelegate {
    static var device: MTLDevice!
    static var library: MTLLibrary!
    
    static let kMaxFramesInFlight = 3
    

    var scene = LScene()

    
    let commandQueue: MTL4CommandQueue
    let commandAllocators: [MTL4CommandAllocator]
    let commandBuffer: MTL4CommandBuffer
    
    let pipelineState: MTLRenderPipelineState
    
    let vertexArgumentTable: MTL4ArgumentTable
    let fragmentArgumentTable: MTL4ArgumentTable
    
    let residencySet: MTLResidencySet
    let sharedEvent: MTLSharedEvent
    
    var frameNumber: UInt64 = 0
    var lastTime: Double = CFAbsoluteTimeGetCurrent()
        
    var camera = {
        var cam = FPCamera()
        cam.origin = .init(x: 0, y: 0, z: 3)
        return cam
    }()
    
    var uniformsBuffer: DynamicBuffer<Uniforms>
    
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
        
        self.vertexArgumentTable = Self.createArgumentTable()
        self.fragmentArgumentTable = Self.createArgumentTable()
        
        self.residencySet = Self.createResidencySet()
        
        self.commandAllocators = Self.createCommandAllocators()
        self.sharedEvent = Self.createSharedEvent(signaledValue: frameNumber)
        
        self.uniformsBuffer = DynamicBuffer(maxBuffersInFlight: Self.kMaxFramesInFlight)!
        
        super.init()
        
        let mesh = Mesh(polytope: .icosahedron, vertexDescriptor: .forwardPassDescriptor)
        scene.addEntity(mesh)
        
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
    
    static func createArgumentTable() -> MTL4ArgumentTable {
        let argumentTableDescriptor = MTL4ArgumentTableDescriptor()
        argumentTableDescriptor.maxBufferBindCount = VertexBindPointCount.index
        argumentTableDescriptor.maxTextureBindCount = TextureBindPointCount.index
        
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
        
        residencySet.addAllocations(scene.resources)
        residencySet.addAllocation(uniformsBuffer.buffer)
     
        residencySet.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        camera.processViewportResize(size: size)
    }
    
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
        
        let currentTime: Double = CFAbsoluteTimeGetCurrent()
        let deltaTime = currentTime - lastTime
        lastTime = currentTime
        
        camera.processMovement(
            movementDirections: InputHandler.Shared.extractMovement(),
            deltaTime: deltaTime)
 
        let mouseMovement = InputHandler.Shared.extractMouseMovement()
        camera.processMouseMovement(deltaX: mouseMovement.x, deltaY: mouseMovement.y)
        
        camera.processMouseScroll(deltaY: InputHandler.Shared.extractMouseScroll().y)
        renderEncoder.setArgumentTable(vertexArgumentTable, stages: .vertex)
        renderEncoder.setArgumentTable(fragmentArgumentTable, stages: .fragment)
        renderEncoder.setTriangleFillMode(.lines)
        

        let uniforms = uniformsBuffer.bindAt(offsetIndex: frameIndex)
        uniforms.pointee.viewMatrix = camera.viewMatrix
        uniforms.pointee.projectionMatrix = camera.projectionMatrix
        
        let drawCalls = scene.renderableEntities.flatMap {$0.drawCalls()}
        
        for drawCall in drawCalls {
            uniforms.pointee.modelMatrix = drawCall.modelMatrix
            
            vertexArgumentTable.setAddress(
                uniformsBuffer.gpuAddressBy(offsetIndex: frameIndex),
                index: UniformsBuffer.index)
            
            for (bufferIndex, vertexBuffer) in drawCall.mesh.vertexBuffers.enumerated() {
                vertexArgumentTable.setAddress(vertexBuffer.gpuAddress, index: bufferIndex)
            }
            
            for submesh in drawCall.mesh.submeshes {
                let material = submesh.material
                
                if case let .texture(baseColor) = material?.baseColor {
                    fragmentArgumentTable.setTexture(baseColor.gpuResourceID, index: BaseColor.index)
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
