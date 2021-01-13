//
//  HTTPResponseStatus.swift
//  HTTPResponseCode
//
//  Created by Koussaïla Ben Mamar on 13/01/2021.
//

import Foundation

struct HTTPResponseStatus {
    var responseCode: Int?
    var responseMessage: String?
    var availableData: Bool
    
    init() {
        responseCode = nil
        responseMessage = nil
        self.availableData = false
    }
}
