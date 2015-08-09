//
//  ContactNode.swift
//  GameplayKit Introduction
//
//  Created by Davis Allie on 26/07/2015.
//  Copyright © 2015 Davis Allie. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class ContactNode: SKShapeNode, GKAgentDelegate {
        
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
