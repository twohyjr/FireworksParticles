import MetalKit


struct FireworkConstants {
    var stemSize: Float = 10
    var stemColor = float3(1)
    var isExploded: Bool = false
    var particleCount: Int = 0
}

class Firework {
    var stemParticles: [Particle] = []
    var explosionParticles: [Particle] = []
    var fireworkConstants = FireworkConstants()
    
    var stemYVel: Float = 10
    var currentHeight: Float = 0
    var explosionHeight: Float = 700
    
    var isExploded: Bool = false
    var hasRemovedStem: Bool = false
    
    //Should die is calculated with this
    var currentLiveTime: Float = 0
    var totalLiveTime: Float = 10
    var shouldDie: Bool = false
    
    var explosionPosition: float2 = float2(0)
    
    var needsParticleUpdate: Bool = false
    
    var stemBuffer: MTLBuffer!
    var explosionBuffer: MTLBuffer!
    
    var xPos: Float = 0
    
    var device: MTLDevice!
    init(device: MTLDevice){
        self.device = device
        createStemParticle()
        createExplosionParticles()
    }
    
    func createStemParticle(){
        
        xPos = Float(MainView.ScreenSize / 2)
        
        let particle = Particle(color: float4(1),
                                position: float2(xPos, 1500),
                                velocity: float2(0,-stemYVel))
        stemParticles.append(particle)
        
        stemBuffer = device.makeBuffer(bytes: stemParticles,
                                       length: MemoryLayout<Particle>.stride * stemParticles.count,
                                       options: [])
    }
    
    //UNIVERSE
    //    velocity: float2(Float(cos(Float(i + place))),
    //    Float(sin(Float(i  - place))))
    
    func getRandom(_ lower: Float, _ upper: Float)->Float{
        return Float(arc4random_uniform(UInt32(upper - lower)) + UInt32(lower))
    }
    
    func getRandom(_ lower: Int, _ upper: Int)->Int{
        return Int(arc4random_uniform(UInt32(upper - lower)) + UInt32(lower))
    }
    
    func createExplosionParticles(){
        let speed: Float = getRandom(1, 4)
        var place: Float = getRandom(1, 6)
        let size: Int = getRandom(1000, 1000000)
        
        //How much distance between the circles
        let div: Int = getRandom(10, 10)
        
        let xRando: Float = getRandom(1, 10)
        let yRando: Float = getRandom(1, 10)
        
        for i in 0..<size {
            if(i % (size / div) == 0){
                place += 0.1
            }
            let red: Float = Float(arc4random_uniform(100)) / 100
            let green: Float = Float(arc4random_uniform(100)) / 100
            let blue: Float = Float(arc4random_uniform(100)) / 100
            let particle = Particle(color: float4(red, green, blue, 1),
                                    position: float2(xPos,
                                                     MainView.ScreenSize - explosionHeight - 500),
                                    velocity: float2(Float(cos(Float(i * Int(yRando))) * place) * speed,
                                                     Float(sin(Float(i * Int(xRando))) * place) * speed))
            explosionParticles.append(particle)
        }
        
        
        explosionBuffer = device.makeBuffer(bytes: explosionParticles,
                                            length: MemoryLayout<Particle>.stride * explosionParticles.count,
                                            options: [])
    }
    
    func update(deltaTime: Float){
        currentLiveTime += deltaTime
        shouldDie = currentLiveTime >= totalLiveTime
        if(isExploded){
            fireworkConstants.isExploded = true
            fireworkConstants.particleCount = explosionParticles.count
        }else{
            
            currentHeight += stemYVel
            isExploded = currentHeight >= explosionHeight
            
            fireworkConstants.particleCount = stemParticles.count
        }
        
    }
    
    func render(computeCommandEncoder: MTLComputeCommandEncoder){
        computeCommandEncoder.setBytes(&fireworkConstants, length: MemoryLayout<FireworkConstants>.stride, index: 1)
    }
    
}
