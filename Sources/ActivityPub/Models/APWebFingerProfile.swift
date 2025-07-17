//
//  APWebFingerProfile.swift
//  ActivityPub
//
//  Created by Nikhil Nigade on 30/10/24.
//

import Foundation

public struct APWebFingerProfile: APContent, Sendable {
  public var subject: String
  public var aliases: [String]
  public var links: [Link]
  
  // Structure to represent each link in the "links" array of the JSON.
  public struct Link: APContent, Sendable {
    public var rel: String
    public var type: String?
    public var href: String?
    public var template: String?
    
    public init(rel: String, type: String? = nil, href: String? = nil, template: String? = nil) {
      self.rel = rel
      self.type = type
      self.href = href
      self.template = template
    }
  }
  
  public init(subject: String, aliases: [String], links: [Link]) {
    self.subject = subject
    self.aliases = aliases
    self.links = links
  }
}
