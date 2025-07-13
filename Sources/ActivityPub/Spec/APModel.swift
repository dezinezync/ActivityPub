//
//  APModel.swift
//  ActivityPub
//
//  Created by Nikhil Nigade on 13/07/25.
//

import Foundation

#if canImport(Vapor)
import Vapor
public typealias APContent = Content
#else
public typealias APAPContent = Codable
#endif
