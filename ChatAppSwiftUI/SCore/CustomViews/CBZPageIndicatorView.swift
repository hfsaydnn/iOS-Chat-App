//
//  CBZPageIndicatorView.swift
//  DatingApp
//
//  Created by Mayil Kannan on 17/08/21.
//

import SwiftUI

// MARK: - Dot Indicator -
private struct DotIndicator: View {
    let minScale: CGFloat = 1
    let maxScale: CGFloat = 1.1
    let minOpacity: Double = 0.6
    
    let pageIndex: Int
    @Binding var slectedPage: Int
    let currentPageTintColor: UIColor
    let pageIndicatorTintColor: UIColor
    
    var body: some View {
        
        Button(action: {
            self.slectedPage = self.pageIndex
        }) {
            Circle()
                .scaleEffect(
                    slectedPage == pageIndex
                        ? maxScale
                        : minScale
                )
                .animation(.spring())
                .foregroundColor(
                    slectedPage == pageIndex
                        ? Color(currentPageTintColor)
                        : Color(pageIndicatorTintColor)
                )
        }
        
    }
}

// MARK: - Page Indicator -
struct CBZPageIndicator: View {
    // Constants
    private let spacing: CGFloat = 8
    private let diameter: CGFloat = 8
    
    // Settings
    let numPages: Int
    let currentPageTintColor: UIColor
    let pageIndicatorTintColor: UIColor
    @Binding var selectedIndex: Int
    
    init(numPages: Int, currentPageTintColor: UIColor, pageIndicatorTintColor: UIColor, currentPage: Binding<Int>) {
        self.numPages = numPages
        self.currentPageTintColor = currentPageTintColor
        self.pageIndicatorTintColor = pageIndicatorTintColor
        self._selectedIndex = currentPage
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: spacing) {
                ForEach((0..<numPages)) {
                    DotIndicator(
                        pageIndex: $0,
                        slectedPage: self.$selectedIndex,
                        currentPageTintColor: currentPageTintColor,
                        pageIndicatorTintColor: pageIndicatorTintColor
                    ).frame(
                        width: self.diameter,
                        height: self.diameter
                    )
                }
            }
        }
    }
}
