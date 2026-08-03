import Foundation

public enum TailnetSelectionReconciler {
    public static func selectedNodeID(
        savedTarget: TailnetTarget?,
        currentNodeID: String?,
        devices: [TailnetDevice]
    ) -> String? {
        if let savedTarget {
            let matchedDevice = devices.first {
                $0.id == savedTarget.nodeID
            } ?? devices.first {
                $0.dnsName?.caseInsensitiveCompare(
                    savedTarget.dnsName
                ) == .orderedSame
            }
            return matchedDevice?.id
        }
        guard let currentNodeID,
              devices.contains(where: { $0.id == currentNodeID })
        else {
            return nil
        }
        return currentNodeID
    }
}
