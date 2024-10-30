//
//  Either.swift
//  
//
//  Created by Nikhil Nigade on 22/08/24.
//
//  Based on https://github.com/swiftlang/swift/blob/main/stdlib/public/core/EitherSequence.swift

import Foundation

// MARK: - Either
public enum Either<Left, Right> {
  case left(Left)
  case right(Right)
}

// MARK: Codable
extension Either: Codable where Left: Codable, Right: Codable {
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    // Attempt to decode the first type
    if let first = try? container.decode(Left.self) {
      self = .left(first)
    } else if let second = try? container.decode(Right.self) {
      self = .right(second)
    } else {
      let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode Either")
      throw DecodingError.dataCorrupted(context)
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .left(let first):
      try container.encode(first)
    case .right(let second):
      try container.encode(second)
    }
  }
}

// MARK: Initialisers
extension Either {
  internal init(_ left: Left, or other: Right.Type) { self = .left(left) }
  internal init(_ left: Left) { self = .left(left) }
  internal init(_ right: Right) { self = .right(right) }
}

// MARK: Equatable
extension Either: Equatable where Left: Equatable, Right: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case let (.left(l), .left(r)): return l == r
    case let (.right(l), .right(r)): return l == r
    case (.left, .right), (.right, .left): return false
    }
  }
}

// MARK: Hashable
extension Either: Hashable where Left: Hashable, Right: Hashable {
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .left(let first):
      hasher.combine(first)
    case .right(let second):
      hasher.combine(second)
    }
  }
}

// MARK: Comparable
extension Either: Comparable where Left: Comparable, Right: Comparable {
  public static func < (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case let (.left(l), .left(r)): return l < r
    case let (.right(l), .right(r)): return l < r
    case (.left, .right): return true
    case (.right, .left): return false
    }
  }
}

// MARK: Sendable
extension Either: Sendable where Left: Sendable, Right: Sendable { }
