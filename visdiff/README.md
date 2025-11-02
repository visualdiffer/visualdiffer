Visdiff
===


#### Problem: The plist build macros like `PRODUCT_BUNDLE_IDENTIFIER` are not expanded

The command line tool visdiff is sandboxed using `.plist` + `.entitlements` files

The plist file must be embedded into binary and before XCode 7 this was achieved adding to the linker `OTHER_LDFLAGS` (under "Other Linker Flags") the value

	-sectcreate __TEXT __info_plist visdiff/Info.plist

but this 'overwrites' the expansion done by the compiler

#### Solution

Remove the linker flag and turn on the flag `Build Settings` -> `Packaging` -> `Create info.plit Section in Binary`