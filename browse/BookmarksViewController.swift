//
//  BookmarksViewController.swift
//  browse
//
//  Created by Evan Brooks on 5/17/17.
//  Copyright © 2017 Evan Brooks. All rights reserved.
//

import Foundation
import UIKit

class BookmarksViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let bookmarks : Array<String> = [
        "apple.com",
        "figma.com",
        "hoverstat.es",
        "medium.com",
        "greenapplebooks.com",
        "amazon.com",
        "fonts.google.com",
        "flights.google.com",
        "maps.google.com",
        "plus.google.com",
        "wikipedia.org",
        "theverge.com",
        "framer.com",
        "nytimes.com",
        "bloomberg.com",
        "theoutline.com",
        "corndog.love",
    ]
    
    var homeVC : HomeViewController!
    
    private var table: UITableView!

    override func loadView() {
        super.loadView()
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Bookmarks"
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barStyle = .blackTranslucent
//        navigationController?.navigationBar.isTranslucent = false
//        navigationController?.navigationBar.barTintColor = .clear
        
        
        
        table = UITableView(frame:self.view.frame)
//        table.contentInset = .init(top: 0, left: 0, bottom: 200, right: 0) // TODO: why?
        self.automaticallyAdjustsScrollViewInsets = true

        table.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
        table.dataSource = self
        table.delegate = self
        self.view.addSubview(table)
        
        view.backgroundColor = .black
        table.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        table.separatorColor = UIColor.white.withAlphaComponent(0.1)

        
//        navigationController?.isToolbarHidden = false
        let toolbar = navigationController?.toolbar
//        toolbar?.isTranslucent = false
        toolbar?.barTintColor = .black
        toolbar?.tintColor = .white

        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let negSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))
        let tabButton = UIBarButtonItem(image: UIImage(named: "tab-filled"), style: .plain, target: self, action: #selector(dismissSelf))
        negSpace.width = -16.0
        tabButton.width = 48.0

        toolbarItems = [flex, done]
//        toolbarItems = [flex, tabButton, negSpace]


    }
    
    
    override func viewWillAppear(_ animated: Bool) {
//        table.setContentOffset(table.contentInset  , animated: false)
        table.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func dismissSelf() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if homeVC != nil {
//            dismissSelf()
            navigationController?.popToRootViewController(animated: true)
            table.deselectRow(at: indexPath, animated: true)
            homeVC.tab.navigateToText(bookmarks[indexPath.row])
            homeVC.showTab()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let remove = UITableViewRowAction(style: .destructive, title: "Remove", handler: { (action, indexPath) in
            print("Remove \(indexPath.row)")
        })
        return [remove]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath as IndexPath)
        for subview in cell.contentView.subviews { subview.removeFromSuperview() }

        cell.textLabel!.text = "\(bookmarks[indexPath.row])"
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .clear
        
        let bv = UIView()
        bv.backgroundColor = UIColor(white: 0.2, alpha: 1)
        cell.selectedBackgroundView = bv
        
        return cell
    }

}
