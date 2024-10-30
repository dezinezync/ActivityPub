//
//  APPostCollections.swift
//  
//
//  Created by Nikhil Nigade on 01/09/24.
//

import Foundation
import Vapor

// MARK: - APPostComments
public struct APPostComments: APOrderedCollection, Content {
  public typealias Item = APPostComment
  
  public var context: URL = APContextURL
  
  public let id: URL
  
  public var type: String = "OrderedCollection"
  
  public let totalItems: UInt
  
  public let current: UInt
  
  public let first: URL
  
  public let last: URL
  
  /// URL to the post's root
  public let partOf: URL
  /// Only include if the page is defined
  public let orderedItems: [APPostComment]?
}

// MARK: - APPostComment
public struct APPostComment: APItem, Content {
  public let id: URL
  
  public var type: String = "Note"
  
  public let inReplyTo: URL?
  
  public let published: Date
  
  public let url: URL
  
  /// actor URL
  public let attributedTo: URL
  
  public let to: [String]
  
  public let cc: [String]
  
  public let sensitive: Bool
  
  public let content: String
  
  public let replies: APPost.Replies
  
  public init(id: URL, type: String, inReplyTo: URL?, published: Date, url: URL, attributedTo: URL, to: [String], cc: [String], sensitive: Bool, content: String, replies: APPost.Replies) {
    self.id = id
    self.type = type
    self.inReplyTo = inReplyTo
    self.published = published
    self.url = url
    self.attributedTo = attributedTo
    self.to = to
    self.cc = cc
    self.sensitive = sensitive
    self.content = content
    self.replies = replies
  }
}
