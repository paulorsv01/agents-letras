# Lift State Only As Far As Needed

Lift state when sibling coordination is required.

Do not lift state just because "shared state sounds cleaner".

Good:

- trigger and panel both need the same open state
- list and summary need the same selection

Bad:

- a leaf-only hover/focus state moved to the page root

Keep fast-changing state near the subtree that changes with it.
