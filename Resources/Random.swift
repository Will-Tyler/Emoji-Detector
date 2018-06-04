//
//  Random.swift
//  Essentials
//
//  Created by Will Tyler on 5/19/18.
//  Copyright © 2018 Will Tyler. All rights reserved.
//

import Foundation
import EssentialsiOS

extension Random {

	static var miscEmoji: Character {
		get {
			return Random.from(Emojis.miscEmojis)
		}
	}

	static var happyEmoji: Character {
		get {
			return Random.from(Emojis.happyEmojis)
		}
	}

	static var sadEmoji: Character {
		get {
			return Random.from(Emojis.sadEmojis)
		}
	}

	static var surpriseEmoji: Character {
		get {
			return Random.from(Emojis.surpriseEmojis)
		}
	}

	static var disgustEmoji: Character {
		get {
			return Random.from(Emojis.disgustEmojis)
		}
	}

	static var neutralEmoji: Character {
		get {
			return Random.from(Emojis.neutralEmojis)
		}
	}

	static var angryEmoji: Character {
		get {
			return Random.from(Emojis.angryEmojis)
		}
	}

}






























