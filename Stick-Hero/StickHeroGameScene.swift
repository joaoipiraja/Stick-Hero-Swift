//
//  StickHeroGameScene.swift
//  Stick-Hero
//
//  Created by 顾枫 on 15/6/19.
//  Copyright © 2015年 koofrank. All rights reserved.
//

import SpriteKit

class StickHeroGameScene: SKScene, SKPhysicsContactDelegate {
  
    var gameOver = false {
        willSet {
            if (newValue) {
                checkHighScoreAndStore()
                let gameOverLayer = childNode(withName: StickHeroGameSceneChildName.GameOverLayerName.rawValue) as SKNode?
                gameOverLayer?.run(SKAction.moveDistance(CGVector(dx: 0, dy: 100), fadeInWithDuration: 0.2))
            }
            
        }
    }
    
    let StackHeight:CGFloat = 400.0
    let StackMaxWidth:CGFloat = 300.0
    let StackMinWidth:CGFloat = 100.0
    let gravity:CGFloat = -100.0
    let StackGapMinWidth:Int = 80
    let HeroSpeed:CGFloat = 760
    
    let StoreScoreName = "com.stickHero.score"
 
    var isBegin = false
    var isEnd = false
    var leftStack:SKShapeNode?
    var rightStack:SKShapeNode?
    
    var nextLeftStartX:CGFloat = 0
    var stickHeight:CGFloat = 0
    
    var hero: Character.Hero?
    var stick: Object.Stick?
    
    var score:Int = 0 {
        willSet {
            let scoreBand = childNode(withName: StickHeroGameSceneChildName.ScoreName.rawValue) as? SKLabelNode
            scoreBand?.text = "\(newValue)"
            scoreBand?.run(SKAction.sequence([SKAction.scale(to: 1.5, duration: 0.1), SKAction.scale(to: 1, duration: 0.1)]))
            
            if (newValue == 1) {
                let tip = childNode(withName: StickHeroGameSceneChildName.TipName.rawValue) as? SKLabelNode
                tip?.run(SKAction.fadeAlpha(to: 0, duration: 0.4))
            }
        }
    }
    
    lazy var playAbleRect:CGRect = {
        let maxAspectRatio:CGFloat = 16.0/9.0 // iPhone 5"
        let maxAspectRatioWidth = self.size.height / maxAspectRatio
        let playableMargin = (self.size.width - maxAspectRatioWidth) / 2.0
        return CGRect(x: playableMargin, y: 0, width: maxAspectRatioWidth, height: self.size.height)
        }()
    

    //MARK: - override
    override init(size: CGSize) {
        super.init(size: size)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        physicsWorld.contactDelegate = self
    }

    override func didMove(to view: SKView) {
        start()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver else {
            let gameOverLayer = childNode(withName: StickHeroGameSceneChildName.GameOverLayerName.rawValue) as SKNode?

            let location = touches.first?.location(in: gameOverLayer!)
            let retry = gameOverLayer!.atPoint(location!)
            
        
            if (retry.name == StickHeroGameSceneChildName.RetryButtonName.rawValue) {
                retry.run(SKAction.sequence([SKAction.setTexture(SKTexture(imageNamed: "button_retry_down"), resize: false), SKAction.wait(forDuration: 0.3)]), completion: {[unowned self] () -> Void in
                    self.restart()
                })
            }
            return
        }
        
        if !isBegin && !isEnd {
            isBegin = true
            
            self.stick = .init(view: self)
            self.stick?.scale()
            self.hero?.scale()
            
            return
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isBegin && !isEnd {
            isEnd  = true

            self.hero?.scaleY()
            self.stick?.growAction()
            
            self.stick?.fallAction { [unowned self] () -> Void in
                self.hero?.go(pass: checkPass())
            }
            
        }
    }
    
    func start() {
        loadBackground()
        loadScoreBackground()
        loadScore()
        loadTip()
        loadGameOverLayer()
 
        leftStack = loadStacks(false, startLeftPoint: playAbleRect.origin.x)
        self.removeMidTouch(false, left:true)
        
        self.hero = .init(view: self)
 
        let maxGap = Int(playAbleRect.width - StackMaxWidth - (leftStack?.frame.size.width)!)
        
        let gap = CGFloat(randomInRange(StackGapMinWidth...maxGap))
        rightStack = loadStacks(false, startLeftPoint: nextLeftStartX + gap)
        
        gameOver = false
    }
    
    func restart() {
        isBegin = false
        isEnd = false
        score = 0
        nextLeftStartX = 0
        removeAllChildren()
        start()
    }
    
    fileprivate func checkPass() -> Bool {
        let stick = childNode(withName: StickHeroGameSceneChildName.StickName.rawValue) as! SKSpriteNode

        let rightPoint = Constants.DefinedScreenWidth / 2 + stick.position.x + self.stickHeight
        
        guard rightPoint < self.nextLeftStartX else {
            return false
        }
        
        guard ((leftStack?.frame)!.intersects(stick.frame) && (rightStack?.frame)!.intersects(stick.frame)) else {
            return false
        }
        
        self.checkTouchMidStack()
        
        return true
    }
    
    fileprivate func checkTouchMidStack() {
        let stick = childNode(withName: StickHeroGameSceneChildName.StickName.rawValue) as! SKSpriteNode
        let stackMid = rightStack!.childNode(withName: StickHeroGameSceneChildName.StackMidName.rawValue) as! SKShapeNode
        
        let newPoint = stackMid.convert(CGPoint(x: -10, y: 10), to: self)
        
        if ((stick.position.x + self.stickHeight) >= newPoint.x  && (stick.position.x + self.stickHeight) <= newPoint.x + 20) {
            loadPerfect()
            self.run(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.StickTouchMidAudioName.rawValue, waitForCompletion: false))
            score += 1
        }
 
    }
    
