# Composition

Use the component system as intended.

Rules:

- item components live inside their group components
- overlays need titles for accessibility
- cards should use full card composition, not one giant `CardContent`
- `TabsTrigger` belongs inside `TabsList`
- `Avatar` needs `AvatarFallback`
- use `Alert`, `Empty`, `Separator`, `Skeleton`, and `Badge` instead of rebuilding the same shapes manually

Prefer composing existing primitives over styled `div` replacements.
