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
import WebKit
import SafariServices
import Firebase


@objc(MessagesViewController)

final class MessagesViewController: MSMessagesAppViewController, AVCapturePhotoCaptureDelegate, UITextViewDelegate {

	//MARK: - Views
	private let containerStack: UIStackView = {
		let stackView = UIStackView()

		stackView.alignment = .fill
		stackView.distribution = .fillEqually
		stackView.spacing = 16
		stackView.axis = .horizontal

		return stackView
	}()
	private let videoPreviewView: UIView = {
		let view = UIView()

		view.backgroundColor = .blue

		return view
	}()
	private let emojisViewController = EmojisViewController()
	private let infoTextView: UITextView = {
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
		textView.isEditable = false
		textView.isSelectable = true
		textView.font = UIFont.preferredFont(forTextStyle: .body)
		textView.dataDetectorTypes = .link

		return textView
	}()

	private func setupInitialLayout() {
		let reloadButton: UIButton = {
			let button = UIButton(type: .system)

			button.setTitle("Reload 🔄", for: .normal)
			button.addTarget(self, action: #selector(reloadButtonPressed), for: .touchUpInside)

			return button
		}()

		reloadButton.heightAnchor.constraint(equalToConstant: reloadButton.intrinsicContentSize.height).isActive = true

		let emojiButtonsContainer = emojisViewController.view!
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

		FirebaseApp.configure()

	    addChildViewController(emojisViewController)

		infoTextView.delegate = self
	    emojisViewController.messagesViewController = self

		setupInitialLayout()

		let deniedMessage = "Emoji Detector requires camera access in order to analyze your facial expression. To fix this issue, go to Settings > Privacy > Camera and toggle the selector to allow this app to use the camera."

		let launch: ()->() = {
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
			DispatchQueue.main.async {
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

			DispatchQueue.main.async {
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
			DispatchQueue.main.async {
				self.infoTextView.isHidden = true
			}

			containerStackBottomConstraint.isActive = true

		case .expanded:
			if infoTextView.isHidden {
				DispatchQueue.main.async {
					self.infoTextView.isHidden = false
				}
			}

		case .transcript: break
		}
    }

	private var containerStackBottomConstraint: NSLayoutConstraint!
	private var didConstrainHeight = false
	private var didConstrainInfoTextView = false

	//MARK: - Actions
	@objc private func reloadButtonPressed() {
		photoOutput?.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
	}

	//MARK: Text view
	func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
		let safariViewController = SFSafariViewController(url: url)

		present(safariViewController, animated: true)

		return false
	}

	//MARK: Photo capture
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		EmojiDetector.handleEmojis(from: photo.fileDataRepresentation()!, with: { emojis in
			self.emojisViewController.updateEmojiButtons(with: emojis)
		})
	}

	//MARK: - Private members
	private var captureSession: AVCaptureSession?
	private var photoOutput: AVCapturePhotoOutput?
	private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

	//MARK: - Private methods
	
	private func alertUser(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
		present(alert, animated: true, completion: nil)
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

}