    fileprivate func removeMidTouch(_ animate:Bool, left:Bool) {
        let stack = left ? leftStack : rightStack
        let mid = stack!.childNode(withName: StickHeroGameSceneChildName.StackMidName.rawValue) as! SKShapeNode
        if (animate) {
            mid.run(SKAction.fadeAlpha(to: 0, duration: 0.3))
        }
        else {
            mid.removeFromParent()
        }
    }
    
    
    fileprivate func checkHighScoreAndStore() {
        let highScore = UserDefaults.standard.integer(forKey: StoreScoreName)
        if (score > Int(highScore)) {
            showHighScore()
            
            UserDefaults.standard.set(score, forKey: StoreScoreName)
            UserDefaults.standard.synchronize()
        }
    }
    
    fileprivate func showHighScore() {
        self.run(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.HighScoreAudioName.rawValue, waitForCompletion: false))
        
        let wait = SKAction.wait(forDuration: 0.4)
        let grow = SKAction.scale(to: 1.5, duration: 0.4)
        grow.timingMode = .easeInEaseOut
        let explosion = starEmitterActionAtPosition(CGPoint(x: 0, y: 300))
        let shrink = SKAction.scale(to: 1, duration: 0.2)
       
        let idleGrow = SKAction.scale(to: 1.2, duration: 0.4)
        idleGrow.timingMode = .easeInEaseOut
        let idleShrink = SKAction.scale(to: 1, duration: 0.4)
        let pulsate = SKAction.repeatForever(SKAction.sequence([idleGrow, idleShrink]))
        
