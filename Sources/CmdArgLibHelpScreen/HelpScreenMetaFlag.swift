//  Copyright (c) 2025-2026 Peter Buenafuente Summerland.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.

import CmdArgLibCore

public extension MetaFlag {

    /// A meta-flag that builds a help-screen
    init(helpElements: [ShowElement])
    {
        @Sendable
        func function(callNames: [String], values: [String], context: RunContext) -> Exception {
            let helpScreen = HelpScreen(
                callNames: callNames,
                helpScreenElements: helpElements,
                context: context)
            return Exception.stderr(helpScreen.makeHelpScreen())
        }
        let newMetaFlag = MetaFlag(
            metaTypeFunction: function, isHelpMetaType: true, isManpageMetaType: false,
            isCompletionMetaType: false, showElements: helpElements)
        self = newMetaFlag
    }
}
