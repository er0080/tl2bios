# GAL-Based ROM Disable - Technical Explanation

## What is a GAL?

**GAL** = **Generic Array Logic**

A GAL is a type of **Programmable Logic Device (PLD)** - essentially a blank chip that you can program to implement custom digital logic.

### Think of it as:
- **Hardware equivalent of software** - you write logic equations and "compile" them into the chip
- **Programmable glue logic** - replaces discrete 74-series logic chips
- **Field-programmable** - can be programmed without special equipment (unlike mask ROMs)
- **Reprogrammable** - can be erased and reprogrammed (most GALs are EEPROM-based)

### History & Context

**1980s Technology:**
- Developed by Lattice Semiconductor in 1985
- Popular in 80s/90s for custom logic in computers
- Used extensively in arcade boards, industrial controllers, expansion cards
- Replaced complex combinations of discrete logic chips

**Common GAL chips:**
- **GAL16V8** - 16 inputs, 8 outputs (most common, perfect for this project)
- **GAL20V8** - 20 inputs, 8 outputs
- **GAL22V10** - 22 inputs, 10 outputs

**Modern equivalent:**
- CPLDs (Complex PLDs) - like Xilinx CoolRunner, Altera MAX
- FPGAs (Field-Programmable Gate Arrays) - much larger, more complex
- SPLDs (Simple PLDs) - modern replacements for GALs

---

## How a GAL Works

### Internal Architecture

A GAL contains:

1. **Input pins** - connect to signals you want to monitor
2. **Programmable AND-OR array** - implements Boolean logic
3. **Output logic macrocells** - can be configured as combinational or registered
4. **Output pins** - drive signals based on your logic

**Simplified diagram:**
```
Inputs ──┐
         ├──> Programmable  ──> Output ──> Outputs
Feedback─┘    AND-OR Array      Macrocells
```

### What You Can Program

**Boolean logic equations:**
```
OUTPUT1 = INPUT1 & INPUT2 | INPUT3
OUTPUT2 = /INPUT1 & INPUT4 | INPUT5 & INPUT6
```

**Registered outputs (with flip-flops):**
```
OUTPUT.R = INPUT1 & INPUT2  ; Registered output
```

**Tristatable outputs:**
```
OUTPUT.E = ENABLE_SIGNAL    ; Output enable control
```

### Example: Simple Logic

**Replace 74LS08 (AND gate) + 74LS32 (OR gate):**

Old way (2 chips):
```
Chip1 (74LS08): A AND B = C
Chip2 (74LS32): C OR D = E
```

GAL way (1 chip):
```
E = (A & B) | D
```

Program this into GAL, done!

---

## GAL for ROM Disable - The Concept

### What We Want to Achieve

**Goal:** Make ROMCS controllable via Port FFEA

**Current situation:**
- Memory controller generates ROMCS based on address (hardwired)
- ROMCS goes directly to ROM chips
- No software control

**With GAL:**
- Intercept ROMCS signal
- Monitor Port FFEA writes
- Only pass ROMCS to ROM chips if "ROM enable" bit is set
- Otherwise block ROMCS (keep ROM disabled)

### Block Diagram

**Before (current hardware):**
```
Memory Controller (U22)
         |
      ROMCS# ────────────> ROM Chips (U54-U57)
                                |
                                v
                           Data Bus (E000 content)
```

**After (with GAL):**
```
Memory Controller (U22)
         |
      ROMCS# ────> GAL (intercepts)
                    |
                    ├─ Monitor Port FFEA writes
                    ├─ Check "enable ROM" control bit
                    └─ Pass ROMCS only if enabled
                         |
                         v
                    ROM Chips (U54-U57)
                         |
                         v
                    Data Bus (E000 content)
```

### GAL Inputs (What it monitors)

The GAL would need to monitor:

1. **ROMCS#** - Original signal from memory controller
2. **XD0-XD7** - Data bus (to capture Port FFEA writes)
3. **IOW#** - I/O Write signal (to detect when Port FFEA is written)
4. **SA0-SA7** - System address (to detect Port FFEA address 0xFFEA)

### GAL Outputs (What it controls)

1. **ROMCS_TO_ROM#** - Modified ROMCS signal to ROM chips
2. **Status LED** (optional) - Show ROM enabled/disabled state

### GAL Logic (Pseudocode)

```
// Internal register to store ROM enable state
register ROM_ENABLE = 1;  // Start with ROM enabled

// Detect Port FFEA write
FFEA_WRITE = /IOW & (ADDRESS == 0xFFEA);

// When Port FFEA is written, capture bit 7 as ROM enable
if (FFEA_WRITE) {
    ROM_ENABLE = DATA_BUS[7];  // Use bit 7 as "ROM enable" control
}

// Only pass ROMCS to ROM chips if ROM is enabled
ROMCS_TO_ROM = ROMCS & ROM_ENABLE;

// If ROM_ENABLE = 0, ROM never gets chip select
// If ROM_ENABLE = 1, ROM gets chip select normally
```

