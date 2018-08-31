//
//  SampleViewController.swift
//  StockViewSample
//
//  Created by Lukes Lu on 2018/8/31.
//  Copyright © 2018 YunShenIT. All rights reserved.
//

import UIKit

class SampleViewController: UIViewController {
    
    // MARK: - Property
    
    @IBOutlet weak var eventValueLabel: UILabel!
    @IBOutlet weak var eventTimeLabel: UILabel!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var avgLabel: UILabel!
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var stockView: StockView!
    
    private var  rangeSegmentedControl: UISegmentedControl?
    private var valueSegmentedControl: UISegmentedControl?
    
    private let IS_IPHONE_X: Bool = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone && UIScreen.main.nativeBounds.height == 2436
    
    var store: Store!
    
    private var fractionDigitsNum: Int = 4
    
    // MARK: - Memory
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // StockView
        
        self.stockView.topMargin = 30+5+5
        self.stockView.bottomMargin = 30+5+5+20
        
        self.stockView.infoRecall.delegate(on: self) { (self, results) in
            if results.count == 3 {
                let min = results[0]
                let avg = results[1]
                let max = results[2]
                
                self.minLabel.text = "Min: \(self.getString(for: min))"
                self.avgLabel.text = "Avg: \(self.getString(for: avg))"
                self.maxLabel.text = "Max: \(self.getString(for: max))"
            }
        }
        
        // Store
        self.store = Store.init()
        self.store.recall.delegate(on: self) { (self, meta) in
            self.createRangesItem()
            self.createValueItem()
            self.loadChartPoints()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    deinit {
        
    }
    
    // MARK: - Actions
    
    @objc private func whenRangeTimeValueChanged(_ sender: UISegmentedControl) {
        self.loadChartPoints()
    }
    
    @objc private func whenValueItemValueChanged(_ sender: UISegmentedControl) {
        self.loadChartPoints()
    }
    
    @objc private func whenDisplayStyleValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.stockView.displayStyle = .Line
        case 1:
            self.stockView.displayStyle = .Area
        default:
            break
        }
        
