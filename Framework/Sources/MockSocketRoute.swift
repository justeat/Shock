//  MockSocketRoute.swift

import Foundation

public enum MockSocketRoute {
    public typealias LogStashEchoClosure = (String) -> Void
    
    case logStashEcho(LogStashEchoClosure)
    case collection(
        routes: [MockSocketRoute]
    )
}