### How Software Would Use It

**New Port FFEA behavior (with GAL):**

**Enable ROM:**
```assembly
MOV AL, 80h        ; Bit 7 = 1 (enable ROM)
OUT 0xFFEA, AL
; ROM now responds to E000 addresses
```

**Disable ROM:**
```assembly
MOV AL, 00h        ; Bit 7 = 0 (disable ROM)
OUT 0xFFEA, AL
; ROM now ignores E000 addresses, E000 is free for UMBs
```

**DOS device driver could now control ROM:**
```assembly
; NOROM.SYS using GAL-modified hardware
IN  AL, 0xFFEA
AND AL, 7Fh        ; Clear bit 7 = disable ROM
OUT 0xFFEA, AL
; Success! ROM is disabled via software
```

---

## How to Program a GAL

### Equipment Needed

1. **GAL Programmer Device**
   - **TL866** series (TL866II Plus) - Modern, affordable (~$50-70)
   - **GQ-4X** programmer - Also supports GALs
   - **Older programmers:** BP Microsystems, Data I/O (expensive, obsolete)
   - **DIY programmer:** Arduino-based GAL programmer (advanced)

2. **Programming Software**
   - **minipro** - Open source for TL866 (Linux/Windows/Mac)
   - **Xgpro** - Official TL866 software (Windows)
   - **galette** - GAL development toolkit
   - **WinCUPL** - Compiler for PLD equations (legacy, but works)

3. **GAL Chip**
   - **GAL16V8** or **GAL22V10** (depends on pin count needed)
   - Available on eBay, Aliexpress (~$2-5 per chip)
   - Atmel ATF16V8, ATF22V10 (modern replacements)

### Programming Workflow

**Step 1: Write Logic Equations**

Create a source file (`.pld` format for WinCUPL or CUPL):

```
Name     TL2_ROMCTL;
Partno   00;
Date     2026-02-10;
Revision 01;
Designer Your_Name;
Company  Vintage_Computing;
Assembly TL2_ROM_Control;
Location U99;
Device   g16v8;

/* Inputs */
Pin 1  = CLK;
Pin 2  = ROMCS_IN;      /* From memory controller */
Pin 3  = IOW;           /* I/O Write strobe */
Pin 4  = A7;            /* Address bit 7 */
Pin 5  = A6;
Pin 6  = A5;
Pin 7  = A4;
Pin 8  = A3;
Pin 9  = A2;
Pin 10 = GND;

Pin 11 = D7;            /* Data bus bit 7 */
Pin 12 = D6;
Pin 13 = D5;
Pin 14 = D4;
Pin 15 = D3;
Pin 16 = D2;
Pin 17 = D1;
Pin 18 = D0;
Pin 19 = ROMCS_OUT;     /* To ROM chips */
Pin 20 = VCC;

/* Logic */

/* Detect Port FFEA write (address 0xFFEA) */
FFEA = A7 & A6 & A5 & !A4 & A3 & !A2;  /* Simplified address decode */

/* ROM enable register (uses macrocell flip-flop) */
ROM_EN.D = D7;                         /* Capture data bus bit 7 */
ROM_EN.CK = !IOW & FFEA;              /* Clock on FFEA write */

/* Output: pass ROMCS only if ROM enabled */
ROMCS_OUT = ROMCS_IN & ROM_EN;
```

**Step 2: Compile Equations**

Use CUPL or WinCUPL to compile:
```bash
cupl -j -a tl2_romctl.pld
```

This generates:
- `.jed` file (JEDEC fuse map - this is what gets programmed into GAL)
- `.sim` file (simulation data)
- `.doc` file (documentation)

**Step 3: Program the GAL Chip**

Using TL866 programmer:

```bash
# Using minipro (open source)
minipro -p "ATF16V8B" -w tl2_romctl.jed

# Or using Xgpro GUI:
# 1. Select device: ATF16V8B
# 2. Load .jed file
# 3. Click "Program"
```

Programming takes ~10-30 seconds.

**Step 4: Verify Programming**

```bash
minipro -p "ATF16V8B" -r readback.jed
diff tl2_romctl.jed readback.jed
# Should be identical
```

**Step 5: Test in Circuit**

- Install programmed GAL in circuit
- Test with multimeter (measure signals)
- Test with logic analyzer if available
- Boot system and test ROM enable/disable

### If Logic is Wrong

**GALs are reprogrammable!**

1. Remove from circuit
2. Erase: `minipro -p "ATF16V8B" -E`
3. Modify .pld file
4. Recompile and reprogram
5. Test again

