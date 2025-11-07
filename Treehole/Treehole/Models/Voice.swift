//
//  Voice.swift
//  Treehole
//
//  Created by Kayli Cheung on 2025-11-06.
//

import Foundation

struct VoiceConfig: Codable {
    var ttsVoiceId: String = "com.apple.ttsbundle.Samantha-compact"
    var voiceProvider: VoiceProvider = .apple
    var sttLanguage: String = "zh-CN"
    var lastConsentAt: Date?
    var unlockedVoices: [UnlockedVoice] = []
    var preferredEmotion: EmotionParameter = .neutral

    enum VoiceProvider: String, Codable {
        case apple = "apple"
        case piper = "piper"
        case douyin = "douyin" // 豆音 (ByteDance TTS)
        case megatts3 = "megatts3"
    }

    enum EmotionParameter: String, Codable {
        case neutral = "neutral"
        case happy = "happy"
        case calm = "calm"
        case concerned = "concerned"
    }

    struct UnlockedVoice: Codable, Identifiable {
        let id: String
        var name: String
        var provider: VoiceProvider
        var emotion: EmotionParameter
        var language: String
        var source: UnlockSource
        var expiryDate: Date?
        var isActive: Bool = false

        var isExpired: Bool {
            if let expiry = expiryDate {
                return Date() > expiry
            }
            return false
        }

        enum UnlockSource: String, Codable {
            case subscription = "pro_subscription"
            case trial = "trial"
            case event = "event_reward"
            case battlePass = "battle_pass"
            case purchase = "premium_purchase"
        }
    }
}

struct NotificationPermission: Codable {
    var isGranted: Bool = false
    var lastRequestedAt: Date?
    var types: [NotificationType] = [.feeding, .watering, .story]

    enum NotificationType: String, Codable {
        case feeding = "feeding_reminder"
        case watering = "watering_reminder"
        case story = "story_update"
        case task = "daily_task"
        case event = "event_notification"
    }
}
