//
//  ViewController.swift
//  Noteniki
//
//  Created by Herb Bowie on 9/7/20.
//  Copyright © 2020 PowerSurge Publishing. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let fm = FileManager.default
        let path = Bundle.main.resourcePath!
        let items = try! fm.contentsOfDirectory(atPath: path)
        print("Displaying contents of resource folder")
        for item in items {
            print("  - \(item)")
        }
    }


}

