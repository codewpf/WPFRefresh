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
    var dataSource: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.edgesForExtendedLayout = UIRectEdge()
        
        self.tableView.dataSource = self
        self.tableView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height-64)
        self.tableView.tableFooterView = UIView()
        self.view.addSubview(self.tableView)
        
        self.tableView.header = LCTRefreshHeader.header { [weak self] in
            self?.datas(true)
        }
        
        self.tableView.footer = LCTRefreshFooter.footer { [weak self] in
            self?.datas(false)
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) { 
            self.datas(true)
        }
        
    }
    
    var count = 0
    
    func datas(_ remove: Bool) {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) { [weak self] in
            
            if remove {
                self?.dataSource.removeAll()
            }
            
            let random: UInt32 = arc4random()%10+10
            for i in 0..<random {
                self?.dataSource += ["\(i)\(i)\(i)"]
            }

            self?.tableView.reloadData()
            if remove {
                self?.count = 0
                self?.tableView.header?.endRefreshing()
            } else {
                self?.count += 1
                self?.tableView.footer?.endRefreshing()
                if self?.count == 2{
                    self?.tableView.removeFooter()
                }
            }
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
        print(indexPath.row,self.dataSource.count)
        cell?.textLabel?.text = "\(indexPath.row) --- \(self.dataSource[indexPath.row])"
        return cell!
    }

    
}

