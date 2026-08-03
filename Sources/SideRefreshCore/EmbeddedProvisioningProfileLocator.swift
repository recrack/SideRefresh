import Foundation

public enum EmbeddedProvisioningProfileLocator {
    private static let productDirectoryNames = [
        "Products",
        "SideRefreshProducts",
    ]

    public static func profiles(
        inDerivedDataURL derivedDataURL: URL,
        fileManager: FileManager = .default
    ) -> [URL] {
        let buildDirectory = derivedDataURL.appendingPathComponent(
            "Build",
            isDirectory: true
        )
        var seen: Set<URL> = []
        return productDirectoryNames.flatMap { directoryName in
            profiles(
                below: buildDirectory.appendingPathComponent(
                    directoryName,
                    isDirectory: true
                ),
                fileManager: fileManager
            )
        }.filter {
            seen.insert($0.standardizedFileURL).inserted
        }
    }

    private static func profiles(
        below productsURL: URL,
        fileManager: FileManager
    ) -> [URL] {
        let immediateChildren = contents(
            of: productsURL,
            fileManager: fileManager
        )
        let apps = immediateChildren.flatMap { child -> [URL] in
            if child.pathExtension.lowercased() == "app",
               isDirectory(child, fileManager: fileManager)
            {
                return [child]
            }
            guard isDirectory(child, fileManager: fileManager) else {
                return []
            }
            return contents(
                of: child,
                fileManager: fileManager
            ).filter {
                $0.pathExtension.lowercased() == "app"
                    && isDirectory($0, fileManager: fileManager)
            }
        }
        return apps.compactMap { appURL in
            let profileURL = appURL.appendingPathComponent(
                "embedded.mobileprovision"
            )
            return fileManager.fileExists(atPath: profileURL.path)
                ? profileURL
                : nil
        }
    }

    private static func contents(
        of directoryURL: URL,
        fileManager: FileManager
    ) -> [URL] {
        (
            try? fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        ) ?? []
    }

    private static func isDirectory(
        _ url: URL,
        fileManager: FileManager
    ) -> Bool {
        var isDirectory: ObjCBool = false
        return fileManager.fileExists(
            atPath: url.path,
            isDirectory: &isDirectory
        ) && isDirectory.boolValue
    }
}
