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
import EssentialsiOS


class MessagesViewController: MSMessagesAppViewController, AVCapturePhotoCaptureDelegate, UITextViewDelegate {

	//MARK: - Outlets
	@IBOutlet weak var videoPreviewView: UIView!
	@IBOutlet weak var infoTextView: UITextView!
	@IBOutlet weak var functionallityContainer: UIStackView!

	@IBOutlet weak var emojiButton1: UIButton!
	@IBOutlet weak var emojiButton2: UIButton!
	@IBOutlet weak var emojiButton3: UIButton!
	@IBOutlet weak var emojiButton4: UIButton!

	//MARK: - Actions
	@IBAction func emojiButtonPressed(_ sender: UIButton) {
		requestPresentationStyle(.compact)

		activeConversation?.insertText(sender.title(for: .normal)!, completionHandler: nil)
	}
	@IBAction func reloadButtonPressed(_ sender: UIButton) {
		photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
	}

	//MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

		infoTextView.delegate = self

		DispatchQueue.main.async {
			let _ = NSAttributedString(string: "https://www.openu.ac.il/home/hassner/projects/cnn_emotions/", attributes: [NSAttributedStringKey.link: NSURL(string: "https://www.openu.ac.il/home/hassner/projects/cnn_emotions/")!])
			let _ = NSAttributedString(string: "will.tyler11@gmail.com")
			self.infoTextView.text =
				"""
				Emoji Detector takes photos of your face and uses a machine learning model to determine the best emojis to use based off of your facial expression.

				Emoji Detector runs entirely on your device, and while this means the app uses more storage, any photo captured by this app will not leave your device, and will be gone once your emojis are detected.

				The machine learning model was developed by Gil Levi and Tal Hassner. https://www.openu.ac.il/home/hassner/projects/cnn_emotions/

				Contact the developer at will.tyler11@gmail.com.
				"""
			self.infoTextView.isHidden = true
		}

		switch AVCaptureDevice.authorizationStatus(for: .video) {
		case .authorized:
			print("Camera access is authorized.")
			setupCaptureSession()
			photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)

		case .denied:
			print("The user has denied camera permission.")
			fallthrough

		case .notDetermined:
			print("Requesting camera access...")
			AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
				if granted {
					self.setupCaptureSession()
				}
			})

		case .restricted:
			print("The user cannot set camera permission.")

			return
		}
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Conversation Handling
    
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

		DispatchQueue.main.async {
			self.videoPreviewLayer.frame = self.videoPreviewView.bounds
			self.videoPreviewView.layer.addSublayer(self.videoPreviewLayer)
		}
	}
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
        // Use this method to prepare for the change in presentation style.

		switch presentationStyle {
		case .compact:
			DispatchQueue.main.async {
				self.infoTextView.isHidden = true
			}

		case .expanded:
			if !didConstrainHeight {
				DispatchQueue.main.async {
					self.functionallityContainer.heightAnchor.constraint(equalToConstant: self.functionallityContainer.bounds.height).isActive = true
					self.didConstrainHeight = true
				}
			}

		case .transcript:
			break
		}
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
        // Use this method to finalize any behaviors associated with the change in presentation style.

		switch presentationStyle {
		case .compact:
			if !infoTextView.isHidden {
				DispatchQueue.main.async {
					self.infoTextView.isHidden = true
				}
			}

		case .expanded:
			DispatchQueue.main.async {
				self.infoTextView.isHidden = false
			}

		case .transcript:
			break
		}
    }

	//MARK: Text view
	func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
//		print("Opening", url.absoluteString + "...")
//
//		let webView = WKWebView(frame: view.subviews[0].frame)
//		view.addSubview(webView)
//		webView.load(URLRequest(url: url))

		return true
	}

	private typealias Emojis = (top: Character, second: Character, third: Character, random: Character)
	private typealias Feeling = (key: Emotion, value: Int)

	private var captureSession: AVCaptureSession!
	private var photoOutput: AVCapturePhotoOutput!
	private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
	private var didConstrainHeight = false

	private func setupCaptureSession() {
		guard let frontCamera: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
			fatalError("Could not load front camera.")
		}

		do {
			try frontCamera.lockForConfiguration()
			frontCamera.videoZoomFactor = 1.0
			frontCamera.unlockForConfiguration()
		}
		catch {
			print(error)
		}

		guard let input = try? AVCaptureDeviceInput(device: frontCamera) else {
			fatalError("Could not load front camera input.")
		}

		captureSession = AVCaptureSession()

		captureSession.beginConfiguration()

		captureSession.addInput(input)

		photoOutput = AVCapturePhotoOutput()
		guard captureSession.canAddOutput(photoOutput) else {
			fatalError("Cannot add photo output.")
		}
		captureSession.addOutput(photoOutput)

		captureSession.commitConfiguration()

		videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		videoPreviewLayer.videoGravity = .resizeAspectFill

		captureSession.startRunning()
	}

	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		detectEmotions(photoData: photo.fileDataRepresentation()!)
	}

	private func detectEmotions(photoData: Data) {
		guard let model = try? VNCoreMLModel(for: CNNEmotions().model) else {
			fatalError("Could not load CNNEmotions model.")
		}

		let request = VNCoreMLRequest(model: model, completionHandler: { request, error in
			guard let results = request.results as? [VNClassificationObservation] else {
				fatalError("Unpredicted results from VNCoreMLRequest.")
			}

			self.handleEmotions(results: results)
		})

		let handler = VNImageRequestHandler(data: photoData)

		do {
			try handler.perform([request])
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
		print("\n")

		let emojis: Emojis = getEmojis(emotions: emotions)

		emojiButton1.setTitle(String(emojis.top), for: .normal)
		emojiButton2.setTitle(String(emojis.second), for: .normal)
		emojiButton3.setTitle(String(emojis.third), for: .normal)
		emojiButton4.setTitle(String(emojis.random), for: .normal)
	}

	private func getEmojis(emotions: [Emotion: Int]) -> Emojis {
		var emojis: Emojis

		let feelings: [Feeling] = emotions.sorted { (left, right) -> Bool in
			return left.value > right.value
		}

		let topFeeling = feelings[0]
		emojis.top = getEmojiForFeeling(feeling: topFeeling)

		let secondFeeling: Feeling
		switch topFeeling.value {
		case 50...100:
			secondFeeling = topFeeling

		case 0...50:
			secondFeeling = feelings[1]

		default: fatalError()
		}
		emojis.second = getEmojiForFeeling(feeling: secondFeeling, without: Set([emojis.top]))

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
		emojis.third = getEmojiForFeeling(feeling: thirdFeeling, without: Set([emojis.top, emojis.second]))

		emojis.random = Random.miscEmoji

		return emojis
	}

	private func getEmojiForFeeling(feeling: Feeling, without usedEmojis: Set<Character> = Set<Character>()) -> Character {
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
				return Random.from(Set("🤭😲😵").subtracting(usedEmojis))

			case 0..<50:
				return Random.from(Set("😳😱😯😮").subtracting(usedEmojis))

			default: fatalError()
			}
		}
	}

}
























































