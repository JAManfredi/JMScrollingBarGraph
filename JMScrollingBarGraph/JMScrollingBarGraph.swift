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

protocol JMBarGraphDelegate: class
{
    func barSelectedWithValue(value: Int, index: Int)
}

class JMScrollingBarGraph: UIView, UIScrollViewDelegate
{
    private var barColor: UIColor! = UIColor.whiteColor()
    private var barCount: CGFloat! = 0.0
    private var barGraphDataTotalWidth: CGFloat! = 0.0
    private var barGraphLayerArray: NSMutableArray!
    private var barHighlightColor: UIColor! = UIColor.lightGrayColor()
    private var barWidth: CGFloat! = 10.0 // Default Bar Width
    private var dataArray: Array<CGFloat>! = Array()
    private var draggingIndex: CGFloat! = 0.0
    private var largestDataValue: CGFloat! = 0
    private var scrollView: UIScrollView!
    private var scrollContentView: UIView!
    
    weak var delegate: JMBarGraphDelegate?
    
    // MARK: View Lifecycle
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        scrollView = UIScrollView(frame: CGRectMake(0, 0, frame.size.width, frame.size.height))
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.whiteColor()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        
        scrollContentView = UIView()
        scrollContentView.backgroundColor = UIColor.clearColor()
        scrollView.addSubview(scrollContentView)
        
        barGraphLayerArray = NSMutableArray()
    }

    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layoutScrollview()
    {
        // Set ScrollView Size
        scrollView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        
        // Set Content Size
        scrollView.contentSize = CGSizeMake(scrollView.frame.size.width + barGraphDataTotalWidth, scrollView.frame.size.height)
        
        // Set ContentView Size
        scrollContentView.frame = CGRectMake(scrollView.frame.size.width/2.0,
            0,
            barGraphDataTotalWidth,
            scrollView.bounds.size.height)

        // Offset Everything In Order To Scroll Right
        scrollView.contentOffset = CGPointMake(barGraphDataTotalWidth, 0)
    }
    
    // MARK: Set Data With Array
    
    func setBarDataWithArray(array: Array<CGFloat>)
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
        layoutScrollview()
    }
    
    // MARK: Set Bar Width
    
    func setGraphBarWidth(newWidth: Int)
    {
        barWidth = CGFloat(newWidth)
        barGraphDataTotalWidth = (barCount * barWidth) + barCount
        layoutScrollview()
    }
    
    // MARK: Set Bar Color
    
    func setBarColorTo(color: UIColor)
    {
        barColor = color
    }
    
    // MARK: Set Bar Highlight Color
    
    func setBarHighlightColorTo(color: UIColor)
    {
        barHighlightColor = color
    }
    
    // MARK: Set Background Color 
    
    func setGraphBackgroundColorTo(color: UIColor)
    {
        scrollView.backgroundColor = color
    }
    
    // MARK: Load Graph Data
    
    func loadGraphDataWithAnimation(animate: Bool)
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
            barLayer.frame = CGRectMake(barLocationOffset,
                scrollContentView.frame.size.height - heightOfCurrentBar,
                barWidth,
                heightOfCurrentBar)
            barLayer.strokeColor = barColor.CGColor
            barLayer.lineWidth = barWidth
            
            let barPath = UIBezierPath()
            barPath.moveToPoint(CGPointMake(0 + barWidth/2.0, barLayer.frame.size.height))
            barPath.addLineToPoint(CGPointMake(0 + barWidth/2.0, 0))
            barLayer.path = barPath.CGPath
            
            barGraphLayerArray.addObject(barLayer)
            scrollContentView.layer.addSublayer(barLayer)
            barIndex++
            
            // Animate Drawing Of Each Line
            if animate {
                let pathAnimation: CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
                pathAnimation.duration = 0.5
                pathAnimation.fromValue = 0.0
                pathAnimation.toValue = 1.0
                barLayer.addAnimation(pathAnimation, forKey: "strokeEnd")
            } else {
                barLayer.backgroundColor = barColor.CGColor
            }
        }
        snapToBar()
    }
    
    // MARK: ScrollView Delegate Methods
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        if !decelerate {
            // ScrollView Ended Dragging Without Scrolling Further
            snapToBar()
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView)
    {
        // Called After Drag & Scrolled To Stop
        snapToBar()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView)
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
                if scrollView.dragging {
                    if closestBarIndex != draggingIndex {
                        let resetBarLayer = barGraphLayerArray[Int(draggingIndex)] as! CAShapeLayer
                        let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
                        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
                            self.resetHighlightColor(resetBarLayer)
                        })
                        draggingIndex = closestBarIndex
                        
                        let highlightBarLayer = barGraphLayerArray[Int(closestBarIndex)] as! CAShapeLayer
                        highlightBarLayer.strokeColor = barHighlightColor.CGColor
                    }
                }
            }
        }
    }
    
    // MARK: Snap To Nearest Bar
    
    private func snapToBar()
    {
        if dataArray.count > 0 {
            let currentXOffset = scrollView.contentOffset.x
            let closestBarIndex = CGFloat(max(min(Int(floor(currentXOffset / (barWidth + 1))), dataArray.count - 1), 0))
            
            let currentIndex = Int(closestBarIndex)
            let value = Int(dataArray[currentIndex])
            if let del = delegate {
                del.barSelectedWithValue(value, index: currentIndex)
            }
            
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.scrollView.contentOffset = CGPointMake(closestBarIndex * self.barWidth + closestBarIndex + self.barWidth/2.0, 0)
                }) { (complete) -> Void in
                    let highlightBarLayer = self.barGraphLayerArray[Int(closestBarIndex)] as! CAShapeLayer
                    self.resetHighlightColor(highlightBarLayer)
            }
        } else {
            // Return 0, Most Recent For No Data
            if let del = delegate {
                del.barSelectedWithValue(0, index: 0)
            }
        }
    }
    
    // MARK: Reset Highlight Color
    
    private func resetHighlightColor(layer: CAShapeLayer)
    {
        layer.strokeColor = barColor.CGColor
    }
}
