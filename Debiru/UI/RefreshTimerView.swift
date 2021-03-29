//
//  RefreshTimerView.swift
//  Debiru
//
//  Created by Mike Polan on 3/29/21.
//

import SwiftUI

// MARK: - View

struct RefreshTimerView: View {
    private static let intervalFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute, .hour]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    @Binding var lastUpdate: Date
    @StateObject private var viewModel: RefreshTimerViewModel = RefreshTimerViewModel()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
            makeLastUpdateText()
        }
        .onReceive(timer) { date in
            viewModel.lastChecked = date
        }
        .help("Time since thread was refreshed")
    }
    
    private func makeLastUpdateText() -> Text {
        let diff = viewModel.lastChecked.timeIntervalSince(lastUpdate)
        let interval = diff <= 0
            ? "Just a moment"
            : RefreshTimerView.intervalFormatter.string(from: diff) ?? "?"
        
        return Text("\(interval) ago")
    }
}

// MARK: - View Model

class RefreshTimerViewModel: ObservableObject {
    @Published var lastChecked: Date = Date()
}

// MARK: - Preview

struct RefreshTimerView_Previews: PreviewProvider {
    @State private static var lastUpdate = Date()
    
    static var previews: some View {
        RefreshTimerView(lastUpdate: $lastUpdate)
    }
}
