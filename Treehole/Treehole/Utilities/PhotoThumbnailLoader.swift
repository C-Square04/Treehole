import SwiftUI
import ImageIO
import UIKit

// MARK: - Photo Thumbnail Loader

/// Loads journal photos as downsampled thumbnails off the main thread.
/// CGImageSourceCreateThumbnailAtIndex decodes directly at the target pixel
/// size — the full-resolution bitmap is never materialized — and results are
/// cached per filename + pixel size so scrolling back never re-decodes.
enum PhotoThumbnailLoader {

    /// Pixel cap for grid thumbnails — covers the largest cell (~170pt @3x).
    nonisolated static let gridThumbnailMaxPixel: CGFloat = 512

    nonisolated(unsafe) private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200
        return cache
    }()

    /// Synchronous cache probe — lets a cell skip the placeholder frame when
    /// its thumbnail was already decoded.
    nonisolated static func cachedThumbnail(filename: String, maxPixelSize: CGFloat) -> UIImage? {
        cache.object(forKey: cacheKey(filename, maxPixelSize))
    }

    nonisolated static func thumbnail(filename: String, maxPixelSize: CGFloat) async -> UIImage? {
        let key = cacheKey(filename, maxPixelSize)
        if let hit = cache.object(forKey: key) { return hit }
        let url = PhotoStorage.photoURL(filename)
        let image = await Task.detached(priority: .userInitiated) {
            ImageDownsampler.image(url: url, maxPixelSize: maxPixelSize)
        }.value
        if let image { cache.setObject(image, forKey: key) }
        return image
    }

    nonisolated private static func cacheKey(_ filename: String, _ maxPixelSize: CGFloat) -> NSString {
        "\(filename)#\(Int(maxPixelSize))" as NSString
    }
}

// MARK: - Photo Import Pipeline

/// Import-time downsampling shared by the PhotosPicker and camera paths:
/// 1024px max dimension, JPEG quality 0.7, 2MB cap. All decoding, resizing,
/// and encoding runs off the caller's actor.
enum PhotoImportPipeline {

    nonisolated static let maxPixelSize: CGFloat = 1024
    nonisolated static let jpegQuality: CGFloat = 0.7
    nonisolated static let maxBytes = 2_000_000

    enum Outcome: Sendable {
        case imported(jpeg: Data, thumbnail: UIImage?)
        /// Encoded JPEG missing or over the size cap — counts toward the
        /// "photos skipped" message, unlike an undecodable item.
        case skipped
    }

    /// nil = data isn't a decodable image (not counted as "skipped",
    /// matching the previous `UIImage(data:)` guard in the import loop).
    nonisolated static func processPickedPhoto(_ data: Data) async -> Outcome? {
        await Task.detached(priority: .userInitiated) { () -> Outcome? in
            guard let image = ImageDownsampler.image(data: data, maxPixelSize: maxPixelSize) else { return nil }
            guard let jpeg = image.jpegData(compressionQuality: jpegQuality), jpeg.count <= maxBytes else {
                return .skipped
            }
            let thumbnail = ImageDownsampler.image(data: jpeg, maxPixelSize: PhotoThumbnailLoader.gridThumbnailMaxPixel)
            return .imported(jpeg: jpeg, thumbnail: thumbnail)
        }.value
    }

    /// Camera capture path: same 1024px/JPEG cap as the PhotosPicker path.
    nonisolated static func downsampledJPEG(from image: UIImage) async -> Data? {
        await Task.detached(priority: .userInitiated) { () -> Data? in
            let pixelWidth = image.size.width * image.scale
            let pixelHeight = image.size.height * image.scale
            let largest = max(pixelWidth, pixelHeight)
            guard largest > maxPixelSize else { return image.jpegData(compressionQuality: jpegQuality) }
            let ratio = maxPixelSize / largest
            let target = CGSize(width: (pixelWidth * ratio).rounded(), height: (pixelHeight * ratio).rounded())
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let renderer = UIGraphicsImageRenderer(size: target, format: format)
            let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: target)) }
            return resized.jpegData(compressionQuality: jpegQuality)
        }.value
    }

    /// Decodes a thumbnail from in-memory data off the caller's actor —
    /// used for draft photos that aren't on disk yet.
    nonisolated static func decodedThumbnail(data: Data, maxPixelSize: CGFloat) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            ImageDownsampler.image(data: data, maxPixelSize: maxPixelSize)
        }.value
    }
}

// MARK: - Downsampling (CGImageSource)

private enum ImageDownsampler {

    nonisolated static func image(data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        return thumbnailImage(source: source, maxPixelSize: maxPixelSize)
    }

    nonisolated static func image(url: URL, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else { return nil }
        return thumbnailImage(source: source, maxPixelSize: maxPixelSize)
    }

    nonisolated private static func thumbnailImage(source: CGImageSource, maxPixelSize: CGFloat) -> UIImage? {
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,   // bake EXIF orientation
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ] as [CFString: Any] as CFDictionary
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Async Thumbnail View

/// Grid thumbnail cell: async-decodes via PhotoThumbnailLoader, showing a
/// neutral placeholder while loading. Callers apply frame + clipShape exactly
/// as they previously did to the Image.
struct AsyncThumbnailView: View {
    let filename: String
    let maxPixelSize: CGFloat

    @State private var image: UIImage?

    init(filename: String, maxPixelSize: CGFloat = PhotoThumbnailLoader.gridThumbnailMaxPixel) {
        self.filename = filename
        self.maxPixelSize = maxPixelSize
        _image = State(initialValue: PhotoThumbnailLoader.cachedThumbnail(filename: filename, maxPixelSize: maxPixelSize))
    }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.1)
                ProgressView()
            }
        }
        .task(id: filename) {
            guard image == nil else { return }
            image = await PhotoThumbnailLoader.thumbnail(filename: filename, maxPixelSize: maxPixelSize)
        }
    }
}
