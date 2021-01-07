public protocol ExperimentalStylableWidget: Widget {
  associatedtype StyleKeys: ExperimentalDefaultStyleKeys
}

extension ExperimentalStylableWidget {
  func with(@Experimental.StylePropertiesBuilder styleProperties build: (ExperimentalDefaultStyleKeys.Type) -> [Experimental.StyleProperty]) -> Widget {
    self.experimentalDirectStyleProperties.append(contentsOf: build(StyleKeys.self))
    return self
  }
}