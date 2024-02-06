//
//  View-Extensions.swift
//  Rlystate_V2
//
//  Created by Shervin Mobasheri on 12/27/23.
//

import SwiftUI

// View Extension for UI
extension View{
    // Closing All Active Keyboards
    func closeKeyBoard(){
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    // Disabaling with Opacity
    func disabledWithOpacity(_ condition: Bool)->some View{
        self
            .disabled(condition)
            .opacity(condition ? 0.6 : 1)
    }
    
    func hAlign(_ alignment: Alignment)->some View{
        self
            .frame(maxWidth: .infinity,alignment: alignment)
    }
    func vAlign(_ alignment: Alignment)->some View{
        self
            .frame(maxHeight: .infinity,alignment: alignment)
    }

    // Custom Border View With Padding
func border(_ width: CGFloat,_ color: Color)->some View{
    self
        .padding(.horizontal,15)
        .padding(.vertical,10)
        .background {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(color, lineWidth: width)
    
        }
    }
    
    // Custom Fill View With Padding
func fillView(_ color: Color)->some View{
    self
        .padding(.horizontal,15)
        .padding(.vertical,10)
        .background {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(color)
    
        }
    }
    
}
