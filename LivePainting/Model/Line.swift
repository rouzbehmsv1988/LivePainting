//
//  Line.swift
//  LivePainting
//
//  Created by rouzbeh on 21.08.23.
//

import Foundation
import SwiftUI
typealias CodableColor = Line.CodableColor

struct Line: Codable {
    var points: [CGPoint]
    var color: CodableColor // Use a CodableColor instead of Color
    
    // ... other properties or methods ...
    
    struct CodableColor: Codable {
        var red: Double
        var green: Double
        var blue: Double
        var alpha: Double
        
        // Initialize CodableColor from a SwiftUI Color
        init(_ color: Color) {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
            red = Double(r)
            green = Double(g)
            blue = Double(b)
            alpha = Double(a)
        }
        
        // Convert CodableColor back to SwiftUI Color
        var swiftUIColor: Color {
            Color(red: red, green: green, blue: blue, opacity: alpha)
        }
    }
}
