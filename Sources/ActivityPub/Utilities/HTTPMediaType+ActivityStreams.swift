//
//  HTTPMediaType+ActivityStreams.swift
//  ActivityPub
//
//  Created by Nikhil Nigade on 30/10/24.
//

import Foundation
import Vapor

public extension HTTPMediaType {
  static let activityStreams = HTTPMediaType(type: "application", subType: "ld+json", parameters: [
    "profile": "https://www.w3.org/ns/activitystreams"
  ])
  
  static let activityStreamsAlt = HTTPMediaType(type: "application", subType: "jrd+json", parameters: [
    "charset": "utf-8"
  ])
  
  static let activityJSON = HTTPMediaType(type: "application", subType: "activity+json", parameters: [
    "charset": "utf-8"
  ])
}
