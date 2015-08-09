//
//  GameScene.swift
//  GameplayKit Introduction
//
//  Created by Davis Allie on 19/07/2015.
//  Copyright (c) 2015 Davis Allie. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let worldNode = SKNode()
    let cameraNode = SKCameraNode()
    
    let playerNode = PlayerNode(circleOfRadius: 50)
    
    var upDisplayTimer: NSTimer!
    var rightDisplayTimer: NSTimer!
    var downDisplayTimer: NSTimer!
    var leftDisplayTimer: NSTimer!
    
    var respawnTimer: NSTimer!
    
    let spawnPoints = [
        CGPoint(x: 245, y: 3900),
        CGPoint(x: 700, y: 3500),
        CGPoint(x: 1250, y: 1500),
        CGPoint(x: 1200, y: 1950),
        CGPoint(x: 1200, y: 2450),
        CGPoint(x: 1200, y: 2950),
        CGPoint(x: 1200, y: 3400),
        CGPoint(x: 2550, y: 2350),
        CGPoint(x: 2500, y: 3100),
        CGPoint(x: 3000, y: 2400),
        CGPoint(x: 2048, y: 2400),
        CGPoint(x: 2200, y: 2200)
    ]
    var graph: GKObstacleGraph!
    
    var agents: [GKAgent2D] = []
    var lastUpdateTime: CFTimeInterval = 0.0
    
    override func didMoveToView(view: SKView) {
        
        let obstacles = SKNode.obstaclesFromNodePhysicsBodies(self.children)
        graph = GKObstacleGraph(obstacles: obstacles, bufferRadius: 0.0)
        
        /* Scene setup */
        self.addChild(worldNode)
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        self.upDisplayTimer = NSTimer(timeInterval: 1.0/60.0, target: self, selector: "moveUp", userInfo: nil, repeats: true)
        self.rightDisplayTimer = NSTimer(timeInterval: 1.0/60.0, target: self, selector: "moveRight", userInfo: nil, repeats: true)
        self.downDisplayTimer = NSTimer(timeInterval: 1.0/60.0, target: self, selector: "moveDown", userInfo: nil, repeats: true)
        self.leftDisplayTimer = NSTimer(timeInterval: 1.0/60.0, target: self, selector: "moveLeft", userInfo: nil, repeats: true)
        
        self.respawnTimer = NSTimer(timeInterval: 1.0, target: self, selector: "respawn", userInfo: nil, repeats: true)
        NSRunLoop.mainRunLoop().addTimer(self.respawnTimer, forMode: NSRunLoopCommonModes)
        
        self.camera = cameraNode
        self.camera?.position = CGPoint(x: 2048, y: 2048)
        self.camera?.setScale(1.0)
        
        playerNode.position = CGPoint(x: 2048, y: 2048)
        playerNode.fillColor = UIColor.blueColor()
        playerNode.lineWidth = 0.0
        
        let playerBody = SKPhysicsBody(circleOfRadius: 50)
        playerBody.contactTestBitMask = 1
        playerNode.physicsBody = playerBody
        
        self.addChild(playerNode)
        self.initialSpawn()
        
        playerNode.stateMachine = GKStateMachine(states: [NormalState(withNode: playerNode), InvulnerableState(withNode: playerNode)])
        playerNode.stateMachine.enterState(NormalState)
        
        playerNode.entity.addComponent(playerNode.agent)
        playerNode.agent.delegate = playerNode
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        self.camera?.position = playerNode.position
        
        if self.lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        
        let delta = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        playerNode.agent.updateWithDeltaTime(delta)
        
        for agent in agents {
            agent.updateWithDeltaTime(delta)
        }
    }
    
    //  MARK: Physics Delegate
    func didBeginContact(contact: SKPhysicsContact) {
        let nodeA = contact.bodyA.node
        let nodeB = contact.bodyB.node
        
        if let contact = nodeA as? ContactNode where nodeB! is PlayerNode {
            self.handleContactWithNode(contact)
        }
        else if let contact = nodeB as? ContactNode where nodeA! is PlayerNode {
            self.handleContactWithNode(contact)
        }
    }
    
    func handleContactWithNode(contact: ContactNode) {
        if contact is PointsNode {
            NSNotificationCenter.defaultCenter().postNotificationName("updateScore", object: self, userInfo: ["score": 1])
        }
        else if contact is RedEnemyNode && playerNode.stateMachine.currentState! is NormalState {
            NSNotificationCenter.defaultCenter().postNotificationName("updateScore", object: self, userInfo: ["score": -2])
            
            playerNode.stateMachine.enterState(InvulnerableState)
            playerNode.performSelector("enterNormalState", withObject: nil, afterDelay: 5.0)
        }
        else if contact is YellowEnemyNode  && playerNode.stateMachine.currentState! is NormalState  {
            self.playerNode.enabled = false
        }
        
        contact.removeFromParent()
    }
    
    //  MARK: Respawning Behaviour
    func initialSpawn() {
        
        let endNode = GKGraphNode2D(point: float2(x: 2048.0, y: 2048.0))
        self.graph.connectNodeUsingObstacles(endNode)
        
        for point in self.spawnPoints {
            let respawnFactor = arc4random() % 3  //  Will produce a value between 0 and 2 (inclusive)
            
            var node: SKShapeNode? = nil
            
            switch respawnFactor {
            case 0:
                node = PointsNode(circleOfRadius: 25)
                node!.physicsBody = SKPhysicsBody(circleOfRadius: 25)
                node!.fillColor = UIColor.greenColor()
            case 1:
                node = RedEnemyNode(circleOfRadius: 75)
                node!.physicsBody = SKPhysicsBody(circleOfRadius: 75)
                node!.fillColor = UIColor.redColor()
            case 2:
                node = YellowEnemyNode(circleOfRadius: 50)
                node!.physicsBody = SKPhysicsBody(circleOfRadius: 50)
                node!.fillColor = UIColor.yellowColor()
            default:
                break
            }
            
            if let entity = node?.valueForKey("entity") as? GKEntity,
                let agent = node?.valueForKey("agent") as? GKAgent2D where respawnFactor != 0 {
                    
                entity.addComponent(agent)
                agent.delegate = node as? ContactNode
                agent.position = float2(x: Float(point.x), y: Float(point.y))
                agents.append(agent)
                
                /*let behavior = GKBehavior(goal: GKGoal(toSeekAgent: playerNode.agent), weight: 1.0)
                agent.behavior = behavior*/
            
                /*** BEGIN PATHFINDING ***/
                let startNode = GKGraphNode2D(point: agent.position)
                self.graph.connectNodeUsingObstacles(startNode)
                
                let pathNodes = self.graph.findPathFromNode(startNode, toNode: endNode) as! [GKGraphNode2D]
                
                if !pathNodes.isEmpty {
                    let path = GKPath(graphNodes: pathNodes, radius: 1.0)
                    
                    let followPath = GKGoal(toFollowPath: path, maxPredictionTime: 1.0, forward: true)
                    let stayOnPath = GKGoal(toStayOnPath: path, maxPredictionTime: 1.0)
                    
                    let behavior = GKBehavior(goals: [followPath, stayOnPath])
                    agent.behavior = behavior
                }
                
                self.graph.removeNodes([startNode])
                /*** END PATHFINDING ***/
                
                agent.mass = 0.01
                agent.maxSpeed = 50
                agent.maxAcceleration = 1000
            }
            
            node!.position = point
            node!.strokeColor = UIColor.clearColor()
            node!.physicsBody!.contactTestBitMask = 1
            self.addChild(node!)
        }
        
        self.graph.removeNodes([endNode])
    }
    
    func respawn() {
        
    }
    
    //  MARK: Movement Methods
    func startMoveUp() {
        NSRunLoop.mainRunLoop().addTimer(self.upDisplayTimer, forMode: NSRunLoopCommonModes)
    }
    
    func endMoveUp() {
        self.upDisplayTimer.invalidate()
        self.upDisplayTimer = NSTimer(timeInterval: 1.0/60.0, target: self, selector: "moveUp", userInfo: nil, repeats: true)
    }
    
    func moveUp() {
        let action = SKAction.moveByX(0, y: 10, duration: 0.0)
        if self.playerNode.enabled {
            self.playerNode.runAction(action)
        }
    }
    
    func startMoveRight() {
        NSRunLoop.mainRunLoop().addTimer(self.rightDisplayTimer, forMode: NSRunLoopCommonModes)
    }
    
    func endMoveRight() {
        self.rightDisplayTimer.invalidate()
        self.rightDisplayTimer = NSTimer(timeInterval: 1.0/60.0, target: self, selector: "moveRight", userInfo: nil, repeats: true)
    }
    
    func moveRight() {
        let action = SKAction.moveByX(10, y: 0, duration: 0.0)
        if self.playerNode.enabled {
            self.playerNode.runAction(action)
        }
    }
    
    func startMoveDown() {
        NSRunLoop.mainRunLoop().addTimer(self.downDisplayTimer, forMode: NSRunLoopCommonModes)
    }
    
    func endMoveDown() {
        self.downDisplayTimer.invalidate()
        self.downDisplayTimer = NSTimer(timeInterval: 1.0/60.0, target: self, selector: "moveDown", userInfo: nil, repeats: true)
    }
    
    func moveDown() {
        let action = SKAction.moveByX(0, y: -10, duration: 1.0/60.0)
        if self.playerNode.enabled {
            self.playerNode.runAction(action)
        }
    }
    
    func startMoveLeft() {
        NSRunLoop.mainRunLoop().addTimer(self.leftDisplayTimer, forMode: NSRunLoopCommonModes)
    }
    
    func endMoveLeft() {
        self.leftDisplayTimer.invalidate()
        self.leftDisplayTimer = NSTimer(timeInterval: 1.0/60.0, target: self, selector: "moveLeft", userInfo: nil, repeats: true)
    }
    
    func moveLeft() {
        let action = SKAction.moveByX(-10, y: 0, duration: 1.0/60.0)
        if self.playerNode.enabled {
            self.playerNode.runAction(action)
        }
    }
}
