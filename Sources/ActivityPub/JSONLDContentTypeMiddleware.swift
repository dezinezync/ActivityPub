//
//  JSONLDContentTypeMiddleware.swift
//  ActivityPub
//
//  Created by Nikhil Nigade on 17/08/24.
//

#if canImport(Vapor)
import Vapor

public final class JSONLDContentTypeMiddleware: Middleware {
  public init() {
    
  }
  
  public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
    next.respond(to: request).map { response in
      response.headers.replaceOrAdd(name: .contentType, value: ACTIVITY_JSON_HEADER)
      return response
    }
  }
}
#endif
