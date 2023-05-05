import Foundation
import SwiftUI
import Charts

// MARK: Sequence extensions

extension Sequence {
  func pairs() -> AnyIterator<(Element, Element)> {
    var iterator = self.makeIterator()
    var last = iterator.next()
    return AnyIterator {
      guard let left = last else {
        return nil
      }
      guard let right = iterator.next() else {
        return nil
      }
      defer {
        last = right
      }
      return (left, right)
    }
  }
}

extension Sequence {
  func count(
    where predicate: (Element) throws -> Bool
  ) rethrows -> Int {
    try self.reduce(0) { partialResult, element in
      try partialResult + (predicate(element) ? 1 : 0)
    }
  }
}

extension Sequence {
  func scan<Result>(
    _ initialResult: Result,
    _ nextPartitialResult: (Result, Element) throws -> Result
  ) rethrows -> [Result] {
    try self.reduce(into: [initialResult]) { partialResult, element in
      let result = partialResult.last ?? initialResult
      let nextResult = try nextPartitialResult(result, element)
      partialResult.append(nextResult)
    }
  }
}

// MARK: - ClosedRange extensions

extension ClosedRange where Bound == Double {
  var middle: Double {
    (self.lowerBound + self.upperBound) / 2
  }
}

// MARK: - ClosedRange Format

extension ClosedRange where Bound == Double {
  func formatted() -> String {
    self.formatted(ClosedRangeFormatStyle(
      bound: .number.precision(.fractionLength(2)),
      separator: " – "
    ))
  }
}

extension ClosedRange {
  func formatted<Format: FormatStyle>(
    _ format: Format
  ) -> Format.FormatOutput where Self == Format.FormatInput {
    format.format(self)
  }
}

struct ClosedRangeFormatStyle<BoundFormatStyle>: FormatStyle
where BoundFormatStyle: FormatStyle,
      BoundFormatStyle.FormatInput: Comparable,
      BoundFormatStyle.FormatOutput == String {
  init(bound: BoundFormatStyle, separator: String) {
    self.boundFormatStyle = bound
    self.separator = separator
  }

  func format(_ value: ClosedRange<BoundFormatStyle.FormatInput>) -> String {
    let lowerBound = self.boundFormatStyle.format(value.lowerBound)
    let upperBound = self.boundFormatStyle.format(value.upperBound)
    return "\(lowerBound)\(self.separator)\(upperBound)"
  }

  private let boundFormatStyle: BoundFormatStyle
  private let separator: String
}

// MARK: - Chart render

extension Command {
  @MainActor
  func render(
    name: String,
    @ChartContentBuilder content: @escaping () -> some ChartContent
  ) {
    let outputURL = URL(fileURLWithPath: self.outputDirectory)
      .appending(path: "\(name).png")

    let marks = AxisMarks() { value in
      AxisGridLine(stroke: StrokeStyle(lineWidth: 1.5))
      AxisValueLabel {
        if let string = value.as(String.self) {
          Text(string).font(.largeTitle)
        }
        if let double = value.as(Double.self) {
          Text(double.formatted()).font(.largeTitle)
        }
      }
    }

    let chart = Chart(content: content)
      .chartYAxis { marks }
      .chartXAxis { marks }
      .frame(width: 1000, height: 500)

    ImageRenderer(content: chart).cgImage
      .map(NSBitmapImageRep.init)
      .flatMap { $0.representation(using: .png, properties: [:]) }
      .flatMap { try? $0.write(to: outputURL) }
  }
}
