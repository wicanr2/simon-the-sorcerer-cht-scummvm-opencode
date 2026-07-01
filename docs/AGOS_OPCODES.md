# AGOS Engine Opcode Reference (Simon the Sorcerer)

This document lists the opcodes used by the AGOS engine to execute game scripts. These opcodes are used in `script_s1.cpp` and other script files to control game logic, character actions, and UI.

## Basic Control & Flow
| Opcode | Description |
| :--- | :--- |
| `o_invalid` | Invalid operation |
| `o_goto` | Jump to specific instruction/location |
| `o_when` | Conditional branch |
| `o_if1` | If condition is true |
| `o_if2` | If condition is true (alternative) |
| `o_isCalled` | Check if a subroutine is called |
| `o_is` | Check equality |
| `o_end` | End of script |
| `o_done` | Mark script as completed |
| `o_process` | Process next instruction |
| `o_haltAnimation` | Halt current animation |
| `o_restartAnimation` | Restart current animation |

## Comparison & Logic
| Opcode | Description |
| :--- | :--- |
| `o_eq` | Equal to |
| `o_notEq` | Not equal to |
| `o_gt` | Greater than |
| `o_lt` | Less than |
| `o_eqf` | Equal to (Float) |
| `o_notEqf` | Not equal to (Float) |
| `o_ltf` | Less than (Float) |
| `o_gtf` | Greater than (Float) |
| `o_zero` | Check if zero |
| `o_notZero` | Check if not zero |
| `o_chance` | Random chance check |

## Object & Character Interaction
| Opcode | Description |
| :--- | :--- |
| `o_at` | Check if at location |
| `o_notAt` | Check if not at location |
| `o_carried` | Check if item is carried |
| `o_notCarried` | Check if item is not carried |
| `o_isAt` | Check current position |
| `o_isRoom` | Check if target is a room |
| `o_isObject` | Check if target is an object |
| `o_state` | Get/set object state |
| `o_oflag` | Check/set object flags |
| `o_destroy` | Destroy object |
| `o_place` | Place object |
| `o_defObj` | Define object |
| `o_getParent` | Get parent of object |
| `o_getChildren` | Get children of object |
| `o_isCalled` | Check if subroutine is called |

## Variables & Math
| Opcode | Description |
| :--- | :--- |
| `o_let` | Assign value to variable |
| `o_add` | Addition |
| `o_sub` | Subtraction |
| `o_mul` | Multiplication |
| `o_div` | Division |
| `o_mulf` | Floating point multiplication |
| `o_divf` | Floating point division |
| `o_mod` | Modulo |
| `o_modf` | Floating point modulo |
| `o_inc` | Increment |
| `o_dec` | Decrement |
| `o_random` | Generate random number |
| `o_copyff` | Copy buffer |

## UI & Text (AGOS UI System)
| Opcode | Description |
| :--- | :--- |
| `o_print` | Print text to screen |
| `o_message` | Show message box |
| `o_msg` | Show short message |
| `oww_addTextBox` | Add text box to UI |
| `oww_setShortText` | Set short text |
| `oww_setLongText` | Set long text |
| `oww_printLongText` | Print long text |
| `o_defWindow` | Define window/dialog |
| `o_window` | Create window |
| `o_cls` | Clear window |
| `o_closeWindow` | Close window |
| `o_addBox` | Add box to window |
| `o_delBox` | Delete box from window |
| `o_enableBox` | Enable box |
| `o_disableBox` | Disable box |
| `o_moveBox` | Move box |

## Animation & Sound
| Opcode | Description |
| :--- | :--- |
| `o_playTune` | Play music/tune |
| `o_picture` | Load/show picture |
| `o_loadZone` | Load zone/room data |
| `os1_animate` | Animate object |
| `os1_pauseGame` | Pause game |
| `os1_screenTextBox` | Screen text box |
| `os1_screenTextMsg` | Screen text message |
| `os1_playEffect` | Play SFX |
| `os1_mouseOn` | Mouse on event |
| `os1_mouseOff` | Mouse off event |

*Note: This is an extracted list for development reference. Many opcodes are internal to the engine and may not be exposed directly to high-level scripting.*
