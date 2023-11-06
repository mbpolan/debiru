//
//  ThreadMetricsView.swift
//  Debiru
//
//  Created by Mike Polan on 3/28/21.
//

import SwiftUI

// MARK: - View

struct ThreadMetricsView: View {
    // a default number formatter for human readable statistics
    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
    
    struct Metric: OptionSet {
        let rawValue: Int
        
        static let replies = Metric(rawValue: 1 << 0)
        static let images = Metric(rawValue: 1 << 1)
        static let uniquePosters = Metric(rawValue: 1 << 2)
        static let page = Metric(rawValue: 1 << 3)
        
        static let all: Metric = [.replies, .images, .uniquePosters, .page]
    }
    
    let replies: Int?
    let images: Int?
    let uniquePosters: Int?
    let bumpLimit: Bool
    let imageLimit: Bool
    let page: Int?
    var metrics: Metric
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            makeMetricView(.replies, icon: "message.fill", value: replies)
                .foregroundColor(Color(bumpLimit ? PFColor.systemRed : PFTextColor))
                .help("Number of replies to original post")
            
            makeMetricView(.images, icon: "photo.fill", value: images)
                .foregroundColor(Color(imageLimit ? PFColor.systemRed : PFTextColor))
                .help("Number of replies containing images")
            
            makeMetricView(.uniquePosters, icon: "person.2.fill", value: uniquePosters)
                .help("Number of unique posters in this thread")
            
            makeMetricView(.page, icon: "text.book.closed.fill", value: page)
                .help("The page this thread is currently on in the catalog")
        }
    }
    
    private func makeMetricView(_ metric: Metric, icon: String, value: Int?) -> AnyView {
        if metrics.contains(.all) || metrics.contains(metric) {
            return Group {
                Image(systemName: icon)
                makeNumberText(value)
                    .lineLimit(1)
            }
            .toErasedView()
        } else {
            return EmptyView().toErasedView()
        }
    }
    
    private func makeNumberText(_ number: Int?) -> Text {
        var text: String?
        if let number = number {
            text = ThreadMetricsView.numberFormatter.string(from: NSNumber(value: number))
        }
        
        return Text(text ?? "?")
    }
}

// MARK: - Preview

struct ThreadMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        ThreadMetricsView(replies: 1,
                          images: 2,
                          uniquePosters: 1,
                          bumpLimit: true,
                          imageLimit: false,
                          page: 0,
                          metrics: .all)
    }
}
