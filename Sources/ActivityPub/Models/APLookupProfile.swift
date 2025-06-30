//
//  APLookupProfile.swift
//  ActivityPub
//
//  Created by Nikhil Nigade on 30/06/25.
//

import Foundation
import Vapor

/// Represents a user account from a Mastodon-compatible API
public struct APLookupProfile: Content {
  /// The unique identifier of the account
  public let id: String
  
  /// The account's username, not including domain
  public let username: String
  
  /// The account username as it should be addressed
  public let acct: String
  
  /// The display name of the account
  public let displayName: String
  
  /// Whether the account is locked (private)
  public let locked: Bool
  
  /// Whether the account is a bot
  public let bot: Bool
  
  /// Whether the account is discoverable
  public let discoverable: Bool
  
  /// Whether the account is allowed to be indexed
  public let indexable: Bool
  
  /// Whether the account represents a group
  public let group: Bool
  
  /// When the account was created
  public let createdAt: Date
  
  /// The account's bio/description (HTML)
  public let note: String
  
  /// The account's profile page URL
  public let url: String
  
  /// The account's ActivityPub URI
  public let uri: String
  
  /// URL to the account's avatar image
  public let avatar: String
  
  /// URL to the account's static avatar image
  public let avatarStatic: String
  
  /// URL to the account's header image
  public let header: String?
  
  /// URL to the account's static header image
  public let headerStatic: String?
  
  /// Number of followers the account has
  public let followersCount: Int
  
  /// Number of accounts the account is following
  public let followingCount: Int
  
  /// Number of statuses the account has posted
  public let statusesCount: Int
  
  /// When the account last posted a status
  public let lastStatusAt: String?
  
  /// Whether collections are hidden
  public let hideCollections: Bool
  
  /// Whether the account should be hidden from search results
  public let noindex: Bool
  
  /// Additional metadata fields displayed on profile
  public let fields: [Field]
  
  /// Represents a profile metadata field
  public struct Field: Codable {
    /// The label of the field
    public let name: String
    
    /// The value of the field (HTML)
    public let value: String
    
    /// When the field value was verified, if applicable
    public let verifiedAt: Date?
    
    public  enum CodingKeys: String, CodingKey {
      case name, value
      case verifiedAt = "verified_at"
    }
  }
  
  public enum CodingKeys: String, CodingKey {
    case id, username, acct, locked, bot, discoverable, indexable, group, note, url, uri, avatar
    case avatarStatic = "avatar_static"
    case header
    case headerStatic = "header_static"
    case followersCount = "followers_count"
    case followingCount = "following_count"
    case statusesCount = "statuses_count"
    case lastStatusAt = "last_status_at"
    case hideCollections = "hide_collections"
    case noindex, fields
    case displayName = "display_name"
    case createdAt = "created_at"
  }
  
  public init(id: String, username: String, acct: String, displayName: String, locked: Bool, bot: Bool, discoverable: Bool, indexable: Bool, group: Bool, createdAt: Date, note: String, url: String, uri: String, avatar: String, avatarStatic: String, header: String?, headerStatic: String?, followersCount: Int, followingCount: Int, statusesCount: Int, lastStatusAt: String?, hideCollections: Bool, noindex: Bool, fields: [Field]) {
    self.id = id
    self.username = username
    self.acct = acct
    self.displayName = displayName
    self.locked = locked
    self.bot = bot
    self.discoverable = discoverable
    self.indexable = indexable
    self.group = group
    self.createdAt = createdAt
    self.note = note
    self.url = url
    self.uri = uri
    self.avatar = avatar
    self.avatarStatic = avatarStatic
    self.header = header
    self.headerStatic = headerStatic
    self.followersCount = followersCount
    self.followingCount = followingCount
    self.statusesCount = statusesCount
    self.lastStatusAt = lastStatusAt
    self.hideCollections = hideCollections
    self.noindex = noindex
    self.fields = fields
  }
}

public extension APLookupProfile {
  /// Custom date formatter for Mastodon API dates
  static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }()
  
  /// Custom decoder that handles the date formats used by Mastodon API
  static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let dateString = try container.decode(String.self)
      
      // Try ISO8601 format first
      if let date = dateFormatter.date(from: dateString) {
        return date
      }
      
      // Try null date
      if dateString.isEmpty || dateString == "null" {
        return Date(timeIntervalSince1970: 0)
      }
      
      // Try simple date format (YYYY-MM-DD)
      let simpleDateFormatter = DateFormatter()
      simpleDateFormatter.dateFormat = "yyyy-MM-dd"
      if let date = simpleDateFormatter.date(from: dateString) {
        return date
      }
      
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Cannot decode date string \(dateString)"
      )
    }
    return decoder
  }()
}
