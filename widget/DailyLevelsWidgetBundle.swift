//
//  DailyLevelsWidgetBundle.swift
//  DailyLevelsWidget  (widget extension target only)
//
//  The @main entry for the widget extension. One widget for now; add more here later
//  (e.g. a Lock Screen accessory) without touching the app.
//

import WidgetKit
import SwiftUI

@main
struct DailyLevelsWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyLevelsWidget()
    }
}
