(module
  ;; Memory with initial data
  (memory (export "memory") 1)

  ;; Data section - strings stored here!
  (data (i32.const 0) "שלום עולם Hello World פורנוגרפיה הימורים קזינו")

  ;; Simple function
  (func (export "greet") (result i32)
    i32.const 0  ;; return pointer to string
  )

  (func (export "add") (param i32 i32) (result i32)
    local.get 0
    local.get 1
    i32.add
  )
)
