import VisualAppBase
import CustomGraphicsMath

public class DefaultThemeProvider: ConfigProvider {
    public enum Mode {
        case Light, Dark
    }
    
    public var mode: Mode

    public var primaryColor: Color

    public init(mode: Mode, primaryColor: Color, @WidgetBuilder child childBuilder: @escaping () -> Widget) {
        let backgroundColor: Color = mode == .Light ? Color.White : Color.Grey

        self.mode = mode
        self.primaryColor = primaryColor

        super.init(configs: [
            TextField.PartialConfig(
                backgroundConfig: Background.Config(
                    fill: backgroundColor,
                    shape: Background.Shape.RoundedRectangle(CornerRadii(all: 24)))
            ),
            TextInput.PartialConfig(
                caretColor: primaryColor
            ),
            Button.PartialConfig {
                $0.normalStyle {
                    $0.backgroundConfig {
                        $0.fill = primaryColor
                        $0.shape = .Rectangle
                    }
                    $0.textConfig = Text.PartialConfig(transform: TextTransform.Lowercase, color: Color(255, 255, 0, 255))
                }
                    
                $0.hoverStyle {
                    $0.backgroundConfig {
                        $0.fill = primaryColor.adjusted(alpha: 140)
                        $0.shape = .Rectangle
                    }
                    $0.textConfig = Text.PartialConfig(color: .White)
                }

                $0.activeStyle {
                    $0.backgroundConfig {
                        $0.fill = primaryColor.adjusted(alpha: 60)
                        $0.shape = .Rectangle
                    }
                    $0.textConfig = Text.PartialConfig(color: .White)
                }
            }
        ], child: childBuilder)
    }
}