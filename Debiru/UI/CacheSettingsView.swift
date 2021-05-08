//
//  CacheSettingsView.swift
//  Debiru
//
//  Created by Mike Polan on 5/7/21.
//

import Combine
import SwiftUI

// MARK: - View

struct CacheSettingsView: View {
    private static let stepSize: Int = 1 // 1 MB
    
    @AppStorage(StorageKeys.maximumCacheSize) private var maximumCacheSize: Int =
        UserDefaults.standard.maximumCacheSize()
    @AppStorage(StorageKeys.cacheEnabled) private var cacheEnabled: Bool =
        UserDefaults.standard.cacheEnabled()
    @AppStorage(StorageKeys.limitCacheEnabled) private var limitCacheEnabled: Bool =
        UserDefaults.standard.limitCacheEnabled()
    
    @ObservedObject private var viewModel: CacheSettingsViewModel = CacheSettingsViewModel()
    
    private let byteFormatter = { () -> ByteCountFormatter in
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        return formatter
    }()
    
    var body: some View {
        let maximumCacheSizeBinding = Binding<String>(
            get: { String(maximumCacheSize) },
            set: { value in
                guard let number = Int(value) else { return }
                maximumCacheSize = number < 0 ? 0 : number
            })
        
        Form {
            VStack(alignment: .leading) {
                Toggle("Enable caching", isOn: $cacheEnabled)
                Toggle("Limit amount of data to be cached", isOn: $limitCacheEnabled)
                    .disabled(!cacheEnabled)
                
                LazyVGrid(columns: [
                    GridItem(.fixed(300)),
                    GridItem(.fixed(100), spacing: 0.0, alignment: .trailing),
                ], alignment: .leading) {
                    Text("Maximum amount of data to cache (MB)")
                    
                    Stepper(onIncrement: { handleStepCacheSize(CacheSettingsView.stepSize) },
                            onDecrement: { handleStepCacheSize(-CacheSettingsView.stepSize) }) {
                        
                        TextField("", text: maximumCacheSizeBinding)
                    }
                }
                .disabled(!cacheEnabled || !limitCacheEnabled)
                
                makeCacheStatisticsText()
                    .disabled(!cacheEnabled)
                
                HStack {
                    Text("Purge all cached data")
                    
                    Spacer()
                    
                    Button("Clear") {
                        handleClearCache()
                    }
                }
                .disabled(!cacheEnabled)
            }
            
        }
        .frame(width: 400, height: 120)
        .onChange(of: cacheEnabled) { value in
            DataCache.shared.setEnabled(value)
        }
        .onChange(of: limitCacheEnabled) { value in
            if !value {
                DataCache.shared.updateMaximumCost(0)
            } else {
                DataCache.shared.updateMaximumCost(maximumCacheSize)
            }
        }
        .onChange(of: maximumCacheSize) { value in
            // convert megabytes into bytes
            DataCache.shared.updateMaximumCost(value * 1024 * 1024)
        }
        .onAppear {
            viewModel.statistics = DataCache.shared.statistics
            viewModel.statisticsSink = DataCache.shared.statisticsSubject.sink { statistics in
                viewModel.statistics = statistics
            }
        }
        .onDisappear {
            viewModel.statisticsSink = nil
        }
    }
    
    private func makeCacheStatisticsText() -> Text {
        let count = byteFormatter.string(fromByteCount: Int64(viewModel.statistics.cost))
        
        return Text("Current cache statistics: estimated size is \(count), storing \(viewModel.statistics.count) item(s).")
    }
    
    private func handleStepCacheSize(_ size: Int) {
        if maximumCacheSize + size < 1 {
            maximumCacheSize = 1
        } else {
            maximumCacheSize += size
        }
    }
    
    private func handleClearCache() {
        DataCache.shared.clear()
    }
}

// MARK: - View Model

class CacheSettingsViewModel: ObservableObject {
    @Published var statistics: DataCache.Statistics = DataCache.shared.statistics
    @Published var statisticsSink: AnyCancellable?
}

// MARK: - Preview

struct CacheSettingsView_Preview: PreviewProvider {
    static var previews: some View {
        CacheSettingsView()
    }
}
