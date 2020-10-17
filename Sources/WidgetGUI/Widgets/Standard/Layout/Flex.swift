import CustomGraphicsMath
import VisualAppBase

public class Flex: Widget {

  private let orientation: Orientation
  private let crossAlignment: CrossAlignment
  private let mainAxisVectorIndex: Int
  private let crossAxisVectorIndex: Int
  private let spacing: Double
  private let wrap: Bool

  private let buildItems: () -> [Item]
  private var items: [Item] = []
  private var lines: [Line] = []

  // TODO: default of crossAlignment = .Stretch slows down computation right now. optimize or change default
  public init(
    orientation: Orientation, crossAlignment: CrossAlignment = .Stretch, spacing: Double = 0,
    wrap: Bool = false, @Flex.ItemBuilder items buildItems: @escaping () -> [Item]
  ) {
    self.orientation = orientation
    self.crossAlignment = crossAlignment

    switch orientation {
    case .Row:
      mainAxisVectorIndex = 0
      crossAxisVectorIndex = 1

    case .Column:
      mainAxisVectorIndex = 1
      crossAxisVectorIndex = 0
    }

    self.buildItems = buildItems
    self.spacing = spacing
    self.wrap = wrap

    super.init()
  }

  /*private func getMainAxisDimension<VectorProtocol: Vector2Protocol>(_ vector: VectorProtocol) -> Double where VectorProtocol.Element == Double {

        return vector.x
    }

    private func getCrossAxisDimension<VectorProtocol: Vector2Protocol>(_ vector: VectorProtocol) -> Double where VectorProtocol.Element == Double {

        return vector.y
    }*/

  override public func build() {
    items = buildItems()
    children = items.map {
      $0.content
    }
  }

  // TODO: maybe have box config inside the Widget and then let the parent give the child constraints
  // or maybe one dimension and then the child should decide how to set up the other direction
  override public func getBoxConfig() -> BoxConfig {
    var config = BoxConfig(preferredSize: .zero, minSize: .zero, maxSize: .zero)

    for (index, item) in items.enumerated() {
      let content = item.content
      let contentConfig = content.boxConfig
      let spaceAfter = index < items.count - 1 ? spacing : 0.0

      config.preferredSize[mainAxisVectorIndex] += contentConfig.preferredSize[mainAxisVectorIndex] + spaceAfter
      if config.preferredSize[crossAxisVectorIndex]
        < contentConfig.preferredSize[crossAxisVectorIndex]
      {
        config.preferredSize[crossAxisVectorIndex] =
          contentConfig.preferredSize[crossAxisVectorIndex]
      }

      config.minSize[mainAxisVectorIndex] += contentConfig.minSize[mainAxisVectorIndex] + spaceAfter
      if config.minSize[crossAxisVectorIndex] < contentConfig.minSize[crossAxisVectorIndex] {
        config.minSize[crossAxisVectorIndex] = contentConfig.minSize[crossAxisVectorIndex]
      }

      config.maxSize[mainAxisVectorIndex] += contentConfig.maxSize[mainAxisVectorIndex] + spaceAfter
      if config.maxSize[crossAxisVectorIndex] < contentConfig.maxSize[crossAxisVectorIndex] {
        config.maxSize[crossAxisVectorIndex] = contentConfig.maxSize[crossAxisVectorIndex]
      }
    }

    return config
  }

