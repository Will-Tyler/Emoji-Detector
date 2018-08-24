//
// Created by Will Tyler on 8/24/18.
//

import UIKit


public extension UIView {

	public func removeSubviews() {
		subviews.forEach({ $0.removeFromSuperview() })
	}

}