## qui, a simple imgui for odin
very very wip  
goals:
- simple
- powerful
- customizable

## example
```odin
if qui.div_start() {
  if qui.div_start(
    direction = .Horizontal,
    padding = 8,
    gap = 8,
    background_color = rl.RED,
  ) {
    qui.rect(64)
    qui.rect(64)
    qui.rect(64)
  }
}
```
