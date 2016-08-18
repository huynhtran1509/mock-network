//
//  ViewController.swift
//  Example
//
//  Created by Ian Terrell on 8/18/16.
//  Copyright © 2016 WillowTree. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var textField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        let stripe = URL(string: "https://api.stripe.com/")!
        let task = URLSession.shared.dataTask(with: stripe) { (data, response, error) in
            DispatchQueue.main.async {
                guard error == nil else {
                    self.textField.text = "Error was not nil"
                    return
                }

                guard let data = data else {
                    self.textField.text = "Data was nil"
                    return
                }

                guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
                    let json = jsonObject as? [String: Any]
                    else {
                        self.textField.text = "Could not parse JSON"
                        return
                }

                guard let error = json["error"] as? [String:Any],
                    let type = error["type"] as? String
                    else {
                        self.textField.text = "Unexpected JSON"
                        return
                }

                self.textField.text = type
            }
        }
        task.resume()
    }
    
}
