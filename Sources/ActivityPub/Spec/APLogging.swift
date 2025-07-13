//
//  APLogging.swift
//  ActivityPub
//
//  Created by Nikhil Nigade on 13/07/25.
//

import Foundation

public protocol APLogging {
  @inlinable func info(_ message: @autoclosure () -> any ExpressibleByStringLiteral,
                       metadata: @autoclosure () -> (any ExpressibleByStringLiteral)?,
                       file: String,
                       function: String,
                       line: UInt)
  
  @inlinable func warning(_ message: @autoclosure () -> any ExpressibleByStringLiteral,
                          metadata: @autoclosure () -> (any ExpressibleByStringLiteral)?,
                          file: String,
                          function: String,
                          line: UInt)
  
  @inlinable func error(_ message: @autoclosure () -> any ExpressibleByStringLiteral,
                        metadata: @autoclosure () -> (any ExpressibleByStringLiteral)?,
                        file: String,
                        function: String,
                        line: UInt)
}
