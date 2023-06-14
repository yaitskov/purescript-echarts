{ name = "purescript-echarts"
, packages = ./packages.dhall
, backend = "purs-backend-es build"
, dependencies =
  [ "arrays"
  , "bifunctors"
  , "colors"
  , "control"
  , "datetime"
  , "effect"
  , "either"
  , "enums"
  , "foldable-traversable"
  , "foreign"
  , "foreign-object"
  , "formatters"
  , "identity"
  , "integers"
  , "lists"
  , "maybe"
  , "newtype"
  , "nonempty"
  , "now"
  , "numbers"
  , "partial"
  , "prelude"
  , "random"
  , "signal"
  , "tailrec"
  , "transformers"
  , "tuples"
  , "unsafe-coerce"
  , "variant"
  , "web-dom"
  , "web-events"
  , "web-html"
  ]
, sources = [ "src/**/*.purs", "example/src/**/*.purs" ]
}
