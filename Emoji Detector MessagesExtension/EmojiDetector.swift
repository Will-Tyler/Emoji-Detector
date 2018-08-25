//
// Created by Will Tyler on 8/24/18.
// Copyright (c) 2018 Will Tyler. All rights reserved.
//

import Foundation
import CoreML
import Vision


final class EmojiDetector {

	private static let model = try! VNCoreMLModel(for: CNNEmotions().model)

	private typealias Feeling = (key: Emotion, value: Int)

	/// Handle the emojis that are predicted from the photoData passed in.
	static func handleEmojis(from photoData: Data, with handler: @escaping (Emojis)->()) {
		detectEmotions(photoData: photoData, emojiHandler: handler)
	}

	private static func detectEmotions(photoData: Data, emojiHandler: @escaping (Emojis)->()) {
		let request = VNCoreMLRequest(model: model, completionHandler: { request, error in
			guard let results = request.results as? [VNClassificationObservation] else {
				fatalError("Unpredicted results from VNCoreMLRequest.")
			}

			self.handleEmotions(results: results, emojiHandler: emojiHandler)
		})

		do {
			try VNImageRequestHandler(data: photoData).perform([request])
		}
		catch {
			print(error)
		}
	}

	private static func handleEmotions(results: [VNClassificationObservation], emojiHandler: (Emojis)->()) {
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

		emojiHandler(emojis)
	}

	private static func getEmojisFrom(emotions: [Emotion: Int]) -> Emojis {
		let feelings: [Feeling] = emotions.sorted { (left, right) -> Bool in
			return left.value > right.value
		}

		let topFeeling = feelings[0]
		let first = getEmojiFor(feeling: topFeeling)

		let secondFeeling: Feeling
		switch topFeeling.value {
		case 50...100:
			secondFeeling = topFeeling

		case 0...50:
			secondFeeling = feelings[1]

		default: fatalError()
		}
		let second = getEmojiFor(feeling: secondFeeling, without: Set([first]))

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
		let third = getEmojiFor(feeling: thirdFeeling, without: Set([first, second]))

		let random = Random.miscEmoji

		return Emojis(first: first, second: second, third: third, random: random)
	}

	private static func getEmojiFor(feeling: Feeling, without usedEmojis: Set<Character> = Set<Character>()) -> Character {
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
