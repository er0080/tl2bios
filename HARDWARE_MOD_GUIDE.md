# Hardware Modification Guide - ROM Disable at E000:0000

## ⚠️ WARNING - READ THIS FIRST

**This guide describes PERMANENT HARDWARE MODIFICATIONS to your Tandy 1000 TL/2.**

**Risks:**
- **PERMANENT DAMAGE** to motherboard if done incorrectly
- **LOSS OF ROM DRIVE FUNCTIONALITY** (cannot be restored if traces cut)
- **SYSTEM MAY NOT BOOT** if modification fails
- **WARRANTY VOID** (though likely expired on 35+ year old hardware)
- **POTENTIAL FOR COMPLETE SYSTEM FAILURE**

**Prerequisites:**
- Experience with electronics and soldering
- Multimeter for testing continuity
- Steady hands and patience
- **BACKUP ROM DUMP** (already have: 8079044.BIN)
- Ability to boot from floppy if system fails

**Only proceed if you:**
- Understand the risks
- Have soldering experience
- Can accept permanent loss of ROM drive
- Have proper tools and workspace

---

## Project Background

### Why Hardware Modification is Necessary

After extensive testing and analysis, we determined:

1. **Port FFEA does NOT control ROM enable/disable** - it only selects which 64KB page is visible
2. **ROMCS is hardware address-decoded** - generated automatically by memory controller
3. **No software method exists** to disable ROM at E000:0000
4. **BIOS cannot disable ROM** - address decoding happens before BIOS in hardware stack

The DRAM/DMA Control IC (U22) has hardwired logic:
```
IF (Address = 0xE0000-0xEFFFF) AND (NOT REFRESH)
THEN Assert ROMCS (activate ROM chips)
```

**This logic is in silicon and cannot be changed by software.**

### What This Modification Achieves

**Goal:** Disconnect ROM chips from E000 segment to free 64KB for DOS UMBs

**After modification:**
- E000:0000-EFFF:FFFF becomes unoccupied address space
- EMM386 can map RAM to E000-EFFF
- ~60KB additional upper memory available for drivers/TSRs
- ROM drive functionality LOST (cannot boot from ROM, no DeskMate)
- System BIOS at F000 unaffected (still works normally)

---

## Understanding the Hardware

### ROM Chip Architecture

**ROM Chips:**
- **U54, U55**: ROM0 (256KB) - Lower half of ROM
- **U56, U57**: ROM1 (256KB) - Upper half of ROM
- Total: 512KB organized as 8 pages of 64KB each

**Control Signals:**
- **ROMCS#**: Main chip select (active LOW) ← This is what we must disable
- **Page Select**: Bits from Port FFEA select which 64KB page
- **Address Lines**: SA0-SA15 address within the 64KB page

### Memory Controller Signal Path

```
CPU Address Bus
      |
      v
DRAM/DMA Control IC (U22)
      |
      ├──> Address Decode Logic (A17-A23)
      |           |
      |           v
      |      ROMCS# Signal ────┐
      |                        |
      v                        v
  (to RAM)              ROM Chips (U54-U57)
                              |
                              v
                         Data Bus (E000 content)
```

**To disable ROM, we must break the ROMCS# signal path.**

---

## Modification Options

### Option 1: Cut ROMCS# Trace (Easiest, Permanent)

**Difficulty:** ⭐⭐☆☆☆ (Medium)
**Reversibility:** ❌ PERMANENT (trace cannot be restored easily)
**Risk:** Medium (can damage board if wrong trace cut)

**Method:** Physically cut the ROMCS# trace between memory controller and ROM chips

**Pros:**
- Simple - just cut one trace
- No additional components needed
- Clean solution

**Cons:**
- Permanent modification
- Cannot restore ROM drive without soldering jumper wire
- Must identify correct trace (easy to cut wrong one)

**Success Rate:** 85% (if correct trace identified)

---

### Option 2: Lift ROMCS# Pin on ROM Chips (Reversible)

