//
//  Service.swift
//  PageKit
//
//  Created by Nathan Borror on 10/9/16.
//  Copyright © 2016 Nathan Borror. All rights reserved.
//

import Foundation
import SwiftGRPC
import SwiftProtobuf

public class Service {

    public typealias SessionHandler = (() throws -> Session) -> Void
    public typealias PagesHandler   = (() throws -> PagesSet) -> Void
    public typealias PageHandler    = (() throws -> Page) -> Void
    public typealias EmptyHandler   = (() throws -> Empty) -> Void

    public enum Route: CustomStringConvertible {
        case account(Accounts)
        case page(Pages)

        public enum Accounts: String {
            case register   = "Register"
            case connect    = "Connect"
        }

        public enum Pages: String {
            case create     = "PageCreate"
            case update     = "PageUpdate"
            case delete     = "PageDelete"
            case get        = "PageGet"
            case list       = "PageList"
        }

        public var description: String {
            switch self {
            case let .account(route):
                return "/Accounts/\(route.rawValue)"
            case let .page(route):
                return "/Pages/\(route.rawValue)"
            }
        }
    }

    let session: GrpcSession

    public init(endpoint: String) {
        guard let endpointUrl = URL(string: endpoint) else {
            fatalError("Service Error: Unable to initialize URL for endpoint: \(endpoint)")
        }
        self.session = GrpcSession(url: endpointUrl)
    }

    public func register(name: String, email: String, password: String, then: @escaping SessionHandler) {
        let data = RegisterRequest.with {
            $0.name = name
            $0.email = email
            $0.password = password
        }
        call(route: .account(.register), data: data, token: nil, then: then)
    }

    public func connect(identifier: String, password: String, then: @escaping SessionHandler) {
        let data = ConnectRequest.with {
            $0.identifier = identifier
            $0.password = password
        }
        call(route: .account(.connect), data: data, token: nil, then: then)
    }

    public func pageCreate(text: String, token: String?, then: @escaping PageHandler) {
        let data = PageCreateRequest.with {
            $0.text = text
        }
        call(route: .page(.create), data: data, token: token, then: then)
    }

    public func pageUpdate(id: String, text: String, token: String?, then: @escaping PageHandler) {
        let data = PageUpdateRequest.with {
            $0.id = id
            $0.text = text
        }
        call(route: .page(.update), data: data, token: token, then: then)
    }

    public func pageDelete(id: String, token: String?, then: @escaping PageHandler) {
        let data = PageDeleteRequest.with {
            $0.id = id
        }
        call(route: .page(.delete), data: data, token: token, then: then)
    }

    public func pageGet(id: String, then: @escaping PageHandler) {
        let data = PageGetRequest.with {
            $0.id = id
        }
        call(route: .page(.get), data: data, token: nil, then: then)
    }

    public func pageList(then: @escaping PagesHandler) {
        let data = Empty()
        call(route: .page(.list), data: data, token: nil, then: then)
    }

    private func call<Request: ProtobufMessage, Response: ProtobufMessage>(route: Service.Route, data: Request, token: String?, then: @escaping (() throws -> Response) -> Void) {
        do {
            try session.write(path: String(describing: route), message: data, token: token) {
                switch $0 {
                case .value(let bytes):
                    let data = Data(bytes)
                    then { return try Response(protobuf: data) }
                case .failure(let err):
                    let error = ServiceError(err: err)
                    then { throw error }
                }
            }
        } catch {
            then { throw error }
        }
    }
}
