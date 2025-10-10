import MetalKit

class Engine: NSObject {
    var scene: LScene
    var renderer: Renderer
    var camera: ResponsiveCamera
    
    var fps: Double = 0
    var lastTime: Double = CFAbsoluteTimeGetCurrent()
    
    init(metalView: MTKView) {
        renderer = Renderer(metalView: metalView)
        
        let mesh = Mesh(polytope: .icosahedron, vertexDescriptor: .forwardPassDescriptor)
        scene = .init(renderables: [mesh], renderer: renderer)
     
        camera = PerspectiveResponsiveCamera()
        
        super.init()
        
        metalView.delegate = self
        fps = Double(metalView.preferredFramesPerSecond)
        mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
    }
}

extension Engine {
    private func updateCamera(deltaTime: Double) {
        camera.processMovement(
            movementDirections: InputHandler.Shared.extractMovement(),
            deltaTime: deltaTime)
 
        let mouseMovement = InputHandler.Shared.extractMouseMovement()
        camera.processMouseMovement(deltaX: mouseMovement.x, deltaY: mouseMovement.y)
        
        camera.processMouseScroll(deltaY: InputHandler.Shared.extractMouseScroll().y)
    }
}


extension Engine: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.mtkView(view, drawableSizeWillChange: size)
        camera.processViewportResize(size: size)
    }
    
    func draw(in view: MTKView) {
        let currentTime: Double = CFAbsoluteTimeGetCurrent()
        let deltaTime = currentTime - lastTime
        lastTime = currentTime
        
        updateCamera(deltaTime: deltaTime)
        renderer.draw(scene: scene, camera: camera, in: view)
    }
}
