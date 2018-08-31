//
//  HistoryStore.swift
//  Todays Exchange Rate
//
//  Created by Lukes Lu on 2018/8/24.
//  Copyright © 2018 Lukes Lu. All rights reserved.
//

import Foundation
import Alamofire

class Store: NSObject {
    
    class Meta {
        
        // MARK: - Property
        
        var currency: String!
        var granularity: String!
        var times: [TimeInterval] = []
        
        private var values: [String: [Any]] = [:]
        
        // MARK: - Lifecycle
        
        init(currency: String, granularity: String, times: [TimeInterval]) {
            self.currency = currency
            self.granularity = granularity
            self.times = times
        }
        
        // MARK: - Methods
        
        public func addValues(with key: String, values: [Any]) {
            self.values[key] = values
        }
        
        public func getValues(with key: String) -> [Any]? {
            return self.values[key]
        }
        
        public func keys() -> [String]? {
            var results: [String] = []
            for (key, _) in self.values {
                results.append(key)
            }
            
            guard !results.isEmpty else {
                return nil
            }
            
            return results.sorted(by: { (first, second) -> Bool in
                return first < second
            })
        }
        
    }
    
    // MARK: - Property
    
    var base: String = "USD"
    var current: String = "CNY"
    
    var recall: SDelegate = SDelegate<Meta, Void>()
    
    private var metas: [String: Meta] = [:]
    private var ranges: [String] = []
    
    private var requesting: DataRequest?
    
    // MARK: - Setter/Getter
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        
        self.initData()
    }
    
    init(base: String, current: String) {
        super.init()
        
        self.base = base
        self.current = current
        self.initData()
    }
    
    deinit {
        self.requesting?.cancel()
    }
    
    // MARK: - Private Methods
    
    private func initData() {
        self.loadData(with: "1d")
    }
    
    private func getGranularity(with range: String = "1d") -> String {
        switch range {
        case "1d":
            return "1m"
        case "5d":
            return "15m"
        default:
            return "1d"
        }
    }
    
    private func getURL(with range: String = "1d") -> URL? {
        let string = "https://query1.finance.yahoo.com/v8/finance/chart/\(self.base)\(self.current)=X?region=CN&lang=en-US&includePrePost=false&interval=\(self.getGranularity(with: range))&range=\(range)&corsDomain=finance.yahoo.com&tsrc=finance"
        return URL(string: string)
    }
    
    // MARK: - Public Methods
    
    public func loadData() {
        self.requesting?.cancel()
        self.metas.removeAll()
        self.ranges.removeAll()
        self.initData()
    }
    
    public func rangesCount() -> Int {
        return self.ranges.count
    }
    
    public func range(with index: Int) -> String? {
        guard self.ranges.count > index else {
            return nil
        }
        
        return self.ranges[index]
    }
    
    public func meta(with key: String) -> Meta? {
        return self.metas[key]
    }
    
    public func loadData(with range: String) {
        self.requesting?.cancel()
        
        if let url = self.getURL(with: range) {
            self.requesting = Alamofire.request(url).responseJSON(completionHandler: { (response) in
                if let json = response.result.value as? [String: Any] {
                    if let chart = json["chart"] as? [String: Any], let result = chart["result"] as? [Any], let first = result.first as? [String: Any], let meta = first["meta"] as? [String: Any], let ranges = meta["validRanges"] as? [String] {
                        if let currency = meta["currency"] as? String, let granularity = meta["dataGranularity"] as? String {
                            self.ranges = ranges
                            
                            var times: [TimeInterval] = []
                            var values: [String: Any] = [:]
                            if let t = first["timestamp"] as? [TimeInterval], let indicators = first["indicators"] as? [String: Any], let quote = indicators["quote"] as? [Any], let v = quote.first as? [String: Any] {
                                times = t
                                values = v
                            }
                            
                            let data = Meta.init(currency: currency, granularity: granularity, times: times)
                            for (key, v) in values {
                                switch key {
                                case "open", "high", "low", "close", "volume":
                                    if let value = v as? [Any] {
                                        data.addValues(with: key, values: value)
                                    }
                                default:
                                    break
                                }
                            }
                            
                            self.metas[range] = data
                            
                            self.recall.call(data)
                        }
                    }
                }
            })
        }
    }
    
}
