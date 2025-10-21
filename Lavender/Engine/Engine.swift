import MetalKit
import Spatial

class Engine: NSObject {
    var scene: LScene
    var renderer: Renderer
    var camera: ResponsiveCamera
    
    var fps: Double = 0
    var lastTime: Double = CFAbsoluteTimeGetCurrent()
    
    init(metalView: MTKView) {
        renderer = Renderer(metalView: metalView)
      
        //let mesh = Mesh(polytope: .icosahedron, vertexDescriptor: .forwardPassDescriptor)
        
        
        let house = try! AssetLoader.loadModel(url: Bundle.main.url(forResource: "lowpoly-house", withExtension: "usdz")!, device: Renderer.device)
        let frank = try! AssetLoader.loadModel(url: Bundle.main.url(forResource: "Frank", withExtension: "usdz")!, device: Renderer.device)
        frank.affineTransform.scale(by: .init(vector: [0.05, 0.05, 0.05]))
        frank.affineTransform.translated(by: Vector3D.init(vector: simd_double3(x: 10, y: 0, z: 0)))
        
        /*
        let lobby = try! AssetLoader.loadModel(url: Bundle.main.url(forResource: "supermarket", withExtension: "usdz")!, device: Renderer.device)
        lobby.affineTransform.scale(by: .init(vector: [0.001, 0.001, 0.001]))
        */
        
        let sphere = try! AssetLoader.loadModel(url: Bundle.main.url(forResource: "final-sphere", withExtension: "usdz")!, device: Renderer.device)
        //sphere.affineTransform.scale(by: .init(vector: [2,1,1]))
        //sphere.affineTransform.translate(by: Vector3D.init(vector: [3,0,0]))
        
        scene = .init(renderables: [sphere], renderer: renderer)
     
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
