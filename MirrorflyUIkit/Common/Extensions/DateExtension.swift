//
//  DateExtension.swift
//  MirrorflyUIkit
//
//  Created by User on 27/08/21.
//

import Foundation
extension Date {
    static func dateFromCustomString(customString: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.date(from: customString) ?? Date()
    }
    
    func reduceToMonthDayYear() -> Date {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: self)
        let day = calendar.component(.day, from: self)
        let year = calendar.component(.year, from: self)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.date(from: "\(month)/\(day)/\(year)") ?? Date()
    }
    
    func toDate(withFormat format: String)-> Date?{
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone(identifier: "Asia/Tehran")
            dateFormatter.locale = Locale(identifier: "fa-IR")
            dateFormatter.calendar = Calendar(identifier: .indian)
            dateFormatter.dateFormat = format
            let date = dateFormatter.date(from: format)
            return date
    }
    
    func getTimeFormat() -> String {
        let dateFormatter = DateFormatter()
        let locale = NSLocale.current
        let formatter : String = DateFormatter.dateFormat(fromTemplate: "j", options:0, locale:locale)!
        if formatter.contains("a") {
            //phone is set to 12 hours format
            dateFormatter.dateFormat = "hh:mm a"
        } else {
            //phone is set to 24 hours format
            dateFormatter.dateFormat = "HH:mm"
        }
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let formattedDate = dateFormatter.string(from: self)
        return formattedDate.lowercased()
    }
}
