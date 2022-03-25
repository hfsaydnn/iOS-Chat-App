//
//  CPKProgressHUDSwiftUI.swift
//  ClassifiedsApp
//
//  Created by Florian Marcu on 9/25/19.
//  Copyright © 2019 Instamobile. All rights reserved.
//

import SwiftUI
import UIKit

struct CPKProgressHUDSwiftUI: UIViewRepresentable {
    
    func makeUIView(context: UIViewRepresentableContext<CPKProgressHUDSwiftUI>) -> CPKProgressHUD {
        return CPKProgressHUD.progressHUD(style: .loading(text: nil))
    }

    func updateUIView(_ uiView: CPKProgressHUD, context: UIViewRepresentableContext<CPKProgressHUDSwiftUI>) {
        uiView.indicator?.startAnimating()
        UIView.animate(withDuration: 0.3) {
            uiView.isHidden = false
            uiView.alpha = 1
        }
    }
}
