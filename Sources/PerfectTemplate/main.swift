//
//  main.swift
//  PerfectTemplate
//
//  Created by Kyle Jessup on 2015-11-05.
//    Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectHTTP
import PerfectHTTPServer

// An example request handler.
// This 'handler' function can be referenced directly in the configuration below.
func handler(request: HTTPRequest, response: HTTPResponse) {
    // Respond with a simple message.
    response.setHeader(.contentType, value: "text/html")
    response.appendBody(string: "<html><title>Hello, world!</title><body>Hello, world!</body></html>")
    // Ensure that response.completed() is called when your processing is done.
    response.completed()
}

// Configure one server which:
//    * Serves the hello world message at <host>:<port>/
//    * Serves static files out of the "./webroot"
//        directory (which must be located in the current working directory).
//    * Performs content compression on outgoing data when appropriate.
var routes = Routes()

routes.add(method: .get, uri: "/", handler: handler)

//routes.add(method: .get, uri: "/**",
//           handler: StaticFileHandler(documentRoot: "./webroot", allowResponseFilters: true).handleRequest)

func echoHandler(request: HTTPRequest, _ response: HTTPResponse) {
    response.appendBody(string: "Echo handler: You accessed path \(request.path) with variables \(request.params())")
    response.completed()
}





//
//  RosreestrModels.swift
//  COpenSSL
//
//  Created by Никита Краснов on 09.05.2020.
//

import Foundation

// MARK: - ItemModel
class ItemModel: Decodable {
    let total: Int
    let features: [Feature]
    let totalRelation: String?

    init(total: Int, features: [Feature], totalRelation: String) {
        self.total = total
        self.features = features
        self.totalRelation = totalRelation
    }
}

// MARK: - Feature
class Feature: Decodable {
    let center: Center
    let extent: Extent
    let type, sort: Int
    let attrs: Attrs

    init(center: Center, extent: Extent, type: Int, sort: Int, attrs: Attrs) {
        self.center = center
        self.extent = extent
        self.type = type
        self.sort = sort
        self.attrs = attrs
    }
}

// MARK: - Attrs
class Attrs: Decodable {
    let address, cn, id: String

    init(address: String, cn: String, id: String) {
        self.address = address
        self.cn = cn
        self.id = id
    }
}

// MARK: - Center
class Center: Decodable {
    let y, x: Double

    init(y: Double, x: Double) {
        self.y = y
        self.x = x
    }
}

// MARK: - Extent
class Extent: Decodable {
    let ymax, xmin, xmax, ymin: Double

    init(ymax: Double, xmin: Double, xmax: Double, ymin: Double) {
        self.ymax = ymax
        self.xmin = xmin
        self.xmax = xmax
        self.ymin = ymin
    }
}

class ModelExtent: Decodable {
    let feature: ModelFeature

    init(feature: ModelFeature) {
        self.feature = feature
    }
}

// MARK: - Feature
class ModelFeature: Decodable {
    let type: Int
    let attrs: ModelAttrs?
    let center: Center?

    init(type: Int, attrs: ModelAttrs, center: Center) {
        self.type = type
        self.attrs = attrs
        self.center = center
    }
}

// MARK: - Attrs
class ModelAttrs: Decodable {
    let id, name, address: String?
    let cadCost: Double?
    let oksType: String?
    let area_value: Double

    init(id: String, name: String, address: String, cadCost: Double, oksType: String, areaValue: Double) {
        self.id = id
        self.name = name
        self.address = address
        self.cadCost = cadCost
        self.oksType = oksType
        self.area_value = areaValue
    }
}

struct ResponseBody {

    var isInterest: Bool

    var expectedArea: Double
    var similarArea: Double?

    var amount: Double?

    var lat, lon: Double

    var bodyDescription: String {
        var str: String = ""

        if isInterest {
            str.append(contentsOf: "Данный объект вызывает инетерес, по скольку есть вреоятность, что он не зарегистрирован\n")
            if let ar = similarArea {
                str.append(contentsOf: "Предполагаемая площадь дома = \(expectedArea) кв.м\n")
                str.append(contentsOf: "Рядом были найдены дома с похожей площадью (\(ar) кв.м, необходимо уточнение\n")
            } else {
                str.append(contentsOf: "Предполагаемая площадь дома = \(expectedArea) кв.м\n")
            }

            str.append(contentsOf: "Координаты: \nШирота: \(lat)\nДолгота:  \(lon)")
        } else {
            str.append(contentsOf: "Мы нашли совпадение с реестром по этим координатам и заданной площади, объект не вызывает инетереса")
        }

        return str
    }
}


class NetworkManager {

    static var shared: NetworkManager {
        return NetworkManager()
    }

    func requestItemsByCoord(lan: Double, lon: Double, completion: @escaping (ItemModel?) -> ()) {
        request(lan: lan, lon: lon, completion: completion)
    }

