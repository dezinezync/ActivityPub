//
//  APInbox.swift
//  
//
//  Created by Nikhil Nigade on 16/08/24.
//

import Foundation

public struct APInboxItem: APItem, Sendable {
  
}

// MARK: - APInbox
/// The inbox stream contains all activities received by the actor. The server SHOULD filter content according to the requester's permission. In general, the owner of an inbox is likely to be able to access all of their inbox contents.
public struct APInbox: APOrderedCollection, APContent, Sendable {
  public typealias Item = APInboxItem
  
  public let context: URL = APContextURL
  
  public let type: String = "OrderedCollection"
  
  public let totalItems: UInt
  
  public let current: UInt
  
  public let first: URL
  
  public let last: URL
  /// Should only be included if page is defined
  public let orderedItems: [Item]?
  
  public enum CodingKeys: String, CodingKey {
    case context = "@context"
    case type, totalItems, current, first, last, orderedItems
  }
}

