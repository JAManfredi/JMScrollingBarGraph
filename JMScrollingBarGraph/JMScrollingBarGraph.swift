//
//  JMScrollingBarGraph.swift
//  JMScrollingBarGraph
//
//  Created by Jared Manfredi on 1/4/16.
//  Copyright © 2016 jm. All rights reserved.
//

/*
    -- Bar Graph Appearance Methods --

    func setGraphBarWidth(newWidth: Int)
    func setBarColorTo(color: UIColor)
    func setBarHighlightColorTo(color: UIColor)
    func setGraphBackgroundColorTo(color: UIColor)

    -- Bar Graph Functional Methods --

    func setBarDataWithArray(array: Array<CGFloat>)
    func loadGraphDataWithAnimation(animate: Bool)
*/

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


protocol JMBarGraphDelegate: class
{
    func barSelectedWithValue(_ value: Int, index: Int)
}

class JMScrollingBarGraph: UIView, UIScrollViewDelegate
{
    private lazy var __once: () = {
                            self.showGraphScroll()
                        }()
    fileprivate var barColor: UIColor! = UIColor.white
    fileprivate var barCount: CGFloat! = 0.0
    fileprivate var barGraphDataTotalWidth: CGFloat! = 0.0
    fileprivate var barGraphLayerArray: NSMutableArray!
    fileprivate var barHighlightColor: UIColor! = UIColor.lightGray
    fileprivate var barWidth: CGFloat! = 10.0 // Default Bar Width
    fileprivate var dataArray: Array<CGFloat>! = Array()
    fileprivate var draggingIndex: CGFloat! = 0.0
    fileprivate var largestDataValue: CGFloat! = 0
    fileprivate var scrollView: UIScrollView!
    fileprivate var scrollContentView: UIView!
    fileprivate var demoForUser: Bool = false
    fileprivate var demoToken: Int = 0
    
    weak var delegate: JMBarGraphDelegate?
    
    // MARK: View Lifecycle
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.white
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        
        scrollContentView = UIView()
        scrollContentView.backgroundColor = UIColor.clear
        scrollView.addSubview(scrollContentView)
        
