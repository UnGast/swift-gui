extension Experimental {
  public enum StylePropertyValue<T> {
    case inherit
    case some(T)
  }

  public enum AnyStylePropertyValue {
    case inherit
    case some(Any)

    public init?<T>(_ concreteValue: StylePropertyValue<T>?) {
      if let concreteValue = concreteValue {
        self.init(concreteValue)
      }
      return nil
    }

    public init<T>(_ concreteValue: StylePropertyValue<T>) {
      switch concreteValue {
      case .inherit:
        self = .inherit
      case let .some(value):
        self = .some(value)
      }
    }
  }
}