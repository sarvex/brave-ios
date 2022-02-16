// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Combine
import Data
import CoreData

private struct PlaylistFolderImage: View {
    static let cornerRadius = 10.0
    private static let favIconSize = 16.0
    private var thumbnailLoader: ImageLoader
    private var favIconLoader: ImageLoader
    
    private var title: String?
    @State private var thumbnail = UIImage()
    @State private var favIcon = UIImage()
    
    init(item: PlaylistItem) {
        title = item.name
        thumbnailLoader = ImageLoader(thumbnail: item)
        favIconLoader = ImageLoader(favIcon: item)
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: PlaylistFolderImage.cornerRadius, style: .continuous))
                .overlay(tint.opacity(0.25))
            
            VStack(alignment: .leading) {
                Image(uiImage: favIcon)
                    .resizable()
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(width: PlaylistFolderImage.favIconSize,
                           height: PlaylistFolderImage.favIconSize)
                    .clipShape(RoundedRectangle(cornerRadius: 2.5, style: .continuous))
                
                Spacer()
                
                Text(title ?? "")
                    .font(.callout.weight(.medium))
                    .lineLimit(2)
                    .foregroundColor(.white)
            }
            .padding(8.0)
        }
        .frame(maxWidth: (UIScreen.main.bounds.width / 2.0) - 12.0,
               minHeight: 100.0,
               maxHeight: 100.0)
        .onReceive(thumbnailLoader.$image) {
            self.thumbnail = $0 ?? UIImage()
        }
        .onReceive(favIconLoader.$image) {
            self.favIcon = $0 ?? UIImage()
        }
    }
    
    private var tint: some View {
        EmptyView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: PlaylistFolderImage.cornerRadius, style: .continuous))
    }
    
    private class ImageLoader: ObservableObject {
        @Published var image: UIImage?
        
        private let renderer = PlaylistThumbnailRenderer()
        
        init(thumbnail: PlaylistItem) {
            guard let mediaSrc = thumbnail.mediaSrc,
                  let assetUrl = URL(string: mediaSrc) else {
                image = nil
                return
            }
            
            loadImage(url: assetUrl, isFavIcon: false)
        }
        
        init(favIcon: PlaylistItem) {
            guard let pageSrc = favIcon.pageSrc,
                  let favIconUrl = URL(string: pageSrc) else {
                image = nil
                return
            }
            
            loadImage(url: favIconUrl, isFavIcon: true)
        }
        
        private func loadImage(url: URL, isFavIcon: Bool) {
            renderer.loadThumbnail(assetUrl: isFavIcon ? nil : url,
                                   favIconUrl: isFavIcon ? url : nil,
                                   completion: { [weak self] image in
                self?.image = image
            })
        }
    }
}

struct PlaylistNewFolderView: View {
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(
        entity: PlaylistItem.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \PlaylistItem.order, ascending: true),
            NSSortDescriptor(keyPath: \PlaylistItem.dateAdded, ascending: false)
        ],
        predicate: NSPredicate(format: "playlistFolder.uuid == %@", PlaylistFolder.savedFolderUUID)
    ) var items: FetchedResults<PlaylistItem>
    
    private let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    @State private var folderName: String = ""
    @State private var selected: [NSManagedObjectID] = []
    
    var onCancelButtonPressed: (() -> Void)?
    var onCreateFolder: ((_ folderTitle: String, _ selectedItems: [NSManagedObjectID]) -> Void)?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Untitled Folder", text: $folderName)
                        .disableAutocorrection(true)
                        .frame(maxWidth: .infinity,
                               minHeight: 44.0,
                               maxHeight: 44.0)
                }
                .listRowBackground(Color(.secondaryBraveGroupedBackground))
                
                if !items.isEmpty {
                    Section {
                        VStack(alignment: .leading) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5.0) {
                                    Text("Add videos to this folder")
                                        .font(.callout.weight(.medium))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                    Text("Tap to select videos")
                                        .font(.footnote)
                                        .foregroundColor(Color(.secondaryBraveLabel))
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            
                            LazyVGrid(columns: gridItems, alignment: .leading, spacing: 12.0) {
                                ForEach((0..<items.count), id: \.self) { index in
                                    PlaylistFolderImage(item: items[index])
                                        .overlay(
                                            RoundedRectangle(cornerRadius: PlaylistFolderImage.cornerRadius, style: .continuous)
                                                .stroke(Color.blue, lineWidth: selected.contains(items[index].objectID) ? 2.0 : 0.0)
                                        )
                                        .onTapGesture {
                                        if let index = selected.firstIndex(of: items[index].objectID) {
                                            selected.remove(at: index)
                                        } else {
                                            selected.append(items[index].objectID)
                                        }
                                    }
                                }
                            }
                        }
                        .listRowInsets(.zero)
                        .listRowBackground(Color(.braveGroupedBackground))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(.stack)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancelButtonPressed?() }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { onCreateFolder?(folderName, selected) }
                    .foregroundColor(.white)
                }
            }
        }
        .background(Color(.braveBackground))
        .environment(\.colorScheme, .dark)
    }
}

//swiftlint:disable:next swiftui_previews_guard
struct PlaylistNewFolderView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistNewFolderView()
            .environment(\.managedObjectContext, DataController.swiftUIContext)
    }
}
