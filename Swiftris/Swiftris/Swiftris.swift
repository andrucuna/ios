//
//  Swiftris.swift
//  Swiftris
//
//  Created by Andrés Ruiz on 9/26/14.
//  Copyright (c) 2014 Andrés Ruiz. All rights reserved.
//

import Foundation

// We've defined the total number of rows and columns on the game board, the location of where each piece 
// starts and the location of where the preview piece belongs.
let NumColumns = 10
let NumRows = 20

let StartingColumn = 4
let StartingRow = 0

let PreviewColumn = 12
let PreviewRow = 1

let PointsPerLine = 10
let LevelThreshold = 1000

protocol SwiftrisDelegate
{
    // Invoked when the current round of Swiftris ends
    func gameDidEnd(swiftris: Swiftris)
    
    // Invoked immediately after a new game has begun
    func gameDidBegin(swiftris: Swiftris)
    
    // Invoked when the falling shape has become part of the game board
    func gameShapeDidLand(swiftris: Swiftris)
    
    // Invoked when the falling shape has changed its location
    func gameShapeDidMove(swiftris: Swiftris)
    
    // Invoked when the falling shape has changed its location after being dropped
    func gameShapeDidDrop(swiftris: Swiftris)
    
    // Invoked when the game has reached a new level
    func gameDidLevelUp(swiftris: Swiftris)
}

class Swiftris
{
    var blockArray:Array2D<Block>
    var nextShape:Shape?
    var fallingShape:Shape?
    var delegate:SwiftrisDelegate?
    var score:Int
    var level:Int
    
    init()
    {
        score = 0
        level = 1
        fallingShape = nil
        nextShape = nil
        blockArray = Array2D<Block>(columns: NumColumns, rows: NumRows)
    }
    
    func beginGame()
    {
        if (nextShape == nil)
        {
            nextShape = Shape.random(PreviewColumn, startingRow: PreviewRow)
        }
        
        delegate?.gameDidBegin(self)
    }
    
    // We have a method which assigns nextShape, our preview shape, as fallingShape.
    func newShape() -> (fallingShape:Shape?, nextShape:Shape?)
    {
        fallingShape = nextShape
        nextShape = Shape.random(PreviewColumn, startingRow: PreviewRow)
        fallingShape?.moveTo(StartingColumn, row: StartingRow)
        
        // We added some logic to newShape() which may now detect the ending of a Switris game. The game 
        // ends when a new shape located at the designated starting location collides with existing blocks. 
        // This is the case where the player no longer has enough room to move the new shape, and therefore, 
        // we must terminate their tower of terror.
        if detectIllegalPlacement()
        {
            nextShape = fallingShape
            nextShape!.moveTo(PreviewColumn, row: PreviewRow)
            endGame()
            return (nil, nil)
        }
        return (fallingShape, nextShape)
    }
    
    // We added a function for checking both block boundary conditions. This first determines whether or not 
    // a block exceeds the legal size of the game board. The second determines whether or not a block's 
    // current location overlaps with an existing block.
    func detectIllegalPlacement() -> Bool
    {
        if let shape = fallingShape
        {
            for block in shape.blocks
            {
                if block.column < 0 || block.column >= NumColumns
                    || block.row < 0 || block.row >= NumRows
                {
                        return true
                }
                else if blockArray[block.column, block.row] != nil
                {
                    return true
                }
            }
        }
        return false
    }
    
    // This function will continue dropping the shape by a single row until an illegal placement state is 
    // reached, at which point it will raise it and then notify the delegate that a drop has occurred.
    func dropShape()
    {
        if let shape = fallingShape
        {
            while detectIllegalPlacement() == false
            {
                shape.lowerShapeByOneRow()
            }
            shape.raiseShapeByOneRow()
            delegate?.gameShapeDidDrop(self)
        }
    }
    
    // We've defined a function to be called once every tick. This attempts to lower the shape by one row 
    // and ends the game if it fails to do so without finding legal placement for it.
    func letShapeFall()
    {
        if let shape = fallingShape
        {
            shape.lowerShapeByOneRow()
            if detectIllegalPlacement()
            {
                shape.raiseShapeByOneRow()
                if detectIllegalPlacement()
                {
                    endGame()
                }
                else
                {
                    settleShape()
                }
            }
            else
            {
                delegate?.gameShapeDidMove(self)
                if detectTouch()
                {
                    settleShape()
                }
            }
        }
    }
    
    // Swiftris attempts to rotate the shape clockwise. If its new block positions violate the boundaries of 
    // the game or overlap with settled blocks, we revert the rotation and return. Otherwise, we let the 
    // delegate know that the shape has moved.
    func rotateShape()
    {
        if let shape = fallingShape
        {
            shape.rotateClockwise()
            if detectIllegalPlacement()
            {
                shape.rotateCounterClockwise()
            }
            else
            {
                delegate?.gameShapeDidMove(self)
            }
        }
    }
    
