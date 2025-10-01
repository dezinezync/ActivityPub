//
//  APUtilities.swift
//  
//
//  Created by Nikhil Nigade on 28/10/24.
//

import Foundation
import NIOHTTP1
import NIOCore
#if canImport(Network)
import Network
#endif

/// Fetches the actor profile given the actor URL.
///
/// This is a three  step process:
/// 1. First, the host-meta URL is queried on the host, to fetch the webfinger URL of the host.
/// 1. Then, the webfinger URL is queried on the host, to fetch the actual profile of the user.
/// 2. Then based on the response in 1, the activity stream URL is fetched.
/// - Parameters:
///   - actorURL: the URL to the actor
///   - client: an instance conforming to `APNetworkingRequest` to use for making external requests.
///   - decoder: the decoder to use for the response, uses `JSONDecoder` by default.
///   - cacheProvider: optional cache provider
/// - Returns: instance of an `APPublicActor` which has `instance.publicKey`
public func fetchActorProfile(from actorURL: URL, using req: APNetworkingRequest, decoder: JSONDecoder? = nil, cacheProvider: APCacheProvider?) async throws -> (any APPublicActor) {
  // We allow this to throw and not catch it as this can fail, but the rest of our routine can continue
  if let cached = try? await cacheProvider?.getCachedActorProfile(for: actorURL.absoluteString) {
    return cached
  }
  
  guard let hostScheme = actorURL.scheme,
        let hostHost = actorURL.host else {
    throw APAbortError(.badRequest, reason: "Invalid actor URL")
  }
  
  let hostPort = actorURL.port ?? 443
  
  guard let hostMetaURL = hostPort == 80 || hostPort == 443
          ? URL(string: "\(hostScheme)://\(hostHost)/.well-known/host-meta")
          : URL(string: "\(hostScheme)://\(hostHost):\(hostPort)/.well-known/host-meta") else {
    throw APAbortError(.internalServerError, reason: "Failed to form host meta URL for actor URL \(actorURL)")
  }
  
  let hostMetaRes = try await req.get(hostMetaURL, headers: HTTPHeaders([]))
  
  guard hostMetaRes.0.status.code <= 299,
        let hostMetaBody = hostMetaRes.1 else {
    throw APAbortError(.badRequest, reason: "Received invalid response from host for actor URL \(actorURL) when fetching host-meta information.")
  }
  
  // Since we expect a very strict format here, we forego implementing
  // an XMLParser and use a simple regular expression to extract the URL.
  let hostMetaString = String(buffer: hostMetaBody)
  
  guard !hostMetaString.isEmpty,
        let expression = try? NSRegularExpression(pattern: #"\<Link\s.+template\=\"(.+\?resource=)\{uri\}\".+"#),
        let match = expression.firstMatch(in: hostMetaString, range: NSRange(location: 0, length: hostMetaString.count)),
        match.numberOfRanges > 1 else {
    throw APAbortError(.internalServerError, reason: "Failed to inspect host-meta response for actor URL \(actorURL)")
  }
  
  let matchedRange = match.range(at: 1)
  
  let startIndex = hostMetaString.index(hostMetaString.startIndex, offsetBy: matchedRange.location)
  let endIndex = hostMetaString.index(hostMetaString.startIndex, offsetBy: matchedRange.location + matchedRange.length)
  
  let hostMetaURI = hostMetaString[startIndex..<endIndex]
  
  // Strip the prefixed "@" if one exists else some server implementations may respond with a 404 response
  let actorName = actorURL.path.split(separator: "/").last!.replacingOccurrences(of: "@", with: "")
  
  guard let webFingerURL = URL(string: "\(hostMetaURI)acct:\(actorName)@\(actorURL.host!)") else {
    throw APAbortError(.internalServerError, reason: "Failed to form webfinger URL for base: \(hostMetaURI) and actor URL \(actorURL)")
  }
  
  #if canImport(Network)
  // Disallow multi-cast and loopback addresses on the local system.
  //
  // This may sometimes cause an infinite recursion on misconfigured systems.
  if let ipv4Address = IPv4Address(webFingerURL.host!),
     ipv4Address.isLoopback || ipv4Address.isMulticast {
    throw APAbortError(.internalServerError, reason: "Loopback/Multicast address for remote in \(webFingerURL), exiting")
  }

  if let ipv6Address = IPv6Address(webFingerURL.host!),
     ipv6Address.isLoopback || ipv6Address.isMulticast {
    throw APAbortError(.internalServerError, reason: "Loopback/Multicast address for remote in \(webFingerURL), exiting")
  }
  #endif
  
  req.logger.info("WebFinger: \(webFingerURL)")
  
  let webFingerRes = try await req.get(webFingerURL, headers: HTTPHeaders([
    ("Accept", JSON_LD_HEADER)
  ]))
  
  guard webFingerRes.0.status.code < 299,
        let resData = webFingerRes.1 else {
    throw APAbortError(webFingerRes.0.status)
  }
  
  let decoderToUse = decoder ?? JSONDecoder()
  
  let webFingerResult = try decoderToUse.decode(APWebFingerProfile.self, from: resData)
  
  guard let profilePath = webFingerResult.links.first(where: { $0.type == "application/activity+json" })?.href else {
    throw APAbortError(.notFound, reason: "The actor profile URL could not be fetched from \(hostHost)")
  }
  
  req.logger.info("Fetching actor profile for \(profilePath)")
  
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
  
  // We allow this to throw and not catch it as this can fail, but our overall routine has completed successfully
  try? await cacheProvider?.cacheActorProfile(profile: actor, uri: actorURL.absoluteString)
  
  return actor
}
