//
//  LCTRefresh.swift
//  WPFRefresh
//
//  Created by wpf on 2016/12/31.
//  Copyright © 2016年 wpf. All rights reserved.
//

import UIKit
/// 刷新状态
enum LCTRefreshState {
    /// "普通闲置" 状态
    case idle
    /// "松开就刷新" 状态
    case pulling
    /// "正在刷新" 状态
    case refreshing
    /// "即将刷新" 状态
    case willrefresh
    /// "全部数据完毕，没有更多数据" 状态
    case nomoredata
}

/// 常量定义
struct LCTRefreshConst {
    /// KVO-ContentOffset
    static let kKeyPathContentOffset = "contentOffset"
    /// KVO-ContentSize
    static let kKeyPathContentSize = "contentSize"
    /// KVO-PanState
    static let kKeyPathPanState = "state"
    
    /// HeaderHeight
    static let kHeaderHeight = 54
    /// FooterHeight
    static let kFooterHeight = 44
    
    /// Duration
    static let kAnimationDuration = 0.25
}

/// "进入刷新" 回调
typealias LCTRefreshRefreshingBlock = () -> Void
/// "开始刷新后" 回调
typealias LCTRefreshBeginRefreshCompletionBlock = () -> Void
/// "完成刷新后" 回调
typealias LCTRefreshEndRefreshCompletionBlock = () -> Void



class LCTRefresh: UIView {
    
    fileprivate var pan: UIPanGestureRecognizer?
    
    /// 父控件
    var scrollView: UIScrollView?
    /// 记录scrollView刚开始的inset
    var originalInset: UIEdgeInsets?
    
    /// 正在刷新 的回调
    var refreshingBlock: LCTRefreshRefreshingBlock?
    /// 开始刷新后 的回调
    var beginRefreshingCompletionBlock: LCTRefreshBeginRefreshCompletionBlock?
    /// 刷新完成后 的回调
    var endRefreshingCompletionBlock: LCTRefreshEndRefreshCompletionBlock?
    
    /// 当前状态
    private var privateState: LCTRefreshState?
    
    private var privatePullingPercent: Float?
    
    //MARK: - 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.prepare()
        
        self.privateState = .idle
        self.privatePullingPercent = 0.0
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepare() {
        self.autoresizingMask = [.flexibleWidth]
        self.backgroundColor = UIColor.clear
    }
    
    override func layoutSubviews() {
        
        self.placeSubviews()
        
        super.layoutSubviews()
    }
    
    func placeSubviews() {
        
    }
    
    /// 当前state "计算属性"
    fileprivate var state: LCTRefreshState {
        get {
            return self.privateState!
        }
        set {
            self.privateState = newValue
            DispatchQueue.main.async {
                self.setNeedsLayout()
            }
        }
    }

    /// 刷新比例 "计算属性"
    fileprivate var pullingPercent: Float {
        get {
            return self.privatePullingPercent!
        }
        set {
            self.privatePullingPercent = newValue
        }
    }
    
    
}

extension LCTRefresh {
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard newSuperview is UIScrollView else {
            return
        }
        self.removeObservers()
        
        self.scrollView = newSuperview as? UIScrollView
        self.scrollView?.alwaysBounceVertical = true
        self.originalInset = self.scrollView?.contentInset
        self.addObservers()
    }
    
    //MARK: - 监听
    private func addObservers() {
        self.scrollView?.addObserver(self, forKeyPath: LCTRefreshConst.kKeyPathContentOffset, options: [.old, .new], context: nil)
        self.scrollView?.addObserver(self, forKeyPath: LCTRefreshConst.kKeyPathContentSize, options: [.old, .new], context: nil)
        self.pan = self.scrollView?.panGestureRecognizer
        self.pan?.addObserver(self, forKeyPath: LCTRefreshConst.kKeyPathPanState, options: [.old, .new], context: nil)
    }
    
    private func removeObservers() {
        self.superview?.removeObserver(self, forKeyPath: LCTRefreshConst.kKeyPathContentOffset, context: nil)
        self.superview?.removeObserver(self, forKeyPath: LCTRefreshConst.kKeyPathContentSize, context: nil)
        self.pan?.removeObserver(self, forKeyPath: LCTRefreshConst.kKeyPathPanState, context: nil)
        self.pan = nil
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // 遇到此种情况返回
        guard self.isUserInteractionEnabled else {
            return
        }
        
        // 隐藏状态下也要处理
        if keyPath == LCTRefreshConst.kKeyPathContentSize {
            self.scrollViewContentSizeDidChange()
        }
        
        // 隐藏情况
        guard self.isHidden == false else {
            return
        }
        if keyPath == LCTRefreshConst.kKeyPathContentOffset {
            self.scrollViewContentOffsetDidChange()
        } else if keyPath == LCTRefreshConst.kKeyPathPanState {
            self.scrollViewPanStateDidChange()
        }
        
    }
    
    fileprivate func scrollViewContentOffsetDidChange() {}
    fileprivate func scrollViewContentSizeDidChange() {}
    fileprivate func scrollViewPanStateDidChange() {}

}


extension LCTRefresh {

    /// 开始刷新
    fileprivate func beginRefreshing(completion: ((Swift.Void) -> Swift.Void)? = nil) {
        self.beginRefreshingCompletionBlock = completion
        
        UIView.animate(withDuration: LCTRefreshConst.kAnimationDuration) {
            self.alpha = 1.0
        }
        
        self.pullingPercent = 1.0
        
        if self.window != nil {
            self.state = .refreshing
        } else {
            if self.state != .refreshing {
                self.state = .refreshing
                self.setNeedsDisplay()
            }
        }
    }
    
    /// 结束刷新
    fileprivate func endRefreshing(completion: ((Swift.Void) -> Swift.Void)? = nil) {
        self.endRefreshingCompletionBlock = completion
        self.state = .idle
    }
    
    func isRefreshing() -> Bool {
        return (self.state == .refreshing || self.state == .willrefresh)
    }
    
    /// 子类 执行刷新回调
    private func executeRefreshingBlock() {
        DispatchQueue.main.async {
            if self.refreshingBlock != nil {
                self.refreshingBlock!()
            }
            
            if self.beginRefreshingCompletionBlock != nil {
                self.beginRefreshingCompletionBlock!()
            }
        }
    }

}



class LCTRefreshHeader: LCTRefresh {
    
}

class LCTRefreshFooter: LCTRefresh {
    
}






