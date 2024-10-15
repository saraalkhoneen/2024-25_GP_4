//
//  WaveShape.swift
//  Ain
//
//  Created by Sara alkhoneen on 11/04/1446 AH.
//
import SwiftUI
struct BackgroundWaveShape: Shape {
    var phase: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let waveHeight: CGFloat = 20
        let waveLength = rect.width / 2
        
        path.move(to: CGPoint(x: 0, y: rect.height / 2))
        
        for x in stride(from: 0, to: rect.width, by: 1) {
            let relativeX = x / waveLength
            let sine = sin(relativeX * .pi * 2 + phase)
            let y = rect.height / 2 + sine * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
    }
}