        self.stockView.setNeedsDisplay()
    }
    
    // MARK: - Methods
    
    private func getString(for currency: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
        formatter.maximumFractionDigits = self.fractionDigitsNum
        formatter.minimumFractionDigits = self.fractionDigitsNum
        return formatter.string(from: NSNumber(value: currency))!
    }
    
    private func getFullString(with date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        
        return dateFormatter.string(from: date)
    }
    
    private func cleanRangesItem() {
        self.rangeSegmentedControl?.removeFromSuperview()
        self.rangeSegmentedControl = nil
    }
    
    private func createRangesItem(with selectedIndex: Int = 0) {
        guard self.rangeSegmentedControl == nil else {
            return
        }
        
        var items: [String] = []
        for i in 0..<self.store.rangesCount() {
            if let range = self.store.range(with: i) {
                items.append(range)
            }
        }
        
        if !items.isEmpty {
            self.rangeSegmentedControl = UISegmentedControl.init(items: items)
            self.rangeSegmentedControl?.selectedSegmentIndex = 0
            self.rangeSegmentedControl?.frame = CGRect(x: 5, y: self.view.bounds.height-5-30-(self.IS_IPHONE_X ? 34 : 0), width: self.view.bounds.width-5*2, height: 30)
            self.rangeSegmentedControl?.addTarget(self, action: #selector(whenRangeTimeValueChanged(_:)), for: .valueChanged)
            self.view.addSubview(self.rangeSegmentedControl!)
        }
    }
    
    private func cleanValueItem() {
        self.valueSegmentedControl?.removeFromSuperview()
        self.valueSegmentedControl = nil
    }
    
    private func createValueItem() {
        guard self.valueSegmentedControl == nil else {
            return
        }
        
        if let item = self.rangeSegmentedControl, let range = self.store.range(with: item.selectedSegmentIndex), let meta = self.store.meta(with: range), var items = meta.keys() {
            if let index = items.firstIndex(of: "volume") {
                items.remove(at: index)
            }
            
            self.valueSegmentedControl = UISegmentedControl.init(items: items)
            self.valueSegmentedControl?.selectedSegmentIndex = 0
            self.valueSegmentedControl?.frame = CGRect(x:0, y: self.stockView.frame.origin.y+5, width: self.view.bounds.width/4.0*3-5*2, height: 30)
            self.valueSegmentedControl?.addTarget(self, action: #selector(whenValueItemValueChanged(_:)), for: .valueChanged)
            self.view.addSubview(self.valueSegmentedControl!)
            self.valueSegmentedControl?.center = CGPoint(x: self.view.bounds.width/2.0, y: self.valueSegmentedControl?.center.y ?? 0)
        }
    }
    
    private func addDisplayStyleItemToRight(_ selectedIndex: Int = 0) {
        let item = UISegmentedControl(items: ["Line", "Area"])
        item.addTarget(self, action: #selector(whenDisplayStyleValueChanged(_:)), for: .valueChanged)
        item.frame = CGRect(x: 0, y: (44-30)/2.0, width: 85, height: 30)
        item.selectedSegmentIndex = selectedIndex
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: item)
    }
    
    func loadChartPoints() {
        if let index = self.rangeSegmentedControl?.selectedSegmentIndex, let range = self.store.range(with: index) {
            if let meta = self.store.meta(with: range) {
                var points: [StockView.Stock] = []
                
                if let opens = meta.getValues(with: "open"), let closes = meta.getValues(with: "close"), let lows = meta.getValues(with: "low"), let highs = meta.getValues(with: "high") {
                    for i in 0..<meta.times.count {
                        let ds: Double = meta.times[i]
                        
                        var open: Double = 0
                        if opens.count > i, let v = opens[i] as? Double {
                            open = v
                        }
                        var close: Double = 0
                        if closes.count > i, let v = closes[i] as? Double {
                            close = v
                        }
                        var low: Double = 0
                        if lows.count > i, let v = lows[i] as? Double {
                            low = v
                        }
                        var high: Double = 0
                        if highs.count > i, let v = highs[i] as? Double {
                            high = v
                        }
                        
                        var value: Double = close
                        if let item = self.valueSegmentedControl, let title = item.titleForSegment(at: item.selectedSegmentIndex) {
                            switch title {
                            case "open":
                                value = open
                            case "close":
                                value = close
                            case "low":
                                value = low
                            case "high":
                                value = high
                            default:
                                value = close
                            }
                        }
                        
                        if value > 0.000001 {
                            points.append(StockView.Stock(time: ds, value: value))
                        }
                    }
                }
                
                if !points.isEmpty {
                    // Display Style
                    self.addDisplayStyleItemToRight(self.stockView.displayStyle == .Line ? 0 : 1)
                    
                    self.stockView.timeFormatRecall.delegate(on: self) { (self, time) -> String in
                        let date: Date = Date.init(timeIntervalSince1970: time)
                        let dt: String = self.getFullString(with: date)
                        
                        switch range {
                        case "1d":
                            return String(dt[dt.index(dt.startIndex, offsetBy: 11)...dt.index(dt.startIndex, offsetBy: 15)])
                        case "5d":
                            return String(dt[dt.index(dt.startIndex, offsetBy: 8)...dt.index(dt.startIndex, offsetBy: 15)])
                        case "1mo", "3mo", "6mo", "ytd":
                            return String(dt[dt.index(dt.startIndex, offsetBy: 5)...dt.index(dt.startIndex, offsetBy: 10)])
                        default:
                            return String(dt[dt.index(dt.startIndex, offsetBy: 2)...dt.index(dt.startIndex, offsetBy: 10)])
                        }
                    }
                    self.stockView.valueFormatRecall.delegate(on: self) { (self, value) -> String in
                        return self.getString(for: value)
                    }
                    self.stockView.eventRecall.delegate(on: self) { (self, result) in
                        for (time, value) in result {
                            self.loadEventInfo(with: time, value: value)
                            break
                        }
                    }
                    
                    self.stockView.stocks = points
                    
                    if let stock = points.first {
                        self.loadEventInfo(with: stock.time, value: stock.value)
                    }
                }
            }else{
                self.cleanValueItem()
                self.navigationItem.rightBarButtonItem = nil
                self.store.loadData(with: range)
            }
        }
    }
    
    private func loadEventInfo(with time: TimeInterval, value: Double) {
        self.eventValueLabel.text = self.getString(for: value)
        
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        fmt.locale = Locale.current
        fmt.timeZone = TimeZone.init(secondsFromGMT: 0)
        let str = fmt.string(from: Date(timeIntervalSince1970: time))
        if str.hasSuffix(" 00:00:00") {
            fmt.dateFormat = "yyyy-MM-dd"
            self.eventTimeLabel.text = fmt.string(from: Date(timeIntervalSince1970: time))
        }else{
            fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
            self.eventTimeLabel.text = fmt.string(from: Date(timeIntervalSince1970: time))
        }
    }
    
}
