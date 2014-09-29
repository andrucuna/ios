//
//  GameScene.swift
//  Swiftris
//
//  Created by Andrés Ruiz on 9/24/14.
//  Copyright (c) 2014 Andrés Ruiz. All rights reserved.
//

import SpriteKit


// We simply define the point size of each block sprite - in our case 20.0 x 20.0 - the lower of the 
// available resolution options for each block image. We also declare a layer position which will give us an 
// offset from the edge of the screen.
let BlockSize:CGFloat = 20.0
// This variable will represent the slowest speed at which our shapes will travel.
let TickLengthLevelOne = NSTimeInterval(600)


class GameScene: SKScene
{
    // #2
    let gameLayer = SKNode()
    let shapeLayer = SKNode()
    let LayerPosition = CGPoint(x: 6, y: -6)

    // In tick, its type is (() -> ())? which means that it's a closure which takes no parameters and 
    // returns nothing. Its question mark indicates that it is optional and therefore may be nil.
    var tick: (() ->())?
    var tickLengthMillis = TickLengthLevelOne
    var lastTick: NSDate?
    var textureCache = Dictionary<String, SKTexture>()
    
    required init( coder aDecoder: (NSCoder!) )
    {
        fatalError( "NSCoder not supported" )
    }
    
    override init( size: CGSize )
    {
        super.init( size: size )
        
        anchorPoint = CGPoint( x: 0, y: 1.0 )
        
        let background = SKSpriteNode( imageNamed: "background" )
        background.position = CGPoint( x: 0, y: 0 )
        background.anchorPoint = CGPoint( x: 0, y: 1.0 )
        
        addChild( background )
        
        addChild(gameLayer)
        
        let gameBoardTexture = SKTexture(imageNamed: "gameboard")
        let gameBoard = SKSpriteNode(texture: gameBoardTexture, size: CGSizeMake(BlockSize * CGFloat(NumColumns), BlockSize * CGFloat(NumRows)))
        gameBoard.anchorPoint = CGPoint(x:0, y:1.0)
        gameBoard.position = LayerPosition
        
        shapeLayer.position = LayerPosition
        shapeLayer.addChild(gameBoard)
        gameLayer.addChild(shapeLayer)
        
        // We set up a looping sound playback action of our theme song.
        runAction(SKAction.repeatActionForever(SKAction.playSoundFileNamed("theme.mp3", waitForCompletion: true)))
    }
    
    // We added a method which GameViewController may use to play any sound file on demand.
    func playSound(sound:String)
    {
        runAction(SKAction.playSoundFileNamed(sound, waitForCompletion: false))
    }
    
    override func update(currentTime: CFTimeInterval)
    {
        /* Called before each frame is rendered */
        
        // If lastTick is missing, we are in a paused state, not reporting elapsed ticks to anyone,
        // therefore we simply return.
        if lastTick == nil
        {
            return
        }
        var timePassed = lastTick!.timeIntervalSinceNow * -1000.0
        if timePassed > tickLengthMillis
        {
            lastTick = NSDate.date()
            tick?()
        }
    }
    
    // We provide accessor methods to let external classes stop and start the ticking process.
    func startTicking() {
        lastTick = NSDate.date()
    }
    
    func stopTicking() {
        lastTick = nil
    }
    
    
    // The math here looks funky but just know that each sprite will be anchored at its center, therefore we 
    // need to find its center coordinate before placing it in our shapeLayer object.
    func pointForColumn(column: Int, row: Int) -> CGPoint
    {
        let x: CGFloat = LayerPosition.x + (CGFloat(column) * BlockSize) + (BlockSize / 2)
        let y: CGFloat = LayerPosition.y - ((CGFloat(row) * BlockSize) + (BlockSize / 2))
        return CGPointMake(x, y)
    }
    
    func addPreviewShapeToScene(shape:Shape, completion:() -> ())
    {
        for (idx, block) in enumerate(shape.blocks)
        {
            // We've created a method which will add a shape for the first time to the scene as a preview 
            // shape. We use a dictionary to store copies of re-usable SKTexture objects since each shape
            // will require multiple copies of the same image.
            var texture = textureCache[block.spriteName]
            if texture == nil
            {
                texture = SKTexture(imageNamed: block.spriteName)
                textureCache[block.spriteName] = texture
            }
            let sprite = SKSpriteNode(texture: texture)
            
            // We use our convenient pointForColumn(Int, Int) method to place each block's sprite in the 
            // proper location. We start it at row - 2, such that the preview piece animates smoothly into 
            // place from a higher location.
            sprite.position = pointForColumn(block.column, row:block.row - 2)
            shapeLayer.addChild(sprite)
            block.sprite = sprite
            
            // Animation
            sprite.alpha = 0
            // We introduce SKAction objects which are responsible for visually manipulating SKNode objects. 
            // Each block will fade and move into place as it appears as part of the next piece. It will 
            // move two rows down and fade from complete transparency to 70% opacity.
            let moveAction = SKAction.moveTo(pointForColumn(block.column, row: block.row), duration: NSTimeInterval(0.2))
            moveAction.timingMode = .EaseOut
            let fadeInAction = SKAction.fadeAlphaTo(0.7, duration: 0.4)
            fadeInAction.timingMode = .EaseOut
            sprite.runAction(SKAction.group([moveAction, fadeInAction]))
        }
        runAction(SKAction.waitForDuration(0.4), completion: completion)
    }
    