**Iteration is easy** - just reprogram until it works!

---

## Practical Implementation for TL/2

### Circuit Design

**Required connections:**

**GAL Input Pins:**
- ROMCS_IN ← From memory controller U22 pin (cut original trace)
- IOW ← From system bus
- A0-A15 ← From system address bus (or decode logic)
- D0-D7 ← From system data bus (buffered)
- GND, VCC

**GAL Output Pins:**
- ROMCS_OUT → To ROM chips U54-U57 (reconnect)
- STATUS_LED → Optional indicator LED

### Physical Installation

**Step 1: Cut ROMCS Trace**
- Same as simple hardware mod
- But keep both cut ends accessible

**Step 2: Install GAL Socket**
- Wire-wrap or solder a DIP socket somewhere on board
- Or use a small perfboard with GAL socket

**Step 3: Wire Connections**
- ROMCS_IN: Wire from memory controller side of cut trace
- ROMCS_OUT: Wire to ROM chips side of cut trace
- Bus signals: Tap into nearby pins or vias
- Power: Tap 5V and GND

**Step 4: Test**

**Without GAL (test wiring):**
- Jumper ROMCS_IN to ROMCS_OUT
- Should behave exactly like unmodified system
- This verifies wiring is correct

**With GAL (test logic):**
- Insert programmed GAL
- Boot system
- Test Port FFEA ROM enable/disable
- Verify with E000:0000 reads

### Debugging

**Logic analyzer is your friend!**

Can observe:
- ROMCS_IN signal from memory controller
- Port FFEA write signals (IOW, Address, Data)
- ROMCS_OUT signal to ROM chips
- Verify GAL logic behavior in real-time

**Without logic analyzer:**
- Use multimeter to check DC signals
- Use oscilloscope to observe transitions
- Use POST codes / beep codes for debugging
- Add status LED to GAL output

---

## Advantages of GAL Approach

### Flexibility

**Can implement complex features:**
- ROM enable/disable via Port FFEA bit 7
- Write protection (prevent accidental ROM writes if RAM mapped)
- Page-based protection (protect specific pages)
- Status register (read back ROM enable state)
- Multiple control ports

**Example advanced logic:**
```
; Port FFEA bit 7 = ROM enable (1=on, 0=off)
; Port FFEA bit 6 = Lock bit (1=locked, prevent changes)
; Port FFEB = Read ROM status
```

### Reversibility

**Fully reversible:**
- Remove GAL and restore jumper = back to original
- No permanent modification (except initial trace cut)
- Can try different logic without hardware changes

### Testability

**Easy to iterate:**
- Program GAL with test logic
- Test on hardware
- If wrong, reprogram GAL with fixes
- No circuit changes needed

### Expandability

**Can add features:**
- Status LEDs (ROM enabled/disabled indicator)
- Diagnostic features
- Shadow RAM control
- Multiple ROM banks

---

## Disadvantages of GAL Approach

### Complexity

**Requires:**
- Understanding of digital logic
- GAL programming tools and knowledge
- Ability to compile PLD equations
- Debugging skills

**Learning curve:**
- Must learn CUPL or similar language
- Must understand GAL architecture
- Must be able to debug logic issues

### Cost

**Hardware needed:**
- GAL programmer: $50-70 (TL866II Plus)
- GAL chips: $2-5 each
- DIP socket, wire, etc: $5
- **Total: ~$60-80** vs free for simple trace cut

**But programmer is reusable** for future projects!

### Physical Space

**Circuit must fit:**
- GAL chip is 20-pin or 24-pin DIP package (large)
- Needs wiring to multiple bus signals
- May require perfboard or wirewrap
- Harder to hide than simple cut

### Reliability

**More failure points:**
- GAL chip can fail
- Wiring can break
- Bus loading issues
- More complex to debug

---

## Is GAL Approach Worth It?

### When GAL Makes Sense:

✅ **You want software control** - can toggle ROM on/off from DOS
✅ **You want reversibility** - can remove GAL and restore original behavior
✅ **You have/want to learn** GAL programming skills
✅ **You have programmer** or want to buy one for future projects
✅ **You like tinkering** - fun educational project
✅ **You want status indication** - LEDs, diagnostic features

### When Simple Trace Cut Makes More Sense:

✅ **You just want it to work** - simple, effective
✅ **You never want ROM enabled** - permanent disable is fine
✅ **You don't have GAL programmer** - $0 vs $60+ cost
✅ **You want quick modification** - done in 30 minutes
✅ **You don't want complexity** - fewer failure modes

---

## Modern Alternatives to GALs

### CPLDs (Complex Programmable Logic Devices)