        let gameOverLayer = childNode(withName: StickHeroGameSceneChildName.GameOverLayerName.rawValue) as SKNode?
        let highScoreLabel = gameOverLayer?.childNode(withName: StickHeroGameSceneChildName.HighScoreName.rawValue) as SKNode?
        highScoreLabel?.run(SKAction.sequence([wait, explosion, grow, shrink]), completion: { () -> Void in
            highScoreLabel?.run(pulsate)
        })
    }
    
     func moveStackAndCreateNew() {
        let action = SKAction.move(by: CGVector(dx: -nextLeftStartX + (rightStack?.frame.size.width)! + playAbleRect.origin.x - 2, dy: 0), duration: 0.3)
        rightStack?.run(action)
        self.removeMidTouch(true, left:false)

        let hero = childNode(withName: StickHeroGameSceneChildName.HeroName.rawValue) as! SKSpriteNode
        let stick = childNode(withName: StickHeroGameSceneChildName.StickName.rawValue) as! SKSpriteNode
        
        hero.run(action)
        stick.run(SKAction.group([SKAction.move(by: CGVector(dx: -Constants.DefinedScreenWidth, dy: 0), duration: 0.5), SKAction.fadeAlpha(to: 0, duration: 0.3)]), completion: { () -> Void in
            stick.removeFromParent()
        })
        
        leftStack?.run(SKAction.move(by: CGVector(dx: -Constants.DefinedScreenWidth, dy: 0), duration: 0.5), completion: {[unowned self] () -> Void in
            self.leftStack?.removeFromParent()
            
            let maxGap = Int(self.playAbleRect.width - (self.rightStack?.frame.size.width)! - self.StackMaxWidth)
            let gap = CGFloat(randomInRange(self.StackGapMinWidth...maxGap))
            
            self.leftStack = self.rightStack
            self.rightStack = self.loadStacks(true, startLeftPoint:self.playAbleRect.origin.x + (self.rightStack?.frame.size.width)! + gap)
        })
    }
  
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - load node
private extension StickHeroGameScene {
    func loadBackground() {
        guard let _ = childNode(withName: "background") as! SKSpriteNode? else {
            let texture = SKTexture(image: UIImage(named: "stick_background.png")!)
            let node = SKSpriteNode(texture: texture)
            node.size = texture.size()
            node.zPosition = StickHeroGameSceneZposition.backgroundZposition.rawValue
            self.physicsWorld.gravity = CGVector(dx: 0, dy: gravity)
            
            addChild(node)
            return
        }
    }
    
    func loadScore() {
        let scoreBand = SKLabelNode(fontNamed: "Arial")
        scoreBand.name = StickHeroGameSceneChildName.ScoreName.rawValue
        scoreBand.text = "0"
        scoreBand.position = CGPoint(x: 0, y: Constants.DefinedScreenHeight / 2 - 200)
        scoreBand.fontColor = SKColor.white
        scoreBand.fontSize = 100
        scoreBand.zPosition = StickHeroGameSceneZposition.scoreZposition.rawValue
        scoreBand.horizontalAlignmentMode = .center
        
        addChild(scoreBand)
    }
    
    func loadScoreBackground() {
        let back = SKShapeNode(rect: CGRect(x: 0-120, y: 1024-200-30, width: 240, height: 140), cornerRadius: 20)
        back.zPosition = StickHeroGameSceneZposition.scoreBackgroundZposition.rawValue
        back.fillColor = SKColor.black.withAlphaComponent(0.3)
        back.strokeColor = SKColor.black.withAlphaComponent(0.3)
        addChild(back)
    }
    