    private func request(lan: Double, lon: Double, completion: @escaping (ItemModel?) -> ()) {

        URLSession(configuration: .default)
            .dataTask(with: itemsUrl(lan: lan, lon: lon), completionHandler: { data, response, error in
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }

                var items = ItemModel(total: 0, features: [], totalRelation: "")

                do {
                    items = try JSONDecoder().decode(ItemModel.self, from: data)
                } catch {
                    completion(nil)
                    return
                }

                completion(items)
            })
            .resume()
    }

    func requestAdditionalInfo(for id: String, completion: @escaping (ModelExtent?)->()) {

        URLSession(configuration: .default)
        .dataTask(with: itemDesc(id: id), completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            let items: ModelExtent
            do {
                items = try JSONDecoder().decode(ModelExtent.self, from: data)
            } catch {
                print(error)
                completion(nil)
                return
            }

            completion(items)
        })
        .resume()
    }

    private func itemsUrl(lan: Double, lon: Double) -> URL {
        guard let url = URL(string: "https://pkk.rosreestr.ru/api/features/5") else {
            fatalError()
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        components?.queryItems = []

        components?.queryItems?.append(URLQueryItem(name: "text", value: "\(lan)+\(lon)"))
        components?.queryItems?.append(URLQueryItem(name: "limit", value: "40"))
        components?.queryItems?.append(URLQueryItem(name: "skip", value: "0"))
        components?.queryItems?.append(URLQueryItem(name: "inPoint", value: "false"))

        guard let ret = components?.url else {
            fatalError()
        }

        return ret
    }

    private func itemDesc(id: String) -> URL {
        guard let url = URL(string: "https://pkk.rosreestr.ru/api/features/5") else {
            fatalError()
        }

        return url.appendingPathComponent(id)
    }
}

class InfoHandler {

    private var currentRequestModels = [ModelExtent]()

    func handleRequest(request: HTTPRequest, _ response: HTTPResponse) {

        response.setHeader(.contentType, value: "text/html")
        currentRequestModels = []

        guard request.method == .get else {
            return
        }

        if let lat = request.param(name: "lat"),
            let lon = request.param(name: "lon"),
            let sq = request.param(name: "sq"),
            let latParam = Double(lat),
            let lonParam = Double(lon),
            let square = Double(sq)
        {
            requestInfoFromRkk(lat: latParam, lon: lonParam, area: square, response: response)
        } else {
            response.appendBody(string: "Invalid Request")
            response.completed(status: .badRequest)
        }
    }

    private func requestInfoFromRkk(lat: Double, lon: Double, area: Double, response: HTTPResponse) {
        NetworkManager.shared.requestItemsByCoord(lan: lat, lon: lon, completion: { [weak self] in
            self?.handleLogic(lon: lon, lat: lat, model: $0, area: area, response: response)
        })
    }

    private func requestExtent(for id: String, group: DispatchGroup, completion: @escaping (ModelExtent) -> ()) {
        group.enter()
        NetworkManager.shared.requestAdditionalInfo(for: id, completion: { model in
            guard let model = model else {
                group.leave()
                return
            }

            completion(model)
            group.leave()
        })
    }

    private func sendResponse(with body: ResponseBody, responce: HTTPResponse) {
        responce.setHeader(.contentType, value: "text/html; charset=utf-8")
        responce.appendBody(string: "<html><title>Данные по </title><body>\(body.bodyDescription.utf8)</body></html>")
        responce.completed()
    }

    private func handleLogic(lon: Double, lat: Double, model: ItemModel?, area: Double, response: HTTPResponse) {
        guard let model = model, model.features.count > 0 else {
            sendResponse(with: .init(isInterest: true,
                                     expectedArea: area,
                                     similarArea: nil,
                                     amount: nil,
                                     lat: lat,
                                     lon: lon),
                         responce: response)
            return
        }

        let group = DispatchGroup()

        model.features.forEach {
            requestExtent(for: $0.attrs.id, group: group, completion: { [weak self] in
                self?.currentRequestModels.append($0)
            })
        }

        group.notify(queue: DispatchQueue.global(qos: .default), execute: { [weak self] in
            self?.compareObjectAndAnswer(lon: lon, lat: lat, area: area, response: response)
        })
    }

    private func compareObjectAndAnswer(lon: Double, lat: Double, area: Double, response: HTTPResponse) {
        guard currentRequestModels.count > 0 else {
            sendResponse(with: .init(isInterest: true,
                                     expectedArea: area,
                                     similarArea: nil,
                                     amount: nil,
                                     lat: lat,
                                     lon: lon),
                         responce: response)
            return
        }

        guard area > 50 else {
            sendResponse(with: .init(isInterest: false,
                                     expectedArea: area,
                                     similarArea: nil,
                                     amount: nil,
                                     lat: lat,
                                     lon: lon),
                         responce: response)

            return
        }

        var closestArea: Double = 10000
        var maxChange: Double = 10000

        currentRequestModels.forEach {
            if let ar = $0.feature.attrs?.area_value {
                let div = area / ar * 100

                let change = div > 100 ? div - 100 : 100 - div

                if change < 12 {
                    sendResponse(with: .init(isInterest: false,
                                             expectedArea: area,
                                             similarArea: nil,
                                             amount: nil,
                                             lat: lat,
                                             lon: lon),
                                 responce: response)
                    return
                } else {
                    let currentChange = area > ar ? area - ar : ar - area

                    if currentChange < maxChange {
                        maxChange = currentChange
                        closestArea = ar
                    }
                }
            }
        }

        guard closestArea == 10000 else {
            sendResponse(with: .init(isInterest: true,
                                     expectedArea: area,
                                     similarArea: closestArea,
                                     amount: nil,
                                     lat: lat,
                                     lon: lon),
                         responce: response)

            return
        }

        sendResponse(with: .init(isInterest: false,
                                 expectedArea: area,
                                 similarArea: nil,
                                 amount: nil,
                                 lat: lat,
                                 lon: lon),
                     responce: response)
    }
}

routes.add(method: .get, uri: "/info", handler: InfoHandler().handleRequest(request:_:))

try HTTPServer.launch(name: "localhost",
                      port: 8181,
                      routes: routes,
                      responseFilters: [
                        (PerfectHTTPServer.HTTPFilter.contentCompression(data: [:]), HTTPFilterPriority.high)])
