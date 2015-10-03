//
//  SRSDataItemCollectionViewController.swift
//  KeitaiWaniKani
//
//  Copyright © 2015 Chris Laverty. All rights reserved.
//

import UIKit
import WaniKaniKit

private let headerReuseIdentifier = "Header"
private let radicalReuseIdentifier = "RadicalDataItemCell"
private let kanjiReuseIdentifier = "KanjiDataItemCell"

private struct ClassifiedSRSDataItems {
    struct Section {
        let title: String
        let items: [SRSDataItem]
    }
    
    let sections: [Section]
    
    init(items: [SRSDataItem]) {
        let items = items.sort { $0.userSpecificSRSData?.srsLevelNumeric < $1.userSpecificSRSData?.srsLevelNumeric }
        var sections: [Section] = []
        sections.reserveCapacity(2)
        
        let pending = items.filter(self.dynamicType.isPending)
        if !pending.isEmpty {
            sections.append(Section(title: "Remaining to Level", items: pending))
        }
        
        let complete = items.filter(self.dynamicType.isComplete)
        if !complete.isEmpty {
            sections.append(Section(title: "Complete", items: complete))
        }
        
        self.sections = sections
    }
    
    private static func isPending(item: SRSDataItem) -> Bool {
        guard let srsLevel = item.userSpecificSRSData?.srsLevelNumeric else { return true }
        return srsLevel < SRSLevel.Guru.numericLevelThreshold
    }
    
    private static func isComplete(item: SRSDataItem) -> Bool {
        guard let srsLevel = item.userSpecificSRSData?.srsLevelNumeric else { return false }
        return srsLevel >= SRSLevel.Guru.numericLevelThreshold
    }
}

class SRSDataItemCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Properties
    
    private var classifiedItems: ClassifiedSRSDataItems?
    func setSRSDataItems(items: [SRSDataItem], withTitle title: String) {
        classifiedItems = ClassifiedSRSDataItems(items: items)
        navigationItem.title = title
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        guard let classifiedItems = classifiedItems else { return 0 }
        return classifiedItems.sections.count
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let classifiedItems = classifiedItems else { return 0 }
        
        return classifiedItems.sections[section].items.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if let classifiedItems = classifiedItems {
            let item = classifiedItems.sections[indexPath.section].items[indexPath.row]
            
            switch item {
            case let radical as Radical:
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(radicalReuseIdentifier, forIndexPath: indexPath) as! RadicalGuruProgressCollectionViewCell
                cell.radical = radical
                return cell
            case let kanji as Kanji:
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(kanjiReuseIdentifier, forIndexPath: indexPath) as! KanjiGuruProgressCollectionViewCell
                cell.kanji = kanji
                return cell
            default: fatalError("Only Radicals and Kanji are supported by \(self.dynamicType)")
            }
        } else {
            fatalError("Neither kanji or radicals set, yet it tried to dequeue a cell")
        }
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: headerReuseIdentifier, forIndexPath: indexPath) as! SRSItemHeaderCollectionReusableView
        
        if kind == UICollectionElementKindSectionHeader {
            let section = classifiedItems?.sections[indexPath.section]
            view.headerLabel.text = section?.title
        } else {
            view.headerLabel.text = nil
        }
        
        return view
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    }
    
}
