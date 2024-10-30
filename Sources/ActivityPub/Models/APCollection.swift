//
//  APCollection.swift
//  
//
//  Created by Nikhil Nigade on 16/08/24.
//

import Foundation

public protocol APItem: Codable { }

public protocol APCollection: Codable {
  associatedtype Item: APItem
  
  var context: URL { get }
  
  var type: String { get}
  
  var totalItems: UInt { get}
  var current: UInt { get}
  var first: URL { get}
  var last: URL { get}
  /// Should only be included when page is defined
  var items: [Item]? { get}
}

public protocol APOrderedCollection: Codable {
  associatedtype Item: APItem
  
  var context: URL { get }
  
  var type: String { get}
  
  var totalItems: UInt { get}
  var current: UInt { get}
  var first: URL { get}
  var last: URL { get}
  /// Should only be included when page is defined
  var orderedItems: [Item]? { get}
}
