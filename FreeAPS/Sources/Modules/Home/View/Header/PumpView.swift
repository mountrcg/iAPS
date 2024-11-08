import SwiftUI

struct PumpView: View {
    @Binding var reservoir: Decimal?
    @Binding var battery: Battery?
    @Binding var name: String
    @Binding var expiresAtDate: Date?
    @Binding var timerDate: Date
    @Binding var timeZone: TimeZone?
//    @Binding var pumpStatusHighlightMessage: String?
//    @Binding var selectedDays: Int // Default value is 7 days
//    @Binding var selectedEndDate: Date
//    @Binding var dailyTotalDoses: [(date: Date, dose: NSDecimalNumber)]
//    var averageTDD: NSDecimalNumber
    var ytdTDDValue: Decimal
//    var totalInsulinDisplayType: TotalInsulinDisplayType
//    var roundedTotalBolus: String
//    var hours: Int16 = 6
//    var totalDaily: String
    @State var state: Home.StateModel


    @Environment(\.colorScheme) var colorScheme
    private var color: LinearGradient {
        colorScheme == .dark ? LinearGradient(
            gradient: Gradient(colors: [
                Color.bgDarkBlue,
                Color.bgDarkerDarkBlue
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
            :
            LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
    }

    @State private var isPickerPresented = false

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

    var body: some View {
        HStack(spacing: 4) {
            Spacer()

//            if let pumpStatusHighlightMessage = pumpStatusHighlightMessage {
//                Text(pumpStatusHighlightMessage)
//                    .font(.footnote)
//                    .fontWeight(.bold)
//                    .layoutPriority(2) // Higher priority to ensure it scales less
//            } else {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if reservoir == nil && battery == nil {
                        Image(systemName: "keyboard.onehanded.left")
                            .font(.body)
                            .imageScale(.large)
                        Text("Add pump")
                            .font(.caption)
                            .bold()
                            .layoutPriority(1)
                    }

                    if let reservoir = reservoir {
                        HStack(spacing: 4) {
                            Image(systemName: "cross.vial.fill")
                                .font(.system(size: 16))
                                .foregroundColor(reservoirColor)
                            if reservoir == 0xDEAD_BEEF {
                                Text("50+ " + NSLocalizedString("U", comment: "Insulin unit"))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .layoutPriority(2)
                            } else {
                                Text(
                                    reservoirFormatter
                                        .string(from: reservoir as NSNumber)! + NSLocalizedString(" U", comment: "Insulin unit")
                                )
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .layoutPriority(2)
                            }
                        }

                        if let timeZone = timeZone, timeZone.secondsFromGMT() != TimeZone.current.secondsFromGMT() {
                            Image(systemName: "clock.badge.exclamationmark.fill")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.red, Color(.warning))
                                .layoutPriority(1)
                        }
                    }

                    if let battery = battery, battery.display ?? false, expiresAtDate == nil {
                        HStack {
                            Image(systemName: "battery.100")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .symbolRenderingMode(.palette)
                                .foregroundColor(batteryColor)
                                .layoutPriority(1)
                            Text("\(Int(battery.percent ?? 100)) %")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                    }

                    if let date = expiresAtDate {
                        HStack(spacing: 4) {
                            Image(systemName: "stopwatch.fill")
                                .font(.system(size: 16))
                                .foregroundColor(timerColor)
                                .layoutPriority(1)
                            Text(remainingTimeString(time: date.timeIntervalSince(timerDate)))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                    }
                }
//            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "ivfluid.bag")
                    .font(.system(size: 16))
                    .foregroundColor(.insulin)
                    .layoutPriority(1)
//                if totalInsulinDisplayType == .totalDailyDose {
//                    Text("∅\(selectedDays)d")
//                        .foregroundColor(.insulin)
//                        .font(.system(size: 15))
//                        .layoutPriority(1)
//                    Text(numberFormatter.string(from: averageTDD as NSNumber) ?? "")
//                        .font(.system(size: 16, design: .rounded))
//                        .layoutPriority(2)
//                }
                Text("ytd")
                    .foregroundColor(.insulin)
                    .font(.system(size: 15))
                    .layoutPriority(1)
                Text("\(ytdTDDValue)")
                    .font(.system(size: 16, design: .rounded))
                    .layoutPriority(2)
                Text("24h")
                    .foregroundColor(.insulin)
                    .font(.system(size: 16))
                    .layoutPriority(1)
                Text(totalDaily)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .layoutPriority(2)
//                if totalInsulinDisplayType == .totalInsulinInScope {
//                    Text("TINS")
//                        .foregroundColor(.insulin)
//                        .font(.system(size: 16))
//                        .layoutPriority(1)
//                    Text(roundedTotalBolus)
//                        .font(.system(size: 16, weight: .bold, design: .rounded))
//                        .layoutPriority(2)
//                }
//                }
//            .onTapGesture {
//                isPickerPresented = true
//            }
//            .sheet(isPresented: $isPickerPresented) {
//                NavigationView {
//                    TDDChartView(
//                        selectedDays: $selectedDays,
//                        selectedEndDate: $selectedEndDate,
//                        dailyTotalDoses: $dailyTotalDoses,
//                        averageTDD: averageTDD,
//                        ytdTDD: ytdTDD,
//                        totalDaily: totalDaily
//                    )
//                    .scrollContentBackground(.hidden).background(color)
//                    .navigationTitle("Total Daily Doses")
//                    .navigationBarTitleDisplayMode(.inline)
//                    .toolbar(content: {
//                        ToolbarItem(placement: .topBarLeading) {
//                            Button {
//                                isPickerPresented = false } label: {
//                                Text("Close").foregroundColor(.blue)
//                            }
//                        }
//                    })
//                }
            }

            Spacer()
        }
        .lineLimit(1) // Ensure all text stays on a single line
        .minimumScaleFactor(0.5) // Allow the text to scale down if needed
        .fixedSize(horizontal: false, vertical: true) // Prevent vertical scaling
    }

    private func remainingTimeString(time: TimeInterval) -> String {
        guard time > 0 else {
            return NSLocalizedString("Replace pod", comment: "View/Header when pod expired")
        }

        var time = time
        let days = Int(time / 1.days.timeInterval)
        time -= days.days.timeInterval
        let hours = Int(time / 1.hours.timeInterval)
        time -= hours.hours.timeInterval
        let minutes = Int(time / 1.minutes.timeInterval)

        if days >= 1 {
            return "\(days)" + NSLocalizedString("d", comment: "abbreviation for days") + " \(hours)" +
                NSLocalizedString("h", comment: "abbreviation for hours")
        }

        if hours >= 1 {
            return "\(hours)" + NSLocalizedString("h", comment: "abbreviation for hours")
        }

        return "\(minutes)" + NSLocalizedString("m", comment: "abbreviation for minutes")
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
        guard let expiresAt = expiresAtDate else {
            return .gray
        }

        let time = expiresAt.timeIntervalSince(timerDate)

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
