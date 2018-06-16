//
//  MessagesViewController.swift
//  Emoji Detector MessagesExtension
//
//  Created by Will Tyler on 5/18/18.
//  Copyright © 2018 Will Tyler. All rights reserved.
//

import UIKit
import Messages
import AVFoundation
import CoreML
import Vision
import WebKit
import SafariServices

@objc(MessagesViewController)


class MessagesViewController: MSMessagesAppViewController, AVCapturePhotoCaptureDelegate, UITextViewDelegate {

	//MARK: - Views
	let containerStack: UIStackView = {
		let stackView = UIStackView()

		stackView.alignment = .fill
		stackView.distribution = .fillEqually
		stackView.spacing = 16
		stackView.axis = .horizontal

		return stackView
	}()
	let videoPreviewView: UIView = {
		let view = UIView()

		view.backgroundColor = .blue

		return view
	}()
	let emojiButtons: [UIButton] = {
		var array = [UIButton]()

		for _ in 1...4 {
			let button = UIButton()

			button.backgroundColor = .green
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
	let infoTextView: UITextView = {
		let textView = UITextView()

		textView.text =
		"""
		Emoji Detector uses photos of your face and a machine learning model to determine the best emojis to use based off of your facial expression.

		If this app isn't displaying the correct emojis, try exaggerating your facial expresssions, or positioning the camera with a different background.

		Emoji Detector runs entirely on your device, and while this means the app uses more storage, any photo captured by this app will not leave your device and will be gone once your emojis are detected.

		The machine learning model was developed by Gil Levi and Tal Hassner. https://www.openu.ac.il/home/hassner/projects/cnn_emotions/

		If you enjoy this app or have any suggestions, please leave a review on the iMessage App Store!
		"""
		textView.isHidden = true
		textView.backgroundColor = UIColor.lightGray
		textView.isEditable = false
		textView.isSelectable = true
		textView.font = UIFont.preferredFont(forTextStyle: .body)
		textView.dataDetectorTypes = .link

		return textView
	}()
	private var containerStackBottomConstraint: NSLayoutConstraint!
	private var didConstrainHeight = false
	private var didConstrainInfoTextView = false

	//MARK: - Actions
	@objc func emojiButtonPressed(_ sender: UIButton) {
		requestPresentationStyle(.compact)

		activeConversation!.insertText(sender.title(for: .normal)!, completionHandler: nil)
	}
	@objc func reloadButtonPressed() {
		photoOutput?.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
	}

	private func setupInitialLayout() {
		let reloadButton: UIButton = {
			let button = UIButton(type: .system)

			button.setTitle("Reload 🔄", for: .normal)
			button.backgroundColor = .yellow
			button.addTarget(self, action: #selector(reloadButtonPressed), for: .touchUpInside)

			return button
		}()

		reloadButton.heightAnchor.constraint(equalToConstant: reloadButton.intrinsicContentSize.height).isActive = true

		let emojiButtonsContainer: UIView = {
			let view = UIView()

			view.backgroundColor = .red

			return view
		}()

		for emojiButton in emojiButtons {
			emojiButtonsContainer.addSubview(emojiButton)
		}

		for emojiButton in emojiButtons {
			emojiButton.translatesAutoresizingMaskIntoConstraints = false
		}

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
		emojiButtonsContainer.translatesAutoresizingMaskIntoConstraints = false
		emojiButtons[0].topAnchor.constraint(equalTo: emojiButtonsContainer.topAnchor, constant: 4).isActive = true
		emojiButtons[1].topAnchor.constraint(equalTo: emojiButtonsContainer.topAnchor, constant: 4).isActive = true
		emojiButtons[2].bottomAnchor.constraint(equalTo: emojiButtonsContainer.bottomAnchor, constant: -4).isActive = true
		emojiButtons[3].bottomAnchor.constraint(equalTo: emojiButtonsContainer.bottomAnchor, constant: -4).isActive = true
		emojiButtons[0].leadingAnchor.constraint(equalTo: emojiButtonsContainer.leadingAnchor, constant: 4).isActive = true
		emojiButtons[2].leadingAnchor.constraint(equalTo: emojiButtonsContainer.leadingAnchor, constant: 4).isActive = true
		emojiButtons[1].trailingAnchor.constraint(equalTo: emojiButtonsContainer.trailingAnchor, constant: -4).isActive = true
		emojiButtons[3].trailingAnchor.constraint(equalTo: emojiButtonsContainer.trailingAnchor, constant: -4).isActive = true

		let rightSideStack: UIStackView = {
			let stackView = UIStackView()

			stackView.alignment = .fill
			stackView.distribution = .fill
			stackView.spacing = 16
			stackView.axis = .vertical

			return stackView
		}()

		rightSideStack.addArrangedSubview(emojiButtonsContainer)
		rightSideStack.addArrangedSubview(reloadButton)

		containerStack.addArrangedSubview(videoPreviewView)
		containerStack.addArrangedSubview(rightSideStack)

		view.addSubview(containerStack)
		view.addSubview(infoTextView)

		let safeArea = view.safeAreaLayoutGuide
		containerStack.translatesAutoresizingMaskIntoConstraints = false
		containerStack.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16).isActive = true
		containerStack.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16).isActive = true
		containerStack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16).isActive = true
		containerStackBottomConstraint = containerStack.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -16)
		containerStackBottomConstraint.isActive = true
	}

	//MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

		infoTextView.delegate = self

		setupInitialLayout()

		let deniedMessage = "Emoji Detector requires camera access in order to analyze your facial expression. To fix this issue, go to Settings > Privacy > Camera and toggle the selector to allow this app to use the camera."

		let launch: ()->Void = {
			self.setupCaptureSession()
			self.photoOutput?.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
		}

		switch AVCaptureDevice.authorizationStatus(for: .video) {
		case .authorized:
			print("Camera access is authorized.")
			launch()

		case .denied:
			print("The user has denied camera permission.")
			alertUser(title: "Camera Access", message: deniedMessage)

		case .notDetermined:
			print("Requesting camera access...")
			AVCaptureDevice.requestAccess(for: .video, completionHandler: { (wasGranted: Bool) in
				if wasGranted {
					launch()
				}
				else {
					self.alertUser(title: "Camera Access", message: deniedMessage)
				}
			})

		case .restricted:
			print("The user cannot set camera permission.")
			alertUser(title: "Camera Access", message: "Your device is restricted from using the camera. Emoji Detector needs the front camera in order to analyze your facial expression. You must allow camera access for this app to work.")
		}
    }

    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        // Use this method to configure the extension and restore previously stored state.
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
    }

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		if videoPreviewLayer != nil {
			updateUI {
				self.videoPreviewLayer!.frame = self.videoPreviewView.bounds
				self.videoPreviewView.layer.addSublayer(self.videoPreviewLayer!)
			}
		}
	}
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
		super.willTransition(to: presentationStyle)
        // Called before the extension transitions to a new presentation style.
        // Use this method to prepare for the change in presentation style.

		switch presentationStyle {
		case .compact:
			break

		case .expanded:
			if !didConstrainHeight {
				containerStack.heightAnchor.constraint(equalToConstant: containerStack.bounds.height).isActive = true

				didConstrainHeight = true
			}

			containerStackBottomConstraint.isActive = false

			if !didConstrainInfoTextView {
				infoTextView.translatesAutoresizingMaskIntoConstraints = false
				infoTextView.topAnchor.constraint(equalTo: containerStack.bottomAnchor, constant: 16).isActive = true
				infoTextView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
				infoTextView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
				infoTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true

				didConstrainInfoTextView = true
			}

			updateUI {
				self.infoTextView.isHidden = false
			}

		case .transcript: break
		}
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
		super.didTransition(to: presentationStyle)
        // Called after the extension transitions to a new presentation style.
        // Use this method to finalize any behaviors associated with the change in presentation style.

		switch presentationStyle {
		case .compact:
			updateUI {
				self.infoTextView.isHidden = true
			}

			containerStackBottomConstraint.isActive = true

		case .expanded:
			if infoTextView.isHidden {
				updateUI {
					self.infoTextView.isHidden = false
				}
			}

		case .transcript: break
		}
    }

	//MARK: Text view
	func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
		let safariViewController = SFSafariViewController(url: url)

		present(safariViewController, animated: true)

		return false
	}

	//MARK: Photo capture
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		detectEmotions(photoData: photo.fileDataRepresentation()!)
	}

	//MARK: - Private members
	private typealias Emojis = (top: Character, second: Character, third: Character, random: Character)
	private typealias Feeling = (key: Emotion, value: Int)

	private var captureSession: AVCaptureSession?
	private var photoOutput: AVCapturePhotoOutput?
	private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

	//MARK: - Private methods
	
	private func alertUser(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
		present(alert, animated: true, completion: nil)
	}

	private func updateUI(_ block: @escaping ()->Void) {
		DispatchQueue.main.async(execute: block)
	}

	private func setupCaptureSession() {
		guard let frontCamera: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
			alertUser(title: "Front Camera", message: "Emoji Detector could not load the front camera.")

			return
		}

		do {
			try frontCamera.lockForConfiguration()
			frontCamera.videoZoomFactor = 1.0
			frontCamera.unlockForConfiguration()
		}
		catch {
			print(error)
		}

		let input = try! AVCaptureDeviceInput(device: frontCamera)

		captureSession = AVCaptureSession()

		captureSession!.beginConfiguration()

		captureSession!.addInput(input)

		photoOutput = AVCapturePhotoOutput()
		guard captureSession!.canAddOutput(photoOutput!) else {
			fatalError("Cannot add photo output.")
		}
		captureSession!.addOutput(photoOutput!)

		captureSession!.commitConfiguration()

		videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
		videoPreviewLayer!.videoGravity = .resizeAspectFill

		captureSession!.startRunning()
	}

	private func detectEmotions(photoData: Data) {
		let model = try! VNCoreMLModel(for: CNNEmotions().model)

		let request = VNCoreMLRequest(model: model, completionHandler: { request, error in
			guard let results = request.results as? [VNClassificationObservation] else {
				fatalError("Unpredicted results from VNCoreMLRequest.")
			}

			self.handleEmotions(results: results)
		})

		do {
			try VNImageRequestHandler(data: photoData).perform([request])
		}
		catch {
			print(error)
		}
	}

	private func handleEmotions(results: [VNClassificationObservation]) {
		var emotions: [Emotion: Int] = [:]
		for result in results {
			emotions[Emotion(rawValue: result.identifier)!] = Int(result.confidence * 100)
		}

		for feeling in emotions.sorted(by: { (left, right) -> Bool in
			return left.value > right.value
		}) {
			print("\(feeling.key.rawValue): \(feeling.value)")
		}
		print("\n", terminator: "")

		let emojis: Emojis = getEmojisFrom(emotions: emotions)

		updateUI {
			self.emojiButtons[0].setTitle(String(emojis.top), for: .normal)
			self.emojiButtons[1].setTitle(String(emojis.second), for: .normal)
			self.emojiButtons[2].setTitle(String(emojis.third), for: .normal)
			self.emojiButtons[3].setTitle(String(emojis.random), for: .normal)
		}
	}

	private func getEmojisFrom(emotions: [Emotion: Int]) -> Emojis {
		var emojis: Emojis

		let feelings: [Feeling] = emotions.sorted { (left, right) -> Bool in
			return left.value > right.value
		}

		let topFeeling = feelings[0]
		emojis.top = getEmojiFor(feeling: topFeeling)

		let secondFeeling: Feeling
		switch topFeeling.value {
		case 50...100:
			secondFeeling = topFeeling

		case 0...50:
			secondFeeling = feelings[1]

		default: fatalError()
		}
		emojis.second = getEmojiFor(feeling: secondFeeling, without: Set([emojis.top]))

		let thirdFeeling: Feeling
		switch topFeeling.value {
		case 75...100:
			thirdFeeling = topFeeling

		case 50..<75:
			thirdFeeling = feelings[1]

		case 0..<50:
			thirdFeeling = feelings[2]

		default: fatalError()
		}
		emojis.third = getEmojiFor(feeling: thirdFeeling, without: Set([emojis.top, emojis.second]))

		emojis.random = Random.miscEmoji

		return emojis
	}

	private func getEmojiFor(feeling: Feeling, without usedEmojis: Set<Character> = Set<Character>()) -> Character {
		switch feeling.key {
		case .angry:
			switch feeling.value {
			case 50...100:
				return Random.from(Set("😤😡🤬").subtracting(usedEmojis))

			case 0..<50:
				return Random.from(Set("🤨😠😑").subtracting(usedEmojis))

			default: fatalError()
			}

		case .disgust:
			switch feeling.value {
			case 50...100:
				let options = Set("🤢🤮").subtracting(usedEmojis)
				if options.isEmpty {
					fallthrough
				}

				return Random.from(options)

			case 0..<50:
				var options = Set("😖😷").subtracting(usedEmojis)
				if options.isEmpty {
					options = Set("🤢🤮")
				}

				return Random.from(options)

			default: fatalError()
			}

		case .fear:
			switch feeling.value {
			case 75...100:
				let options = Set("😱😨").subtracting(usedEmojis)
				guard !options.isEmpty else {
					fallthrough
				}

				return Random.from(options)

			case 50..<75:
				return Random.from(Set("😳😬😧").subtracting(usedEmojis))

			case 0..<50:
				return Random.from(Set("😟😮😲").subtracting(usedEmojis))

			default: fatalError()
			}

		case .happy:
			switch feeling.value {
			case 75...100:
				return Random.from(Set("😂🤣😊🤪😆🤗").subtracting(usedEmojis))

			case 50..<75:
				return Random.from(Set("😃😁😅☺️😝").subtracting(usedEmojis))

			case 0..<50:
				return Random.from(Set("😀😄🙂😌😛").subtracting(usedEmojis))

			default: fatalError()
			}

		case .neutral:
			switch feeling.value {
			case 50...100:
				let options = Set("😶😐").subtracting(usedEmojis)
				guard !options.isEmpty else {
					fallthrough
				}

				return Random.from(options)

			case 0..<50:
				var options = Set("🙃😴").subtracting(usedEmojis)
				if options.isEmpty {
					options = Set("😶😐")
				}

				return Random.from(options)

			default: fatalError()
			}

		case .sad:
			switch feeling.value {
			case 75...100:
				return Random.from(Set("😫😭😰").subtracting(usedEmojis))

			case 50..<75:
				return Random.from(Set("😣😢😥😓").subtracting(usedEmojis))

			case 0..<50:
				return Random.from(Set("😒😞😔😕🙁☹️").subtracting(usedEmojis))

			default: fatalError()
			}

		case .surprise:
			switch feeling.value {
			case 50...100:
				return Random.from(Set("🤭😱😲😵").subtracting(usedEmojis))

			case 0..<50:
				return Random.from(Set("😳😯😮").subtracting(usedEmojis))

			default: fatalError()
			}
		}
	}

}
























