    // Lastly, the player will enjoy the privilege of moving the shape either leftwards or rightwards. The 
    // functions written below permit such behavior and follow the same pattern found in rotateShape.
    func moveShapeLeft()
    {
        if let shape = fallingShape
        {
            shape.shiftLeftByOneColumn()
            if detectIllegalPlacement()
            {
                shape.shiftRightByOneColumn()
                return
            }
            delegate?.gameShapeDidMove(self)
        }
    }
    
    func moveShapeRight()
    {
        if let shape = fallingShape
        {
            shape.shiftRightByOneColumn()
            if detectIllegalPlacement()
            {
                shape.shiftLeftByOneColumn()
                return
            }
            delegate?.gameShapeDidMove(self)
        }
    }
    
    // Adds the falling shape to the collection of blocks maintained by Swiftris. Once the falling shape's 
    // blocks are part of the game board, fallingShape is nullified and the delegate is notified of a new 
    // shape settling into the game board.
    func settleShape()
    {
        if let shape = fallingShape
        {
            for block in shape.blocks
            {
                blockArray[block.column, block.row] = block
            }
            fallingShape = nil
            delegate?.gameShapeDidLand(self)
        }
    }
    
    // Swiftris needs to be able to tell when a shape should settle. This happens under two conditions: when 
    // one of the shapes' bottom blocks is located immediately above a block on the game board or when one 
    // of those same blocks has reached the bottom of the game board. The function properly detects this 
    // occurrence and returns true when detected.
    func detectTouch() -> Bool
    {
        if let shape = fallingShape
        {
            for bottomBlock in shape.bottomBlocks
            {
                if bottomBlock.row == NumRows - 1 ||
                    blockArray[bottomBlock.column, bottomBlock.row + 1] != nil
                {
                        return true
                }
            }
        }
        return false
    }
    
    func endGame()
    {
        score = 0
        level = 1
        delegate?.gameDidEnd(self)
    }
    
    // We defined a function which returns yet another tuple. This time it's composed of two arrays: 
    // linesRemoved and fallenBlocks. linesRemoved maintains each row of blocks which the user has filled in 
    // completely.
    func removeCompletedLines() -> (linesRemoved: Array<Array<Block>>, fallenBlocks: Array<Array<Block>>)
    {
        var removedLines = Array<Array<Block>>()
        for var row = NumRows - 1; row > 0; row--
        {
            var rowOfBlocks = Array<Block>()
            // We use a for loop which iterates from 0 all the way up to, but not including NumColumns; 
            // therefore 0 to 9. This for loop adds every block in a given row to a local array variable 
            // named rowOfBlocks. If it ends up with a full set - 10 blocks in total - it counts that as a 
            // removed line and adds it to the return variable.
            for column in 0..<NumColumns
            {
                if let block = blockArray[column, row]
                {
                    rowOfBlocks.append(block)
                }
            }
            if rowOfBlocks.count == NumColumns
            {
                removedLines.append(rowOfBlocks)
                for block in rowOfBlocks
                {
                    blockArray[block.column, block.row] = nil
                }
            }
        }
        
        // We check and see if we recovered any lines at all, if not, we return empty arrays immediately.
        if removedLines.count == 0
        {
            return ([], [])
        }
        // We add points to the player's score based on the number of lines they've created and their level. 
        // If their points exceed their level times 1000, they level up and our delegate is informed.
        let pointsEarned = removedLines.count * PointsPerLine * level
        score += pointsEarned
        if score >= level * LevelThreshold
        {
            level += 1
            delegate?.gameDidLevelUp(self)
        }
        
        var fallenBlocks = Array<Array<Block>>()
        for column in 0..<NumColumns
        {
            var fallenBlocksArray = Array<Block>()
            // We do something a bit murky-looking. Starting in the left-most column and immediately above 
            // the bottom-most removed line, we count upwards towards the top of the game board. As we do 
            // so, we take each remaining block we find on the game board and lower it as far as possible. 
            // fallenBlocks is an array of arrays, each sub-array is filled with blocks that fell to a new 
            // position as a result of the user clearing lines beneath them.
            for var row = removedLines[0][0].row - 1; row > 0; row--
            {
                if let block = blockArray[column, row]
                {
                    var newRow = row
                    while (newRow < NumRows - 1 && blockArray[column, newRow + 1] == nil)
                    {
                        newRow++
                    }
                    block.row = newRow
                    blockArray[column, row] = nil
                    blockArray[column, newRow] = block
                    fallenBlocksArray.append(block)
                }
            }
            if fallenBlocksArray.count > 0
            {
                fallenBlocks.append(fallenBlocksArray)
            }
        }
        return (removedLines, fallenBlocks)
    }
    
    func removeAllBlocks() -> Array<Array<Block>>
    {
        var allBlocks = Array<Array<Block>>()
        for row in 0..<NumRows
        {
            var rowOfBlocks = Array<Block>()
            for column in 0..<NumColumns
            {
                if let block = blockArray[column, row]
                {
                    rowOfBlocks.append(block)
                    blockArray[column, row] = nil
                }
            }
            allBlocks.append(rowOfBlocks)
        }
        return allBlocks
    }
}