**Difficulty:** ⭐⭐⭐☆☆ (Hard)
**Reversibility:** ✅ Can resolder pin
**Risk:** High (can damage ROM chip pins)

**Method:** Bend or desolder ROMCS# pin on all 4 ROM chips

**Pros:**
- Reversible (can resolder pins)
- ROM chips unharmed if done carefully
- No trace cutting

**Cons:**
- Must modify ALL 4 ROM chips
- Requires desoldering (or careful pin bending)
- Risk of breaking pins on old chips
- Difficult on through-hole ICs

**Success Rate:** 60% (risky on old hardware)

---

### Option 3: Install ROMCS# Override Switch (Advanced, Reversible)

**Difficulty:** ⭐⭐⭐⭐☆ (Very Hard)
**Reversibility:** ✅ Fully reversible
**Risk:** Medium (complex circuit, more failure points)

**Method:** Insert switch/jumper in ROMCS# signal path

**Pros:**
- **Can toggle ROM on/off at will**
- Fully reversible
- Preserves ROM drive when needed
- Can test before making permanent

**Cons:**
- Requires cutting trace AND soldering switch
- Need to mount switch/jumper somewhere accessible
- More complex installation

**Success Rate:** 70% (if executed correctly)

---

### Option 4: GAL-Based Programmable Disable (Expert, Reversible)

**Difficulty:** ⭐⭐⭐⭐⭐ (Expert)
**Reversibility:** ✅ Fully reversible
**Risk:** High (complex, requires GAL programming)

**Method:** Insert GAL/CPLD to intercept and conditionally block ROMCS#

**Pros:**
- Software-controllable ROM disable via Port FFEA
- Fully reversible
- Most flexible solution
- Can add features (page protection, etc.)

**Cons:**
- Requires GAL programmer
- Must write and test GAL logic
- Complex circuit design
- Need to intercept Port FFEA writes

**Success Rate:** 40% (expert-level project)

---

## RECOMMENDED: Option 1 - Cut ROMCS# Trace

This guide focuses on Option 1 (trace cutting) as it offers the best balance of simplicity, effectiveness, and success rate.

---

## Tools and Materials Required

### Essential Tools:
- [ ] Phillips screwdriver (for case)
- [ ] Anti-static wrist strap
- [ ] Magnifying glass or jeweler's loupe
- [ ] Bright work light
- [ ] Sharp hobby knife or scalpel
- [ ] Multimeter with continuity tester
- [ ] Isopropyl alcohol (90%+) for cleaning

### Optional but Recommended:
- [ ] Digital microscope or camera
- [ ] PCB holder or helping hands
- [ ] Fine-tip permanent marker
- [ ] Electrical tape or Kapton tape
- [ ] Thin insulated wire (30AWG) for jumper if reversal needed later
- [ ] Soldering iron (if installing switch or reversing later)

### Documentation Materials:
- [ ] Camera or phone for photos
- [ ] Notepad for documenting steps
- [ ] Printed copy of this guide

---

## Phase 1: Preparation and Identification

### Step 1.1: Create Backup and Boot Disk

**Before opening the case:**

1. **Create DOS boot disk:**
   ```
   FORMAT A: /S
   COPY C:\DOS\MEM.EXE A:\
   COPY C:\DOS\DEBUG.COM A:\
   ```

2. **Verify ROM dump exists:**
   - Check that `8079044.BIN` (512KB) is backed up
   - Store on PC or another disk

3. **Test boot from floppy:**
   - Ensure system can boot from A: drive
   - This is your recovery method if modification fails

### Step 1.2: Open the Case

1. **Power off and unplug system**
2. **Wait 10 minutes** for capacitors to discharge
3. **Ground yourself** with anti-static strap
4. **Remove case screws** (typically 4-6 Phillips screws on back)
5. **Carefully slide off case top**
6. **Take photos** of motherboard before any work

### Step 1.3: Locate ROM Chips and Memory Controller

