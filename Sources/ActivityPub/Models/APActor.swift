//
//  APActor.swift
//
//
//  Created by Nikhil Nigade on 16/08/24.
//

import Foundation
import Vapor

public let APContextURL = URL(string: "https://www.w3.org/ns/activitystreams")!

public protocol ActorPublicKey {
  var id: String { get }
  var owner: String { get }
  var publicKeyPem: String { get }
}

public protocol APPublicActor {
  associatedtype PubKey: ActorPublicKey
  
  var publicKey: PubKey { get }
}

// MARK: - APActor
public struct APActor: APPublicActor, Content {
  public enum ActorType: String, Codable {
    case person = "Person"
    case team = "Team"
  }
  
  public var context: [APActorContexts.ContextItem]
  public var type: ActorType
  public var id: URL
  public var following: URL
  public var followers: URL
  public var liked: URL
  public var inbox: URL
  public var outbox: URL
  public var url: URL
  public var preferredUsername: String
  public var name: String
  public var summary: String
  public var icon: Icon?
  public var group: Bool = false
  public var followersCount: UInt = 0
  public var followingCount: UInt = 0
  public var publicKey: APPublicKey
  public var indexable: Bool = true
  public var discoverable: Bool = true
  public var manuallyApprovesFollowers: Bool = false
  public var memorial: Bool = false
  public var endpoints: [String: URL] = [:]
  public var image: Icon?
  public var tag: [URL] = []
  public var attachment: [APActorAttachment] = []
  public var published: Date
  
  public var devices: URL?
  
  public enum CodingKeys: String, CodingKey {
    case context = "@context"
    case type, id, following, followers, liked, inbox, outbox, preferredUsername, name, summary, icon
    case group
    case followersCount, followingCount
    case publicKey
    case indexable, discoverable, manuallyApprovesFollowers, memorial, endpoints
    case url, image, tag, attachment, published
    case devices
  }
  
  public struct APPublicKey: ActorPublicKey, Content {
    public let id: String
    public let owner: String
    public let publicKeyPem: String
    
    public init(id: String, owner: String, publicKeyPem: String) {
      self.id = id
      self.owner = owner
      self.publicKeyPem = publicKeyPem
    }
  }
  
  public struct Icon: Content {
    public let type: String
    public let mediaType: String
    public let url: URL
    
    public init(type: String, mediaType: String, url: URL) {
      self.type = type
      self.mediaType = mediaType
      self.url = url
    }
    
    public init(url: URL) {
      self.type = "Image"
      self.mediaType = "image/\(url.pathExtension.isEmpty ? "jpeg" : url.pathExtension)"
      self.url = url.appendingPathExtension(url.pathExtension.isEmpty ? "jpeg" : "")
    }
  }
  
  public struct APActorAttachment: Content {
    public var type: String = "PropertyValue"
    public let name: String
    public let value: String
  }
}

public struct APActorContexts: Codable {
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
  
  // @TODO: The context uses a static `incise:` prefix
  // Need to figure out how this can be made dynamic 
  public struct ComplexContext: Codable {
    public var manuallyApprovesFollowers: String = "as:manuallyApprovesFollowers"
    public var incise: String = "http://incise.app/ns#"
    public var featured: IDType = IDType(id: "incise:featured")
    public var featuredTags: IDType = IDType(id: "incise:featuredTags")
    public var alsoKnownAs: IDType = IDType(id: "as:alsoKnownAs")
    public var movedTo: IDType = IDType(id: "as:movedTo")
    public var schema: String = "http://schema.org#"
    public var PropertyValue: String = "schema:PropertyValue"
    public var value: String = "schema:value"
    public var discoverable: String = "incise:discoverable"
    public var Device: String = "incise:Device"
    public var Ed25519Signature: String = "incise:Ed25519Signature"
    public var Ed25519Key: String = "incise:Ed25519Key"
    public var Curve25519Key: String = "incise:Curve25519Key"
    public var EncryptedMessage: String = "incise:EncryptedMessage"
    public var publicKeyBase64: String = "incise:publicKeyBase64"
    public var deviceId: String = "incise:deviceId"
    public var claim: IDType = IDType(id: "incise:claim")
    public var fingerprintKey: IDType = IDType(id: "incise:fingerprintKey")
    public var identityKey: IDType = IDType(id: "incise:identityKey")
    public var devices: IDType = IDType(id: "incise:devices")
    public var messageFranking: String = "incise:messageFranking"
    public var messageType: String = "incise:messageType"
    public var cipherText: String = "incise:cipherText"
    public var suspended: String = "incise:suspended"
    public var memorial: String = "incise:memorial"
    public var indexable: String = "incise:indexable"
    public var focalPoint: IDContainer = IDContainer(id: "incise:focalPoint")
    public var followersCount: String = "incise:followersCount"
    public var followingCount: String = "incise:followingCount"
    public var group: String = "incise:group"
    
    public struct IDType: Codable {
      public var id: String
      public var type: String = "@id"
      
      enum CodingKeys: String, CodingKey {
        case id = "@id"
        case type = "@type"
      }
    }
    
    public struct IDContainer: Codable {
      public var container: String = "@list"
      public var id: String
      
      enum CodingKeys: String, CodingKey {
        case id = "@id"
        case container = "@container"
      }
    }
  }
}
