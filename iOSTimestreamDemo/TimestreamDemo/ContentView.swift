//
//  ContentView.swift
//  TimestreamDemo
//
//  Created by Jason Wiker on 2020-11-19.
//
import HealthKit
import SwiftUI

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}

struct ContentView: View {
    private var healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit(from: "count/min")
    
    @State private var value = 0
    
    var body: some View {
        VStack{
            HStack{
                Text("❤️")
                    .font(.system(size: 50))
                Spacer()

            }
            
            HStack{
                Text("\(value)")
                    .fontWeight(.regular)
                    .font(.system(size: 70))
                
                Text("steps today")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.red)
                    .padding(.bottom, 28.0)
                
                Spacer()
                
            }

        }
        .padding()
        .onAppear(perform: start)
    }
    func start() {
        autorizeHealthKit()
        activitySteps(Date().dayBefore, endDate: Date(), anchorDate: Date()) { (values, error: NSError?) in
            print(values)
        }
        getTodaysSteps { (steps) in
            value = Int(steps)
        }
    //   startHeartRateQuery(quantityTypeIdentifier: .heartRate)
    }

    func autorizeHealthKit() {
        let healthKitTypes: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!]

        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in }
    }

    func getTodaysSteps(completion: @escaping (Double) -> Void) {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.count()))
        }

        healthStore.execute(query)
    }
    
    func activitySteps(_ startDate:Date, endDate:Date, anchorDate:Date, completion: @escaping (Array<NSObject>, NSError?) -> ()) {
        print("Jason")
        let type = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        let interval = NSDateComponents()
        interval.hour = 1

        let predicate = HKQuery.predicateForSamples(withStart: startDate as Date, end: endDate as Date, options: .strictEndDate)
        let query = HKStatisticsCollectionQuery(quantityType: type!, quantitySamplePredicate: predicate, options: [.cumulativeSum], anchorDate: anchorDate as Date, intervalComponents:interval as DateComponents)

        query.initialResultsHandler = { query, results, error in
          if let myResults = results{
            var stepsArray: [NSObject] = []
            myResults.enumerateStatistics(from: startDate as Date, to: endDate as Date) {
              statistics, stop in

              if let quantity = statistics.sumQuantity() {
                let steps = quantity.doubleValue(for: HKUnit.count())

                let ret =  [
                  "steps": steps,
                  "startDate" : statistics.startDate,
                  "endDate": statistics.endDate
                  ] as [String : Any]
                stepsArray.append(ret as NSObject)
              }
            }
            completion(stepsArray, error as NSError?)
          }
        }

        healthStore.execute(query)
      }
}



    
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
