//
//  ViewController.swift
//  WPFRefresh
//
//  Created by wpf on 2016/12/30.
//  Copyright © 2016年 wpf. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let tableView: UITableView = UITableView(frame: .zero, style: .plain)
    var dataSource: [String] = ["111","222","333"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.edgesForExtendedLayout = UIRectEdge()
        
        self.tableView.dataSource = self
        self.tableView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height-64)
        self.view.addSubview(self.tableView)
        
        self.tableView.header = LCTRefreshHeader.header { [weak self] in
            self?.addData()
        }
        
    }
    
    func addData() {
        
        
        

        let random: UInt32 = arc4random()%10
        for i in 0..<random {
            self.dataSource += ["\(i)\(i)\(i)"]
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) { [weak self] in
            print("count --------- \(self?.dataSource.count)")
            self?.tableView.reloadData()
            self?.tableView.header?.endRefreshing()
        }

        
    }
    
    

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "vccell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
        }
        cell?.textLabel?.text = "\(indexPath.row) --- \(self.dataSource[indexPath.row])"
        print(cell?.textLabel?.text ?? "")
        return cell!
    }

    
}

