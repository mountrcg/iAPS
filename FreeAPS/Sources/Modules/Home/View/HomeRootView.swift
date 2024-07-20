import CoreData
import SpriteKit
import SwiftDate
import SwiftUI
import Swinject

extension Home {
    struct RootView: BaseView {
        let resolver: Resolver

        @StateObject var state = StateModel()
        @State var isStatusPopupPresented = false
        @State var showCancelAlert = false
        @State var showCancelTTAlert = false
        @State var triggerUpdate = false

        struct Buttons: Identifiable {
            let label: String
            let number: String
            var active: Bool
            let hours: Int
            var id: String { label }
        }

        @State var timeButtons: [Buttons] = [
            Buttons(label: "3h", number: "3", active: false, hours: 3),
            Buttons(label: "6h", number: "6", active: false, hours: 6),
            Buttons(label: "12h", number: "12", active: false, hours: 12),
            Buttons(label: "24h", number: "24", active: false, hours: 24),
            Buttons(label: "36h", number: "36", active: false, hours: 36)
        ]

        let buttonFont = Font.custom("TimeButtonFont", size: 14)

        @Environment(\.managedObjectContext) var moc
        @Environment(\.colorScheme) var colorScheme

        @FetchRequest(
            entity: Override.entity(),
            sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
        ) var fetchedPercent: FetchedResults<Override>

        @FetchRequest(
            entity: OverridePresets.entity(),
            sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], predicate: NSPredicate(
                format: "name != %@", "" as String
            )
        ) var fetchedProfiles: FetchedResults<OverridePresets>

        @FetchRequest(
            entity: TempTargets.entity(),
            sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
        ) var sliderTTpresets: FetchedResults<TempTargets>

