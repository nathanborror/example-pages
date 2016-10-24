//
//  State.swift
//  PageKit
//
//  Created by Nathan Borror on 10/6/16.
//  Copyright © 2016 Nathan Borror. All rights reserved.
//

import Foundation
import SwiftGRPC

protocol StateType {

    associatedtype InputEvent
    associatedtype OutputCommand

    mutating func handle(event: InputEvent) -> OutputCommand

    static var initial: Self { get }
}

public enum State: StateType {
    
    case active(session: Session, pages: [String: Page])
    case inactive
    
    public enum Event {
        case activate(Session)
        case deactivate
        case update([Page])
        case remove(Page)
        case error(Error?)
    }
    
    public enum Command {
        case activated
        case deactivated
        case updated
        case error(Error?)
    }
    
    public static var initial: State {
        guard let session = State.restore() else {
            return .inactive
        }
        return .active(session: session, pages: [:])
    }
    
    public mutating func handle(event: Event) -> Command? {
        switch (self, event) {
            
        case (.inactive, .activate(let session)):
            self = .active(session: session, pages: [:])
            State.save(session: session)
            return .activated
            
        case (.active, .deactivate):
            self = .inactive
            State.destroy()
            return .deactivated
            
        case (let .active(session, pages), let .update(newPages)):
            var out = pages
            for page in newPages {
                out[page.id] = page
            }
            self = .active(session: session, pages: out)
            return .updated
            
        case (let .active(session, pages), let .remove(page)):
            var out = pages
            out.removeValue(forKey: page.id)
            self = .active(session: session, pages: out)
            return .updated
            
        case (.inactive, .error(let error)), (.active, .error(let error)):
            return .error(error)
            
        default: break
        }
        return nil
    }
    
    static let sessionKey = "session"
    
    static func save(session: Session) {
        let data = try? session.serializeProtobuf()
        UserDefaults.standard.setValue(data, forKey: sessionKey)
    }
    
    static func restore() -> Session? {
        guard let data = UserDefaults.standard.value(forKey: sessionKey) as? Data else {
            return nil
        }
        return try? Session(protobuf: data)
    }
    
    static func destroy() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }
}
