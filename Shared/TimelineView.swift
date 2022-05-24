import Foundation
import SwiftUI

extension Value: View {
    var body: some View {
        switch self {
        case .int(let i): Text("\(i)")
        case .string(let s): Text(s)
        case let .combined(v1, v2):
            HStack(spacing: 0) {
                v1
                v2
            }
        }
    }
}

struct EventNode: View {
    @Binding var event: Event
    var secondsPerPoint: CGFloat
    @GestureState private var offset: CGFloat = 0
    
    var body: some View {
        event.value
            .frame(width: 30, height: 30)
            .background {
                Circle().fill(event.color)
            }
            .offset(x: offset)
            .gesture(gesture)
    }
    
    var gesture: some Gesture {
        DragGesture()
            .updating($offset) { value, state, _ in
                state = value.translation.width
            }.onEnded { value in
                event.time += value.translation.width * secondsPerPoint
            }
    }
}

struct TimelineView: View {
    @Binding var events: [Event]
    var duration: TimeInterval
    
    var body: some View {
        GeometryReader { proxy in
            let numberOfTicks = Int(duration.rounded(.up))
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.secondary)
                    .frame(height: 1)
                ForEach(0..<numberOfTicks) { tick in
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(.secondary)
                        .alignmentGuide(.leading) { dim in
                            let relativeTime = CGFloat(tick) / duration
                            return -(proxy.size.width-30) * relativeTime
                        }
                }.id(numberOfTicks)
                .offset(x: 15)
                ForEach($events) { $event in
                    EventNode(event: $event, secondsPerPoint: duration/(proxy.size.width - 30))
                        .alignmentGuide(.leading) { dim in
                            let relativeTime = event.time / duration
                            return -(proxy.size.width-30) * relativeTime
                        }
                        .help("\(event.time)")
                }
            }
        }
        .frame(height: 30)
    }
}
