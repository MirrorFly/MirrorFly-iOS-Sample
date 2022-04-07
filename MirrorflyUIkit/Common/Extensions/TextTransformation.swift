//
//  TextTransformation.swift
//  MirrorflyUIkit
//
//  Created by User on 18/09/21.
//

import Foundation
import UIKit

extension String {
    func fetchMessageDateHeader(for date : Date) -> String {
        
        var secondsAgo = Int(Date().timeIntervalSince(date))
        if secondsAgo < 0 {
            secondsAgo = secondsAgo * (-1)
        }
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let twoDays = 2 * day
        let oneDay = 1 * day
        
        if secondsAgo < oneDay  {
            
            return "TODAY".localized
            
        } else if secondsAgo < twoDays {
            let day = secondsAgo/day
            if day == 1 {
                return "YESTERDAY".localized
            }else{
                let formatter = DateFormatter()
                formatter.dateFormat = "EEE"
                formatter.locale = Locale(identifier: "en_US")
                let strDate: String = formatter.string(from: date)
                return strDate.uppercased()
            }
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM, yyyy"
            formatter.locale = Locale(identifier: "en_US")
            let strDate: String = formatter.string(from: date)
            return strDate
        }
    }
    
    func fetchMessageDate(for lastMessageTime : Double) -> String {
        let date = DateFormatterUtility.shared.convertMillisecondsToDateTime(milliSeconds: lastMessageTime)
        let time = DateFormatterUtility.shared.convertMillisecondsToTime(milliSeconds: lastMessageTime)
        var secondsAgo = Int(Date().timeIntervalSince(date))
        if secondsAgo < 0 {
            secondsAgo = secondsAgo * (-1)
        }
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let weekDays = 7 * day
        let twoDays = 2 * day
        let oneDay = 1 * day
        
        if secondsAgo < oneDay  {
            return time.getTimeFormat()
            
        } else if secondsAgo < twoDays {
            let day = secondsAgo/day
            if day == 1 {
                return "YESTERDAY".localized
            }
        } else if secondsAgo < weekDays {
            let formatter = DateFormatter()
            formatter.dateFormat = "eee"
            formatter.locale = Locale(identifier: "en_US")
            let strDate: String = formatter.string(from: date)
            return strDate.capitalized
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            formatter.locale = Locale(identifier: "en_US")
            let strDate: String = formatter.string(from: date)
            return strDate.capitalized
        }
        return ""
    }
}



