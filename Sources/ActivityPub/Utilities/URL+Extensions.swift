//
//  URL+Extensions.swift
//  ActivityPub
//
//  Created by Nikhil Nigade on 30/10/24.
//

#if os(Linux)
import Foundation

extension URL {
  func host() -> String? {
    guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
      return nil
    }
    
    return components.host?.removingPercentEncoding
  }
  
  func path() -> String {
    guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
      return ""
    }
    
    let path = components.path
    
    return path.removingPercentEncoding ?? path
  }
  
  /// Appends query items to the URL.
  /// - Parameter queryItems: An array of `URLQueryItem` representing the query parameters.
  /// - Returns: A new URL with the query items appended, or nil if the URL cannot be constructed.
  func appending(queryItems: [URLQueryItem]) -> URL {
    guard var components = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
      #if DEBUG
      fatalError("Failed to form components from \(self)")
      #endif
      return self
    }
    
    // Append or create the array of query items
    if components.queryItems != nil {
      components.queryItems! += queryItems
    } else {
      components.queryItems = queryItems
    }
    
    // Return the url from the components
    return components.url!
  }
}
#endif