  // TODO: might create an extra, simpler function that is faster for non-wrapping Flex layouts
  override public func performLayout(constraints: BoxConstraints) -> DSize2 {
    lines = [
      Line(crossAxisStart: 0)
    ]

    var needSecondsPass = false
    var mainAxisSize = constraints.minSize[mainAxisVectorIndex]
    var mainAxisPosition = 0.0

    for item in items {
      let crossAlignment = item.crossAlignment ?? self.crossAlignment

      if !needSecondsPass {
        needSecondsPass =
          crossAlignment == .Center || crossAlignment == .End || crossAlignment == .Stretch
          || item.grow > 0
      }

      let content = item.content
      let contentBoxConfig = content.boxConfig
      let freeMainAxisSpace = constraints.maxSize[mainAxisVectorIndex] - mainAxisPosition
      let freeCrossAxisSpace =
        constraints.maxSize[crossAxisVectorIndex] - lines.last!.crossAxisStart
      var contentConstraints = BoxConstraints(
        minSize: .zero,
        maxSize: .infinity
      )

      switch orientation {
      case .Row:
        contentConstraints.maxSize = DSize2(freeMainAxisSpace, freeCrossAxisSpace)
      case .Column:
        contentConstraints.maxSize = DSize2(freeCrossAxisSpace, freeMainAxisSpace)
      }

      var preferredMainAxisSize = contentBoxConfig.preferredSize[mainAxisVectorIndex]

      var explicitMainAxisSizeValue: Double? = nil
      if let explicitMainAxisSize = item.getMainAxisSize(orientation) {
        switch explicitMainAxisSize {
        case let .Pixels(value):
          explicitMainAxisSizeValue = value
        case let .Percent(value):
          explicitMainAxisSizeValue = constraints.maxSize[mainAxisVectorIndex] * value / 100
        }

        contentConstraints.maxSize[mainAxisVectorIndex] = explicitMainAxisSizeValue!

        if explicitMainAxisSizeValue!.isFinite {
          preferredMainAxisSize = explicitMainAxisSizeValue!
          contentConstraints.minSize[mainAxisVectorIndex] = explicitMainAxisSizeValue!
        }
      }

      mainAxisPosition += item.getMainAxisStartMargin(orientation)

      // + 1 at the end to account for floating point precision errors
      if wrap
        && mainAxisPosition + preferredMainAxisSize >= constraints.maxSize[mainAxisVectorIndex] + 1
      {
        // TODO: maybe only do this if shrink is set to some value > 0
        if contentBoxConfig.minSize[mainAxisVectorIndex] > freeMainAxisSpace {
          mainAxisPosition = item.getMainAxisStartMargin(orientation)

          if explicitMainAxisSizeValue == nil {
            contentConstraints.maxSize[mainAxisVectorIndex] =
              constraints.maxSize[mainAxisVectorIndex]
          }

          contentConstraints.maxSize[crossAxisVectorIndex] =
            constraints.maxSize[crossAxisVectorIndex] - lines.last!.crossAxisStart
            - lines.last!.size[crossAxisVectorIndex]
          lines.append(
            Line(
              crossAxisStart: lines.last!.crossAxisStart + lines.last!.size[crossAxisVectorIndex]))
        }
      }

      if item.grow > 0 {
        // this is currently a hack to avoid the child skipping layouting
        // when the current constraints equal the past constraints
        // if not doing this, the child will simply return it's current size
        // since nothing has changed
        // but since the child's size was grown, it should be recalculated because
        // other items might have changed
        // there is probably a more clever / optimized way to do this
        content.previousConstraints = nil
      }
      
      content.layout(constraints: contentConstraints)
      content.position[mainAxisVectorIndex] = mainAxisPosition
      content.position[crossAxisVectorIndex] =
        lines.last!.crossAxisStart + item.getCrossAxisStartMargin(orientation)

      mainAxisPosition +=
        content.bounds.size[mainAxisVectorIndex] + item.getMainAxisEndMargin(orientation)

      lines[lines.count - 1].totalGrow += Double(item.grow)
      lines[lines.count - 1].items.append(item)
      lines[lines.count - 1].size[mainAxisVectorIndex] = mainAxisPosition

      let marginedCrossAxisItemSize =
        content.bounds.size[crossAxisVectorIndex] + item.getCrossAxisStartMargin(orientation)
        + item.getCrossAxisEndMargin(orientation)
      if marginedCrossAxisItemSize > lines.last!.size[crossAxisVectorIndex] {
        lines[lines.count - 1].size[crossAxisVectorIndex] = marginedCrossAxisItemSize
      }

      if mainAxisPosition > mainAxisSize {
        mainAxisSize = mainAxisPosition
      }

      if wrap && constraints.maxSize[mainAxisVectorIndex] < mainAxisPosition {
        mainAxisPosition = 0
        lines.append(
          Line(crossAxisStart: lines.last!.crossAxisStart + lines.last!.size[crossAxisVectorIndex]))
      } else {
        mainAxisPosition += spacing
      }
    }

    // TODO: maybe split up the min size over all lines when there is more than one line
    if lines.count == 1 {
      if lines[0].size[crossAxisVectorIndex] < constraints.minSize[crossAxisVectorIndex] {
        lines[0].size[crossAxisVectorIndex] = constraints.minSize[crossAxisVectorIndex]
      }
    }

    if needSecondsPass {
      // second pass through all lines
      for index in 0..<lines.count {
        var line = lines[index]
        var mainAxisPosition = 0.0

        let mainAxisGrowSpace = mainAxisSize - line.size[mainAxisVectorIndex]

        if index > 0 {
          line.crossAxisStart =
            lines[index - 1].crossAxisStart + lines[index - 1].size[crossAxisVectorIndex]
        }

        // pass through items in line, grow rest free space, apply CrossAlignment
        for item in line.items {
          let content = item.content
          var newConstraints = BoxConstraints(
            minSize: content.bounds.size,
            maxSize: content.bounds.size
          )

          var relayout = false

          mainAxisPosition += item.getMainAxisStartMargin(orientation)
          content.position[mainAxisVectorIndex] = mainAxisPosition

          if item.grow > 0 {
            let itemGrow = mainAxisGrowSpace * (item.grow / line.totalGrow)
            newConstraints.minSize[mainAxisVectorIndex] =
              content.bounds.size[mainAxisVectorIndex] + itemGrow
            newConstraints.maxSize[mainAxisVectorIndex] =
              content.bounds.size[mainAxisVectorIndex] + itemGrow
            relayout = true
          }

          let crossAlignment = item.crossAlignment ?? self.crossAlignment

          switch crossAlignment {
          case .Center:
            let marginedCrossAxisItemSize =
              content.bounds.size[crossAxisVectorIndex] + item.getCrossAxisStartMargin(orientation)
              + item.getCrossAxisEndMargin(orientation)
            content.position[crossAxisVectorIndex] =
              line.crossAxisStart + line.size[crossAxisVectorIndex] / 2 - marginedCrossAxisItemSize
              / 2

          case .Stretch:
            newConstraints.minSize[crossAxisVectorIndex] = line.size[crossAxisVectorIndex]
            newConstraints.maxSize[crossAxisVectorIndex] = line.size[crossAxisVectorIndex]
            relayout = true

          default:
            break
          }

          if relayout {
            // saving and storing the previousConstraints is a hack currently to
            // let the content change it's size according to the real constraints
            // it obtained above,
            // TODO: might introduce a separate property on Widget like: parentConstraints / mainConstraints
            // which can be used by the widget itself to determine how much it can grow on content change
            let previousConstraints = content.previousConstraints
            content.layout(constraints: newConstraints)
            content.previousConstraints = previousConstraints
          }

          mainAxisPosition +=
            content.bounds.size[mainAxisVectorIndex] + item.getMainAxisEndMargin(orientation)

          if content.bounds.size[crossAxisVectorIndex] > line.size[crossAxisVectorIndex] {
            line.size[crossAxisVectorIndex] = content.bounds.size[crossAxisVectorIndex]
          }

          if mainAxisPosition > line.size[mainAxisVectorIndex] {
            line.size[mainAxisVectorIndex] = mainAxisPosition
          }

          if mainAxisPosition > mainAxisSize {
            mainAxisSize = mainAxisPosition
          }

          mainAxisPosition += spacing
        }
        lines[index] = line
      }
    }

    switch orientation {
    case .Row:
      return constraints.constrain(
        DSize2(mainAxisSize, lines.last!.crossAxisStart + lines.last!.size[crossAxisVectorIndex]))
    case .Column:
      return constraints.constrain(
        DSize2(lines.last!.crossAxisStart + lines.last!.size[crossAxisVectorIndex], mainAxisSize))
    }
  }
}

