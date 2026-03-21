//
//  WebService.swift
//  Protecta EGPL
//
//  Created by avinash pandey on 21/03/26.
//

import Foundation

class WebService {

    func sendTokenToServer(token: String) {

        let urlString = "\(Constants.tokenAPI)?token=\(token)"
        
        print("Push Token urlString:", urlString)

        /*
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data {
                print(String(data: data, encoding: .utf8) ?? "")
            }
        }.resume()*/
    }
}
