//
//  APFederation.swift
//  ActivityPub
//
//  Created by Nikhil Nigade on 30/10/24.
//

import Foundation
import _CryptoExtras
import NIOCore
import NIOHTTP1
#if canImport(Network)
import Network
#endif

/// **APFederationHost** manages notifying remote ActivityPub servers of new updates from your system.
///
/// This is a sparse implementation of the S2S (server-to-server) spec of ActivityPub.
///
/// In your implementation, you'll only ever need to invoke the `federate(object:to:actoryKeyId:actorPrivateKey:_)` method, however, the `notify(remote:digest:dateHeader:signature:content:request:)` method is also an open implementation should you need to tweak or override it. For most cases, this can be used as-is with no changes.
open class APFederationHost {
  public static let encoder: JSONEncoder = {
    var encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    encoder.keyEncodingStrategy = .useDefaultKeys
    encoder.dataEncodingStrategy = .deferredToData
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }()
  
  /// Federates the provided object to remote ActivityPub compliant servers.
  ///
  /// Each remote will only be notified once. Errors are consumed and no retries are implemented.
  /// - Parameters:
  ///   - object: the object to notify, the `ActivityObject` is encapsulated by the `APActivityResponse` for semantic purposes by the spec.
  ///   - remotes: list of remotes to notify, duplicates will be notified
  ///   - actorKeyId: the actor's key ID
  ///   - actorPrivateKey: the actor's private key
  ///   - req: networking request object which can provide a client for making the outgoing requests
  open func federate(object: any APActivityResponse, to remotes: [URL], actorKeyId: String, actorPrivateKey: String, _ req: APNetworkingRequest) async throws {
    let encodedObject = try Self.encoder.encode(object)
    
    let privateKey = try _RSA.Signing.PrivateKey(pemRepresentation: actorPrivateKey)
    
    // 1. Generate the content hash using the private key of the user who will be notifying this
    guard let encodedDigest = encodedObject.sha256Data()?.base64EncodedString() else {
      throw APAbortError(.internalServerError, reason: "Failed to form base64 encoded representation of the object.")
    }
    
    // 2. Prepare the string to sign
    let date = Date.now
    let rfcDate = APAuthenticator.rfc2616Formatter.string(from: date)
    
    let headers = ["(request-target)", "host", "date", "digest"]
    
    for remote in remotes {
      guard let host = remote.host() else {
        req.logger.warning("No valid host for remote in \(String.init(describing: object)), exiting")
        continue
      }
      
      #if canImport(Network)
      // Disallow multi-cast and loopback addresses on the local system.
      //
      // This may sometimes cause an infinite recursion on misconfigured systems.
      if let ipv4Address = IPv4Address(host),
         ipv4Address.isLoopback || ipv4Address.isMulticast {
        req.logger.warning("Loopback/Multicast address for remote in \(String.init(describing: object)), exiting")
        continue
      }
      
      if let ipv6Address = IPv6Address(host),
         ipv6Address.isLoopback || ipv6Address.isMulticast {
        req.logger.warning("Loopback/Multicast address for remote in \(String.init(describing: object)), exiting")
        continue
      }
      #endif
      
      let path = remote.path()
      
      guard !path.isEmpty else {
        req.logger.warning("No valid path for remote in \(String.init(describing: object)), exiting")
        continue
      }
      
      let stringToSign = "(request-target): post \(path)\nhost: \(host)\ndate: \(rfcDate)\ndigest: SHA-256=\(encodedDigest)"
      
      guard let stringToSignData = stringToSign.data(using: String.Encoding.utf8) else {
        continue
      }
      
      req.logger.info("stringToSign: \(stringToSign); base64: \(stringToSignData.base64EncodedString())")
      
      // 3. Sign the string using our user's private key
      //
      // Continue to use `insecurePKCS1v1_5` here until Mastodon upgrades its signature verification.
      //
      // This will work normally for other remotes as they are handling the same.
      let signature = try privateKey.signature(
        for: stringToSignData,
        padding: _RSA.Signing.Padding.insecurePKCS1v1_5
      )
      let encodedSig = Data(signature.rawRepresentation).base64EncodedString()
      
      // 4. Prepare the signature header using all the components
      let signatureHeader = """
keyId="\(actorKeyId)",headers="\(headers.joined(separator: " "))",signature="\(encodedSig)"
"""
      // 5. Make the request
      try await notify(
        remote: remote,
        digest: encodedDigest,
        dateHeader: rfcDate,
        signature: signatureHeader,
        content: object,
        request: req
      )
    }
  }
  