extension Flex {

  public enum Orientation {
    case Row, Column
  }

  public enum CrossAlignment {
    case Start, Center, End, Stretch
  }

  private struct Line {
    public var crossAxisStart: Double
    public var size: DSize2 = .zero
    public var items: [Item] = []
    public var totalGrow: Double = 0
  }

  public struct Item {
    public enum FlexValue {
      case Pixels(_ value: Double)
      case Percent(_ value: Double)
    }

    var grow: Double
    var crossAlignment: CrossAlignment?
    var content: Widget
    var width: FlexValue?
    var height: FlexValue?
    var margins: Margins

    public init(
      grow: Double = 0,
      crossAlignment: CrossAlignment? = nil,
      width: FlexValue? = nil,
      height: FlexValue? = nil,
      margins: Margins = Margins(all: 0),
      @WidgetBuilder content contentBuilder: @escaping () -> Widget
    ) {
      self.grow = grow
      self.crossAlignment = crossAlignment
      self.width = width
      self.height = height
      self.margins = margins
      self.content = contentBuilder()
    }

    public func getMainAxisSize(_ orientation: Orientation) -> FlexValue? {
      switch orientation {
      case .Row:
        return width
      case .Column:
        return height
      }
    }

    public func getCrossAxisSize(_ orientation: Orientation) -> FlexValue? {
      switch orientation {
      case .Row:
        return height
      case .Column:
        return width
      }
    }

    public func getMainAxisStartMargin(_ orientation: Orientation) -> Double {
      switch orientation {
      case .Row:
        return margins.left
      case .Column:
        return margins.top
      }
    }

    public func getMainAxisEndMargin(_ orientation: Orientation) -> Double {
      switch orientation {
      case .Row:
        return margins.right
      case .Column:
        return margins.bottom
      }
    }

    public func getCrossAxisStartMargin(_ orientation: Orientation) -> Double {
      switch orientation {
      case .Row:
        return margins.top
      case .Column:
        return margins.left
      }
    }

    public func getCrossAxisEndMargin(_ orientation: Orientation) -> Double {
      switch orientation {
      case .Row:
        return margins.bottom
      case .Column:
        return margins.right
      }
    }
  }

  @_functionBuilder
  public struct ItemBuilder {
    public static func buildExpression(_ widget: Widget) -> [Flex.Item] {
      [Flex.Item { widget }]
    }

    public static func buildExpression(_ widgets: [Widget]) -> [Flex.Item] {
      widgets.map { widget in Flex.Item { widget } }
    }

    public static func buildExpression(_ item: Flex.Item) -> [Flex.Item] {
      [item]
    }

    public static func buildExpression(_ items: [Flex.Item]) -> [Flex.Item] {
      items
    }

    public static func buildExpression(_ items: [[Flex.Item]]) -> [Flex.Item] {
      items.flatMap { $0 }
    }

    public static func buildOptional(_ items: [Flex.Item]?) -> [Flex.Item] {
      return items ?? []
    }

    public static func buildBlock(_ items: [Flex.Item]...) -> [Flex.Item] {
      items.flatMap { $0 }
    }

    public static func buildBlock(_ items: [[Flex.Item]]) -> [Flex.Item] {
      items.flatMap { $0 }
    }
  }
}
