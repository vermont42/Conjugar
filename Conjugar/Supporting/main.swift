//
//  main.swift
//  Conjugar
//
//  Created by Joshua Adams on 1/31/20.
//  Copyright © 2020 Josh Adams. All rights reserved.
//

import Foundation

import UIKit

let appDelegateClass: AnyClass = NSClassFromString("TestingAppDelegate") ?? AppDelegate.self

UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(appDelegateClass))