    func movePreviewShape(shape:Shape, completion:() -> ())
    {
        for (idx, block) in enumerate(shape.blocks)
        {
            let sprite = block.sprite!
            let moveTo = pointForColumn(block.column, row:block.row)
            let moveToAction:SKAction = SKAction.moveTo(moveTo, duration: 0.2)
            moveToAction.timingMode = .EaseOut
            sprite.runAction(
                SKAction.group([moveToAction, SKAction.fadeAlphaTo(1.0, duration: 0.2)]), completion:nil)
        }
        runAction(SKAction.waitForDuration(0.2), completion: completion)
    }
    
    func redrawShape(shape:Shape, completion:() -> ())
    {
        for (idx, block) in enumerate(shape.blocks)
        {
            let sprite = block.sprite!
            let moveTo = pointForColumn(block.column, row:block.row)
            let moveToAction:SKAction = SKAction.moveTo(moveTo, duration: 0.05)
            moveToAction.timingMode = .EaseOut
            sprite.runAction(moveToAction, completion: nil)
        }
        runAction(SKAction.waitForDuration(0.05), completion: completion)
    }
    
    
    // You can see that we take in precisely the tuple data which Swiftris returns each time a line is 
    // removed. This will ensure that GameViewController need only pass those elements to GameScene in order 
    // for them to animate properly.
    func animateCollapsingLines(linesToRemove: Array<Array<Block>>, fallenBlocks: Array<Array<Block>>, completion:() -> ())
    {
        var longestDuration: NSTimeInterval = 0
        // We also established a longestDuration variable which will determine precisely how long we should 
        // wait before calling the completion closure.
        for (columnIdx, column) in enumerate(fallenBlocks)
        {
            for (blockIdx, block) in enumerate(column)
            {
                let newPosition = pointForColumn(block.column, row: block.row)
                let sprite = block.sprite!
                // We wrote code which will produce this pleasing effect for eye balls to enjoy. Based on 
                // the block and column indices, we introduce a directly proportional delay.
                let delay = (NSTimeInterval(columnIdx) * 0.05) + (NSTimeInterval(blockIdx) * 0.05)
                let duration = NSTimeInterval(((sprite.position.y - newPosition.y) / BlockSize) * 0.1)
                let moveAction = SKAction.moveTo(newPosition, duration: duration)
                moveAction.timingMode = .EaseOut
                sprite.runAction(
                    SKAction.sequence([
                        SKAction.waitForDuration(delay),
                        moveAction]))
                longestDuration = max(longestDuration, duration + delay)
            }
        }
        
        for (rowIdx, row) in enumerate(linesToRemove)
        {
            for (blockIdx, block) in enumerate(row)
            {
                // We make their blocks shoot off the screen like explosive debris. In order to accomplish 
                // this we will employ UIBezierPath. Our arch requires a radius and we've chosen to generate 
                // one randomly in order to introduce a natural variance among the explosive paths. 
                // Furthermore, we've randomized whether the block flies left or right.
                let randomRadius = CGFloat(UInt(arc4random_uniform(400) + 100))
                let goLeft = arc4random_uniform(100) % 2 == 0
                
                var point = pointForColumn(block.column, row: block.row)
                point = CGPointMake(point.x + (goLeft ? -randomRadius : randomRadius), point.y)
                
                let randomDuration = NSTimeInterval(arc4random_uniform(2)) + 0.5
                // We choose beginning and starting angles, these are clearly in radians
                // When going left, we begin at 0 radians and end at π. When going right, we go from π to 
                // 2π. Math FTW!
                var startAngle = CGFloat(M_PI)
                var endAngle = startAngle * 2
                if goLeft
                {
                    endAngle = startAngle
                    startAngle = 0
                }
                let archPath = UIBezierPath(arcCenter: point, radius: randomRadius, startAngle: startAngle, endAngle: endAngle, clockwise: goLeft)
                let archAction = SKAction.followPath(archPath.CGPath, asOffset: false, orientToPath: true, duration: randomDuration)
                archAction.timingMode = .EaseIn
                let sprite = block.sprite!
                // We place the block sprite above the others such that they animate above the other blocks 
                // and begin the sequence of actions which concludes with the sprite being removed from the 
                // scene.
                sprite.zPosition = 100
                sprite.runAction(
                    SKAction.sequence(
                        [SKAction.group([archAction, SKAction.fadeOutWithDuration(NSTimeInterval(randomDuration))]),
                            SKAction.removeFromParent()]))
            }
        }
        // We run the completion action after a duration matching the time it will take to drop the last 
        // block to its new resting place.
        runAction(SKAction.waitForDuration(longestDuration), completion:completion)
    }
}
