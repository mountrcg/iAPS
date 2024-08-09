import Charts
import SwiftUI

struct TDDChartView: View {
    @Binding var selectedDays: Int
    @Binding var dailyTotalDoses: [(date: Date, dose: NSDecimalNumber)]

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d" // Only day format
        return formatter
    }

    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM" // Only month format
        return formatter
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("Select # of days for ∅-TDD")
            Picker("Days", selection: $selectedDays) {
                ForEach([3, 5, 7, 10, 14, 28], id: \.self) { days in
                    Text("\(days)").tag(days)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 4)

            Chart {
                ForEach(completeData(forDays: selectedDays), id: \.date) { entry in
                    BarMark(
                        x: .value("Day", dayFormatter.string(from: entry.date)), // Use day number as category
                        y: .value("Dose", entry.dose.doubleValue)
                    )
                    .annotation(position: .top) {
                        Text("\(entry.dose.doubleValue, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    .foregroundStyle(Color.insulin)
                }
            }
            .chartXAxis {
                AxisMarks(values: xAxisValues()) { value in
                    AxisValueLabel(centered: true) {
                        if let dayStr = value.as(String.self) {
                            Text(dayStr)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .padding()

            // Display the month(s) below the chart
            HStack {
                if let leftMonth = leftMonthLabel(), let rightMonth = rightMonthLabel() {
                    Text(leftMonth)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(alignment: .leading)
                    Spacer()
                    if leftMonth != rightMonth {
                        Text(rightMonth)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(alignment: .trailing)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.trailing, 8)
            .padding(.top, -20)
            Spacer()
        }
    }

    private func completeData(forDays days: Int) -> [(date: Date, dose: NSDecimalNumber)] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date().addingTimeInterval(-86400)) // Exclude the current day
        let startDate = calendar.date(byAdding: .day, value: -days + 1, to: endDate)!
        var completeData: [(date: Date, dose: NSDecimalNumber)] = []
        var currentDate = startDate
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            if let existingEntry = dailyTotalDoses.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) {
                completeData.append(existingEntry)
            } else {
                completeData.append((date: dayStart, dose: .zero))
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return completeData
    }

    private func leftMonthLabel() -> String? {
        guard let firstDate = completeData(forDays: selectedDays).first?.date else { return nil }
        return monthFormatter.string(from: firstDate)
    }

    private func rightMonthLabel() -> String? {
        let data = completeData(forDays: selectedDays)
        guard let lastDate = data.last?.date else { return nil }
        return monthFormatter.string(from: lastDate)
    }

    private func xAxisValues() -> [String] {
        let calendar = Calendar.current
        var values = completeData(forDays: selectedDays).map { dayFormatter.string(from: $0.date) }

        // Show only odd days if selectedDays > 14
        if selectedDays > 14 {
            values = values.enumerated().compactMap { index, element in
                let date = completeData(forDays: selectedDays)[index].date
                return calendar.component(.day, from: date) % 2 != 0 ? element : nil
            }
        }
        return values
    }
}
