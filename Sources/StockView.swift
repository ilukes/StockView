//
//  StockView.swift
//  Todays Exchange Rate
//
//  Created by Lukes Lu on 2018/8/27.
//  Copyright © 2018 Lukes Lu. All rights reserved.
//

import Foundation
import UIKit

class StockView: UIView {
    
    struct Stock {
        var time: TimeInterval
        var value: Double = 0
    }
    
    enum DisplayStyle: Int {
        case Line = 0
        case Area = 1
    }
    
    // MARK: - Property
    
    var leftMargin: CGFloat = 10
    var bottomMargin: CGFloat = 30
    var topMargin: CGFloat = 5
    var rightMargin: CGFloat = 10
    var diffMargin: CGFloat = 20
    var boundLineColor: UIColor = .darkGray
    var boundLineWidth: CGFloat = CGFloat(1.0/Double(UIScreen.main.scale))
    
    var timeTextColor: UIColor = .white
    var timeFont: UIFont = UIFont.systemFont(ofSize: 12)
    var timeSegmentCount: Int = 4 // How many times do you want to display
    
    var valueTextColor: UIColor = .white
    var valueFont: UIFont = UIFont.systemFont(ofSize: 12)
    var valueSegmentCount: Int = 4 // How many values do you want to display
    var valueLineColor: UIColor = .lightGray
    var valueLineWidth: CGFloat = CGFloat(1.0/Double(UIScreen.main.scale))
    
    var eventLineColor: UIColor = .white
    var eventLineHeightWidth: CGFloat = CGFloat(1.0/Double(UIScreen.main.scale))
    var eventPointColor: UIColor = .white
    var eventPointRadius: CGFloat = 2.50
    var eventLineWidth: CGFloat = CGFloat(1.0/Double(UIScreen.main.scale))
    
    var stockLineColor: UIColor = .blue
    var stockLineWidth: CGFloat = 1.0
    var stockAreaColor: UIColor = .red
    
    var displayStyle: DisplayStyle = .Line
    
    var infoRecall: SDelegate = SDelegate<[Double], Void>() // [] Will has three values. Min/Avg/Max
    var eventRecall: SDelegate = SDelegate<[TimeInterval: Double], Void>() // When user hold the view will call this
    var timeFormatRecall: SDelegate = SDelegate<TimeInterval, String>() // If you want to custom the time info for display you can implement this.
    var valueFormatRecall: SDelegate = SDelegate<Double, String>() // If you want to custom the value info for display you can implement this. e.g. %.2f %.4f %.6f ...
    
    private var points: [CGPoint] = []
    private var minValue: Double = 0
    private var maxValue: Double = 0
    private var avgValue: Double = 0
    private var minTime: TimeInterval = 0
    private var maxTime: TimeInterval = 0
    
    // Event
    private var begin: Bool = false
    private var eventPoint: CGPoint = .zero
    private var eventDataPoint: CGPoint = .zero
    private var eventTimeLine: UIImageView?
    private var eventValueLine: UIImageView?
    private var eventPointCircle: UIImageView?
    
    // MARK: - Setter/Getter
    
    var stocks: [Stock] = [] {// Must set from outside
        didSet {
            self.loadData()
        }
    }
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        guard !self.points.isEmpty else {
            return
        }
        
