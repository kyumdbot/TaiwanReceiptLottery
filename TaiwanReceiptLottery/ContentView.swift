//
//  ContentView.swift
//  TaiwanReceiptLottery
//
//  Created by Wei-Cheng Ling on 2021/1/1.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var dataStore = ReceiptDataStore()
    @State private var receiptNumber : String?
    @State private var selectedIndex = 0
    
    var body: some View {
        VStack {
            CameraView(receiptNumber: $receiptNumber)
                .frame(width: 640, height: 480, alignment: .center)
                .background(Color.black)
                .border(Color(white: 0.85), width: 1)
                .overlay(
                    ReceiptTextView(receiptNumber: "\(receiptNumber ?? "")",
                                    dataArray: dataStore.dataArray,
                                    dataIndex: selectedIndex),
                    alignment: .bottom
                )
            
            if dataStore.dataArray.count == 0 {
                Text("資料下載中...")
            } else {
                Picker(selection: $selectedIndex, label: Text("對獎月份")) {
                    ForEach(dataStore.dataArray.indices) { index in
                        Text(dataStore.dataArray[index].title).tag(index)
                    }
                }
                .padding(EdgeInsets(top: 5, leading: 20, bottom: 15, trailing: 20))
            }
        }
        .onAppear {
            self.dataStore.downloadData()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
