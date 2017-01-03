//
//  LCTRefresh.swift
//  WPFRefresh
//
//  Created by wpf on 2016/12/31.
//  Copyright © 2016年 wpf. All rights reserved.
//

import UIKit
import ObjectiveC


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
    
    var pan: UIPanGestureRecognizer?
    
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
    fileprivate var privateState: LCTRefreshState?
    
    fileprivate var privatePullingPercent: Float?
    
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
        get { return self.privateState! }
        set {
            self.privateState = newValue
            DispatchQueue.main.async {
                self.setNeedsLayout()
            }
        }
    }
    
    /// 刷新比例 "计算属性"
    fileprivate var pullingPercent: Float {
        get { return self.privatePullingPercent! }
        set {
            self.privatePullingPercent = newValue
        }
    }
    
    
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
            self.scrollViewContentSizeDidChange(change)
        }
        
        // 隐藏情况
        guard self.isHidden == false else {
            return
        }
        if keyPath == LCTRefreshConst.kKeyPathContentOffset {
            self.scrollViewContentOffsetDidChange(change)
        } else if keyPath == LCTRefreshConst.kKeyPathPanState {
            self.scrollViewPanStateDidChange(change)
        }
        
    }
    
    fileprivate func scrollViewContentOffsetDidChange(_ change: [NSKeyValueChangeKey : Any]?) {}
    fileprivate func scrollViewContentSizeDidChange(_ change: [NSKeyValueChangeKey : Any]?) {}
    fileprivate func scrollViewPanStateDidChange(_ change: [NSKeyValueChangeKey : Any]?) {}
    

    /// 开始刷新
    func beginRefreshing(completion: ((Swift.Void) -> Swift.Void)? = nil) {
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
    func endRefreshing(completion: ((Swift.Void) -> Swift.Void)? = nil) {
        self.endRefreshingCompletionBlock = completion
        self.state = .idle
    }
    
    func isRefreshing() -> Bool {
        return (self.state == .refreshing || self.state == .willrefresh)
    }
    
    /// 子类 执行刷新回调
    fileprivate func executeRefreshingBlock() {
        DispatchQueue.main.async {
            if let block = self.refreshingBlock {
                block()
            }
            
            if let block = self.beginRefreshingCompletionBlock {
                block()
            }
        }
    }

}



class LCTRefreshHeader: LCTRefresh {
    
    var ignoredScrollViewContentInsetTop: CGFloat = 0.0
    var insetTDeldta: CGFloat = 0.0
    
    static func header(block refreshingBlock: @escaping LCTRefreshRefreshingBlock) -> LCTRefreshHeader {
        let header = LCTRefreshHeader()
        header.refreshingBlock = refreshingBlock
        return header
    }
    
    override func prepare() {
        super.prepare()
        
        self.wpf_h = CGFloat(LCTRefreshConst.kHeaderHeight)
    }
    
    override func placeSubviews() {
        super.placeSubviews()
        
        self.wpf_y = -self.wpf_h - self.ignoredScrollViewContentInsetTop
    }
    
    fileprivate override func scrollViewContentOffsetDidChange(_ change: [NSKeyValueChangeKey : Any]?) {
        super.scrollViewContentOffsetDidChange(change)
        
        if self.state == .refreshing {
            guard self.window != nil else {
                return
            }
            
            // sectionheader停留解决
            guard let scroll = self.scrollView , let origin = self.originalInset else {
                return
            }
            var insetT: CGFloat = -scroll.wpf_offsetY > origin.top ? -scroll.wpf_offsetY : origin.top
            insetT = insetT > self.wpf_h + origin.top ? self.wpf_h + origin.top : insetT
            scroll.wpf_insetT = insetT
            self.insetTDeldta = origin.top - insetT
            return
        }
        
        // 跳转到下一个控制器时，contentInset可能会变
        self.originalInset = self.scrollView?.contentInset
        // 当前的contentOffset
        let offsetY: CGFloat = self.scrollView?.wpf_offsetY ?? 0.0
        // 头部控件刚好出现的offsetY
        let happenOffsetY: CGFloat = -(self.originalInset?.top)!
        // 如果是向上滚动到看不见头部控件，直接返回
        if offsetY > happenOffsetY {
            return
        }
        
        // 普通 和 即将刷新 的临界点
        let normal2pullingOffsetY: CGFloat = happenOffsetY - self.wpf_h
        let pullingPercent: Float = Float((happenOffsetY - offsetY) / self.wpf_h)
        
        
        if self.scrollView?.isDragging ?? false { // 正在拖拽 解包默认false
            self.pullingPercent = pullingPercent
            if self.state == .idle && offsetY < normal2pullingOffsetY {
                self.state = .pulling
            } else if self.state == .pulling && offsetY > normal2pullingOffsetY {
                self.state = .idle
            }
        } else if self.state == .pulling { // 即将刷新 && 手松开
            self.beginRefreshing()
        } else if pullingPercent < 1 {
            self.pullingPercent = pullingPercent
        }
        
    }
    
    
    override var state: LCTRefreshState {
        get { return self.privateState! }
        set {
            
            let oldState = self.privateState
            guard oldState != newValue else {
                return
            }
            super.state = newValue

            if newValue == .idle {
                guard oldState == .refreshing else {
                    return
                }
                
                UIView.animate(withDuration: LCTRefreshConst.kAnimationDuration, animations: { 
                    self.scrollView?.wpf_insetT += self.insetTDeldta
                }, completion: { (_) in
                    self.pullingPercent = 0.0
                    if let block = self.endRefreshingCompletionBlock {
                        block()
                    }
                })
            } else if newValue == .refreshing {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: LCTRefreshConst.kAnimationDuration, animations: { 
                        let top: CGFloat = ((self.originalInset?.top)!  + self.wpf_h)
                        self.scrollView?.wpf_insetT = top
                        self.scrollView?.contentOffset = CGPoint(x: 0, y: -top)
                    }, completion: { (_) in
                        self.executeRefreshingBlock()
                    })
                }
            }
        }
    }
    
    
    override func endRefreshing(completion: ((Swift.Void) -> Swift.Void)? = nil) {
        self.endRefreshingCompletionBlock = completion
        DispatchQueue.main.async {
            self.state = .idle
        }
    }
    
}

