//
//  APNetworking.swift
//  ActivityPub
//
//  Created by Nikhil Nigade on 13/07/25.
//

import Foundation
import NIOHTTP1
import NIOCore
import NIOFoundationCompat
import Logging

#if canImport(Vapor)
import Vapor
#endif

// MARK: - Content
public protocol APNetworkingContent {
  var body: Data? { get }
}

// MARK: - Request
public protocol APNetworkingRequest {
  var method: HTTPMethod { get set }
  
  var uri: CustomStringConvertible { get set }
  
  var resourceURL: URL? { get }
  
  var headers: HTTPHeaders { get set }
  
  var logger: Logger { get }
  
  // MARK: Network Request
  func get(_ url: CustomStringConvertible, headers: HTTPHeaders) async throws -> (APNetworkingResponse, ByteBuffer?)
  
  #if canImport(Vapor)
  func post<C>(_ url: CustomStringConvertible, headers: HTTPHeaders, body: C, contentType: HTTPMediaType) async throws -> (APNetworkingResponse, ByteBuffer?) where C: APContent
  #else
  func post<C>(_ url: CustomStringConvertible, headers: HTTPHeaders, body: C, contentType: String) async throws -> (APNetworkingResponse, ByteBuffer?) where C: APContent
  #endif
  
  // MARK: Encoding Data
  #if canImport(Vapor)
  var contentType: HTTPMediaType? { get }

  func encode<C: Content>(_ content: C, as contentType: HTTPMediaType) throws
  #else
  var mimeType: String? { get }

  func encode<C: Codable>(_ content: C, as contentType: String) throws
  #endif
}

// MARK: - Response

public protocol APNetworkingResponse {
  var status: HTTPResponseStatus { get }
  var headers: HTTPHeaders { get }
  var contentType: HTTPMediaType { get }
}
