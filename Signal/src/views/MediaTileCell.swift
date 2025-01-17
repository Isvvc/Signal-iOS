//
// Copyright 2023 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

protocol MediaTileCell: AnyObject {
    func makePlaceholder()
    func configure(item: PhotoGridItem)
    var item: PhotoGridItem? { get set }
    var allowsMultipleSelection: Bool { get }
    func setAllowsMultipleSelection(_ allowed: Bool, animated: Bool)
    func mediaPresentationContext(
        collectionView: UICollectionView,
        in coordinateSpace: UICoordinateSpace) -> MediaPresentationContext?
    func indexPathDidChange(_ indexPath: IndexPath, itemCount: Int)
}
