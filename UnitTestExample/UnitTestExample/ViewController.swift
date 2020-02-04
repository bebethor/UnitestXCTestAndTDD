//
//  ViewController.swift
//  UnitTestExample
//
//  Created by Jose Alberto Ruíz-Carrillo González on 04/02/2020.
//  Copyright © 2020 JARCG. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        print(2.square())
    }
}

extension Int {
    func square() -> Int {
        return self * self * self
    }
}