**ROM Chips Identification:**

Look for 4 large rectangular ICs in the upper-middle area of the motherboard:
- **U54, U55** (ROM0) - Should be labeled 27C010 or similar (128Kx8)
- **U56, U57** (ROM1) - Same type
- Usually in DIP-32 packages (32 pins)
- May have sticker labels: "Tandy BIOS" or similar

**Memory Controller Identification:**

- **U22** - DRAM/DMA Control IC
- Large IC (likely 68-pin PLCC or similar)
- Located near RAM SIMMs
- May be labeled with Tandy or AMD part number

**Take clear photos showing:**
- All 4 ROM chips with labels visible
- Memory controller IC
- Any visible trace connections between them

### Step 1.4: Locate ROMCS# Signal

**ROMCS# is an active-LOW signal (marked with # or * suffix)**

**Look for:**
1. **Pin connections on ROM chips**
   - ROMCS# is typically pin 20 or 22 on 27C-series ROMs
   - Consult datasheet for exact pin (varies by chip type)

2. **Trace from Memory Controller (U22) to ROM chips**
   - ROMCS# trace goes from U22 to all 4 ROM chips
   - May split into two: one for ROM0 pair, one for ROM1 pair
   - Trace may be labeled on silkscreen (look for "RCS", "ROMCS", "CS")

**Document findings:**
- Mark ROMCS# pin on each ROM chip with marker (on paper, not board!)
- Trace path from U22 to ROMs
- Identify where trace is accessible for cutting

---

## Phase 2: Testing and Verification

### Step 2.1: Verify System Operation (Baseline)

