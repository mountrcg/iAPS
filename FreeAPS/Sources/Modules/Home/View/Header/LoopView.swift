import SwiftDate
import SwiftUI
import UIKit

struct LoopView: View {
    private enum Config {
        static let lag: TimeInterval = 30
    }

    @Binding var suggestion: Suggestion?
    @Binding var enactedSuggestion: Suggestion?
    @Binding var closedLoop: Bool
    @Binding var timerDate: Date
    @Binding var isLooping: Bool
    @Binding var lastLoopDate: Date
    @Binding var manualTempBasal: Bool
    @State private var scale: CGFloat = 1.0

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    private let rect = CGRect(x: 0, y: 0, width: 18, height: 18)

    var body: some View {
        HStack(alignment: .center) {
            ZStack {
                if isLooping {
                    CircleProgress()
                } else {
                    Circle()
                        .strokeBorder(color, lineWidth: 4)
                        .frame(width: rect.width, height: rect.height, alignment: .center)
                        .scaleEffect(1)
                        .mask(mask(in: rect).fill(style: FillStyle(eoFill: true)))
                }
            }
            if manualTempBasal {
                Text("Manual")
            } else if actualSuggestion?.timestamp != nil {
                Text(timeString)
            } else {
                Text("--")
            }
        }
        .font(.system(size: 16))
    }

    private var timeString: String {
        let minAgo = Int((timerDate.timeIntervalSince(lastLoopDate) - Config.lag) / 60) + 1
        if minAgo > 1440 {
            return "--"
        }
        return "\(minAgo) " + NSLocalizedString("min", comment: "Minutes ago since last loop")
    }

    private var color: Color {
        guard actualSuggestion?.timestamp != nil else {
            return .loopGray
        }
        guard manualTempBasal == false else {
            return .loopManualTemp
        }
        let delta = timerDate.timeIntervalSince(lastLoopDate) - Config.lag

        if delta <= 5.minutes.timeInterval {
            guard actualSuggestion?.deliverAt != nil else {
                return .loopYellow
            }
            return .loopGreen
        } else if delta <= 10.minutes.timeInterval {
            return .loopYellow
        } else {
            return .loopRed
        }
    }

    func mask(in rect: CGRect) -> Path {
        var path = Rectangle().path(in: rect)
        if !closedLoop || manualTempBasal {
            path.addPath(Rectangle().path(in: CGRect(x: rect.minX, y: rect.midY - 5, width: rect.width, height: 10)))
        }
        return path
    }

    private var actualSuggestion: Suggestion? {
        if closedLoop, enactedSuggestion?.recieved == true {
            return enactedSuggestion ?? suggestion
        } else {
            return suggestion
        }
    }
}

struct CircleProgress: View {
    @State private var rotationAngle = 0.0
    @State private var pulse = false

    private let rect = CGRect(x: 0, y: 0, width: 18, height: 18) // Same dimensions as in LoopView
    private var backgroundGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                Color(red: 0.262745098, green: 0.7333333333, blue: 0.9137254902),
                Color(red: 0.3411764706, green: 0.6666666667, blue: 0.9254901961),
                Color(red: 0.4862745098, green: 0.5450980392, blue: 0.9529411765),
                Color(red: 0.6235294118, green: 0.4235294118, blue: 0.9803921569),
                Color(red: 0.7215686275, green: 0.3411764706, blue: 1),
                Color(red: 0.6235294118, green: 0.4235294118, blue: 0.9803921569),
                Color(red: 0.4862745098, green: 0.5450980392, blue: 0.9529411765),
                Color(red: 0.3411764706, green: 0.6666666667, blue: 0.9254901961),
                Color(red: 0.262745098, green: 0.7333333333, blue: 0.9137254902)
            ]),
            center: .center,
            startAngle: .degrees(rotationAngle),
            endAngle: .degrees(rotationAngle + 360)
        )
    }

    let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    var body: some View {
        let rect = CGRect(x: 0, y: 0, width: 18, height: 18)

        ZStack {
            Circle()
                .trim(from: 0, to: 1)
//                .stroke(backgroundGradient, style: StrokeStyle(lineWidth: 3))
                .stroke(backgroundGradient, style: StrokeStyle(lineWidth: pulse ? 6 : 3.5))
                .scaleEffect(pulse ? 0.5 : 1)
                .animation(
                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                    value: pulse
                )
                .frame(width: rect.width, height: rect.height, alignment: .center)
                .onReceive(timer) { _ in
                    rotationAngle = (rotationAngle + 24).truncatingRemainder(dividingBy: 360)
                }
                .onAppear {
                    self.pulse = true
                }
        }
    }
}

struct CircleProgress_Previews: PreviewProvider {
    static var previews: some View {
        CircleProgress()
    }
}
