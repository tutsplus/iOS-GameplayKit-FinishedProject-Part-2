//
//  PlayerAgent.swift
//  GameplayKit Introduction
//
//  Created by Davis Allie on 9/08/2015.
//  Copyright © 2015 Davis Allie. All rights reserved.
//

import UIKit
import GameplayKit
import SpriteKit

class PlayerAgent: GKAgent2D {
    
    var parentNode: SKSpriteNode
    
    init(withParentNode node: SKSpriteNode) {
        parentNode = node
    }
}
