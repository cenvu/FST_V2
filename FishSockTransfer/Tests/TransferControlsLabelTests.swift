import Foundation

private func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    guard actual == expected else {
        fatalError("\(message): expected \(expected), got \(actual)")
    }
}

private func assertNotEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    guard actual != expected else {
        fatalError("\(message): expected value different from \(expected)")
    }
}

@main
struct TransferControlsLabelTests {
    static func main() {
        assertEqual(
            TransferControlsActionPresentation.title(for: .ready),
            "START",
            "ready label"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .copying),
            "TRANSFERRING",
            "copying label"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .verifying),
            "VERIFYING",
            "verifying label"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .copyComplete),
            "TRANSFER COMPLETE",
            "copyComplete copy-only label"
        )
        assertNotEqual(
            TransferControlsActionPresentation.title(for: .copyComplete),
            "SAFE TO EJECT",
            "copyComplete must not display safe-to-eject label"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .safeToFormat),
            "SAFE TO EJECT",
            "safeToFormat label"
        )
        let formerFormatLabel = ["SAFE", "TO", "FORMAT"].joined(separator: " ")
        for state in [TransferState.ready, .validating, .copying, .verifying, .copyComplete, .safeToFormat, .error, .cancelled] {
            assertNotEqual(
                TransferControlsActionPresentation.title(for: state),
                formerFormatLabel,
                "state \(state.rawValue) must not display old format wording"
            )
        }
        assertEqual(
            TransferControlsActionPresentation.title(for: .error),
            "TRANSFER ERROR",
            "transfer error label"
        )
        assertEqual(
            TransferControlsActionPresentation.title(
                for: .error,
                errorMessage: "MANUAL CHECK REQUIRED: Verification failed."
            ),
            "MANUAL CHECK REQUIRED",
            "verification failure label"
        )
        assertEqual(
            TransferControlsActionPresentation.icon(for: .copyComplete),
            "doc.on.doc",
            "copyComplete copy-only icon"
        )
        assertNotEqual(
            TransferControlsActionPresentation.icon(for: .copyComplete),
            TransferControlsActionPresentation.icon(for: .safeToFormat),
            "copyComplete icon must differ from safeToFormat icon"
        )
        assertNotEqual(
            TransferControlsActionPresentation.icon(for: .copyComplete),
            "checkmark.circle.fill",
            "copyComplete must not use safe checkmark icon"
        )
        assertEqual(
            TransferControlsActionPresentation.icon(for: .safeToFormat),
            "checkmark.circle.fill",
            "safeToFormat safe checkmark icon"
        )
        assertEqual(
            TransferControlsActionPresentation.visualRole(for: .copyComplete),
            .copyOnlyComplete,
            "copyComplete visual role"
        )
        assertEqual(
            TransferControlsActionPresentation.visualRole(for: .safeToFormat),
            .safeToFormat,
            "safeToFormat visual role"
        )
        assertNotEqual(
            TransferControlsActionPresentation.visualRole(for: .copyComplete),
            TransferControlsActionPresentation.visualRole(for: .safeToFormat),
            "copyComplete button color role must differ from safeToFormat"
        )
        assertEqual(
            TransferState.copyComplete.statusVisualRole,
            .copyOnlyComplete,
            "copyComplete status color role"
        )
        assertEqual(
            TransferState.safeToFormat.statusVisualRole,
            .safeToFormat,
            "safeToFormat status color role"
        )
        assertNotEqual(
            TransferState.copyComplete.statusVisualRole,
            TransferState.safeToFormat.statusVisualRole,
            "copyComplete status color role must differ from safeToFormat"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .error),
            "TRANSFER ERROR",
            "default error label"
        )
        assertEqual(
            TransferControlsActionPresentation.title(for: .cancelled),
            "START",
            "cancelled label"
        )

        print("TransferControlsLabelTests passed")
    }
}
