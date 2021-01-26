//
//  ReceiptDataFetcher.swift
//  TaiwanReceiptLottery
//
//  Created by Wei-Cheng Ling on 2021/1/5.
//

import Foundation


class ReceiptDataFetcher {
    
    static let urlString = "https://invoice.etax.nat.gov.tw/invoice.xml"
    
    class func fetch(callback: @escaping (String?) -> Void) {
        httpGET_withFetchXMLText(URLString: urlString, callback: callback)
    }
    
    
    // MARK: - HTTP GET
    
    // GET Method with fetch a XML text
    class func httpGET_withFetchXMLText(URLString: String, callback: @escaping (String?) -> Void) {
        httpRequestWithFetchXMLText(httpMethod: "GET", URLString: URLString, parameters: nil, callback: callback)
    }
    
    // MARK: - HTTP Request with Method
    
    // fetch XML text
    class func httpRequestWithFetchXMLText(httpMethod: String,
                                           URLString: String,
                                           parameters: Dictionary<String,Any>?,
                                           callback: @escaping (String?) -> Void)
    {
        // Create request
        let url = URL(string: URLString)!
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        // Header
        request.setValue("application/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        // Body
        if let parameterDict = parameters {
            // parameter dict to json data
            let jsonData = try? JSONSerialization.data(withJSONObject: parameterDict)
            // insert json data to the request
            request.httpBody = jsonData
        }
        
        // Session and configuration
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        let session = URLSession(configuration: config)
        
        // Task
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    callback(nil)
                    return
                }
                
                let text = String(decoding: data, as: UTF8.self)
                callback(text)
            }
        }
        task.resume()
    }
}
