//
//  AudioStorageTests.swift
//  TreeholeTests
//

import Testing
import Foundation
@testable import Treehole

@Suite("AudioStorage Tests")
struct AudioStorageTests {

    // Write a small Data blob, verify the local URL exists, then delete it.
    @Test func testSaveAndLoadURLExists() throws {
        let sampleData = Data("fake-audio-data".utf8)
        guard let filename = AudioStorage.saveAudio(sampleData) else {
            Issue.record("saveAudio returned nil")
            return
        }
        defer { AudioStorage.deleteAudio(filename: filename) }
        let url = AudioStorage.loadAudioURL(filename: filename)
        #expect(url != nil)
        #expect(FileManager.default.fileExists(atPath: url!.path))
    }

    // Verify the saved file has .m4a extension.
    @Test func testSavedFilenameHasM4AExtension() throws {
        let sampleData = Data("audio-extension-test".utf8)
        guard let filename = AudioStorage.saveAudio(sampleData) else {
            Issue.record("saveAudio returned nil")
            return
        }
        defer { AudioStorage.deleteAudio(filename: filename) }
        #expect(filename.hasSuffix(".m4a"))
    }

    // After deleting, loadAudioURL should return nil.
    @Test func testDeleteRemovesFile() throws {
        let sampleData = Data("audio-delete-test".utf8)
        guard let filename = AudioStorage.saveAudio(sampleData) else {
            Issue.record("saveAudio returned nil")
            return
        }
        AudioStorage.deleteAudio(filename: filename)
        let url = AudioStorage.loadAudioURL(filename: filename)
        #expect(url == nil)
    }

    // Loading a non-existent filename returns nil without crashing.
    @Test func testLoadNonExistentReturnsNil() throws {
        let url = AudioStorage.loadAudioURL(filename: "nonexistent-file.m4a")
        #expect(url == nil)
    }

    // Each save produces a unique filename.
    @Test func testEachSaveProducesUniqueFilename() throws {
        let data = Data("unique-test".utf8)
        guard let f1 = AudioStorage.saveAudio(data),
              let f2 = AudioStorage.saveAudio(data) else {
            Issue.record("saveAudio returned nil")
            return
        }
        defer {
            AudioStorage.deleteAudio(filename: f1)
            AudioStorage.deleteAudio(filename: f2)
        }
        #expect(f1 != f2)
    }
}
