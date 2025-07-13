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

#if canImport(Vapor)
import Vapor
#endif

// MARK: - Content
public protocol APNetworkingContent {
  var body: ByteBuffer? { get set }
  
  #if canImport(Vapor)
  var contentType: HTTPMediaType { get }
  
  func encode<C: Content>(_ content: C, as contentType: HTTPMediaType) throws
  #else
  var mimeType: String? { get }
  
  func encode<C: Codable>(_ content: C, as contentType: String) throws
  #endif
}

#if !canImport(Vapor)
extension APNetworkingContent {
  mutating func encode<C: Codable>(_ content: C, as contentType: String) throws {
    let data = try JSONEncoder().encode(content)
    self.body = ByteBuffer(data: data)
  }
}
#endif

// MARK: - Request
public protocol APNetworkingRequest {
  var method: HTTPMethod { get set }
  
  var uri: CustomStringConvertible { get set }
  
  var url: URL { get }
  
  var headers: HTTPHeaders { get set }
  
  var logger: APLogging { get }
  
  var client: APNetworking { get }
  
  var content: APNetworkingContent? { get set }
}

// MARK: - Response

public protocol APNetworkingResponse {
  var status: HTTPResponseStatus { get }
  var headers: HTTPHeaders { get }
  var body: ByteBuffer? { get }
  var content: APNetworkingContent { get }
}

// MARK: - Networking

public protocol APNetworking {
  func get(_ url: CustomStringConvertible, headers: HTTPHeaders) async throws -> (APNetworkingResponse, Data)
  
  func post(_ url: CustomStringConvertible, headers: HTTPHeaders, beforeSend: (inout APNetworkingRequest) throws -> ()) async throws -> (APNetworkingResponse, Data)
}
