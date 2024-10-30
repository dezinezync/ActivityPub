//
//  APActivity.swift
//  
//
//  Created by Nikhil Nigade on 22/08/24.
//

import Foundation
import Vapor

public protocol APActivityResponse: Content, AsyncResponseEncodable {
  var context: [String] { get }
  var id: String { get }
  var type: APActivity.ActivityType { get }
  var actor: String { get }
  var object: Either<ActivityObject, URL> { get }
}

extension APActivityResponse {
  public func encodeResponse(for request: Request) async throws -> Response {
    let encoder = try ContentConfiguration.global.requireEncoder(for: .activityJSON)
    var headers = HTTPHeaders()
    var byteBuffer = ByteBuffer()
    
    try encoder.encode(self, to: &byteBuffer, headers: &headers)

    headers.remove(name: .contentType)
    headers.add(name: .contentType, value: "application/activity+json")
    return Response(status: .ok, headers: headers, body: Response.Body(buffer: byteBuffer))
  }
}

// Nested structure for the "object" part of the JSON.
public struct ActivityObject: Content {
  let id: String
  let type: APActivity.ActivityType
  let actor: String
  let object: String
}

// MARK: - APActivity
public struct APActivity: Content {
  public enum ActivityType: String, Codable {
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
  
  public struct Object: Content {
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
  }
  
  public struct Tag: Content {
    public var type: String
    public var href: URL
    public var name: String
  }
  
  public struct Replies: Content {
    public var id: String
    public var type: String
    public var first: First
  }
  
  public struct First: Content {
    public var type: String
    public var next: URL
    public var partOf: URL
    public var items: [String]
  }
  
  public struct Signature: Content {
    public var type: String
    public var creator: URL
    public var created: Date
    public var signatureValue: String
  }
}

// MARK: - Tombstone
public struct Tombstone: Content {
  public let id: String
  public let type: APActivity.ActivityType
  public let atomUri: String?
}

// MARK: - APActivityContexts
public struct APActivityContexts: Codable {
  public var items: [ContextItem]
  
  public enum ContextItem: Codable {
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

  public struct ComplexContext: Codable {
    public var ostatus: String = "http://ostatus.org#"
    public var atomUri: String? = "ostatus:atomUri"
    public var inReplyToAtomUri: String? = "ostatus:inReplyToAtomUri"
    public var conversation: String? = "ostatus:conversation"
    public var sensitive: String? = "as:sensitive"
    public var toot: String?
    public var votersCount: String?
  }
}
