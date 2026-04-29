# StatsLite Menu Bar App Design

Date: 2026-04-29

## Goal

Create a native macOS menu bar app named StatsLite. The app reads local CPU, GPU, and memory information and presents the current load in the macOS menu bar.

## Project Form

StatsLite will be a full Xcode macOS project using Swift, SwiftUI, and AppKit. It will create `StatsLite.xcodeproj` and native source/test targets.

The app will run as a menu bar utility rather than a normal windowed app:

- No main window at launch.
- No Dock icon.
- One `NSStatusItem` in the system menu bar.
- A menu attached to the status item with detailed CPU, GPU, and memory information plus Quit.

## Menu Bar Presentation

The menu bar item will use option B from the visual mockup: a balanced semi-circular progress indicator with an integer value centered inside it.

Default dimensions:

- Approximate status item content size: 42 px wide by 26 px high.
- Semi-circle track with rounded caps.
- Filled arc color: muted green.
- Background track: macOS system gray.
- Center text: integer only, no percent sign.
- Font: compact system font, bold enough to remain readable in the menu bar.

The displayed integer will represent the primary load value. For the first version, this will be CPU usage rounded to the nearest whole number. Detailed CPU, GPU, and memory values will be available in the dropdown menu.

## Dropdown Menu

Clicking the status item opens a simple native menu:

- CPU usage as an integer percentage.
- GPU device name.
- Memory used and total memory.
- Refresh interval.
- Quit command.

The menu will update from the same cached stats snapshot used by the menu bar indicator.

## System Stats Collection

CPU usage:

- Use `host_processor_info` to read per-core CPU ticks.
- Calculate usage from the delta between consecutive samples.
- Clamp the result to 0...100 before formatting.

Memory:

- Use `host_statistics64` for VM statistics.
- Use `sysctl` to read total physical memory.
- Report used and total memory in GB.

GPU:

- Use Metal to get the default device name.
- If Metal is unavailable, show `Unavailable`.

## Main Components

`StatsLiteApp.swift`

- App entry point.
- Configures the app as menu-bar-only.
- Owns the app delegate or startup bridge needed for AppKit status item setup.

`MenuBarController.swift`

- Owns `NSStatusItem`.
- Hosts the custom semi-circle progress view in the status item.
- Builds and refreshes the dropdown menu.
- Runs the refresh timer.

`SemiCircleProgressView.swift`

- Draws the balanced semi-circle progress indicator.
- Displays only the integer value in the center.
- Handles clamping and stable intrinsic sizing for menu bar use.

`SystemStatsProvider.swift`

- Reads CPU, GPU, and memory data.
- Keeps CPU previous-sample state so usage is calculated from deltas.
- Returns a typed stats snapshot.

`StatsFormatter.swift`

- Formats integers and memory strings.
- Keeps presentation rules testable without depending on macOS system APIs.

## Testing

Use focused unit tests for deterministic behavior:

- Integer formatting rounds and clamps values correctly.
- Memory formatting produces stable GB strings.
- Semi-circle view model clamps progress to 0...1.
- Menu bar primary value uses CPU usage as the displayed integer.

System API collection will be validated by build and runtime smoke testing because exact values depend on local hardware and current load.

## Validation

After implementation:

- Build with `xcodebuild`.
- Run unit tests with `xcodebuild test` if a suitable macOS test destination is available.
- Confirm the project opens in Xcode.
- Confirm the app target is a menu bar app with no normal launch window.

## Out Of Scope For First Version

- User-selectable primary metric.
- Historical charts.
- Preferences window.
- Login item installation.
- Multiple simultaneous menu bar gauges.