**Examples:**
- Xilinx XC9500 series
- Altera MAX 7000/MAX II
- Lattice ispMACH 4000

**Advantages over GALs:**
- More logic capacity (hundreds to thousands of gates)
- Modern tools (Xilinx ISE, Quartus, Diamond)
- In-System Programming (ISP) - no need to remove chip
- Better availability

**Disadvantages:**
- More complex to program
- Smaller (harder to hand-solder)
- More expensive
- Overkill for this simple task

### Arduino / Microcontroller

**Use ATtiny or ATmega:**
- Monitor Port FFEA writes via interrupt
- Control ROMCS output pin
- Very flexible - can reprogram firmware easily

**Advantages:**
- Extremely flexible
- Easy to program (Arduino IDE)
- Can add serial debugging output
- Cheap (~$2-5)

**Disadvantages:**
- Slower than GAL (microseconds vs nanoseconds)
- May not respond fast enough for memory timing
- Needs oscillator/crystal
- More power hungry

### FPGAs (Field-Programmable Gate Arrays)

**Examples:**
- Lattice iCE40 series
- Xilinx Spartan/Artix
- Intel Cyclone

**Advantages:**
- Massive logic capacity
- Can implement entire memory controller
- Modern tools and support

**Disadvantages:**
- **MASSIVE OVERKILL** for this project
- Expensive ($10-50+)
- Complex to design with
- Small packages (BGA, QFP) - difficult to hand-solder

---

## Learning Resources

### GAL Programming

**Online Resources:**
- [GAL Tutorial by Ken Shirriff](http://www.righto.com/2017/10/reverse-engineering-hardware-to-create.html)
- [GALette - GAL Development Tools](https://github.com/simon-frankau/galette)
- WinCUPL User's Manual (search for PDF)

**Books:**
- "Programmable Logic Devices" by Richard S. Sandige
- "Digital Systems Design Using Programmable Logic Devices" by Parag K. Lala

**Forums:**
- Vintage Computer Forum (VCFed)
- EEVblog Forum
- Reddit r/AskElectronics

### TL866 Programmer

**Software:**
- [minipro (open source)](https://gitlab.com/DavidGriffith/minipro)
- [Official Xgpro software](http://www.xgecu.com/en/)

**Tutorials:**
- YouTube: "TL866 programmer tutorial"
- YouTube: "GAL programming with TL866"

---

## Example: Simple ROM Control GAL

Here's a minimal working example:

```
Name     Simple_ROM_Control;
Device   g16v8;

/* Inputs */
Pin 1  = ROMCS_IN;      /* From memory controller */
Pin 2  = ENABLE;        /* Physical jumper or switch */

/* Outputs */
Pin 19 = ROMCS_OUT;     /* To ROM chips */

/* Logic - simplest possible */
ROMCS_OUT = ROMCS_IN & ENABLE;

/* If ENABLE jumper is closed (high), ROM works normally */
/* If ENABLE jumper is open (low), ROM is disabled */
```

This is the "toggle switch" approach implemented in a GAL!

**Advantages:**
- Learn GAL programming with simple project
- Can later add Port FFEA monitoring
- Can experiment with more complex logic
- Reversible - can always go back to simple jumper

---

## Conclusion

**GAL = Programmable hardware logic**
- Like software for hardware
- Can implement custom control logic
- Reprogrammable and flexible

**For TL/2 ROM control:**
- Can make ROM software-controllable
- Requires GAL programmer (~$60)
- Advanced approach for experienced users
- Very educational and fun!

**Recommendation:**
- **Beginners:** Start with simple trace cut
- **Intermediate:** Try toggle switch first
- **Advanced:** GAL approach for learning and flexibility

**The GAL approach transforms this from a hardware-only solution back into a software-controlled solution** - which was the original goal! But at the cost of significant additional complexity.

---

## Quick Reference

**GAL16V8 Pinout:**
```
        GAL16V8
    +---\_/---+
CLK |1      20| VCC
I/O |2      19| I/O
I/O |3      18| I/O
I/O |4      17| I/O
I/O |5      16| I/O
I/O |6      15| I/O
I/O |7      14| I/O
I/O |8      13| I/O
I/O |9      12| I/O
GND |10     11| I/O
    +---------+
```

**Common GAL Part Numbers:**
- GAL16V8 / ATF16V8 (most common)
- GAL20V8 / ATF20V8
- GAL22V10 / ATF22V10

**Programming Software:**
- WinCUPL (compiler)
- minipro (programmer)
- galasm (assembler)

**Useful Commands:**
```bash
# Compile
cupl -j -a source.pld

# Program
minipro -p "ATF16V8B" -w source.jed

# Verify
minipro -p "ATF16V8B" -r readback.jed

# Erase
minipro -p "ATF16V8B" -E
```
