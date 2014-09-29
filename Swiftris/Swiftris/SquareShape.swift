//
//  SquareShape.swift
//  Swiftris
//
//  Created by Andrés Ruiz on 9/25/14.
//  Copyright (c) 2014 Andrés Ruiz. All rights reserved.
//

import Foundation

class SquareShape:Shape
{
    /*
    | 0•| 1 |
    | 2 | 3 |
    
    • marks the row/column indicator for the shape
    */
    
    // The square shape will not rotate
    
    // A square shape is the easiest, it will not rotate at all since its shape is identical at every 
    // orientation. Consequently, its bottom blocks will always be the third and fourth block
    override var blockRowColumnPositions: [Orientation: Array<(columnDiff: Int, rowDiff: Int)>]
    {
        return [
            Orientation.Zero: [(0, 0), (1, 0), (0, 1), (1, 1)],
            Orientation.OneEighty: [(0, 0), (1, 0), (0, 1), (1, 1)],
            Orientation.Ninety: [(0, 0), (1, 0), (0, 1), (1, 1)],
            Orientation.TwoSeventy: [(0, 0), (1, 0), (0, 1), (1, 1)]
            ]
    }
    
    // We perform a similar override by providing a dictionary of bottom block arrays. As was stated 
    // earlier, a square shape does not rotate, therefore its bottom-most blocks are consistently the third 
    // and fourth blocks
    override var bottomBlocksForOrientations: [Orientation: Array<Block>]
    {
        return [
            Orientation.Zero:       [blocks[ThirdBlockIdx], blocks[FourthBlockIdx]],
            Orientation.OneEighty:  [blocks[ThirdBlockIdx], blocks[FourthBlockIdx]],
            Orientation.Ninety:     [blocks[ThirdBlockIdx], blocks[FourthBlockIdx]],
            Orientation.TwoSeventy: [blocks[ThirdBlockIdx], blocks[FourthBlockIdx]]
            ]
    }
}