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
import MessageUI
import SafariServices


class MessagesViewController: MSMessagesAppViewController, AVCapturePhotoCaptureDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate {

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

		let emoji = sender.title(for: .normal)!

		activeConversation?.insertText(emoji, completionHandler: nil)
	}
	@IBAction func reloadButtonPressed(_ sender: UIButton) {
		photoOutput?.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
	}

	//MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

		infoTextView.delegate = self
		updateUI {
			self.infoTextView.text =
			"""
			Emoji Detector uses photos of your face and a machine learning model to determine the best emojis to use based off of your facial expression.

			If this app isn't displaying the correct emojis, try exaggerating your facial expresssions, or positioning the camera with a different background.

			Emoji Detector runs entirely on your device, and while this means the app uses more storage, any photo captured by this app will not leave your device and will be gone once your emojis are detected.

			The machine learning model was developed by Gil Levi and Tal Hassner. https://www.openu.ac.il/home/hassner/projects/cnn_emotions/

			If you enjoy this app or have any suggestions, please leave a review on the iMessage App Store!
			"""
			self.infoTextView.isHidden = true
		}

		let deniedMessage = "Emoji Detector requires camera access in order to analyze your facial expression. To fix this issue, go to Settings > Privacy > Camera and toggle the selector to allow this app to use the camera."

		let launch: () -> Void = {
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
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
        // Use this method to prepare for the change in presentation style.

		switch presentationStyle {
		case .compact:
			updateUI {
				self.infoTextView.isHidden = true
			}

		case .expanded:
			if !didConstrainHeight {
				updateUI {
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
				updateUI {
					self.infoTextView.isHidden = true
				}
			}

		case .expanded:
			updateUI {
				self.infoTextView.isHidden = false
			}

		case .transcript:
			break
		}
    }

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		guard videoPreviewLayer != nil else {
			return
		}

		updateUI {
			self.videoPreviewLayer!.frame = self.videoPreviewView.bounds
			self.videoPreviewView!.layer.addSublayer(self.videoPreviewLayer!)
		}
	}

	//MARK: Text view
	func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
		print("Opening", url.absoluteString + "...")

		if url.absoluteString.hasPrefix("mailto:") {
			guard MFMailComposeViewController.canSendMail() else {
				alertUser(title: "Email", message: "Your device is not configured to send email.")

				return false
			}

			let emailViewController = MFMailComposeViewController()
			emailViewController.mailComposeDelegate = self

			var emailAddress: String = url.absoluteString
			emailAddress.removeFirst("mailto:".count)

			emailViewController.setToRecipients([emailAddress])
			emailViewController.setSubject("Emoji Detector")

			present(emailViewController, animated: true, completion: nil)

			return false
		}
		else {
			let safariViewController = SFSafariViewController(url: url)

			present(safariViewController, animated: true)

			return false
		}
	}

	//MARK: Email composition
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		if let error = error {
			print(error)
		}

		controller.dismiss(animated: true, completion: nil)
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
	private var didConstrainHeight = false

	//MARK: - Private methods
	private func alertUser(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
		self.present(alert, animated: true, completion: nil)
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
		guard let model = try? VNCoreMLModel(for: CNNEmotions().model) else {
			fatalError("Could not load CNNEmotions model.")
		}

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
		print("")

		let emojis: Emojis = getEmojisFrom(emotions: emotions)

		updateUI {
			self.emojiButton1.setTitle(String(emojis.top), for: .normal)
			self.emojiButton2.setTitle(String(emojis.second), for: .normal)
			self.emojiButton3.setTitle(String(emojis.third), for: .normal)
			self.emojiButton4.setTitle(String(emojis.random), for: .normal)
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
				return Random.from(Set("🤭😲😵").subtracting(usedEmojis))

			case 0..<50:
				return Random.from(Set("😳😱😯😮").subtracting(usedEmojis))

			default: fatalError()
			}
		}
	}

}
























































