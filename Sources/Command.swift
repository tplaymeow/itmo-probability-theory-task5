import Foundation
import Charts
import SwiftUI
import AppKit
import ArgumentParser
import TextTable

@main
struct Command: ParsableCommand {
  @Argument
  var inputFilepath: String

  @Argument
  var outputDirectory: String

  @MainActor
  func run() throws {
    let numbers = try String(contentsOfFile: self.inputFilepath)
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .split(separator: ",")
      .compactMap(Double.init)

    let variationalSeries = numbers
      .sorted()

    print()
    print("Variational series:")
    print(TextTable(variationalSeries.enumerated()) {
      TextTableColumn(title: "i", value: \.offset, format: .number)
      TextTableColumn(title: "x_i", value: \.element, format: .number)
    })

    let statisticalSeries = numbers
      .reduce(into: [:]) { $0[$1, default: 0] += 1 }
      .sorted { $0.key < $1.key }

    print()
    print("Statistical series:")
    print(TextTable(statisticalSeries.enumerated()) {
      TextTableColumn(title: "i", value: \.offset, format: .number)
      TextTableColumn(title: "x_i", value: \.element.key, format: .number)
      TextTableColumn(title: "n_i", value: \.element.value, format: .number)
    })

    guard
      let first = variationalSeries.first,
      let last = variationalSeries.last else { return }
    let range = last - first

    print()
    print("Range:")
    print(range.formatted())

    let expectedValue = statisticalSeries
      .reduce(0) { result, pair in
        let x = pair.key
        let p = Double(pair.value) / Double(numbers.count)
        return result + x * p
      }

    print()
    print("Expected value:")
    print(expectedValue.formatted())

    let dispersion = statisticalSeries
      .reduce(0) { result, pair in
        let x = pair.key
        let p = Double(pair.value) / Double(numbers.count)
        return result + pow(x - expectedValue, 2) * p
      }

    print()
    print("Dispersion:")
    print(dispersion.formatted())

    let standardDeviation = sqrt(dispersion)

    print()
    print("Standard deviation:")
    print(standardDeviation.formatted())

    let intervalsCount = 1 + log2(Double(numbers.count))
    let intervalLength = range / intervalsCount

    print()
    print("Interval length:")
    print(intervalLength.formatted())

    let empiricalDistributionFunctionIntervals = (
      [-Double.infinity] +
      statisticalSeries.map(\.key) +
      [Double.infinity]
    ).pairs()

    let empiricalDistributionFunctionValues = statisticalSeries
      .map(\.value)
      .scan(0, +)
      .map { Double($0) / Double(numbers.count) } + [1.0]

    let empiricalDistributionFunction = Array(zip(
      empiricalDistributionFunctionIntervals,
      empiricalDistributionFunctionValues
    ))

    print()
    print("Empirical distribution function:")
    print(TextTable(empiricalDistributionFunction) {
      TextTableColumn(
        title: "Value",
        value: \.1,
        format: .number)
      TextTableColumn(title: "Condition") {
        "\($0.0.0.formatted()) < x <= \($0.0.1.formatted())"
      }
    })

    let intervalStatisticalSeries = stride(
      from: first - intervalLength / 2,
      through: last + intervalLength / 2,
      by: intervalLength
    )
      .pairs()
      .map(...)
      .reduce(into: [:]) { result, interval in
        result[interval] = numbers.count { interval ~= $0 }
      }
      .sorted {
        $0.key.lowerBound < $1.key.lowerBound
      }

    print()
    print("Interval statistical series:")
    print(TextTable(intervalStatisticalSeries.enumerated()) {
      TextTableColumn(
        title: "i",
        value: \.offset,
        format: .number)
      TextTableColumn(
        title: "x_i from",
        value: \.element.key.lowerBound,
        format: .number)
      TextTableColumn(
        title: "x_i to",
        value: \.element.key.upperBound,
        format: .number)
      TextTableColumn(
        title: "n_i",
        value: \.element.value,
        format: .number)
    })

    self.render(name: "empirical-distribution-function-chart") {
      ForEach(empiricalDistributionFunction, id: \.0.1) { item in
        LineMark(
          x: .value("X", item.0.0),
          y: .value("Y", item.1)
        )
      }
      .interpolationMethod(.stepStart)
    }

    self.render(name: "histogramm") {
      ForEach(intervalStatisticalSeries, id: \.key) { item in
        BarMark(
          x: .value("X", item.key.formatted()),
          y: .value("N", item.value),
          width: .ratio(0.9)
        )
      }
    }

    self.render(name: "polygon") {
      ForEach(intervalStatisticalSeries, id: \.key) { item in
        LineMark(
          x: .value("X", item.key.middle),
          y: .value("N", item.value)
        )
      }
    }
  }
}
