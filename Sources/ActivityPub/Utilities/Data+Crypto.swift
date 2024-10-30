//
//  Data+Crypto.swift
//  ActivityPub
//
//  Created by Nikhil Nigade on 30/10/24.
//

import Vapor
import _CryptoExtras

public extension Data {
  func sha256Data() -> Data? {
    let digest = SHA256.hash(data: self)
    
    return Data(digest)
  }
}
