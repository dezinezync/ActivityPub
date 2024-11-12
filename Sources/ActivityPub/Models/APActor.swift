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
  public var preferredUsername: String?
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
    
    public init(type: String = "PropertyValue", name: String, value: String) {
      self.type = type
      self.name = name
      self.value = value
    }
  }
  
  public init(context: [APActorContexts.ContextItem], type: APActor.ActorType, id: URL, following: URL, followers: URL, liked: URL, inbox: URL, outbox: URL, url: URL, preferredUsername: String, name: String, summary: String, icon: APActor.Icon? = nil, group: Bool = false, followersCount: UInt = 0, followingCount: UInt = 0, publicKey: APActor.APPublicKey, indexable: Bool = true, discoverable: Bool = true, manuallyApprovesFollowers: Bool = false, memorial: Bool = false, endpoints: [String : URL] = [:], image: APActor.Icon? = nil, tag: [URL] = [], attachment: [APActor.APActorAttachment] = [], published: Date, devices: URL? = nil) {
    self.context = context
    self.type = type
    self.id = id
    self.following = following
    self.followers = followers
    self.liked = liked
    self.inbox = inbox
    self.outbox = outbox
    self.url = url
    self.preferredUsername = preferredUsername
    self.name = name
    self.summary = summary
    self.icon = icon
    self.group = group
    self.followersCount = followersCount
    self.followingCount = followingCount
    self.publicKey = publicKey
    self.indexable = indexable
    self.discoverable = discoverable
    self.manuallyApprovesFollowers = manuallyApprovesFollowers
    self.memorial = memorial
    self.endpoints = endpoints
    self.image = image
    self.tag = tag
    self.attachment = attachment
    self.published = published
    self.devices = devices
  }
}

public struct APActorContexts: Codable {
  public var items: [ContextItem]
  
  public init(items: [APActorContexts.ContextItem]) {
    self.items = items
  }
  
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
      
      public init(id: String, type: String = "@id") {
        self.id = id
        self.type = type
      }
    }
    
    public struct IDContainer: Codable {
      public var container: String = "@list"
      public var id: String
      
      enum CodingKeys: String, CodingKey {
        case id = "@id"
        case container = "@container"
      }
      
      public init(container: String = "@list", id: String) {
        self.container = container
        self.id = id
      }
    }
    
    public init(
      manuallyApprovesFollowers: String = "as:manuallyApprovesFollowers",
      incise: String = "http://incise.app/ns#",
      featured: APActorContexts.ComplexContext.IDType = IDType(id: "incise:featured"),
      featuredTags: APActorContexts.ComplexContext.IDType = IDType(id: "incise:featuredTags"),
      alsoKnownAs: APActorContexts.ComplexContext.IDType = IDType(id: "as:alsoKnownAs"),
      movedTo: APActorContexts.ComplexContext.IDType = IDType(id: "as:movedTo"),
      schema: String = "http://schema.org#",
      PropertyValue: String = "schema:PropertyValue",
      value: String = "schema:value",
      discoverable: String = "incise:discoverable",
      Device: String = "incise:Device",
      Ed25519Signature: String = "incise:Ed25519Signature",
      Ed25519Key: String = "incise:Ed25519Key",
      Curve25519Key: String = "incise:Curve25519Key",
      EncryptedMessage: String = "incise:EncryptedMessage",
      publicKeyBase64: String = "incise:publicKeyBase64",
      deviceId: String = "incise:deviceId",
      claim: APActorContexts.ComplexContext.IDType = IDType(id: "incise:claim"),
      fingerprintKey: APActorContexts.ComplexContext.IDType = IDType(id: "incise:fingerprintKey"),
      identityKey: APActorContexts.ComplexContext.IDType = IDType(id: "incise:identityKey"),
      devices: APActorContexts.ComplexContext.IDType = IDType(id: "incise:devices"),
      messageFranking: String = "incise:messageFranking",
      messageType: String = "incise:messageType",
      cipherText: String = "incise:cipherText",
      suspended: String = "incise:suspended",
      memorial: String = "incise:memorial",
      indexable: String = "incise:indexable",
      focalPoint: APActorContexts.ComplexContext.IDContainer = IDContainer(id: "incise:focalPoint"),
      followersCount: String = "incise:followersCount",
      followingCount: String = "incise:followingCount",
      group: String = "incise:group"
    ) {
      self.manuallyApprovesFollowers = manuallyApprovesFollowers
      self.incise = incise
      self.featured = featured
      self.featuredTags = featuredTags
      self.alsoKnownAs = alsoKnownAs
      self.movedTo = movedTo
      self.schema = schema
      self.PropertyValue = PropertyValue
      self.value = value
      self.discoverable = discoverable
      self.Device = Device
      self.Ed25519Signature = Ed25519Signature
      self.Ed25519Key = Ed25519Key
      self.Curve25519Key = Curve25519Key
      self.EncryptedMessage = EncryptedMessage
      self.publicKeyBase64 = publicKeyBase64
      self.deviceId = deviceId
      self.claim = claim
      self.fingerprintKey = fingerprintKey
      self.identityKey = identityKey
      self.devices = devices
      self.messageFranking = messageFranking
      self.messageType = messageType
      self.cipherText = cipherText
      self.suspended = suspended
      self.memorial = memorial
      self.indexable = indexable
      self.focalPoint = focalPoint
      self.followersCount = followersCount
      self.followingCount = followingCount
      self.group = group
    }
  }
}
