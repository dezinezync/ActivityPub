//
//  APAuthenticator.swift
//  
//
//  Created by Nikhil Nigade on 30/08/24.
//

import Vapor
import Crypto
import _CryptoExtras

public let JSON_LD_HEADER = "application/ld+json; profile=\"https://www.w3.org/ns/activitystreams\""
public let ACTIVITY_JSON_HEADER = "application/activity+json; charset=utf-8"

/// Authenticates `Signature` header for ActivityPub requests
public struct APAuthenticator: AsyncRequestAuthenticator {
  public static let rfc2616Formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")     // POSIX locale to ensure consistency
    formatter.timeZone = TimeZone(secondsFromGMT: 0)         // GMT timezone
    formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'" // RFC 2616 format
    return formatter
  }()
  
  public let signatureRegExp = try! Regex(#"keyId=\"(.+)\",\s?headers=\"(.+)\",\s?signature=\"(.+)\""#)
  
  public init() {
    
  }
  
  public func authenticate(request: Vapor.Request) async throws {
    guard let signatureHeader = request.headers.first(name: "Signature") else {
      throw Abort(.unauthorized, reason: "Signature header missing, required for authenticated requests.")
    }
    
    // Ensure request was made within the last twelve hours
    guard let dateStr = request.headers.first(name: "Date") ?? request.headers.first(name: "date") else {
      throw Abort(.badRequest, reason: "Date header not included in the request")
    }
    
    guard let date = Self.rfc2616Formatter.date(from: dateStr) else {
      throw Abort(.badRequest, reason: "Date value in the header must be RFC2616 formatted")
    }
    // 12 hours max
    guard Date().timeIntervalSince(date) <= (86400 * 0.5) else {
      throw Abort(.badRequest, reason: "Stale request")
    }
    
    var signature: String?
    var headers: String?
    var keyId: String?
    
    guard let match = try signatureRegExp.wholeMatch(in: signatureHeader),
          match.count >= 4 else {
      throw Abort(.unauthorized, reason: "Invalid signature format.")
    }
    // 0-th match is the whole string
    keyId = String(match[1].substring ?? "")
    headers = String(match[2].substring ?? "")
    signature = String(match[3].substring ?? "")
    
    guard let keyId,
          let signature,
          let headers else {
      throw Abort(.unauthorized, reason: "Incomplete Signature header components.")
    }
    
    // fetch profile from KeyID trimming all items after `#` if observed in the URI
    var actorURLPath = keyId
    if let hashIndex = actorURLPath.firstIndex(of: "#") {
      actorURLPath = String(actorURLPath[actorURLPath.startIndex..<hashIndex])
    }
    
    let publicKey = try await fetchPublicKey(for: URI(string: actorURLPath), using: request)
    
    let headersList = headers
      .split(separator: " ")
      .map(String.init).map {
        $0.split(separator: ",")
      }.reduce([], +).map {
        $0.trimmingCharacters(in: .whitespaces)
      }
    
    let signedData = prepareSignedData(from: request, headersList: headersList)
    
    guard  let signatureData = Data(base64Encoded: signature),
           try verifySignature(publicKeyPem: publicKey,
                               signatureData: signatureData,
                               signedData: signedData) else {
      throw Abort(.unauthorized, reason: "Signature mismatch, please verify the signature provided in the headers.")
    }
    
    request.logger.info("Validated signature for \(actorURLPath)")
  }
  
  /// Get the public key for the provided actor.
  ///
  /// If one does not exist in our local cache, it'll be fetched from its respective server.
  /// - Parameters:
  ///   - actor: the actor's URL
  ///   - req: the `Request` instance to use for making this request.
  /// - Returns: the `publicKey` in `PEM` format of the actor.
  func fetchPublicKey(for actor: URI, using req: Request) async throws -> String {
    let profile = try await fetchActorProfile(from: actor, using: req)
    let publicKey = profile.publicKey.publicKeyPem
    
    guard !publicKey.isEmpty else {
      throw Abort(.lengthRequired, reason: "Public key was empty for \(actor)")
    }
    
    return publicKey
  }
  
  /// Prepares the data for signing based on the headers list included in the `Signature` header of the request.
  /// - Parameters:
  ///   - request: the request (header values are fetched from this instance)
  ///   - headersList: the list of headers included in the `Signature` header
  /// - Returns: the `.utf8` Data representation of the assumed signed string
  fileprivate func prepareSignedData(from request: Request, headersList: [String]) -> Data {
    let signingStrings: [String] = headersList.compactMap { header in
      if header == "(request-target)" {
        return "\(header): \(request.method.string.lowercased()) \(request.url.path)"
      }
      
      if let headerValue = request.headers.first(name: header) {
        return "\(header): \(headerValue)"
      }
      return nil
    }
    
    let signingString = signingStrings.joined(separator: "\n")

    return Data(signingString.utf8)
  }
  
  /// Verify the RSA signature included in the headers
  /// - Parameters:
  ///   - publicKeyPem: the actor's public key
  ///   - signatureData: the signature component (RSA-256 encrypted) provided in the header
  ///   - signedData: the signed data we generate based on the headers list and digest
  /// - Returns: `true` if the signature is valid, `false` otherwise.
  fileprivate func verifySignature(publicKeyPem: String, signatureData: Data, signedData: Data) throws -> Bool {
    let publicKey = try _RSA.Signing.PublicKey(pemRepresentation: publicKeyPem)
    let sigKey = _RSA.Signing.RSASignature(rawRepresentation: signatureData)
    // most platforms will validate with this correctly
    //
    // and hopefully Mastodon as well, in a future update
    if publicKey.isValidSignature(sigKey, for: signedData) {
      return true
    }
    // for now, as of v4.3.0, this continues to work
    else if publicKey.isValidSignature(sigKey, for: signedData, padding: .insecurePKCS1v1_5) {
      return true
    }
    return false
  }
}
