import Foundation
import SwiftUI

class ImageCache: ObservableObject {
    static let shared = ImageCache()
    
    private var cache = NSCache<NSString, UIImage>()
    private var loadingTasks: [String: Task<UIImage?, Never>] = [:]
    
    private init() {
        // Configure cache
        cache.countLimit = 100 // Maximum 100 images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    func image(for url: String) -> UIImage? {
        return cache.object(forKey: NSString(string: url))
    }
    
    func setImage(_ image: UIImage, for url: String) {
        cache.setObject(image, forKey: NSString(string: url))
    }
    
    func loadImage(from url: String) async -> UIImage? {
        // Check cache first
        if let cached = image(for: url) {
            return cached
        }
        
        // Check if already loading
        if let existingTask = loadingTasks[url] {
            return await existingTask.value
        }
        
        // Create new loading task
        let task = Task<UIImage?, Never> {
            guard let imageUrl = URL(string: url) else { return nil }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: imageUrl)
                if let image = UIImage(data: data) {
                    setImage(image, for: url)
                    return image
                }
            } catch {
                print("Failed to load image from \(url): \(error)")
            }
            
            return nil
        }
        
        loadingTasks[url] = task
        let result = await task.value
        loadingTasks.removeValue(forKey: url)
        
        return result
    }
    
    func clearCache() {
        cache.removeAllObjects()
        loadingTasks.removeAll()
    }
    
    func preloadImages(urls: [String]) {
        Task {
            await withTaskGroup(of: Void.self) { group in
                for url in urls {
                    group.addTask {
                        _ = await self.loadImage(from: url)
                    }
                }
            }
        }
    }
}

// SwiftUI view for cached images
struct CachedAsyncImage: View {
    let url: String
    let placeholder: Image
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                placeholder
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadImageIfNeeded()
        }
        .onChange(of: url) { _, _ in
            loadImageIfNeeded()
        }
    }
    
    private func loadImageIfNeeded() {
        // Check cache first
        if let cached = ImageCache.shared.image(for: url) {
            image = cached
            return
        }
        
        // Load from network
        isLoading = true
        Task {
            let loadedImage = await ImageCache.shared.loadImage(from: url)
            await MainActor.run {
                image = loadedImage
                isLoading = false
            }
        }
    }
}
