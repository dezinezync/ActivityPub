//
//  APWebFingerProfile.swift
//  ActivityPub
//
//  Created by Nikhil Nigade on 30/10/24.
//

import Vapor

public struct APWebFingerProfile: Content {
  public var subject: String
  public var aliases: [String]
  public var links: [Link]
  
  // Structure to represent each link in the "links" array of the JSON.
  public struct Link: Content {
    public var rel: String
    public var type: String?
    public var href: String?
    public var template: String?
  }
}
