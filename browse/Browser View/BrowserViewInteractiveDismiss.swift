//
//  BrowserViewInteractiveDismiss.swift
//  browse
//
//  Created by Evan Brooks on 6/20/17.
//  Copyright © 2017 Evan Brooks. All rights reserved.
//

import UIKit
import WebKit

enum WebViewInteractiveDismissDirection {
    case top
    case bottom
    case left
    case right
}

// NOTE: There seems to be a problem when webview.scrollview doesn't exist
// that silently logs in xcode, but doesn't seem to break anything.
// Only shows up on blank pages.

class BrowserViewInteractiveDismiss : NSObject, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    var vc : BrowserViewController!
    var home : HomeViewController!
    
    var view : UIView!
    var toolbar : UIView!
    var statusBar : UIView!
    var cardView : UIView!
    
    var direction : WebViewInteractiveDismissDirection!
    var velocity : CGFloat = 0
    
    var backFeedback: UIView!
    
    init(for vc : BrowserViewController) {
        super.init()
        
        self.vc = vc
        view = vc.view
        home = vc.home
        statusBar = vc.statusBar
        cardView = vc.cardView
        toolbar = vc.toolbar
        
//        backFeedback = UIView(frame: CGRect(x: 0, y: view.frame.height/2, width: 64, height: 64))
        backFeedback = ToolbarIconButton(icon: UIImage(named: "back"), onTap: {})
        backFeedback.frame = CGRect(x: 0, y: view.frame.height/2, width: 64, height: 64)
        backFeedback.layer.cornerRadius = 32
        backFeedback.backgroundColor = .black
        backFeedback.tintColor = .white
        backFeedback.alpha = 0
        
        backFeedback.clipsToBounds = false
        backFeedback.layer.shadowColor = UIColor.black.cgColor
        backFeedback.layer.shadowOffset = .zero
        backFeedback.layer.shadowRadius = 4
        backFeedback.layer.shadowOpacity = 0.3

//        view.addSubview(backFeedback)
        
        let dismissPanner = UIPanGestureRecognizer()
        dismissPanner.delegate = self
        dismissPanner.addTarget(self, action: #selector(panGestureChange(gesture:)))
        dismissPanner.cancelsTouchesInView = true
        view.addGestureRecognizer(dismissPanner)
        
        let edgeDismissPan = UIScreenEdgePanGestureRecognizer()
        edgeDismissPan.delegate = self
        edgeDismissPan.edges = .left
        edgeDismissPan.addTarget(self, action: #selector(edgeGestureChange(gesture:)))
        edgeDismissPan.cancelsTouchesInView = true
        view.addGestureRecognizer(edgeDismissPan)
    }
        
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        vc.showToolbar()
    }
    
    var prevScrollY : CGFloat = 0
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let contentH = scrollView.contentSize.height
        let viewH = scrollView.bounds.height
        
        if contentH > viewH && scrollView.contentOffset.y < 0 {
            if scrollView.isDecelerating {
                // disguise overscroll as shifting card
                vc.webView.scrollView.backgroundColor = vc.statusBar.backgroundColor
//                let overscroll = scrollView.contentOffset.y
//                cardView.frame.origin.y -= overscroll
//                cardView.frame.origin.y = elasticLimit(cardView.frame.origin.y)
//                scrollView.contentOffset.y = 0
            }
            else {
                scrollView.contentOffset.y = 0
            }
        }
        else if isInteractiveDismiss {
            scrollView.contentOffset.y = max(startScroll.y, 0)
        }
        
        let scrollDelta = scrollView.contentOffset.y - prevScrollY
        prevScrollY = scrollView.contentOffset.y
        
        if scrollView.isDragging && !vc.isDisplayingSearch && scrollView.contentOffset.y > 0 && !vc.webView.isLoading   {
            let newH = vc.toolbar.frame.height - scrollDelta
            let toolbarH = max(0, min(Const.shared.toolbarHeight, newH))
            
//            vc.toolbar.frame.size.height = toolbarH
            vc.toolbarHeightConstraint.constant = toolbarH
            vc.heightConstraint.constant = -toolbarH - Const.shared.statusHeight

        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView.contentOffset.y > 0 else { return }
        if vc.toolbar.frame.height < (Const.shared.toolbarHeight / 2) {
            vc.hideToolbar()
        }
        else {
            vc.showToolbar()
        }
    }
    
    var isInteractiveDismiss : Bool = false
    var startPoint : CGPoint = .zero
    var startScroll : CGPoint = .zero
    
    let dismissPointX : CGFloat = 150
    let backPointX : CGFloat = 120
    let DISMISS_POINT_V : CGFloat = 300

    @objc func edgeGestureChange(gesture:UIScreenEdgePanGestureRecognizer) {

        if gesture.state == .began {
            direction = .left
            start()
            backFeedback.frame.origin.y = gesture.location(in: view).y - 72
            vc.showToolbar()
        }
        else if gesture.state == .changed {
            if isInteractiveDismiss && (direction == .left || direction == .right) {
                let gesturePos = gesture.translation(in: view)

                
                let revealProgress = min(gesturePos.x / 200, 1)
                home.navigationController?.view.alpha = revealProgress * 0.4 // alpha is 0 ... 0.4
                
                let scale = PRESENT_TAB_BACK_SCALE + revealProgress * 0.5 * (1 - PRESENT_TAB_BACK_SCALE)
                home.navigationController?.view.transform = CGAffineTransform(scaleX: scale, y: scale)
                
//                let adjustedX = elasticLimit(gesturePos.x)
                let adjustedX = gesturePos.x
                
                
//                if vc.webView.canGoBack && adjustedX > dismissPointX {
//                    cardView.frame.origin.x = adjustedX - dismissPointX
//                    if (Const.shared.cardRadius < Const.shared.thumbRadius) {
//                        cardView.layer.cornerRadius = min(Const.shared.cardRadius + revealProgress * 4 * Const.shared.thumbRadius, Const.shared.thumbRadius)
//                    }
//                }
                if !vc.webView.canGoBack {
                    cardView.frame.origin.x = adjustedX
                    if (Const.shared.cardRadius < Const.shared.thumbRadius) {
                        cardView.layer.cornerRadius = min(Const.shared.cardRadius + revealProgress * 4 * Const.shared.thumbRadius, Const.shared.thumbRadius)
                    }
                }
                else {
                    cardView.frame.origin.x = 0
                }
                
                let showBackProgress = min(gesturePos.x / backPointX, 1)
                let backToFarProgress = min(1 - (gesturePos.x - dismissPointX) / 50, 1)
                
//                cardView.frame.origin.y = gesturePos.y
                backFeedback.frame.origin.x = adjustedX - backFeedback.frame.width
//                if abs(gesturePos.y) > 50 {
//                    backFeedback.alpha = 0
//                }
                if vc.webView.canGoBack && adjustedX > backPointX {
                    backFeedback.alpha = 1
                    backFeedback.backgroundColor = .black
                    backFeedback.tintColor = .white
                }
                else if !vc.webView.canGoBack {
                    backFeedback.alpha = 0
                }
//                else if adjustedX > dismissPointX {
//                    backFeedback.alpha = backToFarProgress
//                }
                else {
                    backFeedback.backgroundColor = .white
                    backFeedback.tintColor = .black
                    backFeedback.alpha = 1
                }

            }
        }
        else if gesture.state == .ended {
            let gesturePos = gesture.translation(in: view)
            
            if cardView.frame.origin.y > DISMISS_POINT_V {
                commit()
            }
            else if !vc.webView.canGoBack && cardView.frame.origin.x > dismissPointX {
                commit()
            }
            else if vc.webView.canGoBack && gesturePos.x > backPointX {
                commitBack()
            }
            else {
                reset()
            }
        }
    }
    
    func considerStarting(gesture: UIPanGestureRecognizer) {
        let scrollY = vc.webView.scrollView.contentOffset.y
        let contentH = vc.webView.scrollView.contentSize.height
        let viewH = vc.webView.scrollView.bounds.height
        
        let maxScroll = contentH - viewH

        
        let gesturePos = gesture.translation(in: view)
        
        if contentH > viewH {
            // Body scrollable, cancel at scrollPos 0
            if scrollY == 0 && gesturePos.y > 0 {
                direction = .top
                startPoint = gesturePos
                start()
            }
            else if scrollY > maxScroll {
                direction = .bottom
                startPoint = gesturePos
                start()
            }
        }
        else {
            // Inner div is scrollable, body always scrollPos, 0 cancel at scrollPos -1
            if scrollY < 0 && gesturePos.y > 0 {
                direction = .top
                startPoint = gesturePos
                start()
            }
        }
        
    }
    
    
//    var statusBarAnimator : UIViewPropertyAnimator!
    
    var shouldRestoreKeyboard : Bool = false
    var thumbStartY : CGFloat = 0.0
    func start() {
        isInteractiveDismiss = true
        startScroll = vc.webView.scrollView.contentOffset
        
        if vc.isDisplayingSearch {
            vc.hideSearch()
        }
        
        if let rect = home.thumbFrame(forTab: vc.browserTab!) {
            thumbStartY = rect.origin.y
        }
    }
    
    
    
    func end() {
        isInteractiveDismiss = false
    }
    
    func commit() {
        end()
        vc.dismissSelf()
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.backFeedback.frame.origin.x = -self.backFeedback.frame.width
        })
    }
    
    func commitBack() {
        end()
        vc.webView.goBack()

        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: {
            self.vc.resetSizes(withKeyboard: self.shouldRestoreKeyboard)
            self.vc.home.navigationController?.view.alpha = 0
            self.home.navigationController?.view.frame.origin.y = 0
            self.backFeedback.alpha = 0
            self.backFeedback.frame.origin.x = self.view.frame.width
            
            self.cardView.layer.cornerRadius = Const.shared.cardRadius
        }, completion: { completed in
            self.backFeedback.transform = .identity
        })
    }
    
    func reset(atVelocity vel : CGFloat = 0.0) {
        end()
        
        UIView.animate(withDuration: 0.6, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.0, options: .allowUserInteraction, animations: {
            self.vc.resetSizes(withKeyboard: self.shouldRestoreKeyboard)
            self.vc.setNeedsStatusBarAppearanceUpdate()
            self.vc.home.navigationController?.view.alpha = 0
            self.home.navigationController?.view.frame.origin.y = 0
            self.backFeedback.frame.origin.x = -self.backFeedback.frame.width

            self.cardView.layer.cornerRadius = Const.shared.cardRadius
        }, completion: nil)
        
        if shouldRestoreKeyboard {  // HACK, COPY PASTED EVERYWHERE
            shouldRestoreKeyboard = false
            vc.displaySearch()
        }
        
    }
    
    func elasticLimit(_ val : CGFloat) -> CGFloat {
        let resist = 1 - log10(1 + abs(val) / 150) // 1 ... 0.5
        return val * resist
    }
    
    func update(gesture: UIPanGestureRecognizer) {
        
        let gesturePos = gesture.translation(in: view)
        let adjustedY : CGFloat = gesturePos.y - startPoint.y
        
        if (direction == .top && adjustedY < 0) || (direction == .bottom && adjustedY > 0) {
            
            
            end()
            vc.resetSizes(withKeyboard: shouldRestoreKeyboard)
            if shouldRestoreKeyboard {  // HACK, COPY PASTED EVERYWHERE
                shouldRestoreKeyboard = false
                vc.displaySearch()
            }
            return
        }
        
//        adjustedY = elasticLimit(adjustedY)
        
        
        let statusOffset : CGFloat = 0 // min(Const.shared.statusHeight, (abs(adjustedY) / 300) * Const.shared.statusHeight)
        vc.webView.frame.origin.y = Const.shared.statusHeight - statusOffset
        statusBar.frame.origin.y = 0 - statusOffset
        
        cardView.frame.origin.y = adjustedY
        
//        if adjustedY > 0 {
//            cardView.frame.size.height = view.frame.height - (abs(adjustedY))
//        }
        
        
        let revealProgress = abs(adjustedY) / 200
        home.navigationController?.view.alpha = revealProgress * 0.4 // alpha is 0 ... 0.4
        let scale = PRESENT_TAB_BACK_SCALE + revealProgress * 0.5 * (1 - PRESENT_TAB_BACK_SCALE)
        
        home.navigationController?.view.transform = CGAffineTransform(scaleX: scale, y: scale)
        
//        home.navigationController?.view.frame.origin.y = adjustedY - thumbStartY
        
        if let cv = home.collectionView {
            for cell in home.visibleCellsAbove {
                if let idx = cv.indexPath(for: cell)?.item {
                    cell.frame.origin.y = (adjustedY / 4) * CGFloat(idx) + cv.contentOffset.y + Const.shared.statusHeight
                }
            }
        }
        
//        cardView.layer.cornerRadius = min(revealProgress * 8 * CORNER_RADIUS, CORNER_RADIUS)
        
        if (Const.shared.cardRadius < Const.shared.thumbRadius) {
            cardView.layer.cornerRadius = min(Const.shared.cardRadius + revealProgress * 4 * Const.shared.thumbRadius, Const.shared.thumbRadius)
        }
        
        
        if vc.preferredStatusBarStyle != UIApplication.shared.statusBarStyle {
            UIView.animate(withDuration: 0.2, animations: {
                self.vc.setNeedsStatusBarAppearanceUpdate()
            })
        }
        
//        if abs(adjustedY) > 160 {
//            commit()
//        }
        
//        statusBarAnimator.fractionComplete = abs(adjustedY) / 50
    }
    
    
    @objc func panGestureChange(gesture: UIPanGestureRecognizer) {

        if gesture.state == .began {
            considerStarting(gesture: gesture)
        }
            
        else if gesture.state == .changed {
            
            if isInteractiveDismiss && !(direction == .left) {
                update(gesture: gesture)
            }
            else if !isInteractiveDismiss {
                considerStarting(gesture: gesture)
            }
            
        }
            
        else if gesture.state == .ended {
            if isInteractiveDismiss && !(direction == .left) {
                let gesturePos = gesture.translation(in: view)
                let adjustedY : CGFloat = gesturePos.y - startPoint.y

                let vel = gesture.velocity(in: vc.view)
                
                
                if (direction == .top && (vel.y > 600 || adjustedY > DISMISS_POINT_V)) {
                    commit()
                }
                else if (direction == .bottom && (vel.y < -600 || adjustedY < -DISMISS_POINT_V)) {
                    commit()
                }
                else {
                    reset(atVelocity: vel.y)
                }
            }
            
        }
    }
    
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
//    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        if gestureRecognizer is UIScreenEdgePanGestureRecognizer {
//            return !vc.webView.canGoBack
//        }
//        return true
//    }
    
    // only recognize verticals
//    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
//        if gestureRecognizer is UIScreenEdgePanGestureRecognizer { return true }
//        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
//            let translation = panGestureRecognizer.translation(in: view!)
//            if fabs(translation.x) < fabs(translation.y) {
//                print("Beding Interactive Dismiss")
//                return true
//            }
//            return false
//        }
//        return false
//    }
    
    var isInteractiveDismissToolbar : Bool = false
    var interactiveDismissToolbarStartPoint : CGPoint = .zero

}
