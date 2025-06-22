//
//  EditWaterGoalView.swift
//  MyFitPlate
//
//  Created by Omar Sabeha on 4/23/25.
//

import SwiftUI

struct EditWaterGoalView: View {
    @Environment(\.dismiss) var dismiss

    @State var newGoalInput: String = ""
    
    var body: some View {
        
        }
    
    var isValidGoalInputl: Bool {
        guard let goal = Double(newGoalInput), goal > 0 else {
            print("invalid new goal input")
            return false
        }
        return true
    }
}