  /// Notify the provided remote with the resulting content.
  ///
  /// - Warning:
  /// You may rarely need to call this method directly.
  /// Please see ``APFederationHost.federate(object:to:actoryKeyId:actorPrivateKey:_)`` instead, which invokes with this method with the correct parameter values.
  ///
  /// - Parameters:
  ///   - remote: the remote to notify, generally a `/inbox` url
  ///   - digest: an encoded digest of the content being notified to the remote (sha256-base64)
  ///   - dateHeader: the value to be used for the `Date` HTTP header
  ///   - signature: the value to be used for the `Authentication` HTTP header
  ///   - content: the content to notify
  ///   - request: networking request object which can provide a client for making the outgoing requests
  open func notify(remote: URL, digest: String, dateHeader: String, signature: String, content: any APContent, request: APNetworkingRequest) async throws {
    guard let host = remote.host() else {
      return
    }
    
    if remote.absoluteString == "https://www.w3.org/ns/activitystreams#Public" {
      return
    }
    
    request.logger.info("Notifying: url: \(remote); digest: \(digest); date: \(dateHeader); signature: \(signature);")
    
    do {
      let headers = HTTPHeaders([
        ("Host", host),
        ("Date", dateHeader),
        ("Digest", "SHA-256=\(digest)"),
        ("Content-Type", ACTIVITY_JSON_HEADER),
        ("Signature", signature)
      ])
      #if canImport(Vapor)
      let response = try await request.post(
        remote.absoluteString,
        headers: headers,
        body: content,
        contentType: .activityJSON
      )
      #else
      let response = try await request.post(
        remote.absoluteString,
        headers: headers,
        body: content,
        contentType: "application/activity+json"
      )
      #endif
      
      // @TODO: Inspect Response to ensure everything is okay
      switch response.0.status {
      case .accepted...(.imUsed):
        request.logger.info("Notified \(remote); status: \(response.0.status);")
      default:
        guard let resData = response.1 else {
          throw APAbortError(.notAcceptable, reason: "Invalid or no response data from remote ActivityPub server")
        }
        
        #if canImport(Vapor)
        if response.0.contentType == .json || response.0.contentType == .activityJSON,
           let jsonObject = try? JSONSerialization.jsonObject(with: resData) {
          request.logger.warning("Failed to notify \(remote); digest \(digest); date: \(dateHeader); signature: \(signature); response: \(jsonObject)")
        }
        else {
          if let data = response.1 {
            let string = String(buffer: data)
            request.logger.warning("Failed to notify \(remote); digest \(digest); date: \(dateHeader); signature: \(signature); response: \(String(describing: string))")
          }
        }
        #else
        let mimeType = response.0.contentType
        
        if mimeType == .json || mimeType.subType.contains("activity+json"),
           let jsonObject = try? JSONSerialization.jsonObject(with: resData) {
          request.logger.warning("Failed to notify \(remote); digest \(digest); date: \(dateHeader); signature: \(signature); response: \(jsonObject)")
        }
        else {
          request.logger.warning("Failed to notify \(remote); digest \(digest); date: \(dateHeader); signature: \(signature); response: \(String(describing: String(buffer: resData)))")
        }
        #endif
      }
    }
    catch {
      // @TODO: Observe Error
      // Errors like host unavailable, timeout, SSL errors should be queued for retrying
      request.logger.error("Error notifying \(remote); digest \(digest); date: \(dateHeader); signature: \(signature); error: \(error.localizedDescription); \((error as NSError).code)")
    }
  }
}

// MARK: - HTTPResponseStatus
extension HTTPResponseStatus: @retroactive Comparable {
  public static func < (lhs: HTTPResponseStatus, rhs: HTTPResponseStatus) -> Bool {
    lhs.code < rhs.code
  }
  
  public static func > (lhs: HTTPResponseStatus, rhs: HTTPResponseStatus) -> Bool {
    lhs.code > rhs.code
  }
}
