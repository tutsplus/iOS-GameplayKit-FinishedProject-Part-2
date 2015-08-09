//
//  PlayerNode.swift
//  GameplayKit Introduction
//
//  Created by Davis Allie on 19/07/2015.
//  Copyright © 2015 Davis Allie. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class PlayerNode: SKShapeNode, GKAgentDelegate {
    
    var enabled = true {
        didSet {
            if self.enabled == false {
                self.alpha = 0.1
                
                self.runAction(SKAction.customActionWithDuration(2.0, actionBlock: { (node, elapsedTime) -> Void in
                    if elapsedTime == 2.0 {
                        self.enabled = true
                    }
                }))
                
                self.runAction(SKAction.fadeInWithDuration(2.0))
            }
        }
    }
    
    var entity = Player()
    
    var stateMachine: GKStateMachine!

    func enterNormalState() {
        self.stateMachine.enterState(NormalState)
    }
    
    var agent = GKAgent2D()
    
    //  MARK: Agent Delegate
    func agentWillUpdate(agent: GKAgent) {
        if let agent2D = agent as? GKAgent2D {
            agent2D.position = float2(Float(position.x), Float(position.y))
        }
    }

    func agentDidUpdate(agent: GKAgent) {
        if let agent2D = agent as? GKAgent2D {
            self.position = CGPoint(x: CGFloat(agent2D.position.x), y: CGFloat(agent2D.position.y))
        }
    }
}
