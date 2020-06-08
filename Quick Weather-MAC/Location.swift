//
//  Location.swift
//  Quick Weather-MAC
//
//  Created by Ozan Mirza on 2/10/19.
//  Copyright © 2019 Ozan Mirza. All rights reserved.
//

import Foundation

struct PLaces: Codable {
    let predictions: [Prediction]
    let status: String
}

struct Prediction: Codable {
    let description, id: String?
    let matchedSubstrings: [MatchedSubstring]?
    let placeID, reference: String?
    let structuredFormatting: StructuredFormatting?
    let terms: [Term]?
    let types: [TypeElement]?
    
    enum CodingKeys: String, CodingKey {
        case description, id
        case matchedSubstrings = "matched_substrings"
        case placeID = "place_id"
        case reference
        case structuredFormatting = "structured_formatting"
        case terms, types
    }
}

struct MatchedSubstring: Codable {
    let length, offset: Int
}

struct StructuredFormatting: Codable {
    let mainText: String
    let mainTextMatchedSubstrings: [MatchedSubstring]
    let secondaryText: String
    
    enum CodingKeys: String, CodingKey {
        case mainText = "main_text"
        case mainTextMatchedSubstrings = "main_text_matched_substrings"
        case secondaryText = "secondary_text"
    }
}

struct Term: Codable {
    let offset: Int
    let value: String
}

enum TypeElement: String, Codable {
    case geocode = "geocode"
    case locality = "locality"
    case political = "political"
    case route = "route"
}
