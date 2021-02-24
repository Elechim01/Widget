//
//  Graph.swift
//  Graph
//
//  Created by Michele Manniello on 24/02/21.
//

import WidgetKit
import SwiftUI

//First Creating Model For Widget Data....
struct Model: TimelineEntry {
    var date : Date
    var widgetData : [JSONModel]
}
//Creazione del Modello Per JSON DATA
struct JSONModel: Decodable,Hashable {
    var date : CGFloat
    var units : Int
}
//Creating Provider For Providing Data For Widget.....
struct Provider: TimelineProvider {
//    for safer side were returning placeolder content...
    func placeholder(in context: Context) -> Model {
        let loadingData = Model(date: Date(), widgetData: Array(repeating: JSONModel(date: 0, units: 0), count: 6))
        return loadingData
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Model) -> Void) {
//        initial snapshot
//        or loading type content...
        let loadingData = Model(date: Date(), widgetData: Array(repeating: JSONModel(date: 0, units: 0), count: 6))
        completion(loadingData)
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Model>) -> Void) {
//        parsing json data and displayng
        
        GetData { (modelData) in
            let date = Date()
            let data = Model(date: date, widgetData: modelData)
//            creating TimeLine
//            reloading data every 15 minute
            let nextUpdate = Calendar.current.date(byAdding: .minute,value: 15, to: date)
            let timeline = Timeline(entries: [data], policy: .after(nextUpdate!))
            completion(timeline)
        }
    }
}
//attaching completion handler to send back data...
func GetData(competiton : @escaping ([JSONModel]) -> () ){
    let url = "https://canvasjs.com/data/gallery/javascript/daily-sales-data.json"
    let session = URLSession(configuration: .default)
    session.dataTask(with: URL(string: url)!) { (data, _, error) in
        if error != nil{
            print(error!.localizedDescription)
            return
        }
        do{
            let jsonData = try JSONDecoder().decode([JSONModel].self, from: data!)
            competiton(jsonData)
            
        }catch{
            print(error.localizedDescription)
        }
    }.resume()
}

//Creazione View for Widget
struct WidgetView: View {
    var data : Model
//    picing colors
    var colors = [Color.red,Color.yellow,Color.red,Color.blue,Color.green,Color.pink,Color.purple]
    var body: some View{
        VStack(alignment: .leading, spacing: 15){
//            displaying date of update
            HStack(spacing: 15) {
                Text("Units Sold")
                    .font(.title)
                    .fontWeight(.bold)
                Text(Date(),style: .time)
                    .font(.caption2)
            }
            .padding()
            HStack(spacing:15){
                ForEach(data.widgetData,id: \.self){ value in
                    if value.units == 0 && value.date == 0 {
//                        data is loading...
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.gray)
                    }else{
//                        data view
                        VStack(spacing:15){
                            Text("\(value.units)")
                                .fontWeight(.bold)
//                            Graph
                            GeometryReader{g in
                                VStack{
                                    Spacer(minLength: 0)
                                    
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(colors.randomElement()!)
//                                    calculating height
                                        .frame(height: getHeight(value: CGFloat(value.units), height: g.frame(in: .global).height))
                                }
                            }
                            
//                            date
                            Text(GetData(value: value.date))
                                .font(.caption2)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    func getHeight(value: CGFloat,height: CGFloat)-> CGFloat {
//        alcuni calcoli base..
        let max = data.widgetData.max { (first, second) -> Bool in
            if first.units > second.units{return false}
            else{return true}
        }
        let percent = value / CGFloat(max!.units)
        return percent * height
    }
    
    func GetData(value : CGFloat) -> String {
        let format = DateFormatter()
        format.dateFormat = "MM dd"
//        since its in millisecond
        let date = Date(timeIntervalSince1970: Double(value) / 1000.0)
        return format.string(from: date)
        
    }
}
//Widget Configuration...
@main
struct MainWidget: Widget {
    var body: some WidgetConfiguration{
        StaticConfiguration(kind: "Graph", provider: Provider()) { data in
            WidgetView(data: data)
        }
//        you can use anything
        .description(Text("Daily Status"))
        .configurationDisplayName(Text("Daily Updates"))
        .supportedFamilies([.systemLarge])
    }
}
