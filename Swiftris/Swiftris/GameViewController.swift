//
//  GameViewController.swift
//  Swiftris
//
//  Created by Andrés Ruiz on 9/24/14.
//  Copyright (c) 2014 Andrés Ruiz. All rights reserved.
//

import UIKit
import SpriteKit


class GameViewController: UIViewController, SwiftrisDelegate, UIGestureRecognizerDelegate
{

    var scene: GameScene!
    var swiftris:Swiftris!
    // We keep track of the last point on the screen at which a shape movement occurred or where a pan 
    // begins.
    var panPointReference:CGPoint?
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var levelLabel: UILabel!
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        //Configure the view
        let skView = view as SKView
        skView.multipleTouchEnabled = false
        
        //Create and configure the scene.
        scene = GameScene( size: skView.bounds.size )
        scene.scaleMode = .AspectFill
        
        // We've set a closure for the tick property of GameScene.swift.
        scene.tick = didTick
        swiftris = Swiftris()
        swiftris.delegate = self
        swiftris.beginGame()
        
        //Present the scene.
        skView.presentScene( scene )
        
        // We add nextShape to the game layer at the preview location. When that animation completes, we 
        // reposition the underlying Shape object at the starting row and starting column before we ask 
        // GameScene to move it from the preview location to its starting position. Once that completes, we 
        // ask Swiftris for a new shape, begin ticking, and add the newly established upcoming piece to the 
        // preview area.
        /*
        scene.addPreviewShapeToScene(swiftris.nextShape!)
        {
            self.swiftris.nextShape?.moveTo(StartingColumn, row: StartingRow)
            self.scene.movePreviewShape(self.swiftris.nextShape!)
            {
                let nextShapes = self.swiftris.newShape()
                self.scene.startTicking()
                self.scene.addPreviewShapeToScene(nextShapes.nextShape!) {}
            }
        }
        */
    }

    override func prefersStatusBarHidden() -> Bool
    {
        return true
    }
    
    // All it does is lower the falling shape by one row and then asks GameScene to redraw the shape at its 
    // new location.
    func didTick()
    {
        swiftris.letShapeFall()
        /*
        swiftris.fallingShape?.lowerShapeByOneRow()
        scene.redrawShape(swiftris.fallingShape!, completion: {})
        */
    }
    
    func nextShape()
    {
        let newShapes = swiftris.newShape()
        if let fallingShape = newShapes.fallingShape
        {
            self.scene.addPreviewShapeToScene(newShapes.nextShape!) {}
            self.scene.movePreviewShape(fallingShape)
            {
                // We introduced a boolean which allows us to shut down interaction with the view. 
                // Regardless of what the user does to the device at this point, they will not be able to 
                // manipulate Switris in any way. This is useful during intermediate states when blocks are 
                // being animated, shifted around or calculated. Otherwise, a well-timed user interaction 
                // may cause an unpredictable game state to occur.
                self.view.userInteractionEnabled = true
                self.scene.startTicking()
            }
        }
    }
    
    func gameDidBegin(swiftris: Swiftris)
    {
        levelLabel.text = "\(swiftris.level)"
        scoreLabel.text = "\(swiftris.score)"
        scene.tickLengthMillis = TickLengthLevelOne
        
        // The following is false when restarting a new game
        if swiftris.nextShape != nil && swiftris.nextShape!.blocks[0].sprite == nil
        {
            scene.addPreviewShapeToScene(swiftris.nextShape!)
            {
                self.nextShape()
            }
        }
        else
        {
            nextShape()
        }
    }
    
    func gameDidEnd(swiftris: Swiftris)
    {
        view.userInteractionEnabled = false
        scene.stopTicking()
        
        scene.playSound("gameover.mp3")
        scene.animateCollapsingLines(swiftris.removeAllBlocks(), fallenBlocks: Array<Array<Block>>())
        {
            swiftris.beginGame()
        }
    }
    
    func gameDidLevelUp(swiftris: Swiftris)
    {
        levelLabel.text = "\(swiftris.level)"
        if scene.tickLengthMillis >= 100
        {
            scene.tickLengthMillis -= 100
        }
        else if scene.tickLengthMillis > 50
        {
            scene.tickLengthMillis -= 50
        }
        scene.playSound("levelup.mp3")
    }
    
    func gameShapeDidDrop(swiftris: Swiftris)
    {
        // We stop the ticks, redraw the shape at its new location and then let it drop. This will in turn 
        // call back to GameViewController and report that the shape has landed.
        scene.stopTicking()
        scene.redrawShape(swiftris.fallingShape!)
        {
            swiftris.letShapeFall()
        }
        
        scene.playSound("drop.mp3")
    }
    
    func gameShapeDidLand(swiftris: Swiftris)
    {
        scene.stopTicking()
        
        self.view.userInteractionEnabled = false
        
        // We invoke removeCompletedLines to recover the two arrays from Swiftris. If any lines have
        // been removed at all, we update the score label to represent the newest score and then animate the 
        // blocks with our explosive new animation function.
        let removedLines = swiftris.removeCompletedLines()
        if removedLines.linesRemoved.count > 0
        {
            self.scoreLabel.text = "\(swiftris.score)"
            scene.animateCollapsingLines(removedLines.linesRemoved, fallenBlocks:removedLines.fallenBlocks)
            {
                // A recursive function is one which invokes itself. In Swiftris' case, after the blocks
                // have fallen to their new location, they may have formed brand new lines. Therefore, after 
                // the first set of lines are removed, we invoke gameShapeDidLand(Swiftris) again in order 
                // to detect any such new lines. If none are found, the next shape is brought in.
                self.gameShapeDidLand(swiftris)
            }
            scene.playSound("bomb.mp3")
        }
        else
        {
            nextShape()
        }
    }
    
    // All that is necessary to do after a shape has moved is to redraw its representative sprites at their 
    // new locations.
    func gameShapeDidMove(swiftris: Swiftris)
    {
        scene.redrawShape(swiftris.fallingShape!) {}
    }
    
    @IBAction func didTap(sender: UITapGestureRecognizer)
    {
        swiftris.rotateShape()
    }
    
    @IBAction func didPan(sender: UIPanGestureRecognizer)
    {
        // We recover a point which defines the translation of the gesture relative to where it began. This 
        // is not an absolute coordinate, just a measure of the distance that the user's finger has 
        // traveled.
        let currentPoint = sender.translationInView(self.view)
        if let originalPoint = panPointReference
        {
            // We check whether or not the x translation has crossed our threshold - 90% of BlockSize - 
            // before proceeding.
            if abs(currentPoint.x - originalPoint.x) > (BlockSize * 0.9)
            {
                // Velocity will give us direction, in this case a positive velocity represents a gesture 
                // moving towards the right side of the screen, negative towards the left. We then move the 
                // shape in the corresponding direction and reset our reference point.
                if sender.velocityInView(self.view).x > CGFloat(0)
                {
                    swiftris.moveShapeRight()
                    panPointReference = currentPoint
                }
                else
                {
                    swiftris.moveShapeLeft()
                    panPointReference = currentPoint
                }
            }
        }
        else if sender.state == .Began
        {
            panPointReference = currentPoint
        }
    }
    
    @IBAction func didSwipe(sender: UISwipeGestureRecognizer)
    {
        swiftris.dropShape()
    }
    
    // GameViewController will implement an optional delegate method found in UIGestureRecognizerDelegate 
    // which will allow each gesture recognizer to work in tandem with the others. However, at times a 
    // gesture recognizer may collide with another.
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool
    {
        return true
    }
    
    // The code performs several optional cast conditionals. These if conditionals attempt to cast the 
    // generic UIGestureRecognizer parameters as the specific types of recognizers we expect to be notified 
    // of. If the cast succeeds, the code block is executed.
    // Our code lets the pan gesture recognizer take precedence over the swipe gesture and the tap to do 
    // likewise over the pan. This will keep all three of our recognizers from bickering with one another 
    // over who's the prettiest API in the room.
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer!, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer!) -> Bool
    {
        if let swipeRec = gestureRecognizer as? UISwipeGestureRecognizer
        {
            if let panRec = otherGestureRecognizer as? UIPanGestureRecognizer
            {
                return true
            }
        }
        else if let panRec = gestureRecognizer as? UIPanGestureRecognizer
        {
            if let tapRec = otherGestureRecognizer as? UITapGestureRecognizer
            {
                return true
            }
        }
        return false
    }
}