        @FetchRequest(
            entity: TempTargetsSlider.entity(),
            sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)]
        ) var enactedSliderTT: FetchedResults<TempTargetsSlider>

        var bolusProgressFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimum = 0
            formatter.maximumFractionDigits = state.settingsManager.preferences.bolusIncrement > 0.05 ? 1 : 2
            formatter.minimumFractionDigits = state.settingsManager.preferences.bolusIncrement > 0.05 ? 1 : 2
            formatter.allowsFloats = true
            formatter.roundingIncrement = Double(state.settingsManager.preferences.bolusIncrement) as NSNumber
            return formatter
        }

        private var numberFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2
            return formatter
        }

        private var fetchedTargetFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            if state.units == .mmolL {
                formatter.maximumFractionDigits = 1
            } else { formatter.maximumFractionDigits = 0 }
            return formatter
        }

        private var targetFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 1
            return formatter
        }

        private var tirFormatter: NumberFormatter {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter
        }

        private var dateFormatter: DateFormatter {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            return dateFormatter
        }

        private var spriteScene: SKScene {
            let scene = SnowScene()
            scene.scaleMode = .resizeFill
            scene.backgroundColor = .clear
            return scene
        }

        private var color: LinearGradient {
            colorScheme == .dark ? LinearGradient(
                gradient: Gradient(colors: [
                    Color.bgDarkBlue,
                    Color.bgDarkerDarkBlue,
                    Color.bgDarkBlue
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

        @ViewBuilder func header(_: GeometryProxy) -> some View {
            HStack {
                Spacer()
                pumpView
                Spacer()
            }
        }

        var glucoseView: some View {
            CurrentGlucoseView(
                recentGlucose: $state.recentGlucose,
                timerDate: $state.timerDate,
                delta: $state.glucoseDelta,
                units: $state.units,
                alarm: $state.alarm,
                lowGlucose: $state.lowGlucose,
                highGlucose: $state.highGlucose
            )
            .onTapGesture {
                if state.alarm == nil {
                    state.openCGM()
                } else {
                    state.showModal(for: .snooze)
                }
            }
            .onLongPressGesture {
                let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                impactHeavy.impactOccurred()
                if state.alarm == nil {
                    state.showModal(for: .snooze)
                } else {
                    state.openCGM()
                }
            }
        }

        var pumpView: some View {
            PumpView(
                reservoir: $state.reservoir,
                battery: $state.battery,
                name: $state.pumpName,
                expiresAtDate: $state.pumpExpiresAtDate,
                timerDate: $state.timerDate,
                timeZone: $state.timeZone,
                state: state
            )
            .onTapGesture {
                if state.pumpDisplayState != nil {
                    state.setupPump = true
                }
            }
        }

        var loopView: some View {
            LoopView(
                suggestion: $state.suggestion,
                enactedSuggestion: $state.enactedSuggestion,
                closedLoop: $state.closedLoop,
                timerDate: $state.timerDate,
                isLooping: $state.isLooping,
                lastLoopDate: $state.lastLoopDate,
                manualTempBasal: $state.manualTempBasal
            )
            .onTapGesture {
                state.isStatusPopupPresented.toggle()
            }.onLongPressGesture {
                let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                impactHeavy.impactOccurred()
                state.runLoop()
            }
        }

        var tempBasalString: String? {
            guard let tempRate = state.tempRate else {
                return nil
            }
            let rateString = numberFormatter.string(from: tempRate as NSNumber) ?? "0"
            var manualBasalString = ""

            if state.apsManager.isManualTempBasal {
                manualBasalString = NSLocalizedString(
                    " - Manual Basal ⚠️",
                    comment: "Manual Temp basal"
                )
            }
            return rateString + " " + NSLocalizedString(" U/hr", comment: "Unit per hour with space") + manualBasalString
        }

        var tempTargetString: String? {
            guard let tempTarget = state.tempTarget else {
                return nil
            }
            let targetSet = tempTarget.targetBottom ?? 0
            let target = state.suggestion?.current_target ?? 0
            let unitString = targetFormatter.string(from: target.asMmolL as NSNumber) ?? ""
            let rawString = (tirFormatter.string(from: target as NSNumber) ?? "") + " " + state.units
                .rawValue

            var string = ""
            if sliderTTpresets.first?.active ?? false {
                let hbt = sliderTTpresets.first?.hbt ?? 0
                string = ", " + (tirFormatter.string(from: state.infoPanelTTPercentage(hbt, target) as NSNumber) ?? "") + " %"
            }

            var percentString = state
                .units == .mmolL ? (unitString + " mmol/L" + string) : (rawString + (string == "0" ? "" : string))
            if targetSet < 80 {
                percentString = percentString + "‼️"
            }
            return tempTarget.displayName + " " + percentString
        }

        var overrideString: String? {
            guard fetchedPercent.first?.enabled ?? false else {
                return nil
            }
            var percentString = "\((fetchedPercent.first?.percentage ?? 100).formatted(.number)) %"
            var ortarget = (fetchedPercent.first?.target ?? 100) as Decimal
            let indefinite = (fetchedPercent.first?.indefinite ?? false)
            let unit = state.units.rawValue
            if state.units == .mmolL {
                ortarget = ortarget.asMmolL
            }
            var targetString = (fetchedTargetFormatter.string(from: ortarget as NSNumber) ?? "") + " " + unit
            if tempTargetString != nil || ortarget == 0 { targetString = "" }
            percentString = percentString == "100 %" ? "" : percentString

            let duration = (fetchedPercent.first?.duration ?? 0) as Decimal
            let addedMinutes = Int(duration)
            let date = fetchedPercent.first?.date ?? Date()
            var newDuration: Decimal = 0

            if date.addingTimeInterval(addedMinutes.minutes.timeInterval) > Date() {
                newDuration = Decimal(Date().distance(to: date.addingTimeInterval(addedMinutes.minutes.timeInterval)).minutes)
            }

            var durationString = indefinite ?
                "" : newDuration >= 1 ?
                (newDuration.formatted(.number.grouping(.never).rounded().precision(.fractionLength(0))) + " min") :
                (
                    newDuration > 0 ? (
                        (newDuration * 60).formatted(.number.grouping(.never).rounded().precision(.fractionLength(0))) + " s"
                    ) :
                        ""
                )

            let smbToggleString = (fetchedPercent.first?.smbIsOff ?? false) ? " \u{20e0}" : ""
            var comma1 = ", "
            var comma2 = comma1
            var comma3 = comma1
            if targetString == "" || percentString == "" { comma1 = "" }
            if durationString == "" { comma2 = "" }
            if smbToggleString == "" { comma3 = "" }

            if percentString == "", targetString == "" {
                comma1 = ""
                comma2 = ""
            }
            if percentString == "", targetString == "", smbToggleString == "" {
                durationString = ""
                comma1 = ""
                comma2 = ""
                comma3 = ""
            }
            if durationString == "" {
                comma2 = ""
            }
            if smbToggleString == "" {
                comma3 = ""
            }

            if durationString == "", !indefinite {
                return nil
            }
            return percentString + comma1 + targetString + comma2 + durationString + comma3 + smbToggleString
        }

        var infoPanel: some View {
            HStack(alignment: .center) {
                if state.pumpSuspended {
                    Text("Pump suspended")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(.loopGray)
                        .padding(.leading, 8)
                } else if let tempBasalString = tempBasalString {
                    Text(tempBasalString)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.insulin)
                        .padding(.leading, 8)
                }
                if state.tins {
                    HStack {
                        Text(
                            "TINS: \(state.calculatedTins)" +
                                NSLocalizedString(" U", comment: "Unit in number of units delivered (keep the space character!)")
                        )
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.insulin)
                        .onChange(of: state.hours) { _ in
                            state.calculatedTins = state.calculateTINS()
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                state.calculatedTins = state.calculateTINS()
                            }
                        }
                    }
                }

                if let tempTargetString = tempTargetString {
                    Text(tempTargetString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let overrideString = overrideString {
                    HStack {
                        Text("👤 " + overrideString)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                    .alert(
                        "Return to Normal?", isPresented: $showCancelAlert,
                        actions: {
                            Button("No", role: .cancel) {}
                            Button("Yes", role: .destructive) {
                                state.cancelProfile()
                            }
                        }, message: { Text("This will change settings back to your normal profile.") }
                    )
                    .padding(.trailing, 8)
                    .onTapGesture {
                        showCancelAlert = true
                    }
                }

                if state.closedLoop, state.settingsManager.preferences.maxIOB == 0 {
                    Text("Max IOB: 0").font(.callout).foregroundColor(.orange).padding(.trailing, 20)
                }

//                if let progress = state.bolusProgress {
//                    HStack {
//                        Text("Bolusing")
//                            .font(.system(size: 12, weight: .bold)).foregroundColor(.insulin)
//                        ProgressView(value: Double(progress))
//                            .progressViewStyle(BolusProgressViewStyle())
//                            .padding(.trailing, 8)
//                    }
//                    .onTapGesture {
//                        state.cancelBolus()
//                    }
//                }
            }
            .frame(maxWidth: .infinity, maxHeight: 30)
        }

        var timeInterval: some View {
            HStack(alignment: .center, spacing: 4) {
                Spacer()
                Group {
                    Text("TDD").foregroundColor(.insulin)
                    Text(numberFormatter.string(from: (state.suggestion?.tdd ?? 0) as NSNumber) ?? "0").foregroundColor(.primary)
                }.font(.system(size: 12, weight: .bold))
                Group {
                    Text("ytd.").foregroundColor(.insulin).padding(.leading, 4)
                    Text(numberFormatter.string(from: (state.suggestion?.tddytd ?? 0) as NSNumber) ?? "0")
                        .foregroundColor(.primary)
//                    Text("Ø7d").foregroundColor(.insulin).padding(.leading, 4)
//                    Text(numberFormatter.string(from: (state.suggestion?.tdd7d ?? 0) as NSNumber) ?? "0")
//                        .foregroundColor(.primary)
                }.font(.system(size: 12, weight: .regular)).foregroundColor(.insulin)
                Text(" | ")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12, weight: .light))
                    .padding(.horizontal, 8)
                ForEach(timeButtons) { button in
                    Text(button.active ? NSLocalizedString(button.label, comment: "") : button.number).onTapGesture {
                        state.hours = button.hours
                    }
                    .foregroundStyle(button.active ? (colorScheme == .dark ? Color.white : Color.black).opacity(0.9) : .secondary)
                    .frame(maxHeight: 20).padding(.horizontal, 6)
                    .background(
                        button.active ?
                            // RGB(30, 60, 95)
                            (
                                colorScheme == .dark ? Color(red: 0.1176470588, green: 0.2352941176, blue: 0.3725490196) :
                                    Color.white
                            ) :
                            Color
                            .clear
                    )
                    .cornerRadius(4)
                }
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.75 : 0.33),
                    radius: colorScheme == .dark ? 5 : 3
                )
                Spacer()
            }
            .font(buttonFont)
        }

        var legendPanel: some View {
            HStack(spacing: 0) {
                LeftLegend
                    .frame(maxWidth: .infinity, alignment: .trailing)
                loopView
                    .frame(alignment: .center)
                    .padding(.horizontal, 30)
                RightLegend
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        var LeftLegend: some View {
            HStack {
                Spacer()
                Group {
                    Circle().fill(Color.loopYellow).frame(width: 8, height: 8)
                    Text("COB")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(.loopYellow)
                    Circle().fill(Color.insulin).frame(width: 8, height: 8)
                        .padding(.leading, 12)
                    Text("IOB")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(.insulin)
                }
            }
        }

        var RightLegend: some View {
            HStack {
                Circle().fill(Color.uam).frame(width: 8, height: 8)
                Text("UAM")
                    .font(.system(size: 12, weight: .bold)).foregroundColor(.uam)
                Circle().fill(Color.zt).frame(width: 8, height: 8)
                    .padding(.leading, 12)
                Text("ZT")
                    .font(.system(size: 12, weight: .bold)).foregroundColor(.zt)
                Spacer()
            }
        }

        var mainChart: some View {
            ZStack {
                if state.animatedBackground {
                    SpriteView(scene: spriteScene, options: [.allowsTransparency])
                        .ignoresSafeArea()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                }

                MainChartView(
                    glucose: $state.glucose,
                    isManual: $state.isManual,
                    suggestion: $state.suggestion,
                    tempBasals: $state.tempBasals,
                    boluses: $state.boluses,
                    suspensions: $state.suspensions,
                    announcement: $state.announcement,
                    hours: .constant(state.filteredHours),
                    maxBasal: $state.maxBasal,
                    autotunedBasalProfile: $state.autotunedBasalProfile,
                    basalProfile: $state.basalProfile,
                    tempTargets: $state.tempTargets,
                    carbs: $state.carbs,
                    timerDate: $state.timerDate,
                    units: $state.units,
                    smooth: $state.smooth,
                    highGlucose: $state.highGlucose,
                    lowGlucose: $state.lowGlucose,
                    screenHours: $state.hours,
                    displayXgridLines: $state.displayXgridLines,
                    displayYgridLines: $state.displayYgridLines,
                    thresholdLines: $state.thresholdLines,
                    triggerUpdate: $triggerUpdate,
                    overrideHistory: $state.overrideHistory
                )
            }
            .padding(.bottom)
            .modal(for: .dataTable, from: self)
        }

        func highlightButtons() {
            for i in 0 ..< timeButtons.count {
                timeButtons[i].active = timeButtons[i].hours == state.hours
            }
        }

        @ViewBuilder private func bottomPanel(_: GeometryProxy) -> some View {
            let colorIcon: Color = (colorScheme == .dark ? Color.white : Color.black).opacity(0.9)

            ZStack {
                Rectangle()
                    .fill(Color("Chart"))
                    .frame(height: UIScreen.main.bounds.height / 13)
                    .cornerRadius(15)
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.75) : Color.black.opacity(0.33),
                        radius: colorScheme == .dark ? 5 : 3
                    )
                    .padding([.leading, .trailing], 10)

                HStack(alignment: .bottom) {
                    Button { state.showModal(for: .addCarbs(editMode: false, override: false)) }
                    label: {
                        ZStack(alignment: Alignment(horizontal: .trailing, vertical: .bottom)) {
                            Image("carbs1")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 30, height: 30)
//                                .foregroundColor(.loopYellow)
                                .padding(8)
                            if let carbsReq = state.carbsRequired {
                                Text(numberFormatter.string(from: carbsReq as NSNumber)!)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Capsule().fill(Color.red))
                            }
                        }
                    }
                    .foregroundColor(colorIcon)
                    .buttonStyle(.borderless)
                    Spacer()
                    Button {
                        state.showModal(for: .bolus(
                            waitForSuggestion: true,
                            fetch: false
                        ))
                    }
                    label: {
                        Image("bolus")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 30, height: 30)
//                            .foregroundColor(.insulin)
                            .padding(8)
                    }
                    .foregroundColor(colorIcon)
                    .buttonStyle(.borderless)
                    Spacer()
                    Button { state.showModal(for: .addTempTarget) }
                    label: {
                        Image("target1")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 30, height: 30)
