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
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    }
    var monthBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    }
}

struct ContentView: View {
    private var healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit(from: "count/min")
    
    @State private var value = 0
    
    var body: some View {
        VStack{
            HStack{
                Text("💪💪")
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
        getHourlySteps(Date().monthBefore, endDate: Date(), anchorDate: Date()) { (values, error: NSError?) in
            print(values)
            let url = URL(string: "https://tvoaon0awg.execute-api.us-west-2.amazonaws.com/prod/healthInput")!
            var request = URLRequest(url: url)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            let parameters: [String: Any] = [
                "value": values
            ]
            guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
                return
            }
            request.httpBody = httpBody
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data,
                    let response = response as? HTTPURLResponse,
                    error == nil else {
                    print("error", error ?? "Unknown error")
                    return
                }

                guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                    print("statusCode should be 2xx, but is \(response.statusCode)")
                    print("response = \(response)")
                    return
                }

                let responseString = String(data: data, encoding: .utf8)
                print("responseString = \(responseString)")
            }

            task.resume()
        }
        getTodaysSteps { (steps) in
            value = Int(steps)
        }
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
    
    func getHourlySteps(_ startDate:Date, endDate:Date, anchorDate:Date, completion: @escaping ([[String: Any]], NSError?) -> ()) {
        let type = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
        let interval = NSDateComponents()
        interval.hour = 1

        let predicate = HKQuery.predicateForSamples(withStart: startDate as Date, end: endDate as Date, options: .strictEndDate)
        let query = HKStatisticsCollectionQuery(quantityType: type!, quantitySamplePredicate: predicate, options: [.cumulativeSum], anchorDate: anchorDate as Date, intervalComponents:interval as DateComponents)

        query.initialResultsHandler = { query, results, error in
          if let myResults = results{
            var stepsArray: [[String: Any]] = []
            myResults.enumerateStatistics(from: startDate as Date, to: endDate as Date) {
              statistics, stop in

              if let quantity = statistics.sumQuantity() {
                let steps = quantity.doubleValue(for: HKUnit.count())

                let ret =  [
                  "steps": steps,
                  "startDate" : round(statistics.startDate.timeIntervalSince1970 * 1000.0),
                  "endDate": round(statistics.endDate.timeIntervalSince1970 * 1000.0)
                  ] as [String : Any]
                stepsArray.append(ret )
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
