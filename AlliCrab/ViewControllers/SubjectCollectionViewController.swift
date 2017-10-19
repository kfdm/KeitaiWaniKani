//
//  SubjectCollectionViewController.swift
//  AlliCrab
//
//  Copyright © 2017 Chris Laverty. All rights reserved.
//

import os
import UIKit
import WaniKaniKit

class SubjectCollectionViewController: UICollectionViewController {
    
    private enum ReuseIdentifier: String {
        case subject = "Subject"
    }
    
    // MARK: - Properties
    
    var repositoryReader: ResourceRepositoryReader? {
        didSet {
            updateUI()
        }
    }
    
    var srsStage: SRSStage? {
        didSet {
            guard let srsStage = srsStage else {
                return
            }
            
            navigationItem.title = String(describing: srsStage)
            updateUI()
        }
    }
    
    private var assignments = [Assignment]()
    private var subjectsBySubjectID = [Int: Subject]()
    private var notificationObservers: [NSObjectProtocol]?
    
    // MARK: - Initialisers
    
    deinit {
        if let notificationObservers = notificationObservers {
            if #available(iOS 10.0, *) {
                os_log("Removing NotificationCenter observers from %@", type: .debug, String(describing: type(of: self)))
            }
            notificationObservers.forEach(NotificationCenter.default.removeObserver(_:))
        }
        notificationObservers = nil
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assignments.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ReuseIdentifier.subject.rawValue, for: indexPath) as! SubjectCollectionViewCell
        configure(cell, at: indexPath)
        
        return cell
    }
    
    private func configure(_ cell: SubjectCollectionViewCell, at indexPath: IndexPath) {
        let assignment = assignments[indexPath.row]
        
        let subject: Subject
        if let s = subjectsBySubjectID[assignment.subjectID] {
            subject = s
        } else {
            subject = try! repositoryReader!.loadResource(id: assignment.subjectID).data as! Subject
            subjectsBySubjectID[assignment.subjectID] = subject
        }
        cell.subject = subject
    }
    
    // MARK: - UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! SubjectCollectionViewCell
        self.present(WebViewController.wrapped(url: cell.documentURL), animated: true, completion: nil)
    }
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let flowLayout = collectionView!.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.estimatedItemSize = flowLayout.itemSize
        
        notificationObservers = addNotificationObservers()
        
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            collectionView!.backgroundView = BlurredImageView(frame: collectionView!.frame, imageNamed: "Art03", style: .extraLight)
        }
    }
    
    // MARK: - Update UI
    
    private func addNotificationObservers() -> [NSObjectProtocol] {
        if #available(iOS 10.0, *) {
            os_log("Adding NotificationCenter observers to %@", type: .debug, String(describing: type(of: self)))
        }
        let notificationObservers = [
            NotificationCenter.default.addObserver(forName: .waniKaniUserInformationDidChange, object: nil, queue: .main) { [unowned self] _ in
                self.updateUI()
            },
            NotificationCenter.default.addObserver(forName: .waniKaniAssignmentsDidChange, object: nil, queue: .main) { [unowned self] _ in
                self.updateUI()
            },
            NotificationCenter.default.addObserver(forName: .waniKaniSubjectsDidChange, object: nil, queue: .main) { [unowned self] _ in
                self.subjectsBySubjectID = [Int: Subject]()
                self.updateUI()
            }
        ]
        
        return notificationObservers
    }
    
    private func updateUI() {
        guard let repositoryReader = repositoryReader, let srsStage = srsStage else {
            return
        }
        
        if #available(iOS 10.0, *) {
            os_log("Updating subject list for SRS stage %@", type: .info, String(describing: srsStage))
        }
        
        assignments = try! repositoryReader.assignments(srsStage: srsStage).sorted(by: Assignment.Sorting.byProgress)
        subjectsBySubjectID.reserveCapacity(assignments.count)
    }
    
}