        if let ctx = UIGraphicsGetCurrentContext() {
            switch self.displayStyle {
            case .Line:
                let path = UIBezierPath.init()
                let first = self.points.first!
                path.move(to: first)
                
                for i in 1..<self.points.count {
                    path.addLine(to: self.points[i])
                }
                
                ctx.setLineWidth(self.stockLineWidth)
                self.stockLineColor.set()
                ctx.addPath(path.cgPath)
                ctx.strokePath()
            case .Area:
                let path = UIBezierPath.init()
                path.move(to: CGPoint(x: self.leftMargin, y: self.bounds.height-self.bottomMargin))
                
                for i in 0..<self.points.count {
                    path.addLine(to: self.points[i])
                }
                
                path.addLine(to: CGPoint(x: self.bounds.width-self.rightMargin, y: self.bounds.height-self.bottomMargin))
                
                self.stockAreaColor.setFill()
                ctx.addPath(path.cgPath)
                path.fill()
                ctx.strokePath()
            }
        }
    }
    
    // MARK: - Event
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.points.isEmpty {
            return
        }
        
        if let touch: UITouch = touches.first {
            self.eventPoint = touch.location(in: self)
            self.begin = true
            self.displayEventInfo()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            self.eventPoint = touch.location(in: self)
            self.displayEventInfo()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.begin = false
        self.removeEventInfo()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.begin = false
        self.removeEventInfo()
    }
    
    // MARK: - Private Methods
    
    private func displayEventInfo() {
        guard self.begin, self.eventPoint != .zero else {
            return
        }
        
        self.eventDataPoint = self.getDataPoint(with: self.eventPoint)
        
        guard self.eventDataPoint != .zero else {
            return
        }
        
        // Line
        if self.eventTimeLine == nil {
            self.eventTimeLine = UIImageView.init(frame: CGRect(x: self.leftMargin, y: self.topMargin, width: self.eventLineHeightWidth, height: self.bounds.height-self.topMargin-self.bottomMargin))
            self.eventTimeLine?.backgroundColor = self.eventLineColor
            self.addSubview(self.eventTimeLine!)
        }
        if self.eventValueLine == nil {
            self.eventValueLine = UIImageView.init(frame: CGRect(x: self.leftMargin, y: self.topMargin, width: self.bounds.width-self.leftMargin-self.rightMargin, height: self.eventLineHeightWidth))
            self.eventValueLine?.backgroundColor = self.eventLineColor
            self.addSubview(self.eventValueLine!)
        }
        if self.eventPointCircle == nil {
            self.eventPointCircle = UIImageView.init(frame: CGRect(x: 0, y: 0, width: self.eventPointRadius*2, height: self.eventPointRadius*2))
            self.eventPointCircle?.layer.cornerRadius = self.eventPointRadius
            self.eventPointCircle?.layer.masksToBounds = true
            self.eventPointCircle?.backgroundColor = self.eventPointColor
            self.addSubview(self.eventPointCircle!)
        }
        
        self.eventTimeLine?.center = CGPoint(x: self.eventDataPoint.x, y: self.eventTimeLine?.center.y ?? 0)
        self.eventValueLine?.center = CGPoint(x: self.eventValueLine?.center.x ?? 0, y: self.eventDataPoint.y)
        self.eventPointCircle?.center = self.eventDataPoint
        
        // Found Times
        if let index = self.points.firstIndex(where: { (point) -> Bool in
            return point.x == self.eventDataPoint.x && point.y == self.eventDataPoint.y
        }) {
            if index >= 0, index < self.stocks.count {
                let stock = self.stocks[index]
                let time = stock.time
                let value = stock.value
                
                self.eventRecall.call([time: value])
            }
        }
    }
    
    private func removeEventInfo() {
        self.eventTimeLine?.removeFromSuperview()
        self.eventValueLine?.removeFromSuperview()
        self.eventPointCircle?.removeFromSuperview()
        self.eventTimeLine = nil
        self.eventValueLine = nil
        self.eventPointCircle = nil
        self.eventPoint = .zero
        self.eventDataPoint = .zero
    }
    
    private func getDataPoint(with event: CGPoint) -> CGPoint {
        guard !self.points.isEmpty else {
            return .zero
        }
        
        var result: CGPoint = self.points.first!
        
        for point in self.points {
            if abs(point.x-event.x) <= abs(result.x-event.x) {
                result = point
                continue
            }
            break
        }
        
        return result
    }
    
    private func clear() {
        for view in self.subviews {
            view.removeFromSuperview()
        }
        self.points.removeAll()
        self.setNeedsDisplay()
    }
    
    private func computeBounds() {
        self.minValue = Double(MAXFLOAT)
        self.maxValue = Double(-MAXFLOAT)
        self.minTime = self.stocks.first?.time ?? 0
        self.maxTime = self.stocks.last?.time ?? Double(MAXFLOAT)
        
        var sumValue: Double = 0
        for stock in self.stocks {
            let value: Double = stock.value
            
            sumValue += value
            
            if value < self.minValue {
                self.minValue = value
            }
            if value > self.maxValue {
                self.maxValue = value
            }
        }
        
        if self.stocks.isEmpty {
           self.avgValue = 0
        }else{
            self.avgValue = sumValue/Double(self.stocks.count)
        }
        
        self.infoRecall.call([self.minValue, self.avgValue, self.maxValue])
    }
    
    private func getString(with time: TimeInterval) -> String {
        if let string = self.timeFormatRecall.call(time) {
            return string
        }
        
        return "\(time)"
    }
    
    private func getString(for value: Double) -> String {
        if let string = self.valueFormatRecall.call(value) {
            return string
        }
        
        return String(format: "%.4f", value)
    }
    
    // MARK: - Public Methods
    
    public func loadData() {
        // Clean
        self.clear()
        
        // Init
        self.computeBounds()
        
        let baseWith: CGFloat = self.bounds.width-self.leftMargin-self.rightMargin
        let baseHeight: CGFloat = self.bounds.height-self.topMargin-self.bottomMargin-self.diffMargin*2
        
        // Bounds
        
        let leftBoundLine = UIImageView.init(frame: CGRect(x: self.leftMargin, y: self.topMargin, width: self.boundLineWidth, height: self.bounds.height-self.topMargin-self.bottomMargin))
        leftBoundLine.backgroundColor = self.boundLineColor
        self.addSubview(leftBoundLine)
        
        let bottomBoundLine = UIImageView.init(frame: CGRect(x: self.leftMargin, y: self.bounds.height-self.bottomMargin-self.boundLineWidth, width: self.bounds.width-self.leftMargin-self.rightMargin, height: self.boundLineWidth))
        bottomBoundLine.backgroundColor = self.boundLineColor
        self.addSubview(bottomBoundLine)
        
        let topBoundLine = UIImageView.init(frame: CGRect(x: self.leftMargin, y: self.topMargin, width: self.bounds.width-self.leftMargin-self.rightMargin, height: self.boundLineWidth))
        topBoundLine.backgroundColor = self.boundLineColor
        self.addSubview(topBoundLine)
        
        let rightBoundLine = UIImageView.init(frame: CGRect(x: self.bounds.width-self.rightMargin-self.boundLineWidth, y: self.topMargin, width: self.boundLineWidth, height: self.bounds.height-self.topMargin-self.bottomMargin))
        rightBoundLine.backgroundColor = self.boundLineColor
        self.addSubview(rightBoundLine)
        
        // Times Guide Line & Text
        
        for i in 0...self.timeSegmentCount {
            let timeLabel = UILabel.init(frame: .zero)
            timeLabel.textColor = self.timeTextColor
            timeLabel.font = self.timeFont
            timeLabel.text = self.getString(with: self.minTime+(self.maxTime-self.minTime)*Double(i)/Double(self.timeSegmentCount))
            self.addSubview(timeLabel)
            timeLabel.sizeToFit()
            
            var x: CGFloat = self.leftMargin+baseWith*(CGFloat(i)/CGFloat(self.timeSegmentCount))
            if timeLabel.bounds.width/2.0 > x {
                x = timeLabel.bounds.width/2.0
            }else if x + timeLabel.bounds.width/2.0 > self.bounds.width {
                x = self.bounds.width-timeLabel.bounds.width/2.0
            }
            
            timeLabel.center = CGPoint(x: x, y: leftBoundLine.frame.origin.y+leftBoundLine.bounds.height+5+timeLabel.bounds.height/2.0)
        }
        
        // Values Guide Line & Text
        
        for i in 0...self.valueSegmentCount {
            let line = UIImageView.init(frame: CGRect(x: self.leftMargin, y: self.topMargin+self.diffMargin+baseHeight*CGFloat(i)/CGFloat(self.valueSegmentCount), width: self.bounds.width-self.leftMargin-self.rightMargin, height: self.valueLineWidth))
            line.backgroundColor = self.valueLineColor
            self.addSubview(line)
            
            let label = UILabel.init(frame: .zero)
            label.textColor = self.valueTextColor
            label.font = self.valueFont
            label.text = self.getString(for: self.maxValue-(self.maxValue-self.minValue)*Double(i)/Double(self.valueSegmentCount))
            self.addSubview(label)
            label.sizeToFit()
            
            var y: CGFloat = line.center.y+2+label.bounds.height/2.0
            if y + label.bounds.height/2.0 + self.diffMargin > self.bounds.height-self.bottomMargin {
                y = line.center.y-2-label.bounds.height/2.0
            }
            
            label.center = CGPoint(x: self.bounds.width-self.rightMargin-label.bounds.width/2.0, y: y)
        }
        
        // Get Points
        
        for stock in self.stocks {
            let time = stock.time
            let value = stock.value
            
            let x: CGFloat = self.leftMargin+CGFloat((time-self.minTime)/(self.maxTime-self.minTime))*baseWith
            let y: CGFloat = self.bounds.height-self.bottomMargin-self.diffMargin-CGFloat((value-self.minValue)/(self.maxValue-self.minValue))*baseHeight
            self.points.append(CGPoint(x: x, y: y))
        }
        
        self.setNeedsDisplay()
    }
    
}

class SDelegate<Input, Output> {
    
    private var block: ((Input) -> Output?)?
    
    func delegate<T:AnyObject>(on target: T, block: ((T, Input) -> Output)?) {
        self.block = {[weak target] input in
            guard let target = target else {
                return nil
            }
            return block?(target, input)
        }
    }
    
    func call(_ input: Input) -> Output? {
        return block?(input)
    }
    
}

extension SDelegate where Input == Void {
    func call() -> Output? {
        return call(())
    }
}