class LCTRefreshFooter: LCTRefresh {
    
    var ignoredScrollViewContentInsetTop: CGFloat = 0.0
    
    var automaticallyRefresh: Bool = true
    var isAutomaticallyRefresh: Bool {
        get {
            return self.automaticallyRefresh
        }
    }
    
    var triggerAutomaticallyRefreshPercent: CGFloat = 1.0
    
    static func footer(block refreshingBlock: @escaping LCTRefreshRefreshingBlock) -> LCTRefreshFooter {
        let footer = LCTRefreshFooter()
        footer.refreshingBlock = refreshingBlock
        return footer
    }
    
    override func prepare() {
        super.prepare()
        
        self.wpf_h = CGFloat(LCTRefreshConst.kFooterHeight)
    }
    
    func endRefreshingWithNoMoreData() {
        self.state = .nomoredata
    }
    
    func resetNoMoreData() {
        self.state = .idle
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if newSuperview != nil {
            if self.isHidden == false {
                self.scrollView?.wpf_insetB += self.wpf_h
            }
            self.wpf_y = self.scrollView?.wpf_sizeH ?? 0.0
        } else {
            if self.isHidden == false {
                self.scrollView?.wpf_insetB -= self.wpf_h
            }
        }
    }
    
    fileprivate override func scrollViewContentSizeDidChange(_ change: [NSKeyValueChangeKey : Any]?) {
        super.scrollViewContentSizeDidChange(change)
        
        self.wpf_y = self.scrollView?.wpf_sizeH ?? 0.0
    }
    fileprivate override func scrollViewContentOffsetDidChange(_ change: [NSKeyValueChangeKey : Any]?) {
        super.scrollViewContentOffsetDidChange(change)
        guard self.state == .idle, self.automaticallyRefresh == true, self.wpf_y != 0, let scroll = self.scrollView else {
            return
        }
        
        if scroll.wpf_insetT + scroll.wpf_sizeH > scroll.wpf_h {
            
            if scroll.wpf_offsetY >= scroll.wpf_sizeH - scroll.wpf_h + self.wpf_h*self.triggerAutomaticallyRefreshPercent + scroll.wpf_insetB - self.wpf_h {
                // 防止松手连续调用
                let old = (change?[.oldKey] as? NSValue)?.cgPointValue ?? CGPoint(x: 0, y: 0)
                let new = (change?[.newKey] as? NSValue)?.cgPointValue ?? CGPoint(x: 0, y: 0)
                
                guard new.y > old.y  else {
                    return
                }
                self.beginRefreshing()
            }
        }
    }
    fileprivate override func scrollViewPanStateDidChange(_ change: [NSKeyValueChangeKey : Any]?) {
        super.scrollViewPanStateDidChange(change)
        
        guard self.state == .idle, let scroll = self.scrollView else {
            return
        }
        
        if scroll.panGestureRecognizer.state == .ended {
            if scroll.wpf_insetT + scroll.wpf_sizeH <= scroll.wpf_h {
                if scroll.wpf_offsetY >= -scroll.wpf_insetT {
                    self.beginRefreshing()
                }
            } else {
                if scroll.wpf_offsetY >= scroll.wpf_sizeH + scroll.wpf_insetB - scroll.wpf_h {
                    self.beginRefreshing()
                }
            }
        }
        
    }
    
