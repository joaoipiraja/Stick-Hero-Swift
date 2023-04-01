
import Foundation
import SpriteKit


struct Character{
    
    class Hero: SKSpriteNode{
        
        
        struct Action{
            static var walk:SKAction = {
                var textures:[SKTexture] = []
                for i in 0...1 {
                    let texture = SKTexture(imageNamed: "human\(i + 1).png")
                    textures.append(texture)
                }
                
                let action = SKAction.animate(with: textures, timePerFrame: 1/4, resize: true, restore: true)
                
                return SKAction.repeatForever(action)
            }()
            
        }
        
        
        private var view: StickHeroGameScene
        
        
        init(view: StickHeroGameScene){
            
            self.view = view
            let texture = SKTexture(imageNamed: "human1")
            super.init(texture: texture, color: .white, size: texture.size())
            self.load()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
       
        private func load() {
            self.name = StickHeroGameSceneChildName.HeroName.rawValue
            
            
            let x:CGFloat = view.nextLeftStartX - Constants.DefinedScreenWidth / 2 - self.size.width / 2 - Constants.GAP.X
            let y:CGFloat = Constants.StackHeight + self.size.height / 2 - Constants.DefinedScreenHeight / 2 - Constants.GAP.Y
            self.position = CGPoint(x: x, y: y)
            self.zPosition = StickHeroGameSceneZposition.heroZposition.rawValue
            self.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 16, height: 18))
            self.physicsBody?.affectedByGravity = false
            self.physicsBody?.allowsRotation = false
            
            view.addChild(self)
        }
    
        func scaleY(){
            self.removeAction(forKey: StickHeroGameSceneActionKey.HeroScaleAction.rawValue)
            self.run(SKAction.scaleY(to: 1, duration: 0.04))
        }
        
        
        func scale(){
            let scaleAction = SKAction.sequence([SKAction.scaleY(to: 0.9, duration: 0.05), SKAction.scaleY(to: 1, duration: 0.05)])
            self.run(SKAction.repeatForever(scaleAction), withKey: StickHeroGameSceneActionKey.HeroScaleAction.rawValue)
        }
        
        func move(){
            let action = SKAction.move(by: CGVector(dx: -view.nextLeftStartX + (view.rightStack?.frame.size.width)! + view.playAbleRect.origin.x - 2, dy: 0), duration: 0.3)
            self.run(action)
        }
        
        func go(pass:Bool) {
            
            
            guard pass else {
                
                let stick = view.childNode(withName: StickHeroGameSceneChildName.StickName.rawValue) as! SKSpriteNode

                let dis:CGFloat = stick.position.x + view.stickHeight
                let overGap = Constants.DefinedScreenWidth / 2 - abs(self.position.x)
                let disGap = view.nextLeftStartX - overGap - (view.rightStack?.frame.size.width)!  / 2
                let move = SKAction.moveTo(x: dis, duration: TimeInterval(abs(disGap / Constants.HeroSpeed)))
                
                self.run(Action.walk, withKey: StickHeroGameSceneActionKey.WalkAction.rawValue)
                
                self.run(move, completion: {[unowned self] () -> Void in
                    stick.run(SKAction.rotate(toAngle: CGFloat(-Double.pi), duration: 0.4))
                    self.physicsBody!.affectedByGravity = true
                    self.run(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.DeadAudioName.rawValue, waitForCompletion: false))
                    self.removeAction(forKey: StickHeroGameSceneActionKey.WalkAction.rawValue)
                    self.run(SKAction.wait(forDuration: 0.5), completion: {[unowned self] () -> Void in
                        view.gameOver = true
                    })
                })
                
                return
            }
            
                let dis:CGFloat = view.nextLeftStartX - Constants.DefinedScreenWidth / 2 - self.size.width / 2 - Constants.GAP.X
                  
                let overGap = Constants.DefinedScreenWidth / 2 - abs(self.position.x)
                let disGap = view.nextLeftStartX - overGap - (view.rightStack?.frame.size.width)! / 2
                  
                let move = SKAction.moveTo(x: dis, duration: TimeInterval(abs(disGap / Constants.HeroSpeed)))
           
                self.run(Action.walk, withKey: StickHeroGameSceneActionKey.WalkAction.rawValue)
                  self.run(move, completion: { [unowned self]() -> Void in
                      view.score += 1
                      
                    self.run(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.VictoryAudioName.rawValue, waitForCompletion: false))
                      self.removeAction(forKey: StickHeroGameSceneActionKey.WalkAction.rawValue)
                      view.moveStackAndCreateNew()
                  })
        }
        
    }
}
