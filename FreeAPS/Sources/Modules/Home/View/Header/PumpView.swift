import SwiftUI

struct PumpView: View {
    @Binding var reservoir: Decimal?
    @Binding var battery: Battery?
    @Binding var name: String
    @Binding var expiresAtDate: Date?
    @Binding var timerDate: Date
    @Binding var timeZone: TimeZone?

    @State var state: Home.StateModel

    @Environment(\.colorScheme) var colorScheme

    private var reservoirFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }

    private var batteryFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }

    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        return dateFormatter
    }

    private var glucoseFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        if state.units == .mmolL {
            formatter.minimumFractionDigits = 1
            formatter.maximumFractionDigits = 1
        }
        formatter.roundingMode = .halfUp
        return formatter
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
//            Text("COB").font(.caption2).foregroundColor(.secondary)
            Image("premeal")
                .renderingMode(.template)
                .resizable()
                .frame(width: 12, height: 12)
                .foregroundColor(.loopYellow)
            Text(
                numberFormatter
                    .string(from: (state.suggestion?.cob ?? 0) as NSNumber) ?? "0" +
                    NSLocalizedString(" g", comment: "gram of carbs")
            )
            .font(.callout).fontWeight(.bold)

            Spacer()

//            Text("IOB").font(.caption2).foregroundColor(.secondary)
//            Image("bolus1")
//                .renderingMode(.template)
//                .resizable()
//                .frame(width: 12, height: 12)
//                .foregroundColor(.insulin)
            Image(systemName: "drop.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 12)
                .foregroundColor(Color.insulin)
            Text(
                numberFormatter
                    .string(from: (state.suggestion?.iob ?? 0) as NSNumber) ?? "0" +
                    NSLocalizedString(" U", comment: "Insulin unit")
            )
            .font(.callout).fontWeight(.bold)

            Spacer()

            Text("ISF").font(.caption2).foregroundColor(.secondary)
            let isf = state.units == .mmolL ? state.suggestion?.isf?.asMmolL : state.suggestion?.isf
            Text(
                glucoseFormatter
                    .string(from: (isf ?? 0) as NSNumber) ?? "0"
            )
            .font(.callout).fontWeight(.bold)

            Spacer()

            if let reservoir = reservoir {
                HStack {
                    Image(systemName: "drop.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 12)
                        .foregroundColor(reservoirColor)
                    if reservoir == 0xDEAD_BEEF {
                        Text("50+ " + NSLocalizedString("U", comment: "Insulin unit")).font(.callout).fontWeight(.bold)
                    } else {
                        Text(
                            reservoirFormatter
                                .string(from: reservoir as NSNumber)! + NSLocalizedString(" U", comment: "Insulin unit")
                        )
                        .font(.callout).fontWeight(.bold)
                    }
                }

                if let timeZone = timeZone, timeZone.secondsFromGMT() != TimeZone.current.secondsFromGMT() {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .font(.system(size: 15))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.red, Color(.warning))
                }
            }

            Spacer()

            if let battery = battery, battery.display ?? false, expiresAtDate == nil {
                HStack {
                    Image(systemName: "battery.100")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 12)
                        .foregroundColor(batteryColor)
                    Text("\(Int(battery.percent ?? 100)) %").font(.callout)
                        .fontWeight(.bold)
                }
            }

            if let date = expiresAtDate {
                HStack {
                    Image(systemName: "stopwatch.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 12)
                        .foregroundColor(timerColor)
                    Text(remainingTimeString(time: date.timeIntervalSince(timerDate))).font(.callout).fontWeight(.bold)
                }
            }
        }
    }

    private func remainingTimeString(time: TimeInterval) -> String {
        guard (time + 7) > 0 else {
            return NSLocalizedString("Replace pod", comment: "View/Header when pod expired")
        }

//        var time = time
//        let days = Int(time / 1.days.timeInterval)
//        time -= days.days.timeInterval
//        let hours = Int(time / 1.hours.timeInterval)
//        time -= hours.hours.timeInterval
//        let minutes = Int(time / 1.minutes.timeInterval)

        let remainingTime = time + 8 * 60 * 60
        let hours = floor(remainingTime / 60 / 60)
        let minutes = floor((remainingTime - (hours * 60 * 60)) / 60)

        if hours >= 8 {
            return "\(Int(hours))" + NSLocalizedString("h", comment: "abbreviation for hours")
        }

        if hours >= 1 {
            return "\(Int(hours))" + NSLocalizedString("h", comment: "abbreviation for hours") + ":\(Int(minutes))" +
                NSLocalizedString("m", comment: "abbreviation for minutes")
        }

        return "\(Int(minutes))" + NSLocalizedString("m", comment: "abbreviation for minutes")
    }

    private var batteryColor: Color {
        guard let battery = battery, let percent = battery.percent else {
            return .gray
        }

        switch percent {
        case ...10:
            return .red
        case ...20:
            return .yellow
        default:
            return .green
        }
    }

    private var reservoirColor: Color {
        guard let reservoir = reservoir else {
            return .gray
        }

        switch reservoir {
        case ...10:
            return .red
        case ...30:
            return .yellow
        default:
            return .blue
        }
    }

    private var timerColor: Color {
        guard let expisesAt = expiresAtDate else {
            return .gray
        }

        let time = expisesAt.timeIntervalSince(timerDate)

        switch time {
        case ...8.hours.timeInterval:
            return .red
        case ...1.days.timeInterval:
            return .yellow
        default:
            return .green
        }
    }
}

struct Hairline: View {
    let color: Color

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: UIScreen.main.bounds.width / 1.3, height: 1)
            .opacity(0.5)
    }
}
