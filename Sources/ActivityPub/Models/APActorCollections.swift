//
//  APFollowers.swift
//  
//
//  Created by Nikhil Nigade on 17/08/24.
//

import Foundation
import Vapor

// MARK: - APFollowers
public struct APFollowers: APOrderedCollection, Content {
  public typealias Item = APFollower
  
  public let context: URL = APContextURL
  
  public let id: URL
  
  public let type: String = "OrderedCollection"
  
  public let totalItems: UInt
  
  public let current: UInt
  
  public let first: URL
  
  public let last: URL
  /// URL to the actor's root
  public let partOf: URL
  /// Should only be included if page is defined
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

// MARK: - APFollowing
public struct APFollowing: APOrderedCollection, Content {
  public typealias Item = APFollower
  
  public let context: URL = APContextURL
  
  public let id: URL
  
  public let type: String = "OrderedCollection"
  
  public let totalItems: UInt
  
  public let current: UInt
  
  public let first: URL
  
  public let last: URL
  /// URL to the actor's root
  public let partOf: URL
  
  /// Should only be included when page is defined
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

// MARK: - APLiked
/// Specifically a property of actors. This is a collection of Like activities performed by the actor, added to the collection as a side effect of delivery to the outbox.
public struct APLiked: APOrderedCollection, Content {
  public typealias Item = APPost
  
  public let context: URL = APContextURL
  
  public let id: URL
  
  public let type: String = "OrderedCollection"
  
  public let totalItems: UInt
  
  public let current: UInt
  
  public let first: URL
  
  public let last: URL
  /// URL to the actor's root
  public let partOf: URL
  /// Should only be included if page is defined
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

// MARK: - APFollower
public struct APFollower: APItem, Content {
  public let id: URL
  
  public var type = "Person"
  
  public let preferredUsername: String
  
  public let inbox: URL?
  
  public let outbox: URL?
  
  public let icon: [URL]
  
  public init(id: URL, preferredUsername: String, inbox: URL?, outbox: URL?, icon: [URL]) {
    self.id = id
    self.preferredUsername = preferredUsername
    self.inbox = inbox
    self.outbox = outbox
    self.icon = icon
  }
}

// MARK: - APPost
public struct APPost: APItem, Content {
  public let id: URL
  public var type: String = "Note"
  public let url: URL
  public let attributedTo: URL
  public let content: String
  public let published: Date
  public let summary: String
  public let replies: Replies
  public let attachment: [Attachment]
  
  public struct Attachment: Content {
    public let type: String
    public let url: URL
    public let mediaType: String
    public let name: String
    public let blurhash: String
    
    public init(type: String, url: URL, mediaType: String, name: String, blurhash: String) {
      self.type = type
      self.url = url
      self.mediaType = mediaType
      self.name = name
      self.blurhash = blurhash
    }
  }
  
  public struct Replies: Content {
    public let id: URL
    public var type: String = "Collection"
    public let first: APCollectionPage
    
    public init(id: URL, type: String = "Collection", first: APCollectionPage) {
      self.id = id
      self.type = type
      self.first = first
    }
  }
  
  public init(id: URL, type: String = "Note", url: URL, attributedTo: URL, content: String, published: Date, summary: String, replies: Replies, attachment: [Attachment]) {
    self.id = id
    self.type = type
    self.url = url
    self.attributedTo = attributedTo
    self.content = content
    self.published = published
    self.summary = summary
    self.replies = replies
    self.attachment = attachment
  }
}

public struct APCollectionPage: Content {
  public var type: String = "CollectionPage"
  public let next: URL
  public let partOf: URL
  public var items: [String] = []
  
  public init(type: String = "CollectionPage", next: URL, partOf: URL, items: [String] = []) {
    self.type = type
    self.next = next
    self.partOf = partOf
    self.items = items
  }
}
