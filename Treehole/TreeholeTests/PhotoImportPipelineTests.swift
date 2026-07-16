//
//  PhotoImportPipelineTests.swift
//  TreeholeTests
//

import Testing
import UIKit
@testable import Treehole

@Suite("Photo Import Pipeline Tests")
struct PhotoImportPipelineTests {

    /// Solid-color JPEG at an exact pixel size (renderer scale pinned to 1).
    private func makeJPEG(width: CGFloat, height: CGFloat) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        let image = renderer.image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return image.jpegData(compressionQuality: 0.9)!
    }

    private func pixelSize(of data: Data) -> CGSize? {
        guard let image = UIImage(data: data) else { return nil }
        return CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
    }

    // MARK: - processPickedPhoto (PhotosPicker path)

    @Test func testLargePhotoIsDownsampledTo1024Cap() async {
        let outcome = await PhotoImportPipeline.processPickedPhoto(makeJPEG(width: 3000, height: 1500))
        guard case .imported(let jpeg, let thumbnail) = outcome else {
            Issue.record("expected .imported, got \(String(describing: outcome))")
            return
        }
        let size = pixelSize(of: jpeg)
        #expect(size != nil)
        #expect(max(size!.width, size!.height) <= PhotoImportPipeline.maxPixelSize)
        #expect(jpeg.count <= PhotoImportPipeline.maxBytes)
        // Aspect ratio preserved (2:1)
        #expect(abs(size!.width / size!.height - 2.0) < 0.05)
        // Grid thumbnail decoded at append time, capped at the grid pixel size
        #expect(thumbnail != nil)
        let thumbMax = max(
            thumbnail!.size.width * thumbnail!.scale,
            thumbnail!.size.height * thumbnail!.scale
        )
        #expect(thumbMax <= PhotoThumbnailLoader.gridThumbnailMaxPixel)
    }

    @Test func testSmallPhotoKeepsItsPixelSize() async {
        let outcome = await PhotoImportPipeline.processPickedPhoto(makeJPEG(width: 640, height: 480))
        guard case .imported(let jpeg, _) = outcome else {
            Issue.record("expected .imported, got \(String(describing: outcome))")
            return
        }
        let size = pixelSize(of: jpeg)
        #expect(size?.width == 640)
        #expect(size?.height == 480)
    }

    @Test func testUndecodableDataReturnsNilNotSkipped() async {
        // nil (not .skipped) — decode failures never counted toward the
        // "photos skipped" message, matching the original import loop.
        let outcome = await PhotoImportPipeline.processPickedPhoto(Data("not an image".utf8))
        #expect(outcome == nil)
    }

    // MARK: - downsampledJPEG (camera path)

    @Test func testCameraImageIsDownsampledToSameCap() async {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4000, height: 3000), format: format)
        let image = renderer.image { context in
            UIColor.systemIndigo.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4000, height: 3000))
        }
        let data = await PhotoImportPipeline.downsampledJPEG(from: image)
        #expect(data != nil)
        let size = pixelSize(of: data!)
        #expect(size != nil)
        #expect(max(size!.width, size!.height) <= PhotoImportPipeline.maxPixelSize)
        #expect(abs(size!.width / size!.height - 4.0 / 3.0) < 0.05)
    }

    @Test func testCameraImageBelowCapIsNotUpscaled() async {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 600), format: format)
        let image = renderer.image { context in
            UIColor.systemPink.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 800, height: 600))
        }
        let data = await PhotoImportPipeline.downsampledJPEG(from: image)
        #expect(data != nil)
        let size = pixelSize(of: data!)
        #expect(size?.width == 800)
        #expect(size?.height == 600)
    }
}
