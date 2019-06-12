# NVIDIA 418.74 Drivers

This is a shame. I would never been doing this if not forced to. And I have been.

Since NVIDIA upgraded their drivers to _430.14_, I can't use my computer because I just see a black
screen when I login. There are workarounds that are not doable for the time I wait for a real fix.

While they don't release a fix for this issue, I will be _sadly_ maintaining this pinned version of
the drivers.

I'm maintaining both `nvidia-418`, as well as `nvidia-utils-418`. I intend to remove both as soon as
this is fixed on upstream - or I find a better alternative/workaround to keep using the Arch
package.

## Issue

The problem is that I see a black screen shortly after the Linux boot initial logs. After that, the
screen shutdown and never turns on again - it enters on energy saving mode.

This doesn't seem to be related with Xorg, because this happens before Xorg is even started. In
fact, if I disable Xorg it still happens.

To detect that you're a victim of this problem, just look for a single log entry at the boot time
(`journalctl -b -0`):

```
nvidia-modeset: WARNING: GPU:0: Lost display notification (0:0x00000000); continuing.
```

## Workaround

The workaround is a PITA. I need to plug in my monitor into the onboard VGA, then wait for Xorg to
start, then I can re-plug it on the NVIDIA card. This is the worst.
