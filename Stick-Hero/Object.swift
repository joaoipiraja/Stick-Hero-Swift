//
//  Object.swift
//  Stick-Hero
//
//  Created by João Victor Ipirajá de Alencar on 01/04/23.
//  Copyright © 2023 koofrank. All rights reserved.
//

import Foundation
import SpriteKit

struct Object{
    class Stick: SKSpriteNode{
        
        private var view: StickHeroGameScene
        
        init(view: StickHeroGameScene){
            self.view = view
            super.init(texture: nil, color: .black, size: CGSize(width: 12, height: 1))
            self.load()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func scale(){
            
                let action = SKAction.resize(toHeight: CGFloat(Constants.DefinedScreenHeight - view.StackHeight), duration: 1.5)
                self.run(action, withKey:StickHeroGameSceneActionKey.StickGrowAction.rawValue)
            
                  let loopAction = SKAction.group([SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.StickGrowAudioName.rawValue, waitForCompletion: true)])
                  
                  self.run(SKAction.repeatForever(loopAction), withKey: StickHeroGameSceneActionKey.StickGrowAudioAction.rawValue)
            
        }
        
        func growAction(){
         
            self.removeAction(forKey: StickHeroGameSceneActionKey.StickGrowAction.rawValue)
            self.removeAction(forKey: StickHeroGameSceneActionKey.StickGrowAudioAction.rawValue)
            self.run(SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.StickGrowOverAudioName.rawValue, waitForCompletion: false))
            
            view.stickHeight = self.size.height

            
        }
        
        func fallAction(completion: @escaping () -> Void){
            let action = SKAction.rotate(toAngle: CGFloat(-Double.pi / 2), duration: 0.4, shortestUnitArc: true)
            let playFall = SKAction.playSoundFileNamed(StickHeroGameSceneEffectAudioName.StickFallAudioName.rawValue, waitForCompletion: false)
            
            self.run(SKAction.sequence([SKAction.wait(forDuration: 0.2), action, playFall]), completion: completion)
            

        }
        
        private func load(){
            self.zPosition = StickHeroGameSceneZposition.stickZposition.rawValue
            self.name = StickHeroGameSceneChildName.StickName.rawValue
            self.anchorPoint = CGPoint(x: 0.5, y: 0);
            self.position = CGPoint(x: (view.hero?.position.x)! + (view.hero?.size.width)! / 2 + 18, y: (view.hero?.position.y)! - (view.hero?.size.height)! / 2)
            view.addChild(self)
        }

        
    }
}
