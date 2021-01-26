//
//  String+Helpers.swift
//  TaiwanReceiptLottery
//
//  Created by Wei-Cheng Ling on 2021/1/22.
//

import Foundation

extension String {
    
    // MARK: - Receipt Number
    
    func extractReceiptNumberString() -> String? {
        let string = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let regex = try? NSRegularExpression(pattern: #"\d{8}"#, options: []) else { return nil }
        
        if let match = regex.firstMatch(in: string,
                                        options: [],
                                        range: NSRange(location: 0, length: string.count))
        {
            return (string as NSString).substring(with: match.range)
        }
        return nil
    }
    
    func compareReceiptNumber(_ receiptData: ReceiptData) -> WinningStatus {
        for str in receiptData.superNumbers {
            if self == str {
                return .superNumber
            }
        }
        
        for str in receiptData.specialNumbers {
            if self == str {
                return .specialNumber
            }
        }
        
        for str in receiptData.jackpotNumbers {
            if self == str {
                return .jackpot
            }
            
            if self.count == str.count {
                var dropNum = 1
                while dropNum <= 5 && dropNum <= str.count {
                    if String(self.dropFirst(dropNum)) == String(str.dropFirst(dropNum)) {
                        if dropNum == 1 {
                            return .secondPrize
                        } else if dropNum == 2 {
                            return .thirdPrize
                        } else if dropNum == 3 {
                            return .fourthPrize
                        } else if dropNum == 4 {
                            return .fifthPrize
                        } else if dropNum == 5 {
                            return .sixthPrize
                        }
                    }
                    dropNum += 1
                }
            }
        }
        
        for str in receiptData.sixthPrizeNumbers {
            if self.count == 8 {
                if str == String(self.dropFirst(5)) {
                    return .sixthPrize
                }
            }
        }
        
        return .none
    }
    
    func groupReceiptNumber(winningStatus: WinningStatus) -> (String, String) {
        if self.count != 8 { return (self, "") }
        
        var prefixNum = 0
        
        switch winningStatus {
        case .superNumber:
            prefixNum = 0
        case .specialNumber:
            prefixNum = 0
        case .jackpot:
            prefixNum = 0
        case .secondPrize:
            prefixNum = 1
        case .thirdPrize:
            prefixNum = 2
        case .fourthPrize:
            prefixNum = 3
        case .fifthPrize:
            prefixNum = 4
        case .sixthPrize:
            prefixNum = 5
        case .none:
            prefixNum = 8
        }
        
        let substr1 = String(self.prefix(prefixNum))
        let substr2 = String(self.suffix(self.count - prefixNum))
        return (substr1, substr2)
    }
    
    
    // MARK: - Regex
    
    func match(pattern: String) -> Array<Array<String>> {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            var results = [[String]]()
            regex.enumerateMatches(in: self,
                                   options: [],
                                   range: NSRange(location: 0, length: self.count))
            { (match, flags, stop) in
                if let m = match {
                    var array = [String]()
                    for idx in 0..<m.numberOfRanges {
                        if let range = Range(m.range(at: idx), in: self) {
                            array.append( String(self[range]) )
                        }
                    }
                    results.append(array)
                }
            }
            return results
        } catch {
            return []
        }
    }
    
    func firstMatch(pattern: String) -> Array<String> {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let match = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.count))
            var array = [String]()
            if let m = match {
                for idx in 0..<m.numberOfRanges {
                    if let range = Range(m.range(at: idx), in: self) {
                        array.append( String(self[range]) )
                    }
                }
            }
            return array
        } catch {
            return []
        }
    }
}
