//
//  Random.swift
//  Essentials
//
//  Created by Will Tyler on 5/19/18.
//  Copyright © 2018 Will Tyler. All rights reserved.
//

import Foundation

public class Random {

	private static func randomFor<T: ExpressibleByIntegerLiteral>(type: T.Type) -> T {
		var number: T = 0
		arc4random_buf(&number, MemoryLayout<T>.size)

		return number
	}

	private static func uint32(lower: UInt32 = UInt32.min, upper: UInt32 = UInt32.max) -> UInt32 {
		precondition(upper > lower)

		let range = upper - lower

		return arc4random_uniform(range+1) + lower
	}

	private static func int32(lower: Int32 = Int32.min, upper: Int32 = Int32.max) -> Int32 {
		precondition(upper > lower)

		let range = Int64(upper) - Int64(lower)
		let result = uint32(upper: UInt32(range)+1)

		return Int32(result) + lower
	}

	private static func uint64(lower: UInt64 = UInt64.min, upper: UInt64 = UInt64.max) -> UInt64 {
		precondition(upper > lower)

		let range = upper - lower
		var min: UInt64
		var random = randomFor(type: UInt64.self)

		if range > UInt64(Int64.max) {
			min = ~range + 1
		}
		else {
			min = ((UInt64.max - (2*range)) + 1) % range
		}

		while random < min {
			random = randomFor(type: UInt64.self)
		}

		return (random % (range+1)) + lower
	}

	private static func int64(lower: Int64 = Int64.min, upper: Int64 = Int64.max) -> Int64 {
		precondition(upper > lower)

		let (range, overflow) = upper.subtractingReportingOverflow(lower)
		let bound = overflow ? UInt64.max - UInt64(~range) : UInt64(range)
		let random = uint64(upper: bound)

		if random > UInt64(Int64.max)  {
			return Int64(random - (UInt64(~lower) + 1))
		}
		else {
			return Int64(random) + lower
		}
	}

	private static func uint(lower: UInt = UInt.min, upper: UInt = UInt.max) -> UInt {
		switch MemoryLayout<UInt>.size {
		case 4: return UInt(uint32(lower: UInt32(lower), upper: UInt32(upper)))
		case 8: return UInt(uint64(lower: UInt64(lower), upper: UInt64(upper)))
		default: fatalError("Could not recognize Int size.")
		}
	}

	// both parameters inclusive
	private static func int(lower: Int = Int.min, upper: Int = Int.max) -> Int {
		switch MemoryLayout<Int>.size {
		case 4: return Int(int32(lower: Int32(lower), upper: Int32(upper)))
		case 8: return Int(int64(lower: Int64(lower), upper: Int64(upper)))
		default: fatalError("Could not recognize Int size")
		}
	}

	public static var bool: Bool {
		get {
			return arc4random_uniform(2) == 1
		}
	}

	public static var int: Int {
		get {
			return randomFor(type: Int.self)
		}
	}

	public static var uint: UInt {
		get {
			return randomFor(type: UInt.self)
		}
	}

	public static func from<CollectionType: Collection>(_ collection: CollectionType) -> CollectionType.Element {
		precondition(!collection.isEmpty, "Collection cannot be empty.")

		guard collection.count != 1 else {
			return collection[collection.startIndex]
		}

		let offset = int(lower: 0, upper: collection.count-1)
		let index = collection.index(collection.startIndex, offsetBy: offset)

		return collection[index]
	}

}

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






























