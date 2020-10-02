//
//  MockSocketRoute.swift
//  Shock
//
//  Created by Antonio Strijdom on 01/10/2020.
//

import Foundation

public enum MockSocketRoute {
    public typealias LogStashEchoClosure = (String) -> Void
    
    case logStashEcho(LogStashEchoClosure)
    case collection(
        routes: [MockSocketRoute]
    )
}
