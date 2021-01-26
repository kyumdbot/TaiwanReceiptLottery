//
//  ReceiptData.swift
//  TaiwanReceiptLottery
//
//  Created by Wei-Cheng Ling on 2021/1/23.
//

import Foundation

enum WinningStatus {
    case none
    case superNumber      // 特別獎
    case specialNumber    // 特獎
    case jackpot          // 頭獎
    case secondPrize      // 二獎
    case thirdPrize       // 三獎
    case fourthPrize      // 四獎
    case fifthPrize       // 五獎
    case sixthPrize       // 六獎
    
    func string() -> String {
        switch self {
        case .none:
            return "沒中獎"
        case .superNumber:
            return "特別獎"
        case .specialNumber:
            return "特獎"
        case .jackpot:
            return "頭獎"
        case .secondPrize:
            return "二獎"
        case .thirdPrize:
            return "三獎"
        case .fourthPrize:
            return "四獎"
        case .fifthPrize:
            return "五獎"
        case .sixthPrize:
            return "六獎"
        }
    }
}

struct ReceiptData {
    let title : String
    let pubDate : String
    
    let superNumbers : [String]        // 特別獎
    let specialNumbers : [String]      // 特獎
    let jackpotNumbers : [String]      // 頭獎
    let sixthPrizeNumbers : [String]   // 增開六獎
}

