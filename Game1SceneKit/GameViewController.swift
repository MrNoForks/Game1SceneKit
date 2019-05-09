//
//  GameViewController.swift
//  Game1SceneKit
//
//  Created by Boppo on 09/05/19.
//  Copyright © 2019 Boppo. All rights reserved.
//
//https://www.pluralsight.com/blog/film-games/understanding-different-light-types
import UIKit
import QuartzCore
import SceneKit

enum BodyType : Int{
    // Powers of 2
    case box = 1
    case ball = 2
    case donut = 4
    case pyramid = 8
}



class GameViewController: UIViewController , SCNPhysicsContactDelegate{

    var ballNode : SCNNode!
    
    var boxNode : SCNNode!
    
    var scnView : SCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/MainScene.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        

        
        // retrieve the SCNView
        scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
       
        //debugOptions
        scnView.debugOptions = .showPhysicsShapes
        
        // this will handle contact notification
        scnView.scene?.physicsWorld.contactDelegate = self
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        //MARK:- SCNAction
        let wait : SCNAction = SCNAction.wait(duration: 3)
        
        let runAfter : SCNAction = SCNAction.run { _ in
            
            self.addSceneContent()
            
        }
        
        let seq : SCNAction = SCNAction.sequence([wait,runAfter])
        
        scnView.scene!.rootNode.runAction(seq)

    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        print("Contact happened")
        
        if(contact.nodeA.physicsBody?.contactTestBitMask == BodyType.box.rawValue && contact.nodeB.physicsBody?.contactTestBitMask == BodyType.ball.rawValue){
            print("Node A is a box and Node B is a ball")
        }
        else if (contact.nodeA.physicsBody?.contactTestBitMask == BodyType.ball.rawValue && contact.nodeB.physicsBody?.contactTestBitMask == BodyType.box.rawValue){
             print("Node A is a ball and Node B is a box")
        }
        
    }
    
    func addSceneContent(){
        // retrieve the ship node
        let ship = scnView.scene!.rootNode.childNode(withName: "DummyNode", recursively: false)!
        
        // animate the 3d object
        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        
        // enumerating ChildNodes
        scnView.scene?.rootNode.enumerateChildNodes({ (node, _) in
            
            if (node.name == "ball"){
                
                print("Found ball")
                
                ballNode = node
                //MARK:- SCNPhysicsBody
                ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: node, options: nil))
                
                ballNode.physicsBody?.isAffectedByGravity = true
                
                ballNode.physicsBody?.restitution = 1
                
                ballNode.physicsBody?.categoryBitMask = BodyType.ball.rawValue
                
                ballNode.physicsBody?.collisionBitMask = BodyType.box.rawValue
                
                ballNode.physicsBody?.contactTestBitMask = BodyType.box.rawValue
            }
                
            else if (node.name == "box"){
                
                print("Found box")
                
                boxNode = node
                
                let boxGeometry = boxNode.geometry
                
                let boxShape = SCNPhysicsShape(geometry: boxGeometry!, options: nil)
                
                boxNode.physicsBody = SCNPhysicsBody(type: .static, shape: boxShape)
                
                boxNode.physicsBody?.restitution = 1
                
                boxNode.physicsBody?.categoryBitMask = BodyType.box.rawValue
                
                // What you can collide with
                boxNode.physicsBody?.collisionBitMask = BodyType.ball.rawValue
                // this means ball cant go right through box which happens kinda by default but now we are specifally saying we want this things to collide with eachother
                
                //MARK:- Collision with multiple things
                /*
                boxNode.physicsBody?.collisionBitMask = BodyType.ball.rawValue | BodyType.pyramid.rawValue
                // To make  boxNode collide with different object we put | symbol
                 */
                // This means we actually care about collision of this 2 things
                boxNode.physicsBody?.contactTestBitMask = BodyType.ball.rawValue
                // If we dont care about we dont set it at all
                
            }
        })
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
//        // retrieve the SCNView
//        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // in AR you can have option to detect existing plane if it is vertical or horizontal
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            //MARK:- SCNTransaction
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
            
            if result.node.name == "ball"{
                
                //MARK:- PhysicsBody.applyforce
                ballNode.physicsBody?.applyForce(SCNVector3(0, 10, 0), asImpulse: false)
                
            }
            
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

}
