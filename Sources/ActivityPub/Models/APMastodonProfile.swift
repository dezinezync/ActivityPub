//
//  APMastodonProfile.swift
//
//
//  Created by Nikhil Nigade on 31/08/24.
//

import Foundation

public struct APMastodonProfile: APPublicActor, APContent, Sendable {
  public var preferredUsername: String
  public var endpoints: Endpoints
  public var outbox: String
  public var summary: String
  public var url: String
  public var image: Media?
  public var manuallyApprovesFollowers: Bool?
  public var discoverable: Bool?
  public var icon: Media?
  public var tag: [Tag]?
  public var name: String
  public var featuredTags: String
  public var type: String
  public var followers: String
  public var devices: String?
  public var id: String
  public var indexable: Bool?
  public var publicKey: PublicKey
  public var following: String
  public var memorial: Bool?
  public var published: String
  public var featured: String
  public var attachment: [Attachment]
  public var inbox: String
  
  public struct Endpoints: APContent, Sendable {
    public var sharedInbox: String
  }
  
  public struct Media: APContent, Sendable {
    public var type: String
    public var mediaType: String
    public var url: String
  }
  
  public struct PublicKey: ActorPublicKey, APContent, Sendable {
    public var id: String
    public var owner: String
    public var publicKeyPem: String
  }
  
  public struct Attachment: APContent, Sendable {
    public var type: String
    public var name: String
    public var value: String
  }
  
  public struct TypeIdPair: APContent, Sendable {
    public var type: String
    public var id: String
  }
  
  public struct FocalPoint: APContent, Sendable {
    public var container: String
    public var id: String
  }
  
  public struct Tag: APContent, Sendable {
    public let id: String
    public let type: String
    public let name: String?
    public let updated: Date?
    public let icon: Media?
  }
}