    func loadHero() {
        let hero = SKSpriteNode(imageNamed: "human1")
        hero.name = StickHeroGameSceneChildName.HeroName.rawValue
        let x:CGFloat = nextLeftStartX - Constants.DefinedScreenWidth / 2 - hero.size.width / 2 - Constants.GAP.X
        let y:CGFloat = StackHeight + hero.size.height / 2 - Constants.DefinedScreenHeight / 2 - Constants.GAP.Y
        hero.position = CGPoint(x: x, y: y)
        hero.zPosition = StickHeroGameSceneZposition.heroZposition.rawValue
        hero.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 16, height: 18))
        hero.physicsBody?.affectedByGravity = false
        hero.physicsBody?.allowsRotation = false
        
        addChild(hero)
    }
    
    func loadTip() {
        let tip = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        tip.name = StickHeroGameSceneChildName.TipName.rawValue
        tip.text = "将手放在屏幕使竿变长"
        tip.position = CGPoint(x: 0, y: Constants.DefinedScreenHeight / 2 - 350)
        tip.fontColor = SKColor.black
        tip.fontSize = 52
        tip.zPosition = StickHeroGameSceneZposition.tipZposition.rawValue
        tip.horizontalAlignmentMode = .center
    
        addChild(tip)
    }
    
    func loadPerfect() {
        defer {
            let perfect = childNode(withName: StickHeroGameSceneChildName.PerfectName.rawValue) as! SKLabelNode?
            let sequence = SKAction.sequence([SKAction.fadeAlpha(to: 1, duration: 0.3), SKAction.fadeAlpha(to: 0, duration: 0.3)])
            let scale = SKAction.sequence([SKAction.scale(to: 1.4, duration: 0.3), SKAction.scale(to: 1, duration: 0.3)])
            perfect!.run(SKAction.group([sequence, scale]))
        }

        guard let _ = childNode(withName: StickHeroGameSceneChildName.PerfectName.rawValue) as! SKLabelNode? else {
            let perfect = SKLabelNode(fontNamed: "Arial")
            perfect.text = "Perfect +1"
            perfect.name = StickHeroGameSceneChildName.PerfectName.rawValue
            perfect.position = CGPoint(x: 0, y: -100)
            perfect.fontColor = SKColor.black
            perfect.fontSize = 50
            perfect.zPosition = StickHeroGameSceneZposition.perfectZposition.rawValue
            perfect.horizontalAlignmentMode = .center
            perfect.alpha = 0
            
            addChild(perfect)
            
            return
        }
       
    }
    
    
    func loadStacks(_ animate: Bool, startLeftPoint: CGFloat) -> SKShapeNode {
        let max:Int = Int(StackMaxWidth / 10)
        let min:Int = Int(StackMinWidth / 10)
        let width:CGFloat = CGFloat(randomInRange(min...max) * 10)
        let height:CGFloat = StackHeight
        let stack = SKShapeNode(rectOf: CGSize(width: width, height: height))
        stack.fillColor = SKColor.black
        stack.strokeColor = SKColor.black
        stack.zPosition = StickHeroGameSceneZposition.stackZposition.rawValue
        stack.name = StickHeroGameSceneChildName.StackName.rawValue
 
        if (animate) {
            stack.position = CGPoint(x: Constants.DefinedScreenWidth / 2, y: -Constants.DefinedScreenHeight / 2 + height / 2)
            
            stack.run(SKAction.moveTo(x: -Constants.DefinedScreenWidth / 2 + width / 2 + startLeftPoint, duration: 0.3), completion: {[unowned self] () -> Void in
                self.isBegin = false
                self.isEnd = false
            })
            
        }
        else {
            stack.position = CGPoint(x: -Constants.DefinedScreenWidth / 2 + width / 2 + startLeftPoint, y: -Constants.DefinedScreenHeight / 2 + height / 2)
        }
        addChild(stack)
        
        let mid = SKShapeNode(rectOf: CGSize(width: 20, height: 20))
        mid.fillColor = SKColor.red
        mid.strokeColor = SKColor.red
        mid.zPosition = StickHeroGameSceneZposition.stackMidZposition.rawValue
        mid.name = StickHeroGameSceneChildName.StackMidName.rawValue
        mid.position = CGPoint(x: 0, y: height / 2 - 20 / 2)
        stack.addChild(mid)
        
        nextLeftStartX = width + startLeftPoint
        
        return stack
    }

    func loadGameOverLayer() {
        let node = SKNode()
        node.alpha = 0
        node.name = StickHeroGameSceneChildName.GameOverLayerName.rawValue
        node.zPosition = StickHeroGameSceneZposition.gameOverZposition.rawValue
        addChild(node)
        
        let label = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        label.text = "Game Over"
        label.fontColor = SKColor.white
        label.fontSize = 150
        label.position = CGPoint(x: 0, y: 100)
        label.horizontalAlignmentMode = .center
        node.addChild(label)
        
        let retry = SKSpriteNode(imageNamed: "button_retry_up")
        retry.name = StickHeroGameSceneChildName.RetryButtonName.rawValue
        retry.position = CGPoint(x: 0, y: -200)
        node.addChild(retry)
        
        let highScore = SKLabelNode(fontNamed: "AmericanTypewriter")
        highScore.text = "Highscore!"
        highScore.fontColor = UIColor.white
        highScore.fontSize = 50
        highScore.name = StickHeroGameSceneChildName.HighScoreName.rawValue
        highScore.position = CGPoint(x: 0, y: 300)
        highScore.horizontalAlignmentMode = .center
        highScore.setScale(0)
        node.addChild(highScore)
    }
    
    //MARK: - Action
    func starEmitterActionAtPosition(_ position: CGPoint) -> SKAction {
        let emitter = SKEmitterNode(fileNamed: "StarExplosion")
        emitter?.position = position
        emitter?.zPosition = StickHeroGameSceneZposition.emitterZposition.rawValue
        emitter?.alpha = 0.6
        addChild((emitter)!)
        
        let wait = SKAction.wait(forDuration: 0.15)

        return SKAction.run({ () -> Void in
           emitter?.run(wait)
        })
    }

}
    
