// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Data
import CoreData

struct PlaylistEditFolderView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    @State private var folderName: String = ""
    @State var currentFolder: NSManagedObjectID
    var currentFolderTitle: String
    
    var onCancelButtonPressed: (() -> Void)?
    var onEditFolder: ((_ folderTitle: String, _ currentFolder: NSManagedObjectID) -> Void)?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField(currentFolderTitle, text: $folderName)
                        .disableAutocorrection(true)
                        .padding()
                }
                .listRowBackground(Color(.secondaryBraveGroupedBackground))
                .listRowInsets(.zero)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Edit Folder")
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(.stack)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancelButtonPressed?() }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { onEditFolder?(folderName, currentFolder) }
                    .foregroundColor(.white)
                    .disabled(currentFolderTitle == folderName)
                }
            }
        }
        .background(Color(.braveBackground))
        .environment(\.colorScheme, .dark)
    }
}

#if DEBUG
struct PlaylistEditFolderView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistEditFolderView()
    }
}
#endif
