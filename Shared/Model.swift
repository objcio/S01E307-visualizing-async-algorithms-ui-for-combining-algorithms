//
//  Model.swift
//  AsyncAlgorithmsVisualization
//
//  Created by Chris Eidhof on 27.04.22.
//

import Foundation
@preconcurrency import SwiftUI

enum Value: Hashable, Sendable {
    case int(Int)
    case string(String)
    indirect case combined(Value, Value)
}

indirect enum EventID: Hashable, Sendable {
    case single(UUID)
    case combined(EventID, EventID)
}

struct Event: Identifiable, Hashable, Sendable, Comparable {
    static func < (lhs: Event, rhs: Event) -> Bool {
        lhs.time < rhs.time
    }
    
    var id: EventID = .single(UUID())
    var time: TimeInterval
    var color: Color = .green
    var value: Value
}

var sampleInt: [Event] = [
    .init(time:  0, color: .red, value: .int(1)),
    .init(time:  1, color: .red, value: .int(2)),
    .init(time:  2, color: .red, value: .int(3)),
    .init(time:  5, color: .red, value: .int(4)),
    .init(time:  8, color: .red, value: .int(5)),
]

var sampleString: [Event] = [
    .init(time:  1.5, value: .string("a")),
    .init(time:  2.5, value: .string("b")),
    .init(time:  4.5, value: .string("c")),
    .init(time:  6.5, value: .string("d")),
    .init(time:  7.5, value: .string("e")),
]
