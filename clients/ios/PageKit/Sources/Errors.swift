//
//  Errors.swift
//  PageKit
//
//  Created by Nathan Borror on 10/24/16.
//  Copyright © 2016 Nathan Borror. All rights reserved.
//

import Foundation
import SwiftGRPC

public enum ServiceError: Error {
    case invalid(String)
    case restricted(String)
    case serverError(String)
    case badArgument(String)
    case unknown(Error)
    
    init(err: ResponseError) {
        switch err {
        case let .canceled(msg):            self = .serverError(msg)
        case .unknown:                      self = .unknown(err)
        case let .invalidArgument(msg):     self = .badArgument(msg)
        case let .deadlineExceeded(msg):    self = .serverError(msg)
        case let .notFound(msg):            self = .invalid(msg)
        case let .alreadyExists(msg):       self = .invalid(msg)
        case let .permissionDenied(msg):    self = .restricted(msg)
        case let .unauthenticated(msg):     self = .restricted(msg)
        case let .resourceExhausted(msg):   self = .serverError(msg)
        case let .failedPrecondition(msg):  self = .invalid(msg)
        case let .aborted(msg):             self = .invalid(msg)
        case let .outOfRange(msg):          self = .invalid(msg)
        case let .unimplemented(msg):       self = .serverError(msg)
        case let .internal(msg):            self = .serverError(msg)
        case let .unavailable(msg):         self = .invalid(msg)
        case let .dataLoss(msg):            self = .serverError(msg)
        }
    }
    
    public var localizedDescription: String {
        switch self {
        case let .invalid(msg):     return msg
        case let .restricted(msg):  return msg
        case let .serverError(msg): return msg
        case let .badArgument(msg): return msg
        case let .unknown(err):     return "\(err)"
        }
    }
}
