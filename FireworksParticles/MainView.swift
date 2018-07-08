import MetalKit

struct Particle{
    var color: float4
    var position: float2
    var velocity: float2
}

struct ModelConstants{
    var modelMatrix = matrix_identity_float4x4
}

class MainView: MTKView {
    var commandQueue: MTLCommandQueue!
    var clearPass: MTLComputePipelineState!
    var drawDotPass: MTLComputePipelineState!
    public static var ScreenSize: Float = 0
    
    var fireworks: [Firework] = []
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        self.device = MTLCreateSystemDefaultDevice()
        
        MainView.ScreenSize = Float(self.bounds.width * 2)
        
        self.colorPixelFormat = .bgra8Unorm
        
        fireworks.append(Firework(device: device!))
        
        self.framebufferOnly = false
        
        self.commandQueue = device?.makeCommandQueue()
        
        let library = device?.makeDefaultLibrary()
        let clearFunc = library?.makeFunction(name: "clear_pass_func")
        let drawDotFunc = library?.makeFunction(name: "draw_dots_func")
        do{
            clearPass = try device?.makeComputePipelineState(function: clearFunc!)
            drawDotPass = try device?.makeComputePipelineState(function: drawDotFunc!)
        }catch let error as NSError{
            print(error)
        }
    }
    
    override var acceptsFirstResponder: Bool { return true }
    
    
    
    override func keyUp(with event: NSEvent) {
        if(event.keyCode == 49){
            shouldResetAll = true
        }
    }
    
    var shouldResetAll: Bool = false
    
    var timeToAdd: Float = 5.0
    var currentTime: Float = 0.0
    override func draw(_ dirtyRect: NSRect) {
        if(shouldResetAll){
            fireworks = []
            shouldResetAll = false
        }
        
        guard let drawable = self.currentDrawable else { return }
        
        
        
        currentTime += 1 / Float(self.preferredFramesPerSecond)
        
        if(currentTime >= timeToAdd){
            fireworks.append(Firework(device: device!))
            currentTime = 0.0
        }
        let commandbuffer = commandQueue.makeCommandBuffer()
        let computeCommandEncoder = commandbuffer?.makeComputeCommandEncoder()
        
        computeCommandEncoder?.setComputePipelineState(clearPass)
        computeCommandEncoder?.setTexture(drawable.texture, index: 0)
        
        let w = clearPass.threadExecutionWidth
        let h = clearPass.maxTotalThreadsPerThreadgroup / w
        
        var threadsPerThreadGroup = MTLSize(width: w, height: h, depth: 1)
        var threadsPerGrid = MTLSize(width: drawable.texture.width, height: drawable.texture.height, depth: 1)
        computeCommandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        
        var fireworksToRemove: [Int] = []
        var index: Int = 0
        for firework in fireworks {
            let stemCount: Int = firework.stemParticles.count
            let explosionCount: Int = firework.explosionParticles.count
            
            if(firework.shouldDie){
                fireworksToRemove.append(index)
                
            }
            
            computeCommandEncoder?.setComputePipelineState(drawDotPass)
            
            firework.update(deltaTime: 1 / Float(self.preferredFramesPerSecond))
            
            firework.render(computeCommandEncoder: computeCommandEncoder!)
            
            var particleCount: Int = 0
            if(!firework.isExploded){
                particleCount = stemCount
                computeCommandEncoder?.setBuffer(firework.stemBuffer, offset: 0, index: 0)
            }else{
                particleCount = explosionCount
                computeCommandEncoder?.setBuffer(firework.explosionBuffer, offset: 0, index: 0)
            }
            
            threadsPerGrid = MTLSize(width: particleCount, height: 1, depth: 1)
            threadsPerThreadGroup = MTLSize(width: w, height: 1, depth: 1)
            computeCommandEncoder?.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
            
            index += 1
        }
        
        computeCommandEncoder?.endEncoding()
        commandbuffer?.present(drawable)
        commandbuffer?.commit()
        
        removeFireworks(indices: fireworksToRemove)
    }
    
    func removeFireworks(indices: [Int]){
        for i in indices {
            fireworks.remove(at: i)
        }
    }
    
    
}