        barGraphLayerArray = NSMutableArray()
    }

    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        scrollView = UIScrollView(frame: CGRect.zero)
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.scBarGraphBackgroundBlue()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        
        scrollContentView = UIView()
        scrollContentView.backgroundColor = UIColor.clear
        scrollView.addSubview(scrollContentView)
        
        barGraphLayerArray = NSMutableArray()
    }
    
    override func layoutSubviews()
    {
        // Set ScrollView Size
        scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        
        // Set Content Size
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width + barGraphDataTotalWidth, height: scrollView.frame.size.height)
        
        // Set ContentView Size
        scrollContentView.frame = CGRect(x: scrollView.frame.size.width/2.0,
            y: 0,
            width: barGraphDataTotalWidth,
            height: scrollView.bounds.size.height)

        // Offset Everything In Order To Scroll Right
        scrollView.contentOffset = CGPoint(x: barGraphDataTotalWidth, y: 0)
    }
    
    // MARK: Set Data With Array
    
    func setBarDataWithArray(_ array: Array<CGFloat>)
    {
        dataArray = array
        
        // Find Largest Data Value To Normalize Graph
        for dataPt in dataArray {
            if (dataPt > largestDataValue) {
                largestDataValue = dataPt
            }
        }
        
        barCount =  CGFloat(dataArray.count)
        barGraphDataTotalWidth = (barCount * barWidth) + barCount
        layoutSubviews()
    }
    
    // MARK: Set Bar Width
    
    func setGraphBarWidth(_ newWidth: Int)
    {
        barWidth = CGFloat(newWidth)
        barGraphDataTotalWidth = (barCount * barWidth) + barCount
        layoutSubviews()
    }
    
    // MARK: Set Bar Color
    
    func setBarColorTo(_ color: UIColor)
    {
        barColor = color
    }
    
    // MARK: Set Bar Highlight Color
    
    func setBarHighlightColorTo(_ color: UIColor)
    {
        barHighlightColor = color
    }
    
    // MARK: Set Background Color 
    
    func setGraphBackgroundColorTo(_ color: UIColor)
    {
        scrollView.backgroundColor = color
    }
    
    // MARK: Load Graph Data
    
    func loadGraphDataWithAnimation(_ animate: Bool)
    {
        barGraphLayerArray.removeAllObjects()
        scrollContentView.layer.sublayers = nil
        
        var barIndex: CGFloat = 0 // Init To First Index
        for barData in dataArray {
            let barLayer = CAShapeLayer() // New Shape Layer
            let heightOfLargestValuePossible: CGFloat = scrollContentView.frame.size.height - 10.0 // Keep 10 Pt Buffer To Top At All Times
            
            // Normalize To Largest Value In Array
            let heightOfCurrentBar: CGFloat = (largestDataValue > 0) ? CGFloat(barData)/largestDataValue * heightOfLargestValuePossible + 2 : 2
            // Index x Width Then Subtract Half of Width To Center
            let barLocationOffset: CGFloat = barIndex * barWidth + barIndex
            barLayer.frame = CGRect(x: barLocationOffset,
                y: scrollContentView.frame.size.height - heightOfCurrentBar,
                width: barWidth,
                height: heightOfCurrentBar)
            barLayer.strokeColor = barColor.cgColor
            barLayer.lineWidth = barWidth
            
            let barPath = UIBezierPath()
            barPath.move(to: CGPoint(x: 0 + barWidth/2.0, y: barLayer.frame.size.height))
            barPath.addLine(to: CGPoint(x: 0 + barWidth/2.0, y: 0))
            barLayer.path = barPath.cgPath
            
            barGraphLayerArray.add(barLayer)
            scrollContentView.layer.addSublayer(barLayer)
            barIndex += 1
            
            // Animate Drawing Of Each Line
            if animate {
                let pathAnimation: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
                pathAnimation.duration = 0.5
                pathAnimation.fromValue = 0.0
                pathAnimation.toValue = 1.0
                barLayer.add(pathAnimation, forKey: "strokeEnd")
            } else {
                barLayer.backgroundColor = barColor.cgColor
            }
        }
        snapToBar(animate)
    }
    
    // MARK: ScrollView Delegate Methods
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        if !decelerate {
            // ScrollView Ended Dragging Without Scrolling Further
            snapToBar(false)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        // Called After Drag & Scrolled To Stop
        snapToBar(false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        if dataArray.count > 0 {
            let currentXOffset = scrollView.contentOffset.x
            let closestBarIndex = CGFloat(max(min(Int(floor(currentXOffset / (barWidth + 1))), dataArray.count - 1), 0))
            let currentIndex = Int(closestBarIndex)
            let value = Int(dataArray[Int(closestBarIndex)])
            
            if let del = delegate {
                del.barSelectedWithValue(value, index: currentIndex)
            }
            
            // Change Colors of Bars While Dragging
            if (barGraphLayerArray != nil && barGraphLayerArray.count > 0) {
                if scrollView.isDragging || demoForUser {
                    if closestBarIndex != draggingIndex {
                        let resetBarLayer = barGraphLayerArray[Int(draggingIndex)] as! CAShapeLayer
                        let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                        DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                            self.resetHighlightColor(resetBarLayer)
                        })
                        draggingIndex = closestBarIndex
                        
                        let highlightBarLayer = barGraphLayerArray[Int(closestBarIndex)] as! CAShapeLayer
                        highlightBarLayer.strokeColor = barHighlightColor.cgColor
                    }
                }
            }
        }
    }
    
    // MARK: Snap To Nearest Bar
    
    fileprivate func snapToBar(_ showDemo: Bool)
    {
        if dataArray.count > 0 {
            let currentXOffset = scrollView.contentOffset.x
            let closestBarIndex = CGFloat(max(min(Int(floor(currentXOffset / (barWidth + 1))), dataArray.count - 1), 0))
            
            let currentIndex = Int(closestBarIndex)
            let value = Int(dataArray[currentIndex])
            if let del = delegate {
                del.barSelectedWithValue(value, index: currentIndex)
            }
            
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                    self.scrollView.contentOffset = CGPoint(x: closestBarIndex * self.barWidth + closestBarIndex + self.barWidth/2.0, y: 0)
                }, completion: { (complete) -> Void in
                    let highlightBarLayer = self.barGraphLayerArray[Int(closestBarIndex)] as! CAShapeLayer
                    self.resetHighlightColor(highlightBarLayer)
                    
                    if (showDemo) {
                        // Only Show Demo Once
                        _ = self.__once
                    }
            }) 
        } else {
            // Return 0, Most Recent For No Data
            if let del = delegate {
                del.barSelectedWithValue(0, index: 0)
            }
        }
    }
    
    // MARK: Show Graph Scrolls To User
    
    fileprivate func showGraphScroll()
    {
        if dataArray.count > 3 {
            let currentXOffset = scrollView.contentOffset.x
            let startBarIndex = CGFloat(max(min(Int(floor(currentXOffset / (barWidth + 1))), dataArray.count - 1), 0))
            let scrollToBar1 = startBarIndex - 1
            let scrollToBar2 = startBarIndex - 2
            
            self.demoForUser = true
            UIView.animate(withDuration: 0.4, delay: 0.5, options: UIViewAnimationOptions(), animations: { () -> Void in
                self.scrollView.contentOffset = CGPoint(x: scrollToBar1 * self.barWidth + scrollToBar1 + self.barWidth/2.0, y: 0)
            }) { (complete) -> Void in
                let value = Int(self.dataArray[Int(scrollToBar1)])
                if let del = self.delegate {
                    del.barSelectedWithValue(value, index: Int(scrollToBar1))
                }
                
                UIView.animate(withDuration: 0.4, animations: { () -> Void in
                    self.scrollView.contentOffset = CGPoint(x: scrollToBar2 * self.barWidth + scrollToBar2 + self.barWidth/2.0, y: 0)
                }, completion: { (complete) -> Void in
                    let value = Int(self.dataArray[Int(scrollToBar2)])
                    if let del = self.delegate {
                        del.barSelectedWithValue(value, index: Int(scrollToBar2))
                    }
                    
                    UIView.animate(withDuration: 0.4, animations: { () -> Void in
                        self.scrollView.contentOffset = CGPoint(x: scrollToBar1 * self.barWidth + scrollToBar1 + self.barWidth/2.0, y: 0)
                    }, completion: { (complete) -> Void in
                        let value = Int(self.dataArray[Int(scrollToBar1)])
                        if let del = self.delegate {
                            del.barSelectedWithValue(value, index: Int(scrollToBar1))
                        }
                        
                        UIView.animate(withDuration: 0.4, animations: { () -> Void in
                            self.scrollView.contentOffset = CGPoint(x: startBarIndex * self.barWidth + startBarIndex + self.barWidth/2.0, y: 0)
                        }, completion: { (complete) -> Void in
                            let value = Int(self.dataArray[Int(startBarIndex)])
                            if let del = self.delegate {
                                del.barSelectedWithValue(value, index: Int(startBarIndex))
                            }
                        
                            let highlightBarLayer = self.barGraphLayerArray[Int(startBarIndex)] as! CAShapeLayer
                            self.resetHighlightColor(highlightBarLayer)
                            self.demoForUser = false
                        }) 
                    }) 
                }) 
            }
        }
    }
    
    // MARK: Reset Highlight Color
    
    fileprivate func resetHighlightColor(_ layer: CAShapeLayer)
    {
        layer.strokeColor = barColor.cgColor
    }
}
