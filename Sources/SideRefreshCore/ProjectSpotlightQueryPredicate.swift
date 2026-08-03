import Foundation

public enum ProjectSpotlightQueryPredicate {
    public static func make(
        excludingDirectoryURLs: Set<URL>
    ) -> NSPredicate {
        let containerPredicate = NSPredicate(
            format:
                "(%K LIKE[c] %@) OR (%K LIKE[c] %@)",
            NSMetadataItemFSNameKey,
            "*.xcodeproj",
            NSMetadataItemFSNameKey,
            "*.xcworkspace"
        )
        let exclusionPredicates =
            excludingDirectoryURLs.map { url in
                let path = url.standardizedFileURL.path
                return NSPredicate(
                    format:
                        "NOT (%K == %@ OR %K LIKE[c] %@)",
                    NSMetadataItemPathKey,
                    path,
                    NSMetadataItemPathKey,
                    path + "/*"
                )
            }
        guard !exclusionPredicates.isEmpty else {
            return containerPredicate
        }
        return NSCompoundPredicate(
            andPredicateWithSubpredicates:
                [containerPredicate] + exclusionPredicates
        )
    }
}
