//
//  MockSocketRoute.swift
//  Shock
//
//  Created by Antonio Strijdom on 01/10/2020.
//

import Foundation

public enum MockSocketRoute {
    case echo
    case collection(
        routes: [MockSocketRoute]
    )
}