    override var state: LCTRefreshState {
        get { return self.privateState! }
        set {
            let oldState = self.privateState
            guard oldState != newValue else {
                return
            }
            super.state = newValue
            if newValue == .refreshing {
                DispatchQueue.main.asyncAfter(deadline: .init(uptimeNanoseconds: 1), execute: {
                    self.executeRefreshingBlock()
                })
            } else if newValue == .nomoredata || newValue == .idle {
                if oldState == .refreshing {
                    if let block = self.endRefreshingCompletionBlock {
                        block()
                    }
                }
            }
        }
    }
    
    override var isHidden: Bool {
        get {
            return super.isHidden
        }
        set {
            let last: Bool = super.isHidden
            super.isHidden = newValue
            if last == false && newValue == true {
                self.state = .idle
                self.scrollView?.wpf_insetB -= self.wpf_h
            } else if last == true && newValue == false {
                self.scrollView?.wpf_insetB += self.wpf_h

                self.wpf_y = self.scrollView?.wpf_sizeH ?? 0
            }
        }
    }
    
    
    
    
}











//MARK: - Implement Extension
extension UIScrollView {
    
    private struct AssociatedKey {
        static var header: UInt8 = 0
        static var footer: UInt8 = 0
        static let keyHeader: String = "header"
        static let keyFooter: String = "footer"
    }
    
    var header: LCTRefreshHeader? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.header) as? LCTRefreshHeader
        }
        set {
            
            if newValue != self.header {
                self.header?.removeFromSuperview()
                self.insertSubview(newValue!, at: 0)
                
                self.willChangeValue(forKey: AssociatedKey.keyHeader)
                objc_setAssociatedObject(self, &AssociatedKey.header, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                self.didChangeValue(forKey: AssociatedKey.keyHeader)
            }
            
        }
    }
    
    var footer: LCTRefreshFooter? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.footer) as? LCTRefreshFooter
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKey.footer, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    
}


//MARK: - Helper Extension
extension UIView {
    public var wpf_x: CGFloat {
        get { return self.frame.origin.x }
        set {
            var frame: CGRect = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
    }
    
    public var wpf_y: CGFloat {
        get { return self.frame.origin.y }
        set {
            var frame: CGRect = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
    }
    
    public var wpf_origin: CGPoint {
        get { return self.frame.origin }
        set {
            var frame: CGRect = self.frame
            frame.origin = newValue
            self.frame = frame
        }
    }
    
    public var wpf_w: CGFloat {
        get { return self.frame.size.width }
        set {
            var frame: CGRect = self.frame
            frame.size.width = newValue
            self.frame = frame
        }
    }
    
    public var wpf_h: CGFloat {
        get { return self.frame.size.height }
        set {
            var frame: CGRect = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
    }
    
    public var wpf_size: CGSize {
        get { return self.frame.size }
        set {
            var frame: CGRect = self.frame
            frame.size = newValue
            self.frame = frame
        }
    }
}

extension UIScrollView {
    public var wpf_insetT: CGFloat {
        get { return self.contentInset.top }
        set {
            var inset: UIEdgeInsets = self.contentInset
            inset.top = newValue
            self.contentInset = inset
        }
    }
    
    public var wpf_insetB: CGFloat {
        get { return self.contentInset.bottom }
        set {
            var inset: UIEdgeInsets = self.contentInset
            inset.bottom = newValue
            self.contentInset = inset
        }
    }
    public var wpf_insetL: CGFloat {
        get { return self.contentInset.left }
        set {
            var inset: UIEdgeInsets = self.contentInset
            inset.left = newValue
            self.contentInset = inset
        }
    }

    public var wpf_insetR: CGFloat {
        get { return self.contentInset.right }
        set {
            var inset: UIEdgeInsets = self.contentInset
            inset.right = newValue
            self.contentInset = inset
        }
    }

    public var wpf_offsetX: CGFloat {
        get { return self.contentOffset.x }
        set {
            var offset: CGPoint = self.contentOffset
            offset.x = newValue
            self.contentOffset = offset
        }
    }
    
    public var wpf_offsetY: CGFloat {
        get { return self.contentOffset.y }
        set {
            var offset: CGPoint = self.contentOffset
            offset.y = newValue
            self.contentOffset = offset
        }
    }

    public var wpf_sizeW: CGFloat {
        get { return self.contentSize.width }
        set {
            var size: CGSize = self.contentSize
            size.width = newValue
            self.contentSize = size
        }
    }
    
    public var wpf_sizeH: CGFloat {
        get { return self.contentSize.height }
        set {
            var size: CGSize = self.contentSize
            size.height = newValue
            self.contentSize = size
        }
    }
}











