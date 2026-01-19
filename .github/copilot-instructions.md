# Electric Furnace Hopper System - AI Coding Instructions

> **Reading Priority for AI:**
>
> 1.  **[CRITICAL]** - Hard constraints, must strictly follow
> 2.  **[IMPORTANT]** - Key specifications
> 3.  **[Rule]** - Coding standards (Occam's Razor)

---

## 1. Project Overview

| Property          | Value                                            |
| ----------------- | ------------------------------------------------ |
| **Project**       | Electronic Furnace Feed System (电炉加料监控系统) |
| **Type**          | Windows Desktop Industrial Monitoring App        |
| **Stack**         | Flutter 3.22.x + Dart 3.4.x                      |
| **Backend**       | FastAPI (Python) + InfluxDB 2.7                  |
| **Target**        | 工控机触摸屏 (1920×1080 or 1280×800)             |
| **Key Principle** | **Stability (7x24h)** & **Simplicity (Occam's)** |

---

## 2. [CRITICAL] Domain Context: Electric Furnace Hopper

**核心业务纠正 (Domain Correction)**:
本项目是 **"电炉 (Electric Furnace)"** 的配套加料系统，**绝不是**磨料车间或回转窑 (Rotary Kiln) 系统。
-   **Subject**: Electric Furnace Hopper (电炉料仓).
-   **Function**: Monitoring the material feeding process into the electric furnace.
-   **Key Metrics**: Weight (重量), Feeding Rate (下料速度), Temperature (温度), Vibration (振动).

### 2.1 Sensor Configuration
本项目每个料仓配备以下传感器：
-   **PM10 传感器**: 监测粉尘浓度
-   **温度传感器**: 监测料仓温度
-   **电表**: 监测电流、电压、功率等电气参数
-   **振动传感器**: 监测振动幅值和频谱

---

## 3. [CRITICAL] UI/Navigation Requirements

### 3.1 Main Layout (Dashboard)
The dashboard uses a structured layout ensuring the visual model is prominent.

-   **Left Side (Data Panel)**:
    -   Real-time list of hoppers.
    -   Key KPIs: Weight (tons/kg), Status (Running/Stopped).
    -   Control status showing valve opening degrees.

-   **Right Side (Visual Twin)**:
    -   **[CRITICAL]** Must display the **Electric Furnace Hopper Structure (电炉料仓结构图)**.
    -   **Visual Elements**:
        -   Hopper body (Must look like a furnace feed hopper, not a kiln).
        -   Feeding pipes connecting to the furnace.
        -   Sensors overlaid on the physical structure.
    -   **Asset**: Use `assets/images/blue_bg_structure.png` (Ensure this represents the furnace hopper).

### 3.2 Window Configuration
-   **Mode**: Fullscreen or Fixed Size Window (No resize).
-   **Style**: Hidden TitleBar, Industrial Dark Theme.

---

## 4. [CRITICAL] Stability & Occam's Razor

> **Core Principle**: Do not multiply entities without necessity. Simple code has fewer bugs.

### 4.1 Timer Management ⏱️
**Problem**: Timers are the #1 cause of freezes.
-   **[Rule]** Strictly pair `Timer.periodic` with `cancel()` in `dispose()`.
-   **[Rule]** Check `if (mounted)` inside callbacks.
-   **[Rule]** Use `visible` awareness to pause polling on inactive tabs.

### 4.2 HTTP & Networking 🌐
-   **[Rule]** **Timeouts**: Every request MUST have `.timeout()`.
-   **[Rule]** **Singleton**: Use `ApiClient` singleton.
-   **[Rule]** **Retry**: Exponential backoff, never crash on 404/500.

---

## 5. Data Specifications

-   **Refresh Rate**: 3-5 seconds.
-   **Data Flow**: Backend (Polling) -> REST API -> Flutter App.
-   **Mocking**: Frontend must support a "Demo Mode" or handle empty data gracefully.

---

## 6. Visual Style (Tech/Industrial)

-   **Palette**:
    -   Bg: `TechColors.bgDeep` (Dark Blue/Black)
    -   Accent: `TechColors.glowCyan` (Data), `TechColors.glowOrange` (Warning).
    -   Text: Readable contrast, monospaced for numbers.
-   **Components**: `TechPanel`, `InfoCard`, `StatusIndicator` (Custom widgets in `lib/widgets/`).

---

## 7. Anti-Patterns (Do NOT do this)

-   ❌ **NO**: Confusing this project with "Rotary Kiln" (回转窑).
-   ❌ **NO**: Hardcoding screen sizes inside widgets (Use `LayoutBuilder`).
-   ❌ **NO**: Infinite retry loops without delay (CPU spike).
-   ❌ **NO**: Using complex state management (Bloc/Redux) for simple UI toggles.

---

**AI Instruction**: When generating code for this project, always verify: "Does this look like an Electric Furnace component?" and "Is the code crash-proof?".
