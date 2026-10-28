// Self-check for core/beat.js (the cava frame parser): node scripts/test_beat.js
const fs = require("fs");
const vm = require("vm");
const assert = require("assert");

const ctx = {};
// Another realm: arrays from it fail deepStrictEqual, hence Array.from below.
vm.runInNewContext(fs.readFileSync(__dirname + "/../core/beat.js", "utf8"), ctx);

// A raw ascii frame: values 0..1000 split by ';', often with a trailing ';'.
assert.deepStrictEqual(Array.from(ctx.parseFrame("0;500;1000;", 3)), [0, 0.5, 1]);
assert.deepStrictEqual(Array.from(ctx.parseFrame("250;750", 2)), [0.25, 0.75]);
// A frame cut short or with junk is dropped, not drawn half.
assert.strictEqual(ctx.parseFrame("0;500;", 3), null);
assert.strictEqual(ctx.parseFrame("a;b;c;", 3), null);
assert.strictEqual(ctx.parseFrame("", 3), null);
// Out-of-range values are clamped.
assert.deepStrictEqual(Array.from(ctx.parseFrame("-5;2000;", 2)), [0, 1]);

// Bass is the loudest of the lowest three bars.
assert.strictEqual(ctx.bass([0.2, 0.9, 0.4, 1, 1]), 0.9);

// Attack is fast, release slow: rising jumps most of the way, falling eases.
assert.ok(ctx.follow(0, 1) > 0.5);
assert.ok(ctx.follow(1, 0) > 0.5);
assert.strictEqual(ctx.follow(0.3, 0.3), 0.3);

console.log("beat.js ok");
