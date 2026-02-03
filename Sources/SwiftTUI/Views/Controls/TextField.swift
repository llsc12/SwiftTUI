import Foundation

public struct TextField: View, PrimitiveView {

  public let placeholder: String?
  public let initialValue: String?
  public let action: (String) -> Void
  public let update: ((String) -> Void)?
  
  // scoped modifiers
  private var disableAction: Bool = false
  
  public func disableAction(_ disable: Bool = true) -> TextField {
	var copy = self
	copy.disableAction = disable
	return copy
  }
  
  // end

  @Environment(\.placeholderColor) private var placeholderColor: Color

  public init(
    placeholder: String? = nil,
    initialValue: String? = nil,
    action: @escaping (String) -> Void,
    update: ((String) -> Void)? = nil
  ) {
    self.placeholder = placeholder
    self.initialValue = initialValue
    self.action = action
    self.update = update
  }

  static var size: Int? { 1 }

  func buildNode(_ node: Node) {
    setupEnvironmentProperties(node: node)
    node.control = TextFieldControl(
      placeholder: placeholder ?? "",
      placeholderColor: placeholderColor,
      initialValue: initialValue ?? "",
      action: action,
      update: update,
	  disableAction: disableAction
    )
  }

  func updateNode(_ node: Node) {
    setupEnvironmentProperties(node: node)
    node.view = self
    (node.control as! TextFieldControl).action = action
  }

  private class TextFieldControl: Control {
    var placeholder: String
    var placeholderColor: Color
    var action: (String) -> Void
    var update: ((String) -> Void)?
    var text: String = ""
	var disableAction: Bool = false

    init(
      placeholder: String,
      placeholderColor: Color,
      initialValue: String,
      action: @escaping (String) -> Void,
      update: ((String) -> Void)?,
	  disableAction: Bool = false
    ) {
      self.placeholder = placeholder
      self.placeholderColor = placeholderColor
      self.text = initialValue
      self.action = action
      self.update = update
	  self.disableAction = disableAction
    }

    override func size(proposedSize: Size) -> Size {
      return Size(
        width: Extended(max(text.count, placeholder.count)) + 1,
        height: 1
      )
    }

    override func handleEvent(_ char: Character) {
      //			defer { update?(text) } // we don't want update after action

      if char == "\n" {
		guard !disableAction else { return }
        update?(text)
        action(text)
        self.text = ""
        layer.invalidate()
        return
      }

      if char == ASCII.DEL {
        if !self.text.isEmpty {
          self.text.removeLast()
          update?(text)
          layer.invalidate()
        }
        return
      }

      self.text += String(char)
      layer.invalidate()
      update?(text)
    }

    override func cell(at position: Position) -> Cell? {
      guard position.line == 0 else { return nil }
      if text.isEmpty {
        if position.column.intValue < placeholder.count {
          let showUnderline =
            (position.column.intValue == 0) && isFirstResponder
          let char = placeholder[
            placeholder.index(
              placeholder.startIndex,
              offsetBy: position.column.intValue
            )
          ]
          return Cell(
            char: char,
            foregroundColor: placeholderColor,
            attributes: CellAttributes(underline: showUnderline)
          )
        }
        return .init(char: " ")
      }
      if position.column.intValue == text.count, isFirstResponder {
        return Cell(char: " ", attributes: CellAttributes(underline: true))
      }
      guard position.column.intValue < text.count else {
        return .init(char: " ")
      }
      return Cell(
        char: text[
          text.index(text.startIndex, offsetBy: position.column.intValue)
        ]
      )
    }

    override var selectable: Bool { true }

    override func becomeFirstResponder() {
      super.becomeFirstResponder()
      layer.invalidate()
    }

    override func resignFirstResponder() {
      super.resignFirstResponder()
      layer.invalidate()
    }
  }
}

extension EnvironmentValues {
  public var placeholderColor: Color {
    get { self[PlaceholderColorEnvironmentKey.self] }
    set { self[PlaceholderColorEnvironmentKey.self] = newValue }
  }
}

private struct PlaceholderColorEnvironmentKey: EnvironmentKey {
  static var defaultValue: Color { .default }
}
