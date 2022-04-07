//
//  DateFormatterUtility.swift
//  MirrorflyUIkit
//
//  Created by Sowmiya T on 19/11/21.
//

import Foundation

class DateFormatterUtility: NSObject {
    
    //Singleton class
    static let shared = DateFormatterUtility()
    
    func convertMillisecondsToDateTime(milliSeconds: Double)  -> Date {
        let timeStamp = milliSeconds / 1000
        let date2 = Date(timeIntervalSince1970: (Double(timeStamp) / 1000.0))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        guard let str = utcToLocal(dateStr:dateFormatter.string(from: date2)) else {
            return Date()
        }
        return dateFormatter.date(from: str) ?? Date()
    }
    
    func convertMillisecondsToTime(milliSeconds: Double)  -> Date {
        let timeStamp = milliSeconds / 1000
        let date2 = Date(timeIntervalSince1970: (Double(timeStamp) / 1000.0))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        guard let str = utcToLocalTime(dateStr:dateFormatter.string(from: date2)) else {
            return Date()
        }
        return dateFormatter.date(from: str) ?? Date()
        
    }
    
    func utcToLocalTime(dateStr: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = dateFormatter.date(from: dateStr) {
            dateFormatter.timeZone = TimeZone.current
            return dateFormatter.string(from: date)
        }
        return nil
    }
    
    func utcToLocal(dateStr: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = dateFormatter.date(from: dateStr) {
            dateFormatter.timeZone = TimeZone.current
            return dateFormatter.string(from: date)
        }
        return nil
    }
    
    func convertMillisecondsToWebLoginTime(milliSeconds: Double)  -> String {
        // Date
        let timeStamp = milliSeconds / 1000
        let date2 = Date(timeIntervalSince1970: Double(timeStamp/1000))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        let time = convertMillisecondsToTime(milliSeconds: milliSeconds).getTimeFormat()
 
        return  dateFormatter.string(from: date2) + " " + time
    }
    
}