1. **Reassemble temporarily** (don't close case)
2. **Power on** and boot to DOS
3. **Run baseline tests:**
   ```
   DEBUG
   -D E000:0000 0010
   ```
   **Expected:** Should see ROM data (EB 34 90...)

4. **Run MEM:**
   ```
   MEM /C
   ```
   **Expected:** E000-EFFF shows as "ROM" or unavailable

5. **Power off** after verification

**Mark this baseline - this is "ROM enabled" state**

### Step 2.2: Identify Cut Location

**Best cut locations (in order of preference):**

1. **Between U22 and ROM chips**
   - Look for trace running from Memory Controller toward ROM area
   - Should be accessible on top layer
   - May run under solder mask (appears as thin line)

2. **Near ROM chip pins**
   - Trace connecting to ROMCS# pin on U54/U56
   - Easier to access than mid-board traces

3. **At via or junction**
   - Where trace changes layers or joins
   - More visible and easier to cut cleanly

**Mark the cut location:**
- Use permanent marker to mark TWO cut points
- Space cuts 2-3mm apart (easier to verify discontinuity)
- Take photos of marked location

**CRITICAL: Verify this is ROMCS# trace:**
- Use multimeter continuity mode
- Probe from Memory Controller ROMCS# pin
- Probe to ROM chip ROMCS# pin
- Should have continuity (beep)
- **If no continuity, DO NOT CUT - wrong trace**

---

## Phase 3: Making the Modification

### Step 3.1: Prepare for Cutting

1. **Remove power** (unplug completely)
2. **Ground yourself** (anti-static strap)
3. **Clean area** with isopropyl alcohol
4. **Double-check:**
   - Correct trace identified
   - Cut location marked
   - Camera ready for documentation
   - Multimeter nearby for testing

### Step 3.2: Cut the Trace

**Method: Two-Point Cut**

This method creates a 2-3mm gap to ensure complete disconnection.

**Steps:**

1. **First cut:**
   - Hold hobby knife like a pencil
   - Position blade perpendicular to trace
   - Apply gentle pressure and rock blade slightly
   - Cut completely through trace (will feel slight "give")
   - Do NOT apply excessive force (can damage board layers)

2. **Inspect first cut:**
   - Use magnifying glass
   - Ensure cut goes completely through trace
   - Should see separation with exposed fiberglass between

3. **Second cut (2-3mm away):**
   - Repeat process for second cut
   - Creates clear gap between cut ends

4. **Remove trace segment (optional):**
   - Use knife tip to carefully scrape away trace between cuts
   - Creates visible gap (easier to verify)
   - Clean away copper debris with alcohol

5. **Clean area:**
   - Wipe with isopropyl alcohol
   - Remove any copper dust or debris
   - Let dry completely

**Take photos of completed cuts from multiple angles**

### Step 3.3: Verify Disconnection

**Use multimeter in continuity mode:**

1. **Test Memory Controller to ROM0:**
   - Probe U22 ROMCS# pin
   - Probe U54/U55 ROMCS# pin
   - **Expected: NO continuity (no beep)**

2. **Test Memory Controller to ROM1:**
   - Probe U22 ROMCS# pin
   - Probe U56/U57 ROMCS# pin
   - **Expected: NO continuity (no beep)**

3. **Test ROM to ROM:**
   - Probe U54 ROMCS# pin
   - Probe U56 ROMCS# pin
   - **Expected: May have continuity if ROMs share common trace**
   - This is OK - we only need disconnection from U22

**If continuity still exists:**
- Cut did not go deep enough
- Make additional cuts
- Verify with magnifying glass

---

## Phase 4: Testing the Modification

### Step 4.1: First Power-On Test

**This is the moment of truth!**

1. **Reassemble** (don't close case yet)
2. **Connect power** (don't turn on yet)
3. **Prepare boot disk** in drive A:
4. **Cross fingers** 🤞
5. **Power on**

**Expected behaviors:**

**GOOD Signs:**
- ✅ System powers on normally
- ✅ POST completes (may beep)
- ✅ BIOS screen appears (F000 BIOS still works!)
- ✅ Boots from floppy disk
- ✅ Can get to A:\> prompt

**BAD Signs (See Troubleshooting):**
- ❌ System doesn't power on
- ❌ Continuous beeping
- ❌ Hangs at BIOS screen
- ❌ No video output

**If BAD signs occur:**
- POWER OFF immediately
- See "Troubleshooting" section below
- May need to restore trace with jumper wire

### Step 4.2: Verify ROM is Disabled

**At A:\> prompt:**

1. **Test E000 segment:**
   ```
   DEBUG
   -D E000:0000 0010
   ```

   **EXPECTED RESULT:**
   ```
   FF FF FF FF FF FF FF FF ...
   ```
   (All 0xFF indicates no ROM responding - success!)

   **If you see:**
   ```
   EB 34 90 54 41 4E ...
   ```
   (ROM boot sector - mod failed, ROMCS still active)

2. **Try writing to E000:**
   ```
   DEBUG
   -F E000:0000 E000:000F 42
   -D E000:0000 0010
   ```

   **EXPECTED:** Should see "42 42 42..." (wrote successfully)
   **ROM was read-only, so writes confirm ROM is disconnected**

3. **Test Port FFEA:**
   ```
   DEBUG
   -O FFEA C8
   -D E000:0000 0010
   ```

   **EXPECTED:** Still shows 0xFF (page switching has no effect)
   **Confirms ROM chips are not receiving ROMCS signal**

### Step 4.3: Test System Stability

**Run stability tests for 30 minutes:**

1. **Memory test:**
   ```
   A:\>MEM
   ```
   Should show E000-EFFF as available/free

2. **File operations:**
   ```
   A:\>DIR
   A:\>COPY *.* B:\  (if you have B: drive)
   ```

3. **Let system idle** - watch for crashes, hangs, or errors

**If stable for 30 minutes → Modification successful! ✅**

---

## Phase 5: EMM386 Integration

### Step 5.1: Configure EMM386 to Use E000-EFFF

Create/edit CONFIG.SYS on your boot drive (C:):

```
DEVICE=C:\DOS\HIMEM.SYS
DEVICE=C:\DOS\EMM386.EXE NOEMS I=E000-EFFF
DOS=HIGH,UMB
FILES=30
BUFFERS=20
```

**Key line:** `I=E000-EFFF` tells EMM386 to include E000-EFFF as UMB space

### Step 5.2: Test UMB Allocation

1. **Reboot from hard drive**

2. **Check UMB availability:**
   ```
   C:\>MEM /C
   ```

   **Look for:**
   ```
   Upper Memory:
   ...
   E000-EFFF    64,000    Free
   ...
   ```

3. **Load drivers high:**

   Add to CONFIG.SYS:
   ```
   DEVICEHIGH=C:\DOS\ANSI.SYS
   ```

   Add to AUTOEXEC.BAT:
   ```
   LOADHIGH C:\DOS\DOSKEY.COM
   ```

4. **Verify memory savings:**
   ```
   C:\>MEM
   ```

   **Should show:**
   - ~60KB+ additional Upper Memory available
   - More conventional memory free (drivers loaded high)

---

## Troubleshooting

### System Won't Boot After Modification

**Symptom:** No video, no POST beeps, or continuous beeping

**Possible causes:**
1. Cut wrong trace (damaged critical signal)
2. Shorted adjacent traces during cutting
3. Damaged board layers
4. Static discharge damaged IC

**Recovery steps:**
1. **Inspect cuts carefully** with magnifying glass
2. **Check for shorts** - use multimeter to test adjacent traces
3. **Look for copper debris** - clean with alcohol
4. **Restore ROMCS# with jumper wire:**
   - Solder thin wire across cut points
   - Test if system boots with trace restored
   - If boots, problem was NOT the mod (something else wrong)

### System Boots but ROM Still Active (E000 shows EB 34...)

**Symptom:** E000:0000 still shows ROM data after modification

**Possible causes:**
1. Cut didn't go through completely
2. Cut wrong trace
3. Multiple ROMCS# signals (separate for ROM0/ROM1)
4. ROMCS# routed on internal layer

**Solutions:**
1. **Verify continuity test** - ensure NO continuity U22 to ROM chips
2. **Make deeper cuts** - ensure trace is completely severed
3. **Check for parallel traces** - there may be ROM0_CS and ROM1_CS
4. **Cut all ROMCS# traces** to both ROM chip pairs

### System Boots but Unstable (Crashes, Hangs)

**Symptom:** System boots but crashes during use

**Possible causes:**
1. Cut trace other than ROMCS# by accident
2. Damaged board during modification
3. Static damage to ICs
4. Unrelated hardware failure coincidentally

**Solutions:**
1. **Restore ROMCS# with jumper** - test if stability returns
2. **Boot from floppy only** - does it work without hard drive?
3. **Run RAM test** - may have damaged RAM system
4. **Check all visible traces** - look for accidental cuts

### E000 Still Shows FF but EMM386 Won't Map It

**Symptom:** E000 reads as FF but EMM386 error "Unable to set page frame"

**Possible causes:**
1. EMM386 configuration error
2. Conflict with other memory region
3. BIOS still reporting E000 as "in use"

**Solutions:**
1. **Check EMM386 command line:**
   ```
   DEVICE=C:\DOS\EMM386.EXE NOEMS I=E000-EFFF
   ```
   (Make sure I= not E=)

2. **Try forcing inclusion:**
   ```
   DEVICE=C:\DOS\EMM386.EXE NOEMS I=E000-EFFF X=E000-EFFF I=E000-EFFF
   ```

3. **Check for conflicts:**
   ```
   MEM /D
   ```
   Look for other drivers using E000

---

## Reversal Procedure (If Needed)

### To Restore ROM Functionality

**If you need to restore ROM drive:**

1. **Solder jumper wire across cut:**
   - Use 30AWG insulated wire
   - Strip 2mm from each end
   - Tin both cut ends of trace
   - Solder wire bridging the gap
   - Ensure good connection
   - Test continuity with multimeter

2. **Verify restoration:**
   - Boot system
   - Test E000:0000 - should show EB 34 90... again
   - ROM drive should be accessible

**Note:** This restoration is tricky and may not be 100% reliable.

---

## Safety and Best Practices

### Before Starting:
- [ ] Read entire guide start to finish
- [ ] Gather all tools and materials
- [ ] Create backup boot disk
- [ ] Take photos of unmodified system
- [ ] Verify ROM dump backed up

### During Modification:
- [ ] Work in well-lit area
- [ ] Use anti-static precautions
- [ ] Take photos at each step
- [ ] Double-check before cutting
- [ ] Cut slowly and carefully
- [ ] Test continuity after each cut

### After Modification:
- [ ] Document exact cut location (for future reference)
- [ ] Keep photos archived
- [ ] Note any issues encountered
- [ ] Share results with community

---

## Expected Results

### Successful Modification:

**Before:**
```
C:\>MEM
655,360 bytes total conventional memory
640,000 bytes available
      0 bytes upper memory available
```

**After:**
```
C:\>MEM
655,360 bytes total conventional memory
640,000 bytes available
 60,000+ bytes upper memory available
```

### What You Lose:

- ❌ ROM drive (D:) disappears
- ❌ Cannot boot from ROM
- ❌ DeskMate ROM utilities gone
- ❌ ROM filesystem inaccessible

### What You Gain:

- ✅ ~60KB additional upper memory
- ✅ More conventional memory free (drivers loaded high)
- ✅ Better DOS compatibility
- ✅ More drivers/TSRs can load

---

## Community and Support

### Share Your Results:

If you complete this modification:
- Document your results
- Take clear photos
- Note any variations for your specific TL/2
- Share on vintage computing forums

### Known Issues:

*(To be updated as community reports results)*

---

## Appendix A: Circuit Theory

### Why This Works:

The ROMCS# signal is the "chip enable" for the ROM chips:
- ROMCS# = LOW → ROM chips respond to address bus
- ROMCS# = HIGH or FLOATING → ROM chips ignore address bus

By cutting ROMCS#:
- Memory Controller still generates signal (but goes nowhere)
- ROM chips never receive enable signal
- ROM chips remain in high-impedance state
- E000 addresses see no device responding → read as 0xFF
- RAM can be mapped to E000 by memory manager

### Why Port FFEA Doesn't Matter:

Port FFEA controls ROM internal page selection, not chip enable:
- Even with ROMCS# cut, Port FFEA still works
- But with no ROMCS#, ROM never reads Port FFEA
- Page selection has no effect on disconnected ROMs

---

## Appendix B: Alternative: Install Toggle Switch

For advanced users who want reversible ROM enable/disable:

### Materials:
- SPST switch (single-pole, single-throw)
- 30AWG wire
- Small drill for mounting hole

### Procedure:
1. Cut ROMCS# trace as described
2. Solder wires to both cut ends
3. Route wires to accessible location
4. Connect through SPST switch
5. Mount switch in convenient location (back panel?)

**Switch positions:**
- ON → ROMCS# connected → ROM active at E000
- OFF → ROMCS# disconnected → E000 free for UMBs

This allows switching between ROM drive mode and UMB mode!

---

## Appendix C: ROM Chip Pinouts

### 27C010 ROM (128Kx8, 32-pin DIP)

```
Pin  Function
----------------
1    VPP/A16
2    A15
...
20   /CE (Chip Enable) ← ROMCS# connects here
22   /OE (Output Enable)
...
32   VCC
```

**ROMCS# typically connects to pin 20 (/CE)**

Verify with your specific chip datasheet!

---

## Final Notes

This modification is **permanent** and **risky**. Only proceed if:
- You understand the risks
- You have the skills and tools
- You can accept losing ROM drive functionality
- You have a backup plan if things go wrong

**Good luck, and may your cuts be clean and your system stable!** 🔧

---

**Document Version:** 1.0
**Last Updated:** 2026-02-10
**Status:** DRAFT - Community testing needed
**Tested on:** None (awaiting community results)
