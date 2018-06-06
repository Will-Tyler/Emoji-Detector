//
//  WebViewController.swift
//  Emoji Detector MessagesExtension
//
//  Created by Will Tyler on 6/5/18.
//  Copyright © 2018 Will Tyler. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

	//MARK: Outlets
	@IBOutlet weak var webView: WKWebView!
	
	@IBAction func swipeHandler(_ sender: UISwipeGestureRecognizer) {
		print("Detected swipe in webview going \(sender.direction)...")
		
		switch sender.direction {
		case .left:
			if webView.canGoForward {
				webView.goForward()
			}

		case .right:
			if webView.canGoBack {
				webView.goBack()
			}

		default: break
		}
	}
	@IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
		dismiss(animated: true, completion: nil)
	}

	override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
