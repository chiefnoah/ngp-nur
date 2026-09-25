# ngp-nur instructions

When creating new packages, always add a plan9 rc shell script that updates the pinned
version and hash, then update the mkfile's update target to execute it. Refer to
existing rc scripts for examples.
