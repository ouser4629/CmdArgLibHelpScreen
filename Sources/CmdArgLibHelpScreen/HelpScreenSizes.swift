//  Copyright (c) 2025-2026 Psummerland2 LLC.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.

import CmdArgLibCore

/// Define sizes for use by the default help screen
struct HelpScreenSizes: Sendable {
    public let helpScreenWidth: Int?
    let textIndent: Int
    let minimumCommandNameWidth: Int
    let minimumParameterLabelWidth: Int
    let maximumParameterLabelWidth: Int

    /// Initialize an instance of HelpScreenSizes
    public init(
        lineWidth: Int? = nil,
        textIndent: Int = 2,
        minimumCommandNameWidth: Int = 8,
        minimumParameterLabelWidth: Int = 20,
        maximumParameterLabelWidth: Int = 40 )
    {
        self.helpScreenWidth = lineWidth
        self.textIndent = textIndent
        self.minimumCommandNameWidth = minimumCommandNameWidth
        self.minimumParameterLabelWidth = minimumParameterLabelWidth
        self.maximumParameterLabelWidth = maximumParameterLabelWidth
    }
}
