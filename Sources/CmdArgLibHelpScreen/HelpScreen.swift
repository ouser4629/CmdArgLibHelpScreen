//  Copyright (c) 2025-2026 Peter Buenafuente Summerland.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.

import CmdArgLibCore
import Foundation

public struct HelpScreen:  Sendable {
    public let callNames: [String]  // Can be private?
    private let context: RunContext
    private let helpScreenSizes: HelpScreenSizes
    private var helpScreenElements: [ShowElement]
    private let expander: ShowMacroExpander
}

extension HelpScreen {

    public init(
        callNames: [String],
        helpScreenElements: [ShowElement],
        context: RunContext )
    {
        var expander = context.showMacroExpander
        expander.callNames = callNames
        self.expander = expander
        self.callNames = callNames
        self.context = context
        self.helpScreenSizes = HelpScreenSizes()
        self.helpScreenElements = helpScreenElements
    }

    /// Render the help screen
    func makeHelpScreen() -> String
    {
        var sections: [String] = []
        var errorMessages: [String] = []
        var synopsisSectionEncountered = false

        let labelTextWidth = parameterLabelsWidth(of: helpScreenElements)
        let commandNameTextWidth = commandNamesWidth(of: helpScreenElements)
        for element in helpScreenElements {
            switch element.member {
            case .parameterElement(let parameterElement):
                if let text = parameterLineText(for: parameterElement, labelTextWidth: labelTextWidth) {
                    if !parameterElement.description.isEmpty {
                        sections.append(text)
                    }
                } else {
                    errorMessages.append("unrecognized parameter name in synopsis line: \"\(parameterElement.name)\"")
                }
            case .commandContextElement(let context):
                let pd = ParameterShowElement(context: context)
                let text = commandLineText(for: pd, labelTextWidth: commandNameTextWidth)
                sections.append(text)
            case .textBlock(var textBlock):
                textBlock.expandShowMacros(using: expander)
                sections.append(textBlock.description)
            case .linesBlock(var linesBlock):
                linesBlock.expandShowMacros(using: expander)
                sections.append(linesBlock.description)
            case .synopsisDef(let synopsisHeader, let synopsisLines):
                if synopsisSectionEncountered {
                    errorMessages.append("More than one synopsis section encountered in help screen layout")
                    continue
                }
                synopsisSectionEncountered = true
                let lines = makeSynopsisSectionFor(synopsisHeader, and: synopsisLines, errorMessages: &errorMessages)
                sections += lines
            }
        }
        if !errorMessages.isEmpty {
            fatalUseOfAPI(errorMessages, file: #file, line: #line)
        }
        return sections.joined(separator: "\n")
    }
}

extension HelpScreen {

    /// Make a mulitline synopsis section
    /// - Parameters:
    ///   - specsTrailerArray: An array of ([Spec], Trailer)
    /// - Returns: The synopsis lines in mdoc format
    ///
    /// Each spec is <label>:<type>[=]. If "=" is specified the dummy will have a default value. The label an type follow the usual rules
    func makeSynopsisSectionFor(
        _ synopsisHeader: String, and synopsisLines: [SynopsisLine], errorMessages: inout [String]) -> [String]
    {
        var errorMessages: [String] = []
        var foramattedSynopsisLines: [String] = []
        var firsLineCompleted = false
        for rawLine in synopsisLines {
            let lineParameters = synopsisLineParameters(in: rawLine, for: context, errorMessages: &errorMessages)
            var newChunks = callNames
            let (shortFlagsChunk, remainingParameters) = getPackedShortFlagChunk(for: lineParameters)
            if let shortFlagsChunk {
                newChunks.append(shortFlagsChunk)
            }
            for parameter in remainingParameters {
                if let newChunk = ParameterFormatter.synopsisChunk(of: parameter).first, !newChunk.isEmpty {
                    newChunks.append(newChunk)
                }
            }
            let extraIndent = (newChunks.first?.count ?? 1) + 1  // wraps under first parameter
            let header = firsLineCompleted ? "" : synopsisHeader
            let textBlock = TextChunks(header: header, chunks: newChunks, extraIndent: extraIndent)
            foramattedSynopsisLines.append(textBlock.description)
            firsLineCompleted = true
        }
        return foramattedSynopsisLines
    }
}

extension HelpScreen {

