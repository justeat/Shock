//
//  ViewController.swift
//  Shock
//
//  Created by Jack Newcombe on 10/05/2017.
//

import UIKit

class ViewController: UIViewController {
	
	@IBOutlet var pickerView: UIPickerView!
	@IBOutlet var scrollView: UIScrollView!
	@IBOutlet var label: UILabel!
	@IBOutlet var button: UIButton!
	
	let routes = MyRoutes()

    override func viewDidLoad() {
        super.viewDidLoad()
		
		pickerView.dataSource = self
		pickerView.delegate = self
        
        button.layer.cornerRadius = 8.0
        scrollView.layer.cornerRadius = 8.0
        pickerView.layer.cornerRadius = 8.0
        pickerView.layer.borderWidth = 0.5
        pickerView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
    }

	@IBAction func makeRequest(sender: UIButton) {
		
		routes.makeRequest(index: pickerView.selectedRow(inComponent: 0)) { response, data in
			var text = ""
			response.allHeaderFields.keys.forEach { key in
				text += "\(key): \(response.allHeaderFields[key] ?? String())\n"
			}
			text += "\n"
			text += String(data: data, encoding: .utf8) ?? ""
			DispatchQueue.main.async {
				self.label.text = text
				self.label.sizeToFit()
				self.scrollView.contentOffset = CGPoint(x: 0, y: 0)
			}
		}
		
	}

}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return routes.count
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return routes.nameForRoute(index: row)
	}
	
}
