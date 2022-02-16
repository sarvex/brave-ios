// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Combine
import Data
import CoreData

private struct PlaylistFolderImage: View {
    static let cornerRadius = 5.0
    private var thumbnailLoader: ImageLoader
    private var favIconLoader: ImageLoader
    
    @State private var thumbnail = UIImage()
    @State private var favIcon = UIImage()
    
    init(item: PlaylistItem) {
        thumbnailLoader = ImageLoader(thumbnail: item)
        favIconLoader = ImageLoader(favIcon: item)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            Image(uiImage: thumbnail)
                .resizable()
                .background(Color.black)
                .frame(maxWidth: 100.0, minHeight: 60.0, maxHeight: 60.0, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: PlaylistFolderImage.cornerRadius, style: .continuous))
            
            Image(uiImage: favIcon)
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
                .frame(width: 16.0, height: 16.0, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 2.5, style: .continuous))
                .padding(8.0)
        }
        .onReceive(thumbnailLoader.$image) {
            self.thumbnail = $0 ?? UIImage()
        }
        .onReceive(favIconLoader.$image) {
            self.favIcon = $0 ?? UIImage()
        }
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

private struct PlaylistFolderView: View {
    let iconColor: Color
    let titleColor: Color
    let folder: PlaylistFolder?
    @Binding var selectedFolder: PlaylistFolder?
    
    var body: some View {
        HStack(alignment: .center, spacing: 18.0) {
            Image(systemName: "folder")
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(iconColor)
            
            VStack(alignment: .leading) {
                if let folder = folder {
                    Text(folder.title ?? "")
                        .font(.body)
                        .foregroundColor(titleColor)
                    Text("\(folder.playlistItems?.count ?? 0) Items")
                        .font(.footnote)
                        .foregroundColor(titleColor)
                } else {
                    Spacer()
                }
            }
            
            if selectedFolder?.uuid == folder?.uuid {
                Spacer()
                Image(systemName: "checkmark")
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
            }
        }
        .padding(EdgeInsets(top: 7.0, leading: 0.0, bottom: 7.0, trailing: 0.0))
    }
}

struct PlaylistMoveFolderView: View {
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(
        entity: PlaylistFolder.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \PlaylistFolder.order, ascending: true),
            NSSortDescriptor(keyPath: \PlaylistFolder.dateAdded, ascending: false)
        ],
        predicate: NSPredicate(format: "uuid != %@", PlaylistFolder.savedFolderUUID)
    ) var folders: FetchedResults<PlaylistFolder>
    
    @FetchRequest(
        entity: PlaylistFolder.entity(),
        sortDescriptors: [],
        predicate: NSPredicate(format: "uuid == %@", PlaylistFolder.savedFolderUUID)
    ) var savedFolder: FetchedResults<PlaylistFolder>
    
    @State private var moveDisabled: Bool = true
    @State private var selectedFolder = PlaylistManager.shared.currentFolder
    var selectedItems: [PlaylistItem]
    
    var onCancelButtonPressed: (() -> Void)?
    var onDoneButtonPressed: (([PlaylistItem], PlaylistFolder?) -> Void)?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        if selectedItems.count > 1,
                           let firstItem = selectedItems[safe: 0],
                           let secondItem = selectedItems[safe: 1] {
                            ZStack {
                                PlaylistFolderImage(item: firstItem)
                                    .rotationEffect(.degrees(5.0))
                                PlaylistFolderImage(item: secondItem).rotationEffect(.degrees(-5.0))
                            }
                            
                            Text("\(firstItem.name ?? "") & \(selectedItems.count - 1) item(s)")
                                .font(.body)
                                .foregroundColor(.white)
                        } else if let item = selectedItems.first {
                            PlaylistFolderImage(item: item)
                            Text(item.name ?? "")
                                .font(.body)
                                .foregroundColor(.white)
                        }
                    }
                }
                .listRowBackground(Color.clear)
                
                Section(header: Text("Current Folder")
                            .font(.footnote)
                            .foregroundColor(Color(.secondaryBraveLabel))
                            .multilineTextAlignment(.leading)) {
                    
                    Button(action: {
                        selectedFolder = PlaylistManager.shared.currentFolder
                        moveDisabled = true
                    }) {
                        PlaylistFolderView(iconColor: .gray,
                                           titleColor: .gray,
                                           folder: PlaylistManager.shared.currentFolder,
                                           selectedFolder: $selectedFolder)
                    }
                }
                .listRowBackground(Color(.secondaryBraveGroupedBackground))
                
                Section(header: Text("Select a folder to move \(selectedItems.count) item to")
                            .font(.footnote)
                            .foregroundColor(Color(.secondaryBraveLabel))
                            .multilineTextAlignment(.leading)) {
                    
                    // Show the "Saved" folder
                    if PlaylistManager.shared.currentFolder?.uuid != savedFolder.first?.uuid {
                        Button(action: {
                            selectedFolder = savedFolder.first
                            moveDisabled = false
                        }) {
                            PlaylistFolderView(iconColor: Color(.braveOrange),
                                               titleColor: .white,
                                               folder: savedFolder.first,
                                               selectedFolder: $selectedFolder)
                        }
                    }
                    
                    // Show all folders except the current one
                    ForEach((0..<folders.count), id: \.self) { index in
                        if folders[index].uuid != PlaylistManager.shared.currentFolder?.uuid {
                            Button(action: {
                                selectedFolder = folders[index]
                                moveDisabled = false
                            }) {
                                PlaylistFolderView(iconColor: Color(.braveOrange),
                                                   titleColor: .white,
                                                   folder: folders[index],
                                                   selectedFolder: $selectedFolder)
                            }
                        }
                    }
                }
                .listRowBackground(Color(.secondaryBraveGroupedBackground))
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Move")
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(.stack)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancelButtonPressed?() }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onDoneButtonPressed?(selectedItems, selectedFolder) }
                    .foregroundColor(moveDisabled ? .gray : .white)
                    .disabled(moveDisabled)
                }
            }
        }
        .background(Color(.braveBackground))
        .environment(\.colorScheme, .dark)
    }
}

//swiftlint:disable:next swiftui_previews_guard
struct PlaylistMoveFolderView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistMoveFolderView(selectedItems: [])
            .environment(\.managedObjectContext, DataController.swiftUIContext)
    }
}
