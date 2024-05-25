
import SwiftUI

struct TidepoolStartView: View {
    @ObservedObject var state: Settings.StateModel
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

    var body: some View {
        Form {
            Section(
                header: Text("Connect to Tidepool"),
                footer: VStack(alignment: .leading, spacing: 2) {
                    Text(
                        "When connected, uploading of carbs, bolus, basal and glucose from iAPS to your Tidepool account is enabled."
                    )
                    Text(
                        "\nUse your Tidepool credentials to login. If you dont already have a Tidepool account, you can sign up for one on the login page."
                    )
                }
            )
                {
                    Button("Connect to Tidepool") { state.setupTidepool = true }
                }
                .navigationTitle("Tidepool")
        }
        .scrollContentBackground(.hidden).background(color)
        .sheet(isPresented: $state.setupTidepool) {
            if let serviceUIType = state.serviceUIType,
               let pluginHost = state.provider.tidepoolManager.getTidepoolPluginHost()
            {
                if let serviceUI = state.provider.tidepoolManager.getTidepoolServiceUI() {
                    TidepoolSettingsView(
                        serviceUI: serviceUI,
                        serviceOnBoardDelegate: self.state,
                        serviceDelegate: self.state
                    )
                } else {
                    TidepoolSetupView(
                        serviceUIType: serviceUIType,
                        pluginHost: pluginHost,
                        serviceOnBoardDelegate: self.state,
                        serviceDelegate: self.state
                    )
                }
            }
        }
    }
}
