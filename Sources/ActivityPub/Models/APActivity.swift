//
//  APActivity.swift
//  
//
//  Created by Nikhil Nigade on 22/08/24.
//

import Foundation

public protocol APActivityResponse: APContent {
  var context: [String] { get }
  var id: String { get }
  var type: APActivity.ActivityType { get }
  var actor: String { get }
  var object: Either<ActivityObject, URL> { get }
}

// Nested structure for the "object" part of the JSON.
public struct ActivityObject: APContent, Sendable {
  let id: String
  let type: APActivity.ActivityType
  let actor: String
  let object: String
  
  public init(id: String, type: APActivity.ActivityType, actor: String, object: String) {
    self.id = id
    self.type = type
    self.actor = actor
    self.object = object
  }
}

// MARK: - APActivity
public struct APActivity: APContent, Sendable {
  public enum ActivityType: String, Codable, Sendable {
    case comment = "Comment"
    case note = "Note"
    case create = "Create"
    case like = "Like"
    case follow = "Follow"
    case block = "Block"
    case undo = "Undo"
    case delete = "Delete"
    case tombstone = "Tombstone"
    /// sent as reply for a "follow" activity
    case accept = "Accept"
    case image = "Image"
    /// sent for boosts
    case announce = "Announce"
  }
  
  public var context: Either<String, [APActivityContexts.ContextItem]> = .right([
    .string("https://www.w3.org/ns/activitystreams"),
    .string("https://w3id.org/security/v1")
  ])
  public var id: String
  public var type: ActivityType
  public var actor: URL
  public var published: Date?
  public var to: [URL]?
  public var cc: [URL]?
  public var object: Either<Object, Either<Tombstone, URL>>
  public var signature: Signature?
  
  public enum CodingKeys: String, CodingKey {
    case context = "@context"
    case id
    case type
    case actor
    case published
    case to
    case cc
    case object
    case signature
  }
  
  public struct Object: APContent, Sendable {
    public var id: String
    public var type: ActivityType
    public var summary: String?
    public var inReplyTo: String?
    public var published: Date?
    public var url: URL?
    public var attributedTo: URL?
    public var to: [URL]?
    public var cc: [URL]?
    public var sensitive: Bool?
    public var atomUri: URL?
    public var inReplyToAtomUri: URL?
    public var conversation: String?
    public var content: String?
    public var contentMap: [String: String]?
    public var attachment: [APPost.Attachment]?
    public var tag: [Tag]?
    public var replies: Replies?
    // following two items used for `Undo` activity
    public var actor: URL?
    public var object: URL?
    
    public init(id: String, type: APActivity.ActivityType, summary: String? = nil, inReplyTo: String? = nil, published: Date? = nil, url: URL? = nil, attributedTo: URL? = nil, to: [URL]? = nil, cc: [URL]? = nil, sensitive: Bool? = nil, atomUri: URL? = nil, inReplyToAtomUri: URL? = nil, conversation: String? = nil, content: String? = nil, contentMap: [String : String]? = nil, attachment: [APPost.Attachment]? = nil, tag: [APActivity.Tag]? = nil, replies: APActivity.Replies? = nil, actor: URL? = nil, object: URL? = nil) {
      self.id = id
      self.type = type
      self.summary = summary
      self.inReplyTo = inReplyTo
      self.published = published
      self.url = url
      self.attributedTo = attributedTo
      self.to = to
      self.cc = cc
      self.sensitive = sensitive
      self.atomUri = atomUri
      self.inReplyToAtomUri = inReplyToAtomUri
      self.conversation = conversation
      self.content = content
      self.contentMap = contentMap
      self.attachment = attachment
      self.tag = tag
      self.replies = replies
      self.actor = actor
      self.object = object
    }
  }
  
  public struct Tag: APContent, Sendable {
    public var type: String
    public var href: URL
    public var name: String
    
    public init(type: String, href: URL, name: String) {
      self.type = type
      self.href = href
      self.name = name
    }
  }
  
  public struct Replies: APContent, Sendable {
    public var id: String
    public var type: String
    public var first: First
    
    public init(id: String, type: String, first: APActivity.First) {
      self.id = id
      self.type = type
      self.first = first
    }
  }
  
  public struct First: APContent, Sendable {
    public var type: String
    public var next: URL
    public var partOf: URL
    public var items: [String]
    
    public init(type: String, next: URL, partOf: URL, items: [String]) {
      self.type = type
      self.next = next
      self.partOf = partOf
      self.items = items
    }
  }
  
  public struct Signature: APContent, Sendable {
    public var type: String
    public var creator: URL
    public var created: Date
    public var signatureValue: String
    
    public init(type: String, creator: URL, created: Date, signatureValue: String) {
      self.type = type
      self.creator = creator
      self.created = created
      self.signatureValue = signatureValue
    }
  }
  
  public init(context: Either<String, [APActivityContexts.ContextItem]> = .right([
    .string("https://www.w3.org/ns/activitystreams"),
    .string("https://w3id.org/security/v1")
  ]), id: String, type: APActivity.ActivityType, actor: URL, published: Date? = nil, to: [URL]? = nil, cc: [URL]? = nil, object: Either<APActivity.Object, Either<Tombstone, URL>>, signature: APActivity.Signature? = nil) {
    self.context = context
    self.id = id
    self.type = type
    self.actor = actor
    self.published = published
    self.to = to
    self.cc = cc
    self.object = object
    self.signature = signature
  }
}

// MARK: - Tombstone
public struct Tombstone: APContent, Sendable {
  public let id: String
  public let type: APActivity.ActivityType
  public let atomUri: String?
}

// MARK: - APActivityContexts
public struct APActivityContexts: Codable, Sendable {
  public var items: [ContextItem]
  
  public enum ContextItem: Codable, Sendable {
    case string(String)
    case complex(ComplexContext)
    
    public init(from decoder: Decoder) throws {
      if let stringValue = try? decoder.singleValueContainer().decode(String.self) {
        self = .string(stringValue)
      } else {
        self = .complex(try ComplexContext(from: decoder))
      }
    }
    
    public func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      switch self {
      case .string(let stringValue):
        try container.encode(stringValue)
      case .complex(let complexValue):
        try container.encode(complexValue)
      }
    }
  }

  public struct ComplexContext: Codable, Sendable {
    public var ostatus: String = "http://ostatus.org#"
    public var atomUri: String? = "ostatus:atomUri"
    public var inReplyToAtomUri: String? = "ostatus:inReplyToAtomUri"
    public var conversation: String? = "ostatus:conversation"
    public var sensitive: String? = "as:sensitive"
    public var toot: String?
    public var votersCount: String?
  }
}
