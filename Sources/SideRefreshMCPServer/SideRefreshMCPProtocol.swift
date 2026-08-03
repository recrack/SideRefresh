import Foundation

public struct SideRefreshMCPProtocolRouter: Sendable {
    public static let protocolVersion = "2025-11-25"

    private let toolHandler: SideRefreshMCPToolHandler

    public init(toolHandler: SideRefreshMCPToolHandler) {
        self.toolHandler = toolHandler
    }

    public func response(to message: Data) -> Data? {
        let request: MCPJSONValue
        do {
            request = try JSONDecoder().decode(
                MCPJSONValue.self,
                from: message
            )
        } catch {
            return encoded(
                errorResponse(
                    id: .null,
                    code: -32700,
                    message: "Parse error"
                )
            )
        }
        guard case .object(let object) = request,
              object["jsonrpc"]?.stringValue == "2.0",
              let method = object["method"]?.stringValue
        else {
            return encoded(
                errorResponse(
                    id: requestID(in: request) ?? .null,
                    code: -32600,
                    message: "Invalid Request"
                )
            )
        }

        let id = object["id"]
        if method.hasPrefix("notifications/") {
            return nil
        }
        guard let id else {
            return nil
        }

        switch method {
        case "initialize":
            return encoded(
                successResponse(
                    id: id,
                    result: .object([
                        "protocolVersion": .string(
                            Self.protocolVersion
                        ),
                        "capabilities": .object([
                            "tools": .object([
                                "listChanged": .bool(false),
                            ]),
                        ]),
                        "serverInfo": .object([
                            "name": .string(SideRefreshMCPServer.name),
                            "title": .string("SideRefresh"),
                            "version": .string(
                                SideRefreshMCPServer.version
                            ),
                            "description": .string(
                                "Headless automatic iOS app refresh control."
                            ),
                        ]),
                        "instructions": .string(
                            "Read status or run dry_run first. State-changing tools require an explicit true confirmation argument."
                        ),
                    ])
                )
            )
        case "ping":
            return encoded(
                successResponse(id: id, result: .object([:]))
            )
        case "tools/list":
            return encoded(
                successResponse(
                    id: id,
                    result: .object([
                        "tools": .array(
                            SideRefreshMCPToolHandler.toolDefinitions
                        ),
                    ])
                )
            )
        case "tools/call":
            return callTool(
                id: id,
                params: object["params"]
            )
        default:
            return encoded(
                errorResponse(
                    id: id,
                    code: -32601,
                    message: "Method not found: \(method)"
                )
            )
        }
    }

    private func callTool(
        id: MCPJSONValue,
        params: MCPJSONValue?
    ) -> Data? {
        guard let params = params?.objectValue,
              let name = params["name"]?.stringValue
        else {
            return encoded(
                errorResponse(
                    id: id,
                    code: -32602,
                    message:
                        "tools/call requires a tool name and object arguments."
                )
            )
        }
        let arguments: [String: MCPJSONValue]
        if let rawArguments = params["arguments"] {
            guard let parsed = rawArguments.objectValue else {
                return encoded(
                    errorResponse(
                        id: id,
                        code: -32602,
                        message:
                            "tools/call arguments must be an object."
                    )
                )
            }
            arguments = parsed
        } else {
            arguments = [:]
        }
        let result = toolHandler.call(
            name: name,
            arguments: arguments
        )
        return encoded(
            successResponse(
                id: id,
                result: .object([
                    "content": .array([
                        .object([
                            "type": .string("text"),
                            "text": .string(result.content),
                        ]),
                    ]),
                    "structuredContent":
                        result.structuredContent,
                    "isError": .bool(result.isError),
                ])
            )
        )
    }

    private func requestID(
        in value: MCPJSONValue
    ) -> MCPJSONValue? {
        value.objectValue?["id"]
    }

    private func successResponse(
        id: MCPJSONValue,
        result: MCPJSONValue
    ) -> MCPJSONValue {
        .object([
            "jsonrpc": .string("2.0"),
            "id": id,
            "result": result,
        ])
    }

    private func errorResponse(
        id: MCPJSONValue,
        code: Int,
        message: String
    ) -> MCPJSONValue {
        .object([
            "jsonrpc": .string("2.0"),
            "id": id,
            "error": .object([
                "code": .int(code),
                "message": .string(message),
            ]),
        ])
    }

    private func encoded(_ value: MCPJSONValue) -> Data? {
        try? value.jsonData()
    }
}

public struct SideRefreshMCPStdioServer: Sendable {
    private let router: SideRefreshMCPProtocolRouter

    public init(router: SideRefreshMCPProtocolRouter) {
        self.router = router
    }

    public func run(
        input: FileHandle = .standardInput,
        output: FileHandle = .standardOutput
    ) throws {
        var pending = Data()
        while true {
            let chunk = input.availableData
            if chunk.isEmpty {
                if !pending.isEmpty {
                    try writeResponse(for: pending, to: output)
                }
                return
            }
            pending.append(chunk)
            while let newline = pending.firstIndex(of: 0x0A) {
                let message = Data(pending[..<newline])
                pending.removeSubrange(...newline)
                if !message.isEmpty {
                    try writeResponse(for: message, to: output)
                }
            }
        }
    }

    private func writeResponse(
        for message: Data,
        to output: FileHandle
    ) throws {
        guard var response = router.response(to: message) else {
            return
        }
        response.append(0x0A)
        try output.write(contentsOf: response)
    }
}
