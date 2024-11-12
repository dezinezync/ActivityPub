//
//  APUtilities.swift
//  
//
//  Created by Nikhil Nigade on 28/10/24.
//

import Vapor

/// Fetches the actor profile given the actor URL.
///
/// This is a two  step process:
/// 1. First, the webfinger URL is queried on the domain, to fetch the actual profile of the user.
/// 2. Then based on the response in 1, the activity stream URL is fetched.
/// - Parameters:
///   - actorURL: the URL to the actor
///   - client: the `Request.Client` instance to use for making external requests.
/// - Returns: instance of an `APPublicActor` which has `instance.publicKey`
public func fetchActorProfile(from actorURL: URI, using req: Request) async throws -> (any APPublicActor) {
  #if DEBUG
  let webFingerURI = URI(string: "\(actorURL.scheme!)://\(actorURL.host!)\(actorURL.host == "localhost" ? ":8080" : "")/.well-known/webfinger?resource=acct:\(actorURL.path.split(separator: "/").last!)@\(actorURL.host!)\(actorURL.host == "localhost" ? ":8080" : "")")
  #else
  if actorURL.host?.contains("localhost") == true ||
      actorURL.host?.contains("127.0.0.1") == true {
    throw Abort(.notImplemented, reason: "Cannot use loopback address, please check the actor URL")
  }
  let webFingerURI = URI(string: "\(actorURL.scheme!)://\(actorURL.host!)\(actorURL.host == "localhost" ? ":8080" : "")/.well-known/webfinger?resource=acct:\(actorURL.path.split(separator: "/").last!)@\(actorURL.host!)")
  #endif
  
  req.logger.info("WebFinger: \(webFingerURI)")
  
  let webFingerRes = try await req.client.get(webFingerURI, headers: HTTPHeaders([
    ("Accept", JSON_LD_HEADER)
  ]))
  
  guard webFingerRes.status.code < 299 else {
    throw Abort(webFingerRes.status)
  }
  
  let webFingerResult = try webFingerRes.content.decode(APWebFingerProfile.self)
  
  guard let profilePath = webFingerResult.links.first(where: { $0.type == "application/activity+json" })?.href else {
    throw Abort(.notFound, reason: "The actor profile URL could not be fetched from \(webFingerURI.host!)")
  }
  
  req.logger.info("Fetching actor profile for \(profilePath)")
  
  let res = try await req.client.get(URI(string: profilePath), headers: HTTPHeaders([
    ("Accept", JSON_LD_HEADER)
  ]))
  
  guard res.status.code < 299 else {
    throw Abort(res.status)
  }
  
  let actor: any APPublicActor
  
  do {
    let profile = try res.content.decode(APActor.self)
    actor = profile
  }
  catch is DecodingError {
    // check if it's a mastodon profile
    let profile = try res.content.decode(APMastodonProfile.self)
    actor = profile
  }
  catch {
    throw error
  }
  
  return actor
}
