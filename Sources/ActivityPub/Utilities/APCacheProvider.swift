//
//  APCacheProvider.swift
//  ActivityPub
//
//  Created by Nikhil Nigade on 01/10/25.
//

import Foundation

public protocol APCacheProvider {
  func getCachedActorProfile(for uri: String) async throws -> (any APPublicActor)?
  
  func cacheActorProfile(profile: any APPublicActor, uri: String) async throws
}
