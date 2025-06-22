//
//  NutritionSummaryView.swift
//  WatchPlate Watch App
//
//  Created by Omar Sabeha on 6/12/25.
//

import SwiftUI

struct NutritionSummaryView: View {
    private var progress = 0.2

    var body: some View {
        Text("960/1850 cal")
            .font(.system(size: 18))
            .frame(maxWidth: .infinity, alignment: .leading)
        
        Text("protein 60%")
            .font(.system(size: 18))
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(Color(red: 219/255, green: 212/255, blue: 104/255))
        Text("carb 39%")
            .font(.system(size: 18))
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(Color(red: 241/255, green: 104/255, blue: 56/255))
        Text("fat 50%")
            .font(.system(size: 18))
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(Color(red: 51/255, green: 149/255, blue: 81/255))
            
        
        GeometryReader { geometry in
            MultiArcProgressView(progress1: progress, progress2: progress, progress3: progress)
                .frame(width: 160, height: 160)
                .position(x: geometry.size.width - 20,
                          y: geometry.size.height - 40)
        }
        //            VStack(){
        //                Spacer()
        //                ZStack{
        //                    //            Text("Nutrition Progress")
        //                    ProgressView(value: progress)
        //                        .progressViewStyle(.circular)
        //                        .scaleEffect(3)
        //                        .tint(.pink)
        //                    ProgressView(value: progress)
        //                        .progressViewStyle(.circular)
        //                        .scaleEffect(2.4)
        //                        .tint(.green)
        //                    ProgressView(value: progress)
        //                        .progressViewStyle(.circular)
        //                        .scaleEffect(1.92)
        //                        .tint(.blue)
        //                }
        //
        //                HStack(){
        //                    Text("Protein")
        //                        .foregroundColor(.pink)
        //                        .font(.system(size: 15))
        //                    Text("Carbs")
        //                        .foregroundColor(.green)
        //                        .font(.system(size: 15))
        //                    Text("Fats")
        //                        .foregroundColor(.blue)
        //                        .font(.system(size: 15))
        //                }
        //                .padding(.top, 55)
        //
        //            }
        }
    }

#Preview {
    NutritionSummaryView()
}

