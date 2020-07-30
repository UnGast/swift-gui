import VisualAppBase
import CustomGraphicsMath

public class RenderObjectTreeView: Widget {
    private struct Group {
        var parent: Widget?
        var children: [Widget] = []
    }
    
    private struct Line {
        var groups: [Group] = []
    }

    private var debuggingData: RenderObjectTreeRenderer.DebuggingData
    private var selectedObjectPath: TreePath?    
    private var onObjectSelected = EventHandlerManager<(RenderObject, TreePath)>()

    private var groupedChildren: [Line] = []

    public init(
        debuggingData: RenderObjectTreeRenderer.DebuggingData, 
        selectedObjectPath: TreePath?, 
        onObjectSelected objectSelectedHandler: EventHandlerManager<(RenderObject, TreePath)>.Handler?) {
            self.debuggingData = debuggingData
            self.selectedObjectPath = selectedObjectPath
            if let objectSelectedHandler = objectSelectedHandler {
                _ = self.onObjectSelected.addHandler(objectSelectedHandler)
            }
            super.init()
    }

    override open func mount(parent: Parent) {
        var children = [Widget]()
            var currentLineParentIndices = [-2]
            debuggingData.tree.traverseDepth { object, path, index, parentIndex in
                let child = Button(onClick: { _ in
                    try! self.onObjectSelected.invokeHandlers((object, path))
                }) {
                    if path == self.selectedObjectPath {
                        Text("NODE ID Selected!")
                    } else {
                        Text("NODE ID \(index) at PAT \(path)")
                    }
                }
                children.append(child)

                if groupedChildren.count <= path.count {
                    groupedChildren.append(Line())
                    currentLineParentIndices.append(parentIndex)
                }
                if currentLineParentIndices[path.count] != parentIndex {
                    currentLineParentIndices[path.count] = parentIndex
                    var parent: Widget?
                    if path.count > 0 {
                        parent = groupedChildren[path.count - 1].groups.last?.children.last
                    }
                    groupedChildren[path.count].groups.append(Group(parent: parent))
                }
                /*if parentIndex != currentParentIndex {

                }*/

                groupedChildren[path.count].groups[groupedChildren[path.count].groups.count - 1].children.append(child)
                /*child.bounds.topLeft = DPoint2(nextX, nextY)
                nextX += child.bounds.size.width + spacing
                print("Child index", index, "Child Size", child.bounds.size, nextX)*/
            }
            self.children = children
            super.mount(parent: parent)
    }

    override open func layout() {
        var spacing: Double = 30
        var nextX: Double = 0
        var nextY: Double = 0
        var maxX: Double = 0
        var currentLineHeight: Double = 0
        for i in 0..<groupedChildren.count {
            for j in 0..<groupedChildren[i].groups.count {
                for k in 0..<groupedChildren[i].groups[j].children.count {
                    var child = groupedChildren[i].groups[j].children[k]
                    child.constraints = constraints
                    try child.layout()
                    child.bounds.topLeft = DPoint2(nextX, nextY)
                    nextX += child.bounds.size.width + spacing
                    if child.bounds.size.height > currentLineHeight {
                        currentLineHeight = child.bounds.size.height
                    }
                }
                if nextX - spacing > maxX {
                    maxX = nextX - spacing
                }
                nextX += spacing * 4
            }
            nextX = 0
            nextY += currentLineHeight + spacing
            currentLineHeight = 0
        }

        bounds.size = DSize2(maxX, nextY + currentLineHeight)
    }

    override open func renderContent() -> RenderObject? {
        var lines = [RenderObject.LineSegment]()

        for i in 0..<groupedChildren.count {
            for j in 0..<groupedChildren[i].groups.count {
                for k in 0..<groupedChildren[i].groups[j].children.count {
                    let child = groupedChildren[i].groups[j].children[k]
                    if let parent = groupedChildren[i].groups[j].parent {
                        lines.append(RenderObject.LineSegment(from: parent.globalBounds.center, to: child.globalBounds.center))
                    }
                }
            }
        }

        lines.reverse()

        return RenderObject.RenderStyle(fillColor: FixedRenderValue(Color.White)) {
            RenderObject.RenderStyle(strokeWidth: 2, strokeColor: FixedRenderValue(.Black)) {
                lines
            }
            children.map { $0.render() }
        }
    }
}