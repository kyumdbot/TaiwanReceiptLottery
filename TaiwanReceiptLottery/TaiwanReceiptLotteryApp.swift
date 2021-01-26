//
//  TaiwanReceiptLotteryApp.swift
//  TaiwanReceiptLottery
//
//  Created by Wei-Cheng Ling on 2021/1/1.
//

import SwiftUI

@main
struct TaiwanReceiptLotteryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
