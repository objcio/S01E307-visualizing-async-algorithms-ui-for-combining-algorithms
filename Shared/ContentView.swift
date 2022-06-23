import SwiftUI

struct StreamWithID: Identifiable, Equatable {
    var id = UUID()
    var stream: Stream
    init(_ stream: Stream) {
        self.stream = stream
    }
}

extension Stream {
    var pretty: Text {
        switch self {
        case .input1:
            return Text("input1").foregroundColor(.red)
        case .input2:
            return Text("input2").foregroundColor(.green)
        case .merge(let l, let r):
            return Text("merge(\(l.pretty), \(r.pretty))")
        case .chain(let l, let r):
            return Text("chain(\(l.pretty), \(r.pretty))")
        case .zip(let l, let r):
            return Text("zip(\(l.pretty), \(r.pretty))")
        case .combineLatest(let l, let r):
            return Text("combineLatest(\(l.pretty), \(r.pretty))")
        case .adjacentPairs(let stream):
            return Text("\(stream.pretty).adjacentPairs()")
        }
    }
}

struct RunView: View {
    @State var algorithms: [StreamWithID] = [.init(.input1), .init(.input2)]
    @State var sample1 = sampleInt
    @State var sample2 = sampleString
    @State var result: [StreamWithID.ID:[Event]] = [:]
    @State private var loading = false
    @State private var selectedIDs: Set<StreamWithID.ID> = []
    
    var duration: TimeInterval {
        (sample1 + sample2 + result.values.flatMap { $0 }).lazy.map { $0.time }.max() ?? 1
    }
    
    var selectedAlgorithms: [Stream] {
        algorithms.filter { algo in selectedIDs.contains(algo.id) }.map { $0.stream }
    }
    
    var body: some View {
        VStack {
            list
            let selectedAlgos = selectedAlgorithms
            HStack {
                if selectedAlgos.count == 1 {
                    Button("adjacentPairs") {
                        algorithms.append(.init(.adjacentPairs(selectedAlgos[0])))
                    }
                } else if selectedAlgos.count == 2 {
                    Button("merge") {
                        algorithms.append(.init(.merge(selectedAlgos[0], selectedAlgos[1])))
                    }
                    Button("zip") {
                        algorithms.append(.init(.zip(selectedAlgos[0], selectedAlgos[1])))
                    }
                    Button("combineLatest") {
                        algorithms.append(.init(.combineLatest(selectedAlgos[0], selectedAlgos[1])))
                    }
                    Button("chain") {
                        algorithms.append(.init(.chain(selectedAlgos[0], selectedAlgos[1])))
                    }
                }
            }
        }
    }
    var list: some View {
        List(algorithms, selection: $selectedIDs) { algo in
            VStack(alignment: .leading) {
                switch algo.stream {
                case .input1:
                    TimelineView(events: $sample1, duration: duration)
                case .input2:
                    TimelineView(events: $sample2, duration: duration)
                default:
                    TimelineView(events: .constant(result[algo.id] ?? []), duration: duration)
                        .drawingGroup()
                        .opacity(loading ? 0.5 : 1)
                        .animation(.default, value: result)
                }
                algo.stream.pretty
            }
        }
        .padding(20)
        .task(id: Pair(sample1 + sample2, algorithms)) {
            loading = true
            let context = StreamContext(events1: sample1, events2: sample2)
            result = await withTaskGroup(of: (UUID, [Event]).self) { group in
                for algo in algorithms {
                    group.addTask {
                        (algo.id, await run(algorithm: algo.stream, context))
                    }
                }
                return await Dictionary(uniqueKeysWithValues: group)
            }
            loading = false
        }
    }
}

struct Pair<A, B> {
    init(_ a: A, _ b: B) {
        self.a = a
        self.b = b
    }
    
    var a: A
    var b: B
}

extension Pair: Equatable where A: Equatable, B: Equatable { }

struct ContentView: View {
    var body: some View {
        RunView()
    }
}
