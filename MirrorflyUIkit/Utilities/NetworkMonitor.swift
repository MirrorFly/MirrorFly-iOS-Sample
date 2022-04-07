//
//  NetworkMonitor.swift
//  MirrorflyUIkit
//
//  Created by User on 04/02/22.
//

import Foundation
import Network


public final class NetworkMonitor{
    
    public static let networkNotificationObserver = "networkNotificationObserver"
    
    public static let isNetworkAvailable = "isNetworkAvailable"
    
    public static let shared = NetworkMonitor()
    
    private let queue = DispatchQueue.global()
    
    private let monitor: NWPathMonitor
    
    public private(set) var isConnected: Bool = false
    
    private init() {
        monitor = NWPathMonitor()
    }
    
    public func startMonitoring() {
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { [weak self] path in
            switch path.status{
            case .satisfied:
                print("#contact satisfied ")
                self?.isConnected = true
                var data = [String: Bool]()
                data[NetworkMonitor.isNetworkAvailable] = true
                NotificationCenter.default.post(name:  Notification.Name(NetworkMonitor.networkNotificationObserver), object: nil, userInfo: data)
            case .unsatisfied:
                fallthrough
            case .requiresConnection:
                fallthrough
            @unknown default:
                var data = [String: Bool]()
                data[NetworkMonitor.isNetworkAvailable] = false
                NotificationCenter.default.post(name:  Notification.Name(NetworkMonitor.networkNotificationObserver), object: nil, userInfo: data)
                self?.isConnected = false
            }
            
        }
    }
    
    public func stop() {
        var data = [String: Bool]()
        data[NetworkMonitor.isNetworkAvailable] = false
       
        monitor.cancel()
    }
    
}
