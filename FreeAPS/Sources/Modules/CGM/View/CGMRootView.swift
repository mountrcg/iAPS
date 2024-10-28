import LoopKitUI
import SwiftUI
import Swinject

extension CGM {
    struct RootView: BaseView {
        let resolver: Resolver
        let displayClose: Bool
        @StateObject var state = StateModel()
        @State private var setupCGM = false

        @Environment(\.colorScheme) var colorScheme
        var color: LinearGradient {
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

        // @AppStorage(UserDefaults.BTKey.cgmTransmitterDeviceAddress.rawValue) private var cgmTransmitterDeviceAddress: String? = nil

        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("CGM")) {
                        Picker("Type", selection: $state.cgmCurrent) {
                            ForEach(state.listOfCGM) { type in
                                VStack(alignment: .leading) {
                                    Text(type.displayName)
                                    Text(type.subtitle).font(.caption).foregroundColor(.secondary)
                                }.tag(type)
                            }
                        }
                        if let link = state.cgmCurrent.type.externalLink {
                            Button("About this source") {
                                UIApplication.shared.open(link, options: [:], completionHandler: nil)
                            }
                        }

                        if let appURL = state.urlOfApp()
                        {
                            Section {
                                Button {
                                    UIApplication.shared.open(appURL, options: [:]) { success in
                                        if !success {
                                            self.router.alertMessage
                                                .send(MessageContent(content: "Unable to open the app", type: .warning))
                                        }
                                    }
                                }
                                label: {
                                    Label(state.displayNameOfApp() ?? "-", systemImage: "waveform.path.ecg.rectangle") }
                            }
                        } else if state.cgmCurrent.type == .nightscout {
                            if let url = state.url {
                                Section {
                                    Button {
                                        UIApplication.shared.open(url, options: [:]) { success in
                                            if !success {
                                                self.router.alertMessage
                                                    .send(MessageContent(content: "No URL available", type: .warning))
                                            }
                                        }
                                    }
                                    label: { Label("Open Nightscout", systemImage: "waveform.path.ecg.rectangle") }
                                }
                            } else {
                                Section {
                                    Button { state.showModal(for: .nighscoutConfigDirect) }
                                    label: { Label("Configure Nightscout", systemImage: "waveform.path.ecg.rectangle")
                                    }
                                }
                            }
                        }

                        if state.cgmCurrent.type == .plugin {
                            Section {
                                Button("CGM Configuration") {
                                    setupCGM.toggle()
                                }
                            }
                        }
                    }
                    if state.cgmCurrent.type == .xdrip {
                        Section(header: Text("Heartbeat")) {
                            VStack(alignment: .leading) {
                                if let cgmTransmitterDeviceAddress = state.cgmTransmitterDeviceAddress {
                                    Text("CGM address :")
                                    Text(cgmTransmitterDeviceAddress)
                                } else {
                                    Text("CGM is not used as heartbeat.")
                                }
                            }
                        }
                    }
                    if state.cgmCurrent.type == .plugin && state.cgmCurrent.id.contains("Libre") {
                        Section(header: Text("Calibrations")) {
                            Text("Calibrations").navigationLink(to: .calibrations, from: self)
                        }
                    }

                    // }

                    Section(header: Text("Calendar")) {
                        Toggle("Create Events in Calendar", isOn: $state.createCalendarEvents)
                        if state.calendarIDs.isNotEmpty {
                            Picker("Calendar", selection: $state.currentCalendarID) {
                                ForEach(state.calendarIDs, id: \.self) {
                                    Text($0).tag($0)
                                }
                            }
                            Toggle("Display Emojis as Labels", isOn: $state.displayCalendarEmojis)
                            Toggle("Display IOB and COB", isOn: $state.displayCalendarIOBandCOB)
                        } else if state.createCalendarEvents {
                            if #available(iOS 17.0, *) {
                                Text(
                                    "If you are not seeing calendars to choose here, please go to Settings -> iAPS -> Calendars and change permissions to \"Full Access\""
                                ).font(.footnote)

                                Button("Open Settings") {
                                    // Get the settings URL and open it
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        }
                    }

                    Section(header: Text("Experimental")) {
                        Toggle("Smooth Glucose Value", isOn: $state.smoothGlucose)
                    }
                }
                .background(color)
                .onAppear(perform: configureView)
                .navigationTitle("CGM")
                .navigationBarTitleDisplayMode(.automatic)
                .navigationBarItems(leading: displayClose ? Button("Close", action: state.hideModal) : nil)
                .sheet(isPresented: $setupCGM) {
                    if let cgmFetchManager = state.cgmManager,
                       let cgmManager = cgmFetchManager.cgmManager,
                       state.cgmCurrent.type == cgmFetchManager.cgmGlucoseSourceType,
                       state.cgmCurrent.id == cgmFetchManager.cgmGlucosePluginId
                    {
                        CGMSettingsView(
                            cgmManager: cgmManager,
                            bluetoothManager: state.provider.apsManager.bluetoothManager!,
                            unit: state.settingsManager.settings.units,
                            completionDelegate: state
                        )
                    } else {
                        CGMSetupView(
                            CGMType: state.cgmCurrent,
                            bluetoothManager: state.provider.apsManager.bluetoothManager!,
                            unit: state.settingsManager.settings.units,
                            completionDelegate: state,
                            setupDelegate: state,
                            pluginCGMManager: self.state.pluginCGMManager
                        )
                    }
                }
                .onChange(of: setupCGM) { setupCGM in
                    state.setupCGM = setupCGM
                }
                .onChange(of: state.setupCGM) { setupCGM in
                    self.setupCGM = setupCGM
                }
            }
        }
    }
}
