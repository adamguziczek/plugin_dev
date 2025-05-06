# Wobbler Audio Plugin: Technical Architecture Document

## Overview

"Wobbler" is a JUCE-based audio plugin (VST3/AU/AAX) designed to provide creative, pattern-based LFO modulation for DAW parameters. This document outlines the technical architecture of Wobbler, addressing data structures, module interactions, real-time DSP, UI responsiveness, scalability, and testing strategy.

---

## 1. Data Structures & Representation

### LFO Shape Representation

* **Structure:** `std::vector<LFOPoint>` where `LFOPoint` contains `float phase`, `float value`, and `CurveType curve`.
* **Curve Types:** Enumerated (e.g., linear, exponential, spline).
* **Storage:** Curves are computed from point data and cached when possible.

### Pattern Sequencer Representation

* **Grid Model:** 2D grid (`std::vector<std::vector<ShapePlacement>>`), each cell references an LFO shape.
* **ShapePlacement:** Contains start time, duration, reference to shape ID, and transform data (scaling, phase).
* **Tempo Info:** Stored globally and aligned with DAW clock.

### Plugin State Representation

* **Serialization:** Managed via `juce::ValueTree`.
* **Structure:**

  * Root: `PluginState`
  * Children: `LFOShapes`, `PatternSequences`, `Mappings`, `Settings`
* **Versioning:** Integer version stored at root, with deserialization migration logic.

---

## 2. Module Interaction & Design Patterns

### Key Modules:

* LFO Shape Engine
* Pattern Sequencer
* Modulation Routing
* Parameter Mapping
* Playback & Synchronization
* UI
* State Management
* Host Integration Layer
* Testing Framework

### Design Patterns

* **Observer Pattern:** UI subscribes to updates from backend modules (Shape Engine, Sequencer).
* **Model-View-Controller (MVC):** Clear separation between data, view, and control logic.
* **Command Pattern:** Used for Undo/Redo support (shape edits, grid modifications).
* **Dependency Injection:** Interfaces injected at runtime to reduce coupling.

---

## 3. Real-Time Performance & DSP Considerations

### Bottlenecks & Optimization Strategies

* **Shape Interpolation:**

  * Use Cubic Hermite or Catmull-Rom splines.
  * Precompute and cache LFO waveforms for common shapes.
* **Modulation Application:**

  * Per-sample or per-buffer evaluation using `dsp::ProcessBlock`.
  * Use SIMD or lookup tables if necessary.
* **Smoothing:**

  * Apply 1-pole low-pass filters to prevent harsh transitions.
* **Threading:**

  * Audio processing on real-time thread.
  * UI & editing on background or message threads.

---

## 4. Scalability for Future Features

### Multiple LFOs & Targets

* Encapsulate each LFO as an `LFOModule` with its own shape engine, sequencer, and routing.
* Maintain a list of `LFOModule` instances.

### Multi-Target Routing

* Parameter mappings use a `ModulationTarget` struct with target ID, depth, smoothing, phase.
* Routing table: `std::vector<RoutingEntry>` linking LFO outputs to DAW parameters.

### Extensible Modulation Sources

* Abstract base class `ModulationSource`, with subclasses `LFO`, `Envelope`, `Random`, etc.
* Routing system works on base class pointers.

---

## 5. UI Responsiveness & Decoupling

### UI Thread Safety

* UI updated using `AsyncUpdater`, `Timer`, or `MessageManager::callAsync`.
* Audio thread only modifies atomic/shared state – no direct UI interaction.

### Drawing Efficiency

* Use `juce::Graphics` with dirty-region redraws.
* Cache static visuals (e.g., grid lines, default shape renderings).
* Use off-screen rendering for complex or zoomed components.

---

## 6. State Management Robustness

### Preset Saving/Loading

* Full plugin state stored in `juce::ValueTree`, serialized with `getStateInformation()` / `setStateInformation()`.
* Binary blobs used only for performance-critical cache data.

### Undo/Redo

* Custom `Command` objects for edits.
* `UndoManager` tracks shape edits, sequence placements, parameter changes.

### Versioning

* Stored as metadata in `ValueTree` root.
* Deserialization checks version and migrates if necessary.

---

## 7. Testing Strategy

### Unit Tests

* Modules: Shape Engine, Sequencer, Routing, State Serialization.
* Framework: Catch2 or Google Test integrated into CMake.

### Integration Tests

* Validate shape rendering in UI against expected data.
* Confirm sequence timing and pattern playback across edge cases.

### Cross-DAW Sync Tests

* Test against multiple hosts (Ableton, Logic, Reaper, FL Studio).
* Simulate tempo changes, start/stop scenarios.

### Stress Testing

* Simulate multiple LFOs with high modulation rates.
* Profile performance under maximum load conditions.

### Preset Consistency Tests

* Load/save/recall presets with randomized data.
* Compare output against saved baseline.

---

## Conclusion

The architecture of Wobbler is modular, extensible, and optimized for real-time performance and creative flexibility. With a strong foundation in JUCE best practices, Wobbler is engineered to deliver a reliable, scalable modulation system suitable for modern music production workflows.
