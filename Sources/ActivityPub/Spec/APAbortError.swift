//
//  APAbortError.swift
//  ActivityPub
//
//  Created by Nikhil Nigade on 13/07/25.
//

import Foundation
import NIOCore
import NIOHTTP1

public struct APAbortError: Error {
  public let status: HTTPResponseStatus
  
  public let reason: String?
  
  public init(status: HTTPResponseStatus, reason: String? = nil) {
    self.status = status
    self.reason = reason
  }
  
  public init(_ status: HTTPResponseStatus, reason: String? = nil) {
    self.status = status
    self.reason = reason
  }
}

extension APAbortError: CustomStringConvertible {
  public var description: String {
    if let reason {
      return "\(status.code) \(status.reasonPhrase): \(reason)"
    }
    else {
      return "\(status.code) \(status.reasonPhrase)"
    }
  }
}
