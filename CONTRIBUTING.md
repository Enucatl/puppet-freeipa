# Contributing

Changes must preserve the client-only contract, direct argv execution, finite
timeouts, credential redaction, and refusal to replace existing enrollment.
Do not add server lifecycle or administrative operations to this module.

Run `bundle exec rake validate lint spec` and `bundle exec rubocop`. Add unit
coverage for behavior changes. Acceptance changes must use disposable systems;
never use production enrollment credentials.
