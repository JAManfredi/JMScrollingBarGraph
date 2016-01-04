# JMScrollingBarGraph

This is my quick implementation of a scrolling bar graph, feel free to make it into something even more useful!

## Code Example

    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        let barGraph = JMScrollingBarGraph(frame: CGRect( x: CGRectGetMidX(self.view.frame) - 100, 
                                                          y: 100, 
                                                          width: 200, 
                                                          height: 200))
        self.view.addSubview(barGraph)
        
        barGraph.setGraphBackgroundColorTo(UIColor.lightGrayColor())
        barGraph.setBarColorTo(UIColor.blueColor())
        barGraph.setBarHighlightColorTo(UIColor.cyanColor())
        
        barGraph.setBarDataWithArray([123.3, 12, 166.4, 55.3, 10])
        barGraph.loadGraphDataWithAnimation(true)
    }

## Installation

Just drop the JMScrollingBarGraph.swift file into your project. :)
