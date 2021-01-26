//
//  ReceiptTextView.swift
//  TaiwanReceiptLottery
//
//  Created by Wei-Cheng Ling on 2021/1/24.
//

import SwiftUI

struct ReceiptTextView: View {
    
    var receiptNumber : String
    var dataArray : [ReceiptData]
    var dataIndex : Int
    
    var body: some View {
        ZStack {
            if dataArray.count > 0 && dataIndex < dataArray.count {
                let status = receiptNumber.compareReceiptNumber(dataArray[dataIndex])
                let groupText = receiptNumber.groupReceiptNumber(winningStatus: status)
                
                Group {
                    Text("\(groupText.0)")
                        .foregroundColor(Color.blue) +
                    Text("\(groupText.1)")
                        .foregroundColor(Color.red)
                }
                .frame(width: 200, height: 60, alignment: .center)
                .font(.system(size: 30))
                .multilineTextAlignment(.center)
                .background(Color.white)
                .cornerRadius(40)
                
                if receiptNumber != "" {
                    Text("\(status.string())")
                        .frame(width: 75, height: 22, alignment: .center)
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.white)
                        .background(Color.orange)
                        .cornerRadius(8)
                        .offset(x: 0, y: 33)
                }
            } else {
                Text("\(receiptNumber)")
                    .frame(width: 200, height: 60, alignment: .center)
                    .font(.system(size: 30))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.blue)
                    .background(Color.white)
                    .cornerRadius(40)
            }
            
            Text("發票號碼")
                .frame(width: 75, height: 20, alignment: .center)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(Color.white)
                .background(Color(.sRGB, red: 0, green: 128/255, blue: 1, opacity: 1))
                .cornerRadius(8)
                .offset(x: 0, y: -31)
        }
        .padding(26)
    }
}

struct ReceiptTextView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiptTextView(receiptNumber: "12345678",
                        dataArray: [],
                        dataIndex: 0)
    }
}
