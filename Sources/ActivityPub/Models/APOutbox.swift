//
//  APOutbox.swift
//  
//
//  Created by Nikhil Nigade on 16/08/24.
//

import Foundation
import Vapor

// MARK: - APOutbox
/// The outbox stream contains activities the user has published, subject to the ability of the requestor to retrieve the activity (that is, the contents of the outbox are filtered by the permissions of the person reading it)
public struct APOutbox: APOrderedCollection, Content, Sendable {
  public typealias Item = APPostContainer
  
  public let context: URL = APContextURL
  
  public let id: URL
  
  public let type: String = "OrderedCollection"
  
  public let totalItems: UInt
  
  public let current: UInt
  
  public let first: URL
  
  public let last: URL
  /// URL to the actor's root
  public let partOf: URL
  
  /// Should only included when page is defined
  public let orderedItems: [Item]?
  
  public enum CodingKeys: String, CodingKey {
    case context = "@context"
    case id, type, totalItems, current, first, last, partOf, orderedItems
  }
  
  public init(id: URL, totalItems: UInt, current: UInt, first: URL, last: URL, partOf: URL, orderedItems: [Item]?) {
    self.id = id
    self.totalItems = totalItems
    self.current = current
    self.first = first
    self.last = last
    self.partOf = partOf
    self.orderedItems = orderedItems
  }
}

public struct APPostContainer: APItem, Content, Sendable {
  public var context: [String] = ["https://www.w3.org/ns/activitystreams"]
  public let id: String
  public var type = "Create"
  public let actor: String
  public let published: Date
  public let to: [String]
  public let cc: [String]
  public let object: APPost
  
  public init(id: String, actor: String, published: Date, to: [String], cc: [String], object: APPost) {
    self.id = id
    self.actor = actor
    self.published = published
    self.to = to
    self.cc = cc
    self.object = object
  }
}
