//
//  AsyncImageView.swift
//  SleepMate
//
//  Created by Claude on Phase 3 Migration
//

import SwiftUI
import Kingfisher

struct AsyncImageView: View {
    let url: String?
    let placeholder: String?
    let contentMode: ContentMode
    let width: CGFloat?
    let height: CGFloat?
    
    init(
        url: String?,
        placeholder: String? = nil,
        contentMode: ContentMode = .fill,
        width: CGFloat? = nil,
        height: CGFloat? = nil
    ) {
        self.url = url
        self.placeholder = placeholder
        self.contentMode = contentMode
        self.width = width
        self.height = height
    }
    
    var body: some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                KFImage(imageURL)
                    .placeholder {
                        placeholderView
                    }
                    .retry(maxCount: 3)
                    .cacheOriginalImage()
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if let placeholder = placeholder {
                Image(placeholder)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholderView
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
    
    private var placeholderView: some View {
        Rectangle()
            .fill(.regularMaterial)
            .overlay {
                Image(systemName: "photo")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
    }
}

// MARK: - Background Image View
struct BackgroundImageView: View {
    let background: BackgroundEntity
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if background.isImage {
                    if background.isLocalImage {
                        // Local image
                        if let imageName = background.bThumbnailUrl {
                            Image(imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            placeholderView
                        }
                    } else {
                        // Remote image
                        AsyncImageView(
                            url: background.bThumbnailUrl,
                            contentMode: .fill
                        )
                    }
                } else {
                    // Color background
                    backgroundColorView
                }
                
                // Selection overlay
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 3)
                        .background(
                            Color.blue.opacity(0.2)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        )
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .background(Color.white, in: Circle())
                        .offset(x: 35, y: -35)
                }
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private var backgroundColorView: some View {
        Rectangle()
            .fill(getBackgroundColor())
            .overlay {
                if background.bColor == "clearColor" {
                    // Show checkerboard pattern for clear color
                    CheckerboardView()
                        .opacity(0.3)
                }
            }
    }
    
    private var placeholderView: some View {
        Rectangle()
            .fill(.regularMaterial)
            .overlay {
                Image(systemName: "photo")
                    .foregroundColor(.secondary)
            }
    }
    
    private func getBackgroundColor() -> Color {
        guard let colorName = background.bColor else { return .black }
        
        switch colorName {
        case "whiteColor": return .white
        case "blueColor": return .blue
        case "redColor": return .red
        case "greenColor": return .green
        case "blackColor": return .black
        case "darkGrayColor": return Color(.darkGray)
        case "lightGrayColor": return Color(.lightGray)
        case "grayColor": return .gray
        case "cyanColor": return .cyan
        case "yellowColor": return .yellow
        case "magentaColor": return .pink
        case "orangeColor": return .orange
        case "purpleColor": return .purple
        case "brownColor": return .brown
        case "clearColor": return .clear
        default: return .black
        }
    }
}

// MARK: - Checkerboard Pattern for Clear Color
struct CheckerboardView: View {
    let rows = 8
    let columns = 8
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<columns, id: \.self) { column in
                        Rectangle()
                            .fill((row + column) % 2 == 0 ? Color.gray.opacity(0.3) : Color.clear)
                    }
                }
            }
        }
    }
}