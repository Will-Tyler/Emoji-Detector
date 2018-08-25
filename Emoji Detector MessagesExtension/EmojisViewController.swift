//
//  EmojisViewController.swift
//  Emoji Detector MessagesExtension
//
//  Created by Will Tyler on 8/24/18.
//  Copyright © 2018 Will Tyler. All rights reserved.
//

import UIKit


final class EmojisViewController: UIViewController {

	private let emojiButtons: [UIButton] = {
		var array = [UIButton]()

		for _ in 0..<4 {
			let button = UIButton()

			button.titleLabel!.numberOfLines = 1
			button.titleLabel!.adjustsFontSizeToFitWidth = true
			button.titleLabel!.lineBreakMode = .byClipping
			button.titleLabel!.baselineAdjustment = .alignCenters
			button.titleLabel!.font = button.titleLabel!.font.withSize(48)
			button.addTarget(self, action: #selector(emojiButtonPressed), for: .touchUpInside)

			array.append(button)
		}

		array[0].setTitle("❗️", for: .normal)
		array[1].setTitle("❔", for: .normal)
		array[2].setTitle("❕", for: .normal)
		array[3].setTitle("❓", for: .normal)

		return array
	}()

	private func setupInitialLayout() {
		view.removeSubviews()

		emojiButtons.forEach({ emojiButton in
			view.addSubview(emojiButton)
			emojiButton.translatesAutoresizingMaskIntoConstraints = false
		})

		// buttons to each other
		emojiButtons[0].trailingAnchor.constraint(equalTo: emojiButtons[1].leadingAnchor, constant: -4).isActive = true
		emojiButtons[0].bottomAnchor.constraint(equalTo: emojiButtons[2].topAnchor, constant: -4).isActive = true

		emojiButtons[0].heightAnchor.constraint(equalTo: emojiButtons[1].heightAnchor).isActive = true
		emojiButtons[0].heightAnchor.constraint(equalTo: emojiButtons[2].heightAnchor).isActive = true
		emojiButtons[0].heightAnchor.constraint(equalTo: emojiButtons[3].heightAnchor).isActive = true

		emojiButtons[0].widthAnchor.constraint(equalTo: emojiButtons[1].widthAnchor).isActive = true
		emojiButtons[0].widthAnchor.constraint(equalTo: emojiButtons[2].widthAnchor).isActive = true
		emojiButtons[0].widthAnchor.constraint(equalTo: emojiButtons[3].widthAnchor).isActive = true

		emojiButtons[0].centerXAnchor.constraint(equalTo: emojiButtons[2].centerXAnchor).isActive = true
		emojiButtons[1].centerXAnchor.constraint(equalTo: emojiButtons[3].centerXAnchor).isActive = true

		emojiButtons[0].centerYAnchor.constraint(equalTo: emojiButtons[1].centerYAnchor).isActive = true
		emojiButtons[2].centerYAnchor.constraint(equalTo: emojiButtons[3].centerYAnchor).isActive = true

		// buttons to container
		emojiButtons[0].topAnchor.constraint(equalTo: view.topAnchor, constant: 4).isActive = true
		emojiButtons[1].topAnchor.constraint(equalTo: view.topAnchor, constant: 4).isActive = true
		emojiButtons[2].bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4).isActive = true
		emojiButtons[3].bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4).isActive = true
		emojiButtons[0].leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4).isActive = true
		emojiButtons[2].leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4).isActive = true
		emojiButtons[1].trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4).isActive = true
		emojiButtons[3].trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4).isActive = true
	}

	override func loadView() {
		view = UIView()
	}
	override func viewDidLoad() {
		super.viewDidLoad()

		setupInitialLayout()
	}

	var messagesViewController: MessagesViewController!

	@objc func emojiButtonPressed(_ sender: UIButton) {
		messagesViewController.requestPresentationStyle(.compact)
		messagesViewController.activeConversation!.insertText(sender.title(for: .normal)!)
	}

	func updateEmojiButtons(with emojis: Emojis) {
		DispatchQueue.main.async {
			self.emojiButtons[0].setTitle(String(emojis.first), for: .normal)
			self.emojiButtons[1].setTitle(String(emojis.second), for: .normal)
			self.emojiButtons[2].setTitle(String(emojis.third), for: .normal)
			self.emojiButtons[3].setTitle(String(emojis.random), for: .normal)
		}
	}

}
