//
//  Array2D.swift
//  Swiftris
//
//  Created by Andrés Ruiz on 9/25/14.
//  Copyright (c) 2014 Andrés Ruiz. All rights reserved.
//

import Foundation


// Generic arrays in Swift are actually of type struct, not class but we need a class in this case since
// class objects are passed by reference whereas structures are passed by value (copied).
// Our game logic will require a single copy of this data structure to persist across the entire game.
class Array2D<T>
{
    let columns: Int
    let rows: Int
    
    // Underlying data structure which maintains references to our objects. It's declared with type <T?>
    var array: Array<T?>
    
    init( columns: Int, rows: Int )
    {
        self.columns = columns
        self.rows = rows
        
        // We instantiate our internal array structure with a size of rows * columns.
        array = Array<T?>( count: rows * columns, repeatedValue: nil )
    }
    
    // We create a custom subscript for Array2D. We want to have a subscript capable of supporting 
    // array[column, row]
    subscript( column: Int, row: Int ) -> T?
    {
        get
        {
            return array[ (row*columns)+column ]
        }
        set( newValue )
        {
            array[ (row*columns)+column ] = newValue
        }
    }
}