    private func parameterLineText(for parameterElement: ParameterShowElement, labelTextWidth: Int) -> String?
    {
        if parameterElement.isPseudo {
            return pseudoParameterLineText(parameterElement.name, parameterElement.description, labelTextWidth)
        }
        guard let parameter = context.parameterNamed[parameterElement.name] else {
            return nil
        }
        var synopsis = parameterElement.description
        let endsInNewline = synopsis.last == "\n"
        if endsInNewline {
            synopsis = String(synopsis.dropLast())
        }
        synopsis = expander.expandMacros(in: synopsis)
        if !parameter.isFlagOrMetaFlag && !parameter.isMeta {
            if let defaultValue = parameterElement.defaultValueOverride {
                synopsis.append(" (default: \(defaultValue))")
            } else if let defaultValue = parameter.defaultValue, defaultValue != "[]" && defaultValue != "\"[]\"" {
                synopsis.append(" (default: \(defaultValue))")
            }
        }
        if !synopsis.isEmpty && synopsis.last! != "." {
            synopsis.append(".")
        }
        var labelTypeChunk = ParameterFormatter.labelAndTypeChunk(of: parameter)

        let labelWidth = stringWidth(labelTypeChunk)
        if labelWidth > labelTextWidth {
            labelTypeChunk = labelTypeChunk.printfPadded(-labelTextWidth - 3)
        } else {
            labelTypeChunk = labelTypeChunk.printfPadded(-labelTextWidth)
        }
        var specs = [labelTypeChunk] + synopsis.components(separatedBy: .whitespacesAndNewlines)
        if endsInNewline {
            specs.append("\n")
        }
        let indent = helpScreenSizes.textIndent
        let extraIndent = indent + labelTextWidth - 1
        let text = TextChunks(chunks: specs, indent: indent, extraIndent: extraIndent)
        return text.description
    }

    private func pseudoParameterLineText(_ name: String, _ description: String, _ labelTextWidth: Int) -> String
    {
        var synopsis = expander.expandMacros(in: description)
        if !synopsis.isEmpty && synopsis.last! != "." { synopsis.append(".") }
        var rawValueChunk = expander.expandMacros(in: name)
        let rawValueWidth = stringWidth(rawValueChunk)
        if rawValueWidth > labelTextWidth {
            rawValueChunk = rawValueChunk.printfPadded(-labelTextWidth - 3)
        } else {
            rawValueChunk = rawValueChunk.printfPadded(-labelTextWidth)
        }
        let specs = [rawValueChunk] + synopsis.components(separatedBy: .whitespacesAndNewlines)
        let indent = helpScreenSizes.textIndent
        let extraIndent = indent + labelTextWidth - 1
        let text = TextChunks(chunks: specs, indent: indent, extraIndent: extraIndent)
        return text.description
    }

    private func parameterLabelsWidth(of elements: [ShowElement]) -> Int
    {
        var labelTextWidth = helpScreenSizes.minimumParameterLabelWidth
        for element in elements {
            if case .parameterElement(let parameteElement) = element.member {
                var labelTypeChunk = ""
                if parameteElement.isPseudo {
                    labelTypeChunk = parameteElement.name
                }
                else if let parameter = context.parameterNamed[parameteElement.name] {
                    labelTypeChunk = ParameterFormatter.labelAndTypeChunk(of: parameter)
                }
                else {
                    continue
                }
                var width = max(stringWidth(labelTypeChunk), helpScreenSizes.minimumParameterLabelWidth)
                width = min(width, helpScreenSizes.maximumParameterLabelWidth)
                labelTextWidth = max(width, labelTextWidth)
            }
        }
        return labelTextWidth + 1
    }
}

extension HelpScreen {

    private func commandLineText(for parameterElement: ParameterShowElement, labelTextWidth: Int) -> String
    {
        let synopsis = parameterElement.description
        var labelTypeChunk = parameterElement.name
        let labelWidth = stringWidth(labelTypeChunk)
        if labelWidth > labelTextWidth {
            labelTypeChunk = labelTypeChunk.printfPadded(-labelTextWidth - 3)
        } else {
            labelTypeChunk = labelTypeChunk.printfPadded(-labelTextWidth)
        }
        let specs = [labelTypeChunk] + synopsis.components(separatedBy: .whitespacesAndNewlines)
        let indent = helpScreenSizes.textIndent
        let extraIndent = indent + labelTextWidth - 1
        let text = TextChunks(chunks: specs, indent: indent, extraIndent: extraIndent)
        return text.description
    }

    private func commandNamesWidth(of elements: [ShowElement]) -> Int
    {
        var commandNamesWidth = helpScreenSizes.minimumCommandNameWidth
        for element in elements {
            if case .commandContextElement(let context) = element.member {
                var width = max(stringWidth(context.name), helpScreenSizes.minimumCommandNameWidth)
                width = min(width, helpScreenSizes.maximumParameterLabelWidth)
                commandNamesWidth = max(width, commandNamesWidth)
            }
        }
        return commandNamesWidth + 1
    }
}
