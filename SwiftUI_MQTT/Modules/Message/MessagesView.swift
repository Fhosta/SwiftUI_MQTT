//
//  ContentView.swift
//  SwiftUI_MQTT
//
//  Created by Anoop M on 2021-01-19.
//

import SwiftUI

struct MessagesView: View {
    // TODO: Remove singleton
    @StateObject var mqttManager = MQTTManager.shared()
    var body: some View {
        NavigationView {
            MessageView()
        }
        .environmentObject(mqttManager)
    }
}

struct MyData: Codable{
    var CO2Min: Int
    var CO2Max: Int
    var TVOCMin: Int
    var TVOCMax: Int
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}

struct MessageView: View {
    
    @State var topic: String = ""
    @State var topic2: String = ""
    @State var message: String = ""
    @State var data = [MyData]()
    
    @EnvironmentObject private var mqttManager: MQTTManager
    var body: some View {
        VStack {
            ConnectionStatusBar(message: mqttManager.connectionStateMessage(), isConnected: mqttManager.isConnected())
            VStack {
                HStack {
                    MQTTTextField(placeHolderMessage: "Enter a message", isDisabled: !mqttManager.isSubscribed(), message: $message)
                    Button(action: { send(message: message) }) {
                        Text("Envoyer").font(.body)
                    }.buttonStyle(BaseButtonStyle(foreground: .white, background: .green))
                        .frame(width: 80)
                        .disabled(!mqttManager.isSubscribed() || message.isEmpty)
                }
                MessageHistoryTextView(text: $mqttManager.currentAppState.historyText
                ).frame(height: 150)
            }.padding(EdgeInsets(top: 0, leading: 7, bottom: 0, trailing: 7))
            
            Spacer()
        }
        .navigationTitle("Gestion des capteurs")
        .navigationBarItems(trailing: NavigationLink(
            destination: SettingsView(brokerAddress: mqttManager.currentHost() ?? ""),
            label: {
                Image(systemName: "gear")
            }))
    }

    func fetchAPI() {
        let urlString = "http://172.16.6.53:8080/api/getParametre"

        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                if let error = error {
                    print("Error: (error.localizedDescription)")
                }
                return
            }

            // Parse the JSON data
            do {
                let decodedData = try JSONDecoder().decode([MyData].self, from: data)
                // Do something with the decoded data
                print(decodedData)
            } catch {
                print("Error: (error.localizedDescription)")
            }
        }

        task.resume()
    }
    
    private func subscribe(topic: String) {
        mqttManager.subscribe(topic: topic)
        mqttManager.subscribe(topic: topic2)
    }

    private func usubscribe() {
        mqttManager.unSubscribeFromCurrentTopic()
    }

    private func send(message: String) {
        let finalMessage = "SwiftUIIOS says: \(message)"
        mqttManager.publish(with: finalMessage)
        self.message = ""
    }

    private func titleForSubscribButtonFrom(state: MQTTAppConnectionState) -> String {
        switch state {
        case .connected, .connectedUnSubscribed, .disconnected, .connecting:
            return "Subscribe"
        case .connectedSubscribed:
            return "Unsubscribe"
        }
    }

    private func functionFor(state: MQTTAppConnectionState) -> () -> Void {
        switch state {
        case .connected, .connectedUnSubscribed, .disconnected, .connecting:
            return { subscribe(topic: topic) }
        case .connectedSubscribed:
            return { usubscribe() }
        }
    }
}
