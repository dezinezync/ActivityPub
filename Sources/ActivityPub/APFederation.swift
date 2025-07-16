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

open class APFederationHost {
  public static let encoder: JSONEncoder = {
    var encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    encoder.keyEncodingStrategy = .useDefaultKeys
    encoder.dataEncodingStrategy = .deferredToData
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }()
  
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
        req.logger.warning("No valid host for remote in \(String.init(describing: object)), exiting", metadata: nil, file: #file, function: #function, line: #line)
        continue
      }
      
      let path = remote.path()
      
      guard !path.isEmpty else {
        req.logger.warning("No valid path for remote in \(String.init(describing: object)), exiting", metadata: nil, file: #file, function: #function, line: #line)
        continue
      }
      
      let stringToSign = "(request-target): post \(path)\nhost: \(host)\ndate: \(rfcDate)\ndigest: SHA-256=\(encodedDigest)"
      
      guard let stringToSignData = stringToSign.data(using: String.Encoding.utf8) else {
        continue
      }
      
      req.logger.info("stringToSign: \(stringToSign); base64: \(stringToSignData.base64EncodedString())", metadata: nil, file: #file, function: #function, line: #line)
      
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
  
  open func notify(remote: URL, digest: String, dateHeader: String, signature: String, content: any APContent, request: APNetworkingRequest) async throws {
    guard let host = remote.host() else {
      return
    }
    
    if remote.absoluteString == "https://www.w3.org/ns/activitystreams#Public" {
      return
    }
    
    request.logger.info("Notifying: url: \(remote); digest: \(digest); date: \(dateHeader); signature: \(signature);", metadata: nil, file: #file, function: #function, line: #line)
    
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
        request.logger.info("Notified \(remote); status: \(response.0.status);", metadata: nil, file: #file, function: #function, line: #line)
      default:
        guard let resData = response.1 else {
          throw APAbortError(.notAcceptable, reason: "Invalid or no response data from remote ActivityPub server")
        }
        
        #if canImport(Vapor)
        if response.0.contentType == .json || response.0.contentType == .activityJSON,
           let jsonObject = try? JSONSerialization.jsonObject(with: resData) {
          request.logger.warning("Failed to notify \(remote); digest \(digest); date: \(dateHeader); signature: \(signature); response: \(jsonObject)", metadata: nil, file: #file, function: #function, line: #line)
        }
        else {
          if let data = response.1 {
            let string = String(buffer: data)
            request.logger.warning("Failed to notify \(remote); digest \(digest); date: \(dateHeader); signature: \(signature); response: \(String(describing: string))", metadata: nil, file: #file, function: #function, line: #line)
          }
        }
        #else
        guard let mimeType = response.0.content.mimeType else {
          request.logger.warning("No mimetype, ignoring", metadata: nil, file: #file, function: #function, line: #line)
          return
        }
        
        if mimeType.contains("json") || mimeType.contains("activity+json"),
           let jsonObject = try? JSONSerialization.jsonObject(with: response.1) {
          request.logger.warning("Failed to notify \(remote); digest \(digest); date: \(dateHeader); signature: \(signature); response: \(jsonObject)", metadata: nil, file: #file, function: #function, line: #line)
        }
        else {
          let data = response.1
          request.logger.warning("Failed to notify \(remote); digest \(digest); date: \(dateHeader); signature: \(signature); response: \(String(describing: String(data: data, encoding: .utf8)))", metadata: nil, file: #file, function: #function, line: #line)
        }
        #endif
      }
    }
    catch {
      // @TODO: Observe Error
      // Errors like host unavailable, timeout, SSL errors should be queued for retrying
      request.logger.error("Error notifying \(remote); digest \(digest); date: \(dateHeader); signature: \(signature); error: \(error.localizedDescription); \((error as NSError).code)", metadata: nil, file: #file, function: #function, line: #line)
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
