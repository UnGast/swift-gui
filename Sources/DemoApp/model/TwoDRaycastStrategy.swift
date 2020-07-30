import CustomGraphicsMath
import Foundation

public struct TwoDRaycastStrategy {
    public func cast(in world: TwoDVoxelWorld, from start: AnyVector2<Double>, to end: AnyVector2<Double>) -> TwoDRaycast {
        var results = [TwoDRaycastResult]()
        
        var path = end - start 
        var direction = path.normalized()
        var rayLine = AnyLine(point: start, direction: direction)
        var drivingAxis = direction.abs().firstIndex(of: direction.abs().max()!)!
        var otherAxis = drivingAxis == 0 ? 1 : 0
        var targetSlope = direction[otherAxis] / direction[drivingAxis]
        
        var startIndex = start.rounded(.down)
        var endIndex = end.rounded(.down)
        var currentOffset = DVec2()
        
        var testedOffsets = [DVec2]()
        
        while currentOffset.length < path.length {
            testedOffsets.append(currentOffset)

            for otherAxisOffset in -2...2 {
                var offset = DVec2.zero
                offset[otherAxis] = Double(otherAxisOffset)
                testedOffsets.append(currentOffset + offset)
            }


            //var step = DVec2()
            //step[drivingAxis] = copysign(1, direction[drivingAxis])
            var nextOffset = currentOffset
            nextOffset[drivingAxis] += copysign(1, direction[drivingAxis])
            let slope = nextOffset[otherAxis] / nextOffset[drivingAxis]
            if abs(slope) - abs(targetSlope) < 0 {
                nextOffset[otherAxis] += copysign(1, direction[otherAxis])
            }

            currentOffset = nextOffset
        }

        for offset in testedOffsets {
            let tileIndex = IVec2(startIndex + offset.rounded(.down))
            results.append(.Test(tileIndex: tileIndex))
            
            //let lines = getTileLines(tileIndex: tileIndex)
            let edgeVertices = Tile.edgeVertices(topLeft: DVec2(tileIndex))
            var nearestIntersectedEdge: Tile.Edge?
            var nearestIntersectedEdgeDistance: Double = .infinity
            for edge in Tile.Edge.allCases {
                let vertices = edgeVertices[edge]!
                let line = AnyLine(from: vertices.0, to: vertices.1)
                if let intersection = rayLine.intersect(line: line) {
                    if line.pointBetween(test: intersection, from: vertices.0, to: vertices.1) {
                        results.append(.Intersection(position: intersection))
                        let distance = (intersection - start).length
                        if distance < nearestIntersectedEdgeDistance {
                            nearestIntersectedEdge = edge
                            nearestIntersectedEdgeDistance = distance
                        } 
                    }
                }
            }
            if let edge = nearestIntersectedEdge {
                results.append(.Hit(tileIndex: tileIndex, edge: edge))
            }
        }

        return TwoDRaycast(from: start, to: end, results: results)
    }
}