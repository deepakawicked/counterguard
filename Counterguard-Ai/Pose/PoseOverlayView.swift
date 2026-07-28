//
//  PoseOverlayView.swift
//  Counterguard-Ai
//
//  Created by L0011240 DTF on 2026-07-21.
//



import SwiftUI
import Vision

struct PoseOverlayView: View {
    let joints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
    let connections: [BodyConnection]
    var confidenceThreshold: Float = 0.3

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            Canvas { context, _ in
                // Helper to convert normalized Vision coordinates (bottom-left origin)
                // into SwiftUI View coordinates (top-left origin)
                func convert(_ point: CGPoint) -> CGPoint {
                    CGPoint(
                        x: point.x * size.width,
                        y: (1.0 - point.y) * size.height
                    )
                }

                // 1. Draw Skeleton Connection Lines (Bones)
                for connection in connections {
                    if let jointA = joints[connection.from], jointA.confidence >= confidenceThreshold,
                       let jointB = joints[connection.to], jointB.confidence >= confidenceThreshold {
                        
                        let p1 = convert(jointA.location)
                        let p2 = convert(jointB.location)

                        var path = Path()
                        path.move(to: p1)
                        path.addLine(to: p2)

                        context.stroke(
                            path,
                            with: .color(Color.green.opacity(0.85)),
                            lineWidth: 3
                        )
                    }
                }

                // 2. Draw Joint Keypoints (Nodes)
                for (_, joint) in joints where joint.confidence >= confidenceThreshold {
                    let point = convert(joint.location)
                    let nodeRect = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)

                    context.fill(Path(ellipseIn: nodeRect), with: .color(.white))
                    context.stroke(Path(ellipseIn: nodeRect), with: .color(.green), lineWidth: 1.5)
                }
            }
        }
    }
}
