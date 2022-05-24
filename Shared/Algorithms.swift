//
//  Algorithms.swift
//  AsyncAlgorithmsVisualization
//
//  Created by Chris Eidhof on 27.04.22.
//

import Foundation
import AsyncAlgorithms

indirect enum Stream: Sendable, Equatable {
    case input1
    case input2
    case merge(Stream, Stream)
    case chain(Stream, Stream)
    case zip(Stream, Stream)
    case combineLatest(Stream, Stream)
    case adjacentPairs(Stream)
}

extension Array where Element == Event {
    @MainActor
    func stream(speedFactor: Double) -> AsyncStream<Event> {
        AsyncStream { cont in
            let events = sorted()
            for event in events {
                Timer.scheduledTimer(withTimeInterval: event.time/speedFactor, repeats: false) { _ in
                    cont.yield(event)
                    if event == events.last {
                        cont.finish()
                    }
                }
            }
        }
    }
}

func run(algorithm: Stream, _ context: StreamContext) async -> [Event] {
    var result: [Event] = []
    let events = await runHelper(algorithm, context)
    let startDate = Date()
    var interval: TimeInterval { Date().timeIntervalSince(startDate) * context.factor }
    for await event in events {
        result.append(Event(id: event.id, time: interval, color: event.color, value: event.value))
    }
    return result
}

extension AsyncSequence {
    var stream: AsyncStream<Element> {
        var it = makeAsyncIterator()
        return AsyncStream<Element> {
            try! await it.next()
        }
    }
}

struct StreamContext {
    var events1: [Event]
    var events2: [Event]
    let factor: Double = 10
}

func runHelper(_ algorithm: Stream, _ context: StreamContext) async -> AsyncStream<Event> {
    switch algorithm {
    case .input1:
        return await context.events1.stream(speedFactor: context.factor)
    case .input2:
        return await context.events2.stream(speedFactor: context.factor)
    case let .merge(l, r):
        async let stream1 = runHelper(l, context)
        async let stream2 = runHelper(r, context)
        return await merge(stream1, stream2).stream
    case let .combineLatest(l, r):
        async let stream1 = runHelper(l, context)
        async let stream2 = runHelper(r, context)
        return await combineLatest(stream1, stream2).map { (e1, e2) in
            Event(id: .combined(e1.id, e2.id), time: 0, color: .blue, value: .combined(e1.value, e2.value))
        }.stream
    case .chain(let l, let r):
        async let stream1 = runHelper(l, context)
        async let stream2 = runHelper(r, context)
        return await chain(stream1, stream2).stream
    case .zip(let l, let r):
        async let stream1 = runHelper(l, context)
        async let stream2 = runHelper(r, context)
        return await zip(stream1, stream2).map { (e1, e2) in
            Event(id: .combined(e1.id, e2.id), time: 0, color: .blue, value: .combined(e1.value, e2.value))
        }.stream
    case .adjacentPairs(let i):
        async let stream1 = runHelper(i, context)
        return await stream1.adjacentPairs().map { (e1, e2) in
            Event(id: .combined(e1.id, e2.id), time: 0, color: .blue, value: .combined(e1.value, e2.value))
        }.stream
    }
}
