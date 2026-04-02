

## [3.0.0](https://github.com/rodrigoluizs/claude-plugins/compare/maintenance/v2.0.0...maintenance/v3.0.0) (2026-04-02)

## [2.0.0](https://github.com/rodrigoluizs/claude-plugins/compare/maintenance/v1.0.0...maintenance/v2.0.0) (2026-04-02)


### ⚠ BREAKING CHANGES

* **maintenance:** removes the batch merge limit introduced in the previous release.

### Features

* **maintenance:** revert 10-PR re-confirmation guardrail ([#69](https://github.com/rodrigoluizs/claude-plugins/issues/69)) ([b7d512a](https://github.com/rodrigoluizs/claude-plugins/commit/b7d512ac6c64272e74cd8ed87fafbec546fa1f6f))

## [1.0.0](https://github.com/rodrigoluizs/claude-plugins/compare/maintenance/v0.6.4...maintenance/v1.0.0) (2026-04-02)


### ⚠ BREAKING CHANGES

* **maintenance:** handle-dependency-prs now requires the user to explicitly
re-confirm before merging more than 10 PRs in a single session.

### Features

* **maintenance:** require re-confirmation after merging 10 dependency PRs ([#66](https://github.com/rodrigoluizs/claude-plugins/issues/66)) ([fc83433](https://github.com/rodrigoluizs/claude-plugins/commit/fc834334907b06ef510d542192a1078f8cd5b250))

## [0.6.4](https://github.com/rodrigoluizs/claude-plugins/compare/maintenance/v0.6.3...maintenance/v0.6.4) (2026-04-02)


### Bug Fixes

* **release:** fix jq split to handle newline-separated plugin names ([#63](https://github.com/rodrigoluizs/claude-plugins/issues/63)) ([79a3258](https://github.com/rodrigoluizs/claude-plugins/commit/79a3258e5c970f578c8d370061744c4e701bbb41))
* **release:** skip workflow on chore(release) commits to prevent infinite loop ([#62](https://github.com/rodrigoluizs/claude-plugins/issues/62)) ([d75c567](https://github.com/rodrigoluizs/claude-plugins/commit/d75c5677eeb4b1f36488ccbca72edb3cd3b16145))

# Changelog

## 0.6.2 (2026-03-30)

- fix(maintenance): detect dependency bots by heuristics instead of hardcoded author names (#24)


## 0.6.1 (2026-03-30)

- fix(maintenance): enforce subagent delegation in handle-dependency-prs (#23)


## 0.6.0 (2026-03-30)

- feat(maintenance): delegate PR analysis to subagents in handle-dependency-prs skill (#22)


## 0.5.0 (2026-03-30)

- feat(maintenance): extract parallel subagents for dependency PR handling (#21)


## 0.4.1 (2026-03-29)

- fix(maintenance): respect stability period checks in handle-dependency-prs skill (#20)


## 0.4.0 (2026-03-29)

- feat(maintenance): rename dep-review to handle-dependency-prs and improve skill (#19)


## 0.3.0 (2026-03-29)

- feat(maintenance): add fix-ci-main skill (#17)


## 0.2.1 (2026-03-28)

- fix: resolve plugin validation warnings (#10)


## 0.2.0 (2026-03-28)

- feat: add PR validation workflow for plugins and marketplace (#7)


## 0.1.1 (2026-03-27)

- chore: update plugin descriptions to be concept-level (#6)


## 0.1.0 (2026-03-27)

- feat: add maintenance plugin with dep-review skill
