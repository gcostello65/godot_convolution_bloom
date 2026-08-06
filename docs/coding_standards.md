# C++20 / Vulkan Real-Time Coding Standards

## Core Philosophy
- **Zero-Overhead Abstractions**: Write inline/template code that compiles down to raw hardware performance.
- **Determinism**: Zero dynamic allocations (`new`/`delete`, unconstrained `std::vector` growth) during the real-time render loop.
- **Safety via RAII**: Never manage Vulkan handles manually. Wrap every VkDevice, VkBuffer, and VkImageView in custom RAII classes or use unique handles with custom deleters.

## Modern C++ Conventions
- **Const-by-Default**: Use `const` and `constexpr` aggressively. Apply **West const** style (e.g., `const int value` instead of `int const value`).
- **Immutability**: Almost-always-auto (`auto const` or `auto`) for local variables where type is redundant.
- **Safety Checks**: Use `enum class` over C-style enums. Use `nullptr` instead of `0` or `NULL`. No C-style casts; use `static_cast` or `bit_cast`.
- **Object Lifecycles**: Strictly enforce the **Rule of Zero** or **Rule of Five**. Mark move constructors and move assignment operators as `noexcept`.
- **Metaprogramming**: Constrain templates using C++20 `requires` clauses and Concepts.

## Vulkan Specific Rules
- **Handle Wrappers**: Define lightweight RAII wrappers for all Vulkan objects to guarantee destruction order via explicit cleanup chains.
- **Error Handling**: Check all `VkResult` codes explicitly. Assert on `VK_SUCCESS` in development; implement clean fallback/recovery paths for `VK_ERROR_DEVICE_LOST`.
- **Memory Aliasing & Pointers**: Prefer `VMA` (Vulkan Memory Allocator) for buffer/image allocations; avoid raw `vkAllocateMemory` calls spread across application logic.
- **Frame Sync**: Explicitly structure frame-in-flight boundaries using `VkFence` and `VkSemaphore` safely encapsulated in rendering context structures.

