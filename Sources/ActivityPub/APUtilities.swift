//
//  APUtilities.swift
//  
//
//  Created by Nikhil Nigade on 28/10/24.
//

import Foundation
import NIOHTTP1
import NIOCore

/// Fetches the actor profile given the actor URL.
///
/// This is a two  step process:
/// 1. First, the webfinger URL is queried on the domain, to fetch the actual profile of the user.
/// 2. Then based on the response in 1, the activity stream URL is fetched.
/// - Parameters:
///   - actorURL: the URL to the actor
///   - client: the `Request.Client` instance to use for making external requests.
///   - decoder: the decoder to use for the response, uses `JSONDecoder` by default.
/// - Returns: instance of an `APPublicActor` which has `instance.publicKey`
public func fetchActorProfile(from actorURL: URL, using req: APNetworkingRequest, decoder: JSONDecoder? = nil) async throws -> (any APPublicActor) {
  // @TODO: Must check the actorURL's server with the resource path for the webfinger request instead of assuming it's at /.well-known/webfinger
  #if DEBUG
  let webFingerURI = URL(string:"\(actorURL.scheme!)://\(actorURL.host!)\(actorURL.host == "localhost" ? ":8080" : "")/.well-known/webfinger?resource=acct:\(actorURL.path.split(separator: "/").last!)@\(actorURL.host!)\(actorURL.host == "localhost" ? ":8080" : "")")!
  #else
  if actorURL.host?.contains("localhost") == true ||
      actorURL.host?.contains("127.0.0.1") == true {
    throw Abort(.notImplemented, reason: "Cannot use loopback address, please check the actor URL")
  }
  let webFingerURI = URL(string: "\(actorURL.scheme!)://\(actorURL.host!)\(actorURL.host == "localhost" ? ":8080" : "")/.well-known/webfinger?resource=acct:\(actorURL.path.split(separator: "/").last!)@\(actorURL.host!)")!
  #endif
  
  req.logger.info("WebFinger: \(webFingerURI)", metadata: nil, file: #file, function: #function, line: #line)
  
  let webFingerRes = try await req.get(webFingerURI, headers: HTTPHeaders([
    ("Accept", JSON_LD_HEADER)
  ]))
  
  guard webFingerRes.0.status.code < 299,
        let resData = webFingerRes.1 else {
    throw APAbortError(webFingerRes.0.status)
  }
  
  let decoderToUse = decoder ?? JSONDecoder()
  
  let webFingerResult = try decoderToUse.decode(APWebFingerProfile.self, from: resData)
  
  guard let profilePath = webFingerResult.links.first(where: { $0.type == "application/activity+json" })?.href else {
    throw APAbortError(.notFound, reason: "The actor profile URL could not be fetched from \(webFingerURI.host!)")
  }
  
  req.logger.info("Fetching actor profile for \(profilePath)", metadata: nil, file: #file, function: #function, line: #line)
  
  let res = try await req.get(profilePath, headers: HTTPHeaders([
    ("Accept", JSON_LD_HEADER)
  ]))
  
  guard res.0.status.code < 299,
        let resData = res.1 else {
    throw APAbortError(res.0.status)
  }
  
  let actor: any APPublicActor
  
  do {
    let profile = try decoderToUse.decode(APActor.self, from: resData)
    actor = profile
  }
  catch is DecodingError {
    // check if it's a mastodon profile
    let profile = try decoderToUse.decode(APMastodonProfile.self, from: resData)
    actor = profile
  }
  catch {
    throw error
  }
  
  return actor
}