//                            .foregroundColor(.loopGreen)
                            .padding(8)
                    }
                    .foregroundColor(colorIcon)
                    .buttonStyle(.borderless)
                    Spacer()
                    if state.allowManualTemp {
                        Button { state.showModal(for: .manualTempBasal) }
                        label: {
                            Image("bolus1")
                                .renderingMode(.template)
                                .resizable()
//                                .foregroundColor(.basal)
                                .frame(width: 30, height: 30)
                                .padding(8)
                        }
                        .foregroundColor(colorIcon)
                        .buttonStyle(.borderless)
                        Spacer()
                    }

                    // overide profiles
//                    Button {
//                        state.showModal(for: .overrideProfilesConfig)
//                    } label: {
//                        Image(systemName: "person")
//                            .font(.system(size: 30, weight: .light))
//                            .padding(8)
//                    }
//                    .foregroundColor(colorIcon)
//                    .buttonStyle(.borderless)
//                    Spacer()

                    Image("statistics")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 30, height: 30)
                        .padding(8)
//                        .foregroundColor(.uam)
                        .onTapGesture { state.showModal(for: .statistics) }
                        .onLongPressGesture {
                            let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                            impactHeavy.impactOccurred()
                            state.showModal(for: .autoisf)
                        }
                        .foregroundColor(colorIcon)
                        .buttonStyle(.borderless)

                    Spacer()
                    Button { state.showModal(for: .settings) }
                    label: {
                        Image("settings")
                            .renderingMode(.template)
                            .resizable()
//                                .foregroundColor(.secondary)
                            .frame(width: 30, height: 30)
                            .padding(8)
                    }
                    .foregroundColor(colorIcon)
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }

        @ViewBuilder func bolusProgressBar(_ progress: Decimal) -> some View {
            GeometryReader { geo in
                Rectangle()
                    .frame(height: 6)
                    .foregroundColor(.clear)
                    .background(
                        LinearGradient(colors: [
                            Color(red: 0.262745098, green: 0.7333333333, blue: 0.9137254902),
                            Color(red: 0.3411764706, green: 0.6666666667, blue: 0.9254901961),
                            Color(red: 0.4862745098, green: 0.5450980392, blue: 0.9529411765),
                            Color(red: 0.6235294118, green: 0.4235294118, blue: 0.9803921569),
                            Color(red: 0.7215686275, green: 0.3411764706, blue: 1)
                        ], startPoint: .leading, endPoint: .trailing)
                            .mask(alignment: .leading) {
                                Rectangle()
                                    .frame(width: geo.size.width * CGFloat(progress))
                            }
                    )
            }
        }

        @ViewBuilder func bolusProgressView(_: GeometryProxy, _ progress: Decimal, _ amount: Decimal) -> some View {
            let colorRectangle: Color = colorScheme == .dark ? Color(
                "Chart"
            ) : Color.white

            let colorIcon = (colorScheme == .dark ? Color.white : Color.black).opacity(0.9)

            let bolusFraction = progress * amount

            let bolusString =
                (
                    bolusProgressFormatter
                        .string(from: bolusFraction as NSNumber) ??
                        "0"
                )
                + " of " +
                (numberFormatter.string(from: amount as NSNumber) ?? "0")
                + NSLocalizedString(" U", comment: "Insulin unit")

            ZStack(alignment: .bottom) {
                HStack {
                    Text("Bolusing")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text(bolusString)
                        .font(.subheadline)
                    Spacer()
                    Button {
                        state.cancelBolus()
                    } label: {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 22))
                            .padding(1)
                    }.foregroundColor(colorIcon)
                }.padding()

                bolusProgressBar(progress).offset(y: 48)
            }
            .background(colorRectangle)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(height: 20, alignment: .center)
            .padding(10)
            .onTapGesture {
                state.isStatusPopupPresented.toggle() }
        }

        var body: some View {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    ZStack(alignment: .bottomTrailing) {
                        glucoseView
                        if let eventualBG = state.eventualBG {
                            Text(
                                "⇢ " + targetFormatter.string(
                                    from: (
                                        state.units == .mmolL ? eventualBG
                                            .asMmolL : Decimal(eventualBG)
                                    ) as NSNumber
                                )!
                            )
                            .font(.system(size: 18, weight: .bold)).foregroundColor(.secondary)
                            .offset(x: 45, y: 4)
                        }
                    }.padding(.top, 10)

                    Spacer()

                    header(geo)
                        .padding(.top, 15)
                        .padding(.horizontal, 10)

                    Spacer()

                    infoPanel
                        .padding(.horizontal, 10)

                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color("Chart"))
                        .overlay(mainChart)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(
                            color: colorScheme == .dark ? Color.black.opacity(0.75) : Color.black.opacity(0.33),
                            radius: colorScheme == .dark ? 5 : 3
                        )
                        .padding(.horizontal, 10)
                        .frame(maxHeight: UIScreen.main.bounds.height / 2.2)

                    Spacer()

                    timeInterval

                    Spacer()

                    ZStack(alignment: .bottom) {
                        legendPanel
                        if let progress = state.bolusProgress, let amount = state.bolusAmount {
                            bolusProgressView(geo, progress, amount)
                        }
                    }

                    Spacer()

                    bottomPanel(geo)
                }
                .background(color)
                .edgesIgnoringSafeArea([.horizontal, .bottom])
            }
            .onChange(of: state.hours) { _ in
                highlightButtons()
            }
            .onAppear {
                configureView {
                    highlightButtons()
                }
            }
            .navigationTitle("Home")
            .navigationBarHidden(true)
            .ignoresSafeArea(.keyboard)
            .popup(isPresented: state.isStatusPopupPresented, alignment: .top, direction: .bottom) {
                VStack {
                    Rectangle().opacity(0).frame(height: 220)
                    popup
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(colorScheme == .dark ? Color(
                                    red: 0.05490196078,
                                    green: 0.05490196078,
                                    blue: 0.05490196078
                                ) : Color(UIColor.darkGray))
                        )
                        .opacity(0.8)
                        .onTapGesture {
                            state.isStatusPopupPresented = false
                        }
                        .gesture(
                            DragGesture(minimumDistance: 10, coordinateSpace: .local)
                                .onEnded { value in
                                    if value.translation.height > 0 {
                                        state.isStatusPopupPresented = false
                                    }
                                }
                        )
                }
            }
        }

        private var popup: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(state.statusTitle).font(.headline).foregroundColor(.white)
                    .padding(.bottom, 4)
                if let suggestion = state.suggestion {
                    TagCloudView(tags: suggestion.reasonParts).animation(.none, value: false)

                    Text(suggestion.reasonConclusion.capitalizingFirstLetter()).font(.caption).foregroundColor(.white)

                } else {
                    Text("No sugestion found").font(.body).foregroundColor(.white)
                }

                if let errorMessage = state.errorMessage, let date = state.errorDate {
                    Text(NSLocalizedString("Error at", comment: "") + " " + dateFormatter.string(from: date))
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.bottom, 4)
                        .padding(.top, 8)
                    Text(errorMessage).font(.caption).foregroundColor(.loopRed)
                } else if let suggestion = state.suggestion, (suggestion.bg ?? 100) == 400 {
                    Text("Invalid CGM reading (HIGH).").font(.callout).bold().foregroundColor(.loopRed).padding(.top, 8)
                    Text("SMBs and High Temps Disabled.").font(.caption).foregroundColor(.white).padding(.bottom, 4)
                }
            }
        }
    }
}
