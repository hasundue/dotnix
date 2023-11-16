import { assertEquals, assertObjectMatch } from "./std/assert.ts";
import { Group, Init, ClosedSet } from "./loader.ts";

const assert = (actual: Init[], expected: Init[]) => {
  assertEquals(actual.length, 2);
  assertObjectMatch(actual[0], expected[0]);
  assertObjectMatch(actual[1], expected[1]);
};

const expectedGroup = [
  {
    repo: "Shougo/dpp.vim",
    lazy: false,
    rtp: "",
  },
  {
    repo: "Shougo/dpp-ext-lazy",
    depends: ["dpp"],
    lazy: false,
    rtp: "",
  },
] satisfies Init[];

Deno.test("Group", () => {
  assert(
    Group({ lazy: false, rtp: "" }, [
      {
        repo: "Shougo/dpp",
      },
      {
        repo: "Shougo/dpp-ext-lazy",
        depends: ["dpp"],
      },
    ]),
    expectedGroup,
  );
});

Deno.test("Group - nested", () => {
  assert(
    Group({ lazy: false, rtp: "" }, [
      {
        repo: "Shougo/dpp.vim",
      },
      ...Group({ depends: ["dpp"] }, [
        {
          repo: "Shougo/dpp-ext-lazy",
        },
      ]),
    ]),
    expectedGroup,
  );
});

const expectedClosedSet = [
  {
    name: "dpp",
    repo: "Shougo/dpp.vim",
  },
  {
    name: "dpp-ext-lazy",
    repo: "Shougo/dpp-ext-lazy",
    depends: ["dpp"],
  },
] satisfies ClosedSet<"Shougo/dpp.vim" | "Shougo/dpp-ext-lazy">;

Deno.test("ClosedSet", () => {
  assert(
    ClosedSet(
      {
        repo: "Shougo/dpp.vim",
      },
      {
        repo: "Shougo/dpp-ext-lazy",
        depends: ["dpp"],
      },
    ),
    expectedClosedSet,
  );
});

Deno.test("ClosedSet - with nested Groups", () => {
  assert(
    ClosedSet(
      {
        repo: "Shougo/dpp.vim",
      },
      ...Group({ depends: ["dpp"] }, [
        { repo: "Shougo/dpp-ext-lazy" },
      ]),
    ),
    expectedClosedSet,
  );
});

Deno.test("ClosedSet - with top-level Group", () => {
  assert(
    ClosedSet(...Group({ lazy: false, rtp: "" }, [
      {
        repo: "Shougo/dpp.vim",
      },
      {
        repo: "Shougo/dpp-ext-lazy",
        depends: ["dpp"],
      },
    ])),
    expectedClosedSet,
  );
});
