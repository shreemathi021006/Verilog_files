# Smart Charger HMI: From Bluetooth Control to a Single-Wire, Chip-Based Charger

A charger that lets the user decide how much to charge and for how long, and a plan to take it from a Bluetooth-based prototype to a cable-only system built around custom digital logic.

This README is written to accompany my fellowship application. It separates **what I have built** from **what I want to build next**, so it is clear which parts are working and which are proposals.

---

## Quick links

| What | Link |
|---|---|
| Charger HMI project (firmware, hardware details, setup) | https://github.com/shreemathi021006/charger-hmi |
| Verilog designs (shows my RTL / digital design work) | https://github.com/shreemathi021006/Verilog_files |
| Project files, photos and extra material (Google Drive) | https://drive.google.com/drive/folders/1dp5CLIL8Cp9tfwayl4l9uMWgTHDiGyTF?usp=drive_link |

---

## 1. What I have built (working)

A Human-Machine Interface (HMI) that sits between an existing, certified AC-DC charger and the device being charged.

- **Set a target:** using four buttons (Select, Enter, Inc, Dec) and a display, the user enters either a **target charge percentage** or the **time available**.
- **Real battery data:** the phone connects to an **ESP32** over Bluetooth through a small MIT App Inventor app, which sends the phone's actual battery percentage about every 30 seconds.
- **Hard cutoff:** when the target is reached, a **relay** physically disconnects the charger output. In time mode, a local countdown timer does the same.
- **Live telemetry:** an **INA226** sensor shows voltage and current on the display during charging.
- **Safety by design:** the mains-voltage stage stays inside the original sealed charger, so only low-voltage DC is handled by my unit.

Full hardware list, pin map and setup steps are in the [charger-hmi repository](https://github.com/shreemathi021006/charger-hmi).

### Prototype photo

![HMI-based smart charger prototype with display and Select, Enter, Inc, Dec buttons](images/hmi-charger-prototype.jpg)
<img width="388" height="678" alt="image" src="https://github.com/user-attachments/assets/f293d518-94c9-4889-ae90-6b97f3e600dd" />


*The working prototype: a display and four buttons (Select, Enter, Inc, Dec) in a paper-covered enclosure, placed inline between the charger and the device.*
![alt text](image.png)

---

## 2. What I want to build next (proposed)

### Step 1: Remove Bluetooth and buttons, use the cable itself
Bluetooth pairing and a separate control panel make the system clumsy. The next experiment is to use the **USB data lines** so that the moment the cable is plugged in, the charger can read the phone's current charge and receive the target percentage or time from an app on the phone. Everything would happen over one wire. On Android, the Android Open Accessory (AOA) protocol can launch a companion app automatically when the charger connects. On iPhone this needs Apple's MFi program, so it is harder.

### Step 2: Move the control logic into hardware (Verilog and FPGA)
The decision logic (parsing the target, comparing it with the battery level, generating the cutoff or PWM signals) can be written in **Verilog** and prototyped on an **FPGA**. It would work with a standard USB interface IC, because a full USB controller is a large block of its own. The output would drive the power stage through **gate drivers**. This is where my digital design work and my power electronics interest come together.

### Step 3: Let the charger recognise what is plugged in
Using **USB-C and USB-PD negotiation**, the charger can learn how much power a device needs. A phone could get fast charging, while earbuds get a gentle current. Note that this tells the charger a device's power needs, not strictly its type. Exact identification would also need the device's USB descriptors or help from the app.

### Step 4: Scale the idea to electric vehicles
The same pattern already exists in EV charging. Standards like **ISO 15118** let the car and charger share battery limits and charging goals over the cable ("Plug & Charge"). Studying this shows how a small-scale charger idea connects to real, large-scale systems.

---

## 3. What I want to learn through the fellowship

- How to design a **USB-based handshake** between a charger and a phone, and its limits on Android and iOS.
- How to write, simulate and prototype **charger control logic in Verilog** on an FPGA.
- How digital control connects to the **power stage**: PWM, gate drivers, and current and voltage feedback.
- How **USB-PD negotiation** and **ISO 15118** work in practice.

## 4. What I want to achieve

A working wired prototype that:
1. Detects when a device is plugged in.
2. Reads its battery status over the cable.
3. Accepts the user's target (percentage or time).
4. Charges safely up to that target and stops.

---

## 5. About the Verilog repository

The [Verilog_files repository](https://github.com/shreemathi021006/Verilog_files) contains digital design work I have done, and shows the skills I would use in Step 2 above: writing synthesizable RTL, building finite state machines and verifying designs in simulation.

---

## 6. Current limitations and honest notes

- The working prototype uses **Bluetooth, an ESP32 and buttons**. The USB data-line handshake, the Verilog/FPGA controller, device identification and the EV extension are **proposals**, not finished work.
- iPhone support for wired data exchange is restricted by Apple, so the first target for Step 1 is Android.
- Charging protocols that negotiate higher voltages (such as fast charging) add complexity, which is why my current design uses the phone-reported percentage rather than guessing from current alone.

---

## Contact

Shree, B.E. Electrical and Electronics Engineering, SSN College of Engineering, Chennai
