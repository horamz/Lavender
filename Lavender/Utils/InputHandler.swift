import GameController

class InputHandler {
    
    enum Settings {
        static var translationSpeed: Float { 2.0 }
        static var mouseSensitivity: Float { 0.008 }
        static var scrollSensitivity: Float { 0.12 }
    }
    
    static let Shared = InputHandler.init()
    typealias Point = SIMD2<Float>
    
    var leftMouseDown = false
    var mouseDelta: Point = .zero
    var mouseScroll: Point = .zero
    
    
    var keysPressed: Set<GCKeyCode> = []
    
    
    private init() {
        let notifCenter = NotificationCenter.default
        notifCenter.addObserver(
            forName: .GCKeyboardDidConnect,
            object: nil,
            queue: nil) {notification in
                let keyboard = notification.object as? GCKeyboard
                keyboard?.keyboardInput?.keyChangedHandler
                = {_, _, keyCode, isPressed in
                    if isPressed {
                        self.keysPressed.insert(keyCode)
                    } else {
                        self.keysPressed.remove(keyCode)
                    }
                }
            }
#if os(macOS)
        NSEvent.addLocalMonitorForEvents(
            matching: [.keyUp, .keyDown]) { _ in nil }
#endif
        notifCenter.addObserver(
            forName: .GCMouseDidConnect,
            object: nil,
            queue: nil) {notification in
                let mouse = notification.object as? GCMouse
                
                mouse?.mouseInput?.leftButton.pressedChangedHandler
                = {_, _, isPressed in
                    self.leftMouseDown = isPressed
                }
                
                mouse?.mouseInput?.mouseMovedHandler
                = { _, deltaX, deltaY in
                    self.mouseDelta = .init(deltaX, deltaY)
                }
                
                mouse?.mouseInput?.scroll.valueChangedHandler
                = { _, deltaX, deltaY in
                    self.mouseScroll = .init(deltaX, deltaY)
                }
            }
    }
    
    
    func extractMovement() -> [MovementDirection] {
        var dirX = 0
        var dirZ = 0
        
        if keysPressed.contains(.keyW) { dirZ += 1 }
        if keysPressed.contains(.keyS) { dirZ -= 1 }
        if keysPressed.contains(.keyD) { dirX += 1 }
        if keysPressed.contains(.keyA) { dirX -= 1 }
        
        var movementDirs: [MovementDirection] = []
        
        if dirX != 0 {
            movementDirs.append(dirX > 0 ? .right : .left)
        }
        if dirZ != 0 {
            movementDirs.append(dirZ > 0 ? .forward : .backward)
        }
        
        return movementDirs
    }
    
    func extractMouseMovement() -> Point {
        defer {
            self.mouseDelta = .zero
        }
        return self.mouseDelta
    }
    
    func extractMouseScroll() -> Point {
        defer {
            self.mouseScroll = .zero
        }
        return self.mouseScroll
    }
}
