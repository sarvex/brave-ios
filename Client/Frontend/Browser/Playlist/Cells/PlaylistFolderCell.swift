// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import BraveUI

class PlaylistFolderCell: UITableViewCell, TableViewReusable {
    private let iconView = UIImageView().then {
        $0.image = UIImage(systemName: "folder")?.withRenderingMode(.alwaysTemplate)
        $0.tintColor = .braveOrange
        $0.contentMode = .scaleAspectFit
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    let titleLabel = UILabel().then {
        $0.textColor = .white
        
        let metrics = UIFontMetrics(forTextStyle: .body)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .regular)
        $0.font = metrics.scaledFont(for: font)
        $0.adjustsFontForContentSizeCategory = true
    }
    
    let subtitleLabel = UILabel().then {
        $0.textColor = .white
        
        let metrics = UIFontMetrics(forTextStyle: .footnote)
        let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .footnote)
        let font = UIFont.systemFont(ofSize: desc.pointSize, weight: .regular)
        $0.font = metrics.scaledFont(for: font)
        $0.adjustsFontForContentSizeCategory = true
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        accessoryType = .disclosureIndicator
        
        let vStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel]).then {
            $0.axis = .vertical
        }
        
        let hStack = UIStackView(arrangedSubviews: [iconView, vStack]).then {
            $0.spacing = 18.0
            $0.layoutMargins = UIEdgeInsets(top: 7.0, left: 24.0, bottom: 7.0, right: 24.0)
            $0.isLayoutMarginsRelativeArrangement = true
        }
        
        contentView.addSubview(hStack)
        hStack.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
