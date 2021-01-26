//
//  ReceiptDataStore.swift
//  TaiwanReceiptLottery
//
//  Created by Wei-Cheng Ling on 2021/1/20.
//

import Foundation

class ReceiptDataStore: ObservableObject {
    
    @Published var dataArray = [ReceiptData]()
    
    func downloadData() {
        ReceiptDataFetcher.fetch() { xmlText in
            if let text = xmlText, text != "" {
                let data = Data(text.utf8)
                let reader = MyXMLReader()
                let array = reader.read(data: data,
                                        tagName: "item",
                                        fieldNames: ["title", "description", "pubDate"])
                
                self.dataArray = self.cleanData(array)
            }
        }
    }
    
    func cleanData(_ array: Array<Dictionary<String,String>>) -> [ReceiptData] {
        var results = [ReceiptData]()
        
        for item in array {
            var tmpArray = [String]()
            for match in (item["description"] ?? "").match(pattern: #"<p>(.+?)</p>"#) {
                if match.count == 2 {
                    tmpArray.append(match[1])
                } else if match.count == 1 {
                    tmpArray.append(match[0])
                }
            }
//            print("> \(tmpArray)")
            
            let dict = descriptionDictFrom(array: tmpArray)
//            print(">>> \(dict)")
            
            let title = item["title"] ?? ""
            let pubDate = item["pubDate"] ?? ""
            let superNumbers = dict["特別獎"] ?? []
            let specialNumbers = dict["特獎"] ?? []
            let jackpotNumbers = dict["頭獎"] ?? []
            let sixthPrizeNumbers = dict["增開六獎"] ?? []
            
            let receiptData = ReceiptData(title: title,
                                          pubDate: pubDate,
                                          superNumbers: superNumbers,
                                          specialNumbers: specialNumbers,
                                          jackpotNumbers: jackpotNumbers,
                                          sixthPrizeNumbers: sixthPrizeNumbers)
            
            results.append(receiptData)
        }
        return results
    }
    
    func descriptionDictFrom(array: [String]) -> [String: [String]] {
        var dict = [String: [String]]()
        for str in array {
            let match = str.firstMatch(pattern: #"(.+?)[:：](.+)"#)
            
            if match.count == 3 {
                let key = match[1]
                let values = match[2].components(separatedBy: "、").map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                dict[key] = values
            }
        }
        return dict
    }
}

